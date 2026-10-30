/// 18/10/2026
String formatShortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// "Just now", "8 min ago", "2 hr ago", "3 days ago".
String agoLabel(DateTime then, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(then);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  return '${diff.inDays} days ago';
}
