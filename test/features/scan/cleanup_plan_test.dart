import 'package:cleanify/features/scan/domain/cleanup_plan.dart';
import 'package:cleanify/features/scan/domain/media_item.dart';
import 'package:cleanify/features/scan/domain/scan_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_media_source.dart';

const mb = 1000 * 1000;

MediaItem sized(MediaItem item, int bytes) => item.withSize(bytes);

ScanResult sample() => ScanResult(
      duplicateGroups: [
        MediaGroup(id: 'd1', items: [
          sized(photo('d1a'), 4 * mb),
          sized(photo('d1b'), 4 * mb),
          sized(photo('d1c'), 4 * mb),
        ]),
      ],
      similarGroups: [
        MediaGroup(id: 's1', items: [
          sized(photo('s1a'), 3 * mb),
          sized(photo('s1b'), 2 * mb),
        ]),
      ],
      largeVideos: [sized(video('v1'), 200 * mb)],
      screenshots: [sized(photo('sc1', screenshot: true), 1 * mb)],
      completed: ScanCategory.values.toSet(),
    );

void main() {
  test('mặc định chọn mọi mục xóa được, giữ lại bản đầu mỗi nhóm', () {
    final plan = CleanupPlan.all(sample());

    expect(plan.selected, {'d1b', 'd1c', 's1b', 'v1', 'sc1'});
    expect(plan.isSelected('d1a'), isFalse);
    expect(plan.isSelected('s1a'), isFalse);
    expect(plan.bytes, 4 * mb + 4 * mb + 2 * mb + 200 * mb + 1 * mb);
    expect(plan.selectedCategories, ScanCategory.values);
  });

  test('tổng chọn khớp dung lượng có thể giải phóng của kết quả', () {
    final result = sample();
    expect(CleanupPlan.all(result).bytes, result.totalBytes);
  });

  test('không thể chọn hết mọi mục trong một nhóm', () {
    var plan = CleanupPlan.all(sample());

    expect(plan.canSelect('d1a'), isFalse);
    final after = plan.toggleItem('d1a');
    expect(after.isSelected('d1a'), isFalse);
    expect(after.selected, plan.selected);

    // Bỏ chọn một bản trùng thì mới được chọn bản đầu.
    plan = plan.toggleItem('d1c');
    expect(plan.canSelect('d1a'), isTrue);
    plan = plan.toggleItem('d1a');
    expect(plan.isSelected('d1a'), isTrue);
    expect(plan.isSelected('d1b'), isTrue);
    expect(plan.isSelected('d1c'), isFalse);
  });

  test('nhóm 2 mục: chọn bản đầu thì phải bỏ bản còn lại', () {
    var plan = CleanupPlan.all(sample());

    plan = plan.toggleItem('s1a');
    expect(plan.isSelected('s1a'), isFalse);

    plan = plan.toggleItem('s1b');
    expect(plan.isSelected('s1b'), isFalse);
    plan = plan.toggleItem('s1a');
    expect(plan.isSelected('s1a'), isTrue);
  });

  test('id không tồn tại không chọn được', () {
    final plan = CleanupPlan.all(sample());
    expect(plan.canSelect('nope'), isFalse);
    expect(plan.toggleItem('nope').selected, plan.selected);
  });

  test('toggleCategory bỏ chọn rồi chọn lại cả danh mục', () {
    var plan = CleanupPlan.all(sample());
    expect(plan.isCategoryFullySelected(ScanCategory.largeVideos), isTrue);

    plan = plan.toggleCategory(ScanCategory.largeVideos);
    expect(plan.isSelected('v1'), isFalse);
    expect(plan.selectedCategories, isNot(contains(ScanCategory.largeVideos)));

    plan = plan.toggleCategory(ScanCategory.largeVideos);
    expect(plan.isSelected('v1'), isTrue);
  });

  test('chọn danh mục nhóm không bao giờ chọn bản nên giữ', () {
    var plan = CleanupPlan.all(sample());
    plan = plan.toggleCategory(ScanCategory.duplicates);
    plan = plan.toggleCategory(ScanCategory.duplicates);
    expect(plan.isSelected('d1a'), isFalse);
    expect(plan.countFor(ScanCategory.duplicates), 2);
  });

  test('danh mục rỗng: toggle không làm gì', () {
    final empty = CleanupPlan.all(const ScanResult());
    expect(empty.isEmpty, isTrue);
    expect(empty.toggleCategory(ScanCategory.screenshots).isEmpty, isTrue);
    expect(empty.isCategoryFullySelected(ScanCategory.screenshots), isFalse);
  });

  test('bytesFor có thể giới hạn theo tập id đã xóa', () {
    final plan = CleanupPlan.all(sample());
    expect(plan.bytesFor(ScanCategory.duplicates), 8 * mb);
    expect(plan.bytesFor(ScanCategory.duplicates, only: {'d1b'}), 4 * mb);
  });

  group('ScanResult.without', () {
    test('bỏ mục đã xóa, giữ nhóm còn từ 2 mục, bỏ nhóm còn 1', () {
      final next = sample().without({'d1b', 's1b', 'v1'});

      expect(next.duplicateGroups.single.items.map((e) => e.id), ['d1a', 'd1c']);
      expect(next.similarGroups, isEmpty);
      expect(next.largeVideos, isEmpty);
      expect(next.screenshots, hasLength(1));
    });

    test('bản nên giữ bị xóa thì bản kế tiếp lên làm bản giữ', () {
      final next = sample().without({'d1a'});
      expect(next.duplicateGroups.single.keeper.id, 'd1b');
    });

    test('không đổi tập danh mục đã hoàn tất', () {
      expect(sample().without({'v1'}).completed, ScanCategory.values.toSet());
    });
  });
}
