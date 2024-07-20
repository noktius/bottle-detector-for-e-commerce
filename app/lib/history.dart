import 'dart:convert';
import 'dart:io';
import 'globals.dart';
import 'package:find_this_bottle/scan.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

/// Diese Klasse erstellt einen Bildschirm für die Historie der Flaschenscans
///
/// Sie zeigt die historischen Scanergebnisse in einer Listenansicht an. Die Klasse
/// verfügt über Methoden zum Laden der Historie aus den SharedPreferences und zum Anzeigen
/// von Detaildialogen für einzelne Einträge.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

/// Diese Klasse repräsentiert den Zustand des HistoryScreen.
///
/// Sie verwaltet eine Liste von ScanHistoryItems, die die Scan-Historie darstellen.
class HistoryScreenState extends State<HistoryScreen> {
  List<ScanHistoryItem> _history = [];

  /// Initialisiert den Bildschirm und lädt die Scan-Historie.
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Lädt die Scan-Historie aus den SharedPreferences.
  ///
  /// Die Methode holt die gespeicherte Liste der gescannten Einträge und decodiert sie
  /// in ScanHistoryItems, die dann im State verwaltet werden.
  void _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyJson = prefs.getStringList('scan_history') ?? [];
    setState(() {
      _history = historyJson.map((item) => ScanHistoryItem.fromJson(jsonDecode(item))).toList();
    });
  }

  /// Erstellt die grafische Oberfläche des Screens.
  ///
  /// Dieser Teil des Codes ist verantwortlich für die Darstellung der AppBar und der
  /// Liste der Scan-Historie. Für jeden Eintrag wird eine Karte erstellt, die bei Berührung
  /// ein Detaildialogfenster öffnet.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bottle History",
          style: GoogleFonts.jost(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.normal,
            ),
          ),
        ),
        backgroundColor: mainColor,
      ),
      body: ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.white70,
            elevation: 4,
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: FileImage(File(item.imagePath)),
                radius: 25,
              ),
              title: Text(
                item.productName,
                style: GoogleFonts.jost(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(item.description, style: GoogleFonts.jost(fontSize: 14)),
              onTap: () {
                _showDetailsDialog(context, item);
              },
            ),
          );
        },
      ),
    );
  }

  /// Zeigt ein Dialogfenster mit Details zu einem Scan-Eintrag.
  ///
  /// Wenn ein Eintrag in der Liste ausgewählt wird, öffnet diese Methode ein Dialogfenster,
  /// das ein Bild des gescannten Artikels sowie zusätzliche Informationen dazu anzeigt.
  void _showDetailsDialog(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Scan Entry",
            style: GoogleFonts.jost(
              textStyle: TextStyle(
                  color: mainColor, fontWeight: FontWeight.bold
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.file(File(item.imagePath)),
                const SizedBox(height: 10),
                Text(item.productName, style: GoogleFonts.jost(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(item.description, style: GoogleFonts.jost(fontSize: 14)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Close", style: GoogleFonts.jost(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context). pop();
              },
            ),
          ],
        );
      },
    );
  }
}
