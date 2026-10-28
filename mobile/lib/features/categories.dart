import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n_ext.dart';
import '../data/db.dart';
import '../providers.dart';
import 'common.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, Category? c) async {
    final name = TextEditingController(text: c?.name);
    var color = c?.color ?? palette.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(c == null ? ctx.t.newCategory : ctx.t.editCategory),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, autofocus: true, decoration: InputDecoration(labelText: ctx.t.name)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final p in palette)
                GestureDetector(
                  onTap: () => setS(() => color = p),
                  child: CircleAvatar(
                    backgroundColor: Color(p),
                    radius: 16,
                    child: color == p ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                ),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.t.ok)),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    await ref.read(repoProvider).saveCategory(
        id: c?.id, spaceId: c?.spaceId ?? ref.read(spaceIdProvider), name: name.text.trim(), color: color);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    return Scaffold(
      appBar: AppBar(title: Text(context.t.categories)),
      floatingActionButton: ref.watch(canWriteProvider) ? FloatingActionButton(onPressed: () => _edit(context, ref, null), child: const Icon(Icons.add)) : null,
      body: ListView(children: [
        for (final c in cats)
          ListTile(
            leading: CircleAvatar(backgroundColor: Color(c.color), radius: 14),
            title: Text(c.name),
            onTap: () => _edit(context, ref, c),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirm(context, context.t.deleteCategoryConfirm(c.name))) {
                  await ref.read(repoProvider).deleteCategory(c.spaceId, c.id);
                }
              },
            ),
          ),
      ]),
    );
  }
}
