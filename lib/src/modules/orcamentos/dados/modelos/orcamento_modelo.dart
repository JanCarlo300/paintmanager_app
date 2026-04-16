import '../../dominio/entidades/orcamento.dart';
import '../../dominio/entidades/item_servico.dart';

/// Modelo de dados — converte entre Map (Supabase/PostgreSQL) e a entidade Orcamento.
/// Nenhuma dependência do Firebase. Segue convenção snake_case do PostgreSQL.
class OrcamentoModelo extends Orcamento {
  OrcamentoModelo({
    super.id,
    super.idObra,
    required super.clienteNome,
    required super.descricao,
    required super.dataCriacao,
    required super.dataValidade,
    super.status,
    required super.itensServico,
    super.materiaisInclusos,
    super.valorMateriais,
    required super.valorMaoDeObra,
    super.desconto,
    super.valorTotal,
    super.formaPagamento,
  });

  /// Cria um OrcamentoModelo a partir do Map retornado pelo Supabase (snake_case)
  factory OrcamentoModelo.deMapa(Map<String, dynamic> mapa) {
    // Deserializa itens_servico (JSONB → List<ItemServico>)
    final itensRaw = mapa['itens_servico'];
    final itens = itensRaw is List
        ? itensRaw
            .map((e) => ItemServico.deMapa(Map<String, dynamic>.from(e)))
            .toList()
        : <ItemServico>[];

    return OrcamentoModelo(
      id: mapa['id_orcamento'],
      idObra: mapa['id_obra'],
      clienteNome: mapa['cliente_nome'] ?? '',
      descricao: mapa['descricao'] ?? '',
      dataCriacao: DateTime.tryParse(mapa['data_criacao'] ?? '') ?? DateTime.now(),
      dataValidade: DateTime.tryParse(mapa['data_validade'] ?? '') ?? DateTime.now(),
      status: mapa['status'] ?? 'Pendente',
      itensServico: itens,
      materiaisInclusos: mapa['material_incluso'] ?? false,
      valorMateriais: (mapa['valor_material'] ?? 0).toDouble(),
      valorMaoDeObra: (mapa['valor_mao_obra'] ?? 0).toDouble(),
      desconto: (mapa['valor_desconto'] ?? 0).toDouble(),
      valorTotal: (mapa['valor_total'] ?? 0).toDouble(),
      formaPagamento: mapa['forma_pagamento'] ?? 'PIX',
    );
  }

  /// Converte para Map compatível com insert/update do Supabase (snake_case).
  /// Não inclui id_orcamento (gerado automaticamente pelo banco).
  /// Não inclui created_at/updated_at (gerenciados pelo banco/trigger).
  Map<String, dynamic> paraMapa() {
    return {
      'id_obra': idObra,
      'cliente_nome': clienteNome,
      'descricao': descricao,
      'data_criacao': dataCriacao.toIso8601String().split('T').first,         // DATE
      'data_validade': dataValidade.toIso8601String().split('T').first,       // DATE
      'status': status,
      'itens_servico': itensServico.map((e) => e.paraMapa()).toList(),         // JSONB
      'material_incluso': materiaisInclusos,
      'valor_material': valorMateriais,
      'valor_mao_obra': valorMaoDeObra,
      'valor_desconto': desconto,
      'valor_total': valorTotal,
      'forma_pagamento': formaPagamento,
    };
  }
}
