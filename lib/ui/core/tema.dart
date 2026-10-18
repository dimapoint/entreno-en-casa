import 'package:flutter/material.dart';

class Tema {
  const Tema._();

  static const _acento = Color(0xFFC93F18);
  static const _radioTarjeta = 16.0;
  static const _radioControl = 12.0;

  static ThemeData claro() => _construir(Brightness.light);

  static ThemeData oscuro() => _construir(Brightness.dark);

  static ThemeData _construir(Brightness brillo) {
    final oscuro = brillo == Brightness.dark;
    final base = ColorScheme.fromSeed(
      seedColor: _acento,
      brightness: brillo,
    );
    // Superficies grises neutras: el acento no tiñe fondos ni tarjetas.
    final colores = base.copyWith(
      primary: _acento,
      onPrimary: Colors.white,
      surface: oscuro ? const Color(0xFF121214) : const Color(0xFFF7F7F8),
      onSurface: oscuro ? const Color(0xFFEDEDEF) : const Color(0xFF1B1B1D),
      onSurfaceVariant: oscuro
          ? const Color(0xFFA6A6AD)
          : const Color(0xFF5E5E66),
      surfaceContainerLowest: oscuro
          ? const Color(0xFF0D0D0F)
          : const Color(0xFFFFFFFF),
      surfaceContainerLow: oscuro
          ? const Color(0xFF1A1A1D)
          : const Color(0xFFFFFFFF),
      surfaceContainer: oscuro
          ? const Color(0xFF202024)
          : const Color(0xFFF0F0F2),
      surfaceContainerHigh: oscuro
          ? const Color(0xFF2A2A2F)
          : const Color(0xFFE8E8EB),
      outlineVariant: oscuro
          ? const Color(0xFF34343A)
          : const Color(0xFFE0E0E4),
      primaryContainer: oscuro
          ? const Color(0xFF5A2415)
          : const Color(0xFFFFDDD3),
      onPrimaryContainer: oscuro
          ? const Color(0xFFFFDDD3)
          : const Color(0xFF3F1307),
    );
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radioControl),
    );
    const tamanoMinimo = Size(64, 48);
    const textoBoton = TextStyle(fontWeight: FontWeight.w600);
    final textos = ThemeData(brightness: brillo).textTheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colores,
      scaffoldBackgroundColor: colores.surface,
      visualDensity: VisualDensity.standard,
      textTheme: textos.copyWith(
        headlineMedium: textos.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineSmall: textos.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: textos.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: textos.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: textos.bodyMedium?.copyWith(height: 1.4),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: colores.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radioTarjeta),
          side: BorderSide(color: colores.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: tamanoMinimo,
          shape: forma,
          textStyle: textoBoton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: tamanoMinimo,
          shape: forma,
          textStyle: textoBoton,
          side: BorderSide(color: colores.outlineVariant),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colores.surface,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textos.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colores.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colores.surfaceContainerLow,
        indicatorColor: colores.primaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colores.surfaceContainerLow,
        indicatorColor: colores.primaryContainer,
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        tilePadding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
