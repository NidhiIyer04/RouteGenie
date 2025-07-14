import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

void main() {
  runApp(const RouteGenieWebDashboard());
}

class RouteGenieWebDashboard extends StatelessWidget {
  const RouteGenieWebDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteGenie Dashboard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DashboardScreen(),
    );
  }
}
