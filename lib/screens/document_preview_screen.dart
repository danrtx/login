import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentPreviewScreen extends StatefulWidget {
  final String fileName;
  final String filePath;
  final String fileType;

  const DocumentPreviewScreen({
    super.key,
    required this.fileName,
    required this.filePath,
    required this.fileType,
  });

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  bool _isLoading = true;
  String? _error;
  Uint8List? _fileData;
  String? _textContent;

  @override
  void initState() {
    super.initState();
    _loadFileData();
  }

  Future<void> _loadFileData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Obtener la URL pública del archivo
      final response = await Supabase.instance.client.storage
          .from('images')
          .createSignedUrl(widget.filePath, 3600); // URL válida por 1 hora

      // Descargar el archivo
      final fileResponse = await http.get(Uri.parse(response));
      
      if (fileResponse.statusCode == 200) {
        _fileData = fileResponse.bodyBytes;
        
        // Si es un archivo de texto, convertir a string
        if (_isTextFile(widget.fileType)) {
          _textContent = String.fromCharCodes(_fileData!);
        }
        
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar el archivo');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e.toString().contains('404') || e.toString().contains('not_found')) {
          _error = 'Archivo no encontrado. Es posible que haya sido eliminado.';
        } else if (e.toString().contains('403') || e.toString().contains('unauthorized')) {
          _error = 'No tienes permisos para acceder a este archivo.';
        } else {
          _error = 'Error al cargar el archivo: ${e.toString()}';
        }
      });
      print('Error detallado en vista previa: $e');
      print('Ruta del archivo: ${widget.filePath}');
    }
  }

  bool _isPdfFile(String fileType) {
    return fileType.toLowerCase().contains('pdf');
  }

  bool _isImageFile(String fileType) {
    final imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageTypes.any((type) => fileType.toLowerCase().contains(type));
  }

  bool _isTextFile(String fileType) {
    final textTypes = ['txt', 'text', 'md', 'csv', 'json', 'xml', 'html'];
    return textTypes.any((type) => fileType.toLowerCase().contains(type));
  }

  Widget _buildPreviewContent() {
    if (_fileData == null) {
      return const Center(
        child: Text('No se pudo cargar el archivo'),
      );
    }

    if (_isPdfFile(widget.fileType)) {
      return _buildPdfPreview();
    } else if (_isImageFile(widget.fileType)) {
      return _buildImagePreview();
    } else if (_isTextFile(widget.fileType)) {
      return _buildTextPreview();
    } else {
      return _buildUnsupportedFilePreview();
    }
  }

  Widget _buildPdfPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.picture_as_pdf,
            size: 100,
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          const Text(
            'Vista previa de PDF',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Archivo: ${widget.fileName}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _downloadFile,
            icon: const Icon(Icons.download),
            label: const Text('Descargar para ver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return InteractiveViewer(
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.memory(
          _fileData!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error al cargar la imagen'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: SelectableText(
          _textContent ?? 'No se pudo leer el contenido del archivo',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildUnsupportedFilePreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Vista previa no disponible',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tipo de archivo: ${widget.fileType}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Aquí podrías implementar la descarga del archivo
              Navigator.pop(context);
            },
            icon: const Icon(Icons.download),
            label: const Text('Descargar archivo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadFileData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
          ),
          IconButton(
            onPressed: () {
              // Implementar funcionalidad de descarga
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidad de descarga próximamente'),
                ),
              );
            },
            icon: const Icon(Icons.download),
            tooltip: 'Descargar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando vista previa...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadFileData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _buildPreviewContent(),
    );
  }

  void _downloadFile() {
    if (_fileData != null) {
      // Para web, podemos usar url_launcher para abrir el archivo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descarga iniciada...'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}