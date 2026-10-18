import 'package:flutter/material.dart';

import 'cores_app.dart';
import 'medidas_app.dart';
import 'tipografia_app.dart';

/// Tema claro do PaintManager.
ThemeData temaClaro() => _montarTema(CoresApp.claro, Brightness.light);

/// Tema escuro do PaintManager.
ThemeData temaEscuro() => _montarTema(CoresApp.escuro, Brightness.dark);

ThemeData _montarTema(CoresApp c, Brightness brilho) {
  final texto = textThemeApp(brilho, c.ink);

  final esquema = ColorScheme(
    brightness: brilho,
    primary: c.primary,
    onPrimary: c.onPrimary,
    primaryContainer: c.primarySoft,
    onPrimaryContainer: c.primary,
    secondary: c.secondary,
    onSecondary: c.onSecondary,
    secondaryContainer: c.primarySoft,
    onSecondaryContainer: c.ink,
    tertiary: c.secondary,
    onTertiary: c.onSecondary,
    error: c.error,
    onError: c.onError,
    errorContainer: c.errorSoft,
    onErrorContainer: c.error,
    surface: c.surfaceCard,
    onSurface: c.ink,
    onSurfaceVariant: c.inkMuted,
    surfaceContainerLowest: c.surfaceCard,
    surfaceContainerLow: c.surfaceCard,
    surfaceContainer: c.surfaceRaised,
    surfaceContainerHigh: c.surfaceRaised,
    surfaceContainerHighest: c.surfaceSunken,
    outline: c.border,
    outlineVariant: c.border,
    inverseSurface: c.inverseSurface,
    onInverseSurface: c.inverseInk,
    inversePrimary: c.accent,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  final formaBotao = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.botao));
  final formaCard = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.card));
  const tamanhoMinimo = Size(64, alturaToque);
  const paddingBotao = EdgeInsets.symmetric(horizontal: Espaco.x5);

  OutlineInputBorder bordaCampo(Color cor, [double largura = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(Raio.campo),
        borderSide: BorderSide(color: cor, width: largura),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brilho,
    colorScheme: esquema,
    scaffoldBackgroundColor: c.surface,
    canvasColor: c.surface,
    textTheme: texto,
    extensions: <ThemeExtension<dynamic>>[c],
    iconTheme: IconThemeData(color: c.ink, size: TamanhoIcone.medio),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),

    appBarTheme: AppBarTheme(
      backgroundColor: c.surfaceCard,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: texto.titleLarge,
      iconTheme: IconThemeData(color: c.ink),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: c.surfaceCard,
      surfaceTintColor: Colors.transparent,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.ink,
      textColor: c.ink,
      selectedColor: c.primary,
      selectedTileColor: c.primarySoft,
      shape: formaBotao,
    ),

    // Cards: sem sombra, só borda.
    cardTheme: CardThemeData(
      color: c.surfaceCard,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: formaCard.copyWith(side: BorderSide(color: c.border)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: formaCard,
      titleTextStyle: texto.titleMedium,
      contentTextStyle: texto.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Raio.card)),
      ),
    ),

    // Botões
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: c.onPrimary,
        disabledForegroundColor: c.disabledInk,
        minimumSize: tamanhoMinimo,
        padding: paddingBotao,
        shape: formaBotao,
        textStyle: texto.labelLarge,
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.disabled)) return c.disabledBg;
          if (estados.contains(WidgetState.pressed)) return c.primaryPressed;
          return c.primary;
        }),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      // Mesmo visual do primário, sem sombra (o app usa ElevatedButton em várias telas).
      style: ElevatedButton.styleFrom(
        foregroundColor: c.onPrimary,
        disabledForegroundColor: c.disabledInk,
        elevation: 0,
        minimumSize: tamanhoMinimo,
        padding: paddingBotao,
        shape: formaBotao,
        textStyle: texto.labelLarge,
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.disabled)) return c.disabledBg;
          if (estados.contains(WidgetState.pressed)) return c.primaryPressed;
          return c.primary;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.primary,
        disabledForegroundColor: c.disabledInk,
        side: BorderSide(color: c.border, width: 1.5),
        minimumSize: tamanhoMinimo,
        padding: paddingBotao,
        shape: formaBotao,
        textStyle: texto.labelLarge,
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((estados) {
          if (estados.contains(WidgetState.pressed)) return c.primarySoft;
          return c.surfaceCard;
        }),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.primary,
        disabledForegroundColor: c.disabledInk,
        minimumSize: const Size(alturaToque, alturaToque),
        padding: const EdgeInsets.symmetric(horizontal: Espaco.x3),
        shape: formaBotao,
        textStyle: texto.labelLarge,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: c.primary,
      foregroundColor: c.onPrimary,
      elevation: 4,
      focusElevation: 4,
      hoverElevation: 6,
      highlightElevation: 6,
      shape: formaCard,
      extendedTextStyle: texto.labelLarge,
    ),

    // Campos
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceSunken,
      contentPadding: const EdgeInsets.symmetric(horizontal: Espaco.x4, vertical: 14),
      hintStyle: texto.bodyLarge?.copyWith(color: c.inkMuted),
      labelStyle: texto.bodyLarge?.copyWith(color: c.inkMuted),
      floatingLabelStyle: texto.bodySmall?.copyWith(color: c.primary),
      prefixIconColor: c.inkMuted,
      suffixIconColor: c.inkMuted,
      border: bordaCampo(Colors.transparent),
      enabledBorder: bordaCampo(Colors.transparent),
      focusedBorder: bordaCampo(c.primary, 1.5),
      errorBorder: bordaCampo(c.error),
      focusedErrorBorder: bordaCampo(c.error, 1.5),
      errorStyle: texto.bodySmall?.copyWith(color: c.error, letterSpacing: 0),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceSunken,
      selectedColor: c.primarySoft,
      disabledColor: c.disabledBg,
      labelStyle: texto.bodySmall?.copyWith(color: c.ink, letterSpacing: 0),
      side: BorderSide(color: c.border),
      shape: const StadiumBorder(),
      checkmarkColor: c.primary,
    ),

    // Retorno ao usuário
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.inverseSurface,
      contentTextStyle: texto.bodyMedium?.copyWith(color: c.inverseInk),
      actionTextColor: c.accent,
      behavior: SnackBarBehavior.floating,
      shape: formaBotao,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.brand,
      linearTrackColor: c.surfaceSunken,
      circularTrackColor: Colors.transparent,
    ),

    // Calendário (vale para todo showDatePicker / showDateRangePicker)
    datePickerTheme: DatePickerThemeData(
      backgroundColor: c.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      headerBackgroundColor: c.primary,
      headerForegroundColor: c.onPrimary,
      rangePickerHeaderBackgroundColor: c.primary,
      rangePickerHeaderForegroundColor: c.onPrimary,
      rangeSelectionBackgroundColor: c.primarySoft,
      todayBorder: BorderSide(color: c.primary),
      dividerColor: c.border,
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: c.inkMuted),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: c.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}
