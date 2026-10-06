const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String peso(num v) {
  final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
  final parts = s.split('.');
  final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  final decimals = parts.length > 1 ? '.${parts[1]}' : '';
  return '₱$whole$decimals';
}

String weekdayShort(DateTime d) => _days[d.weekday - 1];
String monthShort(DateTime d) => _months[d.month - 1];
String prettyDate(DateTime d) => '${weekdayShort(d)}, ${monthShort(d)} ${d.day}, ${d.year}';
String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

int labelToMinutes(String label) {
  try {
    final parts = label.split(' ');
    final hm = parts[0].split(':');
    var h = int.parse(hm[0]) % 12;
    if (parts[1].toUpperCase() == 'PM') h += 12;
    return h * 60 + int.parse(hm[1]);
  } catch (_) {
    return 0;
  }
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

String minutesToLabel(int m) {
  final h24 = m ~/ 60;
  final min = m % 60;
  final suffix = h24 >= 12 ? 'PM' : 'AM';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h12:${min.toString().padLeft(2, '0')} $suffix';
}