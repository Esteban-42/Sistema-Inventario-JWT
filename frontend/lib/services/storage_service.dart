
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const FlutterSecureStorage _secureStorage =
      FlutterSecureStorage();

  Future<void> guardarSesion({
    required String token,
    required Map<String, dynamic> usuario,
  }) async {
    await _secureStorage.write(
      key: 'access_token',
      value: token,
    );

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'user_name',
      usuario['nombre']?.toString() ?? '',
    );

    await prefs.setString(
      'user_email',
      usuario['correo']?.toString() ?? '',
    );

    await prefs.setInt(
      'user_id',
      int.tryParse(usuario['id'].toString()) ?? 0,
    );
  }

  // Obtener token
  Future<String?> obtenerToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  
  Future<Map<String, dynamic>> obtenerUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('user_id'),
      'nombre': prefs.getString('user_name'),
      'correo': prefs.getString('user_email'),
    };
  }

  // Comprobar si existe un token
  Future<bool> tieneSesion() async {
    final token = await obtenerToken();
    return token != null && token.isNotEmpty;
  }

  // Cerrar sesión y eliminar información
  Future<void> cerrarSesion() async {
    await _secureStorage.delete(key: 'access_token');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }
}
