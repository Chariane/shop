import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shophub/domain/entities/app_notification.dart';
import '../core/providers/core_providers.dart';

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  final Dio _dio;
  NotificationsNotifier(this._dio) : super(const []) {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final response = await _dio.get('/notifications/me');
      final rows = response.data['notifications'] as List<dynamic>;
      state = rows.map((row) {
        final item = row as Map<String, dynamic>;
        final createdAt = DateTime.tryParse(item['createdAt'] as String? ?? '');
        var label = '';
        if (createdAt != null) {
          final age = DateTime.now().difference(createdAt);
          label = age.inDays > 0
              ? 'Il y a ' + age.inDays.toString() + ' j'
              : age.inHours > 0
                  ? 'Il y a ' + age.inHours.toString() + ' h'
                  : 'Récemment';
        }
        return AppNotification(
            id: item['id'] as String,
            type: item['type'] == 'delivery'
                ? AppNotificationType.delivery
                : AppNotificationType.order,
            title: item['title'] as String,
            message: item['message'] as String,
            timeLabel: label,
            isRead: item['isRead'] as bool? ?? false);
      }).toList();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch('/notifications/me/read', data: {'id': id});
    } catch (_) {
      return;
    }
    state = [for (final n in state) n.id == id ? n.copyWith(isRead: true) : n];
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch('/notifications/me/read', data: const {});
    } catch (_) {
      return;
    }
    state = [for (final n in state) n.copyWith(isRead: true)];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
        (ref) => NotificationsNotifier(ref.watch(dioProvider)));
final unreadNotificationsCountProvider = Provider<int>(
    (ref) => ref.watch(notificationsProvider).where((n) => !n.isRead).length);
final loyaltyPointsProvider = FutureProvider<int>((ref) async {
  final response = await ref.watch(dioProvider).get('/loyalty/me');
  return (response.data['points'] as num).toInt();
});
