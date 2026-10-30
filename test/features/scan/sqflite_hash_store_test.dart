import 'dart:typed_data';

import 'package:cleanify/features/scan/data/sqflite_hash_store.dart';
import 'package:cleanify/features/scan/domain/hash_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

StoredHash row(String id, {String sha = 'aa', int modified = 1}) => StoredHash(
      id: id,
      width: 1000,
      height: 800,
      modifiedAtMs: modified,
      fileSize: 1234,
      sha256: sha,
      pdq: Uint8List.fromList(List.generate(32, (i) => i)),
      pdqQuality: 77,
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  Future<SqfliteHashStore> open() => SqfliteHashStore.open(
        inMemoryDatabasePath,
        factory: databaseFactoryFfi,
      );

  test('lưu rồi đọc lại đúng từng trường, PDQ giữ nguyên 32 byte', () async {
    final store = await open();
    await store.saveAll([row('a', sha: 'x1'), row('b', sha: 'x2')]);

    final loaded = await store.loadAll();

    expect(loaded.keys, unorderedEquals(['a', 'b']));
    final a = loaded['a']!;
    expect(a.sha256, 'x1');
    expect(a.fileSize, 1234);
    expect(a.modifiedAtMs, 1);
    expect(a.pdqQuality, 77);
    expect(a.pdq, List.generate(32, (i) => i));
    await store.close();
  });

  test('ghi trùng khóa thì ghi đè (không nhân đôi dòng)', () async {
    final store = await open();
    await store.saveAll([row('a', sha: 'old')]);
    await store.saveAll([row('a', sha: 'new')]);

    final loaded = await store.loadAll();

    expect(loaded, hasLength(1));
    expect(loaded['a']!.sha256, 'new');
    await store.close();
  });

  test('retainOnly xoá dòng không còn trong thư viện', () async {
    final store = await open();
    await store.saveAll([row('a'), row('b'), row('c')]);

    await store.retainOnly({'a', 'c'});

    expect((await store.loadAll()).keys, unorderedEquals(['a', 'c']));
    await store.close();
  });

  test('retainOnly xử lý được danh sách lớn hơn một lô', () async {
    final store = await open();
    final rows = [for (var i = 0; i < 1200; i++) row('id$i')];
    await store.saveAll(rows);

    await store.retainOnly({'id5', 'id1199'});

    expect((await store.loadAll()).keys, unorderedEquals(['id5', 'id1199']));
    await store.close();
  });

  test('lưu và đọc lại đặc trưng ORB (cột features)', () async {
    final store = await open();
    final feat = Uint8List.fromList(List.generate(40, (i) => i));
    await store.saveAll([
      StoredHash(
        id: 'f',
        width: 10,
        height: 10,
        modifiedAtMs: 1,
        fileSize: 5,
        sha256: 'z',
        pdq: Uint8List(32),
        pdqQuality: 1,
        features: feat,
      ),
      row('plain'),
    ]);

    final loaded = await store.loadAll();

    expect(loaded['f']!.features, feat);
    expect(loaded['plain']!.features, isNull);
    await store.close();
  });
}
