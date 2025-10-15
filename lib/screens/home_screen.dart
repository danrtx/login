import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  /// Cargar imagen de perfil del usuario
  Future<void> _loadProfileImage() async {
    try {
      final imageUrl = await _storageService.getProfileImageUrl();
      if (mounted) {
        setState(() => _profileImageUrl = imageUrl);
      }
    } catch (e) {
      print('Error al cargar imagen de perfil: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('SingleDocs'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Avatar del usuario en el AppBar
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, '/profile');
              _loadProfileImage(); // Recargar imagen al volver
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: _profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _profileImageUrl!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              color: Colors.blue,
                              size: 20,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.blue,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de bienvenida
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: _profileImageUrl != null
                                ? Image.network(
                                    _profileImageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.white,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '¡Bienvenido!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? 'Usuario',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Has iniciado sesión exitosamente en la aplicación.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Información del usuario
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información del Usuario',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Correo electrónico',
                      value: user?.email ?? 'No disponible',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.fingerprint,
                      label: 'ID de usuario',
                      value: user?.id ?? 'No disponible',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: 'Última conexión',
                      value: user?.lastSignInAt?.toString().split('.')[0] ?? 'No disponible',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Acciones rápidas
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      icon: Icons.person,
                      label: 'Mi Perfil',
                      onTap: () async {
                        await Navigator.pushNamed(context, '/profile');
                        _loadProfileImage(); // Recargar imagen al volver
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      icon: Icons.folder,
                      label: 'Mis Documentos',
                      onTap: () {
                        Navigator.pushNamed(context, '/documents');
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      icon: Icons.refresh,
                      label: 'Actualizar información',
                      onTap: () {
                        _loadProfileImage();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Información actualizada'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      icon: Icons.logout,
                      label: 'Cerrar sesión',
                      onTap: _showSignOutDialog,
                      isDestructive: true,
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDestructive ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? Colors.red : Colors.blue,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isDestructive ? Colors.red : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}