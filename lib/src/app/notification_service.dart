// import 'dart:convert';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class NotificationService {
//   final String adminId;
//   late WebSocketChannel channel;
//   Function(dynamic)? onMessage;


//   NotificationService(this.adminId, {this.onMessage}) {
//     channel = WebSocketChannel.connect(
//       Uri.parse('ws://localhost:3000/cable'),
//     );

//     // Suscripción al canal
//     channel.sink.add(jsonEncode({
//       "command": "subscribe",
//       "identifier": jsonEncode({"channel": "NotificationsChannel", "admin_id": adminId})
//     }));

//     // Escuchar mensajes entrantes
//     channel.stream.listen((event) {
//       final data = jsonDecode(event);

//       // Ignorar mensajes de control de ActionCable
//       if (data['type'] == 'ping' || data['type'] == 'confirm_subscription' || data['type'] == 'welcome') {
//         return;
//       }

//       // Procesar solo mensajes reales
//       if (data['message'] != null) {
//         print("📩 Mensaje real recibido: ${data['message']}");
//         onMessage?.call(data['message']);
//       }
//     });

//   }

//   void dispose() {
//     channel.sink.close();
//   }
// }


// lib/services/notification_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class NotificationService {
  final String adminId;
  final Uri socketUri;
  late WebSocketChannel _channel;
  Function(dynamic)? onMessage;
  StreamController<Map<String, dynamic>> _controller = StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  NotificationService({
    required this.adminId,
    required this.socketUri, // e.g. Uri.parse('ws://localhost:3000/cable')
    required this.onMessage
  }) {
    _connect();
  }

  void _connect() {
    _channel = WebSocketChannel.connect(socketUri);

    // Subscribe command for ActionCable
    final identifier = jsonEncode({'channel': 'NotificationsChannel', 'admin_id': adminId});
    final subscribeMsg = jsonEncode({
      'command': 'subscribe',
      'identifier': identifier,
    });

    _channel.sink.add(subscribeMsg);

    _channel.stream.listen((event) {
      _handleEvent(event);
    }, onError: (err) {
      // reconectar o exponer error
      print('WebSocket error: $err');
    }, onDone: () {
      // intentos de reconexión simples
      print('WebSocket closed. Intentando reconectar en 2s...');
      Future.delayed(Duration(seconds: 2), () => _connect());
    });
  }

  void _handleEvent(dynamic event) {
    try {
      final data = jsonDecode(event as String);

      // ActionCable envía varios tipos de mensajes. Filtramos los que contienen "message"
      if (data is Map && data.containsKey('message')) {
        final message = data['message'];
        if (message is Map<String, dynamic>) {
          _controller.add(message);
        } else if (message is String) {
          _controller.add({'message': message});
        }
        if (onMessage != null) onMessage!(jsonEncode(message));
      }
    } catch (e) {
      // Puede ser un ping u otro string; ignoramos
      // print('No JSON: $event');
    }
  }

  void dispose() {
    try {
      final identifier = jsonEncode({'channel': 'NotificationsChannel', 'admin_id': adminId});
      final unsubscribeMsg = jsonEncode({
        'command': 'unsubscribe',
        'identifier': identifier,
      });
      _channel.sink.add(unsubscribeMsg);
    } catch (_) {}
    _channel.sink.close();
    _controller.close();
  }
}
