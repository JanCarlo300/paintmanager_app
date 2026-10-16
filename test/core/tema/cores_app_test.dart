import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/core/tema/cores_app.dart';

/// Contraste WCAG 2.1 entre duas cores (de 1:1 a 21:1).
double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final maior = la > lb ? la : lb;
  final menor = la > lb ? lb : la;
  return (maior + 0.05) / (menor + 0.05);
}

void main() {
  // Texto pequeno precisa de pelo menos 4,5:1 (WCAG AA).
  const minimo = 4.5;

  final temas = {'claro': CoresApp.claro, 'escuro': CoresApp.escuro};

  for (final MapEntry(key: nome, value: c) in temas.entries) {
    group('Contraste no tema $nome', () {
      final pares = <String, (Color, Color)>{
        'texto principal sobre o fundo da tela': (c.ink, c.surface),
        'texto principal sobre card': (c.ink, c.surfaceCard),
        'texto principal sobre diálogo': (c.ink, c.surfaceRaised),
        'texto principal sobre campo': (c.ink, c.surfaceSunken),
        'texto secundário sobre o fundo da tela': (c.inkMuted, c.surface),
        'texto secundário sobre card': (c.inkMuted, c.surfaceCard),
        'texto secundário sobre diálogo': (c.inkMuted, c.surfaceRaised),
        'texto secundário sobre campo': (c.inkMuted, c.surfaceSunken),
        'texto do botão primário': (c.onPrimary, c.primary),
        'texto do botão primário pressionado': (c.onPrimary, c.primaryPressed),
        'link e botão secundário sobre card': (c.primary, c.surfaceCard),
        'item selecionado': (c.primary, c.primarySoft),
        'contador de não lidas': (c.onSecondary, c.secondary),
        'botão de exclusão': (c.onError, c.error),
        'card destaque: texto': (c.inverseInk, c.inverseSurface),
        'card destaque: legenda': (c.inverseInkMuted, c.inverseSurface),
        'card destaque: valor': (c.accent, c.inverseSurface),
        'chip Aprovado/Concluída': (c.success, c.successSoft),
        'chip Recusado': (c.error, c.errorSoft),
        'chip Pendente/Pausada': (c.warning, c.warningSoft),
        'chip Em andamento': (c.info, c.infoSoft),
        'receita sobre card': (c.success, c.surfaceCard),
        'despesa sobre card': (c.error, c.surfaceCard),
      };

      for (final MapEntry(key: descricao, value: (frente, fundo)) in pares.entries) {
        test(descricao, () {
          final valor = contraste(frente, fundo);
          expect(
            valor,
            greaterThanOrEqualTo(minimo),
            reason: '$descricao: ${valor.toStringAsFixed(2)}:1 (mínimo $minimo:1)',
          );
        });
      }
    });
  }

  test('claro e escuro têm 6 cores de categoria para os gráficos', () {
    expect(CoresApp.claro.graficoCategorias, hasLength(6));
    expect(CoresApp.escuro.graficoCategorias, hasLength(6));
  });
}
