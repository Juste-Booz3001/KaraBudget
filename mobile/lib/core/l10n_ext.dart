import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get t => AppLocalizations.of(this);

  /// Locale utilisée par intl pour les dates (le malgache utilise les noms de mois français).
  String get dateLocale {
    final code = Localizations.localeOf(this).languageCode;
    return code == 'mg' ? 'fr' : code;
  }

  String dayLabel(int ms) => DateFormat('d MMM', dateLocale).format(DateTime.fromMillisecondsSinceEpoch(ms));
  String dayLabelFull(int ms) => DateFormat.yMMMd(dateLocale).format(DateTime.fromMillisecondsSinceEpoch(ms));
  String monthLabel(DateTime m) => DateFormat.yMMMM(dateLocale).format(m);
  String shortMonth(DateTime m) => DateFormat.MMM(dateLocale).format(m);
  String dateTimeLabel(int ms) => DateFormat.yMd(dateLocale).add_Hm().format(DateTime.fromMillisecondsSinceEpoch(ms));
}

/// Flutter ne fournit pas de textes Material pour le malgache (mg) : on utilise le français
/// pour les composants système (calendrier, boutons OK/Annuler du sélecteur de date…).
class _Fallback<T> extends LocalizationsDelegate<T> {
  const _Fallback(this._inner);
  final LocalizationsDelegate<T> _inner;

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'mg';

  @override
  Future<T> load(Locale locale) => _inner.load(const Locale('fr'));

  @override
  bool shouldReload(covariant LocalizationsDelegate<T> old) => false;
}

const List<LocalizationsDelegate<dynamic>> fallbackDelegates = [
  _Fallback<MaterialLocalizations>(GlobalMaterialLocalizations.delegate),
  _Fallback<WidgetsLocalizations>(GlobalWidgetsLocalizations.delegate),
  _Fallback<CupertinoLocalizations>(GlobalCupertinoLocalizations.delegate),
];
