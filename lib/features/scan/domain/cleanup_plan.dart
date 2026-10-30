import 'media_item.dart';
import 'scan_models.dart';

/// Tập mục người dùng chọn để xóa.
///
/// Bất biến: với nhóm ảnh trùng/tương tự, luôn còn ít nhất một mục KHÔNG được
/// chọn trong mỗi nhóm, nên không bao giờ xóa hết mọi bản của một bức ảnh.
class CleanupPlan {
  CleanupPlan._(this.result, this.selected, this._index);

  /// Mặc định chọn mọi mục xóa được: bản trùng (trừ bản nên giữ), video lớn,
  /// ảnh chụp màn hình.
  factory CleanupPlan.all(ScanResult result) {
    final index = _Index(result);
    final selected = <String>{
      for (final c in ScanCategory.values) ...index.selectable(c),
    };
    return CleanupPlan._(result, Set.unmodifiable(selected), index);
  }

  /// Chỉ chọn các mục trong [ids] mà xóa được (bản nên giữ của mỗi nhóm không
  /// bao giờ nằm trong tập xóa nên bất biến luôn được giữ).
  factory CleanupPlan.only(ScanResult result, Set<String> ids) {
    final index = _Index(result);
    final allowed = <String>{
      for (final c in ScanCategory.values) ...index.selectable(c),
    };
    return CleanupPlan._(
      result,
      Set.unmodifiable(ids.where(allowed.contains).toSet()),
      index,
    );
  }

  final ScanResult result;
  final Set<String> selected;
  final _Index _index;

  int get count => selected.length;
  bool get isEmpty => selected.isEmpty;

  bool isSelected(String id) => selected.contains(id);

  Iterable<String> selectableIds(ScanCategory category) =>
      _index.selectable(category);

  /// Các id đã chọn theo thứ tự ổn định.
  List<String> get orderedIds => selected.toList()..sort();

  int get bytes => _bytesOf(selected);

  int bytesOfId(String id) => _index.items[id]?.sizeBytes ?? 0;

  int bytesFor(ScanCategory category, {Set<String>? only}) {
    final ids = selected.where((id) => _index.categoryOf[id] == category);
    return _bytesOf(only == null ? ids : ids.where(only.contains));
  }

  int countFor(ScanCategory category) =>
      selected.where((id) => _index.categoryOf[id] == category).length;

  /// Danh mục đang có ít nhất một mục được chọn.
  List<ScanCategory> get selectedCategories => [
        for (final c in ScanCategory.values)
          if (countFor(c) > 0) c,
      ];

  /// Danh mục được chọn đủ mọi mục xóa được (và có mục để chọn).
  bool isCategoryFullySelected(ScanCategory category) {
    final all = _index.selectable(category);
    return all.isNotEmpty && all.every(selected.contains);
  }

  CleanupPlan toggleCategory(ScanCategory category) {
    final all = _index.selectable(category).toSet();
    if (all.isEmpty) return this;
    final next = {...selected};
    if (isCategoryFullySelected(category)) {
      next.removeAll(all);
    } else {
      next.addAll(all);
    }
    return CleanupPlan._(result, Set.unmodifiable(next), _index);
  }

  /// Có thể chọn mục này mà vẫn chừa lại ít nhất một mục trong nhóm không.
  bool canSelect(String id) {
    if (!_index.categoryOf.containsKey(id)) return false;
    final group = _index.groupOf[id];
    if (group == null) return true;
    final selectedInGroup =
        group.items.where((i) => selected.contains(i.id)).length;
    return selectedInGroup < group.items.length - 1;
  }

  /// Đảo trạng thái chọn của một mục. Nếu việc chọn vi phạm bất biến của nhóm
  /// thì giữ nguyên kế hoạch.
  CleanupPlan toggleItem(String id) {
    if (selected.contains(id)) {
      return CleanupPlan._(
        result,
        Set.unmodifiable({...selected}..remove(id)),
        _index,
      );
    }
    if (!canSelect(id)) return this;
    return CleanupPlan._(result, Set.unmodifiable({...selected, id}), _index);
  }

  int _bytesOf(Iterable<String> ids) =>
      ids.fold(0, (s, id) => s + (_index.items[id]?.sizeBytes ?? 0));
}

class _Index {
  _Index(ScanResult result) {
    void addGroups(List<MediaGroup> groups, ScanCategory category) {
      for (final g in groups) {
        for (final item in g.items) {
          items[item.id] = item;
          categoryOf[item.id] = category;
          groupOf[item.id] = g;
        }
      }
    }

    // Một mục có thể vừa ở trong nhóm vừa là ảnh chụp màn hình (vd. hai
    // screenshot giống hệt). Khi đó chỉ áp luật của nhóm, nếu không bản nên
    // giữ của nhóm sẽ bị chọn xóa qua danh mục kia.
    void addItems(List<MediaItem> list, ScanCategory category) {
      for (final item in list) {
        items.putIfAbsent(item.id, () => item);
        categoryOf.putIfAbsent(item.id, () => category);
      }
    }

    Iterable<String> ungrouped(List<MediaItem> list) =>
        list.map((i) => i.id).where((id) => !groupOf.containsKey(id));

    addGroups(result.duplicateGroups, ScanCategory.duplicates);
    addGroups(result.similarGroups, ScanCategory.similar);
    addItems(result.largeVideos, ScanCategory.largeVideos);
    addItems(result.screenshots, ScanCategory.screenshots);

    for (final g in result.duplicateGroups) {
      _selectable[ScanCategory.duplicates]!
          .addAll(g.removable.map((i) => i.id));
    }
    for (final g in result.similarGroups) {
      _selectable[ScanCategory.similar]!.addAll(g.removable.map((i) => i.id));
    }
    _selectable[ScanCategory.largeVideos]!
        .addAll(ungrouped(result.largeVideos));
    _selectable[ScanCategory.screenshots]!
        .addAll(ungrouped(result.screenshots));
  }

  final Map<String, MediaItem> items = {};
  final Map<String, ScanCategory> categoryOf = {};
  final Map<String, MediaGroup> groupOf = {};
  final Map<ScanCategory, List<String>> _selectable = {
    for (final c in ScanCategory.values) c: <String>[],
  };

  List<String> selectable(ScanCategory category) => _selectable[category]!;
}
