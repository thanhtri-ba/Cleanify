import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cleanify/features/scan/domain/feature_index.dart';
import 'package:cleanify/features/scan/domain/hash_store.dart';
import 'package:cleanify/features/scan/domain/media_item.dart';
import 'package:cleanify/features/scan/domain/media_source.dart';

final DateTime t0 = DateTime(2026, 1, 1, 12);

MediaItem photo(
  String id, {
  int w = 1000,
  int h = 800,
  Duration at = Duration.zero,
  bool screenshot = false,
}) =>
    MediaItem(
      id: id,
      kind: MediaKind.image,
      width: w,
      height: h,
      createdAt: t0.add(at),
      modifiedAt: t0.add(at),
      isScreenshot: screenshot,
    );

MediaItem video(String id, {Duration at = Duration.zero}) => MediaItem(
      id: id,
      kind: MediaKind.video,
      width: 1920,
      height: 1080,
      createdAt: t0.add(at),
      modifiedAt: t0.add(at),
    );

/// Ảnh xám 64x64 phẳng, mọi điểm bằng [v].
List<int> flatLuma(int v) => List.filled(lumaGridSize, v);

/// Ảnh xám 64x64 có cấu trúc, khác nhau theo [seed] (sóng hình sin).
List<int> patternLuma(int seed) {
  final a = 0.10 + 0.03 * (seed % 7);
  final b = 0.07 + 0.02 * (seed % 5);
  return [
    for (var y = 0; y < lumaSide; y++)
      for (var x = 0; x < lumaSide; x++)
        (128 + 60 * math.sin(a * x + b * y) + 30 * math.sin(0.05 * x * y / 8))
            .round()
            .clamp(0, 255),
  ];
}

/// Nội dung file giả: cùng [tag] thì cùng byte, khác [tag] thì khác byte.
Uint8List contentBytes(String tag, {int size = 1000}) {
  final seed = utf8.encode(tag);
  return Uint8List.fromList([
    for (var i = 0; i < size; i++) seed[i % seed.length] ^ (i & 0xff),
  ]);
}

class InMemoryHashStore implements HashStore {
  final Map<String, StoredHash> rows = {};
  int saveCalls = 0;

  @override
  Future<Map<String, StoredHash>> loadAll() async => Map.of(rows);

  @override
  Future<void> saveAll(List<StoredHash> batch) async {
    saveCalls++;
    for (final r in batch) {
      rows[r.id] = r;
    }
  }

  @override
  Future<void> retainOnly(Set<String> ids) async =>
      rows.removeWhere((k, _) => !ids.contains(k));
}

class FakeMediaSource implements MediaSource {
  FakeMediaSource(
    this.items, {
    Map<String, List<int>>? luma,
    Map<String, int>? sizes,
    Map<String, Uint8List>? bytes,
    Map<String, FeatureSet>? features,
    this.throwOnLuma = false,
    this.throwOnCount = false,
    this.onSizeOf,
    this.onLuma,
  })  : luma = luma ?? {},
        sizes = sizes ?? {},
        bytes = bytes ?? {},
        features = features ?? {};

  final List<MediaItem> items;
  final Map<String, List<int>> luma;
  final Map<String, int> sizes;

  /// Nội dung file gốc theo id. Mục không có thì dùng nội dung riêng theo id.
  final Map<String, Uint8List> bytes;

  /// Đặc trưng ORB theo id; mục không có thì không trích được.
  final Map<String, FeatureSet> features;
  bool throwOnLuma;
  bool throwOnCount;
  Future<void> Function(MediaItem item)? onSizeOf;
  Future<void> Function(MediaItem item)? onLuma;

  final List<String> lumaCalls = [];
  int openCalls = 0;
  int releaseCalls = 0;

  @override
  Future<int> count() async {
    if (throwOnCount) throw const MediaSourceException('library unavailable');
    return items.length;
  }

  @override
  Future<List<MediaItem>> page(int page, int pageSize) async {
    final start = page * pageSize;
    if (start >= items.length) return const [];
    final end = (start + pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  @override
  Future<int?> sizeOf(MediaItem item) async {
    await onSizeOf?.call(item);
    return sizes[item.id];
  }

  @override
  Future<List<int>?> lumaGrid(MediaItem item) async {
    lumaCalls.add(item.id);
    await onLuma?.call(item);
    if (throwOnLuma) throw const MediaSourceException('library unavailable');
    return luma[item.id];
  }

  @override
  Future<FeatureSet?> featureSet(MediaItem item) async => features[item.id];

  @override
  Future<Stream<List<int>>?> openOriginal(MediaItem item) async {
    openCalls++;
    return Stream.value(bytes[item.id] ?? contentBytes(item.id));
  }

  @override
  Future<void> releaseCaches() async => releaseCalls++;
}
