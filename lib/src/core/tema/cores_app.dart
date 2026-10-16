import 'package:flutter/material.dart';

/// Cores do PaintManager (manual da marca aprovado em 15/10/2026).
///
/// Único lugar do app com valores hexadecimais de cor. As telas leem as
/// cores por `context.cores` (ver [CoresContext]) ou por `Theme.of(context)`.
@immutable
class CoresApp extends ThemeExtension<CoresApp> {
  const CoresApp({
    required this.brand,
    required this.primary,
    required this.primaryPressed,
    required this.onPrimary,
    required this.primarySoft,
    required this.accent,
    required this.secondary,
    required this.onSecondary,
    required this.surface,
    required this.surfaceCard,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.border,
    required this.ink,
    required this.inkMuted,
    required this.decor,
    required this.disabledBg,
    required this.disabledInk,
    required this.inverseSurface,
    required this.inverseInk,
    required this.inverseInkMuted,
    required this.success,
    required this.successSoft,
    required this.error,
    required this.errorSoft,
    required this.onError,
    required this.warning,
    required this.warningSoft,
    required this.info,
    required this.infoSoft,
    required this.graficoCategorias,
  });

  /// Terracota 600, a cor da marca: ícone, barra de progresso, gráficos. Não usar com texto branco pequeno.
  final Color brand;

  /// Ação principal: botão primário, FAB, links, item ativo.
  final Color primary;

  /// Botão primário pressionado.
  final Color primaryPressed;

  /// Texto e ícone sobre primary.
  final Color onPrimary;

  /// Selecionado, chip ativo, card pressionado, círculo de ícone de módulo.
  final Color primarySoft;

  /// Pêssego: valor no card destaque, foco. Nunca texto sobre fundo claro.
  final Color accent;

  /// Vinho: contador de mensagens não lidas.
  final Color secondary;

  /// Texto sobre secondary.
  final Color onSecondary;

  /// Fundo das telas.
  final Color surface;

  /// Cards e formulários.
  final Color surfaceCard;

  /// Diálogos, menus e bottom sheets.
  final Color surfaceRaised;

  /// Fundo de campo, trilho de progresso, divisórias leves.
  final Color surfaceSunken;

  /// Bordas de cards, campos e botões secundários.
  final Color border;

  /// Texto principal.
  final Color ink;

  /// Texto secundário (substitui #9A8E85).
  final Color inkMuted;

  /// Só decorativo. Nunca texto.
  final Color decor;

  /// Fundo de botão desativado.
  final Color disabledBg;

  /// Texto e ícone desativados.
  final Color disabledInk;

  /// Card destaque (no máximo um por tela).
  final Color inverseSurface;

  /// Texto sobre inverseSurface.
  final Color inverseInk;

  /// Legenda sobre inverseSurface.
  final Color inverseInkMuted;

  /// Aprovado, Concluída, receita.
  final Color success;

  /// Fundo de chip e ícone de sucesso.
  final Color successSoft;

  /// Recusado, Atrasado, despesa, excluir.
  final Color error;

  /// Fundo de chip e ícone de erro.
  final Color errorSoft;

  /// Texto sobre error (botão "Sim, excluir").
  final Color onError;

  /// Pendente, Pausada, vencendo.
  final Color warning;

  /// Fundo de chip de alerta.
  final Color warningSoft;

  /// Em andamento, avisos.
  final Color info;

  /// Fundo de chip de informação.
  final Color infoSoft;

  /// Cores das categorias nos gráficos, na ordem: Mão de Obra, Materiais,
  /// Ferramentas, Transporte, Alimentação, Outros.
  /// PROPOSTA: confirmar com o Jan no Lote H antes de usar.
  final List<Color> graficoCategorias;

