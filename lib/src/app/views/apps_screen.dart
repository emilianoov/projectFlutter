import 'package:flutter/material.dart';
import 'package:realtime_notifs_flutter/src/app/views/ausencias_screen.dart';

class AppsScreen extends StatelessWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // return const Center(
    //   child: Text(
    //     'Pantalla de Opciones',
    //     style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
    //   ),
    // );
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Card(
            child: ListTile(
              leading: Icon(Icons.airline_seat_individual_suite),
              title: Text('Ausencias'),
              subtitle: Text('Solicitud de ausencias laborales'),
              trailing: Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                // acción al presionar
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AusenciasScreen()),
                );

              },
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.timer_sharp),
              title: Text('Mis Horarios'),
              subtitle: Text('Revisa tu horario laboral'),
              trailing: Icon(Icons.chevron_right, color: Colors.grey),
              onTap: (){
                print("Ir al módulo de horarios");
              },
            ),
          ),
        ],
      ),
    );
  }
}


