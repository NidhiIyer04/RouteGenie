import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteGenie Dashboard',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const DashboardScreen(),
    );
  }
}
