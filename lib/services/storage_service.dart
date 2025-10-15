import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Bucket names
  static const String profileImagesBucket = 'images';
  static const String documentsBucket = 'images';

  /// Seleccionar imagen desde galería o cámara
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      return null;
    }
  }

  /// Redimensionar imagen para optimizar el almacenamiento
  Future<Uint8List?> resizeImage(Uint8List imageBytes, {int maxSize = 512}) async {
    try {
      // Decodificar la imagen
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Redimensionar manteniendo la proporción
      img.Image resized = img.copyResize(
        image,
        width: image.width > image.height ? maxSize : null,
        height: image.height > image.width ? maxSize : null,
      );

      // Convertir de vuelta a bytes
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (e) {
      print('Error al redimensionar imagen: $e');
      return null;
    }
  }

  /// Subir imagen de perfil del usuario
  Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Leer los bytes del archivo
      final bytes = await imageFile.readAsBytes();
      
      // Redimensionar la imagen
      final resizedBytes = await resizeImage(bytes);
      if (resizedBytes == null) {
        throw Exception('Error al procesar la imagen');
      }

      // Nombre del archivo único
      final fileName = 'profile_$userId.jpg';
      final filePath = '$userId/$fileName';

      // Subir a Supabase Storage
      await _supabase.storage
          .from(profileImagesBucket)
          .uploadBinary(
            filePath,
            resizedBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true, // Sobrescribir si ya existe
            ),
          );

      // Obtener URL pública
      final publicUrl = _supabase.storage
          .from(profileImagesBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error al subir imagen de perfil: $e');
      return null;
    }
  }

  /// Obtener URL de la imagen de perfil del usuario
  Future<String?> getProfileImageUrl() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final fileName = 'profile_$userId.jpg';
      final filePath = '$userId/$fileName';

      // Verificar si el archivo existe
      final files = await _supabase.storage
          .from(profileImagesBucket)
          .list(path: userId);

      final fileExists = files.any((file) => file.name == fileName);
      if (!fileExists) return null;

      // Obtener URL pública
      final publicUrl = _supabase.storage
          .from(profileImagesBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error al obtener imagen de perfil: $e');
      return null;
    }
  }

  /// Eliminar imagen de perfil del usuario
  Future<bool> deleteProfileImage() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final fileName = 'profile_$userId.jpg';
      final filePath = '$userId/$fileName';

      await _supabase.storage
          .from(profileImagesBucket)
          .remove([filePath]);

      return true;
    } catch (e) {
      print('Error al eliminar imagen de perfil: $e');
      return false;
    }
  }

  /// Subir documento/archivo general
  Future<String?> uploadDocument(PlatformFile file, String folder) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Leer los bytes del archivo
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('No se pudieron leer los bytes del archivo');
      }
      
      // Generar nombre único para el archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${file.name}';
      final filePath = '$userId/$folder/$fileName';

      // Subir a Supabase Storage
      await _supabase.storage
          .from(documentsBucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Obtener URL pública
      final publicUrl = _supabase.storage
          .from(documentsBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error al subir documento: $e');
      return null;
    }
  }

  /// Listar documentos del usuario en una carpeta específica
  Future<List<FileObject>> getUserDocuments(String folder) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final files = await _supabase.storage
          .from(documentsBucket)
          .list(path: '$userId/$folder');

      return files;
    } catch (e) {
      print('Error al listar documentos: $e');
      return [];
    }
  }

  /// Eliminar documento
  Future<bool> deleteDocument(String filePath) async {
    try {
      print('Intentando eliminar archivo: $filePath');
      print('Bucket utilizado: $documentsBucket');
      
      final response = await _supabase.storage
          .from(documentsBucket)
          .remove([filePath]);
      
      print('Respuesta de eliminación: $response');
      return true;
    } catch (e) {
      print('Error al eliminar documento: $e');
      print('Tipo de error: ${e.runtimeType}');
      print('Ruta del archivo: $filePath');
      print('Bucket: $documentsBucket');
      return false;
    }
  }

  /// Seleccionar archivos múltiples
  Future<List<PlatformFile>?> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: true,
      );

      return result?.files;
    } catch (e) {
      print('Error al seleccionar archivos: $e');
      return null;
    }
  }

  /// Obtener información del archivo
  Map<String, dynamic> getFileInfo(FileObject fileObject) {
    final fileName = path.basename(fileObject.name);
    final extension = path.extension(fileName).toLowerCase();
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
    
    // Determinar el tipo de archivo
    String fileType = 'Otro';
    String icon = '📄';
    
    if (mimeType.startsWith('image/')) {
      fileType = 'Imagen';
      icon = '🖼️';
    } else if (mimeType.startsWith('video/')) {
      fileType = 'Video';
      icon = '🎥';
    } else if (mimeType.startsWith('audio/')) {
      fileType = 'Audio';
      icon = '🎵';
    } else if (mimeType.contains('pdf')) {
      fileType = 'PDF';
      icon = '📕';
    } else if (mimeType.contains('word') || extension == '.docx' || extension == '.doc') {
      fileType = 'Word';
      icon = '📘';
    } else if (mimeType.contains('excel') || extension == '.xlsx' || extension == '.xls') {
      fileType = 'Excel';
      icon = '📗';
    } else if (mimeType.contains('powerpoint') || extension == '.pptx' || extension == '.ppt') {
      fileType = 'PowerPoint';
      icon = '📙';
    } else if (mimeType.contains('text/')) {
      fileType = 'Texto';
      icon = '📝';
    }

    return {
      'name': fileName,
      'type': fileType,
      'icon': icon,
      'size': _formatFileSize(fileObject.metadata?['size'] ?? 0),
      'lastModified': fileObject.updatedAt,
      'mimeType': mimeType,
    };
  }

  /// Formatear tamaño de archivo
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Descargar archivo
  Future<void> downloadFile(String fileName, String filePath) async {
    try {
      final url = _supabase.storage
          .from(documentsBucket)
          .getPublicUrl(filePath);
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error al descargar archivo: $e');
    }
  }

  /// Obtener URL de descarga
  String getDownloadUrl(String filePath) {
    return _supabase.storage
        .from(documentsBucket)
        .getPublicUrl(filePath);
  }

  /// Buscar archivos por nombre
  Future<List<FileObject>> searchFiles(String query, String folder) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final allFiles = await getUserDocuments(folder);
      
      return allFiles.where((file) => 
        file.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      print('Error al buscar archivos: $e');
      return [];
    }
  }
}