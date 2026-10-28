import 'package:photo_manager/photo_manager.dart';

import '../domain/media_access.dart';

/// Cài đặt thật dựa trên plugin `photo_manager`.
class PhotoManagerGateway implements MediaAccessGateway {
  const PhotoManagerGateway();

  static MediaAccess _map(PermissionState state) {
    switch (state) {
      case PermissionState.authorized:
        return MediaAccess.granted;
      case PermissionState.limited:
        return MediaAccess.limited;
      case PermissionState.notDetermined:
        return MediaAccess.unknown;
      case PermissionState.denied:
      case PermissionState.restricted:
        return MediaAccess.denied;
    }
  }

  @override
  Future<MediaAccess> current() async => _map(
        await PhotoManager.getPermissionState(
          requestOption: const PermissionRequestOption(),
        ),
      );

  @override
  Future<MediaAccess> request() async =>
      _map(await PhotoManager.requestPermissionExtend());

  @override
  Future<void> openSettings() => PhotoManager.openSetting();

  @override
  Future<void> manageLimited() => PhotoManager.presentLimited();
}
