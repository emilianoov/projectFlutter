import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationController {
  static const String baseUrl = 'http://localhost:3000/notifications';

  // 🔹 Marcar como leída
  static Future<bool> markAsRead(int id) async {
    final url = Uri.parse('$baseUrl/$id/read');
    final resp = await http.patch(url);

    return resp.statusCode == 200;
  }

  // 🔹 Aceptar notificación
  static Future<bool> acceptNotification(int id) async {
    final url = Uri.parse('$baseUrl/$id/accept');
    final resp = await http.patch(url);

    return resp.statusCode == 200;
  }

  // 🔹 Rechazar notificación
  static Future<bool> rejectNotification(int id) async {
    final url = Uri.parse('$baseUrl/$id/reject');
    final resp = await http.patch(url);

    return resp.statusCode == 200;
  }

  // 🔹 Obtener conteo de no leídas
  static Future<int> getUnreadCount(String adminId) async {
    if (adminId.isEmpty) return 0;

    final url = Uri.parse('$baseUrl/unread/$adminId');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['unread_count'] ?? 0;
      }
    } catch (e) {
      print('Error obteniendo notificaciones no leídas: $e');
    }
    return 0;
  }

  // 🔹 Cargar notificaciones iniciales
  static Future<List<dynamic>> loadNotifications(String adminId, {bool unreadOnly = false}) async {
    if (adminId.isEmpty) return [];

    final readParam = unreadOnly ? '&read=false' : '';
    final url = Uri.parse('$baseUrl?receiver_id=$adminId$readParam');
    
    try {
      final resp = await http.get(url);
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        return data.map((m) => Map<String, dynamic>.from(m)).toList();
      }
    } catch (e) {
      print('Error cargando notificaciones: $e');
    }
    return [];
  }
}