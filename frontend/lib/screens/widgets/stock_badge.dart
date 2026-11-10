import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class StockBadge extends StatelessWidget {
  final int cantidad;
  const StockBadge({super.key, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String texto;
    if (cantidad == 0) {
      color = AppTheme.rojo;
      texto = 'Agotado';
    } else if (cantidad <= 25) {
      color = AppTheme.ambar;
      texto = '$cantidad uds · bajo';
    } else {
      color = AppTheme.verde;
      texto = '$cantidad uds';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}