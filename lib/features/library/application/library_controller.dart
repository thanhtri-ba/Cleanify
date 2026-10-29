import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scan/application/scan_providers.dart';
import '../../scan/domain/media_item.dart';

const libraryPageSize = 120;

class LibraryState {
  const LibraryState({
    this.items = const [],
    this.total = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.failed = false,
  });

  final List<MediaItem> items;

  /// Tổng số ảnh + video trong thư viện (kể cả chưa nạp).
  final int total;
  final bool isLoading;
  final bool hasMore;

  /// Không đọc được thư viện (mất quyền, thư viện tạm thời không truy cập được).
  final bool failed;

  bool get isEmpty => !isLoading && !failed && items.isEmpty;

  LibraryState copyWith({
    List<MediaItem>? items,
    int? total,
    bool? isLoading,
    bool? hasMore,
    bool? failed,
  }) =>
      LibraryState(
        items: items ?? this.items,
        total: total ?? this.total,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        failed: failed ?? this.failed,
      );
}

/// Duyệt toàn bộ thư viện theo từng trang để không nạp hàng nghìn mục một lúc.
class LibraryController extends Notifier<LibraryState> {
  int _nextPage = 0;
  int _generation = 0;

  @override
  LibraryState build() => const LibraryState();

  /// Nạp lại từ đầu (vào màn, kéo để làm mới, sau khi đã xóa ảnh).
  Future<void> reload() async {
    final generation = ++_generation;
    _nextPage = 0;
    state = const LibraryState(isLoading: true);
    try {
      final total = await ref.read(mediaSourceProvider).count();
      if (generation != _generation) return;
      state = LibraryState(total: total, isLoading: true);
    } catch (_) {
      if (generation != _generation) return;
      state = const LibraryState(failed: true, hasMore: false);
      return;
    }
    await _loadPage(generation);
  }

  /// Nạp trang kế tiếp; bỏ qua nếu đang nạp hoặc đã hết.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.failed) return;
    state = state.copyWith(isLoading: true);
    await _loadPage(_generation);
  }

  Future<void> _loadPage(int generation) async {
    try {
      final page = await ref
          .read(mediaSourceProvider)
          .page(_nextPage, libraryPageSize);
      if (generation != _generation) return;
      _nextPage++;
      final items = [...state.items, ...page];
      state = state.copyWith(
        items: items,
        isLoading: false,
        // Trang đầy chưa chắc còn thêm, nên dừng khi trang trả về ít hơn cỡ trang.
        hasMore: page.length >= libraryPageSize && items.length < state.total,
      );
    } catch (_) {
      if (generation != _generation) return;
      state = state.copyWith(isLoading: false, hasMore: false, failed: true);
    }
  }
}

final libraryControllerProvider =
    NotifierProvider<LibraryController, LibraryState>(LibraryController.new);
