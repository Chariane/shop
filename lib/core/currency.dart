String formatCfa(num amount) {
  final digits = amount.round().abs().toString();
  final grouped = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) grouped.write(' ');
    grouped.write(digits[index]);
  }
  final sign = amount < 0 ? '-' : '';
  return '$sign$grouped FCFA';
}
