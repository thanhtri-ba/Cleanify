/// 'example@gmail.com' -> 'e••••@gmail.com'. Không rò rỉ phần tên đầy đủ.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return '••••';
  final local = email.substring(0, at);
  final domain = email.substring(at + 1);
  return '${local[0]}••••@$domain';
}