  static const claro = CoresApp(
    brand: Color(0xFFC2652A),
    primary: Color(0xFFA5521F),
    primaryPressed: Color(0xFF8F4619),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFF8E9DD),
    accent: Color(0xFFF2B27F),
    secondary: Color(0xFF8C3C3C),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFFFAF5EE),
    surfaceCard: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFEFE8DF),
    border: Color(0xFFD8D0C8),
    ink: Color(0xFF3A302A),
    inkMuted: Color(0xFF6B5E55),
    decor: Color(0xFF9A8E85),
    disabledBg: Color(0xFFEFE8DF),
    disabledInk: Color(0xFF9A8E85),
    inverseSurface: Color(0xFF3A302A),
    inverseInk: Color(0xFFFAF5EE),
    inverseInkMuted: Color(0xFFD8D0C8),
    success: Color(0xFF2A7349),
    successSoft: Color(0xFFE3F1E8),
    error: Color(0xFFB3261E),
    errorSoft: Color(0xFFF9E1DF),
    onError: Color(0xFFFFFFFF),
    warning: Color(0xFF8A6100),
    warningSoft: Color(0xFFFCF0D2),
    info: Color(0xFF2F6690),
    infoSoft: Color(0xFFE1ECF5),
    graficoCategorias: [Color(0xFFC2652A), Color(0xFF2F6690), Color(0xFF8C3C3C), Color(0xFF8A6100), Color(0xFF6B5E55), Color(0xFFD8D0C8)],
  );

  static const escuro = CoresApp(
    brand: Color(0xFFC2652A),
    primary: Color(0xFFE07B3F),
    primaryPressed: Color(0xFFEC9561),
    onPrimary: Color(0xFF1E1915),
    primarySoft: Color(0xFF3D2A1E),
    accent: Color(0xFFF2B27F),
    secondary: Color(0xFFB04A4A),
    onSecondary: Color(0xFFFFFFFF),
    surface: Color(0xFF1E1915),
    surfaceCard: Color(0xFF2A231E),
    surfaceRaised: Color(0xFF3A302A),
    surfaceSunken: Color(0xFF3A302A),
    border: Color(0xFF4A3D34),
    ink: Color(0xFFF3ECE4),
    inkMuted: Color(0xFFB8ABA0),
    decor: Color(0xFF6B5E55),
    disabledBg: Color(0xFF3A302A),
    disabledInk: Color(0xFF6B5E55),
    inverseSurface: Color(0xFF4A3D34),
    inverseInk: Color(0xFFF3ECE4),
    inverseInkMuted: Color(0xFFD8D0C8),
    success: Color(0xFF5FBF86),
    successSoft: Color(0xFF183324),
    error: Color(0xFFF2877E),
    errorSoft: Color(0xFF3D1C1A),
    onError: Color(0xFF1E1915),
    warning: Color(0xFFE3B341),
    warningSoft: Color(0xFF3A2E10),
    info: Color(0xFF7DB3DE),
    infoSoft: Color(0xFF172A3A),
    graficoCategorias: [Color(0xFFE07B3F), Color(0xFF7DB3DE), Color(0xFFD88A8A), Color(0xFFE3B341), Color(0xFFB8ABA0), Color(0xFF4A3D34)],
  );

  @override
  CoresApp copyWith({
    Color? brand,
    Color? primary,
    Color? primaryPressed,
    Color? onPrimary,
    Color? primarySoft,
    Color? accent,
    Color? secondary,
    Color? onSecondary,
    Color? surface,
    Color? surfaceCard,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? border,
    Color? ink,
    Color? inkMuted,
    Color? decor,
    Color? disabledBg,
    Color? disabledInk,
    Color? inverseSurface,
    Color? inverseInk,
    Color? inverseInkMuted,
    Color? success,
    Color? successSoft,
    Color? error,
    Color? errorSoft,
    Color? onError,
    Color? warning,
    Color? warningSoft,
    Color? info,
    Color? infoSoft,
    List<Color>? graficoCategorias,
  }) {
    return CoresApp(
      brand: brand ?? this.brand,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySoft: primarySoft ?? this.primarySoft,
      accent: accent ?? this.accent,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      surface: surface ?? this.surface,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      border: border ?? this.border,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      decor: decor ?? this.decor,
      disabledBg: disabledBg ?? this.disabledBg,
      disabledInk: disabledInk ?? this.disabledInk,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      inverseInk: inverseInk ?? this.inverseInk,
      inverseInkMuted: inverseInkMuted ?? this.inverseInkMuted,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      onError: onError ?? this.onError,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      graficoCategorias: graficoCategorias ?? this.graficoCategorias,
    );
  }

  @override
  CoresApp lerp(ThemeExtension<CoresApp>? other, double t) {
    if (other is! CoresApp) return this;
    return CoresApp(
      brand: Color.lerp(brand, other.brand, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      border: Color.lerp(border, other.border, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      decor: Color.lerp(decor, other.decor, t)!,
      disabledBg: Color.lerp(disabledBg, other.disabledBg, t)!,
      disabledInk: Color.lerp(disabledInk, other.disabledInk, t)!,
      inverseSurface: Color.lerp(inverseSurface, other.inverseSurface, t)!,
      inverseInk: Color.lerp(inverseInk, other.inverseInk, t)!,
      inverseInkMuted: Color.lerp(inverseInkMuted, other.inverseInkMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoSoft: Color.lerp(infoSoft, other.infoSoft, t)!,
      graficoCategorias: t < 0.5 ? graficoCategorias : other.graficoCategorias,
    );
  }
}

/// Atalho para ler as cores do tema atual: `context.cores.primary`.
extension CoresContext on BuildContext {
  CoresApp get cores => Theme.of(this).extension<CoresApp>() ?? CoresApp.claro;
}
