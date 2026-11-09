import 'package:flutter/material.dart';

import 'cores.dart';
import 'espacos.dart';

/// Tema a partir das [Cores]: superfícies planas, bordas finas e tipografia
/// com bastante respiro.
abstract final class TemaVisual {
  static ThemeData criar(Cores cores) {
    final base = ThemeData(brightness: cores.brilho, useMaterial3: true);
    final esquema = ColorScheme.fromSeed(seedColor: cores.destaque, brightness: cores.brilho).copyWith(
      primary: cores.destaque,
      onPrimary: cores.sobreDestaque,
      surface: cores.fundo,
      onSurface: cores.texto,
      onSurfaceVariant: cores.suave,
      secondaryContainer: cores.destaque.withValues(alpha: 0.14),
      onSecondaryContainer: cores.texto,
      outline: cores.linha,
      outlineVariant: cores.linha,
      error: cores.critico,
      surfaceTint: Colors.transparent,
    );
    final texto = base.textTheme.apply(bodyColor: cores.texto, displayColor: cores.texto);

    return base.copyWith(
      extensions: [cores],
      colorScheme: esquema,
      scaffoldBackgroundColor: cores.fundo,
      textTheme: texto.copyWith(
        headlineLarge: texto.headlineLarge?.copyWith(fontWeight: FontWeight.w300, letterSpacing: -0.5),
        headlineSmall: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w400),
        titleMedium: texto.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(color: cores.linha, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cores.cartao,
        indicatorColor: cores.destaque.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cores.cartao,
        selectedColor: cores.destaque.withValues(alpha: 0.14),
        side: BorderSide(color: cores.linha),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Espacos.raio)),
        showCheckmark: false,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
