import itertools  # Importiert das itertools-Modul
import os  # Importiert das os-Modul
import random  # Importiert das random-Modul
from io import BytesIO  # Importiert BytesIO aus dem io-Modul
from time import sleep  # Importiert sleep aus dem time-Modul
from PIL import Image, ImageFilter, ImageEnhance, ImageOps, ImageDraw  # Importiert verschiedene Funktionen aus PIL
from datetime import datetime  # Importiert datetime aus dem datetime-Modul
import requests  # Importiert das requests-Modul

size = 640  # Setzt die Bildgröße auf 640 Pixel
probe_size = 3  # Setzt die Anzahl der zu verarbeitenden Bilder auf N
input_folder = 'pictures/3-cropped'  # Definiert den Ordner für die Eingabedaten
output_folder = 'pictures/4-extended'  # Definiert den Ordner für die Ausgabedaten
done = 0  # Initialisiert den Zähler für erledigte Bilder
expected = 0  # Initialisiert den erwarteten Zähler für Bilder
effect_chance = 85  # Setzt die Wahrscheinlichkeit für Effekte auf 85%
multi_effect_chance = 35  # Setzt die Wahrscheinlichkeit für mehrere Effekte auf 35%
bg_urls = [  # Definiert eine Liste von URLs für Hintergrundbilder
    f'https://random.imagecdn.app/{size}/{size}',
    f'https://picsum.photos/{size}/{size}',
    f'https://source.unsplash.com/random/{size}x{size}'
]
global_url_counter = itertools.cycle(range(len(bg_urls)))  # Zyklischer Zähler für die Hintergrund-URLs
effect_statistics = {}  # Initialisiert ein Wörterbuch für Effektstatistiken


def count_image_files(input_folder):  # Definiert eine Funktion zum Zählen der Bilddateien
    image_extensions = {'.jpg', '.jpeg', '.png'}  # Legt erlaubte Bildformate fest
    image_count = 0  # Initialisiert den Bildzähler

    for file in os.listdir(input_folder):  # Durchläuft die Dateien im Eingabeordner
        if os.path.splitext(file)[1].lower() in image_extensions:  # Prüft, ob die Datei eine Bilddatei ist
            image_count += 1  # Erhöht den Bildzähler

    return image_count  # Gibt die Anzahl der Bilder zurück


def apply_random_transformation(img):  # Definiert eine Funktion zur zufälligen Bildtransformation
    transformations = [  # Liste von möglichen Bildtransformationen
        ("contrast", lambda x: ImageEnhance.Contrast(x).enhance(random.uniform(1.5, 2.5))),
        ("brightness", lambda x: ImageEnhance.Brightness(x).enhance(random.uniform(1.5, 2.0))),
        ("darkness", lambda x: ImageEnhance.Brightness(x).enhance(random.uniform(0.2, 0.7))),
        ("grayscale", lambda x: ImageOps.grayscale(x)),
        ("black and white", lambda x: x.convert('L')),
        ("sharpness", lambda x: ImageEnhance.Sharpness(x).enhance(random.uniform(1.5, 2.5))),
        ("gaussian blur", lambda x: x.filter(ImageFilter.GaussianBlur(radius=random.uniform(1.5, 3.0)))),
        ("colorize", lambda x: ImageOps.colorize(x.convert('L'), black=generate_random_color(), white=generate_random_color()) if random.random() > 0.5 else x),
        ("vhs effect", apply_vhs_effect),
        ("damage", apply_damage),
        ("transparent spots", apply_transparent_spots)
    ]

    if random.random() > (1 - (effect_chance / 100)):  # Überprüft, ob ein Effekt angewendet werden soll
        num_effects = random.randint(1, 4)  # Wählt eine zufällige Anzahl von Effekten
        selected_transformations = random.sample(transformations, num_effects)  # Wählt zufällige Effekte aus
        effect_names = []  # Initialisiert eine Liste für Effekt-Namen
        for effect_name, transformation in selected_transformations:  # Durchläuft die ausgewählten Effekte
            img = transformation(img)  # Wendet die Transformation auf das Bild an
            effect_names.append(effect_name)  # Fügt den Effekt-Namen zur Liste hinzu
            if effect_name in effect_statistics:  # Aktualisiert die Effekt-Statistiken
                effect_statistics[effect_name] += 1
            else:
                effect_statistics[effect_name] = 1
        combined_effect_names = ", ".join(effect_names)  # Kombiniert die Effekt-Namen zu einem String
        return img, combined_effect_names  # Gibt das transformierte Bild und die Effekt-Namen zurück
    else:  # Falls kein Effekt angewendet wird
        skip_effect = "🧽"  # Definiert den Skip-Effekt
        if skip_effect in effect_statistics:  # Aktualisiert die Effekt-Statistiken
            effect_statistics[skip_effect] += 1
        else:
            effect_statistics[skip_effect] = 1
        return img, skip_effect  # Gibt das unveränderte Bild und den Skip-Effekt zurück

