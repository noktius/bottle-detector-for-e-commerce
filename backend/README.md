# README - Backend

Dieses Dokument beschreibt das Backend, das für die Bildverarbeitung und Analyse in Verbindung mit einem trainierten neuronalen Netzwerkmodell verwendet wird. Das System ist in Python implementiert.

## Projektstruktur

- **`app.py`**: Hauptdatei, die die Flask-Anwendung definiert und die API-Endpunkte bereitstellt.
- **`/models` und `/utils`**: Enthalten Hilfsfunktionen und Modelle für die Objekterkennung und Bildverarbeitung. Die Modelle und Utilities können aus dem offiziellen Repository von Ultralytics für YOLOv5 geklont werden. Dieses Repository enthält Implementierungen für Objekterkennung, die ständig aktualisiert und verbessert werden.

- **`/models` und `/utils`**:
    * `/models`: Enthält Modelle für die Objekterkennung. Die Modelle können durch die Klassen `DetectMultiBackend` aus `models.common` verwendet werden, um verschiedene Backend-Technologien für die Objekterkennung zu unterstützen.
    * `/utils`: Bietet Hilfsfunktionen für die Bildverarbeitung und Datenverarbeitung. Funktionen wie n`on_max_suppression`, `scale_boxes`, und `check_img_size` aus utils.general sind entscheidend für die Nachbearbeitung von Erkennungsergebnissen (optional!). `LoadImages` aus `utils.dataloaders` unterstützt das Laden und die Vorverarbeitung von Bildern für das Modell.
- **`/trained-model`**: Verzeichnis, das die trainierten Modelldateien enthält.
- **`requirements.txt`**: Enthält alle notwendigen Python-Pakete, die installiert werden müssen.
- **`/db`**: Enthält die Datenbankdateien wie `products.json`, die Produktinformationen speichern.

## Vorbereitung und Einrichtung

### Einrichtung der virtuellen Umgebung

Es wird empfohlen, eine virtuelle Umgebung zu verwenden, um Abhängigkeitskonflikte zu vermeiden:

```bash
python -m venv {name} 
source {name}/bin/activate
```

### Installation der Abhängigkeiten

Zur Installation aller erforderlichen Abhängigkeiten ist folgender Befehl auszuführen:

`pip install -r requirements.txt`

### Integration externer Modelle und Bibliotheken
Um die Funktionalität des Systems zu gewährleisten, ist es erforderlich, die neuesten Versionen der Modelle und Bibliotheken aus dem offiziellen Ultralytics GitHub-Repository zu klonen. Dies ist eine grundlegende Voraussetzung für die vollständige Funktionalität der Bildverarbeitung und des trainierten neuronalen Netzwerkmodells. Dazu ist folgender Befehl auszuführen:

`git clone https://github.com/ultralytics/yolov5.git`

Nach dem Klonen können spezifische Module und Funktionen in die bestehenden Verzeichnisse `/models` und `/utils` integriert werden.

### Starten des Servers

Nach der Installation der Abhängigkeiten kann der Server mit folgendem Befehl gestartet werden:

`python backend.py`

Dies startet die Flask-Anwendung, die auf Port `56789` läuft.

### Nutzung der API

Die API ermöglicht das Hochladen von Bildern zur Analyse. Durch das Senden an den `/process`-Endpunkt werden Bilder verarbeitet und Ergebnisse zu erkannten Objekten und Text zurückgegeben.
