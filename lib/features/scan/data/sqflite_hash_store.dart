import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../domain/hash_store.dart';

/// Kho hash lưu bằng SQLite (sqflite). Bảng `media_hash`:
/// - asset_id: khóa chính, định danh ảnh trong thư viện.
/// - modified_at, width, height, file_size: phát hiện ảnh đã đổi.
/// - sha256 (có index): gom nhóm trùng chính xác.
/// - pdq_hash (32 byte), pdq_quality: so khớp gần giống.
/// - scanned_at: thời điểm băm.
class SqfliteHashStore implements HashStore {
  SqfliteHashStore._(this._db);

  static const _table = 'media_hash';
  static const _chunk = 500;

  final Database _db;

  /// Mở (hoặc tạo) kho tại [path]. Test truyền [factory] của sqflite_common_ffi.
  static Future<SqfliteHashStore> open(
    String path, {
    DatabaseFactory? factory,
  }) async {
    final f = factory ?? databaseFactory;
    final db = await f.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onUpgrade: (db, oldVersion, _) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE $_table ADD COLUMN features BLOB');
          }
        },
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE $_table (
              asset_id TEXT PRIMARY KEY,
              modified_at INTEGER NOT NULL,
              width INTEGER NOT NULL,
              height INTEGER NOT NULL,
              file_size INTEGER NOT NULL,
              sha256 TEXT NOT NULL,
              pdq_hash BLOB NOT NULL,
              pdq_quality INTEGER NOT NULL,
              features BLOB,
              scanned_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_media_hash_sha256 ON $_table (sha256)',
          );
        },
      ),
    );
    return SqfliteHashStore._(db);
  }

  @override
  Future<Map<String, StoredHash>> loadAll() async {
    final rows = await _db.query(_table);
    return {
      for (final r in rows)
        r['asset_id'] as String: StoredHash(
          id: r['asset_id'] as String,
          modifiedAtMs: r['modified_at'] as int,
          width: r['width'] as int,
          height: r['height'] as int,
          fileSize: r['file_size'] as int,
          sha256: r['sha256'] as String,
          pdq: Uint8List.fromList(r['pdq_hash'] as List<int>),
          pdqQuality: r['pdq_quality'] as int,
          features: r['features'] == null
              ? null
              : Uint8List.fromList(r['features'] as List<int>),
        ),
    };
  }

  @override
  Future<void> saveAll(List<StoredHash> rows) async {
    if (rows.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      final batch = txn.batch();
      for (final h in rows) {
        batch.insert(
          _table,
          {
            'asset_id': h.id,
            'modified_at': h.modifiedAtMs,
            'width': h.width,
            'height': h.height,
            'file_size': h.fileSize,
            'sha256': h.sha256,
            'pdq_hash': h.pdq,
            'pdq_quality': h.pdqQuality,
            'features': h.features,
            'scanned_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> retainOnly(Set<String> ids) async {
    final stored = await _db.query(_table, columns: ['asset_id']);
    final stale = [
      for (final r in stored)
        if (!ids.contains(r['asset_id'])) r['asset_id'] as String,
    ];
    for (var i = 0; i < stale.length; i += _chunk) {
      final part = stale.sublist(i, (i + _chunk).clamp(0, stale.length));
      final marks = List.filled(part.length, '?').join(',');
      await _db.delete(_table, where: 'asset_id IN ($marks)', whereArgs: part);
    }
  }

  Future<void> close() => _db.close();
}
