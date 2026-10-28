/// Trạng thái quyền truy cập thư viện ảnh/video.
enum MediaAccess {
  /// Chưa hỏi (iOS) hoặc chưa xác định được.
  unknown,
  granted,

  /// Chỉ truy cập các mục người dùng đã chọn.
  limited,
  denied,
}

/// Cổng truy cập quyền ảnh/video, tách khỏi plugin để dễ kiểm thử.
abstract interface class MediaAccessGateway {
  /// Đọc trạng thái hiện tại, KHÔNG hiện hộp thoại xin quyền.
  Future<MediaAccess> current();

  /// Hiện hộp thoại xin quyền của hệ điều hành.
  Future<MediaAccess> request();

  Future<void> openSettings();

  /// Mở bộ chọn lại các mục được cấp (chế độ limited).
  Future<void> manageLimited();
}

/// Màn nào cần hiển thị cho một trạng thái quyền.
enum PhotoAccessView { intro, limited, denied, granted }

/// Quy tắc chọn màn, tách thành hàm thuần để kiểm thử.
///
/// Android không có trạng thái "chưa hỏi": trước khi xin lần nào nó báo
/// `denied`. Vì vậy `denied` chỉ được coi là bị từ chối thật khi đã từng xin
/// trong phiên này ([hasRequested]) hoặc khi đang ở iOS (có `unknown` riêng).
PhotoAccessView resolvePhotoAccessView(
  MediaAccess access, {
  required bool hasRequested,
  required bool isIos,
}) {
  switch (access) {
    case MediaAccess.granted:
      return PhotoAccessView.granted;
    case MediaAccess.limited:
      return PhotoAccessView.limited;
    case MediaAccess.unknown:
      return PhotoAccessView.intro;
    case MediaAccess.denied:
      return (hasRequested || isIos)
          ? PhotoAccessView.denied
          : PhotoAccessView.intro;
  }
}
