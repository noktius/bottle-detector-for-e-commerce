import 'package:flutter/material.dart';
import 'tabs.dart';

void main() {
  runApp(const FindThisBottle());
}

// Hauptklasse der App
class FindThisBottle extends StatelessWidget {
  const FindThisBottle({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find This Bottle',

      // Definition des Themas der App
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue, // Primärfarbe
        hintColor: Colors.cyan[600], // Farbe für Hinweise
        fontFamily: 'Montserrat', // Schriftart
      ),
      home: MainScreen(), // Hauptscreen der App
    );
  }
}