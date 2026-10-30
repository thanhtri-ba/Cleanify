import 'pdq.dart';

/// Cây BK theo khoảng cách Hamming của PDQ: tìm mọi hash nằm trong một bán
/// kính. Không bỏ sót cặp nào và không cần giới hạn kích thước bucket. Với
/// bán kính nhỏ (31 trên 256 bit) chỉ duyệt một phần nhỏ cây.
class PdqBkTree {
  final List<Pdq> _hashes = [];
  final List<int> _ids = [];
  // Mỗi nút: khoảng cách tới nút con -> chỉ số nút con.
  final List<Map<int, int>> _children = [];

  void add(Pdq hash, int id) {
    final node = _hashes.length;
    _hashes.add(hash);
    _ids.add(id);
    _children.add({});
    if (node == 0) return;
    var cur = 0;
    while (true) {
      final d = _hashes[cur].distanceTo(hash);
      final next = _children[cur][d];
      if (next == null) {
        _children[cur][d] = node;
        return;
      }
      cur = next;
    }
  }

  /// Các id có khoảng cách Hamming tới [hash] không vượt [radius].
  List<int> query(Pdq hash, int radius) {
    final out = <int>[];
    if (_hashes.isEmpty) return out;
    final stack = <int>[0];
    while (stack.isNotEmpty) {
      final n = stack.removeLast();
      final d = _hashes[n].distanceTo(hash);
      if (d <= radius) out.add(_ids[n]);
      for (final entry in _children[n].entries) {
        // Bất đẳng thức tam giác: chỉ cần thăm con có |k - d| <= radius.
        if ((entry.key - d).abs() <= radius) stack.add(entry.value);
      }
    }
    return out;
  }
}
