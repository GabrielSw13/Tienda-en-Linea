const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser'); // Importar body-parser para manejar solicitudes JSON
const app = express();
const port = process.env.PORT || 3000;
const cors = require('cors');



// Configurar la conexión a la base de datos MySQL en Amazon Web Services
const db = mysql.createConnection({
  host: 'bd-plataforma.claq0we8qr5v.us-east-2.rds.amazonaws.com',
  user: 'admin',
  password: '132808Gz',
  database: 'bdplataforma'
});


db.connect((err) => {
  if (err) {
    console.error('Error conectando a la base de datos: ', err);
    return;
  }
  console.log('Conectado a la base de datos');
});

// Middleware para analizar las solicitudes JSON y habilitar CORS
app.use(bodyParser.json({ limit: '50mb' })); // Aumenta el límite del tamaño del JSON para manejar imágenes grandes
app.use(cors()); // Habilita CORS para todas las rutas

// Ruta para obtener todos los productos
app.get('/products', (req, res) => {
  const query = 'SELECT * FROM productos'; // Ajusta el nombre de la tabla según tu esquema
  db.query(query, (err, results) => {
    if (err) {
      console.error('Error al obtener productos: ', err);
      return res.status(500).send({ message: 'Error al obtener productos', error: err });
    }
    // Convertir la imagen de BLOB a base64 para enviar al cliente
    const products = results.map(product => ({
      id: product.id,
      nombre: product.nombre,
      precio: product.precio,
      descripcion: product.descripcion,
      disponibilidad: product.disponibilidad,
      foto: product.foto ? product.foto.toString('base64') : null, // Convertir BLOB a base64
    }));
    res.send(products);
  });
});

// Ruta para agregar un nuevo producto
app.post('/add-productos', (req, res) => {
  const { nombre, precio, descripcion, disponibilidad, foto } = req.body;

  // Verificar que todos los campos estén presentes
  if (!nombre || !precio || !descripcion || !foto) {
    return res.status(400).send({ message: 'Todos los campos son obligatorios.' });
  }

  try {
    // Convertir la imagen base64 a un Buffer para almacenarla en la base de datos
    const fotoBuffer = Buffer.from(foto, 'base64');

    // Consulta para insertar un nuevo producto en la base de datos
    const query = 'INSERT INTO productos (nombre, precio, descripcion, disponibilidad, foto) VALUES (?, ?, ?, ?, ?)';

    db.query(query, [nombre, precio, descripcion, disponibilidad, fotoBuffer], (err, results) => {
      if (err) {
        console.error('Error al insertar el producto en la base de datos:', err);
        return res.status(500).send({ message: 'Error al insertar el producto en la base de datos', error: err });
      }

      res.send({ message: 'Producto agregado correctamente', id: results.insertId });
    });
  } catch (err) {
    console.error('Error al procesar la imagen:', err);
    res.status(500).send({ message: 'Error al procesar la imagen', error: err });
  }
});

// Ruta para eliminar un producto por ID
app.delete('/products/:id', (req, res) => {
  const productId = req.params.id;

  const query = 'DELETE FROM productos WHERE id = ?';
  db.query(query, [productId], (err, results) => {
    if (err) {
      console.error('Error al eliminar el producto: ', err);
      return res.status(500).send({ message: 'Error al eliminar el producto', error: err });
    }

    if (results.affectedRows === 0) {
      return res.status(404).send({ message: 'Producto no encontrado' });
    }

    res.send({ message: 'Producto eliminado correctamente' });
  });
});

// Ruta para actualizar un producto
app.put('/products/:id', (req, res) => {
  const productId = req.params.id;
  const { nombre, precio, descripcion, disponibilidad, foto } = req.body;

  // Convertir la imagen base64 a Buffer (si se incluye)
  const fotoBuffer = foto ? Buffer.from(foto, 'base64') : null;

  const query = `
    UPDATE productos 
    SET nombre = ?, precio = ?, descripcion = ?, disponibilidad = ?, foto = ? 
    WHERE id = ?
  `;
  db.query(query, [nombre, precio, descripcion, disponibilidad, fotoBuffer, productId], (err, results) => {
    if (err) {
      console.error('Error al actualizar el producto: ', err);
      return res.status(500).send({ message: 'Error al actualizar el producto', error: err });
    }

    if (results.affectedRows === 0) {
      return res.status(404).send({ message: 'Producto no encontrado' });
    }

    res.send({ message: 'Producto actualizado correctamente' });
  });
});

// Ruta de prueba para verificar que el servidor está funcionando
app.get('/', (req, res) => {
  res.send('Servidor funcionando');
});

// Iniciar el servidor en el puerto especificado
app.listen(port, () => {
  console.log(`Servidor escuchando en el puerto ${port}`);
});