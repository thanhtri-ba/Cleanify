import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cleanify/features/scan/domain/feature_index.dart';
import 'package:cleanify/features/scan/domain/media_item.dart';
import 'package:cleanify/features/scan/domain/media_scanner.dart';
import 'package:cleanify/features/scan/domain/scan_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_media_source.dart';

const mb = 1000 * 1000;

Future<ScanOutcome> scan(
  FakeMediaSource source, {
  CancelToken? cancel,
  List<ScanProgress>? progress,
  ScanConfig config = const ScanConfig(),
  InMemoryHashStore? store,
}) =>
    MediaScanner(source, config: config, store: store).run(
      cancel: cancel ?? CancelToken(),
      onProgress: progress?.add,
    );

/// Nội dung file cỡ [size] byte, cùng [tag] thì giống hệt nhau.
Uint8List file(String tag, {int size = mb}) =>
    contentBytes(tag, size: size);

void main() {
  test('thư viện rỗng: hoàn tất, rỗng, đủ 4 danh mục', () async {
    final outcome = await scan(FakeMediaSource(const []));

    expect(outcome.end, ScanEnd.completed);
    expect(outcome.result.isEmpty, isTrue);
    expect(outcome.result.completed, ScanCategory.values.toSet());
  });

  test('ảnh trùng chính xác: cùng nội dung từng byte, giữ bản cũ nhất',
      () async {
    final same = file('same');
    final source = FakeMediaSource(
      [
        photo('new', at: const Duration(days: 2)),
        photo('old'),
        photo('other', at: const Duration(days: 1)),
      ],
      bytes: {'new': same, 'old': same, 'other': file('other')},
    );

    final outcome = await scan(source);

    expect(outcome.result.duplicateGroups, hasLength(1));
    final group = outcome.result.duplicateGroups.single;
    expect(group.items.map((e) => e.id), ['old', 'new']);
    expect(group.keeper.id, 'old');
    expect(group.reclaimableBytes, mb);
    expect(outcome.result.similarGroups, isEmpty);
  });

  test('khác một byte thì không phải ảnh trùng chính xác', () async {
    final a = file('same');
    final b = Uint8List.fromList([...a]..[10] ^= 1);
    final source = FakeMediaSource(
      [photo('a'), photo('b')],
      bytes: {'a': a, 'b': b},
    );

    final outcome = await scan(source);

    expect(outcome.result.duplicateGroups, isEmpty);
  });

  test('ảnh gần giống (khác byte, cùng cảnh) được gom bằng PDQ', () async {
    final base = patternLuma(3);
    final brighter = [for (final v in base) (v + 4).clamp(0, 255)];
    final source = FakeMediaSource(
      [photo('a'), photo('b', at: const Duration(days: 9))],
      luma: {'a': base, 'b': brighter},
    );

    final outcome = await scan(source);

    expect(outcome.result.duplicateGroups, isEmpty);
    expect(outcome.result.similarGroups, hasLength(1));
    expect(outcome.result.similarGroups.single.items.map((e) => e.id),
        ['a', 'b']);
  });

  test('ảnh khác cảnh không được gom là tương tự', () async {
    final source = FakeMediaSource(
      [photo('a'), photo('b')],
      luma: {'a': patternLuma(1), 'b': flatLuma(40)},
    );

    final outcome = await scan(source);

    expect(outcome.result.similarGroups, isEmpty);
  });

  test('ảnh không đọc được pixel (không có PDQ) không vào nhóm tương tự',
      () async {
    final source = FakeMediaSource(
      [photo('a'), photo('b')],
      luma: {'a': patternLuma(3)},
    );

    final outcome = await scan(source);

    expect(outcome.end, ScanEnd.completed);
    expect(outcome.result.similarGroups, isEmpty);
  });

  test('ảnh gần như phẳng (chất lượng PDQ thấp) không gom tương tự', () async {
    final source = FakeMediaSource(
      [photo('a'), photo('b')],
      luma: {'a': flatLuma(120), 'b': flatLuma(121)},
    );

    final outcome = await scan(source);

    expect(outcome.result.similarGroups, isEmpty);
  });

  test('ảnh chụp màn hình tách riêng và không bị băm', () async {
    final source = FakeMediaSource(
      [
        photo('s1', screenshot: true),
        photo('s2', screenshot: true, at: const Duration(minutes: 1)),
      ],
      sizes: {'s1': mb, 's2': mb},
    );

    final outcome = await scan(source);

    expect(outcome.result.screenshots.map((e) => e.id), ['s2', 's1']);
    expect(outcome.result.duplicateGroups, isEmpty);
    expect(outcome.result.similarGroups, isEmpty);
    expect(source.lumaCalls, isEmpty);
  });

  test('video lớn: chỉ lấy video từ ngưỡng trở lên, lớn nhất trước', () async {
    final source = FakeMediaSource(
      [video('v1'), video('v2'), video('v3'), video('v4')],
      sizes: {'v1': 149 * mb, 'v2': 150 * mb, 'v3': 900 * mb},
    );

    final outcome = await scan(source);

    expect(outcome.result.largeVideos.map((e) => e.id), ['v3', 'v2']);
    expect(outcome.result.bytes(ScanCategory.largeVideos), 1050 * mb);
  });

  test('mục không đọc được (null) bị bỏ qua, không làm hỏng lượt quét',
      () async {
    final source = FakeMediaSource([photo('a'), photo('b')]);

    final outcome = await scan(source);

    expect(outcome.end, ScanEnd.completed);
    expect(outcome.result.isEmpty, isTrue);
  });

  test('mỗi mục chỉ thuộc một danh mục', () async {
    final same = file('same');
    final source = FakeMediaSource(
      [
        photo('a'),
        photo('b'),
        photo('s', screenshot: true),
        video('v'),
      ],
      bytes: {'a': same, 'b': same},
      sizes: {'s': mb, 'v': 200 * mb},
    );

    final outcome = await scan(source);

    final seen = <String>[];
    for (final c in ScanCategory.values) {
      seen.addAll(outcome.result.itemsOf(c).map((e) => e.id));
    }
    expect(seen.toSet().length, seen.length);
    expect(seen.toSet(), {'a', 'b', 's', 'v'});
  });

  test('hủy giữa chừng: cancelled, giữ danh mục đã xong, không băm ảnh',
      () async {
    final cancel = CancelToken();
    final source = FakeMediaSource(
      [photo('s', screenshot: true), photo('p')],
      sizes: {'s': mb},
      // Hủy ngay khi đang đo ảnh chụp màn hình.
      onSizeOf: (_) async => cancel.cancel(),
    );

    final outcome = await scan(source, cancel: cancel);

    expect(outcome.end, ScanEnd.cancelled);
    expect(outcome.result.completed, contains(ScanCategory.screenshots));
    expect(outcome.result.completed, isNot(contains(ScanCategory.duplicates)));
    expect(outcome.result.completed, isNot(contains(ScanCategory.similar)));
    expect(source.lumaCalls, isEmpty);
  });

  test('thư viện lỗi khi băm: interrupted, giữ kết quả các danh mục đã xong',
      () async {
    final source = FakeMediaSource(
      [photo('s', screenshot: true), video('v'), photo('p')],
      sizes: {'s': 2 * mb, 'v': 300 * mb},
      throwOnLuma: true,
    );

    final outcome = await scan(source);

    expect(outcome.end, ScanEnd.interrupted);
    expect(outcome.error, contains('library unavailable'));
    expect(outcome.result.completed,
        {ScanCategory.screenshots, ScanCategory.largeVideos});
    expect(outcome.result.screenshots, hasLength(1));
    expect(outcome.result.largeVideos, hasLength(1));
    expect(outcome.result.duplicateGroups, isEmpty);
    expect(outcome.hasResults, isTrue);
  });

  test('thư viện lỗi ngay từ đầu: interrupted, không có kết quả nào', () async {
    final outcome =
        await scan(FakeMediaSource([photo('a')], throwOnCount: true));

    expect(outcome.end, ScanEnd.interrupted);
    expect(outcome.hasResults, isFalse);
  });

  test('tiến độ không giảm, kết thúc ở 100% và đủ trạng thái done', () async {
    final progress = <ScanProgress>[];
    final source = FakeMediaSource(
      [for (var i = 0; i < 20; i++) photo('p$i', at: Duration(minutes: i))],
      luma: {for (var i = 0; i < 20; i++) 'p$i': patternLuma(i)},
    );

    final outcome = await scan(
      source,
      progress: progress,
      config: const ScanConfig(pageSize: 7, concurrency: 3),
    );

    expect(outcome.end, ScanEnd.completed);
    for (var i = 1; i < progress.length; i++) {
      expect(
          progress[i].fraction, greaterThanOrEqualTo(progress[i - 1].fraction));
    }
    expect(progress.last.fraction, 1.0);
    expect(progress.last.itemsChecked, 20);
    expect(progress.last.statuses.values.every((s) => s == CategoryStatus.done),
        isTrue);
  });

  test('giải phóng cache sau mỗi giai đoạn', () async {
    final source = FakeMediaSource([photo('a')]);
    await scan(source);
    expect(source.releaseCalls, greaterThanOrEqualTo(3));
  });

  test('MediaKind của mục video không bị đưa vào băm', () async {
    final source = FakeMediaSource([video('v')], sizes: {'v': 10 * mb});
    await scan(source);
    expect(source.lumaCalls, isEmpty);
    expect(source.openCalls, 0);
    expect(video('v').kind, MediaKind.video);
  });

  group('kho hash (quét tăng dần)', () {
    test('lần quét thứ hai dùng lại hash đã lưu, không đọc file lần nữa',
        () async {
      final store = InMemoryHashStore();
      final source = FakeMediaSource(
        [photo('a'), photo('b', at: const Duration(days: 1))],
        luma: {'a': patternLuma(2), 'b': patternLuma(2)},
      );

      await scan(source, store: store);
      final firstOpens = source.openCalls;
      final second = await scan(source, store: store);

      expect(firstOpens, 2);
      expect(source.openCalls, firstOpens);
      expect(second.result.similarGroups, hasLength(1));
    });

    test('ảnh đã đổi ngày sửa thì được băm lại', () async {
      final store = InMemoryHashStore();
      final first = FakeMediaSource([photo('a')], luma: {'a': patternLuma(2)});
      await scan(first, store: store);

      final edited = MediaItem(
        id: 'a',
        kind: MediaKind.image,
        width: 1000,
        height: 800,
        createdAt: t0,
        modifiedAt: t0.add(const Duration(days: 5)),
      );
      final second = FakeMediaSource([edited], luma: {'a': patternLuma(9)});
      await scan(second, store: store);

      expect(second.openCalls, 1);
    });

    test('ảnh đã xoá khỏi thư viện bị bỏ khỏi kho', () async {
      final store = InMemoryHashStore();
      await scan(FakeMediaSource([photo('a'), photo('b')]), store: store);
      expect(store.rows.keys, containsAll(['a', 'b']));

      await scan(FakeMediaSource([photo('a')]), store: store);

      expect(store.rows.keys, ['a']);
    });
  });

  group('ORB: ảnh cắt và che', () {
    FeatureSet fs(int seed) {
      final rng = math.Random(seed);
      return FeatureSet(
        Uint8List.fromList(
          List.generate(60 * descriptorBytes, (_) => rng.nextInt(256)),
        ),
        Float32List(120),
      );
    }

    test('cặp có số điểm khớp đủ ngưỡng được gom thành nhóm tương tự', () async {
      final shared = fs(1);
      final source = FakeMediaSource(
        [photo('a'), photo('b', at: const Duration(days: 3)), photo('c')],
        features: {'a': shared, 'b': shared, 'c': fs(2)},
      );

      final outcome = await MediaScanner(
        source,
        matcher: _FakeMatcher((a, b) => 20),
      ).run(cancel: CancelToken());

      expect(outcome.result.similarGroups, hasLength(1));
      expect(outcome.result.similarGroups.single.items.map((e) => e.id),
          unorderedEquals(['a', 'b']));
    });

    test('số điểm khớp dưới ngưỡng thì không gom', () async {
      final shared = fs(1);
      final source = FakeMediaSource(
        [photo('a'), photo('b', at: const Duration(days: 3))],
        features: {'a': shared, 'b': shared},
      );

      final outcome = await MediaScanner(
        source,
        matcher: _FakeMatcher((a, b) => 5),
      ).run(cancel: CancelToken());

      expect(outcome.result.similarGroups, isEmpty);
    });

    test('không có matcher thì không dùng ORB', () async {
      final shared = fs(1);
      final source = FakeMediaSource(
        [photo('a'), photo('b', at: const Duration(days: 3))],
        features: {'a': shared, 'b': shared},
      );

      final outcome = await scan(source);

      expect(outcome.result.similarGroups, isEmpty);
    });
  });
}

class _FakeMatcher implements FeatureMatcher {
  _FakeMatcher(this.score);

  final int Function(FeatureSet a, FeatureSet b) score;

  @override
  int inliers(FeatureSet a, FeatureSet b) => score(a, b);
}
