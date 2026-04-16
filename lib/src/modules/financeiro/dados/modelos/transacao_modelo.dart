import '../../dominio/entidades/transacao.dart';

/// Modelo de dados — converte entre Map (Supabase/PostgreSQL) e a entidade Transacao.
/// Nenhuma dependência do Firebase. Segue convenção snake_case do PostgreSQL.
class TransacaoModelo extends Transacao {
  TransacaoModelo({
    super.id,
    required super.tipo,
    required super.categoria,
    required super.valor,
    required super.descricao,
    required super.dataTransacao,
    super.status,
    super.formaPagamento,
    super.idCliente,
    super.idOrcamento,
    super.clienteNome,
    super.obraTitulo,
    super.comprovanteUrl,
  });

  /// Cria um TransacaoModelo a partir do Map retornado pelo Supabase (snake_case)
  factory TransacaoModelo.deMapa(Map<String, dynamic> mapa) {
    return TransacaoModelo(
      id: mapa['id_transacao'],
      tipo: mapa['tipo'] ?? 'Despesa',
      categoria: mapa['categoria'] ?? 'Outros',
      valor: (mapa['valor'] ?? 0).toDouble(),
      descricao: mapa['descricao'] ?? '',
      dataTransacao: DateTime.tryParse(mapa['data_transacao'] ?? '') ?? DateTime.now(),
      status: mapa['status'] ?? 'Efetivado',
      formaPagamento: mapa['forma_pagamento'] ?? 'PIX',
      idCliente: mapa['id_cliente'],
      idOrcamento: mapa['id_orcamento'],
      clienteNome: mapa['cliente_nome'],
      obraTitulo: mapa['obra_titulo'],
      comprovanteUrl: mapa['comprovante_url'],
    );
  }

  /// Converte para Map compatível com insert/update do Supabase (snake_case).
  /// Não inclui id_transacao (gerado automaticamente pelo banco).
  /// Não inclui created_at/updated_at (gerenciados pelo banco/trigger).
  Map<String, dynamic> paraMapa() {
    return {
      'descricao': descricao,
      'tipo': tipo,
      'categoria': categoria,
      'valor': valor,
      'data_transacao': dataTransacao.toIso8601String().split('T').first,  // DATE
      'status': status,
      'forma_pagamento': formaPagamento,
      'id_cliente': idCliente,
      'id_orcamento': idOrcamento,
      'cliente_nome': clienteNome ?? '',
      'obra_titulo': obraTitulo ?? '',
      'comprovante_url': comprovanteUrl ?? '',
    };
  }
}
