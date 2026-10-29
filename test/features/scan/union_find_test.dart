import 'package:cleanify/features/scan/domain/union_find.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ban đầu mỗi phần tử một tập riêng', () {
    final sets = UnionFind(4);
    expect(sets.size, 4);
    for (var i = 0; i < 4; i++) {
      expect(sets.find(i), i);
    }
    expect(sets.connected(0, 1), isFalse);
  });

  test('A~B, B~C, C~D gom thành một nhóm', () {
    final sets = UnionFind(6);
    expect(sets.union(0, 1), isTrue);
    expect(sets.union(1, 2), isTrue);
    expect(sets.union(2, 3), isTrue);
    expect(sets.connected(0, 3), isTrue);
    expect(sets.connected(0, 4), isFalse);
    expect(sets.connected(4, 5), isFalse);
  });

  test('union lặp lại trả về false và không đổi nhóm', () {
    final sets = UnionFind(3);
    expect(sets.union(0, 1), isTrue);
    expect(sets.union(1, 0), isFalse);
    expect(sets.union(0, 0), isFalse);
    expect(sets.connected(0, 1), isTrue);
  });

  test('chuỗi dài vẫn tìm gốc đúng', () {
    final sets = UnionFind(1000);
    for (var i = 0; i < 999; i++) {
      sets.union(i, i + 1);
    }
    final root = sets.find(0);
    for (var i = 0; i < 1000; i++) {
      expect(sets.find(i), root);
    }
  });
}
