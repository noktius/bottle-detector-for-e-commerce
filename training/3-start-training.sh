#!/bin/bash
set -e

if command -v python3 &>/dev/null; then
    PYTHON=python3
else
    PYTHON=python
fi

# Nachfragen des Dataset-Verzeichnisses
echo "Vollständiger Pfad zum Dataset-Verzeichnis ist anzugeben (enthält train, test, valid) (z.B $PWD/dataset):"
read dataset_dir

# Überprüfen, ob data.yaml im Wurzelverzeichnis vorhanden ist
echo "Vollständiger Pfad zum data.yaml-Datei ist anzugeben (z.B $PWD/data.yaml):"
read data_yaml

# Klonen der aktuellen Version des YOLOv5-Repository
echo "Die aktuelle Version des YOLOv5-Repository wird geklont..."
git clone https://github.com/ultralytics/yolov5 yolov5t
mv yolov5t/.git yolov5/.git
rm -rf yolov5t
cd yolov5

# Installation der erforderlichen Pakete
echo "Erforderliche Pakete werden aktualisiert..."
pip install -r requirements.txt

# Setzen des COMET_API_KEY
echo "COMET_API_KEY ist einzugeben:"
read comet_api_key
export COMET_API_KEY=$comet_api_key

# Parametereingaben für das Training
echo "Modell für das Training ist auszuwählen (z.B. yolov5s, yolov5m):"
read model_choice
echo "Bildgröße ist anzugeben (z.B. 640, 1024):"
read img_size
echo "Batch-Größe ist anzugeben (z.B. 16):"
read batch_size
echo "Anzahl der Epochen ist anzugeben (z.B. 150):"
read epochs_num
echo "Anzahl der Worker ist anzugeben (z.B. 16):"
read workers_num

# Trainingskommando ausführen
echo "Training wird gestartet..."
$PYTHON train.py --img $img_size --batch $batch_size --epochs $epochs_num --data $data_yaml --weights '' --cfg models/${model_choice}.yaml --workers $workers_num

echo "Training abgeschlossen."
