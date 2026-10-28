import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/backup.dart';
import '../core/export.dart';
import '../core/l10n_ext.dart';
import '../core/money.dart';
import '../data/db.dart' show Category;
import '../providers.dart';
import '../sync/api_client.dart';
import 'app_lock.dart';
import 'categories.dart';
import 'common.dart';
import 'goals.dart';
import 'import_csv.dart';
import 'rates.dart';
import 'recurring.dart';
import 'shared.dart';
import 'templates.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _auth(BuildContext context, WidgetRef ref) async {
    final email = TextEditingController();
    final pass = TextEditingController();
    var register = false;
    String? error;
    var busy = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(register ? ctx.t.createAccount : ctx.t.signIn),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: ctx.t.email)),
            TextField(controller: pass, obscureText: true, decoration: InputDecoration(labelText: ctx.t.passwordHint)),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
            TextButton(onPressed: () => setS(() => register = !register), child: Text(register ? ctx.t.haveAccount : ctx.t.createAccount)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.t.cancel)),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setS(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await ref.read(sessionProvider.notifier).authenticate(email.text, pass.text, register: register);
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setS(() {
                          busy = false;
                          error = apiError(e);
                        });
                      }
                    },
              child: Text(register ? ctx.t.create : ctx.t.signInAction),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref, {required bool pdf}) async {
    final list = await ref.read(monthExpensesProvider.future);
    final cats = <String, Category>{for (final c in ref.read(categoriesProvider).valueOrNull ?? const <Category>[]) c.id: c};
    final cur = ref.read(currencyProvider);
    final month = ref.read(selectedMonthProvider);
    final key = monthKey(month);
    if (!context.mounted) return;
    if (list.isEmpty) return snack(context, context.t.nothingToExport);
    if (pdf) {
      final bytes = await buildPdf(list, cats, cur, DateFormat.yMMMM(context.dateLocale).format(month));
      await shareBytes(bytes, 'depenses-$key.pdf', 'application/pdf');
    } else {
      final csv = buildCsv(list, cats, cur);
      await shareBytes(Uint8List.fromList(utf8.encode(csv)), 'depenses-$key.csv', 'text/csv');
    }
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    try {
      final file = await createBackupFile(ref.read(dbProvider));
      final done = await deliverFile(file);
      if (done && context.mounted) snack(context, context.t.backupCreated);
    } catch (e) {
      if (context.mounted) snack(context, e.toString());
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final t = context.t;
    if (!await confirm(context, t.restoreConfirm)) return;
    final res = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = res?.files.single.path;
    if (path == null) return;
    final ok = await stageRestore(File(path));
    if (!context.mounted) return;
    if (!ok) return snack(context, t.notABackup);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t.restorePrepared),
        content: Text(ctx.t.restartToFinish),
        actions: [TextButton(onPressed: () => SystemNavigator.pop(), child: Text(ctx.t.closeApp))],
      ),
    );
  }

  Future<T?> _pick<T>(BuildContext context, String title, Map<T, String> options, T current) => showDialog<T>(
        context: context,
        builder: (ctx) => SimpleDialog(title: Text(title), children: [
          for (final e in options.entries)
            ListTile(
              leading: Icon(e.key == current ? Icons.radio_button_checked : Icons.radio_button_off),
              title: Text(e.value),
              onTap: () => Navigator.pop(ctx, e.key),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final s = ref.watch(settingsProvider);
    final session = ref.watch(sessionProvider).valueOrNull;
    final status = ref.watch(syncControllerProvider);
    final pending = ref.watch(pendingOpsProvider).valueOrNull ?? 0;
    final loggedIn = session?.loggedIn ?? false;
    final notifier = ref.read(settingsProvider.notifier);
    final active = ref.watch(activeSpaceProvider);
    final canWrite = ref.watch(canWriteProvider);

    void push(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    String role(SpaceInfo sp) => sp.isPersonal ? t.personal : switch (sp.role) { 'owner' => t.roleOwner, 'viewer' => t.roleViewer, _ => t.roleEditor };

    return ListView(children: [
      SectionHeader(t.accountAndSync),
      ListTile(
        leading: const Icon(Icons.person),
        title: Text(loggedIn ? (s.email ?? t.signedIn) : t.notSignedIn),
        subtitle: Text(loggedIn ? t.autoSyncActive : t.dataStaysOnDevice),
        trailing: loggedIn
            ? TextButton(onPressed: () => ref.read(sessionProvider.notifier).logout(), child: Text(t.signOut))
            : FilledButton(onPressed: () => _auth(context, ref), child: Text(t.signIn)),
      ),
      ListTile(
        leading: const Icon(Icons.dns),
        title: Text(t.serverAddress),
        subtitle: Text(s.baseUrl),
        onTap: () async {
          final v = await promptText(context, t.serverAddress, initial: s.baseUrl, hint: 'https://…');
          if (v != null && v.isNotEmpty) notifier.update(baseUrl: v.replaceAll(RegExp(r'/+$'), ''));
        },
      ),
      ListTile(
        leading: const Icon(Icons.sync),
        title: Text(t.syncNow),
        subtitle: Text(status.error ?? '${t.pendingChanges(pending)}${status.last == null ? '' : ' · ${t.lastSync(DateFormat.Hm().format(status.last!))}'}'),
        enabled: loggedIn,
        onTap: () => ref.read(syncControllerProvider.notifier).trigger(immediate: true),
      ),
      if (loggedIn) ...[
        SectionHeader(t.spacesTitle),
        for (final sp in s.spaces)
          ListTile(
            leading: Icon(s.activeSpaceId == sp.id ? Icons.radio_button_checked : Icons.radio_button_off),
            title: Text(sp.name),
            subtitle: Text(role(sp)),
            trailing: sp.isPersonal
                ? null
                : IconButton(
                    tooltip: t.membersBalancesActivity,
                    icon: const Icon(Icons.groups),
                    onPressed: () {
                      notifier.update(activeSpaceId: sp.id);
                      push(const SharedSpaceScreen());
                    },
                  ),
            onTap: () => notifier.update(activeSpaceId: sp.id),
          ),
        ListTile(
          leading: const Icon(Icons.group_add),
          title: Text(t.createSharedSpace),
          onTap: () async {
            final name = await promptText(context, t.spaceName, hint: t.spaceNameHint);
            if (name == null || name.isEmpty) return;
            try {
              final sp = await ref.read(apiProvider).createSpace(name);
              await ref.read(sessionProvider.notifier).refreshSpaces();
              notifier.update(activeSpaceId: sp['id'] as String);
              ref.read(syncControllerProvider.notifier).trigger(immediate: true);
            } catch (e) {
              if (context.mounted) snack(context, apiError(e));
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.login),
          title: Text(t.joinSpace),
          onTap: () async {
            final code = await promptText(context, t.inviteCode);
            if (code == null || code.isEmpty) return;
            try {
              final sp = await ref.read(apiProvider).joinSpace(code);
              await ref.read(sessionProvider.notifier).refreshSpaces();
              notifier.update(activeSpaceId: sp['id'] as String);
              ref.read(syncControllerProvider.notifier).trigger(immediate: true);
            } catch (e) {
              if (context.mounted) snack(context, apiError(e));
            }
          },
        ),
        if (active != null && !active.isPersonal)
          ListTile(
            leading: const Icon(Icons.balance),
            title: Text(t.membersBalancesActivity),
            onTap: () => push(const SharedSpaceScreen()),
          ),
      ],
      SectionHeader(t.budgetAndData),
      ListTile(leading: const Icon(Icons.category), title: Text(t.categories), onTap: () => push(const CategoriesScreen())),
      ListTile(leading: const Icon(Icons.repeat), title: Text(t.recurringExpenses), onTap: () => push(const RecurringScreen())),
      ListTile(leading: const Icon(Icons.flag), title: Text(t.savingsGoals), onTap: () => push(const GoalsScreen())),
      ListTile(leading: const Icon(Icons.currency_exchange), title: Text(t.exchangeRates), onTap: () => push(const RatesScreen())),
      ListTile(leading: const Icon(Icons.bolt), title: Text(t.quickTemplates), onTap: () => push(const TemplatesScreen())),
      SectionHeader(t.importExportBackup),
      ListTile(
        leading: const Icon(Icons.upload_file),
        title: Text(t.importCsv),
        enabled: canWrite,
        onTap: () => push(const ImportCsvScreen()),
      ),
      ListTile(leading: const Icon(Icons.table_view), title: Text(t.exportCsv), onTap: () => _export(context, ref, pdf: false)),
      ListTile(leading: const Icon(Icons.picture_as_pdf), title: Text(t.exportPdf), onTap: () => _export(context, ref, pdf: true)),
      ListTile(leading: const Icon(Icons.save_alt), title: Text(t.backupDatabase), subtitle: Text(t.backupHelp), onTap: () => _backup(context, ref)),
      ListTile(leading: const Icon(Icons.restore), title: Text(t.restoreDatabase), onTap: () => _restore(context, ref)),
      SectionHeader(t.appearance),
      ListTile(
        leading: const Icon(Icons.attach_money),
        title: Text(t.defaultCurrency),
        subtitle: Text(s.currency),
        onTap: () async {
          final v = await _pick<String>(context, t.defaultCurrency, {for (final c in currenciesList) c: '$c  ${currencyOf(c).symbol}'}, s.currency);
          if (v != null) notifier.update(currency: v);
        },
      ),
      ListTile(
        leading: const Icon(Icons.brightness_6),
        title: Text(t.theme),
        subtitle: Text(switch (s.themeMode) { 'light' => t.themeLight, 'dark' => t.themeDark, _ => t.themeSystem }),
        onTap: () async {
          final v = await _pick<String>(context, t.theme, {'system': t.themeSystem, 'light': t.themeLight, 'dark': t.themeDark}, s.themeMode);
          if (v != null) notifier.update(themeMode: v);
        },
      ),
      ListTile(
        leading: const Icon(Icons.language),
        title: Text(t.language),
        subtitle: Text(switch (s.language) { 'fr' => 'Français', 'en' => 'English', 'mg' => 'Malagasy', _ => t.themeSystem }),
        onTap: () async {
          final v = await _pick<String>(context, t.language, {'system': t.themeSystem, 'fr': 'Français', 'en': 'English', 'mg': 'Malagasy'}, s.language);
          if (v != null) notifier.update(language: v);
        },
      ),
      if (Platform.isAndroid)
        SwitchListTile(
          secondary: const Icon(Icons.bolt),
          title: Text(t.quickEntryNotification),
          subtitle: Text(t.quickEntryHelp),
          value: s.quickNotification,
          onChanged: (v) => notifier.update(quickNotification: v),
        ),
      SectionHeader(t.security),
      const LockSettingsTiles(),
      const SizedBox(height: 32),
    ]);
  }
}
