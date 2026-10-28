import 'dart:math' as math;

import 'media_item.dart';
import 'media_source.dart';
import 'perceptual_hash.dart';
import 'scan_models.dart';

class _CancelledSignal implements Exception {
  const _CancelledSignal();
}

class _Hashed {
  const _Hashed(this.item, this.hash);

  final MediaItem item;
  final ImageHash hash;
}

/// Quét thư viện theo các giai đoạn:
/// liệt kê -> ảnh chụp màn hình -> video lớn -> băm ảnh -> trùng -> tương tự.
///
/// Mỗi mục thuộc đúng một danh mục (video lớn, ảnh chụp màn hình, ảnh trùng,
/// ảnh tương tự) nên không bị tính dung lượng hai lần.
///
/// "Ảnh trùng" = cùng dHash, cùng kích thước ảnh và cùng dung lượng file.
/// Đây là heuristic rất chặt nhưng KHÔNG phải so sánh từng byte.
class MediaScanner {
  MediaScanner(this.source, {this.config = const ScanConfig()});

  final MediaSource source;
  final ScanConfig config;

  Future<ScanOutcome> run({
    required CancelToken cancel,
    void Function(ScanProgress progress)? onProgress,
  }) async {
    final statuses = {
      for (final c in ScanCategory.values) c: CategoryStatus.scanning,
    };
    final completed = <ScanCategory>{};
    var total = 0;
    var checked = 0;
    var estimated = 0;
    var fraction = 0.0;
    var duplicates = <MediaGroup>[];
    var similar = <MediaGroup>[];
    var videos = <MediaItem>[];
    var shots = <MediaItem>[];

    void emit() {
      onProgress?.call(
        ScanProgress(
          statuses: Map.of(statuses),
          itemsChecked: checked,
          total: total,
          fraction: fraction.clamp(0.0, 1.0).toDouble(),
          estimatedBytes: estimated,
        ),
      );
    }

    void check() {
      if (cancel.isCancelled) throw const _CancelledSignal();
    }

    void markDone(Iterable<ScanCategory> categories) {
      for (final c in categories) {
        completed.add(c);
        statuses[c] = CategoryStatus.done;
      }
    }

    ScanOutcome finish(ScanEnd end, [String? error]) {
      for (final c in ScanCategory.values) {
        statuses[c] =
            completed.contains(c) ? CategoryStatus.done : CategoryStatus.pending;
      }
      emit();
      return ScanOutcome(
        end: end,
        error: error,
        result: ScanResult(
          duplicateGroups:
              completed.contains(ScanCategory.duplicates) ? duplicates : const [],
          similarGroups:
              completed.contains(ScanCategory.similar) ? similar : const [],
          largeVideos:
              completed.contains(ScanCategory.largeVideos) ? videos : const [],
          screenshots:
              completed.contains(ScanCategory.screenshots) ? shots : const [],
          completed: Set.unmodifiable(completed),
        ),
      );
    }

    try {
      total = await source.count();
      check();
      emit();

      // 1. Liệt kê metadata.
      final all = <MediaItem>[];
      var page = 0;
      while (all.length < total) {
        final batch = await source.page(page, config.pageSize);
        check();
        if (batch.isEmpty) break;
        all.addAll(batch);
        page++;
        checked = math.min(all.length, total);
        fraction = 0.10 * checked / math.max(1, total);
        emit();
      }

      // 2. Ảnh chụp màn hình.
      final shotCandidates = all
          .where((i) => i.kind == MediaKind.image && i.isScreenshot)
          .toList();
      shots = await _sizeAll(shotCandidates, cancel, (done) {
        fraction = 0.10 + 0.10 * _ratio(done, shotCandidates.length);
        emit();
      });
      shots.sort(_newestFirst);
      estimated += _sum(shots);
      markDone([ScanCategory.screenshots]);
      fraction = 0.20;
      await _release();
      emit();

      // 3. Video lớn.
      final videoCandidates =
          all.where((i) => i.kind == MediaKind.video).toList();
      final sizedVideos = await _sizeAll(videoCandidates, cancel, (done) {
        fraction = 0.20 + 0.15 * _ratio(done, videoCandidates.length);
        emit();
      });
      videos = sizedVideos
          .where((v) => (v.sizeBytes ?? 0) >= config.largeVideoBytes)
          .toList()
        ..sort((a, b) => (b.sizeBytes ?? 0).compareTo(a.sizeBytes ?? 0));
      estimated += _sum(videos);
      markDone([ScanCategory.largeVideos]);
      fraction = 0.35;
      await _release();
      emit();

      // 4. Băm ảnh (không gồm ảnh chụp màn hình).
      final photos = all
          .where((i) => i.kind == MediaKind.image && !i.isScreenshot)
          .toList();
      final hashed = <_Hashed>[];
      await _mapBounded<MediaItem, bool>(
        photos,
        (item) async {
          final luma = await source.lumaGrid(item);
          if (luma != null && luma.length == lumaGridSize) {
            hashed.add(_Hashed(item, dHash(luma)));
          }
          return true;
        },
        cancel: cancel,
        onChunk: (done) {
          fraction = 0.35 + 0.45 * _ratio(done, photos.length);
          emit();
        },
      );
      hashed.sort(_byTimeThenId);

      // 5. Ảnh trùng.
      final byKey = <String, List<_Hashed>>{};
      for (final h in hashed) {
        final key = '${h.hash}_${h.item.width}x${h.item.height}';
        byKey.putIfAbsent(key, () => []).add(h);
      }
      final candidates = byKey.values.where((l) => l.length >= 2).toList();
      final inDuplicates = <String>{};
      for (var i = 0; i < candidates.length; i++) {
        check();
        final sized =
            await _sizeAll(candidates[i].map((h) => h.item).toList(), cancel, null);
        final bySize = <int, List<MediaItem>>{};
        for (final item in sized) {
          bySize.putIfAbsent(item.sizeBytes ?? -1, () => []).add(item);
        }
        for (final same in bySize.values.where((l) => l.length >= 2)) {
          final ordered = [...same]..sort(_oldestFirst);
          duplicates.add(MediaGroup(id: 'dup_${ordered.first.id}', items: ordered));
          inDuplicates.addAll(ordered.map((e) => e.id));
        }
        fraction = 0.80 + 0.07 * _ratio(i + 1, candidates.length);
        emit();
      }
      duplicates.sort(_groupsBySavings);
      estimated += duplicates.fold(0, (s, g) => s + g.reclaimableBytes);
      await _release();

      // 6. Ảnh tương tự: chọn "hạt giống" rồi gom các ảnh gần nó trong cửa sổ thời gian.
      final pool = hashed.where((h) => !inDuplicates.contains(h.item.id)).toList();
      final used = List<bool>.filled(pool.length, false);
      final clusters = <List<MediaItem>>[];
      for (var i = 0; i < pool.length; i++) {
        if (i % 200 == 0) {
          check();
          await Future<void>.delayed(Duration.zero);
        }
        if (used[i]) continue;
        final members = <MediaItem>[pool[i].item];
        for (var j = i + 1; j < pool.length; j++) {
          final gap = pool[j].item.createdAt.difference(pool[i].item.createdAt);
          if (gap > config.similarWindow) break;
          if (used[j]) continue;
          if (pool[i].hash.distanceTo(pool[j].hash) <= config.similarMaxDistance) {
            members.add(pool[j].item);
            used[j] = true;
          }
        }
        if (members.length >= 2) {
          used[i] = true;
          clusters.add(members);
        }
      }
      fraction = 0.90;
      emit();

      for (var i = 0; i < clusters.length; i++) {
        check();
        final sized = await _sizeAll(clusters[i], cancel, null);
        if (sized.length < 2) continue;
        final ordered = [...sized]..sort(_bestFirst);
        similar.add(MediaGroup(id: 'sim_${ordered.first.id}', items: ordered));
        fraction = 0.90 + 0.10 * _ratio(i + 1, clusters.length);
        emit();
      }
      similar.sort(_groupsBySavings);
      estimated += similar.fold(0, (s, g) => s + g.reclaimableBytes);
      await _release();

      markDone([ScanCategory.duplicates, ScanCategory.similar]);
      fraction = 1;
      return finish(ScanEnd.completed);
    } on _CancelledSignal {
      return finish(ScanEnd.cancelled);
    } on MediaSourceException catch (e) {
      return finish(ScanEnd.interrupted, e.message);
    } catch (e) {
      return finish(ScanEnd.interrupted, e.toString());
    }
  }

