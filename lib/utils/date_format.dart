/// intl パッケージを入れずに済む、日本語の簡易日付フォーマット。
const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

String formatDate(DateTime date, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final target = _dateOnly(date);
  final diff = target.difference(today).inDays;
  if (diff == 0) return '今日';
  if (diff == 1) return '明日';
  if (diff == -1) return '昨日';
  final w = _weekdays[target.weekday - 1];
  final md = '${target.month}月${target.day}日($w)';
  return target.year == today.year ? md : '${target.year}年$md';
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
