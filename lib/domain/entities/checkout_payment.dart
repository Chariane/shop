import 'order.dart';

class CheckoutPayment {
  final String id;
  final List<Order> orders;
  final String checkoutUrl;
  final double amount;
  final int amountXof;
  final String status;

  const CheckoutPayment({
    required this.id,
    required this.orders,
    required this.checkoutUrl,
    required this.amount,
    required this.amountXof,
    required this.status,
  });
}

class CheckoutPaymentStatus {
  final String status;
  final int amountXof;

  const CheckoutPaymentStatus({required this.status, required this.amountXof});
}
