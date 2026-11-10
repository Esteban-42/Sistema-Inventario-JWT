
const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {

  const authHeader = req.headers.authorization;

  // Comprobar que exista el encabezado Bearer
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      message: 'Acceso denegado. Debes iniciar sesión.'
    });
  }

  const token = authHeader.split(' ')[1];

  try {

    // Verificar la firma y expiración del JWT
    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET
    );

    // Información del usuario autenticado
    req.usuario = decoded;

    next();

  } catch (error) {

    return res.status(401).json({
      message: 'Token inválido o expirado.'
    });

  }
}

module.exports = authMiddleware;
