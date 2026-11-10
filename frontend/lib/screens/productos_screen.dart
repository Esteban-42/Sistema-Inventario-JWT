import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_exception.dart';
import '../modelos/producto.dart';
import '../services/producto_service.dart';
import 'widgets/app_drawer.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _service = ProductoService();
  List<Producto> _productos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await _service.listar();
      if (!mounted) return;
      setState(() => _productos = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _irA(String ruta) async {
    await context.push(ruta);
    _cargar(); // refresca al volver
  }

  @override
  Widget build(BuildContext context) {
    Widget cuerpo;
    if (_cargando) {
      cuerpo = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      cuerpo = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    } else if (_productos.isEmpty) {
      cuerpo = const Center(child: Text('No hay productos registrados'));
    } else {
      cuerpo = RefreshIndicator(
        onRefresh: _cargar,
        child: ListView.separated(
          itemCount: _productos.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = _productos[i];
            return ListTile(
              title: Text(p.nombre),
              subtitle: Text('Precio: \$${p.precio.toStringAsFixed(0)}'),
              trailing: Text('${p.cantidad} uds',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => _irA('/productos/${p.id}'),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      drawer: const AppDrawer(),
      body: cuerpo,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _irA('/productos/nuevo'),
        child: const Icon(Icons.add),
      ),
    );
  }
}