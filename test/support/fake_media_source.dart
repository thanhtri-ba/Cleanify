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
      isScreenshot: screenshot,
    );

MediaItem video(String id, {Duration at = Duration.zero}) => MediaItem(
      id: id,
      kind: MediaKind.video,
      width: 1920,
      height: 1080,
      createdAt: t0.add(at),
    );

/// Tạo lưới độ sáng cho đúng dãy bit mong muốn (bit = trái < phải).
List<int> lumaForBits(List<int> bits) {
  assert(bits.length == 64);
  final luma = <int>[];
  var k = 0;
  for (var row = 0; row < lumaGridHeight; row++) {
    var v = 128;
    luma.add(v);
    for (var col = 0; col < lumaGridWidth - 1; col++) {
      v += bits[k++] == 1 ? 1 : -1;
      luma.add(v);
    }
  }
  return luma;
}

List<int> bitsOf(int pattern, {int flip = 0}) {
  // pattern 0: toàn 0; 1: toàn 1; 2: xen kẽ.
  final bits = List<int>.generate(64, (i) {
    switch (pattern) {
      case 0:
        return 0;
      case 1:
        return 1;
      default:
        return i % 2;
    }
  });
  for (var i = 0; i < flip; i++) {
    bits[i] = bits[i] == 1 ? 0 : 1;
  }
  return bits;
}

class FakeMediaSource implements MediaSource {
  FakeMediaSource(
    this.items, {
    Map<String, List<int>>? luma,
    Map<String, int>? sizes,
    this.throwOnLuma = false,
    this.throwOnCount = false,
    this.onSizeOf,
    this.onLuma,
  })  : luma = luma ?? {},
        sizes = sizes ?? {};

  final List<MediaItem> items;
  final Map<String, List<int>> luma;
  final Map<String, int> sizes;
  bool throwOnLuma;
  bool throwOnCount;
  Future<void> Function(MediaItem item)? onSizeOf;
  void Function(MediaItem item)? onLuma;

  final List<String> lumaCalls = [];
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
    onLuma?.call(item);
    if (throwOnLuma) throw const MediaSourceException('library unavailable');
    return luma[item.id];
  }

  @override
  Future<void> releaseCaches() async => releaseCalls++;
}
