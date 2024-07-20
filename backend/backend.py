from flask import Flask, request, jsonify, send_from_directory
from PIL import Image
import io
from io import BytesIO
import torch
import easyocr
from pathlib import Path
from models.common import DetectMultiBackend
from utils.general import non_max_suppression, scale_boxes, check_img_size
from utils.dataloaders import LoadImages
from utils.torch_utils import select_device
from ultralytics.utils.plotting import Annotator, colors, save_one_box
import uuid
import numpy as np
import os
import base64
import requests
import json
from fuzzywuzzy import fuzz, process

API_KEY = "JDSF832dbans8WGDDBndjaka821"
MODEL = 'trained-model/yolov5-large-trained.pt'
PRODUCTS_DB = 'db/products.json'
IMAGE_DIRECTORIES = {
    'input': 'temp-images/input/',
    'output': 'temp-images/output/',
    'resized': 'temp-images/resized/'
}

# Initialisierungen
app = Flask(__name__)
model = torch.hub.load('ultralytics/yolov5', 'custom', path=MODEL, force_reload=True)
reader = easyocr.Reader(['en', 'de'])  # Laden des EasyOCR-Bibliothek mit Englisch und Deutsch
loaded_model = None
products = []

"""
   Hilfsfunktionen
"""

def load_model(weights_path, device):
    """
    Lädt ein vortrainiertes Modell.
    
    Args:
        weights_path (str): Der Pfad zu den Gewichten des Modells.
        device (str): Die zu verwendende Hardware ("cpu" oder "cuda").
    
    Returns:
        tuple: Ein Modell und der dazugehörige Stride-Wert.
    """
    device = select_device(device)  # Wählt das Gerät (CPU oder GPU) für das Modell aus
    model = DetectMultiBackend(weights_path, device=device)  # Lädt das Modell mit spezifischen Gewichten
    return model

def load_products():
    """
    Lädt Produktinformationen von einer lokalen Datei.
    
    Returns:
        list: Eine Liste von Produkten.
    """
    base_dir = os.path.dirname(__file__)
    file_path = os.path.join(base_dir, PRODUCTS_DB)

    with open(file_path, 'r', encoding='utf-8') as file:
        products = json.load(file)

    return products

def replace_similar_characters(text):
    """
    Ersetzt ähnliche Zeichen in einem gegebenen Text.
    
    Args:
        text (str): Der Eingabetext.
    
    Returns:
        str: Der Text mit ersetzten Zeichen.
    """
    replacements = {
        '0': 'o',
        '1': 'i',
        '3': 'e',
        '4': 'a',
        '5': 's',
        '7': 't',
        '8': 'b'
    }
    return ''.join(replacements.get(char, char) for char in text)

def fetch_image_base64(url):
    """
    Lädt ein Bild von einer URL und konvertiert es zu einem Base64-String.
    
    Args:
        url (str): Die URL des Bildes.
    
    Returns:
        str: Das Bild als Base64-codierter String.
    """
    response = requests.get(url)  # Sendet eine HTTP-Anfrage an den gegebenen Bild-URL
    response.raise_for_status()  # Überprüft auf HTTP-Fehler und wirft eine Ausnahme, falls vorhanden
    return base64.b64encode(BytesIO(response.content).read()).decode('utf-8')

def create_directories(directories):
    """
    Erstellt die Verzeichnisse, die in einem Dictionary definiert sind.
    
    Args:
        directories (dict): Ein Dictionary von Verzeichnisnamen zu Pfaden.
    """
    for directory_path in directories.values():
        Path(directory_path).mkdir(parents=True, exist_ok=True)

def clean_up_images(directories):
    """
    Löscht alle Dateien in den angegebenen Verzeichnissen.
    
    Args:
        directories (dict): Ein Wörterbuch von Verzeichnisnamen zu Pfaden.
    """
    for directory_path in directories.values():
        for filename in os.listdir(directory_path):
            file_path = os.path.join(directory_path, filename)
            try:
                if os.path.isfile(file_path) or os.path.islink(file_path):
                    os.unlink(file_path)  # Löschen der Datei
            except Exception as e:
                print(f'Fehler beim Löschen von {file_path}. Grund: {e}')