def apply_transparent_spots(img):  # Definiert eine Funktion zur Anwendung von transparenten Flecken
    width, height = img.size  # Holt die Bildabmessungen
    spots = Image.new('RGBA', (width, height), (0, 0, 0, 0))  # Erstellt ein neues transparentes Bild
    draw = ImageDraw.Draw(spots)  # Erstellt ein Zeichnungsobjekt
    num_spots = random.randint(10, 30)  # Wählt eine zufällige Anzahl von Flecken

    for _ in range(num_spots):  # Zeichnet die Flecken auf das Bild
        x = random.randint(0, width)  # Wählt eine zufällige x-Position für den Fleck
        y = random.randint(0, height)  # Wählt eine zufällige y-Position für den Fleck
        radius = random.randint(10, 100)  # Wählt einen zufälligen Radius für den Fleck
        opacity = random.randint(30, 120)  # Wählt eine zufällige Deckkraft für den Fleck
        color = (random.randint(50, 150), random.randint(50, 150), random.randint(50, 150), opacity)  # Wählt eine zufällige Farbe und Deckkraft für den Fleck

        draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=color)  # Zeichnet den Fleck auf das Bild

    img = Image.alpha_composite(img.convert('RGBA'), spots)  # Kombiniert die Flecken mit dem Bild
    return img  # Gibt das veränderte Bild zurück


def apply_distortion(img):  # Definiert eine Funktion zur Anwendung von Verzerrungen
    width, height = img.size  # Holt die Bildabmessungen
    m = -0.5  # Setzt den Verzerrungsparameter
    xshift = abs(m) * width  # Berechnet die Verschiebung in x-Richtung
    new_width = width + int(round(xshift))  # Berechnet die neue Bildbreite
    img = img.transform((new_width, height), Image.AFFINE,  # Wendet die Verzerrung an
                        (1, m, -xshift if m > 0 else 0, 0, 1, 0), Image.BICUBIC)
    img = img.crop((int(xshift / 2), 0, int(xshift / 2) + width, height))  # Schneidet das Bild zu
    return img  # Gibt das verzerrte Bild zurück


def apply_damage(img):  # Definiert eine Funktion zur Anwendung von Beschädigungen
    width, height = img.size  # Holt die Bildabmessungen

    if img.mode != 'RGB':  # Prüft, ob der Bildmodus RGB ist
        img = img.convert('RGB')  # Konvertiert das Bild in RGB

    scratches = Image.new('RGB', (width, height), (0, 0, 0))  # Erstellt ein neues Bild für Kratzer
    draw = ImageDraw.Draw(scratches)  # Erstellt ein Zeichnungsobjekt

    for _ in range(random.randint(5, 15)):  # Zeichnet Kratzer auf das Bild
        start_pos = (random.randint(0, width), random.randint(0, height))
        end_pos = (random.randint(0, width), random.randint(0, height))
        line_color = (random.randint(100, 150), random.randint(100, 150), random.randint(100, 150))
        draw.line([start_pos, end_pos], fill=line_color, width=random.randint(1, 3))

    scratches = scratches.filter(ImageFilter.GaussianBlur(radius=1))  # Wendet einen Weichzeichner an
    img = Image.blend(img, scratches, alpha=0.1)  # Mischt die Kratzer mit dem Bild

    enhancer = ImageEnhance.Color(img)  # Erstellt ein Farbenhancement-Objekt
    img = enhancer.enhance(0.8)  # Verringert die Farbsättigung

    noise = Image.effect_noise((width, height), 10)  # Erstellt ein Rauschbild
    noise = Image.blend(img, noise.convert('RGB'), alpha=0.05)  # Mischt das Rauschbild mit dem Originalbild

    for _ in range(random.randint(0, 3)):  # Fügt zufällige Flecken hinzu
        blotch_size = random.randint(10, 100)
        blotch_x = random.randint(0, width - blotch_size)
        blotch_y = random.randint(0, height - blotch_size)
        blotch_shape = [blotch_x, blotch_y, blotch_x + blotch_size, blotch_y + blotch_size]
        draw.ellipse(blotch_shape, fill=(random.randint(150, 200), random.randint(150, 200), random.randint(150, 200)))

    img = img.convert('RGBA')  # Konvertiert das Bild in RGBA
    return img  # Gibt das beschädigte Bild zurück

