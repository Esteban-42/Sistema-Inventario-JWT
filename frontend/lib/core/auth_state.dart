
import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class AuthState extends ChangeNotifier {
  final StorageService _storage = StorageService();

  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  Future<void> initialize() async {
  final tieneToken = await _storage.tieneSesion();

  if (!tieneToken) {
    _isAuthenticated = false;
    notifyListeners();
    return;
  }

  try {
    _isAuthenticated = await AuthService().verificarSesion();
  } catch (_) {
    _isAuthenticated = false;
  }

  notifyListeners();
}


  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }


  Future<void> logout() async {
    await _storage.cerrarSesion();

    _isAuthenticated = false;

    notifyListeners();
  }
}


final authState = AuthState();
