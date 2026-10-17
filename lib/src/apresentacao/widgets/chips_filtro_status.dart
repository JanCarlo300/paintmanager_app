import 'package:flutter/material.dart';
import '../../core/tema/cores_app.dart';
import '../../core/tema/medidas_app.dart';

class OpcaoStatus<T> {
  const OpcaoStatus(this.rotulo, this.valor, this.quantidade, this.cor);
  final String rotulo;
  final T valor;
  final int quantidade;

  /// Cor do chip quando selecionado (use as cores do tema: `context.cores`).
  final Color cor;
}

/// Fileira rolável de chips de status com contagem (Obras e Orçamentos).
class ChipsFiltroStatus<T> extends StatelessWidget {
  const ChipsFiltroStatus({
    super.key,
    required this.opcoes,
    required this.selecionado,
    required this.aoSelecionar,
  });

  final List<OpcaoStatus<T>> opcoes;
  final T selecionado;
  final ValueChanged<T> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, o) in opcoes.indexed) ...[
            if (i > 0) const SizedBox(width: Espaco.x2),
            _chip(context, o),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, OpcaoStatus<T> o) {
    final c = context.cores;
    final ativo = o.valor == selecionado;
    final estilo = Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 0);
    final corTexto = ativo ? c.onPrimary : c.ink;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(o.rotulo, style: estilo?.copyWith(
            fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
            color: corTexto,
          )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ativo ? c.onPrimary.withValues(alpha: 0.25) : c.border,
              borderRadius: BorderRadius.circular(Raio.pilula),
            ),
            child: Text(
              o.quantidade.toString(),
              style: estilo?.copyWith(fontWeight: FontWeight.w700, color: corTexto),
            ),
          ),
        ],
      ),
      selected: ativo,
      selectedColor: o.cor,
      backgroundColor: c.surfaceSunken,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.campo)),
      side: BorderSide.none,
      showCheckmark: false,
      onSelected: (_) => aoSelecionar(o.valor),
    );
  }
}
