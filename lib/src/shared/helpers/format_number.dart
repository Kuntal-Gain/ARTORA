/// Formats a number with comma separators for thousands (e.g. 1,000,000).
String formatNumber(num number) {
  final parts = number.toString().split('.');
  final whole = parts[0];
  final buffer = StringBuffer();
  int count = 0;

  for (int i = whole.length - 1; i >= 0; i--) {
    buffer.write(whole[i]);
    count++;
    if (count % 3 == 0 && i != 0) {
      buffer.write(',');
    }
  }

  final formattedWhole = buffer.toString().split('').reversed.join();
  return parts.length > 1 ? '$formattedWhole.${parts[1]}' : formattedWhole;
}

/// Compact count for UI stats: 999 → `999`, 1100 → `1.1K`, 2400000 → `2.4M`.
String formatCompact(num number) {
  String fmt(double v, String suffix) {
    final s = v.toStringAsFixed(1);
    return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s}$suffix';
  }

  if (number >= 1000000) return fmt(number / 1000000, 'M');
  if (number >= 1000) return fmt(number / 1000, 'K');
  return number.toString();
}
