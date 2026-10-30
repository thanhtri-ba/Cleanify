import '../../scan/domain/scan_models.dart';
import '../../scan/presentation/widgets/category_meta.dart';
import '../domain/cleanup_session.dart';

const _monthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthLong = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];
const _weekdayLong = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// Nhãn ngắn cho biểu đồ tuần (Thứ 2 → Chủ nhật).
const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String monthYear(DateTime d) => '${_monthLong[d.month - 1]} ${d.year}';

String shortDate(DateTime d) =>
    '${_monthShort[d.month - 1]} ${d.day}, ${d.year}';

String longDate(DateTime d) => '${_weekdayLong[d.weekday - 1]}, ${shortDate(d)}';

/// 09:41 AM
String clock(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final mm = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '${h.toString().padLeft(2, '0')}:$mm $ampm';
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Nhãn ngày của một dòng: Today, Yesterday, thứ trong tuần, hoặc "Oct 26".
String dayChip(DateTime d, DateTime now) {
  if (sameDay(d, now)) return 'Today';
  if (sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  if (now.difference(d).inDays < 7) return _weekdayLong[d.weekday - 1];
  return '${_monthShort[d.month - 1]} ${d.day}';
}

String categoriesLine(List<ScanCategory> cats) => cats.isEmpty
    ? 'Cleanup completed'
    : cats.map((c) => c.label).join(', ');

/// Dung lượng đã dọn theo từng ngày của tuần hiện tại (index 0 = Thứ 2).
List<int> weeklyBytes(List<CleanupSession> sessions, DateTime now) {
  final monday = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  final out = List<int>.filled(7, 0);
  for (final s in sessions) {
    final day = (DateTime(s.at.year, s.at.month, s.at.day)
                .difference(monday)
                .inHours /
            24)
        .round();
    if (day >= 0 && day < 7) out[day] += s.bytes;
  }
  return out;
}
