
import 'package:dio/dio.dart';
import '../core/api_cliente.dart';
import 'storage_service.dart';

class AuthService {

    Future<bool> verificarSesion() async {
    try {
      await _dio.get('/auth/me');
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.cerrarSesion();
      }

      return false;
    }
  }
  final Dio _dio = ApiClient.dio;
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> login({
    required String correo,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'correo': correo,
          'password': password,
        },
      );

      final data = Map<String, dynamic>.from(response.data);

      final token = data['access_token'];

      if (token == null || token.toString().isEmpty) {
        throw Exception('El servidor no retornó un token válido');
      }

      final usuario = Map<String, dynamic>.from(
        data['usuario'],
      );

  
      await _storage.guardarSesion(
        token: token.toString(),
        usuario: usuario,
      );

      return data;

    } on DioException catch (e) {
      final responseData = e.response?.data;

      final mensaje = responseData is Map
          ? responseData['message']?.toString()
          : null;

      throw Exception(
        mensaje ?? 'No fue posible conectar con el servidor',
      );
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _storage.cerrarSesion();
  }

  // Comprobar sesión
  Future<bool> estaAutenticado() async {
    return await _storage.tieneSesion();
  }

  // Obtener usuario
  Future<Map<String, dynamic>> obtenerUsuario() async {
    return await _storage.obtenerUsuario();
  }
}
