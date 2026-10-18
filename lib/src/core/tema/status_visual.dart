import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'cores_app.dart';

/// Como um status aparece na tela: rótulo, ícone e cores.
@immutable
class VisualStatus {
  const VisualStatus({
    required this.rotulo,
    required this.icone,
    required this.cor,
    required this.fundo,
  });

  final String rotulo;
  final IconData icone;

  /// Cor do texto e do ícone.
  final Color cor;

  /// Cor de fundo do chip.
  final Color fundo;
}

/// Mapa único de status → visual. Substitui os mapeamentos repetidos nas telas.
///
/// Aceita a grafia do banco ("Em Andamento", "Não Iniciada") e variações
/// ("Em andamento", "Rejeitado" de dados antigos). Status desconhecido
/// aparece neutro, com o próprio texto.
VisualStatus visualDoStatus(String status, CoresApp c) {
  switch (normalizarStatus(status)) {
    // Orçamento
    case 'pendente':
      return VisualStatus(rotulo: 'Pendente', icone: Symbols.schedule_rounded, cor: c.warning, fundo: c.warningSoft);
    case 'aprovado':
      return VisualStatus(rotulo: 'Aprovado', icone: Symbols.check_circle_rounded, cor: c.success, fundo: c.successSoft);
    case 'recusado':
    case 'rejeitado':
      return VisualStatus(rotulo: 'Recusado', icone: Symbols.cancel_rounded, cor: c.error, fundo: c.errorSoft);

    // Obra
    case 'nao iniciada':
      return VisualStatus(rotulo: 'Não iniciada', icone: Symbols.radio_button_unchecked_rounded, cor: c.inkMuted, fundo: c.surfaceSunken);
    case 'em andamento':
      return VisualStatus(rotulo: 'Em andamento', icone: Symbols.autorenew_rounded, cor: c.info, fundo: c.infoSoft);
    case 'pausada':
      return VisualStatus(rotulo: 'Pausada', icone: Symbols.pause_circle_rounded, cor: c.warning, fundo: c.warningSoft);
    case 'concluida':
    case 'concluido':
      return VisualStatus(rotulo: 'Concluída', icone: Symbols.check_circle_rounded, cor: c.success, fundo: c.successSoft);

    default:
      return VisualStatus(rotulo: status.trim(), icone: Symbols.help_rounded, cor: c.inkMuted, fundo: c.surfaceSunken);
  }
}

/// Minúsculas, sem acentos e sem espaços extras: "Não Iniciada" → "nao iniciada".
String normalizarStatus(String status) {
  const acentos = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a',
    'é': 'e', 'ê': 'e',
    'í': 'i',
    'ó': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u',
    'ç': 'c',
  };
  final minusculo = status.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final letra in minusculo.split('')) {
    buffer.write(acentos[letra] ?? letra);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
}
