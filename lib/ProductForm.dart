import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ProductForm extends StatefulWidget {
  @override
  _ProductFormState createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  double _price = 0.0;
  String _description = '';
  bool _availability = true;
  XFile? _imageFile; // Almacena la imagen seleccionada como XFile
  bool _isLoading = false; // Indicar si la operación está en curso

  final ImagePicker _picker = ImagePicker();

  // Controladores para limpiar los campos después de agregar el producto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    // Limpiar los controladores cuando el widget se destruya
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Función para seleccionar una imagen
  Future<void> _selectImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile; // Asignar el XFile seleccionado
      });
    }
  }

  // Función para comprimir la imagen seleccionada
  Future<File?> compressImage(File file) async {
    try {
      // Comprimir la imagen utilizando flutter_image_compress
      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        "${file.path}_compressed.jpg",
        quality: 50, // Ajusta la calidad según sea necesario (1-100)
      );

      // Convertir el XFile a File antes de devolverlo
      if (result != null) {
        return File(result.path); // Convertir XFile a File
      }
      return null; // Si la compresión falla, devuelve null
    } catch (e) {
      print("Error durante la compresión: $e");
      return null;
    }
  }

  // Función para convertir la imagen a base64
  Future<String> _convertImageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  // Función para enviar datos a la base de datos incluyendo la imagen en base64
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Mostrar el indicador de carga
      });
      _formKey.currentState!.save();

      // Verificar que se haya seleccionado una imagen
      if (_imageFile == null) {
        setState(() {
          _isLoading = false; // Detener el indicador de carga
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una imagen primero.')),
        );
        return;
      }

      // Convertir XFile a File antes de comprimir
      final file = File(_imageFile!.path);

      // Comprimir la imagen antes de convertirla a base64
      final compressedImage = await compressImage(file);
      if (compressedImage == null) {
        setState(() {
          _isLoading = false; // Detener el indicador de carga en caso de error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al comprimir la imagen.')),
        );
        return;
      }

      // Convertir la imagen comprimida a base64
      String imageBase64 = await _convertImageToBase64(compressedImage);

      // Crear un objeto con los datos del producto
      Map<String, dynamic> productData = {
        'nombre': _name,
        'precio': _price,
        'descripcion': _description,
        'disponibilidad': _availability,
        'foto': imageBase64, // Imagen en formato base64
      };

      // Llamada HTTP POST a la ruta /add-productos
      final response = await http.post(
        Uri.parse('http://192.168.0.9:3000/add-productos'), // Cambia por la dirección IP o dominio de tu servidor
        headers: {'Content-Type': 'application/json'},
        body: json.encode(productData),
      );

      if (response.statusCode == 200) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto agregado exitosamente.')),
        );

        // Limpiar los campos del formulario
        _nameController.clear();
        _priceController.clear();
        _descriptionController.clear();
        setState(() {
          _imageFile = null; // Limpiar la imagen seleccionada
          _isLoading = false; // Detener el indicador de carga
        });

        // Navegar de regreso a la pantalla de Productos
        Navigator.pop(context, true); // `true` indica que se realizó un cambio
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al agregar el producto.')),
        );
        setState(() {
          _isLoading = false; // Detener el indicador de carga en caso de error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Producto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          }, 
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(), // Mostrar Progress Bar cuando _isLoading es true
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Contenedor para la imagen
                  GestureDetector(
                    onTap: _selectImage, // Llamar a la función para seleccionar imagen
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 2.0),
                      ),
                      child: _imageFile == null
                          ? const Center(
                              child: Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey,
                              ),
                            )
                          : ClipOval(
                              child: Image.file(
                                File(_imageFile!.path), // Convertir XFile a File para mostrarlo
                                fit: BoxFit.cover,
                                width: 150,
                                height: 150,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'imagen +',
                    style: TextStyle(color: Color.fromRGBO(30, 66, 230, 1)),
                  ),
                  const SizedBox(height: 20),

                  // Formulario
                  Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10.0,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Campo para el nombre del producto con controlador
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Nombre'),
                            onSaved: (value) {
                              _name = value ?? '';
                            },
                            validator: (value) {
                              return value!.isEmpty ? 'Este campo es obligatorio' : null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Campo para el precio del producto con controlador
                          TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(labelText: 'Precio'),
                            keyboardType: TextInputType.number,
                            onSaved: (value) {
                              _price = double.tryParse(value ?? '0') ?? 0.0;
                            },
                            validator: (value) {
                              return value!.isEmpty ? 'Este campo es obligatorio' : null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Campo para la descripción del producto con controlador
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descripcion',
                              hintText: 'Breve descripcion del producto',
                            ),
                            maxLines: 2,
                            onSaved: (value) {
                              _description = value ?? '';
                            },
                            validator: (value) {
                              return value!.isEmpty ? 'Este campo es obligatorio' : null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Switch para la disponibilidad
                          SwitchListTile(
                            title: const Text('Disponibilidad'),
                            value: _availability,
                            onChanged: (value) {
                              setState(() {
                                _availability = value;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                          const SizedBox(height: 20),

                          // Botón de envío
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            onPressed: _submitForm,
                            child: const Text(
                              'Añadir',
                              style: TextStyle(fontSize: 18.0, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