def resize_image(image_path, target_size=(640, 640)):
    """
    Skaliert ein Bild auf eine gegebene Zielgröße.
    
    Args:
        image_path (str): Der Pfad zum Originalbild.
        target_size (tuple): Die Zielgröße (Breite, Höhe).
    
    Returns:
        str: Der Pfad zum skalierten Bild.
    """
    with Image.open(image_path) as img:
        img = img.resize(target_size, Image.LANCZOS)  # Skaliert das Bild auf die gewünschte Größe mit dem LANCZOS-Algorithmus, der für hohe Qualität sorgt
        filename = os.path.basename(image_path)
        output_path = os.path.join(IMAGE_DIRECTORIES['resized'], filename)
        img.save(output_path, format='JPEG')  # Speichert das skalierte Bild als JPEG
        return output_path

"""
   KI-Funktionen
"""

def detect_objects(model, img_path, img_size, conf_thres, iou_thres, device):
    """
    Erkennt Objekte in einem Bild.
    
    Args:
        model (Model): Das geladene Modell.
        img_path (str): Der Pfad zum Bild.
        img_size (int): Die Größe, auf die das Bild skaliert werden soll.
        conf_thres (float): Der Schwellenwert für die Konfidenz.
        iou_thres (float): Der Schwellenwert für die Überlappung von Bounding-Boxen.
        device (str): Die zu verwendende Hardware ("cpu" oder "cuda").
    
    Returns:
        tuple: Enthält den Bildpfad, das Bild, das Originalbild und die Detektionen.
    """
    imgsz = check_img_size(img_size, s=model.stride)  # Überprüfen und Anpassen der Bildgröße an das Modell
    dataset = LoadImages(img_path, img_size=imgsz, auto=model.pt)  # Laden des Bildes für die Verarbeitung

    for path, img, im0s, _, _ in dataset:
        img = torch.from_numpy(img).to(device)  # Konvertieren des Bildes in ein Torch Tensor und Verschiebung auf das gewählte Gerät
        img = img.float() / 255.0  # Normalisieren des Bildes
        if len(img.shape) == 3:
            img = img[None]  # Hinzufügen einer zusätzlichen Dimension, falls notwendig

        pred = model(img)  # Vorhersagen des Modells erhalten
        det = non_max_suppression(pred, conf_thres, iou_thres)[0]  # Anwenden der Non-Max Suppression zur Filterung der Vorhersagen
        return path, img, im0s, det

def recognize_text(image):
    """
    Erkennt Text in einem Bild.
    
    Args:
        image (Image): Das Bild, auf dem der Text erkannt werden soll.
    
    Returns:
        tuple: Enthält den erkannten Text und das OCR-Ergebnis.
    """
    image_np = np.array(image)  # Konvertieren des PIL-Bildes in ein NumPy-Array
    ocr_result = reader.readtext(image_np)  # Ausführen der Texterkennung
    recognized_texts = [result[1] for result in ocr_result]  # Extrahieren des erkannten Textes aus dem OCR-Ergebnis
    return " ".join(recognized_texts), ocr_result

def post_process_images(im0s, det):
    """
    Schneidt des erkannten Bereichs aus dem Bild aus und führt OCR auf den erkannten Objekten eines Bildes aus.
    
    Args:
        im0s (numpy.ndarray): Das Originalbild.
        det (list): Die Liste der Detektionen.
    
    Returns:
        list: Liste der erkannten Texte.
    """
    save_path = Path(IMAGE_DIRECTORIES['output'])  # Definieren des Speicherpfades für die Bilder
    text_results = []
    images_base64 = []
    for *xyxy, conf, cls in det:
        filename = f"{uuid.uuid4().hex}.jpg"  # Generieren eines einzigartigen Dateinamens
        file_full_path = save_path / filename  # Zusammenbauen des vollständigen Dateipfades
        cropped_image = save_one_box(xyxy, im0s, file=file_full_path, BGR=True)  # Ausschneiden des erkannten Bereichs aus dem Bild
        if cropped_image is not None and cropped_image.size > 0:
            cropped_pil_image = Image.fromarray(cropped_image)  # Konvertieren des ausgeschnittenen Bereichs in ein PIL-Bild

            recognized_text, _ = recognize_text(cropped_pil_image)  # Erkennen von Text im ausgeschnittenen Bild
            if recognized_text is not None and len(recognized_text) >= 4:
                text_results.append(recognized_text) # Hinzufügen des erkannten Textes zur Liste der Ergebnisse
                
                img_byte_arr = io.BytesIO()
                cropped_pil_image.save(img_byte_arr, format='JPEG')
                encoded_img = base64.b64encode(img_byte_arr.getvalue()).decode('utf-8')
                images_base64.append(encoded_img)

    return text_results, images_base64