  Future<void> _release() async {
    try {
      await source.releaseCaches();
    } catch (_) {}
  }

  /// Đo dung lượng, bỏ các mục không đọc được.
  Future<List<MediaItem>> _sizeAll(
    List<MediaItem> items,
    CancelToken cancel,
    void Function(int done)? onChunk,
  ) async {
    final sized = await _mapBounded<MediaItem, MediaItem>(
      items,
      (item) async {
        if (item.sizeBytes != null) return item;
        final bytes = await source.sizeOf(item);
        return bytes == null ? null : item.withSize(bytes);
      },
      cancel: cancel,
      onChunk: onChunk,
    );
    return sized.whereType<MediaItem>().toList();
  }

  Future<List<R?>> _mapBounded<T, R>(
    List<T> input,
    Future<R?> Function(T item) fn, {
    required CancelToken cancel,
    void Function(int done)? onChunk,
  }) async {
    final out = <R?>[];
    for (var i = 0; i < input.length; i += config.concurrency) {
      if (cancel.isCancelled) throw const _CancelledSignal();
      final end = math.min(i + config.concurrency, input.length);
      out.addAll(await Future.wait(input.sublist(i, end).map(fn)));
      onChunk?.call(out.length);
    }
    return out;
  }

  static double _ratio(int done, int total) => total == 0 ? 1.0 : done / total;

  static int _sum(List<MediaItem> items) =>
      items.fold(0, (s, i) => s + (i.sizeBytes ?? 0));

  static int _newestFirst(MediaItem a, MediaItem b) {
    final c = b.createdAt.compareTo(a.createdAt);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  static int _oldestFirst(MediaItem a, MediaItem b) {
    final c = a.createdAt.compareTo(b.createdAt);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  /// Bản nên giữ của nhóm tương tự: nhiều điểm ảnh nhất, rồi cũ nhất.
  static int _bestFirst(MediaItem a, MediaItem b) {
    final c = b.pixels.compareTo(a.pixels);
    return c != 0 ? c : _oldestFirst(a, b);
  }

  static int _byTimeThenId(_Hashed a, _Hashed b) =>
      _oldestFirst(a.item, b.item);

  static int _groupsBySavings(MediaGroup a, MediaGroup b) {
    final c = b.reclaimableBytes.compareTo(a.reclaimableBytes);
    return c != 0 ? c : a.id.compareTo(b.id);
  }
}
