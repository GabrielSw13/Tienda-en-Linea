import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class EditProductForm extends StatefulWidget {
  final int productId; // ID del producto a editar
  final String nombre;
  final String precio;
  final String descripcion;
  final bool disponibilidad;
  final String? imagenBase64; // Imagen en formato base64

  EditProductForm({
    required this.productId,
    required this.nombre,
    required this.precio,
    required this.descripcion,
    required this.disponibilidad,
    this.imagenBase64,
  });

  @override
  _EditProductFormState createState() => _EditProductFormState();
}

class _EditProductFormState extends State<EditProductForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  bool _availability = true;
  XFile? _imageFile; // Cambiar de File a XFile para adaptarse a image_picker
  String? _currentImageBase64;
  bool _isLoading = false; // Indicar si la actualización está en proceso

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Inicializar controladores con los valores recibidos
    _nameController = TextEditingController(text: widget.nombre);
    _priceController = TextEditingController(text: widget.precio.toString());
    _descriptionController = TextEditingController(text: widget.descripcion);
    _availability = widget.disponibilidad;
    _currentImageBase64 = widget.imagenBase64;
  }

  @override
  void dispose() {
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

  // Función para enviar datos actualizados a la base de datos
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Mostrar el indicador de carga
      });
      _formKey.currentState!.save();

      // Convertir la nueva imagen a base64 si se seleccionó una nueva
      String? imageBase64 = _currentImageBase64;
      if (_imageFile != null) {
        // Convertir XFile a File antes de comprimir
        final file = File(_imageFile!.path);

        // Comprimir la imagen seleccionada antes de convertirla a base64
        final compressedImage = await compressImage(file);
        if (compressedImage != null) {
          imageBase64 = await _convertImageToBase64(compressedImage);
        }
      }

      // Crear un objeto con los datos actualizados del producto
      Map<String, dynamic> updatedProductData = {
        'nombre': _nameController.text,
        'precio': _priceController.text,
        'descripcion': _descriptionController.text,
        'disponibilidad': _availability,
        'foto': imageBase64, // Imagen en formato base64 o imagen actual si no se cambia
      };

      // Llamada HTTP PUT para actualizar el producto en el servidor
      final response = await http.put(
        Uri.parse('http://192.168.0.9:3000/products/${widget.productId}'), // Cambia por tu endpoint de actualización
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedProductData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto actualizado exitosamente.')),
        );

        // Establecer isLoading en false antes de navegar
        setState(() {
          _isLoading = false;
        });

        // Navegar de regreso a la pantalla de lista de productos
        Navigator.pop(context, true); // `true` indica que se realizó un cambio y la lista debe actualizarse
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el producto.')),
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
        title: const Text('Actualizar Producto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Mostrar indicador de carga si _isLoading es true
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
                          ? (_currentImageBase64 != null && _currentImageBase64!.isNotEmpty
                              ? ClipOval(
                                  child: Image.memory(
                                    base64Decode(_currentImageBase64!),
                                    fit: BoxFit.cover,
                                    width: 150,
                                    height: 150,
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ))
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
                          // Campo para el nombre del producto
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Nombre'),
                            validator: (value) {
                              return value!.isEmpty ? 'Este campo es obligatorio' : null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Campo para el precio del producto
                          TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(labelText: 'Precio'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              return value!.isEmpty ? 'Este campo es obligatorio' : null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Campo para la descripción del producto
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descripcion',
                              hintText: 'Breve descripcion del producto',
                            ),
                            maxLines: 2,
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
                              'Actualizar',
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
