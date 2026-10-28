import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/db.dart';
import 'backup.dart';
import 'money.dart';

String _day(int ms) => DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(ms));

// protège contre l'injection de formules à l'ouverture dans Excel/Sheets
String _safe(String s) => s.isNotEmpty && '=+-@'.contains(s[0]) ? "'$s" : s;

String buildCsv(List<Expense> list, Map<String, Category> cats, Currency c) {
  final rows = <List<dynamic>>[
    ['date', 'categorie', 'note', 'montant', 'devise', 'etiquettes'],
    for (final e in list)
      [_day(e.spentAt), _safe(cats[e.categoryId]?.name ?? ''), _safe(e.note), plainMinor(e.amountMinor, currencyOf(e.currency)), e.currency, _safe(e.tags.replaceAll(',', ' '))],
  ];
  return const ListToCsvConverter().convert(rows);
}

Future<Uint8List> buildPdf(List<Expense> list, Map<String, Category> cats, Currency c, String title) async {
  final total = list.fold<int>(0, (a, e) => a + e.amountMinor);
  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    build: (_) => [
      pw.Header(level: 0, child: pw.Text('KaraBudget - $title')),
      pw.TableHelper.fromTextArray(
        headers: ['Date', 'Categorie', 'Note', 'Montant (${c.code})'],
        data: [
          for (final e in list)
            [_day(e.spentAt), cats[e.categoryId]?.name ?? '', e.note, formatMinor(e.amountMinor, currencyOf(e.currency), symbol: false)],
        ],
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.Text('Total : ${formatMinor(total, c, symbol: false)} ${c.code}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ),
    ],
  ));
  return doc.save();
}

Future<void> shareBytes(Uint8List bytes, String name, String mime) => deliverBytes(bytes, name, mime);
