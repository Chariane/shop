import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_notification.dart';

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier()
      : super(
          const [
            AppNotification(
              id: 'n1',
              type: AppNotificationType.delivery,
              title: 'Livraison en cours',
              message:
                  'Votre commande #SH-1271 est en route vers votre adresse.',
              timeLabel: 'Il y a 12 min',
            ),
            AppNotification(
              id: 'n2',
              type: AppNotificationType.promo,
              title: 'Nouvelle promotion',
              message: 'Profitez de -20% sur une sélection TechNova.',
              timeLabel: 'Il y a 1 h',
            ),
            AppNotification(
              id: 'n3',
              type: AppNotificationType.order,
              title: 'Commande confirmée',
              message: 'Votre commande #SH-1284 a bien été validée.',
              timeLabel: 'Hier',
              isRead: true,
            ),
            AppNotification(
              id: 'n4',
              type: AppNotificationType.message,
              title: 'Message vendeur',
              message: 'UrbanWear a répondu à votre demande de suivi.',
              timeLabel: '2 jours',
              isRead: true,
            ),
          ],
        );

  void markAsRead(String id) {
    state = [
      for (final notification in state)
        notification.id == id
            ? notification.copyWith(isRead: true)
            : notification,
    ];
  }

  void markAllAsRead() {
    state = [
      for (final notification in state) notification.copyWith(isRead: true),
    ];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
  return NotificationsNotifier();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});
