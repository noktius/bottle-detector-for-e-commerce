# README - Vorbereitung der Bilddaten

Die vorliegende Anleitung erläutert die Skripte sowie deren Funktionsweise, welche im Rahmen der Vorbereitung der Bilddatensätze sowie des Einsetzens des neuronalen Modells im Kontext der vorliegenden Arbeit zum Einsatz gelangen.

## Vorbereitung der Bilder

Bevor das Skript `1-crop-objects.py` verwendet wird, __müssen die Bilder vorbereitet werden__. Dies beinhaltet das Entfernen des Hintergrunds der Bilder, sodass nur die relevanten Objekte sichtbar sind. Für das Entfernen des Hintergrunds können verschiedene kostenlose Programme verwendet werden, darunter:

- **GIMP**: Ein leistungsstarkes, frei verfügbares Bildbearbeitungsprogramm, das Tools zur manuellen Entfernung von Hintergründen bietet.
- **remove.bg**: Eine Web-basierte Anwendung, die künstliche Intelligenz nutzt, um automatisch den Hintergrund aus Bildern zu entfernen. Dieses Tool eignet sich besonders gut für schnellere Bearbeitungen und wenn keine Installation erforderlich sein soll.
- **PhotoScissors**: Bietet eine einfache Online-Lösung zum Entfernen von Hintergründen, die speziell für weniger komplexe Szenarien konzipiert ist.

Diese Tools sind besonders nützlich, um Bilder effizient vorzubereiten, damit sie in den nachfolgenden Schritten der Datenverarbeitung verwendet werden können.

## Skript `1-crop-objects.py`

### Zweck
Das Skript wird verwendet, um Bilder automatisch zuzuschneiden und dabei unerwünschte Randbereiche zu entfernen. Es erkennt und entfernt Bereiche, die keine wichtigen Informationen enthalten, und orientiert das Bild gemäß seiner Exif-Orientierungsmarkierung.

### Verwendung
Das Skript liest Bilder aus einem vorgegebenen Eingabeordner, verarbeitet jedes Bild und speichert das zugeschnittene Bild in einem Ausgabeordner.

### Ablauf
1. Überprüfung, ob der Ausgabeordner existiert; falls nicht, wird dieser erstellt.
2. Einlesen aller Bild-Dateien im Eingabeordner.
3. Überprüfung der Exif-Orientierung jedes Bildes und Drehung, falls notwendig.
4. Zuschneiden des Bildes auf den Bereich, der tatsächliche Bildinformationen enthält.
5. Speicherung des bearbeiteten Bildes im Ausgabeordner.

## Skript `2-prepare-dataset.py`

### Zweck
Das Skript bereitet den Datensatz vor, indem es Bilder aus einem Eingabeordner nimmt, sie transformiert und in einem Ausgabeordner speichert.

### Verwendung
Das Skript verarbeitet jedes Bild durch Anwendung verschiedener Transformationen und Effekte, um die Vielfältigkeit und Robustheit des Datensatzes zu erhöhen.

### Ablauf
1. Zählen der Bilder im Eingabeordner.
2. Anwendung zufälliger Transformationen auf jedes Bild.
3. Speicherung der transformierten Bilder im Ausgabeordner.

## Skript `2-1-check-annotation.py`

### Zweck
Das Skript überprüft die Annotierungen der Bilder, indem zufällige Bilder aus einem Ordner angezeigt und die entsprechenden Annotierungen visualisiert werden.

### Verwendung
Das Skript wählt ein zufälliges Bild aus dem festgelegten Ordner und zeigt es zusammen mit seinen Annotierungen an, um die Korrektheit der Annotierungen sicherzustellen.

### Ablauf
1. Einlesen aller Bild-Dateien aus dem spezifizierten Ordner.
2. Auswahl eines zufälligen Bildes und Anzeige dessen Annotierungen.
3. Visualisierung des Bildes und seiner Annotierungen mittels `Matplotlib`.


## Ausführen der Skripte

Vor dem Ausführen der Skripte ist zum Skriptverzeichnis zu navigieren:

`cd pfad/zum/skriptverzeichnis`

### Verwendung einer virtuellen Umgebung
Die Verwendung einer virtuellen Umgebung wird empfohlen, um Konflikte mit anderen Python-Paketen zu vermeiden:

```bash
python -m venv {name}
source {name}/bin/activate
```

### Installation der Abhängigkeiten
Zur Installation aller erforderlichen Abhängigkeiten wird requirements.txt verwendet:

`pip install -r requirements.txt`

Anschließend können die Skripte mit folgenden Befehlen ausgeführt werden:

```bash
python 1-crop-objects.py
python 2-1-check-annotation.py
python 2-prepare-dataset.py
```

Die bereitgestellten Skripte sind essenziell für die Vorbereitung und Überprüfung der Bilddaten, die in der Arbeit verwendet werden.

## Shell-Skript `start-training.sh`
### Zweck
Das Shell-Skript `start-training.sh` dient dazu, die Trainingsumgebung vorzubereiten, einschließlich der Aktivierung der virtuellen Umgebung, Installation erforderlicher Pakete und Start des Trainingsprozesses.

### Verwendung auf verschiedenen Plattformen
_Auf Unix-basierten Systemen (Linux, MacOS):_

```bash
chmod +x start-training.sh
./start-training.sh
```

_Auf Windows:_

`bash start-training.sh`

## Fazit

Dieses README stellt sicher, dass alle wesentlichen Informationen enthalten sind, um die Skripte korrekt auszuführen und die Umgebung entsprechend einzurichten.




