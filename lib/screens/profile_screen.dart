import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  /// Cargar imagen de perfil existente
  Future<void> _loadProfileImage() async {
    setState(() => _isLoading = true);
    
    try {
      final imageUrl = await _storageService.getProfileImageUrl();
      setState(() => _profileImageUrl = imageUrl);
    } catch (e) {
      print('Error al cargar imagen de perfil: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Mostrar opciones para seleccionar imagen
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              if (_profileImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar foto', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteProfileImage();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Seleccionar y subir imagen
  Future<void> _pickAndUploadImage(ImageSource source) async {
    setState(() => _isUploadingImage = true);

    try {
      final image = await _storageService.pickImage(source: source);
      if (image == null) return;

      final imageUrl = await _storageService.uploadProfileImage(image);
      if (imageUrl != null) {
        setState(() => _profileImageUrl = imageUrl);
        _showSnackBar('Imagen de perfil actualizada correctamente', Colors.green);
      } else {
        _showSnackBar('Error al subir la imagen', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  /// Eliminar imagen de perfil
  Future<void> _deleteProfileImage() async {
    setState(() => _isUploadingImage = true);

    try {
      final success = await _storageService.deleteProfileImage();
      if (success) {
        setState(() => _profileImageUrl = null);
        _showSnackBar('Imagen de perfil eliminada', Colors.orange);
      } else {
        _showSnackBar('Error al eliminar la imagen', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  /// Mostrar mensaje
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Cerrar sesión
  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      _showSnackBar('Error al cerrar sesión: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Imagen de perfil
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: _profileImageUrl != null
                                ? Image.network(
                                    _profileImageUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 80,
                                        color: Colors.grey,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        // Botón para cambiar imagen
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: _isUploadingImage
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                              onPressed: _isUploadingImage ? null : _showImageSourceDialog,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Información del usuario
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información Personal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow('Email', user?.email ?? 'No disponible'),
                          const SizedBox(height: 10),
                          _buildInfoRow('ID de Usuario', user?.id ?? 'No disponible'),
                          const SizedBox(height: 10),
                          _buildInfoRow(
                            'Fecha de Registro',
                            user?.createdAt != null
                                ? DateTime.parse(user!.createdAt).toLocal().toString().split(' ')[0]
                                : 'No disponible',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Botones de acción
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/documents');
                          },
                          icon: const Icon(Icons.folder),
                          label: const Text('Mis Documentos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar Sesión'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}