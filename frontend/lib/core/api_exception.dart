import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? fieldErrors;
  ApiException(this.message, {this.fieldErrors});

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ApiException('Tiempo de espera agotado');
      case DioExceptionType.connectionError:
        return ApiException('No se pudo conectar con el servidor');
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        final msg = (data is Map && data['message'] != null)
            ? data['message']
            : 'Error del servidor (${e.response?.statusCode})';
        return ApiException(
          msg,
          fieldErrors: (data is Map && data['errors'] is Map)
              ? Map<String, dynamic>.from(data['errors'])
              : null,
        );
      default:
        return ApiException('Error inesperado de comunicación');
    }
  }

  @override
  String toString() => message;
}