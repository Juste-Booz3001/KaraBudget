import 'dart:ui' show FontFeature;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Couleurs propres à KaraBudget, en plus du ColorScheme Material.
@immutable
class KaraColors extends ThemeExtension<KaraColors> {
  const KaraColors({
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.good,
    required this.warn,
    required this.bad,
    required this.card,
    required this.hairline,
    required this.muted,
    required this.accent,
    required this.onAccent,
  });

  final Color hero, onHero, onHeroMuted, good, warn, bad, card, hairline, muted, accent, onAccent;

  static const lime = Color(0xFFD4FF26);
  static const ink = Color(0xFF0C0C0D);

  static const light = KaraColors(
    hero: lime,
    onHero: ink,
    onHeroMuted: Color(0xA60C0C0D),
    good: Color(0xFF1F8A4C),
    warn: Color(0xFFB7791F),
    bad: Color(0xFFD64545),
    card: Color(0xFFFFFFFF),
    hairline: Color(0xFFE0E0DA),
    muted: Color(0xFF6B6B66),
    accent: lime,
    onAccent: ink,
  );

  static const dark = KaraColors(
    hero: lime,
    onHero: ink,
    onHeroMuted: Color(0xA60C0C0D),
    good: Color(0xFF4ADE80),
    warn: Color(0xFFFFB84D),
    bad: Color(0xFFFF6B6B),
    card: Color(0xFF1A1A1C),
    hairline: Color(0xFF2A2A2D),
    muted: Color(0xFF8E8E93),
    accent: lime,
    onAccent: ink,
  );

  @override
  KaraColors copyWith({Color? hero, Color? onHero, Color? onHeroMuted, Color? good, Color? warn, Color? bad, Color? card, Color? hairline, Color? muted, Color? accent, Color? onAccent}) =>
      KaraColors(
        hero: hero ?? this.hero,
        onHero: onHero ?? this.onHero,
        onHeroMuted: onHeroMuted ?? this.onHeroMuted,
        good: good ?? this.good,
        warn: warn ?? this.warn,
        bad: bad ?? this.bad,
        card: card ?? this.card,
        hairline: hairline ?? this.hairline,
        muted: muted ?? this.muted,
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
      );

  @override
  KaraColors lerp(ThemeExtension<KaraColors>? other, double t) {
    if (other is! KaraColors) return this;
    return KaraColors(
      hero: Color.lerp(hero, other.hero, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      onHeroMuted: Color.lerp(onHeroMuted, other.onHeroMuted, t)!,
      good: Color.lerp(good, other.good, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      bad: Color.lerp(bad, other.bad, t)!,
      card: Color.lerp(card, other.card, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

extension KaraThemeX on BuildContext {
  KaraColors get kara => Theme.of(this).extension<KaraColors>()!;
}

/// Police des montants : chiffres de même largeur pour aligner les colonnes.
const amountFeatures = [FontFeature.tabularFigures()];

ThemeData buildKaraTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final k = dark ? KaraColors.dark : KaraColors.light;
  final seeded = ColorScheme.fromSeed(seedColor: KaraColors.lime, brightness: b);
  final scheme = dark
      ? seeded.copyWith(
          primary: KaraColors.lime,
          onPrimary: KaraColors.ink,
          primaryContainer: KaraColors.lime,
          onPrimaryContainer: KaraColors.ink,
          secondary: const Color(0xFFFFB84D),
          surface: const Color(0xFF0C0C0D),
          onSurface: const Color(0xFFF5F5F2),
          surfaceContainerLowest: const Color(0xFF0C0C0D),
          surfaceContainerLow: k.card,
          surfaceContainer: k.card,
          surfaceContainerHigh: const Color(0xFF252528),
          outlineVariant: k.hairline,
          error: k.bad,
        )
      : seeded.copyWith(
          primary: const Color(0xFF1B1B1D),
          onPrimary: Colors.white,
          primaryContainer: KaraColors.lime,
          onPrimaryContainer: KaraColors.ink,
          secondary: const Color(0xFFB7791F),
          surface: const Color(0xFFF2F2EE),
          onSurface: const Color(0xFF111112),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Colors.white,
          surfaceContainer: Colors.white,
          surfaceContainerHigh: const Color(0xFFE9E9E4),
          outlineVariant: k.hairline,
          error: k.bad,
        );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Figtree', brightness: b);
  TextStyle? display(TextStyle? s, double size, FontWeight w, {double spacing = -0.4}) =>
      s?.copyWith(fontFamily: 'Urbanist', fontSize: size, fontWeight: w, letterSpacing: spacing, height: 1.1);
  final tt = base.textTheme;
  final textTheme = tt.copyWith(
    displayMedium: display(tt.displayMedium, 44, FontWeight.w700, spacing: -1.2),
    displaySmall: display(tt.displaySmall, 34, FontWeight.w700, spacing: -0.8),
    headlineMedium: display(tt.headlineMedium, 28, FontWeight.w700),
    headlineSmall: display(tt.headlineSmall, 24, FontWeight.w700),
    titleLarge: display(tt.titleLarge, 20, FontWeight.w700, spacing: -0.2),
    titleMedium: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    labelLarge: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
  );

  final radius = BorderRadius.circular(16);
  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [k],
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    }),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 68,
      titleSpacing: 20,
      titleTextStyle: textTheme.headlineMedium?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: k.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: k.hairline)),
    ),
    dividerTheme: DividerThemeData(color: k.hairline, thickness: 1, space: 1),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 2)),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: 'Figtree',
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? scheme.onSurface : k.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? scheme.onPrimaryContainer : k.muted,
          )),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: k.accent,
      foregroundColor: k.onAccent,
      elevation: 0,
      extendedTextStyle: const TextStyle(fontFamily: 'Figtree', fontWeight: FontWeight.w700, fontSize: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh.withValues(alpha: dark ? .6 : .55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: k.accent, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: k.bad)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: k.bad, width: 1.6)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: k.accent,
        foregroundColor: k.onAccent,
        disabledBackgroundColor: k.hairline,
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontFamily: 'Figtree', fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        side: BorderSide(color: k.hairline),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontFamily: 'Figtree', fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontFamily: 'Figtree', fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: k.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: k.card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: k.hairline),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(linearMinHeight: 8, linearTrackColor: scheme.surfaceContainerHigh),
  );
}
