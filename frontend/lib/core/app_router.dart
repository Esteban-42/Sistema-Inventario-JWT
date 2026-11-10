
import 'package:go_router/go_router.dart';

import 'auth_state.dart';

import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/productos_screen.dart';
import '../screens/producto_detalle_screen.dart';
import '../screens/producto_form_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',


  refreshListenable: authState,


  redirect: (context, state) {

    final autenticado = authState.isAuthenticated;

    final estaEnLogin = state.matchedLocation == '/login';


    if (!autenticado && !estaEnLogin) {
      return '/login';
    }


    if (autenticado && estaEnLogin) {
      return '/';
    }

    return null;
  },

  routes: [

    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),

    GoRoute(
      path: '/productos',
      builder: (context, state) => const ProductosScreen(),
    ),

    GoRoute(
      path: '/productos/nuevo',
      builder: (context, state) => const ProductoFormScreen(),
    ),

    GoRoute(
      path: '/productos/:id',
      builder: (context, state) => ProductoDetalleScreen(
        id: int.parse(state.pathParameters['id']!),
      ),
    ),

    GoRoute(
      path: '/productos/:id/editar',
      builder: (context, state) => ProductoFormScreen(
        id: int.parse(state.pathParameters['id']!),
      ),
    ),

  ],
);
