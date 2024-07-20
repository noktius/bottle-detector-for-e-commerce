import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'globals.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Stellt den Screen für die Produktliste bereit.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  ProductsScreenState createState() => ProductsScreenState();
}

/// Stellt den Status für den Screen [ProductsScreen] dar.
class ProductsScreenState extends State<ProductsScreen> {
  List<dynamic> loadedProducts = []; // Speichern geladene Produkte
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce; // Timer für die Suchverzögerung
  bool _isLoading = false;
  bool _isSearchVisible = false;

  /// Wird aufgerufen, wenn dieses Objekt in den Widget-Baum eingefügt wird.
  ///
  /// Diese Methode initialisiert die Listener und lädt die notwendigen Daten und Einstellungen.
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged); // Fügt einen Listener hinzu, der auf Änderungen im Suchfeld reagiert
    _loadSettings();  // Lädt Benutzereinstellungen beim Start der App
    loadCachedData(); // Lädt gespeicherte Daten aus dem Cache
  }

  /// Wird aufgerufen, wenn dieses Objekt aus dem Widget-Baum entfernt wird.
  ///
  /// Diese Methode bereinigt die Ressourcen und beendet mögliche Hintergrundaktivitäten.
  @override
  void dispose() {
    _searchController.dispose(); // Gibt die Ressourcen des Suchcontrollers frei
    _debounce?.cancel(); // Bricht eventuell laufende Debounce-Operationen ab
    super.dispose();
  }


  /// Lädt die Benutzereinstellungen aus den Shared Preferences.
  /// Hierbei werden Einstellungen wie API-Endpoints und Schlüssel aus dem lokalen Speicher abgerufen.
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    apiJsonEndpoint = prefs.getString('apiJsonEndpoint') ?? apiJsonEndpoint;
    apiScanEndpoint = prefs.getString('apiScanEndpoint') ?? apiScanEndpoint;
    apiScanKey = prefs.getString('apiScanKey') ?? apiScanKey;

    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = info.version;
    });
  }

  /// Lädt die zwischengespeicherten Daten aus den Shared Preferences.
  /// Hier werden Angebote, die zuvor zwischengespeichert wurden, geladen und im Zustand gesetzt.
  /// Anschließend wird versucht, neue Daten vom Backend zu laden.
  Future<void> loadCachedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedOffers = prefs.getString('cachedOffers');
    if (cachedOffers != null) {
      List<dynamic> offers = jsonDecode(cachedOffers); // Umwandlung des JSON-Strings zurück in eine Liste von Dart-Objekten
      setState(() {
        loadedProducts = offers;  // Aktualisierung der geladenen Produkte
      });
    }
    fetchRemoteProducts();  // Ruft Produkte vom Backend ab, um die aktuellste Liste zu erhalten
  }

  /// Holt die Produktdaten vom Backend.
  /// Dies erfolgt durch einen HTTP-Get-Request. Bei erfolgreicher Antwort werden die Daten verarbeitet
  /// und der Zustand der geladenen Produkte wird aktualisiert.
  Future<void> fetchRemoteProducts() async {
    var url = apiJsonEndpoint;  // Verwendung des in den Einstellungen festgelegten Endpunkts

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> jsonData = jsonDecode(response.body); // Konvertiert die Antwort von JSON zu Dart-Objekten

        var fetchedOffers = jsonData.map((offer) {
          return {
            'name': offer['name'],
            'price': offer['alcohol_content'],
            'description': offer['description'],
            'imageUrl': offer['image_url']
          };
        }).toList();

        setState(() {
          loadedProducts = fetchedOffers;  // Aktualisiert die geladenen Produkte mit den neuen Daten
        });
      } else {
        debugPrint('Failed to load offers. Status code: ${response.statusCode}');  // Fehlermeldung bei nicht erfolgreicher Anfrage
      }
    } catch (e) {
      debugPrint('Error fetching offers: $e');  // Fehlerbehandlung bei Problemen mit der Anfrage
    }
  }
  /// Handhabt Änderungen im Suchfeld. Überprüft, ob der Debounce-Timer aktiv ist und stoppt ihn,
  /// falls notwendig. Setzt einen neuen Timer, wenn das Textfeld nicht leer ist, um die Suche
  /// mit einer Verzögerung auszuführen.
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel(); // Überprüft und stoppt den aktiven Timer

    if (_searchController.text.isNotEmpty) { // Überprüft, ob das Suchfeld nicht leer ist
      setState(() {
        _isLoading = true; // Aktiviert den Ladezustand
      });
      _debounce = Timer(const Duration(seconds: 2), () { // Startet einen neuen Timer mit 2 Sekunden Verzögerung
        _handleSearch(_searchController.text); // Führt die Suchfunktion aus, nachdem die Verzögerung abgelaufen ist
      });
    }
  }

  /// Zeigt ein Dialogfenster mit Produktdetails an. Dieses Fenster enthält den Produktnamen,
  /// den Alkoholgehalt, die Beschreibung und ein Bild des Produktes.
  void _showProductDialog(BuildContext context, dynamic offer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(offer['name'],
            style: GoogleFonts.jost(
              textStyle: TextStyle(
                  color: mainColor, fontWeight: FontWeight.bold
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Alc.: ${offer['price']}'), // Zeigt den Alkoholgehalt an
                Text('Description: ${offer['description']}\n'), // Zeigt die Beschreibung des Produktes an
                CachedNetworkImage(
                  imageUrl: offer['imageUrl'],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const CircularProgressIndicator(), // Lade-Animation während das Bild geladen wird
                  errorWidget: (context, url, error) => const Icon(Icons.error), // Fehler-Icon, wenn das Bild nicht geladen werden kann
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Schließt das Dialogfenster
              },
              child: const Text('Close'), // Button, um das Dialogfenster zu schließen
            ),
          ],
        );
      },
    );
  }

  /// Filtert die geladenen Produkte basierend auf dem eingegebenen Suchwert. Diese Funktion wird
  /// aufgerufen, wenn eine Suche durchgeführt wird und aktualisiert die Liste der angezeigten Produkte.
  void _handleSearch(String value) {
    if (value.isEmpty) { // Überprüft, ob der Suchwert leer ist.
      loadCachedData(); // Lädt die gespeicherten Daten neu, wenn keine Suchanfrage vorhanden ist
      return;
    }
    var filteredOffers = loadedProducts.where((offer) { // Filtert die Produkte basierend auf dem Namen oder der Beschreibung
      return offer['name'].toLowerCase().contains(value.toLowerCase()) ||
          offer['description'].toLowerCase().contains(value.toLowerCase());
    }).toList();

    setState(() {
      loadedProducts = filteredOffers; // Aktualisiert die Liste der geladenen Produkte mit den gefilterten Ergebnissen
      _isLoading = false; // Setzt den Ladezustand zurück
    });
  }

  /// Zeigt ein Dialogfenster für die Einstellungen an. Dies ermöglicht es Benutzern,
  /// API-Endpunkte und Schlüssel direkt aus der Benutzeroberfläche der App zu ändern.
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Einstellungen',
            style: GoogleFonts.jost(
              textStyle: TextStyle(
                  color: mainColor, fontWeight: FontWeight.bold
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                // Textfeld für API Scan Endpoint
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: TextEditingController(text: apiScanEndpoint),
                    decoration: const InputDecoration(
                      labelText: "API Scan Endpoint",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => apiScanEndpoint = value,
                  ),
                ),
                // Textfeld für API Scan Key
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: TextEditingController(text: apiScanKey),
                    decoration: const InputDecoration(
                      labelText: "API Scan Key",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => apiScanKey = value,
                  ),
                ),
                // Textfeld für API JSON Endpoint
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: TextEditingController(text: apiJsonEndpoint),
                    decoration: const InputDecoration(
                      labelText: "API JSON Endpoint",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => apiJsonEndpoint = value,
                  ),
                ),
                // Knopf zum Löschen der Scan-Historie
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: mainColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text("Scan-Historie löschen"),
                    onPressed: () => _deleteScanHistory(),
                  ),
                ),
                // Anzeige der App-Version
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.0),
                  child: Text("Version $appVersion",
                    style: GoogleFonts.jost(
                      textStyle: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Abbrechen', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Speichern', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              onPressed: () {
                _saveSettings();
              },
            ),
          ],
        );
      },
    );
  }

  /// Löscht die Scan-Historie aus den Shared Preferences
  void _deleteScanHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('scan_history'); // Entfernt den Eintrag aus den Einstellungen

    if (mounted) {
      Navigator.of(context).pop(); // Schließt das Dialogfenster, falls die Ansicht noch angezeigt wird
    }
  }

  /// Speichert die geänderten Einstellungen in den Shared Preferences
  void _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Speichert die neuen API-Endpunkte und Schlüssel
    await prefs.setString('apiScanEndpoint', apiScanEndpoint);
    await prefs.setString('apiJsonEndpoint', apiJsonEndpoint);
    await prefs.setString('apiScanKey', apiScanKey);

    if (mounted) {
      Navigator.of(context).pop(); // Schließt das Dialogfenster nach dem Speichern
    }
  }

  /// Erstellt die grafische Oberfläche des Screens.
  ///
  /// Dieser Teil des Codes ist verantwortlich für die Darstellung der AppBar und der
  /// Liste der Produkte. Für jeden Eintrag wird eine Karte erstellt, die bei Berührung
  /// ein Detaildialogfenster öffnet.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor,
        title: _isSearchVisible ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Search for a bottle...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ) : Text(
          "Find This Bottle",
          style: GoogleFonts.jost(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.normal,
            ),
          ),
        ),
        actions: [
          if (!_isSearchVisible)
            IconButton(
              icon: const Icon(Icons.search),
              color: Colors.white,
              onPressed: () {
                setState(() {
                  _isSearchVisible = true;
                });
              },
            ),
          if (_isSearchVisible)
            IconButton(
              icon: const Icon(Icons.close),
              color: Colors.white,
              onPressed: () {
                setState(() {
                  _isSearchVisible = false;
                  _searchController.clear();
                  loadCachedData();
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            color: Colors.white,
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: fetchRemoteProducts,
            child: GridView.builder(
              itemCount: loadedProducts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                var offer = loadedProducts[index];
                return GestureDetector(
                  onTap: () {
                    _showProductDialog(context, offer);
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    margin: const EdgeInsets.all(8),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: CachedNetworkImage(
                            imageUrl: offer['imageUrl'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer['name'],
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainColor),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text('Alc. ${offer['price']}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                              Text(
                                offer['description'],
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
