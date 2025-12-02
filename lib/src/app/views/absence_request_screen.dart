import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class AbsenceRequestScreen extends StatefulWidget {
  final List<DateTime?> dates;
  final String tipoAusencia;
  final int diasHabiles;
  const AbsenceRequestScreen({
    super.key,
    required this.dates,
    required this.tipoAusencia,
    required this.diasHabiles,
  });

  @override
  State<StatefulWidget> createState() => _AbsenceRequestScreen();
}

class _AbsenceRequestScreen extends State<AbsenceRequestScreen> {
  final TextEditingController _descripcionController = TextEditingController();
  late String fechaInicio;
  late String fechaFin;
  File? _selectedFile;
  String? _fileName;
  bool _fileIsRequired = true;
  Uint8List? _selectedWebFileBytes;

  @override
  void initState() {
    super.initState();

    fechaInicio = widget.dates[0]!.toString().split(" ")[0];

    fechaFin = (widget.dates.length > 1 && widget.dates[1] != null)
        ? widget.dates[1]!.toString().split(" ")[0]
        : fechaInicio;
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (kIsWeb) {
      // Para web: solo PDF
      _pickDocument();
    } else {
      // Para móvil: mostrar opciones
      final result = await showModalBottomSheet<int>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Tomar foto'),
                onTap: () => Navigator.pop(context, 1),
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Subir imagen'),
                onTap: () => Navigator.pop(context, 2),
              ),
              ListTile(
                leading: Icon(Icons.insert_drive_file),
                title: Text('Subir archivo'),
                onTap: () => Navigator.pop(context, 3),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, 0),
                child: Text('Cancelar'),
              ),
            ],
          ),
        ),
      );

      if (result == 1) {
        await _takePhoto();
      } else if (result == 2) {
        await _pickImage();
      } else if (result == 3) {
        await _pickDocument();
      }
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        _fileName = 'foto.jpg';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        _fileName = pickedFile.name;
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: kIsWeb,      // Importante: en Web se deben obtener los bytes
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final picked = result.files.first;

      setState(() {
        _fileName = picked.name;

        if (kIsWeb) {
          // En Web NO existe File(path)
          _selectedWebFileBytes = picked.bytes; // <-- guarda los bytes
          _selectedFile = File(picked.path!);  
        } else {
          // En móvil/escritorio sí existe path real
          _selectedFile = File(picked.path!);
          _selectedWebFileBytes = null;
          
        }
      });

      print("Archivo seleccionado: ${picked.name}");
    }
  }


  void _showFileTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar tipo de archivo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf),
              title: Text('PDF'),
              onTap: () {
                Navigator.pop(context);
                _simulateFilePick('PDF');
              },
            ),
            ListTile(
              leading: Icon(Icons.description),
              title: Text('Documento'),
              onTap: () {
                Navigator.pop(context);
                _simulateFilePick('DOC');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _simulateFilePick(String type) {
    setState(() {
      _selectedFile = File('/simulated/path/to/file.$type.toLowerCase()');
      _fileName = 'documento.${type.toLowerCase()}';
    });
  }

  void _showWebFilePicker() {
    // Para web, usar input file nativo
    // En implementación real usarías file_picker que soporta web
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cargar archivo PDF'),
        content: Text('Para la versión web, solo se permiten archivos PDF.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _simulateFilePick('PDF');
            },
            child: Text('Simular carga PDF'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
    });
  }

  bool _validateForm() {
    if (_fileIsRequired && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, adjunte un archivo antes de enviar'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _submitRequest() async {
    if (_validateForm()) {
      await sendRequest(
        file: _selectedFile,
        fileName: _fileName!,
        webBytes: _selectedWebFileBytes,
        descripcion: _descripcionController.text,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitud de ${widget.tipoAusencia}',
            style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 7, 46, 131),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey.shade200),
                      ),
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Al aceptar se restarán ${widget.diasHabiles} días de su calendario.',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🔹 Datos de la ausencia
                    Text(
                      'Tipo de ausencia: ${widget.tipoAusencia}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Fechas seleccionadas:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Del $fechaInicio al $fechaFin',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // 🔹 Campo de texto
                    const Text(
                      'Descripción',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Escribe un comentario (opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 🔹 Botón para cargar archivos
                    Text(
                      'Adjuntar archivo${_fileIsRequired ? ' *' : ''}',
                      style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      kIsWeb
                          ? 'Solo se permiten archivos PDF'
                          : 'Puede tomar una foto, subir una imagen o cargar un archivo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botón para seleccionar archivo
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: Icon(Icons.attach_file),
                        label: Text(
                          kIsWeb
                              ? 'Cargar archivo PDF'
                              : 'Seleccionar archivo',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mostrar archivo seleccionado
                    if (_selectedFile != null)
                      Card(
                        color: Colors.green[50],
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(Icons.attach_file, color: Colors.green),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _fileName!,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Archivo listo para enviar',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: _removeFile,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_selectedFile == null && _fileIsRequired)
                      Text(
                        'Debe adjuntar un archivo para continuar',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: _submitRequest,
            icon: const Icon(Icons.send_rounded, color: Colors.white),
            label: const Text(
              'Solicitar',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              shadowColor: Colors.black45,
              elevation: 5,
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _sendNotification(String ausencia, DateTime start, DateTime end, String descripcion) async {
    final url = Uri.parse('http://localhost:3000/notifications');
    
    // Formatear las fechas para mostrarlas mejor
    final fechaInicio = "${start.day}/${start.month}/${start.year}";
    final fechaFin = "${end.day}/${end.month}/${end.year}";
    final dias = end.difference(start).inDays + 1;
    
    // Crear el mensaje con toda la información
    final mensaje = """
    Solicitud de $ausencia

    Fechas: Del $fechaInicio al $fechaFin
    Días solicitados: $dias
    ${descripcion.isNotEmpty ? 'Descripción: $descripcion' : 'Sin comentarios adicionales'}
    """;

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': 1, // el usuario que envía
          'receiver_id': 2,
          'subject': "Solicitud de $ausencia",
          'message': mensaje, // ← Ahora con toda la información
        }),
      );
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Solicitud enviada correctamente',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          )
        );
        // Opcional: regresar a la pantalla anterior después de enviar
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar la solicitud'))
        );
      }
    }
    
}

Future<void> sendRequest({
  required File? file,
  required String fileName,
  required Uint8List? webBytes, // <-- nuevo
  required String descripcion,
  required String fechaInicio,
  required String fechaFin,
}) async {
  final url = Uri.parse("https://tu-api.com/solicitud");

  final request = http.MultipartRequest("POST", url);

  // Campos normales
  request.fields["descripcion"] = descripcion;
  request.fields["fecha_inicio"] = fechaInicio;
  request.fields["fecha_fin"] = fechaFin;

  // Detectar MIME (soporta PDF automáticamente)
  final mimeType = lookupMimeType(fileName) ?? "application/octet-stream";
  final mediaType = MediaType.parse(mimeType);

  // ================================
  //        MANEJO DEL ARCHIVO
  // ================================
  if (kIsWeb) {
    if (webBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'archivo',
          webBytes,
          filename: fileName,
          contentType: mediaType,
        ),
      );
    }
  }else {
    // ANDROID / IOS / DESKTOP — archivo real
    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'archivo',
          file.path,
          filename: fileName,
          contentType: mediaType,
        ),
      );
    }
  }

  // ================================
  //       DEBUG: LO QUE SE ENVÍA
  // ================================
  print("=== DATOS QUE SE MANDARÁN AL BACK ===");
  print("URL: $url");

  print("Campos:");
  request.fields.forEach((key, value) {
    print("  $key: $value");
  });

  if (request.files.isNotEmpty) {
    final f = request.files.first;

    print("Archivo adjunto:");
    print("  Campo: ${f.field}");
    print("  Nombre: ${f.filename}");
    print("  MIME: ${f.contentType}");
    print("  Tamaño (bytes): ${f.length}");
    print(kIsWeb
        ? "  Archivo Web (bytes en memoria)"
        : "  Path real: ${file?.path}");
  } else {
    print("No se adjuntó archivo");
  }

  print("=======================================");

  // ================================
  //            ENVÍO
  // ================================
  final response = await request.send();
  final resBody = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    print("Solicitud enviada correctamente");
  } else {
    print("Error al enviar solicitud: ${response.statusCode}");
    print(resBody);
  }
}
