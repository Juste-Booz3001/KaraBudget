import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/l10n_ext.dart';
import '../core/money.dart';
import '../core/notifications.dart';
import '../core/receipt_ocr.dart';
import '../core/splits.dart';
import '../core/tags.dart';
import '../data/db.dart';
import '../providers.dart';
import '../sync/attachment_sync.dart';
import '../theme.dart';
import 'common.dart';
import 'receipt_view.dart';

class ExpenseEditScreen extends ConsumerStatefulWidget {
  const ExpenseEditScreen({super.key, this.expense});
  final Expense? expense;
  @override
  ConsumerState<ExpenseEditScreen> createState() => _ExpenseEditState();
}

enum _SplitMode { none, equal, exact }

class _ExpenseEditState extends ConsumerState<ExpenseEditScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _tags = TextEditingController();
  String? _categoryId;
  late DateTime _date;
  late String _currency;

  // reçu
  String? _attachmentId; // déjà enregistré
  String? _newPhotoPath; // choisi, pas encore enregistré

  // partage
  String? _paidBy;
  _SplitMode _mode = _SplitMode.none;
  final Set<String> _with = {};
  final Map<String, TextEditingController> _exact = {};

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _currency = e?.currency ?? ref.read(settingsProvider).currency;
    if (e != null) {
      _amount.text = plainMinor(e.amountMinor, currencyOf(e.currency)).replaceAll('.', ',');
      _note.text = e.note;
      _tags.text = e.tags.replaceAll(',', ', ');
      _categoryId = e.categoryId;
      _date = DateTime.fromMillisecondsSinceEpoch(e.spentAt);
      _attachmentId = e.attachmentId;
      _paidBy = e.paidBy;
      final split = parseSplit(e.splitJson);
      if (split != null) {
        _mode = split.mode == 'equal' ? _SplitMode.equal : _SplitMode.exact;
        _with.addAll(split.participants);
        if (split.mode == 'exact') {
          split.shares.forEach((u, v) => _exact[u] = TextEditingController(text: plainMinor(v, currencyOf(e.currency)).replaceAll('.', ',')));
        }
      }
    } else {
      _date = DateTime.now();
      _paidBy = ref.read(settingsProvider).userId;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _tags.dispose();
    for (final c in _exact.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _scan({required bool camera, required bool ocr}) async {
    try {
      final scan = await pickReceipt(camera: camera, ocr: ocr);
      if (scan == null || !mounted) return;
      setState(() => _newPhotoPath = scan.path);
      final text = scan.text;
      if (text == null) return;
      final total = extractTotal(text, currencyOf(_currency).decimals);
      if (!mounted) return;
      if (total == null) return snack(context, context.t.noAmountDetected);
      setState(() => _amount.text = plainMinor(total, currencyOf(_currency)).replaceAll('.', ','));
      snack(context, context.t.totalDetected);
    } catch (e) {
      if (mounted) snack(context, context.t.scanFailed(e.toString()));
    }
  }

  void _applyTemplate(QuickTemplate t) {
    setState(() {
      if (t.amountMinor != null) {
        final cur = currencyOf(t.currency ?? _currency);
        _currency = cur.code;
        _amount.text = plainMinor(t.amountMinor!, cur).replaceAll('.', ',');
      }
      if (t.categoryId != null) _categoryId = t.categoryId;
      if (t.note.isNotEmpty) _note.text = t.note;
      if (t.tags.isNotEmpty) _tags.text = t.tags.replaceAll(',', ', ');
    });
  }

  Future<void> _saveAsTemplate() async {
    final name = await promptText(context, context.t.templateName, initial: _note.text.trim());
    if (name == null || name.isEmpty) return;
    final cur = currencyOf(_currency);
    await ref.read(repoProvider).saveTemplate(
          name: name,
          amountMinor: parseMinor(_amount.text, cur.decimals),
          currency: _currency,
          categoryId: _categoryId,
          note: _note.text.trim(),
          tags: _tags.text,
        );
    if (mounted) snack(context, context.t.templateSaved);
  }

  /// Parts du partage ; null + message si invalide.
  String? _buildSplit(int amount, Currency cur, void Function(String) fail) {
    if (_mode == _SplitMode.none) return '';
    if (_with.isEmpty) {
      fail(context.t.splitNeedsPeople);
      return null;
    }
    if (_mode == _SplitMode.equal) return SplitSpec.equal(_with.toList()..sort()).encode();
    final shares = <String, int>{};
    for (final u in _with) {
      final v = parseMinor(_exact[u]?.text ?? '', cur.decimals);
      if (v == null) {
        fail(context.t.invalidAmount);
        return null;
      }
      shares[u] = v;
    }
    if (!exactSharesValid(amount, shares)) {
      fail(context.t.sharesMustEqualTotal);
      return null;
    }
    return SplitSpec.exact(shares).encode();
  }

  Future<void> _save() async {
    final cur = currencyOf(_currency);
    final minor = parseMinor(_amount.text, cur.decimals);
    if (minor == null || minor <= 0) return snack(context, context.t.invalidAmount);
    final shared = ref.read(isSharedSpaceProvider);
    String? failure;
    final split = shared ? _buildSplit(minor, cur, (m) => failure = m) : '';
    if (split == null) return snack(context, failure ?? context.t.invalidAmount);

    final String space = widget.expense?.spaceId ?? ref.read(spaceIdProvider);
    final repo = ref.read(repoProvider);

    String? attachmentId = _attachmentId;
    if (_newPhotoPath != null) {
      final file = File(_newPhotoPath!);
      final newId = const Uuid().v4();
      await const AttachmentStore().save(newId, await file.readAsBytes(), contentTypeFor(file.path));
      await repo.markAttachmentPending(space, newId);
      attachmentId = newId;
    }

    await repo.saveExpense(
      id: widget.expense?.id,
      spaceId: space,
      amountMinor: minor,
      currency: _currency,
      categoryId: _categoryId,
      note: _note.text.trim(),
      spentAt: _date.millisecondsSinceEpoch,
      tags: normalizeTags(_tags.text),
      paidBy: shared ? _paidBy : null,
      splitJson: split,
      attachmentId: attachmentId,
    );
    await _budgetAlert(space, cur);
    if (mounted) Navigator.pop(context);
  }

  /// Alerte locale si le budget disponible de la catégorie (report inclus) est atteint à 80 % ou dépassé.
  Future<void> _budgetAlert(String space, Currency spent) async {
    final cat = _categoryId;
    if (cat == null) return;
    final display = ref.read(currencyProvider);
    final st = await ref.read(repoProvider).budgetState(space, cat, _date, display.code, ref.read(rateTableProvider));
    final limit = st.effective;
    if (limit == null || limit <= 0 || st.spent * 100 < limit * 80) return;
    if (!mounted) return;
    final name = ref.read(categoriesProvider).valueOrNull?.where((c) => c.id == cat).firstOrNull?.name ?? '';
    final over = st.spent > limit;
    await NotificationService.instance.alert(
      over ? context.t.budgetExceeded : context.t.budgetAlmostReached,
      '$name : ${formatMinor(st.spent, display)} / ${formatMinor(limit, display)}',
    );
  }

  Widget _receiptSection() {
    final t = context.t;
    final String space = widget.expense?.spaceId ?? ref.read(spaceIdProvider);
    Widget? preview;
    if (_newPhotoPath != null) {
      preview = ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_newPhotoPath!), width: 88, height: 88, fit: BoxFit.cover));
    } else if (_attachmentId != null) {
      preview = ReceiptThumb(spaceId: space, attachmentId: _attachmentId!);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t.receipt, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      Row(children: [
        if (preview != null) ...[preview, const SizedBox(width: 12)],
        Expanded(
          child: Wrap(spacing: 8, runSpacing: 4, children: [
            OutlinedButton.icon(
              onPressed: () => _scan(camera: true, ocr: true),
              icon: const Icon(Icons.document_scanner),
              label: Text(t.scanReceipt),
            ),
            OutlinedButton.icon(
              onPressed: () => _scan(camera: false, ocr: false),
              icon: const Icon(Icons.photo_library),
              label: Text(t.attachPhoto),
            ),
            if (preview != null)
              TextButton.icon(
                onPressed: () => setState(() {
                  _newPhotoPath = null;
                  _attachmentId = null;
                }),
                icon: const Icon(Icons.delete_outline),
                label: Text(t.removePhoto),
              ),
          ]),
        ),
      ]),
    ]);
  }

  Widget _sharingSection() {
    final t = context.t;
    final String space = widget.expense?.spaceId ?? ref.read(spaceIdProvider);
    final members = ref.watch(membersProvider(space)).valueOrNull ?? const <MemberInfo>[];
    if (members.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 32),
      DropdownButtonFormField<String>(
        key: ValueKey('$_paidBy-${members.length}'),
        initialValue: members.any((m) => m.userId == _paidBy) ? _paidBy : null,
        decoration: InputDecoration(labelText: t.paidBy),
        items: [for (final m in members) DropdownMenuItem(value: m.userId, child: Text(m.label))],
        onChanged: (v) => setState(() => _paidBy = v),
      ),
      const SizedBox(height: 12),
      SegmentedButton<_SplitMode>(
        segments: [
          ButtonSegment(value: _SplitMode.none, label: Text(t.splitNone)),
          ButtonSegment(value: _SplitMode.equal, label: Text(t.splitEqual)),
          ButtonSegment(value: _SplitMode.exact, label: Text(t.splitExact)),
        ],
        selected: {_mode},
        onSelectionChanged: (s) => setState(() {
          _mode = s.first;
          if (_mode != _SplitMode.none && _with.isEmpty) _with.addAll(members.map((m) => m.userId));
        }),
      ),
      if (_mode != _SplitMode.none)
        for (final m in members)
          Row(children: [
            Checkbox(
              value: _with.contains(m.userId),
              onChanged: (v) => setState(() => v == true ? _with.add(m.userId) : _with.remove(m.userId)),
            ),
            Expanded(child: Text(m.label)),
            if (_mode == _SplitMode.exact && _with.contains(m.userId))
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _exact.putIfAbsent(m.userId, TextEditingController.new),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(isDense: true),
                ),
              ),
          ]),
    ]);
  }

  // ---------------- saisie du montant au clavier numérique ----------------
  void _key(String k) {
    final cur = currencyOf(_currency);
    var s = _amount.text;
    HapticFeedback.selectionClick();
    if (k == '⌫') {
      if (s.isNotEmpty) s = s.substring(0, s.length - 1);
    } else if (k == ',') {
      if (cur.decimals == 0 || s.contains(',')) return;
      s = s.isEmpty ? '0,' : '$s,';
    } else {
      final i = s.indexOf(',');
      if (i >= 0 && s.length - i - 1 >= cur.decimals) return;
      if (i < 0 && s.length >= 12) return;
      s = s == '0' ? k : '$s$k';
    }
    setState(() => _amount.text = s);
  }

  /// Clavier physique (ordinateur) : chiffres, virgule/point, retour arrière, Entrée. Ignoré pendant la saisie d'un champ texte.
  KeyEventResult _hardwareKey(FocusNode _, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final focus = FocusManager.instance.primaryFocus;
    if (focus?.context?.widget is EditableText) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.backspace) {
      _key('⌫');
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (ref.read(canWriteProvider)) _save();
      return KeyEventResult.handled;
    }
    final ch = e.character;
    if (ch == null) return KeyEventResult.ignored;
    if (RegExp(r'^[0-9]$').hasMatch(ch)) {
      _key(ch);
      return KeyEventResult.handled;
    }
    if (ch == ',' || ch == '.') {
      _key(',');
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static String _group(String raw) {
    final i = raw.indexOf(',');
    final whole = i < 0 ? raw : raw.substring(0, i);
    final frac = i < 0 ? '' : raw.substring(i);
    return '${whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')}$frac';
  }

  Widget _amountDisplay(Currency cur, Currency display, int? converted) {
    final t = context.t;
    final k = context.kara;
    final text = Theme.of(context).textTheme;
    final empty = _amount.text.isEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(children: [
        PopupMenuButton<String>(
          tooltip: t.currency,
          initialValue: _currency,
          onSelected: (c) => setState(() => _currency = c),
          itemBuilder: (_) => [for (final c in currenciesList) PopupMenuItem(value: c, child: Text(c))],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: k.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: k.hairline)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_currency, style: text.titleSmall),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 18, color: k.muted),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(
              _group(empty ? '0' : _amount.text),
              style: text.displayMedium?.copyWith(fontSize: 60, fontWeight: FontWeight.w800, color: empty ? k.muted : Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(width: 8),
            Text(cur.symbol, style: text.headlineSmall?.copyWith(color: k.muted)),
          ]),
        ),
        SizedBox(
          height: 22,
          child: _currency == display.code
              ? null
              : Text(converted != null ? '≈ ${formatMinor(converted, display)}' : t.noRateFor(_currency, display.code), style: text.bodyMedium?.copyWith(color: k.muted)),
        ),
      ]),
    );
  }

  Widget _categoryPills(List<Category> cats) {
    final k = context.kara;
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = cats[i];
          final sel = _categoryId == c.id;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _categoryId = sel ? null : c.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? k.accent.withValues(alpha: .14) : k.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? k.accent : k.hairline, width: sel ? 1.6 : 1),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(c.color), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(c.name, style: Theme.of(context).textTheme.titleSmall),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _keypad(Currency cur) {
    Widget key(String label, {IconData? icon, bool enabled = true, VoidCallback? onLongPress}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Material(
              color: enabled ? context.kara.card : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: enabled ? () => _key(label) : null,
                onLongPress: onLongPress,
                child: SizedBox(
                  height: 54,
                  child: Center(
                    child: !enabled
                        ? null
                        : icon != null
                            ? Icon(icon, size: 24)
                            : Text(label, style: const TextStyle(fontFamily: 'Urbanist', fontWeight: FontWeight.w700, fontSize: 24)),
                  ),
                ),
              ),
            ),
          ),
        );
    Widget row(List<Widget> keys) => Row(children: keys);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        row([key('1'), key('2'), key('3')]),
        row([key('4'), key('5'), key('6')]),
        row([key('7'), key('8'), key('9')]),
        row([
          key(',', enabled: cur.decimals > 0),
          key('0'),
          key('⌫', icon: Icons.backspace_outlined, onLongPress: () => setState(() => _amount.clear())),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final k = context.kara;
    final cats = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final templates = ref.watch(templatesProvider).valueOrNull ?? const <QuickTemplate>[];
    final canWrite = ref.watch(canWriteProvider);
    final shared = ref.watch(isSharedSpaceProvider);
    final cur = currencyOf(_currency);
    final display = ref.watch(currencyProvider);
    final rates = ref.watch(rateTableProvider);
    final minor = parseMinor(_amount.text, cur.decimals);
    final converted = minor == null || _currency == display.code ? null : rates.convert(minor, _currency, display.code);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Focus(
      autofocus: true,
      onKeyEvent: _hardwareKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.expense == null ? t.newExpense : t.edit),
          actions: [
            IconButton(tooltip: t.saveAsTemplate, icon: const Icon(Icons.bookmark_add_outlined), onPressed: _saveAsTemplate),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(children: [
              Expanded(
                child: ListView(padding: const EdgeInsets.only(bottom: 16), children: [
                  const ReadOnlyBanner(),
                  _amountDisplay(cur, display, converted),
                  const SizedBox(height: 8),
                  if (widget.expense == null && templates.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(spacing: 8, runSpacing: 4, children: [
                        for (final tpl in templates) ActionChip(avatar: const Icon(Icons.bolt, size: 16), label: Text(tpl.name), onPressed: () => _applyTemplate(tpl)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _categoryPills(cats),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          TextField(controller: _note, decoration: InputDecoration(labelText: t.note)),
                          const SizedBox(height: 10),
                          TextField(controller: _tags, decoration: InputDecoration(labelText: t.tags, hintText: t.tagsHint, prefixIcon: const Icon(Icons.sell_outlined))),
                          const SizedBox(height: 4),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.event_outlined, color: k.muted),
                            title: Text(context.dayLabelFull(_date.millisecondsSinceEpoch)),
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)));
                              if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
                            },
                          ),
                          const Divider(height: 24),
                          _receiptSection(),
                          if (shared) _sharingSection(),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
              // pavé numérique masqué quand le clavier système est ouvert (note, étiquettes…)
              if (!keyboardOpen) _keypad(cur),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(onPressed: canWrite ? _save : null, child: Text(t.save)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
