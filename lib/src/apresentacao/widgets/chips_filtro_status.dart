import 'package:flutter/material.dart';

class OpcaoStatus<T> {
  const OpcaoStatus(this.rotulo, this.valor, this.quantidade, this.cor);
  final String rotulo;
  final T valor;
  final int quantidade;
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
            if (i > 0) const SizedBox(width: 8),
            _chip(o),
          ],
        ],
      ),
    );
  }

  Widget _chip(OpcaoStatus<T> o) {
    final ativo = o.valor == selecionado;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(o.rotulo, style: TextStyle(
            fontSize: 12,
            fontWeight: ativo ? FontWeight.bold : FontWeight.normal,
            color: ativo ? Colors.white : Colors.grey[700],
          )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ativo ? Colors.white.withValues(alpha: 0.3) : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              o.quantidade.toString(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: ativo ? Colors.white : Colors.grey[700]),
            ),
          ),
        ],
      ),
      selected: ativo,
      selectedColor: o.cor,
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
      showCheckmark: false,
      onSelected: (_) => aoSelecionar(o.valor),
    );
  }
}
