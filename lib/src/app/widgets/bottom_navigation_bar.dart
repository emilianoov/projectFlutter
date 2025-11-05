import 'package:flutter/material.dart';
import 'package:realtime_notifs_flutter/src/app/views/apps_screen.dart';
import 'package:realtime_notifs_flutter/src/app/views/home_screen.dart';
import 'package:realtime_notifs_flutter/src/app/views/notifications_screen.dart';

class BottomNavigationBarExample extends StatefulWidget {
  const BottomNavigationBarExample({super.key});

  @override
  State<BottomNavigationBarExample> createState() => _BottomNavigationBarExampleState();
}

class _BottomNavigationBarExampleState extends State<BottomNavigationBarExample> {
  int _selectedIndex = 0;
  int _notifCount = 0;
  List<Map<String, dynamic>> _messages = [];
  
  // Método para actualizar el contador
  void _updateNotifCount(int count) {
    setState(() {
      _notifCount = count;
    });
  }

  void _updateMessages(List<Map<String, dynamic>> messages) {
    setState(() => _messages = messages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PRYECTO DE PRUEBAS'),
        backgroundColor: Colors.blue,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () => _showMessagesDialog(),
                iconSize: 35.0,
              ),
              if (_notifCount > 0)
                Positioned(
                  right: 4,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(
                      _notifCount.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                )
            ],
          )
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.apps),
            label: 'Apps',
          ),
          BottomNavigationBarItem(
            icon: _buildNotificationIcon(),
            label: 'Mensajes',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color.fromARGB(255, 16, 46, 102),
        onTap: _onItemTapped,
      ),
    );
  }

  // Construir la pantalla actual con callback
  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const AppsScreen();
      case 2:
      return NotificationPage(
        onUnreadCountChanged: _updateNotifCount,
        onMessagesChanged: _updateMessages, 
      );
      default:
        return const HomeScreen();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        const Icon(Icons.message),
        if (_notifCount > 0)
          Positioned(
            right: -2,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _notifCount > 99 ? '99+' : _notifCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
      ],
    );
  }

  void _showMessagesDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Notificaciones (${_messages.length})'),
        content: Container(
          width: double.maxFinite,
          child: _messages.isEmpty
              ? Text('No hay notificaciones')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final m = _messages[index];
                    return ListTile(
                      title: Text(m['message']?.toString() ?? ''),
                      subtitle: Row(
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
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Cerrar'))],
      ),
    );
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