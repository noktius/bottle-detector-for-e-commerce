from PIL import Image, ExifTags
import os

def trim_images(input_folder, output_folder):
    """
    Beschneidet Bilder basierend auf ihrer EXIF-Orientierung und speichert die zugeschnittenen Versionen in einem neuen Ordner

    Args:
        input_folder (str): Pfad zum Ordner, der die Originalbilder enthält
        output_folder (str): Pfad zum Ordner, in dem die zugeschnittenen Bilder gespeichert werden sollen
    """
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)  # Erstellt den Ausgabeordner, falls nicht vorhanden

    for file_name in os.listdir(input_folder):
        if file_name.lower().endswith(('.png', '.jpg', '.jpeg', '.tiff', '.bmp')):  # Überprüft die Dateiendungen
            file_path = os.path.join(input_folder, file_name)  # Erstellt den vollständigen Dateipfad
            try:
                with Image.open(file_path) as img:  # Öffnet die Bilddatei
                    try:
                        for orientation in ExifTags.TAGS.keys():  # Durchsucht EXIF-Tags
                            if ExifTags.TAGS[orientation] == 'Orientation':  # Findet die Orientierung
                                break
                        exif = dict(img._getexif().items())
                        if exif[orientation] == 3:
                            img = img.rotate(180, expand=True)  # Dreht das Bild um 180 Grad
                        elif exif[orientation] == 6:
                            img = img.rotate(270, expand=True)  # Dreht das Bild um 270 Grad
                        elif exif[orientation] == 8:
                            img = img.rotate(90, expand=True)  # Dreht das Bild um 90 Grad
                    except (AttributeError, KeyError, IndexError):
                        pass  # Handhabt Ausnahmen, falls EXIF-Daten fehlen

                    if img.mode in ('RGBA', 'LA') or (img.mode == 'P' and 'transparency' in img.info):
                        img = img.convert("RGBA")  # Konvertiert das Bild in RGBA
                        bbox = img.getbbox()  # Ermittelt den Bereich des Bildes, der geschnitten werden soll
                        if bbox:
                            cropped_image = img.crop(bbox)  # Schneidet das Bild zu
                            output_path = os.path.join(output_folder, file_name)  # Setzt den Pfad für das zugeschnittene Bild
                            cropped_image.save(output_path)  # Speichert das zugeschnittene Bild
                    else:
                        print(f"Image {file_name} does not support transparency")  # Gibt eine Meldung aus, falls Transparenz nicht unterstützt wird
            except Exception as e:
                print(f"Error processing {file_name}: {e}")  # Gibt Fehlermeldungen aus
        else:
            print(f"Skipped non-image file: {file_name}")  # Gibt eine Meldung aus, wenn eine Datei übersprungen wird

if __name__ == '__main__':
    input_folder = 'pictures/2-removed-bg'  # Definiert den Eingabeordner
    output_folder = 'pictures/3-cropped'  # Definiert den Ausgabeordner

    trim_images(input_folder, output_folder)
