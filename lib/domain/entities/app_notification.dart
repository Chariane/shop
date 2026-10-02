enum AppNotificationType {
  order,
  delivery,
  promo,
  message,
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String message;
  final String timeLabel;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      timeLabel: timeLabel,
      isRead: isRead ?? this.isRead,
    );
  }
}
