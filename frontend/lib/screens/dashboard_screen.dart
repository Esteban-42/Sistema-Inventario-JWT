
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/api_exception.dart';
import '../core/app_theme.dart';
import '../core/auth_state.dart';
import '../modelos/producto.dart';
import '../services/storage_service.dart';
import '../services/producto_service.dart';

import 'widgets/app_drawer.dart';
import 'widgets/stat_card.dart';
import 'widgets/stock_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = ProductoService();
  final _storage = StorageService();

  List<Producto> _productos = [];
  Map<String, dynamic>? _usuario;

  bool _cargando = true;
  bool _cargandoUsuario = true;
  bool _cerrandoSesion = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final usuario = await _storage.obtenerUsuario();

    if (!mounted) return;

    setState(() {
      _usuario = usuario;
      _cargandoUsuario = false;
    });
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
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro de que deseas cerrar tu sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _cerrandoSesion = true);

    try {
      await authState.logout();

      if (!mounted) return;

      context.go('/login');
    } catch (e) {
      if (!mounted) return;

      setState(() => _cerrandoSesion = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cerrar la sesión: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalProductos = _productos.length;

    final totalUnidades =
        _productos.fold<int>(0, (s, p) => s + p.cantidad);

    final valorTotal =
        _productos.fold<double>(0, (s, p) => s + p.precio * p.cantidad);

    final bajoStock = _productos.where((p) => p.cantidad <= 25).toList()
      ..sort((a, b) => a.cantidad.compareTo(b.cantidad));

    final moneda = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Inventario'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrandoSesion ? null : _cerrarSesion,
            icon: _cerrandoSesion
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 48,
                          color: AppTheme.rojo,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _cargar,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Información del usuario autenticado
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: AppTheme.verde,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _cargandoUsuario
                                    ? const Text('Cargando usuario...')
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _usuario?['nombre'] ??
                                                'Usuario',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            _usuario?['correo'] ?? '',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                              ),
                              const Column(
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    color: Colors.green,
                                  ),
                                  Text(
                                    'Autenticado',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Valor del inventario
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.verde,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Valor del inventario',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              moneda.format(valorTotal),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Productos y unidades
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              titulo: 'Productos',
                              valor: '$totalProductos',
                              icono: Icons.inventory_2_outlined,
                              color: AppTheme.verde,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              titulo: 'Unidades',
                              valor: '$totalUnidades',
                              icono: Icons.layers_outlined,
                              color: AppTheme.ambar,
                            ),
                          ),
                        ],
                      ),

                      // Productos por reponer
                      if (bajoStock.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Para reponer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Column(
                            children: [
                              for (final p in bajoStock.take(4))
                                ListTile(
                                  title: Text(
                                    p.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: StockBadge(
                                    cantidad: p.cantidad,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      FilledButton.icon(
                        onPressed: () => context.go('/productos'),
                        icon: const Icon(Icons.list_alt),
                        label: const Text('Gestionar productos'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
