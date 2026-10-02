import 'package:flutter_test/flutter_test.dart';
import 'package:shophub/core/currency.dart';

void main() {
  test('formats rounded XOF amounts with grouped digits', () {
    expect(formatCfa(1234567.8), '1 234 568 FCFA');
    expect(formatCfa(0), '0 FCFA');
  });
}