def find_products(ocr_text):
    """
    Findet Produkte basierend auf OCR-Text.
    
    Args:
        ocr_text (str): Der erkannte Text aus dem OCR-Prozess.
    
    Returns:
        dict: Das gefundene Produkt oder None, wenn kein Produkt gefunden wurde.
    """
    ocr_text = replace_similar_characters(ocr_text.lower())  # Umwandlung des Textes in Kleinbuchstaben und Ersetzen ähnlicher Zeichen
    ocr_parts = ocr_text.split()  # Zerlegen des Textes in Einzelteile
    best_score = 0
    best_product = None
    for product in products:
        product_name = replace_similar_characters(product['name'].lower())  # Anpassung der Produktnamen
        score = fuzz.ratio(ocr_text, product_name)
        if score > best_score:  # Überprüfung, ob der neue Score höher ist als der bisher beste
            best_score = score
            best_product = product
            best_product['image_base64'] = fetch_image_base64(best_product['image_url'])
    return best_product

"""
   API-Routen
"""

@app.route('/process', methods=['POST'])
def process_image():
    """
    Verarbeitet ein eingehendes Bild und sucht nach entsprechenden Flaschen basierend auf dem Text, der im Bild erkannt wird.
    
    Returns:
        JSON: Antwort mit Ergebnissen der Bildverarbeitung.
    """
    api_key_header = request.headers.get('X-API-KEY')  # Abrufen des API-Schlüssels aus den Headern
    if not api_key_header or api_key_header.split()[-1] != API_KEY:
        return jsonify({'error': 'Unauthorized access'}), 401  # Überprüfung des API-Schlüssels

    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400  # Überprüfung, ob ein Bild hochgeladen wurde

    found_products = []

    file = request.files['image']
    file_path = os.path.join(IMAGE_DIRECTORIES['input'], file.filename)  # Speichern der Datei
    file.save(file_path)

    resized_image_path = resize_image(file_path)  # Bild skalieren
    _, _, im0s, det = detect_objects(loaded_model, resized_image_path, (640, 640), 0.25, 0.45, "cpu")  # Objekterkennung durchführen
    bottle_texts, images_base64 = post_process_images(im0s, det)  # OCR auf den erkannten Objekten ausführen

    if len(im0s) > 0:
        for bottle_text in bottle_texts:
            matched_product = find_products(bottle_text) # Produkte basierend auf dem OCR-Text suchen
            found_products.append(matched_product) if matched_product is not None else None

        text_summary = ", ".join([f"'{text}'" for text in bottle_texts])
        response = {
            'bottles': len(found_products),
            'text': text_summary,
            'results': found_products,
            'images_base64': images_base64
        }
    else:
        response = {
            'bottles': 0,
            'text': "-",
            'results': [],
            'images_base64': []
        }

    clean_up_images(IMAGE_DIRECTORIES)
    return jsonify(response), 200


@app.route('/products.json')
def serve_json_file():
    return send_from_directory('db', 'products.json')

@app.route('/db/images/<path:filename>')
def serve_images(filename):
    return send_from_directory('db/images', filename)

if __name__ == '__main__':
    products = load_products()  # Produkte beim Start laden
    create_directories(IMAGE_DIRECTORIES)  # Verzeichnisse beim Start erstellen
    loaded_model = load_model(MODEL, "cpu")  # Modell laden
    app.run(debug=False, host='0.0.0.0', port=56789)  # Server starten
