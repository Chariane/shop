import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  factory AppException.fromDio(DioException error) {
    final data = error.response?.data;
    final apiMessage = data is Map<String, dynamic> ? data['message'] : null;
    final message = apiMessage is String && apiMessage.isNotEmpty
        ? apiMessage
        : switch (error.type) {
            DioExceptionType.connectionTimeout ||
            DioExceptionType.sendTimeout ||
            DioExceptionType.receiveTimeout =>
              'La connexion a expiré. Réessayez dans un instant.',
            DioExceptionType.connectionError =>
              'Impossible de joindre le serveur. Vérifiez votre connexion.',
            _ => 'Une erreur réseau est survenue. Réessayez.',
          };
    return AppException(message, statusCode: error.response?.statusCode);
  }

  @override
  String toString() => message;
}
