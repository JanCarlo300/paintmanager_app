import 'package:flutter/material.dart';

import '../../core/tema/cores_app.dart';
import '../../core/tema/medidas_app.dart';

/// Card escuro para o valor principal da tela (ex.: lucro do mês).
/// No máximo um por tela.
class CardDestaque extends StatelessWidget {
  const CardDestaque({
    super.key,
    required this.rotulo,
    required this.valor,
    this.legenda,
  });

  final String rotulo;
  final String valor;
  final String? legenda;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Espaco.x5),
      decoration: BoxDecoration(
        color: c.inverseSurface,
        borderRadius: BorderRadius.circular(Raio.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo.toUpperCase(), style: texto.labelSmall?.copyWith(color: c.inverseInkMuted)),
          const SizedBox(height: Espaco.x1),
          Text(valor, style: texto.displayMedium?.copyWith(color: c.accent)),
          if (legenda != null) ...[
            const SizedBox(height: Espaco.x1),
            Text(legenda!, style: texto.bodyMedium?.copyWith(color: c.inverseInkMuted)),
          ],
        ],
      ),
    );
  }
}
