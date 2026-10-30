import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'feature_index.dart';
import 'hash_store.dart';
import 'media_item.dart';
import 'media_source.dart';
import 'pdq.dart';
import 'scan_models.dart';
import 'union_find.dart';

class _CancelledSignal implements Exception {
  const _CancelledSignal();
}

/// Ảnh đã có hash: SHA-256 cho trùng chính xác, PDQ cho gần giống.
class _PhotoHash {
  const _PhotoHash(this.item, this.sha256, this.pdq, {this.features});

  /// Đã gắn dung lượng file.
  final MediaItem item;
  final String sha256;

  /// null khi không tính được PDQ (ảnh không đọc được pixel).
  final Pdq? pdq;

  /// Đặc trưng ORB; null khi không có matcher hoặc ảnh quá ít chi tiết.
  final FeatureSet? features;

  String get id => item.id;
}

/// Quét thư viện theo các giai đoạn:
/// liệt kê -> ảnh chụp màn hình -> video lớn -> băm ảnh -> trùng -> tương tự.
///
/// Mỗi mục thuộc đúng một danh mục (video lớn, ảnh chụp màn hình, ảnh trùng,
/// ảnh tương tự) nên không bị tính dung lượng hai lần.
///
/// - "Ảnh trùng": cùng SHA-256 của nội dung file. Đây là so sánh chính xác từng
///   byte, không phải heuristic.
/// - "Ảnh tương tự": PDQ 256 bit, khoảng cách Hamming <= `pdqMaxDistance`. Tìm
///   ứng viên bằng chỉ mục 32 đoạn 8 bit: nếu hai ảnh có khoảng cách <= 31 thì
///   ít nhất một đoạn trùng nhau, nên không bỏ sót ứng viên (trừ bucket bị chặn
///   bởi `pdqMaxBucketSize`).
/// - Với [store], hash của ảnh chưa đổi (cùng id, ngày sửa, kích thước) được
///   lấy lại, không đọc file gốc lần nữa.
class MediaScanner {
  MediaScanner(
    this.source, {
    this.config = const ScanConfig(),
    this.store,
    this.matcher,
  });

  final MediaSource source;
  final ScanConfig config;

  /// Kho lưu hash; null nghĩa là không lưu, mỗi lần quét tính lại.
  final HashStore? store;

