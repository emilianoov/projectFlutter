import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AbsenceRequestScreen extends StatefulWidget{
  final List<DateTime?> dates;
  final String tipoAusencia;

  const AbsenceRequestScreen({
    super.key,
    required this.dates,
    required this.tipoAusencia,
  });


  @override
  State<StatefulWidget> createState() => _AbsenceRequestScreen();
}

class _AbsenceRequestScreen extends State<AbsenceRequestScreen> {
  final TextEditingController _descripcionController = TextEditingController();

  @override
  void dispose() {
    _descripcionController.dispose(); // Importante: limpiar el controlador
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.dates[0]!;
    final end = widget.dates[1]!;
    final dias = end.difference(start).inDays + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitud de ${widget.tipoAusencia}', style: TextStyle(color: Colors.white),),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 7, 46, 131),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                              'Al aceptar se restarán $dias días de su calendario.',
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Del ${widget.dates[0].toString().split(" ")[0]} '
                      'al ${widget.dates[1].toString().split(" ")[0]}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // 🔹 Campo de texto
                    const Text(
                      'Descripción',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          onPressed: () => _sendNotification(
            widget.tipoAusencia,
            widget.dates[0]!,
            widget.dates[1]!,
            _descripcionController.text, // ← Pasa la descripción
          ),
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
