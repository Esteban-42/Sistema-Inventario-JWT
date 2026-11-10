class Producto {
  final int? id;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final double precio;
  final int cantidad;
  final String categoria;

  Producto({
    this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    required this.precio,
    required this.cantidad,
    required this.categoria,
  });

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        id: json['id'],
        nombre: json['nombre'],
        codigo: json['codigo'],
        descripcion: json['descripcion'],
        precio: (json['precio'] as num).toDouble(),
        cantidad: json['cantidad'],
        categoria: json['categoria'],
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'codigo': codigo,
        'descripcion': descripcion,
        'precio': precio,
        'cantidad': cantidad,
        'categoria': categoria,
      };
}