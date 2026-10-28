import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/db.dart';

bool get _mobile => Platform.isAndroid || Platform.isIOS;

/// À appeler au démarrage, AVANT d'ouvrir la base : si une restauration a été préparée, on remplace
/// le fichier SQLite (l'ancien est gardé en `.before-restore`).
Future<void> applyPendingRestore() async {
  try {
    final path = await databaseFilePath();
    final pending = File('$path.restore');
    if (!await pending.exists()) return;
    final current = File(path);
    if (await current.exists()) await current.copy('$path.before-restore');
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final f = File('$path$suffix');
      if (await f.exists()) await f.delete();
    }
    await pending.rename(path);
  } catch (_) {
    // en cas de problème on garde la base actuelle plutôt que de bloquer le démarrage
  }
}

/// Copie cohérente de la base (même pendant que l'app l'utilise) via VACUUM INTO.
Future<File> createBackupFile(AppDatabase db) async {
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final name = 'karabudget-${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}.sqlite';
  final file = File('${(await getTemporaryDirectory()).path}/$name');
  if (await file.exists()) await file.delete();
  await db.customStatement("VACUUM INTO '${file.path.replaceAll("'", "''")}'");
  return file;
}

/// Mobile : feuille de partage. Ordinateur : boîte « Enregistrer sous ».
Future<bool> deliverFile(File file, {String mime = 'application/octet-stream'}) async {
  final name = file.uri.pathSegments.last;
  if (_mobile) {
    await Share.shareXFiles([XFile(file.path, mimeType: mime)]);
    return true;
  }
  final out = await FilePicker.platform.saveFile(fileName: name);
  if (out == null) return false;
  await file.copy(out);
  return true;
}

Future<bool> deliverBytes(Uint8List bytes, String name, String mime) async {
  final f = File('${(await getTemporaryDirectory()).path}/$name');
  await f.writeAsBytes(bytes);
  return deliverFile(f, mime: mime);
}

/// Vérifie que le fichier est bien une base SQLite (16 premiers octets) puis le prépare pour le
/// prochain démarrage. Retourne false si ce n'est pas une base SQLite.
Future<bool> stageRestore(File picked) async {
  final raf = await picked.open();
  final head = await raf.read(16);
  await raf.close();
  if (head.length < 16 || String.fromCharCodes(head.sublist(0, 15)) != 'SQLite format 3') return false;
  await picked.copy('${await databaseFilePath()}.restore');
  return true;
}
