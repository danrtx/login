import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../services/storage_service.dart';
import 'document_preview_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final StorageService _storageService = StorageService();
  List<FileObject> _documents = [];
  List<FileObject> _filteredDocuments = [];
  bool _isLoading = true;
  bool _isUploading = false;
  String _searchQuery = '';
  String _selectedFilter = 'Todos';
  
  final List<String> _filterOptions = [
    'Todos',
    'Imágenes',
    'Documentos',
    'Videos',
    'Audio',
    'PDF',
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    
    try {
      final documents = await _storageService.getUserDocuments('documents');
      setState(() {
        _documents = documents;
        _applyFilters();
      });
    } catch (e) {
      _showErrorSnackBar('Error al cargar documentos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<FileObject> filtered = _documents;

    // Aplicar filtro de búsqueda
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) =>
          doc.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Aplicar filtro por tipo
    if (_selectedFilter != 'Todos') {
      filtered = filtered.where((doc) {
        final fileInfo = _storageService.getFileInfo(doc);
        switch (_selectedFilter) {
          case 'Imágenes':
            return fileInfo['type'] == 'Imagen';
          case 'Documentos':
            return ['Word', 'Excel', 'PowerPoint', 'Texto'].contains(fileInfo['type']);
          case 'Videos':
            return fileInfo['type'] == 'Video';
          case 'Audio':
            return fileInfo['type'] == 'Audio';
          case 'PDF':
            return fileInfo['type'] == 'PDF';
          default:
            return true;
        }
      }).toList();
    }

    setState(() {
      _filteredDocuments = filtered;
    });
  }

  Future<void> _uploadFiles() async {
    final files = await _storageService.pickFiles(allowMultiple: true);
    
    if (files == null || files.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      for (final file in files) {
        if (file.bytes != null) {
          await _storageService.uploadDocument(file, 'documents');
        }
      }
      
      _showSuccessSnackBar('${files.length} archivo(s) subido(s) exitosamente');
      await _loadDocuments();
    } catch (e) {
      _showErrorSnackBar('Error al subir archivos: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteDocument(FileObject document) async {
    final confirmed = await _showDeleteConfirmation(document.name);
    if (!confirmed) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final filePath = 'documents/${document.name}';
      final success = await _storageService.deleteDocument('$userId/$filePath');
      
      if (success) {
        _showSuccessSnackBar('Archivo eliminado exitosamente');
        await _loadDocuments();
      } else {
        _showErrorSnackBar('Error al eliminar el archivo');
      }
    } catch (e) {
      _showErrorSnackBar('Error al eliminar archivo: $e');
    }
  }

  Future<bool> _showDeleteConfirmation(String fileName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _downloadFile(FileObject document) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final filePath = '$userId/documents/${document.name}';
    _storageService.downloadFile(document.name, filePath);
    _showSuccessSnackBar('Descargando ${document.name}...');
  }

  void _previewDocument(FileObject document) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final filePath = '$userId/documents/${document.name}';
    
    // Obtener el tipo de archivo desde el nombre
    String fileType = '';
    if (document.name.contains('.')) {
      fileType = document.name.split('.').last.toLowerCase();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentPreviewScreen(
          fileName: document.name,
          filePath: filePath,
          fileType: fileType,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SingleDocs - Documentos'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadDocuments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar documentos...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filtros
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                              _applyFilters();
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.blue[100],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de documentos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDocuments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _selectedFilter != 'Todos'
                                  ? 'No se encontraron documentos'
                                  : 'No tienes documentos aún',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toca el botón + para subir archivos',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredDocuments.length,
                        itemBuilder: (context, index) {
                          final document = _filteredDocuments[index];
                          final fileInfo = _storageService.getFileInfo(document);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[50],
                                child: Text(
                                  fileInfo['icon'],
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              title: Text(
                                fileInfo['name'],
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${fileInfo['type']} • ${fileInfo['size']}'),
                                  if (fileInfo['lastModified'] != null)
                                    Text(
                                      'Modificado: ${_formatDate(fileInfo['lastModified'])}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => _previewDocument(document),
                                    icon: const Icon(Icons.visibility),
                                    color: Colors.blue,
                                    tooltip: 'Vista previa',
                                  ),
                                  PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'preview':
                                      _previewDocument(document);
                                      break;
                                    case 'download':
                                      _downloadFile(document);
                                      break;
                                    case 'delete':
                                      _deleteDocument(document);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'preview',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Vista previa'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'download',
                                    child: Row(
                                      children: [
                                        Icon(Icons.download),
                                        SizedBox(width: 8),
                                        Text('Descargar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _uploadFiles,
        backgroundColor: Colors.blue,
        child: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Desconocido';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Desconocido';
    }
  }
}