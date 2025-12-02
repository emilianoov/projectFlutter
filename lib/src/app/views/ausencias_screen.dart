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
  
  // Límite máximo de días hábiles permitidos
  static const int _maxDiasHabiles = 5;
  
  // Lista de días festivos (ejemplo - completa con tus fechas)
  final List<Map<String, int>> _festivos = [
    {'month': 1, 'day': 1},   // Año Nuevo
    {'month': 12, 'day': 25}, // Navidad
  ];

  // Función para verificar si es día hábil
  bool _esDiaHabil(DateTime date) {
    // Fin de semana (sábado = 6, domingo = 7)
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return false;
    }

    // Festivos recurrentes sin importar año
    for (var festivo in _festivos) {
      if (date.month == festivo['month'] &&
          date.day == festivo['day']) {
        return false;
      }
    }

    return true;
  }

  // Función para contar días hábiles en un rango
  int _contarDiasHabiles(DateTime startDate, DateTime endDate) {
    int count = 0;
    DateTime currentDate = startDate;
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    
    while (currentDate.isBefore(endDay) || 
           DateTime(currentDate.year, currentDate.month, currentDate.day)
              .isAtSameMomentAs(endDay)) {
      if (_esDiaHabil(currentDate)) {
        count++;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return count;
  }

  // Función para calcular si un día excedería el límite al ser seleccionado
  // bool _excedeMaximoDias(DateTime? fechaInicio, DateTime? fechaFin, DateTime fechaSeleccionada) {
  //   if (fechaInicio == null) return false;
    
  //   // Si solo hay una fecha seleccionada (inicio), verificar rango desde esa fecha
  //   if (fechaFin == null) {
  //     final diasHabiles = _contarDiasHabiles(fechaInicio, fechaSeleccionada);
  //     return diasHabiles > _maxDiasHabiles;
  //   }
    
  //   // Si ya hay un rango completo, no debería llegar aquí normalmente
  //   return false;
  // }

  // Función para validar las fechas seleccionadas
  String? _validarFechas(List<DateTime?> dates) {
    if (dates.isEmpty || dates[0] == null) {
      return null; // Aún no hay selección válida
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Caso 1: Un solo día seleccionado
    if (dates.length == 1) {
      final selectedDate = dates[0]!;
      final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      
      // Validar que no sea día anterior al actual
      if (selectedDay.isBefore(today)) {
        return 'No se pueden seleccionar días anteriores al actual';
      }
      
      // Validar que sea día hábil para días únicos
      if (!_esDiaHabil(selectedDate)) {
        return 'Para solicitar un solo día, debe ser día hábil (lunes a viernes, no festivo)';
      }
      
      return null;
    }
    
    // Caso 2: Rango de fechas seleccionado
    if (dates.length >= 2 && dates[1] != null) {
      final startDate = dates[0]!;
      final endDate = dates[1]!;
      final startDay = DateTime(startDate.year, startDate.month, startDate.day);
      
      // Validar que la fecha inicial no sea anterior al actual
      if (startDay.isBefore(today)) {
        return 'No se pueden seleccionar días anteriores al actual';
      }
      
      // Validar que haya al menos un día hábil en el rango
      final diasHabiles = _contarDiasHabiles(startDate, endDate);
      if (diasHabiles == 0) {
        return 'El rango debe contener al menos un día hábil';
      }
      
      // Validar que no exceda el máximo de días hábiles
      if (diasHabiles > _maxDiasHabiles) {
        return 'Máximo $_maxDiasHabiles días hábiles permitidos ($diasHabiles seleccionados)';
      }
      
      return null;
    }
    
    return null;
  }

  void _mostrarOpciones(BuildContext context) {
    // Primero validamos las fechas
    final errorMessage = _validarFechas(_dates);
    
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Si las fechas son válidas, mostrar el bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          widthFactor: 1.0,
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
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AbsenceRequestScreen(
                              dates: _dates,
                              tipoAusencia: "Vacaciones",
                              diasHabiles: _dates.length == 1 ? 1 : 
                                          _contarDiasHabiles(_dates[0]!, _dates[1]!),
                            ),
                          ),
                        );
                      },
                    ),
                    _opcionAusencia(
                      icon: Icons.timer_off_outlined,
                      texto: 'Permiso',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AbsenceRequestScreen(
                              dates: _dates,
                              tipoAusencia: "Permiso",
                              diasHabiles: _dates.length == 1 ? 1 : 
                                          _contarDiasHabiles(_dates[0]!, _dates[1]!),
                            ),
                          ),
                        );
                      },
                    ),
                    _opcionAusencia(
                      icon: Icons.medical_services_outlined,
                      texto: 'Licencia laboral',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AbsenceRequestScreen(
                              dates: _dates,
                              tipoAusencia: "Licencia laboral",
                              diasHabiles: _dates.length == 1 ? 1 : 
                                          _contarDiasHabiles(_dates[0]!, _dates[1]!),
                            ),
                          ),
                        );
                      },
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

  Widget _opcionAusencia({
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

  void _onSolicitarPressed(BuildContext context) {
    // Validación 1: Debe haber al menos un día seleccionado
    if (_dates.isEmpty || (_dates[0] == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un día'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validación 2: Si hay rango, ambas fechas deben estar definidas
    if (_dates.length > 1 && _dates[1] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa el rango de fechas o selecciona solo un día'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validación 3: Validar fechas según reglas de negocio
    final errorMessage = _validarFechas(_dates);
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Si pasa todas las validaciones, mostrar opciones
    _mostrarOpciones(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ausencias',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 7, 46, 131),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
              const SizedBox(height: 8),
              Text(
                'Puedes seleccionar un solo día o un rango (máximo $_maxDiasHabiles días hábiles)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fines de semana se omitirán del cálculo',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
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
                      cancelButton: const SizedBox.shrink(),
                      // Solo permitir días actuales y futuros
                      selectableDayPredicate: (date) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final selectedDay = DateTime(date.year, date.month, date.day);
                        
                        // No permitir días anteriores al actual
                        if (selectedDay.isBefore(today)) {
                          return false;
                        }
                        
                        // Si ya hay una fecha inicial seleccionada y no hay fecha final,
                        // verificar que no exceda el límite de días hábiles
                        if (_dates.isNotEmpty && 
                            _dates[0] != null && 
                            (_dates.length < 2 || _dates[1] == null)) {
                          
                          // Calcular días hábiles si se selecciona este día como final
                          final fechaInicio = _dates[0]!;
                          final diasHabiles = _contarDiasHabiles(
                            fechaInicio, 
                            date.isBefore(fechaInicio) ? fechaInicio : date
                          );
                          
                          // Verificar que no exceda el límite
                          return diasHabiles <= _maxDiasHabiles;
                        }
                        
                        return true;
                      },
                    ),
                    value: _dates,
                    onValueChanged: (dates) {
                      setState(() {
                        _dates = dates;
                      });
                      
                      // Mostrar advertencia en tiempo real si hay error
                      final errorMessage = _validarFechas(dates);
                      if (errorMessage != null && dates.isNotEmpty && dates[0] != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
              
              // Mostrar resumen de selección con cálculo de días hábiles
              const SizedBox(height: 16),
              if (_dates.isNotEmpty && _dates[0] != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[800]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen de solicitud:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_dates.length == 1 && _dates[0] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• 1 día hábil: ${_dates[0]!.day}/${_dates[0]!.month}/${_dates[0]!.year}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    '• ${_esDiaHabil(_dates[0]!) ? 'Día hábil' : 'No es día hábil'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _esDiaHabil(_dates[0]!) ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            if (_dates.length >= 2 && _dates[0] != null && _dates[1] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• Rango: ${_dates[0]!.day}/${_dates[0]!.month} al ${_dates[1]!.day}/${_dates[1]!.month}/${_dates[1]!.year}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    '• Días hábiles: ${_contarDiasHabiles(_dates[0]!, _dates[1]!)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _contarDiasHabiles(_dates[0]!, _dates[1]!) > _maxDiasHabiles 
                                          ? Colors.red 
                                          : Colors.black,
                                    ),
                                  ),
                                  if (_contarDiasHabiles(_dates[0]!, _dates[1]!) > _maxDiasHabiles)
                                    Text(
                                      '• Límite excedido (máximo $_maxDiasHabiles días hábiles)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  Text(
                                    '• Días naturales: ${_dates[1]!.difference(_dates[0]!).inDays + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ) 
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
              backgroundColor: _dates.isNotEmpty && _dates[0] != null && 
                             (_dates.length == 1 || (_dates.length >= 2 && _dates[1] != null)) &&
                             _validarFechas(_dates) == null
                  ? Colors.blueGrey[800]
                  : Colors.grey[400],
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