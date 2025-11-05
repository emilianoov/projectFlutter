import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:realtime_notifs_flutter/src/app/views/absence_request_screen.dart';


class AusenciasScreen extends StatefulWidget {
  const AusenciasScreen({super.key});

  @override
  State<AusenciasScreen> createState() => _AusenciasScreenState();
}

class _AusenciasScreenState extends State<AusenciasScreen> {
  List<DateTime?> _dates = [];
  
  void _mostrarOpciones(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // permite controlar altura y ancho
      backgroundColor: Colors.transparent, // quita el borde redondeado default
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.5, // 50% de la pantalla (puedes usar 0.8 o 1.0)
          widthFactor: 1.0, // ocupa todo el ancho
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tipo de ausencia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _opcionAusencia(
                      icon: Icons.beach_access,
                      texto: 'Vacaciones',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AbsenceRequestScreen(
                            dates: _dates,
                            tipoAusencia: "Vacaciones",
                          ),
                        ),
                      ),
                    ),
                    _opcionAusencia(
                      icon: Icons.timer_off_outlined,
                      texto: 'Permiso',
                      onTap: () => Navigator.pop(context),
                    ),
                    _opcionAusencia(
                      icon: Icons.medical_services_outlined,
                      texto: 'Licencia laboral',
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  static Widget _opcionAusencia({
    required IconData icon,
    required String texto,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 90,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blueGrey, size: 32),
            const SizedBox(height: 8),
            Text(
              texto,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  // List<DateTime?> _dates = [DateTime.now()];
  void _onSolicitarPressed(BuildContext context) {
    // Validación: asegurar que haya un rango seleccionado
    print(_dates);
    if (_dates.isEmpty || _dates.length < 2 || _dates[0] == null || _dates[1] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un rango de fechas antes de continuar.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _mostrarOpciones(context);
  }
  
  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Ausencias',
        style: TextStyle(color: Colors.white),
      ),
      iconTheme: IconThemeData(color: Colors.white),
      backgroundColor: const Color.fromARGB(255, 7, 46, 131),
      elevation: 0,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona el rango de fechas de tu ausencia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CalendarDatePicker2WithActionButtons(
                config: CalendarDatePicker2WithActionButtonsConfig(
                  firstDayOfWeek: 1,
                  calendarType: CalendarDatePicker2Type.range,
                  selectedDayTextStyle: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  selectedDayHighlightColor: const Color.fromARGB(255, 110, 179, 211),
                  centerAlignModePicker: true,
                  customModePickerIcon: const SizedBox(),
                ),
                value: _dates,
                onValueChanged: (dates) => _dates = dates,
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
          onPressed: () => _onSolicitarPressed(context),
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

}
