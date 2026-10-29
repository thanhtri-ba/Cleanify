/// Disjoint Set Union theo chỉ số 0..size-1, có nén đường đi và gộp theo hạng.
class UnionFind {
  UnionFind(int size)
      : _parent = List<int>.generate(size, (i) => i),
        _rank = List<int>.filled(size, 0);

  final List<int> _parent;
  final List<int> _rank;

  int get size => _parent.length;

  /// Gốc của tập chứa [index].
  int find(int index) {
    var root = index;
    while (_parent[root] != root) {
      root = _parent[root];
    }
    var node = index;
    while (_parent[node] != root) {
      final next = _parent[node];
      _parent[node] = root;
      node = next;
    }
    return root;
  }

  /// Gộp hai tập. Trả về true nếu trước đó chúng khác tập.
  bool union(int a, int b) {
    final rootA = find(a);
    final rootB = find(b);
    if (rootA == rootB) return false;
    if (_rank[rootA] < _rank[rootB]) {
      _parent[rootA] = rootB;
    } else if (_rank[rootA] > _rank[rootB]) {
      _parent[rootB] = rootA;
    } else {
      _parent[rootB] = rootA;
      _rank[rootA]++;
    }
    return true;
  }

  bool connected(int a, int b) => find(a) == find(b);
}
