import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_exception.dart';
import '../modelos/producto.dart';
import '../services/producto_service.dart';

class ProductoDetalleScreen extends StatefulWidget {
  final int id;
  const ProductoDetalleScreen({super.key, required this.id});

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  final _service = ProductoService();
  Producto? _producto;
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
      final p = await _service.obtener(widget.id);
      if (!mounted) return;
      setState(() => _producto = p);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('¿Seguro que deseas eliminarlo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _service.eliminar(widget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado correctamente')));
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _fila(String label, String valor) => ListTile(
        title: Text(label, style: const TextStyle(color: Colors.grey)),
        subtitle: Text(valor, style: const TextStyle(fontSize: 18)),
      );

  @override
  Widget build(BuildContext context) {
    final p = _producto;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      FilledButton(
                          onPressed: _cargar, child: const Text('Reintentar')),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    _fila('Nombre', p!.nombre),
                    _fila('Código', p.codigo),
                    _fila('Descripción', p.descripcion ?? 'Sin descripción'),
                    _fila('Precio', '\$${p.precio.toStringAsFixed(0)}'),
                    _fila('Cantidad', '${p.cantidad}'),
                    _fila('Categoría', p.categoria),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                await context.push('/productos/${p.id}/editar');
                                _cargar();
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Editar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: _eliminar,
                              icon: const Icon(Icons.delete),
                              label: const Text('Eliminar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}