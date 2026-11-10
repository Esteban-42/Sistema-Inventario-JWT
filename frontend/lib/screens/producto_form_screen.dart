import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_exception.dart';
import '../modelos/producto.dart';
import '../services/producto_service.dart';

class ProductoFormScreen extends StatefulWidget {
  final int? id; // null = crear, con valor = editar
  const ProductoFormScreen({super.key, this.id});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _service = ProductoService();
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _codigo = TextEditingController();
  final _descripcion = TextEditingController();
  final _precio = TextEditingController();
  final _cantidad = TextEditingController();
  final _categoria = TextEditingController();

  bool _cargando = false;
  Map<String, String> _erroresApi = {};

  @override
  void initState() {
    super.initState();
    if (widget.id != null) _precargar();
  }

  Future<void> _precargar() async {
    setState(() => _cargando = true);
    try {
      final p = await _service.obtener(widget.id!);
      _nombre.text = p.nombre;
      _codigo.text = p.codigo;
      _descripcion.text = p.descripcion ?? '';
      _precio.text = p.precio.toString();
      _cantidad.text = p.cantidad.toString();
      _categoria.text = p.categoria;
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_nombre, _codigo, _descripcion, _precio, _cantidad, _categoria]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    _erroresApi = {};
    if (!_formKey.currentState!.validate()) return;

    final producto = Producto(
      nombre: _nombre.text.trim(),
      codigo: _codigo.text.trim(),
      descripcion: _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
      precio: double.parse(_precio.text),
      cantidad: int.parse(_cantidad.text),
      categoria: _categoria.text.trim(),
    );

    setState(() => _cargando = true);
    try {
      if (widget.id == null) {
        await _service.crear(producto);
      } else {
        await _service.actualizar(widget.id!, producto);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto guardado correctamente')));
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erroresApi = (e.fieldErrors ?? {})
            .map((k, v) => MapEntry(k, v.toString()));
      });
      _formKey.currentState!.validate(); // muestra errores del servidor
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Widget _campo(String label, TextEditingController c, String clave,
      {TextInputType? tipo, String? Function(String?)? validar, int lineas = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: tipo,
        maxLines: lineas,
        decoration:
            InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) => _erroresApi[clave] ?? validar?.call(v),
      ),
    );
  }

  String? _obligatorio(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.id == null ? 'Nuevo producto' : 'Editar producto')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _campo('Nombre', _nombre, 'nombre', validar: _obligatorio),
                  _campo('Código', _codigo, 'codigo', validar: _obligatorio),
                  _campo('Descripción (opcional)', _descripcion, 'descripcion',
                      lineas: 2),
                  _campo('Precio', _precio, 'precio',
                      tipo: const TextInputType.numberWithOptions(decimal: true),
                      validar: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n <= 0) ? 'Ingresa un precio mayor a 0' : null;
                  }),
                  _campo('Cantidad', _cantidad, 'cantidad',
                      tipo: TextInputType.number, validar: (v) {
                    final n = int.tryParse(v ?? '');
                    return (n == null || n < 0) ? 'Ingresa un entero mayor o igual a 0' : null;
                  }),
                  _campo('Categoría', _categoria, 'categoria', validar: _obligatorio),
                  FilledButton(
                    onPressed: _guardar,
                    child: Text(widget.id == null ? 'Registrar' : 'Actualizar'),
                  ),
                ],
              ),
            ),
    );
  }
}