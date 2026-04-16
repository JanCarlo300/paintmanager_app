/// Item de Serviço de um Orçamento.
/// Cada Orçamento possui uma lista de itens armazenados como JSONB no PostgreSQL.
class ItemServico {
  final String descricao;
  final double metragem;       // em m²
  final double valorUnitario;  // R$ por m²
  final double subtotal;       // metragem * valorUnitario

  ItemServico({
    required this.descricao,
    required this.metragem,
    required this.valorUnitario,
    double? subtotal,
  }) : subtotal = subtotal ?? (metragem * valorUnitario);

  /// Converte para Map (para serializar no JSONB)
  Map<String, dynamic> paraMapa() {
    return {
      'descricao': descricao,
      'metragem': metragem,
      'valor_unitario': valorUnitario,
      'subtotal': subtotal,
    };
  }

  /// Cria a partir de um Map (JSONB do PostgreSQL)
  factory ItemServico.deMapa(Map<String, dynamic> mapa) {
    return ItemServico(
      descricao: mapa['descricao'] ?? '',
      metragem: (mapa['metragem'] ?? 0).toDouble(),
      valorUnitario: (mapa['valor_unitario'] ?? 0).toDouble(),
      subtotal: (mapa['subtotal'] ?? 0).toDouble(),
    );
  }
}
