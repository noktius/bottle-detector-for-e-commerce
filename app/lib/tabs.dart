import 'package:flutter/material.dart';
import 'products.dart';
import 'scan.dart';
import 'history.dart';
import 'globals.dart';

/// Hauptbildschirm-Widget der Anwendung.
///
/// Zeigt unterschiedliche Screens basierend auf der unteren Navigationsleiste.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

/// State-Klasse für den Hauptscreen.
///
/// Verwaltet den ausgewählten Index und den Wechsel zwischen den Ansichten.
class _MainScreenState extends State<MainScreen> {
  // Aktuell ausgewählter Index für die Navigation
  int _selectedIndex = 0;

  // Liste der Widgets, die auf dem Screen angezeigt werden
  static final List<Widget> _widgetOptions = <Widget>[
    const ProductsScreen(),
    const CameraScreen(),
    const HistoryScreen(),
  ];

  /// Aktualisiert den ausgewählten Index basierend auf Benutzerinteraktion
  ///
  /// Setzt den Zustand neu, um das angezeigte Widget zu aktualisieren.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),  // Anzeige des ausgewählten Widgets
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.wine_bar_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt, size: 35), // Vergrößertes Symbol für die Kamera
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: mainColor,  // Farbe für ausgewähltes Element
        unselectedItemColor: Colors.grey,  // Farbe für nicht ausgewählte Elemente
        onTap: _onItemTapped,
        showSelectedLabels: false,  // Verhindert die Anzeige von Labels
        showUnselectedLabels: false,
        elevation: 0,  // Entfernt den oberen Schatten/Border
        type: BottomNavigationBarType.fixed, // Feste Darstellung ohne Animation
      ),
    );
  }
}
