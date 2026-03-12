class Transacao {
  final String? id;
  final String tipo; // Receita, Despesa
  final String categoria; // Mão de Obra, Materiais, Ferramentas, Transporte, Alimentação, Outros
  final double valor; // Sempre positivo no banco
  final String descricao;
  final DateTime dataTransacao;
  final String status; // Efetivado, Pendente, Atrasado
  final String formaPagamento; // PIX, Cartão de Crédito, Dinheiro, Boleto
  final String? obraId;
  final String? clienteId;
  final String? clienteNome;
  final String? obraTitulo;
  final String? comprovanteUrl;

  Transacao({
    this.id,
    required this.tipo,
    required this.categoria,
    required this.valor,
    required this.descricao,
    required this.dataTransacao,
    this.status = 'Efetivado',
    this.formaPagamento = 'PIX',
    this.obraId,
    this.clienteId,
    this.clienteNome,
    this.obraTitulo,
    this.comprovanteUrl,
  });
}
