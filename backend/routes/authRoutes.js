
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../db');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// REGISTRO DE USUARIO
router.post('/register', async (req, res, next) => {

  try {

    const { nombre, correo, password } = req.body;

    if (!nombre || !correo || !password) {
      return res.status(400).json({
        message: 'Todos los campos son obligatorios'
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        message: 'La contraseña debe tener al menos 8 caracteres'
      });
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const { rows } = await pool.query(
      `INSERT INTO usuarios (nombre, correo, password_hash)
       VALUES ($1, $2, $3)
       RETURNING id, nombre, correo`,
      [nombre.trim(), correo.trim().toLowerCase(), passwordHash]
    );

    return res.status(201).json({
      message: 'Usuario registrado correctamente',
      usuario: rows[0]
    });

  } catch (error) {
    next(error);
  }

});

// LOGIN
router.post('/login', async (req, res, next) => {

  try {

    const { correo, password } = req.body;

    if (!correo || !password) {
      return res.status(400).json({
        message: 'Correo y contraseña son obligatorios'
      });
    }

    const { rows } = await pool.query(
      'SELECT * FROM usuarios WHERE correo = $1',
      [correo.trim().toLowerCase()]
    );

    const usuario = rows[0];

    if (!usuario) {
      return res.status(401).json({
        message: 'Credenciales incorrectas'
      });
    }

    const passwordValida = await bcrypt.compare(
      password,
      usuario.password_hash
    );

    if (!passwordValida) {
      return res.status(401).json({
        message: 'Credenciales incorrectas'
      });
    }

    const token = jwt.sign(
      {
        id: usuario.id,
        correo: usuario.correo
      },
      process.env.JWT_SECRET,
      {
        expiresIn: '2h'
      }
    );

    return res.status(200).json({
      message: 'Inicio de sesión exitoso',
      access_token: token,
      token_type: 'Bearer',
      expires_in: 7200,
      usuario: {
        id: usuario.id,
        nombre: usuario.nombre,
        correo: usuario.correo
      }
    });

  } catch (error) {
    next(error);
  }

});

// INFORMACIÓN DEL USUARIO AUTENTICADO
router.get('/me', authMiddleware, async (req, res, next) => {

  try {

    const { rows } = await pool.query(
      `SELECT id, nombre, correo
       FROM usuarios
       WHERE id = $1`,
      [req.usuario.id]
    );

    if (!rows[0]) {
      return res.status(401).json({
        message: 'Usuario no encontrado'
      });
    }

    return res.status(200).json(rows[0]);

  } catch (error) {
    next(error);
  }

});

module.exports = router;
