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
}) =>
    MediaScanner(source, config: config).run(
      cancel: cancel ?? CancelToken(),
      onProgress: progress?.add,
    );

void main() {
  test('thư viện rỗng: hoàn tất, rỗng, đủ 4 danh mục', () async {
    final outcome = await scan(FakeMediaSource([]));
    expect(outcome.end, ScanEnd.completed);
    expect(outcome.result.isEmpty, isTrue);
    expect(outcome.result.completed, ScanCategory.values.toSet());
  });

  test('ảnh trùng: cùng hash, kích thước, dung lượng; giữ bản cũ nhất',
      () async {
    final source = FakeMediaSource(
      [
        photo('b', at: const Duration(hours: 5)),
        photo('a'),
        photo('c', at: const Duration(hours: 9)),
        photo('other', at: const Duration(days: 3)),
      ],
      luma: {
        'a': lumaForBits(bitsOf(2)),
        'b': lumaForBits(bitsOf(2)),
        'c': lumaForBits(bitsOf(2)),
        'other': lumaForBits(bitsOf(0)),
      },
      sizes: {'a': 5 * mb, 'b': 5 * mb, 'c': 5 * mb, 'other': 3 * mb},
    );

    final outcome = await scan(source);

    final groups = outcome.result.duplicateGroups;
    expect(groups, hasLength(1));
    expect(groups.single.items.map((e) => e.id), ['a', 'b', 'c']);
    expect(groups.single.keeper.id, 'a');
    expect(groups.single.reclaimableBytes, 10 * mb);
    expect(outcome.result.similarGroups, isEmpty);
  });

  test('cùng hash nhưng khác dung lượng: không phải ảnh trùng, thành tương tự',
      () async {
    final source = FakeMediaSource(
      [photo('a'), photo('b', at: const Duration(minutes: 1))],
      luma: {
        'a': lumaForBits(bitsOf(2)),
        'b': lumaForBits(bitsOf(2)),
      },
      sizes: {'a': 5 * mb, 'b': 6 * mb},
    );

    final outcome = await scan(source);

    expect(outcome.result.duplicateGroups, isEmpty);
    expect(outcome.result.similarGroups, hasLength(1));
  });

  test('ảnh tương tự: trong ngưỡng khoảng cách và cửa sổ thời gian', () async {
    final source = FakeMediaSource(
      [
        photo('small', w: 800, h: 600),
        photo('big', w: 2000, h: 1500, at: const Duration(minutes: 2)),
        photo('far', at: const Duration(minutes: 3)),
      ],
      luma: {
        'small': lumaForBits(bitsOf(2)),
        'big': lumaForBits(bitsOf(2, flip: 3)),
        'far': lumaForBits(bitsOf(2, flip: 30)),
      },
      sizes: {'small': 1 * mb, 'big': 4 * mb, 'far': 2 * mb},
    );

    final outcome = await scan(source);

    final group = outcome.result.similarGroups.single;
    expect(group.items.map((e) => e.id), ['big', 'small']);
    expect(group.keeper.id, 'big');
    expect(group.reclaimableBytes, 1 * mb);
  });

  test('giống nhau nhưng cách nhau quá cửa sổ thời gian thì không gom',
      () async {
    final source = FakeMediaSource(
      [photo('a'), photo('b', at: const Duration(hours: 2))],
      luma: {
        'a': lumaForBits(bitsOf(2)),
        'b': lumaForBits(bitsOf(2, flip: 1)),
      },
      sizes: {'a': 1 * mb, 'b': 2 * mb},
    );

    final outcome = await scan(source);

    expect(outcome.result.similarGroups, isEmpty);
  });

  test('ảnh chụp màn hình tách riêng và không bị băm', () async {
    final source = FakeMediaSource(
      [
        photo('s1', screenshot: true),
        photo('s2', screenshot: true, at: const Duration(minutes: 1)),
        photo('p1'),
      ],
      luma: {'p1': lumaForBits(bitsOf(2))},
      sizes: {'s1': 1 * mb, 's2': 2 * mb, 'p1': 3 * mb},
    );

    final outcome = await scan(source);

    expect(outcome.result.screenshots.map((e) => e.id), ['s2', 's1']);
    expect(outcome.result.bytes(ScanCategory.screenshots), 3 * mb);
    expect(source.lumaCalls, ['p1']);
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

  test('mục không đọc được (null) bị bỏ qua, không làm hỏng lượt quét', () async {
    final source = FakeMediaSource(
      [photo('a'), photo('b')],
      luma: {'a': lumaForBits(bitsOf(2))},
    );

    final outcome = await scan(source);

    expect(outcome.end, ScanEnd.completed);
    expect(outcome.result.isEmpty, isTrue);
  });

  test('mỗi mục chỉ thuộc một danh mục', () async {
    final source = FakeMediaSource(
      [
        photo('a'),
        photo('b'),
        photo('s', screenshot: true),
        video('v'),
      ],
      luma: {
        'a': lumaForBits(bitsOf(2)),
        'b': lumaForBits(bitsOf(2)),
      },
      sizes: {'a': mb, 'b': mb, 's': mb, 'v': 200 * mb},
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
      luma: {'p': lumaForBits(bitsOf(2))},
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
    expect(outcome.error, 'library unavailable');
    expect(outcome.result.completed,
        {ScanCategory.screenshots, ScanCategory.largeVideos});
    expect(outcome.result.screenshots, hasLength(1));
    expect(outcome.result.largeVideos, hasLength(1));
    expect(outcome.result.duplicateGroups, isEmpty);
    expect(outcome.hasResults, isTrue);
  });

  test('thư viện lỗi ngay từ đầu: interrupted, không có kết quả nào', () async {
    final outcome = await scan(FakeMediaSource([photo('a')], throwOnCount: true));

    expect(outcome.end, ScanEnd.interrupted);
    expect(outcome.hasResults, isFalse);
  });

  test('tiến độ không giảm, kết thúc ở 100% và đủ trạng thái done', () async {
    final progress = <ScanProgress>[];
    final source = FakeMediaSource(
      [for (var i = 0; i < 20; i++) photo('p$i', at: Duration(minutes: i))],
      luma: {
        for (var i = 0; i < 20; i++) 'p$i': lumaForBits(bitsOf(i % 3)),
      },
      sizes: {for (var i = 0; i < 20; i++) 'p$i': mb},
    );

    final outcome = await scan(
      source,
      progress: progress,
      config: const ScanConfig(pageSize: 7, concurrency: 3),
    );

    expect(outcome.end, ScanEnd.completed);
    for (var i = 1; i < progress.length; i++) {
      expect(progress[i].fraction, greaterThanOrEqualTo(progress[i - 1].fraction));
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
    expect(video('v').kind, MediaKind.video);
  });

  group('so sánh toàn thư viện (globalMaxDistance)', () {
    const global = ScanConfig(globalMaxDistance: 3);

    test('mặc định tắt: ảnh giống nhau cách xa thời gian không gom', () async {
      final source = FakeMediaSource(
        [photo('a'), photo('b', at: const Duration(days: 5))],
        luma: {
          'a': lumaForBits(bitsOf(2)),
          'b': lumaForBits(bitsOf(2, flip: 1)),
        },
        sizes: {'a': 2 * mb, 'b': 1 * mb},
      );

      final outcome = await scan(source);

      expect(outcome.result.similarGroups, isEmpty);
    });

    test('bật: gom ảnh đã nén lưu lại nhiều ngày sau, giữ bản lớn nhất',
        () async {
      final source = FakeMediaSource(
        [
          photo('orig', w: 4000, h: 3000),
          photo('forwarded', w: 1600, h: 1200, at: const Duration(days: 5)),
        ],
        luma: {
          'orig': lumaForBits(bitsOf(2)),
          'forwarded': lumaForBits(bitsOf(2, flip: 2)),
        },
        sizes: {'orig': 6 * mb, 'forwarded': 300 * 1000},
      );

      final outcome = await scan(source, config: global);

      final group = outcome.result.similarGroups.single;
      expect(group.items.map((e) => e.id), ['orig', 'forwarded']);
      expect(group.keeper.id, 'orig');
      expect(group.reclaimableBytes, 300 * 1000);
      expect(outcome.result.duplicateGroups, isEmpty);
    });

    test('khoảng cách 4 bit vượt giới hạn 3: không gom', () async {
      final source = FakeMediaSource(
        [photo('a'), photo('b', at: const Duration(days: 5))],
        luma: {
          'a': lumaForBits(bitsOf(2)),
          'b': lumaForBits(bitsOf(2, flip: 4)),
        },
        sizes: {'a': 2 * mb, 'b': 1 * mb},
      );

      final outcome = await scan(source, config: global);

      expect(outcome.result.similarGroups, isEmpty);
    });

    test('khác tỉ lệ khung hình: không gom', () async {
      final source = FakeMediaSource(
        [
          photo('landscape', w: 1000, h: 800),
          photo('portrait', w: 800, h: 1000, at: const Duration(days: 5)),
        ],
        luma: {
          'landscape': lumaForBits(bitsOf(2)),
          'portrait': lumaForBits(bitsOf(2, flip: 1)),
        },
        sizes: {'landscape': 2 * mb, 'portrait': 1 * mb},
      );

      final outcome = await scan(source, config: global);

      expect(outcome.result.similarGroups, isEmpty);
    });

    test('ảnh gần như phẳng (hash toàn 0 hoặc toàn 1) bị loại khỏi so toàn cục',
        () async {
      final source = FakeMediaSource(
        [
          photo('dark1'),
          photo('dark2', at: const Duration(days: 5)),
          photo('white1', at: const Duration(days: 9)),
          photo('white2', at: const Duration(days: 12)),
        ],
        luma: {
          'dark1': lumaForBits(bitsOf(0)),
          'dark2': lumaForBits(bitsOf(0)),
          'white1': lumaForBits(bitsOf(1)),
          'white2': lumaForBits(bitsOf(1)),
        },
        sizes: {
          'dark1': 1 * mb,
          'dark2': 2 * mb,
          'white1': 3 * mb,
          'white2': 4 * mb,
        },
      );

      final outcome = await scan(source, config: global);

      expect(outcome.result.similarGroups, isEmpty);
    });

    test('nối cụm theo cửa sổ thời gian với ảnh ngoài cửa sổ thành một nhóm',
        () async {
      final source = FakeMediaSource(
        [
          photo('a'),
          photo('b', at: const Duration(minutes: 1)),
          photo('c', at: const Duration(days: 3)),
          photo('unrelated', at: const Duration(days: 4)),
        ],
        luma: {
          'a': lumaForBits(bitsOf(2)),
          'b': lumaForBits(bitsOf(2, flip: 1)),
          'c': lumaForBits(bitsOf(2, flip: 2)),
          'unrelated': lumaForBits(bitsOf(2, flip: 30)),
        },
        sizes: {'a': 3 * mb, 'b': 2 * mb, 'c': 1 * mb, 'unrelated': 4 * mb},
      );

      final outcome = await scan(source, config: global);

      final group = outcome.result.similarGroups.single;
      expect(group.items.map((e) => e.id).toSet(), {'a', 'b', 'c'});
      expect(outcome.result.itemsOf(ScanCategory.similar).map((e) => e.id),
          isNot(contains('unrelated')));
    });

    test('ảnh trùng y hệt vẫn nằm ở danh mục trùng, không lặp sang tương tự',
        () async {
      final source = FakeMediaSource(
        [
          photo('a'),
          photo('b', at: const Duration(days: 2)),
          photo('c', at: const Duration(days: 4)),
        ],
        luma: {
          'a': lumaForBits(bitsOf(2)),
          'b': lumaForBits(bitsOf(2)),
          'c': lumaForBits(bitsOf(2, flip: 1)),
        },
        sizes: {'a': 5 * mb, 'b': 5 * mb, 'c': 2 * mb},
      );

      final outcome = await scan(source, config: global);

      expect(outcome.result.duplicateGroups.single.items.map((e) => e.id),
          ['a', 'b']);
      // 'c' chỉ còn một mình trong nhóm tương tự nên không tạo nhóm.
      expect(outcome.result.similarGroups, isEmpty);
    });

    test('hủy trong lúc so toàn cục: cancelled', () async {
      final cancel = CancelToken();
      final source = FakeMediaSource(
        [photo('a'), photo('b', at: const Duration(days: 5))],
        luma: {
          'a': lumaForBits(bitsOf(2)),
          'b': lumaForBits(bitsOf(2, flip: 1)),
        },
        sizes: {'a': 2 * mb, 'b': 1 * mb},
      );
      // Hủy ngay sau khi băm xong ảnh cuối.
      source.onLuma = (item) {
        if (item.id == 'b') cancel.cancel();
      };

      final outcome = await scan(source, cancel: cancel, config: global);

      expect(outcome.end, ScanEnd.cancelled);
      expect(outcome.result.completed, isNot(contains(ScanCategory.similar)));
    });
  });
}
