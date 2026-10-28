import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Email đang chờ xác minh (null nếu không có). Router dùng giá trị này để
/// chặn truy cập màn Verify email khi không có luồng đăng ký/đăng nhập nào.
class PendingVerificationNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String email) => state = email;
  void clear() => state = null;
}

final pendingVerificationEmailProvider =
    NotifierProvider<PendingVerificationNotifier, String?>(
  PendingVerificationNotifier.new,
);
