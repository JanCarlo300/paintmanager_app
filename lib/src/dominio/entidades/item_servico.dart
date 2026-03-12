class ItemServico {
  final String descricao;
  final double metragem; // em m²
  final double valorUnitario; // R$ por m²
  final double subtotal; // metragem * valorUnitario

  ItemServico({
    required this.descricao,
    required this.metragem,
    required this.valorUnitario,
    double? subtotal,
  }) : subtotal = subtotal ?? (metragem * valorUnitario);
}
