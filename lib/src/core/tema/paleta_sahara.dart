import 'package:flutter/material.dart';

/// PONTE TEMPORÁRIA da identidade visual (Fase 1).
///
/// Mantém as telas antigas compilando com os valores NOVOS do manual
/// (tema claro) enquanto elas migram para `context.cores` na Fase 4.
/// Este arquivo é apagado na Fase 5. Não use em código novo.
class PaletaSahara {
  PaletaSahara._();

  static const background = Color(0xFFFAF5EE); // surface
  static const primary = Color(0xFFA5521F); // primary (antes #C2652A)
  static const tertiary = Color(0xFF8C3C3C); // secondary
  static const border = Color(0xFFD8D0C8); // border
  static const cardSurface = Color(0xFFFFFFFF); // surfaceCard
  static const onSurface = Color(0xFF3A302A); // ink
  static const onSurfaceMuted = Color(0xFF6B5E55); // inkMuted (antes #9A8E85)
}
