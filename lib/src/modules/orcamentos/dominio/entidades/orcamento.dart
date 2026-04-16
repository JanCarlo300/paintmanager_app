import 'item_servico.dart';

/// Entidade de domínio — Orçamento (Supabase).
/// Sem dependências de Firebase. Usa int? id para IDENTITY PK do PostgreSQL.
/// Mantém FK relacional para Obra via idObra (int?).
class Orcamento {
  final int? id;
  final int? idObra;
  final String clienteNome;       // cache desnormalizado para exibição rápida
  final String descricao;
  final DateTime dataCriacao;
  final DateTime dataValidade;
  final String status;            // Pendente | Aprovado | Rejeitado | Concluído
  final List<ItemServico> itensServico;
  final bool materiaisInclusos;
  final double valorMateriais;
  final double valorMaoDeObra;
  final double desconto;
  final double valorTotal;
  final String formaPagamento;

  Orcamento({
    this.id,
    this.idObra,
    required this.clienteNome,
    required this.descricao,
    required this.dataCriacao,
    required this.dataValidade,
    this.status = 'Pendente',
    required this.itensServico,
    this.materiaisInclusos = false,
    this.valorMateriais = 0.0,
    required this.valorMaoDeObra,
    this.desconto = 0.0,
    double? valorTotal,
    this.formaPagamento = 'PIX',
  }) : valorTotal = valorTotal ?? _calcularTotal(
         itensServico, materiaisInclusos, valorMateriais, valorMaoDeObra, desconto,
       );

  /// Calcula o valor total do orçamento automaticamente
  static double _calcularTotal(
    List<ItemServico> itens,
    bool materiaisInclusos,
    double valorMateriais,
    double valorMaoDeObra,
    double desconto,
  ) {
    final totalItens = itens.fold<double>(0, (soma, item) => soma + item.subtotal);
    final totalMateriais = materiaisInclusos ? valorMateriais : 0.0;
    return totalItens + totalMateriais + valorMaoDeObra - desconto;
  }

  /// Verifica se o orçamento está vencido
  bool get vencido => dataValidade.isBefore(DateTime.now());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Orcamento && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
