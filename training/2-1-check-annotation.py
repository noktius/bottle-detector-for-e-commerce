import os
import random
import matplotlib.pyplot as plt
from PIL import Image, ImageDraw

folder = 'pictures/4-extended'  # Ordner mit Bildern und Annotationen

def add_texture_to_shadow(draw, left, top, right, bottom, line_width=10, line_color=(255, 255, 0, 32)):
    """
    Fügt horizontal verlaufende Linien zur Texturierung eines Schattenbereichs in einem Bild hinzu

    Args:
        draw (ImageDraw.Draw): Das Zeichenobjekt, das zur Bearbeitung des Bildes verwendet wird
        left (int): Die linke Grenze des Rechtecks
        top (int): Die obere Grenze des Rechtecks
        right (int): Die rechte Grenze des Rechtecks
        bottom (int): Die untere Grenze des Rechtecks
        line_width (int, optional): Die Breite der Linien. Standardwert ist 10
        line_color (tuple, optional): Die Farbe der Linien im RGBA-Format. Standardwert ist (255, 255, 0, 32)
    """
    y_start = top
    while y_start < bottom:
        draw.line([(left, y_start), (right, y_start)], fill=line_color, width=line_width)
        y_start += line_width * 2

if __name__ == '__main__':
    image_files = [f for f in os.listdir(folder) if f.endswith('.png')]  # Liste alle PNG-Dateien im Ordner
    random_image_file = random.choice(image_files)  # Wählt eine zufällige Bilddatei
    image = Image.open(os.path.join(folder, random_image_file))  # Öffnet das ausgewählte Bild
    img_width, img_height = image.size  # Ermittelt Breite und Höhe des Bildes

    annotation_file = random_image_file[:-4] + '.txt'  # Bildet den Dateinamen der Annotationen

    with open(os.path.join(folder, annotation_file), 'r') as file:  # Öffnet die Annotationsdatei
        annotations = [list(map(float, line.split()[1:])) for line in file.readlines()]  # Liest und verarbeitet die Annotationsdaten

    shadow = Image.new('RGBA', (img_width, img_height), (0, 0, 0, 0))  # Erstellt ein transparentes Overlay
    draw = ImageDraw.Draw(shadow)  # Erstellt ein Zeichenobjekt für das Overlay

    for x_center, y_center, width, height in annotations:
        x_center *= img_width  # Skaliert den x-Mittelpunkt
        y_center *= img_height  # Skaliert den y-Mittelpunkt
        width *= img_width  # Skaliert die Breite
        height *= img_height  # Skaliert die Höhe

        left = x_center - (width / 2)  # Berechnet die linke Grenze
        top = y_center - (height / 2)  # Berechnet die obere Grenze
        right = x_center + (width / 2)  # Berechnet die rechte Grenze
        bottom = y_center + (height / 2)  # Berechnet die untere Grenze

        draw.rectangle([left, top, right, bottom], fill=(0, 0, 0, 127))  # Zeichnet ein Rechteck auf das Overlay
        add_texture_to_shadow(draw, left, top, right, bottom)  # Fügt Texturen zu den Rechtecken hinzu

    combined = Image.alpha_composite(image.convert('RGBA'), shadow)  # Kombiniert das Bild mit dem Overlay

    plt.figure(figsize=(10, 10))  # Erstellt eine Figur für die Darstellung
    plt.imshow(combined)  # Zeigt das kombinierte Bild
    plt.axis('off')  # Entfernt die Achsen
    plt.subplots_adjust(left=0, right=1, top=1, bottom=0)  # Passt den Plot an das Bild an
    plt.show()
