import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/preferences_provider.dart';
import '../data/photo_manager_gateway.dart';
import '../domain/media_access.dart';

final mediaAccessGatewayProvider =
    Provider<MediaAccessGateway>((ref) => const PhotoManagerGateway());

class MediaAccessState {
  const MediaAccessState({
    this.access = MediaAccess.unknown,
    this.isRequesting = false,
    this.hasRequested = false,
  });

  final MediaAccess access;
  final bool isRequesting;

  /// Đã gọi xin quyền ít nhất một lần trong phiên chạy này.
  final bool hasRequested;

  MediaAccessState copyWith({
    MediaAccess? access,
    bool? isRequesting,
    bool? hasRequested,
  }) {
    return MediaAccessState(
      access: access ?? this.access,
      isRequesting: isRequesting ?? this.isRequesting,
      hasRequested: hasRequested ?? this.hasRequested,
    );
  }
}

class MediaAccessController extends Notifier<MediaAccessState> {
  @override
  MediaAccessState build() => const MediaAccessState();

  MediaAccessGateway get _gateway => ref.read(mediaAccessGatewayProvider);

  /// Đọc lại trạng thái (không hiện hộp thoại). Lỗi plugin thì giữ nguyên.
  Future<void> refresh() async {
    try {
      final access = await _gateway.current();
      state = state.copyWith(access: access);
    } catch (_) {}
  }

  /// Xin quyền. Bỏ qua nếu đang có yêu cầu chạy (chống bấm đúp).
  Future<MediaAccess> request() async {
    if (state.isRequesting) return state.access;
    state = state.copyWith(isRequesting: true);
    try {
      final access = await _gateway.request();
      state = state.copyWith(
        access: access,
        isRequesting: false,
        hasRequested: true,
      );
    } catch (_) {
      // Không xin được thì coi như bị từ chối để người dùng có lối thoát.
      state = state.copyWith(
        access: MediaAccess.denied,
        isRequesting: false,
        hasRequested: true,
      );
    }
    return state.access;
  }

  Future<void> openSettings() async {
    try {
      await _gateway.openSettings();
    } catch (_) {}
  }

  Future<void> manageLimited() async {
    try {
      await _gateway.manageLimited();
    } catch (_) {}
    await refresh();
  }
}

final mediaAccessProvider =
    NotifierProvider<MediaAccessController, MediaAccessState>(
  MediaAccessController.new,
);

/// Đã hiển thị màn xin quyền ảnh ít nhất một lần (lưu bền).
class PhotoAccessPromptSeenNotifier extends Notifier<bool> {
  static const storageKey = 'photo_access_prompt_seen';

  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(storageKey) ?? false;

  Future<void> markSeen() async {
    if (state) return;
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(storageKey, true);
  }
}

final photoAccessPromptSeenProvider =
    NotifierProvider<PhotoAccessPromptSeenNotifier, bool>(
  PhotoAccessPromptSeenNotifier.new,
);
