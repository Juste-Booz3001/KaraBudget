import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

bool get _mobile => Platform.isAndroid || Platform.isIOS;

/// Photo de reçu choisie par l'utilisateur et, sur mobile, le texte reconnu par ML Kit.
class ReceiptScan {
  const ReceiptScan(this.path, this.text);
  final String path;
  final String? text; // null : pas d'OCR sur cette plateforme
}

/// Prend (ou choisit) la photo d'un ticket. Sur mobile : ML Kit (sur l'appareil, hors-ligne) lit le texte,
/// la photo est gardée pour être jointe à la dépense. Sur ordinateur : choix d'un fichier, sans OCR.
Future<ReceiptScan?> pickReceipt({bool camera = true, bool ocr = true}) async {
  final source = camera && _mobile ? ImageSource.camera : ImageSource.gallery;
  final picked = await ImagePicker().pickImage(source: source, maxWidth: 1800, imageQuality: 80);
  if (picked == null) return null;
  if (!ocr || !_mobile) return ReceiptScan(picked.path, null);
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    final result = await recognizer.processImage(InputImage.fromFilePath(picked.path));
    return ReceiptScan(picked.path, result.text);
  } finally {
    recognizer.close();
  }
}
