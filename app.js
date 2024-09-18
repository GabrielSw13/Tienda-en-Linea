const express = require('express');
const mysql = require('mysql2'); // Cambia a `pg` si usas PostgreSQL
const app = express();
const port = process.env.PORT || 3000;

// Configura la conexión a la base de datos MySQL en Clever Cloud
const db = mysql.createConnection({
  host: 'TU_HOST_CLEVER_CLOUD',
  user: 'TU_USUARIO_CLEVER_CLOUD',
  password: 'TU_PASSWORD_CLEVER_CLOUD',
  database: 'TU_DATABASE_CLEVER_CLOUD'
});

db.connect((err) => {
  if (err) {
    console.error('Error conectando a la base de datos: ', err);
    return;
  }
  console.log('Conectado a la base de datos');
});

app.get('/', (req, res) => {
  res.send('Servidor funcionando');
});

// Ruta para obtener los productos
app.get('/products', (req, res) => {
  const query = 'SELECT * FROM products'; // Cambia 'products' por tu tabla real
  db.query(query, (err, results) => {
    if (err) {
      return res.status(500).send(err);
    }
    res.json(results);
  });
});

app.listen(port, () => {
  console.log(`Servidor escuchando en el puerto ${port}`);
});
