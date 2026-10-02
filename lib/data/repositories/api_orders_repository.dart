import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/repositories/orders_repository.dart';
import 'package:shophub/domain/entities/cart_item.dart';
import 'package:shophub/domain/entities/checkout_payment.dart';
import 'package:shophub/domain/entities/delivery_option.dart';
import 'package:shophub/domain/entities/order.dart';
import 'package:shophub/domain/entities/product.dart';

class ApiOrdersRepository implements OrdersRepository {
  final Dio _dio;

  const ApiOrdersRepository(this._dio);

  @override
  Future<List<Order>> getMyOrders() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/orders/me');
      return (response.data?['orders'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((row) => _mapOrder(Map<String, dynamic>.from(row)))
          .toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  @override
  Future<void> submitShopReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _dio.post<void>(
        '/orders/$orderId/review',
        data: {
          'rating': rating,
          if (comment?.trim().isNotEmpty == true) 'comment': comment!.trim()
        },
      );
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  @override
  Future<Order> updateVendorOrderStatus(
      {required String orderId, required OrderStatus status}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/orders/$orderId/status',
        data: {'status': status.name},
      );
      final rawOrder = response.data?['order'];
      if (rawOrder is! Map)
        throw const AppException('Réponse de commande invalide.');
      return _mapOrder(Map<String, dynamic>.from(rawOrder));
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  @override
  Future<CheckoutPayment> startCheckout({
    required List<CartItem> items,
    required DeliveryAddress address,
    required DeliveryOption delivery,
    required String customerEmail,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders/checkout',
        data: {
          'items': items
              .map((item) =>
                  {'productId': item.product.id, 'quantity': item.quantity})
              .toList(),
          'deliveryMethod': delivery.id,
          'deliveryFee': delivery.fee,
          'customerEmail': customerEmail,
          'deliveryAddress': {
            'fullName': address.fullName,
            'phone': address.phone,
            'street': address.street,
            'city': address.city,
            'country': address.country,
          },
        },
      );
      final data = response.data ?? const {};
      final rawPayment = data['payment'];
      if (rawPayment is! Map)
        throw const AppException('Réponse de paiement invalide.');
      final payment = Map<String, dynamic>.from(rawPayment);
      final orders = (data['orders'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((row) => _mapOrder(Map<String, dynamic>.from(row)))
          .toList();
      return CheckoutPayment(
        id: payment['id'] as String,
        orders: orders,
        checkoutUrl: payment['checkoutUrl'] as String? ?? '',
        amount: (payment['amount'] as num?)?.toDouble() ?? 0,
        amountXof: (payment['amountXof'] as num?)?.toInt() ?? 0,
        status: payment['status'] as String? ?? 'pending',
      );
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  @override
  Future<CheckoutPaymentStatus> refreshPayment(String paymentId) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/payments/$paymentId');
      final payment = response.data?['payment'];
      if (payment is! Map)
        throw const AppException('Réponse de paiement invalide.');
      return CheckoutPaymentStatus(
        status: payment['status'] as String? ?? 'pending',
        amountXof: (payment['amountXof'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  @override
  Future<List<Order>> createOrder({
    required List<CartItem> items,
    required DeliveryAddress address,
    required DeliveryOption delivery,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders',
        data: {
          'items': items
              .map(
                (item) => {
                  'productId': item.product.id,
                  'quantity': item.quantity,
                },
              )
              .toList(),
          'deliveryMethod': delivery.id,
          'deliveryFee': delivery.fee,
          'deliveryAddress': {
            'fullName': address.fullName,
            'phone': address.phone,
            'street': address.street,
            'city': address.city,
            'country': address.country,
          },
        },
      );
      return (response.data?['orders'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((row) => _mapOrder(Map<String, dynamic>.from(row)))
          .toList();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  Order _mapOrder(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final sourceProduct = item['product'];
      final product = sourceProduct is Map
          ? Map<String, dynamic>.from(sourceProduct)
          : <String, dynamic>{};
      return CartItem(
        product: _productFromOrderItem(item, product, json),
        quantity: (item['quantity'] as num?)?.toInt() ?? 1,
      );
    }).toList();
    return Order(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String? ?? '',
      vendorId: json['vendorId'] as String,
      vendorName: json['vendorName'] as String? ?? '',
      deliveryCity: (json['deliveryAddress'] as Map?)?['city'] as String? ?? '',
      items: items,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      paymentStatus: json['paymentStatus'] as String? ?? 'not_required',
      paymentId: json['paymentId'] as String?,
      status: switch (json['status']) {
        'confirmed' => OrderStatus.confirmed,
        'shipped' => OrderStatus.shipped,
        'delivered' => OrderStatus.delivered,
        _ => OrderStatus.pending,
      },
      shopReviewRating: (json['shopReview'] as Map?)?['rating'] as int?,
      shopReviewComment: (json['shopReview'] as Map?)?['comment'] as String?,
    );
  }

  Product _productFromOrderItem(
    Map<String, dynamic> item,
    Map<String, dynamic> product,
    Map<String, dynamic> order,
  ) {
    return Product(
      id: item['productId'] as String,
      vendorId: order['vendorId'] as String,
      vendorName: order['vendorName'] as String? ?? '',
      name: item['productName'] as String? ?? '',
      shortDescription: '',
      longDescription: '',
      price: (item['unitPrice'] as num?)?.toDouble() ?? 0,
      imageUrl: item['imageUrl'] as String? ?? '',
      category: 'Autre',
      stock: (product['stock'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(product['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