def apply_vhs_effect(img):  # Definiert eine Funktion zur Anwendung des VHS-Effekts
    img = img.convert('RGB')  # Konvertiert das Bild in RGB
    noise = Image.effect_noise(img.size, random.uniform(0.1, 0.5))  # Erstellt ein Rauschbild
    img = Image.blend(img, noise.convert('RGB'), alpha=random.uniform(0.2, 0.5))  # Mischt das Rauschbild mit dem Originalbild
    draw = ImageDraw.Draw(img)  # Erstellt ein Zeichnungsobjekt
    for y in range(0, img.height, 4):  # Zeichnet horizontale Linien
        draw.line([(0, y), (img.width, y)],
                  fill=(random.randint(0, 255), random.randint(0, 255), random.randint(0, 255)), width=1)

    img = img.filter(ImageFilter.GaussianBlur(radius=random.uniform(0.5, 1.5)))  # Wendet einen Weichzeichner an
    return img  # Gibt das veränderte Bild zurück


def random_rgb_shift(img):  # Definiert eine Funktion zur zufälligen RGB-Verschiebung
    r, g, b, a = img.split()  # Teilt das Bild in seine Kanäle auf
    r = r.point(lambda i: i + random.randint(-10, 10))  # Verschiebt den roten Kanal
    g = g.point(lambda i: i + random.randint(-10, 10))  # Verschiebt den grünen Kanal
    b = b.point(lambda i: i + random.randint(-10, 10))  # Verschiebt den blauen Kanal
    return Image.merge("RGBA", (r, g, b, a))  # Fügt die Kanäle wieder zusammen


def generate_random_color():  # Definiert eine Funktion zur Generierung zufälliger Farben
    return random.randint(0, 255), random.randint(0, 255), random.randint(0, 255)  # Gibt eine zufällige RGB-Farbe zurück


def random_rotate_and_scale_image(img):  # Definiert eine Funktion zum zufälligen Drehen und Skalieren von Bildern
    min_target_height = size // 25  # Setzt die minimale Zielhöhe
    max_target_height = (size * 15) // 16  # Setzt die maximale Zielhöhe
    target_height = random.randint(min_target_height, max_target_height)  # Wählt eine zufällige Zielhöhe
    aspect_ratio = img.width / img.height  # Berechnet das Seitenverhältnis
    target_width = int(target_height * aspect_ratio)  # Berechnet die Zielbreite
    img_resized = img.resize((target_width, target_height), Image.Resampling.LANCZOS)  # Skaliert das Bild

    angle = random.randint(-360, 360)  # Wählt einen zufälligen Drehwinkel
    img_rotated = img_resized.rotate(angle, expand=True, fillcolor=(0, 0, 0, 0))  # Dreht das Bild

    return img_rotated  # Gibt das gedrehte und skalierte Bild zurück


def create_annotation_file(final_path, annotations, image_size):  # Definiert eine Funktion zur Erstellung von Annotationsdateien
    class_index = 0  # Setzt den Klassenindex

    with open(final_path.replace('.png', '.txt'), 'w') as file:  # Öffnet die Annotationsdatei zum Schreiben
        for x, y, width, height in annotations:  # Durchläuft die Annotationsdaten
            x_center = (x + width / 2) / image_size[0]  # Berechnet das Zentrum in x-Richtung
            y_center = (y + height / 2) / image_size[1]  # Berechnet das Zentrum in y-Richtung
            norm_width = width / image_size[0]  # Normiert die Breite
            norm_height = height / image_size[1]  # Normiert die Höhe
            file.write(f"{class_index} {x_center} {y_center} {norm_width} {norm_height}\n")  # Schreibt die Annotationsdaten in die Datei


def place_multiple_images_on_background(images, bg):  # Definiert eine Funktion zum Platzieren mehrerer Bilder auf einem Hintergrund
    annotations = []  # Initialisiert eine Liste für Annotationsdaten
    for img in images:  # Durchläuft die Bilder
        while img.width > bg.width or img.height > bg.height:  # Prüft, ob das Bild größer als der Hintergrund ist
            scale_factor = min(bg.width / img.width, bg.height / img.height)  # Berechnet den Skalierungsfaktor
            new_width = int(
                img.width * scale_factor * 0.9)  # Berechnet die neue Breite
            new_height = int(img.height * scale_factor * 0.9)  # Berechnet die neue Höhe
            img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)  # Skaliert das Bild

        max_x = bg.width - img.width  # Berechnet die maximale x-Position
        max_y = bg.height - img.height  # Berechnet die maximale y-Position
        x = random.randint(0, max_x)  # Wählt eine zufällige x-Position
        y = random.randint(0, max_y)  # Wählt eine zufällige y-Position
        bg.paste(img, (x, y), img)  # Fügt das Bild in den Hintergrund ein
        annotations.append((x, y, img.width, img.height))  # Fügt die Annotationsdaten zur Liste hinzu
    return bg, annotations  # Gibt den Hintergrund und die Annotationsdaten zurück


