import 'package:flutter/material.dart';

class Tema {
  const Tema._();

  static const _semilla = Color(0xFF2E7D6B);

  static ThemeData claro() => _construir(Brightness.light);

  static ThemeData oscuro() => _construir(Brightness.dark);

  static ThemeData _construir(Brightness brillo) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _semilla, brightness: brillo),
    visualDensity: VisualDensity.standard,
    cardTheme: const CardThemeData(margin: EdgeInsets.zero),
  );
}
