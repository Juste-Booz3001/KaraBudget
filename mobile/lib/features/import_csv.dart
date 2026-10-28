import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/csv_import.dart';
import '../core/l10n_ext.dart';
import '../core/money.dart';
import '../providers.dart';
import 'common.dart';

class ImportCsvScreen extends ConsumerStatefulWidget {
  const ImportCsvScreen({super.key});
  @override
  ConsumerState<ImportCsvScreen> createState() => _ImportState();
}

class _ImportState extends ConsumerState<ImportCsvScreen> {
  List<List<String>> _rows = const [];
  ColumnMap _cols = const ColumnMap();
  bool _hasHeader = true, _dayFirst = true, _busy = false;
  ImportSign _sign = ImportSign.auto;
  late String _currency;
  Map<String, int> _existing = const {};

  @override
  void initState() {
    super.initState();
    _currency = ref.read(settingsProvider).currency;
  }

  Future<void> _load(String text) async {
    final rows = parseCsv(text);
    final existing = await ref.read(repoProvider).existingExpenseCounts(ref.read(spaceIdProvider));
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _existing = existing;
      _cols = rows.isEmpty ? const ColumnMap() : guessColumns(rows.first);
    });
    if (rows.isEmpty) snack(context, context.t.csvEmpty);
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'txt'], withData: true);
    final bytes = res?.files.single.bytes;
    if (bytes == null) return;
    String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      text = latin1.decode(bytes); // relevés bancaires souvent en ISO-8859-1
    }
    await _load(text);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      if (mounted) snack(context, context.t.csvEmpty);
      return;
    }
    await _load(text);
  }

  List<ImportRow> get _preview => _rows.isEmpty || !_cols.usable
      ? const []
      : buildImport(
          _rows,
          ImportOptions(columns: _cols, decimals: currencyOf(_currency).decimals, hasHeader: _hasHeader, sign: _sign, dayFirst: _dayFirst),
          _existing);

  Future<void> _import(List<ImportRow> rows) async {
    setState(() => _busy = true);
    try {
      final n = await ref.read(repoProvider).importRows(ref.read(spaceIdProvider), rows,
          defaultCurrency: _currency, categoryColor: palette[rows.length % palette.length]);
      if (!mounted) return;
      snack(context, context.t.importDone(n));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        snack(context, e.toString());
      }
    }
  }

  Widget _colPicker(String label, int? value, ValueChanged<int?> onChanged, {bool optional = true}) {
    final header = _rows.isEmpty ? const <String>[] : _rows.first;
    return DropdownButtonFormField<int?>(
      key: ValueKey('$label-$value-${_rows.length}'),
      initialValue: value != null && value < header.length ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, isDense: true),
      items: [
        if (optional) DropdownMenuItem<int?>(value: null, child: Text(context.t.none)),
        for (var i = 0; i < header.length; i++)
          DropdownMenuItem<int?>(value: i, child: Text(_hasHeader && header[i].isNotEmpty ? header[i] : '#${i + 1}', overflow: TextOverflow.ellipsis)),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final canWrite = ref.watch(canWriteProvider);
    final preview = _preview;
    int count(ImportStatus s) => preview.where((r) => r.status == s).length;
    final ok = count(ImportStatus.ok);
    final cur = currencyOf(_currency);

    String reason(ImportRow r) => switch (r.reason) {
          'date' => t.importBadDate,
          'amount' => t.importBadAmount,
          'income' => t.importIncomeSkipped,
          'zero' => t.importZeroSkipped,
          _ => '',
        };

    return Scaffold(
      appBar: AppBar(title: Text(t.importCsv)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(t.importIntro),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          FilledButton.icon(onPressed: _pickFile, icon: const Icon(Icons.upload_file), label: Text(t.chooseFile)),
          OutlinedButton.icon(onPressed: _paste, icon: const Icon(Icons.content_paste), label: Text(t.pasteFromClipboard)),
        ]),
        if (_rows.isNotEmpty) ...[
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.firstLineIsHeader),
            value: _hasHeader,
            onChanged: (v) => setState(() {
              _hasHeader = v;
              if (v) _cols = guessColumns(_rows.first);
            }),
          ),
          Row(children: [
            Expanded(child: _colPicker(t.colDate, _cols.date, (v) => setState(() => _cols = _cols.copyWith(date: v)), optional: false)),
            const SizedBox(width: 12),
            Expanded(child: _colPicker(t.colAmount, _cols.amount, (v) => setState(() => _cols = v == null ? _cols.copyWith(clearAmount: true) : _cols.copyWith(amount: v)))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _colPicker(t.colDebit, _cols.debit, (v) => setState(() => _cols = v == null ? _cols.copyWith(clearDebit: true) : _cols.copyWith(debit: v)))),
            const SizedBox(width: 12),
            Expanded(child: _colPicker(t.colNote, _cols.note, (v) => setState(() => _cols = v == null ? _cols.copyWith(clearNote: true) : _cols.copyWith(note: v)))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _colPicker(t.colCategory, _cols.category, (v) => setState(() => _cols = v == null ? _cols.copyWith(clearCategory: true) : _cols.copyWith(category: v)))),
            const SizedBox(width: 12),
            Expanded(child: CurrencyDropdown(value: _currency, label: t.currency, onChanged: (c) => setState(() => _currency = c))),
          ]),
          const SizedBox(height: 8),
          DropdownButtonFormField<ImportSign>(
            initialValue: _sign,
            decoration: InputDecoration(labelText: t.signMode, isDense: true),
            items: [
              DropdownMenuItem(value: ImportSign.auto, child: Text(t.signAuto)),
              DropdownMenuItem(value: ImportSign.negativeIsExpense, child: Text(t.signNegative)),
              DropdownMenuItem(value: ImportSign.positiveIsExpense, child: Text(t.signPositive)),
              DropdownMenuItem(value: ImportSign.absolute, child: Text(t.signAbsolute)),
            ],
            onChanged: (v) => setState(() => _sign = v ?? ImportSign.auto),
          ),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t.dayFirst), value: _dayFirst, onChanged: (v) => setState(() => _dayFirst = v)),
          const Divider(),
          if (!_cols.usable)
            Text(t.chooseColumns)
          else ...[
            Wrap(spacing: 8, children: [
              Chip(avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18), label: Text(t.importNew(ok))),
              Chip(avatar: const Icon(Icons.content_copy, size: 18), label: Text(t.importDuplicates(count(ImportStatus.duplicate)))),
              Chip(avatar: const Icon(Icons.remove_circle_outline, size: 18), label: Text(t.importSkipped(count(ImportStatus.skipped)))),
              Chip(avatar: const Icon(Icons.error_outline, color: Colors.red, size: 18), label: Text(t.importErrors(count(ImportStatus.error)))),
            ]),
            const SizedBox(height: 8),
            for (final r in preview.take(30))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(switch (r.status) {
                  ImportStatus.ok => Icons.check_circle_outline,
                  ImportStatus.duplicate => Icons.content_copy,
                  ImportStatus.skipped => Icons.remove_circle_outline,
                  ImportStatus.error => Icons.error_outline,
                }),
                title: Text(r.status == ImportStatus.error ? t.importLine(r.line) : (r.note.isEmpty ? '—' : r.note), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text([
                  if (r.date != null) context.dayLabelFull(r.date!.millisecondsSinceEpoch),
                  if (r.status == ImportStatus.duplicate) t.alreadyPresent,
                  if (reason(r).isNotEmpty) reason(r),
                ].join(' · ')),
                trailing: r.amountMinor > 0 ? Text(formatMinor(r.amountMinor, currencyOf(r.currency ?? _currency))) : null,
              ),
            if (preview.length > 30) Text(t.andMore(preview.length - 30)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: canWrite && ok > 0 && !_busy ? () => _import(preview) : null,
              icon: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download_done),
              label: Text(t.importN(ok)),
            ),
            if (cur.decimals == 0) Padding(padding: const EdgeInsets.only(top: 8), child: Text(t.zeroDecimalHint, style: Theme.of(context).textTheme.bodySmall)),
          ],
        ],
      ]),
    );
  }
}
