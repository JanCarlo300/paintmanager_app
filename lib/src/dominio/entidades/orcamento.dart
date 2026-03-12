import 'item_servico.dart';

class Orcamento {
  final String? id;
  final String clienteId;
  final String clienteNome;
  final String descricao;
  final DateTime dataCriacao;
  final DateTime dataValidade;
  final String status; // Pendente, Aprovado, Rejeitado, Concluído
  final List<ItemServico> itensServico;
  final bool materiaisInclusos;
  final double valorMateriais;
  final double valorMaoDeObra;
  final double desconto;
  final double valorTotal;
  final String formaPagamento;

  Orcamento({
    this.id,
    required this.clienteId,
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
}
