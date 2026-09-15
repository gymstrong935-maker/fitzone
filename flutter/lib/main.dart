import 'package:flutter/material.dart';
import 'pages/home/home_page.dart';

void main() {
  runApp(const FitZoneApp());
}

class FitZoneApp extends StatelessWidget {
  const FitZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitZone',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080808),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF05C8D8),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Arial',
      ),
      home: const HomePage(),
    );
  }
}