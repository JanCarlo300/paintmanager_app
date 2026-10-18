import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/tema/cores_app.dart';
import '../../core/tema/medidas_app.dart';

/// Ilustrações disponíveis (assets/ilustracoes/claro e /escuro).
enum IlustracaoVazia { obras, orcamentos, busca, notificacoes }

/// Tela vazia: ilustração + título + uma frase + botão opcional.
/// Usar só quando não há conteúdo, nunca como enfeite.
class TelaVazia extends StatelessWidget {
  const TelaVazia({
    super.key,
    required this.ilustracao,
    required this.titulo,
    required this.texto,
    this.acao,
  });

  final IlustracaoVazia ilustracao;
  final String titulo;
  final String texto;

  /// Ex.: FilledButton.icon("Nova obra") ou OutlinedButton("Limpar filtros").
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final pasta = escuro ? 'escuro' : 'claro';
    final estilos = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Espaco.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/ilustracoes/$pasta/vazio_${ilustracao.name}.svg',
              width: 200,
              height: 160,
              excludeFromSemantics: true,
            ),
            const SizedBox(height: Espaco.x4),
            Text(titulo, style: estilos.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: Espaco.x2),
            Text(
              texto,
              style: estilos.bodyMedium?.copyWith(color: context.cores.inkMuted),
              textAlign: TextAlign.center,
            ),
            if (acao != null) ...[
              const SizedBox(height: Espaco.x5),
              acao!,
            ],
          ],
        ),
      ),
    );
  }
}
