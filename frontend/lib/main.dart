import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(RouteGenieApp());
}

class RouteGenieApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteGenie',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
