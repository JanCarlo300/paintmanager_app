import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Escala tipográfica do PaintManager (manual da marca).
///
/// EB Garamond nos títulos (nunca abaixo de 20 px) e Manrope no resto.
/// Os estilos não definidos no manual herdam Manrope do tema base.
TextTheme textThemeApp(Brightness brilho, Color ink) {
  final base = GoogleFonts.manropeTextTheme(
    (brilho == Brightness.dark ? ThemeData.dark() : ThemeData.light()).textTheme,
  ).apply(bodyColor: ink, displayColor: ink);

  TextStyle garamond(double tamanho, double altura, FontWeight peso) =>
      GoogleFonts.ebGaramond(
        fontSize: tamanho,
        height: altura / tamanho,
        fontWeight: peso,
        color: ink,
      );

  TextStyle manrope(double tamanho, double altura, FontWeight peso, {double? espaco}) =>
      GoogleFonts.manrope(
        fontSize: tamanho,
        height: altura / tamanho,
        fontWeight: peso,
        color: ink,
        letterSpacing: espaco,
      );

  return base.copyWith(
    // Títulos (EB Garamond)
    displaySmall: garamond(40, 44, FontWeight.w700), // Login e boas-vindas
    headlineMedium: garamond(28, 34, FontWeight.w700), // Título de tela
    titleLarge: garamond(22, 28, FontWeight.w600), // Seções, nome da obra, AppBar

    // Interface (Manrope)
    displayMedium: manrope(32, 36, FontWeight.w800), // Valores em R$ do Resumo Geral
    titleMedium: manrope(18, 24, FontWeight.w700), // Título de card e diálogo
    bodyLarge: manrope(16, 24, FontWeight.w500), // Campos e textos principais
    bodyMedium: manrope(14, 20, FontWeight.w400), // Descrições e listas
    labelLarge: manrope(15, 20, FontWeight.w700), // Botões e abas
    bodySmall: manrope(12, 16, FontWeight.w600, espaco: 0.96), // Legendas e datas
    labelSmall: manrope(12, 16, FontWeight.w600, espaco: 0.96), // Chips e rótulos
  );
}
