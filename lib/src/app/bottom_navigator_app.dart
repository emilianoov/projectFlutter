import 'package:flutter/material.dart';
import 'package:realtime_notifs_flutter/src/app/widgets/bottom_navigation_bar.dart';

class BottomNavigationBarExampleApp extends StatelessWidget {
  const BottomNavigationBarExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Bottom Navigation Bar Example',
      home: BottomNavigationBarExample(),
    );
  }
}