import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:realtime_notifs_flutter/src/app/controller/notification_controller.dart';
import 'package:realtime_notifs_flutter/src/app/notification_service.dart';

class NotificationPage extends StatefulWidget {
  final ValueChanged<int>? onUnreadCountChanged; // ← Cambiado a ValueChanged
  final ValueChanged<List<Map<String, dynamic>>>? onMessagesChanged;

  const NotificationPage({
    super.key,
    this.onUnreadCountChanged,
    this.onMessagesChanged,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _adminIdController = TextEditingController(text: '2');
  final _senderIdController = TextEditingController(text: '1');
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  late NotificationService _service;
  List<Map<String, dynamic>> _messages = [];
  int _notifUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _startService();
    _loadInitialMessages();
  }

  void _startService() {
    final adminId = _adminIdController.text;
    // final senderId = _senderIdController.text;

    _service = NotificationService(
      adminId: adminId,
      socketUri: Uri.parse('ws://localhost:3000/cable'),
      onMessage: (raw) {
        final msg = jsonDecode(raw);
        setState(() {
          _messages.insert(0, msg);
        });

        // 🔹 Actualiza la burbuja cada vez que llega un mensaje
        _updateUnreadCount();

        widget.onMessagesChanged?.call(List.from(_messages));
      },
    );
  }


  @override
  void dispose() {
    _service.dispose();
    _adminIdController.dispose();
    // _senderIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final adminId = _adminIdController.text.trim();
    // final senderId = _senderIdController.text.trim();
    final message = _messageController.text.trim();
    if (adminId.isEmpty || message.isEmpty) return;

    final url = Uri.parse('http://localhost:3000/notifications');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender_id': int.parse(_senderIdController.text), // el usuario que envía
        'receiver_id': int.parse(_adminIdController.text),
        'subject' : _subjectController.text.trim(),
        'message': _messageController.text.trim(),
      }),
    );


    if (resp.statusCode == 201 || resp.statusCode == 200) {
      _messageController.clear();
      _subjectController.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notificación enviada')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar')));
    }
  }

  // Reconectar si cambias admin_id
  void _changeAdmin() {
    _service.dispose();
    setState(() => _messages.clear());
    _startService();
    _loadInitialMessages();
  }

  @override
  Widget build(BuildContext context) {
    final notifCount = _notifUnreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notificaciones en tiempo real'),
        // actions: [
        //   Stack(
        //     children: [
        //       IconButton(
        //         icon: Icon(Icons.notifications),
        //         onPressed: () => _showMessagesDialog(),
        //         iconSize: 35.0,
        //       ),
        //       if (notifCount > 0)
        //         Positioned(
        //           right: 4,
        //           top: 0,
        //           child: Container(
        //             padding: EdgeInsets.all(8),
        //             decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        //             child: Text(
        //               notifCount.toString(),
        //               style: TextStyle(color: Colors.white, fontSize: 12),
        //             ),
        //           ),
        //         )
        //     ],
        //   )
        // ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _adminIdController,
                  decoration: InputDecoration(labelText: 'admin_id'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _senderIdController,
                  decoration: InputDecoration(labelText: 'sender_id'),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: _changeAdmin,
                child: Text('Conectar'),
              )
            ]),
            SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Asunto',
                hintText: 'Ingresa el asunto',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Mensaje',
                hintText: 'Ingresa el mensaje',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(children: [
              ElevatedButton(onPressed: _sendNotification, child: Text('Enviar mensaje')),
              SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    _messages.clear();
                  });
                },
                child: Text('Limpiar'),
              )
            ]),
            SizedBox(height: 20),
            Expanded(
              child: _messages.isEmpty
                  ? Center(child: Text('No hay notificaciones recibidas'))
                  : ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index];
                        final isRead = m['read'] == true;
                        final status = m['status'];
                        

                        // Determinar color e icono
                        Color getStatusColor() {
                          if (status == true) return Colors.green;    // Aceptada
                          if (status == false) return Colors.red;     // Rechazada
                          if (!isRead) return Colors.orange;          // No leída
                          return Colors.grey;                         // Leída pero sin acción
                        }

                        IconData getStatusIcon() {
                          if (status == true) return Icons.check_circle;
                          if (status == false) return Icons.cancel;
                          if (!isRead) return Icons.mark_email_unread;
                          return Icons.mark_email_read;
                        }

                        String getStatusText() {
                          if (status == true) return 'Aceptado';
                          if (status == false) return 'Rechazado';
                          return 'Leído';
                        }
                        return ListTile(
                          leading: Icon(
                            getStatusIcon(),
                            color: getStatusColor(),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m['subject']?.toString() ?? 'Sin asunto',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              // Mensaje normal
                              Text(
                                m['message']?.toString() ?? '',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatDate(m['created_at']?.toString() ?? '')),
                              SizedBox(height: 4),
                              TextButton(
                                onPressed: () => _showMessageDetails(context, m),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  minimumSize: Size.zero
                                ),
                                child: Text(
                                  'Ver más detalles',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                )
                              )
                            ],
                          ),
                          trailing: !isRead && status == null
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(
                                    onPressed: () => _acceptMessage(m['id']),
                                    style: TextButton.styleFrom(backgroundColor: Colors.green),
                                    child: Text("Aceptar", style: TextStyle(color: Colors.white)),
                                  ),
                                  SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () => _rejectMessage(m['id']),
                                    style: TextButton.styleFrom(backgroundColor: Colors.red),
                                    child: Text("Rechazar", style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              )
                            : Text(
                                getStatusText(),
                                style: TextStyle(color: getStatusColor(), fontWeight: FontWeight.bold),
                              ),
                        );
                      },
                    ),
            )

          ],
        ),
      ),
    );
  }

  // void _showMessagesDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: Text('Notificaciones (${_messages.length})'),
  //       content: Container(
  //         width: double.maxFinite,
  //         child: _messages.isEmpty
  //             ? Text('No hay notificaciones')
  //             : ListView.builder(
  //                 shrinkWrap: true,
  //                 itemCount: _messages.length,
  //                 itemBuilder: (context, index) {
  //                   final m = _messages[index];
  //                   return ListTile(
  //                     title: Text(m['message']?.toString() ?? ''),
  //                     subtitle: Row(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(_formatDate(m['created_at']?.toString() ?? '')),
  //                         SizedBox(height: 4),
  //                         TextButton(
  //                           onPressed: () => _showMessageDetails(context, m),
  //                           style: TextButton.styleFrom(
  //                             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  //                             minimumSize: Size.zero
  //                           ),
  //                           child: Text(
  //                             'Ver más detalles',
  //                             style: TextStyle(
  //                               fontSize: 12,
  //                               color: Colors.blue,
  //                               decoration: TextDecoration.underline,
  //                             ),
  //                           )
  //                         )
  //                       ],
  //                     ),
  //                   );
  //                 },
  //               ),
  //       ),
  //       actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Cerrar'))],
  //     ),
  //   );
  // }


  // Future<void> _markAsRead(int id) async {
  //   final success = await NotificationController.markAsRead(id);
    
  //   if (success) {
  //     setState(() {
  //       final index = _messages.indexWhere((m) => m['id'] == id);
  //       if (index != -1) _messages[index]['read'] = true;
  //     });
  //     _updateUnreadCount();
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error al marcar notificación')),
  //     );
  //   } 
  // }



  Future<void> _updateUnreadCount() async {
    final adminId = _adminIdController.text.trim();
    final count = await NotificationController.getUnreadCount(adminId);
    setState(() {
      _notifUnreadCount = count;
    });
    
    // Notificar al padre sobre el cambio en el contador
    if (widget.onUnreadCountChanged != null) {
      widget.onUnreadCountChanged!(count); // ← Ahora funciona
    }
  }

  Future<void> _loadInitialMessages() async {
    final adminId = _adminIdController.text.trim();
    final messages = await NotificationController.loadNotifications(adminId);
    setState(() {
      _messages = List<Map<String, dynamic>>.from(messages);
    });
    _updateUnreadCount();
    widget.onMessagesChanged?.call(List.from(_messages));
  }

  Future<void> _acceptMessage(int id) async {
    final success = await NotificationController.acceptNotification(id);
    
    if (success) {
      setState(() {
        final index = _messages.indexWhere((m) => m['id'] == id);
        if (index != -1) {
          _messages[index]['read'] = true;
          _messages[index]['status'] = true;
        }
      });
      _updateUnreadCount();
    }
  }


  Future<void> _rejectMessage(int id) async {
    final success = await NotificationController.rejectNotification(id);
    
    if (success) {
      setState(() {
        final index = _messages.indexWhere((m) => m['id'] == id);
        if (index != -1) {
          _messages[index]['read'] = true;
          _messages[index]['status'] = false;
        }
      });
      _updateUnreadCount();
    }
  }


  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _showMessageDetails(context, m) async{
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Detalles de la notificación"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Asunto:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(m['subject']?.toString() ?? 'Sin asunto'),
                SizedBox(height: 16),
                Text('Mensaje:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(m['message']?.toString() ?? ''),
                SizedBox(height: 16),
                Text('Fecha de envío:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_formatDate(m['created_at']?.toString() ?? '')),
                SizedBox(height: 16),
                Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_getStatusTextDetailed(m)),
                SizedBox(height: 16),
                Text('Remitente:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(m['sender_name']?.toString() ?? ''),
                SizedBox(height: 16),
                // Puedes agregar más campos aquí según lo que tengas en tu mensaje
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), 
              child: Text("Cerrar")
            ),
          ],
        );
      }
    );
  }

  String _getStatusTextDetailed(Map<String, dynamic> message) {
    final isRead = message['read'] == true;
    final status = message['status'];

    if (status == true) return '✅ Aceptada ';
    if (status == false) return '❌ Rechazada';
    if (!isRead) return '📩 No leída';
    return '📨 Leída';
  }
}
