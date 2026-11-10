import 'package:dio/dio.dart';
import '../core/api_cliente.dart';
import '../core/api_exception.dart';
import '../modelos/producto.dart';

class ProductoService {
  final Dio _dio = ApiClient.dio;

  Future<List<Producto>> listar() async {
    try {
      final res = await _dio.get('/productos');
      return (res.data as List).map((e) => Producto.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Producto> obtener(int id) async {
    try {
      final res = await _dio.get('/productos/$id');
      return Producto.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Producto> crear(Producto p) async {
    try {
      final res = await _dio.post('/productos', data: p.toJson());
      return Producto.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Producto> actualizar(int id, Producto p) async {
    try {
      final res = await _dio.put('/productos/$id', data: p.toJson());
      return Producto.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> eliminar(int id) async {
    try {
      await _dio.delete('/productos/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}