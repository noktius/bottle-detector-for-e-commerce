# README - Flutter-App

In der vorliegenden Anleitung wird das Flutter-Projekt vorgestellt, welches die Anwendung eines trainierten neuronalen Netzwerkmodells für die Bildanalyse und -klassifikation in einer mobilen App demonstrieren soll.

## Projektstruktur

Das Projekt umfasst mehrere Hauptkomponenten:

- **`/android`**: Beinhaltet spezifische Konfigurationen und Quelldateien für die Android-Plattform.
- **`/ios`**: Beinhaltet spezifische Konfigurationen und Quelldateien für die iOS-Plattform.
- **`/lib`**: Hauptverzeichnis für den Dart-Quellcode des Flutter-Frameworks.
  - `main.dart`: Stellt den Einstiegspunkt der App dar.
  - `globals.dart`, `history.dart`, `products.dart`, `scan.dart`, `tabs.dart`: Definieren Logik und Layout der einzelnen Screens und Funktionen der App.
- **`/assets`**: Enthält Bilder und Icons, die in der App verwendet werden.

## SDK-Konfiguration und Kompilierung

## Installation von Abhängigkeiten

Die notwendigen externen Pakete sind in der `pubspec.yaml` definiert. Zur Installation dieser Pakete wird im Projektverzeichnis der Befehl `flutter pub get` ausgeführt. 

### Android Studio

Zur Kompilierung und Ausführung in Android Studio:

1. Importieren des Projekts durch Öffnen des Projektordners in Android Studio.
2. Installation des Flutter und Dart Plugins über den Plugin-Manager.
3. Sicherstellen, dass der Flutter SDK-Pfad korrekt eingestellt ist unter `File > Settings > Languages & Frameworks > Flutter`.
4. Starten eines Emulators oder Verbinden eines physischen Geräts.
5. Ausführen des Projekts durch Klicken auf den `Run`-Button.

### Xcode (iOS)

Zur Kompilierung und Ausführung in Xcode:

1. Wechsel in den `ios`-Ordner im Terminal und Ausführen von `pod install`, um CocoaPods-Abhängigkeiten zu installieren.
2. Öffnen der `Runner.xcworkspace`-Datei in Xcode.
3. Einstellen der korrekten `Bundle-ID` und des `Entwickler-Teams` in den Projekt-Einstellungen.
4. Auswahl des Zielgeräts oder Simulators.
5. Kompilieren und Starten der Anwendung durch Klicken auf den `Run`-Button.
