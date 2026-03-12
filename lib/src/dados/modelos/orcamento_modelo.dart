import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/orcamento.dart';
import '../../dominio/entidades/item_servico.dart';

class OrcamentoModelo extends Orcamento {
  OrcamentoModelo({
    super.id,
    required super.clienteId,
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

  /// Converte um documento do Firestore para OrcamentoModelo
  factory OrcamentoModelo.deMapa(Map<String, dynamic> mapa, String id) {
    // Converte a lista de itens de serviço
    final itensRaw = mapa['itensServico'] as List<dynamic>? ?? [];
    final itens = itensRaw.map((item) {
      final m = item as Map<String, dynamic>;
      return ItemServico(
        descricao: m['descricao'] ?? '',
        metragem: (m['metragem'] ?? 0).toDouble(),
        valorUnitario: (m['valorUnitario'] ?? 0).toDouble(),
        subtotal: (m['subtotal'] ?? 0).toDouble(),
      );
    }).toList();

    return OrcamentoModelo(
      id: id,
      clienteId: mapa['clienteId'] ?? '',
      clienteNome: mapa['clienteNome'] ?? '',
      descricao: mapa['descricao'] ?? '',
      dataCriacao: (mapa['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataValidade: (mapa['dataValidade'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: mapa['status'] ?? 'Pendente',
      itensServico: itens,
      materiaisInclusos: mapa['materiaisInclusos'] ?? false,
      valorMateriais: (mapa['valorMateriais'] ?? 0).toDouble(),
      valorMaoDeObra: (mapa['valorMaoDeObra'] ?? 0).toDouble(),
      desconto: (mapa['desconto'] ?? 0).toDouble(),
      valorTotal: (mapa['valorTotal'] ?? 0).toDouble(),
      formaPagamento: mapa['formaPagamento'] ?? 'PIX',
    );
  }

  /// Converte o OrcamentoModelo para um mapa para salvar no Firestore
  Map<String, dynamic> paraMapa() {
    return {
      'clienteId': clienteId,
      'clienteNome': clienteNome,
      'descricao': descricao,
      'dataCriacao': Timestamp.fromDate(dataCriacao),
      'dataValidade': Timestamp.fromDate(dataValidade),
      'status': status,
      'itensServico': itensServico.map((item) => {
        'descricao': item.descricao,
        'metragem': item.metragem,
        'valorUnitario': item.valorUnitario,
        'subtotal': item.subtotal,
      }).toList(),
      'materiaisInclusos': materiaisInclusos,
      'valorMateriais': valorMateriais,
      'valorMaoDeObra': valorMaoDeObra,
      'desconto': desconto,
      'valorTotal': valorTotal,
      'formaPagamento': formaPagamento,
    };
  }
}
