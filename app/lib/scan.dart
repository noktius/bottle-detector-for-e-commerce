import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'globals.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ein StatefulWidget, das den Kamerabildschirm für die Anwendung darstellt.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

/// Der Zustand des CameraScreen, der die Kamerafunktionalitäten verwaltet.
class CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final ImagePicker _picker = ImagePicker();
  bool _isTorchOn = false;

  /// Initialisiert den Zustand und startet die Kamera-Initialisierung.
  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  /// Initialisiert die verfügbaren Kameras und setzt den Kameracontroller.
  /// Diese Methode fragt die verfügbaren Kamerabeschreibungen ab, wählt die erste verfügbare Kamera aus
  /// und initialisiert den Kameracontroller mit einer hohen Auflösung.
  void _initCamera() async {
    _cameras = await availableCameras(); // Abfrage der verfügbaren Kameras
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(
          _cameras![0],
          ResolutionPreset
              .ultraHigh); // Setzt den Kameracontroller mit der ersten verfügbaren Kamera
      _controller!.initialize().then((_) {
        if (!mounted) {
          // Überprüfung, ob das Widget noch im Widget-Baum eingehängt ist
          return;
        }
        setState(
            () {}); // Aktualisiert den UI-Zustand, sobald die Kamera initialisiert ist
      });
    }
  }

  /// Wechselt den Blitzmodus zwischen an und aus.
  /// Diese Funktion überprüft, ob ein Kameracontroller vorhanden ist und schaltet dann den Blitzmodus um.
  void _toggleFlash() {
    if (_controller != null) {
      setState(() {
        _isTorchOn = !_isTorchOn;
        _controller!.setFlashMode(_isTorchOn
            ? FlashMode.torch
            : FlashMode.off); // Setzt den Blitzmodus entsprechend
      });
    }
  }

  /// Nimmt ein Foto auf und bearbeitet es.
  /// Diese Funktion überprüft, ob der Kameracontroller bereit ist und kein Bild aufnimmt.
  /// Nimmt ein Bild auf, schaltet den Blitz aus und bearbeitet das Bild, indem es zentriert zugeschnitten wird.
  void _takeImage() async {
    if (!_controller!.value.isTakingPicture) {
      // Überprüft, ob gerade ein Bild aufgenommen wird
      XFile file = await _controller!.takePicture();
      _controller!.setFlashMode(FlashMode
          .off); // Schaltet den Blitz nach dem Aufnehmen des Bildes aus
      setState(() {
        _isTorchOn = false;
      });
      _cropSquareCenter(file
          .path); // Ruft die Funktion auf, um das Bild quadratisch zuzuschneiden
    }
  }

  /// Wählt ein Bild aus der Galerie aus und bearbeitet es.
  /// Öffnet die Bildergalerie, lässt den Benutzer ein Bild auswählen und schneidet es dann zentriert zu.
  void _pickImage() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource
            .gallery); // Öffnet die Galerie und lässt den Benutzer ein Bild auswählen
    if (image != null) {
      _cropSquareCenter(image.path); // Bearbeitet das ausgewählte Bild
    }
  }

  /// Schneidet das Bild quadratisch aus der Mitte aus und speichert es.
  ///
  /// @param imagePath Der Pfad zum Originalbild.
  Future<void> _cropSquareCenter(String imagePath) async {
    img.Image? originalImage =
        img.decodeImage(File(imagePath).readAsBytesSync()); // Lädt das Bild aus der Datei

    if (originalImage == null) {
      throw Exception('Unable to decode image'); // Wirft eine Ausnahme, wenn das Bild nicht dekodiert werden kann
    }

    // Bestimmt die Größe des zu schneidenden Quadrats basierend auf der kleineren Dimension
    int size = originalImage.width < originalImage.height
        ? originalImage.width
        : originalImage.height;
    // Berechnet den Offset vom Rand zur Mitte des Bildes für die X- und Y-Koordinaten
    int offsetX = (originalImage.width - size) ~/ 2;
    int offsetY = (originalImage.height - size) ~/ 2;

    img.Image croppedImage = img.copyCrop(originalImage,
        x: offsetX, y: offsetY, width: size, height: size); // Schneidet das Bild quadratisch aus der Mitte aus

    String newPath = imagePath.replaceFirst(RegExp(r'\.jpg$'), '_cropped.jpg'); // Ersetzt den Pfad des Originalbildes, um das neue Bild zu speichern
    File(newPath).writeAsBytesSync(img.encodeJpg(croppedImage)); // Speichert das zugeschnittene Bild

    // Zeigt eine Vorschau des bearbeiteten Bildes an
    _showImagePreview(newPath);
  }

  /// Zeigt eine Vorschau des bearbeiteten Bildes in einem Dialog an.
  ///
  /// @param imagePath Der Pfad zum bearbeiteten Bild.
  void _showImagePreview(String imagePath) {
    // Erstellt einen Dialog, der die Bildvorschau anzeigt
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Bottle Preview",
            style: GoogleFonts.jost(
              textStyle:
                  TextStyle(color: mainColor, fontWeight: FontWeight.bold),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.file(File(imagePath), fit: BoxFit.cover),
                const SizedBox(height: 20),
                const Text(
                  "Preview the captured bottle. If it looks good, proceed by clicking 'Identify' or cancel if needed.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _identifyAndShow(imagePath);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: mainColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Identify'),
            )
          ],
        );
      },
    );
  }

  /// Identifiziert das Bild über einen API-Aufruf und zeigt das Ergebnis an.
  ///
  /// @param imagePath Der Pfad zum Bild, das identifiziert werden soll.
  void _identifyAndShow(String imagePath) async {
    var overlay = showLoadingOverlay(context); // Zeigt ein Lade-Overlay während des API-Aufrufs
    try {
      // Erstellt die HTTP-Anfrage
      var uri = Uri.parse(apiScanEndpoint);
      var request = http.MultipartRequest('POST', uri)
        ..headers['X-API-KEY'] = apiScanKey
        ..files.add(await http.MultipartFile.fromPath('image', imagePath));

      var response = await request.send().timeout(const Duration(seconds: 30)); // Sendet die Anfrage und wartet auf die Antwort

      if (response.statusCode == 200) { // Verarbeitet die Antwort, wenn der Statuscode 200 ist
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var decoded = jsonDecode(responseString);
        _showResponse(decoded, imagePath);
      } else {
        _showErrorDialog();
      }
    } on TimeoutException catch (_) {
      _showErrorDialog('Request timed out. Please try again.');
    } catch (e) {
      _showErrorDialog('Failed to process image: $e');
    } finally {
      hideLoadingOverlay(overlay); // Entfernt das Lade-Overlay nach der Verarbeitung
    }
  }

  /// Zeigt einen Fehlerdialog an, wenn ein Problem auftritt.
  ///
  /// @param message Die Nachricht, die im Fehlerdialog angezeigt wird.
  void _showErrorDialog([String message = 'Failed to process image.']) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Error",
            style: GoogleFonts.jost(
              textStyle:
                  TextStyle(color: mainColor, fontWeight: FontWeight.bold),
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Konvertiert eine Zeichenfolge in eine ganze Zahl.
  ///
  /// @param input Die Zeichenfolge, die konvertiert werden soll.
  /// @return Die konvertierte ganze Zahl oder 0 bei einem Formatfehler.
  int parseStringToInt(String input) {
    try {
      return int.parse(input);
    } on FormatException {
      return 0;
    }
  }

  /// Konvertiert einen Base64-kodierten String in ein Bild-Widget.
  ///
  /// @param base64String Der Base64-kodierte String.
  /// @return Das Bild-Widget.
  Widget decodeBase64ToImage(String base64String) {
    return Image.memory(
      base64Decode(base64String),
      fit: BoxFit.cover,
      height: 200,
    );
  }

  /// Zeigt eine Antwortkarte mit den Ergebnissen der Bildidentifizierung an.
  ///
  /// @param decoded Die dekodierte Antwort von der API.
  /// @param imagePath Der Pfad zum Bild, das identifiziert wurde.
  void _showResponse(Map<String, dynamic> decoded, String imagePath) {
    List<dynamic> results = decoded['results'] as List<dynamic>;
    List<dynamic> detectedImages = decoded['images_base64'] as List<dynamic>;
    int bottles = decoded['bottles'];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: Text(
            "Scan Result",
            style: GoogleFonts.jost(
              textStyle:
                  TextStyle(color: mainColor, fontWeight: FontWeight.bold),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.jost(
                          fontSize: 20, fontWeight: FontWeight.w500),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Bottle(s) found: ',
                          style: TextStyle(
                              fontSize: 18,
                              color: mainColor,
                              fontWeight: FontWeight.normal),
                        ),
                        TextSpan(
                          text: '${bottles}',
                          style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (bottles == 0)
                    Text(
                      'Try adjusting your camera or making a different photo!',
                      style: GoogleFonts.jost(
                        textStyle: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.normal),
                      ),
                    ),
                  ...results.asMap().entries.map((entry) => Column(
                        children: [
                          Text(
                            '${entry.key + 1}: ${entry.value['name']}',
                            style: GoogleFonts.jost(
                              textStyle: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 2),
                          //const SizedBox(height: 3),
                          //decodeBase64ToImage(entry.value['image_base64']),
                        ],
                      )
                  ).toList(),
                  ...detectedImages.map((image) {
                    return Column(
                      children: [
                        decodeBase64ToImage(image),
                        const SizedBox(height: 2),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveHistory(
                    imagePath, "${bottles} bottle(s)", 99.0, decoded['text']);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade50,
              ),
              child:
                  const Text('OK', style: TextStyle(color: Colors.deepPurple)),
            ),
          ],
        );
      },
    );
  }

  /// Speichert die Scanergebnisse in den lokalen Einstellungen.
  ///
  /// @param imagePath Der Pfad des gescannten Bildes.
  /// @param name Der Name des erkannten Produkts.
  /// @param price Der Preis des Produkts.
  /// @param description Eine Beschreibung des Produkts.
  void _saveHistory(
      String imagePath, String name, double price, String description) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyJson = prefs.getStringList('scan_history') ?? [];
    ScanHistoryItem newItem = ScanHistoryItem(
      imagePath: imagePath,
      productName: name,
      price: price,
      description: description,
    );
    historyJson.add(jsonEncode(newItem.toJson()));
    prefs.setStringList('scan_history', historyJson);
  }

  /// Zeigt eine Ladeoverlay während des Wartens auf die API-Antwort.
  ///
  /// @param context Der Kontext, in dem das Overlay angezeigt wird.
  /// @return Das OverlayEntry, das später entfernt werden kann.
  OverlayEntry showLoadingOverlay(BuildContext context) {
    var overlay = Overlay.of(context);
    var overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Container(
          color: Colors.black45,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    return overlayEntry;
  }

  /// Entfernt ein angezeigtes Overlay.
  ///
  /// @param overlayEntry Das zu entfernende Overlay.
  void hideLoadingOverlay(OverlayEntry overlayEntry) {
    overlayEntry.remove();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Retrieve screen size
    var screenSize = MediaQuery.of(context).size;
    final screenH = max(screenSize.height, screenSize.width);
    final screenW = min(screenSize.height, screenSize.width);

    // Retrieve camera preview size
    var previewSize = _controller!.value.previewSize!;
    final previewH = max(previewSize.height, previewSize.width);
    final previewW = min(previewSize.height, previewSize.width);

    final screenRatio = screenH / screenW;
    final previewRatio = previewH / previewW;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bottle Scanner",
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
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Align the product within the frame and tap the camera icon to scan or select an image from the gallery.',
                    style: GoogleFonts.jost(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
                Expanded(
                  flex: 7,
                  child: Center(
                    child: Container(
                      width: screenW,
                      height: screenW,
                      color: Colors.black,
                      child: ClipRRect(
                        child: OverflowBox(
                          maxHeight: screenRatio > previewRatio
                              ? screenH
                              : screenW / previewW * previewH,
                          maxWidth: screenRatio > previewRatio
                              ? screenH / previewH * previewW
                              : screenW,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image, color: Colors.white),
                      label: const Text("Gallery",
                          style: TextStyle(color: Colors.white)),
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isTorchOn ? Icons.flash_off : Icons.flash_on,
                          color: Colors.white),
                      onPressed: _toggleFlash,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text("Take a Shot!",
                          style: TextStyle(color: Colors.white)),
                      onPressed: _takeImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// Ein Objekt zur Speicherung der Scan-Historie.
class ScanHistoryItem {
  final String imagePath;
  final String productName;
  final double price;
  final String description;

  ScanHistoryItem({
    required this.imagePath,
    required this.productName,
    required this.price,
    required this.description,
  });

  /// Konvertiert das ScanHistoryItem-Objekt in ein JSON-Format.
  Map<String, dynamic> toJson() => {
        'imagePath': imagePath,
        'productName': productName,
        'price': price,
        'description': description,
      };

  /// Erstellt ein ScanHistoryItem-Objekt aus einem JSON-Objekt.
  static ScanHistoryItem fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      imagePath: json['imagePath'],
      productName: json['productName'],
      price: json['price'],
      description: json['description'],
    );
  }
}
