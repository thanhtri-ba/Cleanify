/// Lỗi của từng trường nhập. UI chịu trách nhiệm ánh xạ sang chuỗi hiển thị.
enum FieldError {
  emailRequired,
  emailInvalid,
  passwordRequired,
  passwordWeak,
  nameRequired,
  nameTooLong,
}

abstract final class Validators {
  static const maxEmailLength = 254;
  static const maxNameLength = 80;
  static const minPasswordLength = 8;
  static const maxPasswordLength = 128;

  // Không hỗ trợ email quốc tế hóa (IDN); chấp nhận hạn chế này ở bản đầu.
  static final RegExp _emailPattern = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$",
  );
  static final RegExp _upper = RegExp(r'[A-Z]');
  static final RegExp _lower = RegExp(r'[a-z]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _spaces = RegExp(r'\s+');

  static String normalizeEmail(String value) => value.trim().toLowerCase();

  static String normalizeName(String value) =>
      value.trim().replaceAll(_spaces, ' ');

  static FieldError? email(String value) {
    final email = value.trim();
    if (email.isEmpty) return FieldError.emailRequired;
    if (email.length > maxEmailLength || !_emailPattern.hasMatch(email)) {
      return FieldError.emailInvalid;
    }
    return null;
  }

  /// Dùng khi đăng nhập: chỉ yêu cầu có nhập, không áp quy tắc độ mạnh.
  static FieldError? requiredPassword(String value) =>
      value.isEmpty ? FieldError.passwordRequired : null;

  /// Dùng khi tạo tài khoản: >= 8 ký tự, có chữ hoa, chữ thường và số.
  static FieldError? newPassword(String value) {
    if (value.isEmpty) return FieldError.passwordRequired;
    if (value.length < minPasswordLength || value.length > maxPasswordLength) {
      return FieldError.passwordWeak;
    }
    if (!_upper.hasMatch(value) ||
        !_lower.hasMatch(value) ||
        !_digit.hasMatch(value)) {
      return FieldError.passwordWeak;
    }
    return null;
  }

  static FieldError? name(String value) {
    final name = normalizeName(value);
    if (name.isEmpty) return FieldError.nameRequired;
    if (name.length > maxNameLength) return FieldError.nameTooLong;
    return null;
  }
}
