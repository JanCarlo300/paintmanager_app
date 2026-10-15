/// Etapa 6 — item da Lista de Materiais da obra.
/// Ex.: "Tinta acrílica fosca" — 3 — "lata 18 L".
class ItemMaterial {
  final String descricao;
  final double? quantidade; // opcional; aceita fração (ex.: 2,5 kg)
  final String unidade;

  const ItemMaterial({
    required this.descricao,
    this.quantidade,
    this.unidade = '',
  });

  /// "3", "2,5" ou "" (sem quantidade) — formato brasileiro.
  String get quantidadeFormatada {
    final q = quantidade;
    if (q == null) return '';
    if (q == q.roundToDouble()) return q.toInt().toString();
    return q.toString().replaceAll('.', ',');
  }

  /// "3 lata 18 L", "lata 18 L" ou "" — pronto para listas e PDF.
  String get quantidadeComUnidade =>
      [quantidadeFormatada, unidade.trim()].where((p) => p.isNotEmpty).join(' ');

  Map<String, dynamic> paraMapa() => {
        'descricao': descricao,
        'quantidade': quantidade,
        'unidade': unidade,
      };

  factory ItemMaterial.deMapa(Map<String, dynamic> mapa) {
    final q = mapa['quantidade'];
    return ItemMaterial(
      descricao: mapa['descricao']?.toString() ?? '',
      quantidade: q is num ? q.toDouble() : double.tryParse(q?.toString().replaceAll(',', '.') ?? ''),
      unidade: mapa['unidade']?.toString() ?? '',
    );
  }
}
