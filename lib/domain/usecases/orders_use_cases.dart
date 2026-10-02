import '../entities/cart_item.dart';
import '../entities/checkout_payment.dart';
import '../entities/delivery_option.dart';
import '../entities/order.dart';
import '../repositories/orders_repository.dart';

class OrdersUseCases {
  final OrdersRepository _repository;

  const OrdersUseCases(this._repository);

  Future<List<Order>> getMyOrders() => _repository.getMyOrders();

  Future<void> submitShopReview({
    required String orderId,
    required int rating,
    String? comment,
  }) =>
      _repository.submitShopReview(
        orderId: orderId,
        rating: rating,
        comment: comment,
      );

  Future<Order> updateVendorOrderStatus(
          {required String orderId, required OrderStatus status}) =>
      _repository.updateVendorOrderStatus(orderId: orderId, status: status);

  Future<CheckoutPayment> startCheckout({
    required List<CartItem> items,
    required DeliveryAddress address,
    required DeliveryOption delivery,
    required String customerEmail,
  }) =>
      _repository.startCheckout(
        items: items,
        address: address,
        delivery: delivery,
        customerEmail: customerEmail,
      );

  Future<CheckoutPaymentStatus> refreshPayment(String paymentId) =>
      _repository.refreshPayment(paymentId);

  Future<List<Order>> createOrder({
    required List<CartItem> items,
    required DeliveryAddress address,
    required DeliveryOption delivery,
  }) =>
      _repository.createOrder(
        items: items,
        address: address,
        delivery: delivery,
      );
}
