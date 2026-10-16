/// Medidas do PaintManager (manual da marca): espaços, cantos, ícones e toque.
library;

/// Espaçamentos, em múltiplos de 4.
abstract final class Espaco {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;

  /// Margem lateral das telas.
  static const double margemTela = x4;
}

/// Raios dos cantos.
abstract final class Raio {
  /// Campos de texto.
  static const double campo = 8;

  /// Botões.
  static const double botao = 12;

  /// Cards, diálogos e botão flutuante.
  static const double card = 16;

  /// Chips, contadores e círculos.
  static const double pilula = 999;
}

/// Tamanhos de ícone.
abstract final class TamanhoIcone {
  /// Junto de texto, em chips e botões.
  static const double pequeno = 20;

  /// Padrão: listas, barra superior, botão flutuante.
  static const double medio = 24;

  /// Resumo Geral e telas vazias.
  static const double grande = 32;
}

/// Altura dos botões e área mínima de toque de qualquer controle.
const double alturaToque = 48;
