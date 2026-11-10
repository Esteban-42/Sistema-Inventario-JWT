const { pool, init } = require('./db');

const productos = [
  ['Arroz 500g', 'P001', 'Arroz blanco', 2500, 100, 'Granos'],
  ['Aceite 1L', 'P002', 'Aceite vegetal', 12000, 40, 'Despensa'],
  ['Leche 1L', 'P003', 'Leche entera', 4200, 60, 'Lácteos'],
  ['Pan tajado', 'P004', null, 6500, 30, 'Panadería'],
  ['Azúcar 1kg', 'P005', 'Azúcar refinada', 4800, 80, 'Despensa'],
  ['Café 250g', 'P006', 'Café molido', 9800, 45, 'Bebidas'],
  ['Jabón en barra', 'P007', null, 2200, 120, 'Aseo'],
  ['Detergente 1kg', 'P008', 'Detergente en polvo', 14500, 25, 'Aseo'],
  ['Huevos x30', 'P009', 'Huevos AA', 19000, 20, 'Lácteos'],
  ['Gaseosa 1.5L', 'P010', 'Bebida gaseosa', 5500, 70, 'Bebidas'],
];

(async () => {
  await init();
  for (const p of productos) {
    await pool.query(
      `INSERT INTO productos (nombre, codigo, descripcion, precio, cantidad, categoria)
       VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (codigo) DO NOTHING`,
      p
    );
  }
  console.log('Seed completado');
  await pool.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});