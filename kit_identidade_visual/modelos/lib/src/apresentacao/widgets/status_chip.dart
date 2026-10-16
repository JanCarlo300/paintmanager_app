import 'package:flutter/material.dart';

import '../../core/tema/cores_app.dart';
import '../../core/tema/medidas_app.dart';
import '../../core/tema/status_visual.dart';

/// Pílula de status (orçamento ou obra), sempre com ícone e texto.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  /// O status como vem do banco ("Pendente", "Em Andamento"...).
  final String status;

  @override
  Widget build(BuildContext context) {
    final visual = visualDoStatus(status, context.cores);
    final estilo = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: visual.cor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        );

    return Semantics(
      label: 'Status: ${visual.rotulo}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: visual.fundo,
          borderRadius: BorderRadius.circular(Raio.pilula),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(visual.icone, size: 16, color: visual.cor, fill: 1),
            const SizedBox(width: Espaco.x1),
            Text(visual.rotulo, style: estilo),
          ],
        ),
      ),
    );
  }
}
