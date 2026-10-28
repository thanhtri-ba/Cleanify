/// Số liệu dung lượng đã tách phần số và đơn vị (để hiển thị số lớn + đơn vị nhỏ).
class ByteSize {
  const ByteSize(this.value, this.unit);

  final String value;
  final String unit;

  @override
  String toString() => '$value $unit';

  @override
  bool operator ==(Object other) =>
      other is ByteSize && other.value == value && other.unit == unit;

  @override
  int get hashCode => Object.hash(value, unit);
}

const int _kb = 1000;
const int _mb = 1000 * _kb;
const int _gb = 1000 * _mb;

/// Dùng hệ thập phân (1 GB = 1000 MB) giống cách iOS/Android hiển thị dung lượng.
/// GB làm tròn 1 chữ số thập phân, MB làm tròn số nguyên.
ByteSize splitBytes(int bytes) {
  if (bytes <= 0) return const ByteSize('0', 'MB');
  if (bytes >= _gb) {
    return ByteSize((bytes / _gb).toStringAsFixed(1), 'GB');
  }
  final mb = (bytes / _mb).round();
  if (mb >= 1000) return const ByteSize('1.0', 'GB');
  if (mb < 1) return const ByteSize('<1', 'MB');
  return ByteSize('$mb', 'MB');
}

String formatBytes(int bytes) => splitBytes(bytes).toString();

/// 12480 -> "12,480".
String formatCount(int n) {
  final digits = n.abs().toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return n < 0 ? '-$out' : out.toString();
}
