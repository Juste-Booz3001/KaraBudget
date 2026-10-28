import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n_ext.dart';
import '../providers.dart';

/// Fichier d'un reçu : local, sinon téléchargé du serveur (null = introuvable / hors-ligne).
final receiptFileProvider = FutureProvider.family<File?, ({String space, String id})>((ref, key) async {
  try {
    return await ref.read(attachmentSyncProvider).fetch(key.space, key.id);
  } catch (_) {
    return null;
  }
});

class ReceiptThumb extends ConsumerWidget {
  const ReceiptThumb({super.key, required this.spaceId, required this.attachmentId, this.size = 88});
  final String spaceId, attachmentId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(receiptFileProvider((space: spaceId, id: attachmentId)));
    Widget box(Widget child) => SizedBox(width: size, height: size, child: Center(child: child));
    return file.when(
      loading: () => box(const CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => box(const Icon(Icons.broken_image)),
      data: (f) {
        if (f == null) return box(const Icon(Icons.cloud_off));
        if (f.path.endsWith('.pdf')) return box(const Icon(Icons.picture_as_pdf, size: 40));
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptFullScreen(file: f))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(f, width: size, height: size, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}

class ReceiptFullScreen extends StatelessWidget {
  const ReceiptFullScreen({super.key, required this.file});
  final File file;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.t.receipt)),
        body: InteractiveViewer(maxScale: 6, child: Center(child: Image.file(file))),
      );
}
