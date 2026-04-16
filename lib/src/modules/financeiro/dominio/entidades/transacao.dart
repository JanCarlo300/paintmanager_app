/// Entidade de domínio — Transação Financeira (Supabase).
/// Sem dependências de Firebase. Usa int? id para IDENTITY PK do PostgreSQL.
/// Mantém FKs relacionais para Cliente (int?) e Orcamento (int?).
class Transacao {
  final int? id;
  final String tipo;            // Receita | Despesa
  final String categoria;       // Mão de Obra | Materiais | Ferramentas | Transporte | Alimentação | Outros
  final double valor;           // Sempre positivo no banco
  final String descricao;
  final DateTime dataTransacao;
  final String status;          // Efetivado | Pendente | Atrasado
  final String formaPagamento;  // PIX | Cartão de Crédito | Dinheiro | Boleto
  final int? idCliente;
  final int? idOrcamento;
  final String? clienteNome;    // cache desnormalizado
  final String? obraTitulo;     // cache desnormalizado
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
    this.idCliente,
    this.idOrcamento,
    this.clienteNome,
    this.obraTitulo,
    this.comprovanteUrl,
  });

  /// Verifica se é uma receita
  bool get isReceita => tipo == 'Receita';

  /// Verifica se é uma despesa
  bool get isDespesa => tipo == 'Despesa';

  /// Verifica se está pendente
  bool get isPendente => status == 'Pendente';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transacao && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
