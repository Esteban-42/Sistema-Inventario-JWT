const express = require('express');
const cors = require('cors');
const { pool, init } = require('./db');
const authRoutes = require('./routes/authRoutes');
const authMiddleware = require('./middleware/authMiddleware');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const ah = (fn) => (req, res, next) => fn(req, res, next).catch(next);
const txt = (v) => (v === undefined || v === null ? '' : String(v).trim());

if (!process.env.JWT_SECRET) {
  throw new Error('Falta configurar JWT_SECRET en .env');
}

// Un id que no sea numérico responde 404
app.param('id', (req, res, next, id) => {
  if (!/^\d+$/.test(id))
    return res.status(404).json({ message: 'Producto no encontrado' });
  next();
});

async function validar(body, idActual = null) {
  const errores = {};
  const nombre = txt(body.nombre);
  const codigo = txt(body.codigo);
  const categoria = txt(body.categoria);
  const { precio, cantidad } = body;

  if (!nombre) errores.nombre = 'El nombre es obligatorio';
  if (!codigo) errores.codigo = 'El código es obligatorio';
  if (!categoria) errores.categoria = 'La categoría es obligatoria';
  if (precio === undefined || precio === null || precio === '' ||
      isNaN(precio) || Number(precio) < 0)
    errores.precio = 'El precio debe ser un número mayor o igual a 0';
  if (cantidad === undefined || cantidad === null || cantidad === '' ||
      !Number.isInteger(Number(cantidad)) || Number(cantidad) < 0)
    errores.cantidad = 'La cantidad debe ser un entero mayor o igual a 0';

  if (codigo) {
    const { rows } = await pool.query(
      'SELECT id FROM productos WHERE codigo = $1', [codigo]);
    if (rows[0] && rows[0].id !== Number(idActual))
      errores.codigo = 'El código ya existe';
  }
  return errores;
}

// Ruta de salud (útil para comprobar que el servidor está vivo)
app.get('/', (req, res) => res.json({ status: 'ok', message: 'API de inventario' }));


app.use('/api/auth', authRoutes);
app.use('/api/productos', authMiddleware);

// GET todos
app.get('/api/productos', ah(async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM productos ORDER BY id DESC');
  res.status(200).json(rows);
}));

// GET uno
app.get('/api/productos/:id', ah(async (req, res) => {
  const { rows } = await pool.query(
    'SELECT * FROM productos WHERE id = $1', [req.params.id]);
  if (!rows[0]) return res.status(404).json({ message: 'Producto no encontrado' });
  res.status(200).json(rows[0]);
}));

// POST
app.post('/api/productos', ah(async (req, res) => {
  const b = req.body ?? {};
  const errores = await validar(b);
  if (Object.keys(errores).length)
    return res.status(422).json({ message: 'Datos inválidos', errors: errores });

  const { rows } = await pool.query(
    `INSERT INTO productos (nombre, codigo, descripcion, precio, cantidad, categoria)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [txt(b.nombre), txt(b.codigo), txt(b.descripcion) || null,
     Number(b.precio), Number(b.cantidad), txt(b.categoria)]
  );
  res.status(201).json(rows[0]);
}));

// PUT
app.put('/api/productos/:id', ah(async (req, res) => {
  const b = req.body ?? {};
  const existe = await pool.query(
    'SELECT id FROM productos WHERE id = $1', [req.params.id]);
  if (!existe.rows[0])
    return res.status(404).json({ message: 'Producto no encontrado' });

  const errores = await validar(b, req.params.id);
  if (Object.keys(errores).length)
    return res.status(422).json({ message: 'Datos inválidos', errors: errores });

  const { rows } = await pool.query(
    `UPDATE productos
     SET nombre=$1, codigo=$2, descripcion=$3, precio=$4, cantidad=$5, categoria=$6
     WHERE id=$7 RETURNING *`,
    [txt(b.nombre), txt(b.codigo), txt(b.descripcion) || null,
     Number(b.precio), Number(b.cantidad), txt(b.categoria), req.params.id]
  );
  res.status(200).json(rows[0]);
}));

// DELETE
app.delete('/api/productos/:id', ah(async (req, res) => {
  const r = await pool.query('DELETE FROM productos WHERE id = $1', [req.params.id]);
  if (r.rowCount === 0)
    return res.status(404).json({ message: 'Producto no encontrado' });
  res.status(200).json({ message: 'Producto eliminado correctamente' });
}));

// Manejo global de errores
app.use((err, req, res, next) => {
  if (err.code === '23505') {

  if (err.constraint === 'usuarios_correo_key') {
    return res.status(409).json({
      message: 'El correo electrónico ya está registrado'
    });
  }

  return res.status(422).json({
    message: 'Datos inválidos',
    errors: {
      codigo: 'El código ya existe'
    }
  });

}
  console.error(err);
  res.status(500).json({ message: 'Error interno del servidor' });
});

const PORT = process.env.PORT || 3000;
init()
  .then(() => app.listen(PORT, '0.0.0.0', () => console.log(`API en puerto ${PORT}`)))
  .catch((err) => {
    console.error('No se pudo iniciar la API:', err);
    process.exit(1);
  });