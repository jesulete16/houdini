import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class FilePackerPage extends StatefulWidget {
  const FilePackerPage({super.key});

  @override
  _FilePackerPageState createState() => _FilePackerPageState();
}

class _FilePackerPageState extends State<FilePackerPage> {
  final supabase = Supabase.instance.client;
  bool isUploading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  final TextEditingController informationController = TextEditingController();
  final TextEditingController singerController = TextEditingController();
  XFile? _imageFile;
  String? _previewUrl;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );

    if (image != null) {
      setState(() {
        _imageFile = image;
        _previewUrl = image.path;
      });
    }
  }

  Future<String?> _uploadImageToSupabase() async {
    if (_imageFile == null) return null;

    try {
      final String fileName = '${DateTime.now().toIso8601String()}.jpg';
      final bytes = await _imageFile!.readAsBytes();

      await supabase.storage.from('images').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
        ),
      );

      final String imageUrl = supabase
          .storage
          .from('images')
          .getPublicUrl(fileName);

      return imageUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir la imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _uploadPlaylist() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes estar registrado para subir discos.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una imagen')),
      );
      return;
    }

    setState(() => isUploading = true);
    try {
      final imageUrl = await _uploadImageToSupabase();
      if (imageUrl == null) throw Exception('Error al subir la imagen');

      await supabase.from('playlist').insert({
        'name': nameController.text.trim(),
        'url': urlController.text.trim(),
        'imagen': imageUrl,
        'information': informationController.text.trim(),
        'singer': singerController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disco subido correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      _clearForm();
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir el disco: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  void _clearForm() {
    nameController.clear();
    urlController.clear();
    informationController.clear();
    singerController.clear();
    setState(() {
      _imageFile = null;
      _previewUrl = null;
    });
  }

  Widget _buildImagePreview() {
    if (_previewUrl == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
          SizedBox(height: 10),
          Text('Seleccionar imagen'),
        ],
      );
    }

    return kIsWeb
        ? Image.network(_previewUrl!, fit: BoxFit.cover)
        : Image.file(File(_previewUrl!), fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NUEVO DISCO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 24,
          ),
        ),
        backgroundColor: Color(0xFF0A0A0A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
      ),
      backgroundColor: Color(0xFF0A0A0A),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 8,
                  color: Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: Color(0xFF00E5FF).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 250,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Color(0xFF00E5FF).withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF00E5FF).withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: _buildImagePreview(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: nameController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'NOMBRE DEL DISCO',
                            labelStyle: TextStyle(color: Color(0xFF00E5FF)),
                            prefixIcon: Icon(Icons.album, color: Color(0xFF00E5FF)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF00E5FF)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF00E5FF).withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF00E5FF)),
                            ),
                            filled: true,
                            fillColor: Color(0xFF2A2A2A),
                          ),
                          validator: (value) =>
                          value?.isEmpty ?? true ? 'Por favor ingresa un nombre' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: urlController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'URL DE YOUTUBE',
                            labelStyle: TextStyle(color: Color(0xFF00E5FF)),
                            prefixIcon: Icon(Icons.play_circle_outline, color: Color(0xFF00E5FF)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF00E5FF).withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF00E5FF)),
                            ),
                            filled: true,
                            fillColor: Color(0xFF2A2A2A),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Por favor ingresa la URL';
                            if (!value!.contains('youtube.com')) return 'Debe ser una URL de YouTube';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: informationController,
                          style: TextStyle(color: Colors.white),
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'INFORMACIÓN DEL DISCO',
                            labelStyle: TextStyle(color: Color(0xFF00E5FF)),
                            prefixIcon: Icon(Icons.info_outline, color: Color(0xFF00E5FF)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF00E5FF).withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF00E5FF)),
                            ),
                            filled: true,
                            fillColor: Color(0xFF2A2A2A),
                          ),
                          validator: (value) =>
                          value?.isEmpty ?? true ? 'Por favor ingresa la información del disco' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: singerController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'NOMBRE DEL CANTANTE',
                            labelStyle: TextStyle(color: Color(0xFF00E5FF)),
                            prefixIcon: Icon(Icons.person, color: Color(0xFF00E5FF)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF00E5FF)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF00E5FF).withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Color(0xFF00E5FF)),
                            ),
                            filled: true,
                            fillColor: Color(0xFF2A2A2A),
                          ),
                          validator: (value) =>
                          value?.isEmpty ?? true ? 'Por favor ingresa el nombre del cantante' : null,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: isUploading ? null : _uploadPlaylist,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00E5FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: isUploading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                              'SUBIR DISCO',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back, color: Color(0xFF00E5FF)),
                  label: Text(
                    'VOLVER AL MENÚ',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    urlController.dispose();
    informationController.dispose();
    singerController.dispose();
    super.dispose();
  }
}