  /// Xác nhận ảnh cắt/che bằng ORB + RANSAC; null nghĩa là chỉ dùng PDQ.
  final FeatureMatcher? matcher;

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
        statuses[c] = completed.contains(c)
            ? CategoryStatus.done
            : CategoryStatus.pending;
      }
      emit();
      return ScanOutcome(
        end: end,
        error: error,
        result: ScanResult(
          duplicateGroups: completed.contains(ScanCategory.duplicates)
              ? duplicates
              : const [],
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

      // 4. Băm ảnh (không gồm ảnh chụp màn hình). Hash đã lưu còn hợp lệ thì
      // dùng lại; ảnh mới hoặc đã đổi thì băm lại và ghi xuống kho theo lô.
      final photos = all
          .where((i) => i.kind == MediaKind.image && !i.isScreenshot)
          .toList();
      final cached = await _loadCache();
      final hashes = <_PhotoHash>[];
      final toSave = <StoredHash>[];
      final failed = <MediaItem>[];
      try {
        await _mapBounded<MediaItem, bool>(
          photos,
          (item) async {
            final hit = _cachedFor(item, cached);
            // Hash đã lưu với PDQ chất lượng 0 thường do thumbnail chưa sẵn sàng
            // khi quét trước đó (PDQ bị bỏ). Coi như chưa có để băm lại.
            if (hit != null && hit.pdqQuality > 0) {
              var ph = _fromStored(item, hit);
              if (matcher != null && ph.features == null) {
                // Đã có hash nhưng chưa có đặc trưng ORB: trích thêm rồi ghi lại.
                ph = _PhotoHash(
                  ph.item,
                  ph.sha256,
                  ph.pdq,
                  features: await source.featureSet(item),
                );
                toSave.add(_toStored(item, ph));
              }
              hashes.add(ph);
              return true;
            }
            final computed = await _hashPhotoSafely(item);
            if (computed == null) {
              failed.add(item);
              return true;
            }
            hashes.add(computed);
            toSave.add(_toStored(item, computed));
            if (toSave.length >= config.hashFlushSize) {
              final batch = List<StoredHash>.of(toSave);
              toSave.clear();
              await _saveRows(batch);
            }
            return true;
          },
          cancel: cancel,
          onChunk: (done) {
            fraction = 0.35 + 0.45 * _ratio(done, photos.length);
            emit();
          },
        );
      } finally {
        // Lưu phần đã băm dù quét xong, bị hủy hay lỗi giữa chừng.
        await _saveRows(toSave);
        toSave.clear();
      }
      // Thử lại ảnh lỗi một lần: ảnh iCloud hoặc file tạm thường đọc được ở lần sau.
      final retried = await _mapBounded<MediaItem, _PhotoHash>(
        failed,
        _hashPhotoSafely,
        cancel: cancel,
      );
      for (final ph in retried.whereType<_PhotoHash>()) {
        hashes.add(ph);
        toSave.add(_toStored(ph.item, ph));
      }
      await _saveRows(toSave);
      toSave.clear();
      await _pruneCache(all);
      hashes.sort((a, b) => _oldestFirst(a.item, b.item));

      // 5. Ảnh trùng: cùng SHA-256 nghĩa là cùng nội dung từng byte.
      final bySha = <String, List<MediaItem>>{};
      for (final h in hashes) {
        bySha.putIfAbsent(h.sha256, () => []).add(h.item);
      }
      final inDuplicates = <String>{};
      for (final same in bySha.values.where((l) => l.length >= 2)) {
        check();
        final ordered = [...same]..sort(_oldestFirst);
        duplicates.add(MediaGroup(id: 'dup_${ordered.first.id}', items: ordered));
        inDuplicates.addAll(ordered.map((e) => e.id));
      }
      duplicates.sort(_groupsBySavings);
      estimated += duplicates.fold(0, (s, g) => s + g.reclaimableBytes);
      fraction = 0.80;
      emit();
      await _release();

      // 6. Ảnh tương tự: PDQ gần nhau, và ORB khớp theo hình học (bắt ảnh cắt
      // và che). Ảnh đã nằm trong nhóm trùng thì bỏ qua.
      final pool = [
        for (final h in hashes)
          if (!inDuplicates.contains(h.id)) h,
      ];
      final clusters = await _similarClusters(pool, check);
      for (var i = 0; i < clusters.length; i++) {
        check();
        final sized = await _sizeAll(clusters[i], cancel, null);
        if (sized.length < 2) continue;
        final ordered = [...sized]..sort(_bestFirst);
        similar.add(MediaGroup(id: 'sim_${ordered.first.id}', items: ordered));
        fraction = 0.80 + 0.10 * _ratio(i + 1, clusters.length);
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
      return finish(ScanEnd.interrupted, e.toString());
    } catch (e) {
      return finish(ScanEnd.interrupted, e.toString());
    }
  }

  /// Lỗi của riêng một file (hỏng, không giải mã được) chỉ bỏ qua file đó.
  /// Lỗi của cả thư viện vẫn dừng lượt quét.
  Future<_PhotoHash?> _hashPhotoSafely(MediaItem item) async {
    try {
      return await _hashPhoto(item);
    } on MediaSourceException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  /// Băm một ảnh: SHA-256 đọc theo khối, PDQ từ ảnh xám 64x64, và đặc trưng ORB
  /// khi có matcher.
  Future<_PhotoHash?> _hashPhoto(MediaItem item) async {
    final stream = await source.openOriginal(item);
    if (stream == null) return null;
    var size = 0;
    final counted = stream.map((chunk) {
      size += chunk.length;
      return chunk;
    });
    final digest = await sha256.bind(counted).first;

    final luma = await source.lumaGrid(item);
    final pdq = luma == null || luma.length != lumaGridSize
        ? null
        : pdqFromLuma(luma);
    final features = matcher == null ? null : await source.featureSet(item);
    return _PhotoHash(
      item.withSize(size),
      digest.toString(),
      pdq,
      features: features,
    );
  }

  static StoredHash _toStored(MediaItem item, _PhotoHash ph) {
    final pdq = ph.pdq;
    return StoredHash(
      id: item.id,
      width: item.width,
      height: item.height,
      modifiedAtMs: item.modifiedAt?.millisecondsSinceEpoch ?? 0,
      fileSize: ph.item.sizeBytes ?? 0,
      sha256: ph.sha256,
      pdq: pdq?.bytes ?? Uint8List(pdqBytes),
      pdqQuality: pdq?.quality ?? 0,
      features: ph.features?.pack(),
    );
  }

  Future<Map<String, StoredHash>> _loadCache() async {
    final s = store;
    if (s == null) return const {};
    try {
      return await s.loadAll();
    } catch (_) {
      // Kho lỗi thì quét không dùng cache; kết quả vẫn đúng.
      return const {};
    }
  }

  Future<void> _saveRows(List<StoredHash> rows) async {
    final s = store;
    if (s == null || rows.isEmpty) return;
    try {
      await s.saveAll(rows);
    } catch (_) {
      // Không ghi được thì lần sau tính lại, không làm hỏng lượt quét.
    }
  }

  Future<void> _pruneCache(List<MediaItem> all) async {
    final s = store;
    if (s == null) return;
    try {
      await s.retainOnly({for (final i in all) i.id});
    } catch (_) {}
  }

  /// Hash đã lưu còn dùng được khi ảnh chưa đổi: cùng ngày sửa và kích thước.
  static StoredHash? _cachedFor(
    MediaItem item,
    Map<String, StoredHash> cached,
  ) {
    final hit = cached[item.id];
    final modified = item.modifiedAt?.millisecondsSinceEpoch;
    if (hit == null || modified == null) return null;
    if (hit.modifiedAtMs != modified ||
        hit.width != item.width ||
        hit.height != item.height) {
      return null;
    }
    return hit;
  }

  static _PhotoHash _fromStored(MediaItem item, StoredHash hit) {
    final bytes = hit.features;
    return _PhotoHash(
      item.withSize(hit.fileSize),
      hit.sha256,
      Pdq(hit.pdq, hit.pdqQuality),
      features: bytes == null ? null : FeatureSet.unpack(bytes),
    );
  }

  /// Gom ảnh tương tự: cạnh PDQ gần nhau (chỉ mục 32 đoạn 8 bit) và cạnh ORB
  /// khớp hình học (chỉ mục LSH chọn ứng viên, RANSAC xác nhận). Hợp các cạnh
  /// bằng union-find; mỗi thành phần liên thông là một nhóm.
  Future<List<List<MediaItem>>> _similarClusters(
    List<_PhotoHash> pool,
    void Function() check,
  ) async {
    final sets = UnionFind(pool.length);
    await _unionPdq(pool, sets, check);
    final m = matcher;
    if (m != null) {
      await _unionOrb(pool, sets, m, check);
    }
    final byRoot = <int, List<MediaItem>>{};
    for (var i = 0; i < pool.length; i++) {
      byRoot.putIfAbsent(sets.find(i), () => []).add(pool[i].item);
    }
    return [
      for (final members in byRoot.values)
        if (members.length >= 2) members,
    ];
  }

  Future<void> _unionPdq(
    List<_PhotoHash> pool,
    UnionFind sets,
    void Function() check,
  ) async {
    final eligible = [
      for (var i = 0; i < pool.length; i++)
        if (pool[i].pdq != null && pool[i].pdq!.quality >= config.pdqMinQuality)
          i,
    ];
    final buckets = <int, List<int>>{};
    for (var e = 0; e < eligible.length; e++) {
      final bytes = pool[eligible[e]].pdq!.bytes;
      for (var b = 0; b < pdqBytes; b++) {
        buckets.putIfAbsent(b * 256 + bytes[b], () => []).add(eligible[e]);
      }
      if (e % 500 == 0) {
        check();
        await Future<void>.delayed(Duration.zero);
      }
    }

    final seen = <int>{};
    var processed = 0;
    for (final members in buckets.values) {
      if (members.length < 2 || members.length > config.pdqMaxBucketSize) {
        continue;
      }
      for (var x = 0; x < members.length; x++) {
        for (var y = x + 1; y < members.length; y++) {
          final i = members[x];
          final j = members[y];
          if (!seen.add(i * pool.length + j)) continue;
          if (pool[i].pdq!.distanceTo(pool[j].pdq!) <= config.pdqMaxDistance) {
            sets.union(i, j);
          }
        }
      }
      if (++processed % 200 == 0) {
        check();
        await Future<void>.delayed(Duration.zero);
      }
    }
  }

  Future<void> _unionOrb(
    List<_PhotoHash> pool,
    UnionFind sets,
    FeatureMatcher matcher,
    void Function() check,
  ) async {
    final eligible = [
      for (var i = 0; i < pool.length; i++)
        if (pool[i].features != null) i,
    ];
    if (eligible.length < 2) return;
    final features = [for (final i in eligible) pool[i].features!];
    final index = LshIndex.build(features);
    // Ứng viên top-K của từng ảnh. Chỉ nối cạnh ORB khi hai ảnh đều nằm trong
    // top-K của nhau: giảm cạnh lạc khiến cụm lan sang ảnh khác cảnh.
    final candidates = List<Set<int>>.generate(eligible.length, (_) => <int>{});
    for (var e = 0; e < eligible.length; e++) {
      candidates[e].addAll(
        index.nearest(features[e], self: e, k: config.orbTopK),
      );
      if (e % 200 == 0) {
        check();
        await Future<void>.delayed(Duration.zero);
      }
    }
    final tried = <int>{};
    for (var e = 0; e < eligible.length; e++) {
      final i = eligible[e];
      for (final int c in candidates[e]) {
        if (!candidates[c].contains(e)) continue;
        final j = eligible[c];
        if (sets.find(i) == sets.find(j)) continue;
        final key = math.min(e, c) * eligible.length + math.max(e, c) as int;
        if (!tried.add(key)) continue;
        if (matcher.inliers(features[e], features[c]) >=
            config.orbMinInliers) {
          sets.union(i, j);
        }
      }
      if (e % 200 == 0) {
        check();
        await Future<void>.delayed(Duration.zero);
      }
    }
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

  Future<void> _release() async {
    try {
      await source.releaseCaches();
    } catch (_) {}
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

  static int _groupsBySavings(MediaGroup a, MediaGroup b) {
    final c = b.reclaimableBytes.compareTo(a.reclaimableBytes);
    return c != 0 ? c : a.id.compareTo(b.id);
  }
}
