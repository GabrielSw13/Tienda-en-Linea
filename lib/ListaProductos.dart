import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:plataforma/Editarproductos.dart';
import 'package:plataforma/ProductForm.dart';


class Product {
  final int id;
  final String nombre;
  final String precio;
  final String descripcion;
  final bool disponibilidad;
  final String? imagenBase64;

  Product({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.descripcion,
    required this.disponibilidad,
    this.imagenBase64,
  });
}

class ListaProductos extends StatefulWidget {
  @override
  _ListaProductosState createState() => _ListaProductosState();
}

class _ListaProductosState extends State<ListaProductos> {
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts(); // Obtener productos al iniciar la pantalla
  }

  // Función para obtener la lista de productos desde la base de datos
  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.0.9:3000/products')); // Cambia por tu endpoint

      if (response.statusCode == 200) {
        final List<dynamic> productData = json.decode(response.body);
        setState(() {
        _products = productData.map((data) {
          return Product(
            id: data['id'],
            nombre: data['nombre'],
            precio: data['precio'],
            descripcion: data['descripcion'],
            disponibilidad: data['disponibilidad'] == 1, // Convertir `1` a `true` y `0` a `false`
            imagenBase64: data['foto'],
          );
        }).toList();

        });
      } else {
        throw Exception('Error al obtener productos');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Función para eliminar un producto
  Future<void> _deleteProduct(int productId) async {
    try {
      final response = await http.delete(Uri.parse('http://192.168.0.9:3000/products/$productId')); // Cambia por tu endpoint de eliminación
      if (response.statusCode == 200) {
        setState(() {
          _products.removeWhere((product) => product.id == productId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado exitosamente')),
        );
      } else {
        throw Exception('Error al eliminar el producto');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar el producto')),
      );
    }
  }

// Función para navegar a la pantalla de edición de producto
void _editProduct(Product product) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditProductForm(
        productId: product.id,
        nombre: product.nombre,
        precio: product.precio,
        descripcion: product.descripcion,
        disponibilidad: product.disponibilidad,
        imagenBase64: product.imagenBase64,
      ),
    ),
  ).then((value) {
    if (value == true) {
      _fetchProducts(); // Actualiza la lista de productos al regresar de la pantalla de edición
    }
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
      ),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            elevation: 5,
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: product.imagenBase64 != null && product.imagenBase64!.isNotEmpty
                    ? Image.memory(
                        base64Decode(product.imagenBase64!.replaceAll("data:image/png;base64,", "").replaceAll("data:image/jpeg;base64,", "")),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
              title: Text(
                product.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('\$${product.precio}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón de Eliminar con diálogo de confirmación
                  TextButton(
                    onPressed: () => _showDeleteConfirmationDialog(product), // Mostrar el diálogo de confirmación
                    child: const Text(
                      'eliminar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  // Botón de Editar
                  TextButton(
                    onPressed: () => _editProduct(product), // Navegar a la pantalla de edición
                    child: const Text(
                      'editar',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // Botón flotante para agregar un nuevo producto
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductForm()), // Asegúrate de importar ProductForm
          ).then((value) {
            if (value == true) {
              _fetchProducts(); // Actualiza la lista de productos al regresar de la pantalla de agregar
            }
          });
        },
        child: const Icon(Icons.add),
        backgroundColor: Color.fromARGB(255, 214, 34, 34),
      ),
    );
  }

  // Función para mostrar el diálogo de confirmación antes de eliminar un producto
  Future<void> _showDeleteConfirmationDialog(Product product) async {
    final bool? shouldDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmación'),
          content: Text('¿Estás seguro de eliminar el producto "${product.nombre}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cerrar el diálogo y devolver false
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Cerrar el diálogo y devolver true
              },
              child: const Text('Aceptar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      // Si el usuario presionó "Aceptar", eliminamos el producto
      _deleteProduct(product.id);
    }
  }
}
