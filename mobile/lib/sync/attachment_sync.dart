import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../data/repository.dart';

/// Accès réseau aux pièces jointes (implémenté par ApiClient).
abstract class AttachmentApi {
  Future<void> putAttachment(String spaceId, String id, Uint8List bytes, String contentType);
  Future<Uint8List?> getAttachment(String spaceId, String id);
}

String contentTypeFor(String path) {
  final p = path.toLowerCase();
  if (p.endsWith('.png')) return 'image/png';
  if (p.endsWith('.webp')) return 'image/webp';
  if (p.endsWith('.pdf')) return 'application/pdf';
  return 'image/jpeg';
}

/// Fichiers des reçus, dans le dossier de l'application : <documents>/attachments/<id>.<ext>.
class AttachmentStore {
  const AttachmentStore();

  Future<Directory> _dir() async {
    final d = Directory('${(await getApplicationDocumentsDirectory()).path}/attachments');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<File?> find(String id) async {
    final d = await _dir();
    for (final ext in ['jpg', 'png', 'webp', 'pdf']) {
      final f = File('${d.path}/$id.$ext');
      if (await f.exists()) return f;
    }
    return null;
  }

  Future<File> save(String id, Uint8List bytes, String contentType) async {
    final ext = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'application/pdf' => 'pdf',
      _ => 'jpg',
    };
    return File('${(await _dir()).path}/$id.$ext').writeAsBytes(bytes, flush: true);
  }

  Future<void> delete(String id) async {
    final f = await find(id);
    if (f != null) await f.delete();
  }
}

/// Envoie les reçus en attente ; sans réseau, ils restent en file pour la prochaine synchro.
class AttachmentSync {
  AttachmentSync(this.repo, this.api, {this.store = const AttachmentStore()});
  final Repository repo;
  final AttachmentApi api;
  final AttachmentStore store;

  Future<void> uploadPending(String spaceId) async {
    for (final a in await repo.pendingAttachments(spaceId)) {
      final f = await store.find(a.id);
      if (f == null) {
        await repo.markAttachmentUploaded(a.id); // fichier perdu : inutile de réessayer
        continue;
      }
      await api.putAttachment(spaceId, a.id, await f.readAsBytes(), contentTypeFor(f.path));
      await repo.markAttachmentUploaded(a.id);
    }
  }

  /// Fichier local, sinon téléchargé depuis le serveur (puis gardé sur l'appareil).
  Future<File?> fetch(String spaceId, String id) async {
    final local = await store.find(id);
    if (local != null) return local;
    final bytes = await api.getAttachment(spaceId, id);
    if (bytes == null) return null;
    return store.save(id, bytes, _sniff(bytes));
  }

  String _sniff(Uint8List b) {
    if (b.length > 4 && b[0] == 0x89 && b[1] == 0x50) return 'image/png';
    if (b.length > 4 && b[0] == 0x25 && b[1] == 0x50) return 'application/pdf';
    if (b.length > 12 && b[8] == 0x57 && b[9] == 0x45) return 'image/webp';
    return 'image/jpeg';
  }
}