def download_background(url, timeout=10):  # Definiert eine Funktion zum Herunterladen eines Hintergrundbildes
    try:
        response = requests.get(url, timeout=timeout)  # Sendet eine HTTP-Anfrage
        if response.status_code == 200:  # Prüft den Statuscode der Antwort
            return Image.open(BytesIO(response.content)).convert('RGBA')  # Öffnet das Bild und konvertiert es in RGBA
    except requests.RequestException as e:  # Fängt Ausnahmen ab
        print(f"Error downloading background: {e}")  # Gibt eine Fehlermeldung aus
    return None  # Gibt None zurück, wenn das Herunterladen fehlschlägt


def process_images(input_folder, output_folder, num_images=1):  # Definiert eine Funktion zur Verarbeitung von Bildern
    global done, expected  # Verwendet globale Variablen
    for img_name in os.listdir(input_folder):  # Durchläuft die Dateien im Eingabeordner
        if img_name.endswith('.png'):  # Prüft, ob die Datei eine PNG-Datei ist
            img_path = os.path.join(input_folder, img_name)  # Erstellt den vollständigen Dateipfad
            with Image.open(img_path) as img:  # Öffnet das Bild
                img = img.convert('RGBA')  # Konvertiert das Bild in RGBA

                for i in range(num_images):  # Durchläuft die Anzahl der zu erstellenden Bilder
                    final_path = os.path.join(output_folder, f'{img_name.split(".")[0]}_{i}.png')  # Erstellt den Pfad für das Ausgabebild
                    url_index = next(global_url_counter)  # Holt die nächste URL für den Hintergrund
                    url = bg_urls[url_index]  # Holt die URL aus der Liste

                    bg = None  # Initialisiert den Hintergrund
                    while not bg:  # Versucht, den Hintergrund herunterzuladen
                        bg = download_background(url)
                        if not bg:
                            url_index = next(global_url_counter)
                            url = bg_urls[url_index]

                    img_transformed = random_rotate_and_scale_image(img)  # Dreht und skaliert das Bild

                    if random.random() < 0.25:  # Prüft, ob das Bild dupliziert werden soll
                        duplication_count = random.choice([2, 3])  # Wählt die Anzahl der Duplikate
                        images = [img_transformed for _ in range(duplication_count)]  # Erstellt die Duplikate
                    elif random.random() < 0.25:  # Prüft, ob das Bild verdoppelt werden soll
                        images = [img_transformed, img_transformed]  # Verdoppelt das Bild
                    else:
                        images = [img_transformed]  # Verwendet das Bild einmal

                    final_image, annotations = place_multiple_images_on_background(images, bg)  # Platziert die Bilder auf dem Hintergrund
                    img_transformed_f, effect_name = apply_random_transformation(final_image)  # Wendet zufällige Effekte an

                    data = img_transformed_f.getdata()  # Holt die Bilddaten
                    img_no_profile = Image.new(img_transformed_f.mode, img_transformed_f.size)  # Erstellt ein neues Bild ohne Farbprofil
                    img_no_profile.putdata(data)  # Fügt die Bilddaten hinzu
                    img_no_profile.save(final_path)  # Speichert das Bild

                    create_annotation_file(final_path, annotations, final_image.size)  # Erstellt die Annotationsdatei
                    sleep(0.5)  # Wartet 0,5 Sekunden


if __name__ == '__main__':  # Überprüft, ob das Skript direkt ausgeführt wird
    start_time = datetime.now()  # Speichert die Startzeit
    print(f"Script started at: {start_time}")  # Gibt die Startzeit aus
    os.makedirs(output_folder, exist_ok=True)  # Erstellt den Ausgabordner, falls er nicht existiert
    process_images(input_folder, output_folder, probe_size)  # Startet die Bildverarbeitung
    end_time = datetime.now()  # Speichert die Endzeit
    print(f"Script finished at: {end_time}")  # Gibt die Endzeit aus
    elapsed_time = end_time - start_time  # Berechnet die verstrichene Zeit
    print(f"Elapsed time: {elapsed_time}")  # Gibt die verstrichene Zeit aus
