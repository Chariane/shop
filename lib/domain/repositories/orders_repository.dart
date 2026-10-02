import 'package:shophub/domain/entities/cart_item.dart';
import 'package:shophub/domain/entities/delivery_option.dart';
import 'package:shophub/domain/entities/order.dart';
import 'package:shophub/domain/entities/checkout_payment.dart';

abstract class OrdersRepository {
  Future<List<Order>> getMyOrders();
  Future<void> submitShopReview({
    required String orderId,
    required int rating,
    String? comment,
  });
  Future<Order> updateVendorOrderStatus(
      {required String orderId, required OrderStatus status});
  Future<CheckoutPayment> startCheckout({
    required List<CartItem> items,
    required DeliveryAddress address,
    required DeliveryOption delivery,
    required String customerEmail,
  });
  Future<CheckoutPaymentStatus> refreshPayment(String paymentId);
  Future<List<Order>> createOrder({
    required List<CartItem> items,
    required DeliveryAddress address,
    required DeliveryOption delivery,
  });
}
