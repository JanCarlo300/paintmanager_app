import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/transacao.dart';

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
    super.obraId,
    super.clienteId,
    super.clienteNome,
    super.obraTitulo,
    super.comprovanteUrl,
  });

  factory TransacaoModelo.deMapa(Map<String, dynamic> mapa, String id) {
    return TransacaoModelo(
      id: id,
      tipo: mapa['tipo'] ?? 'Despesa',
      categoria: mapa['categoria'] ?? 'Outros',
      valor: (mapa['valor'] ?? 0).toDouble(),
      descricao: mapa['descricao'] ?? '',
      dataTransacao: (mapa['dataTransacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: mapa['status'] ?? 'Efetivado',
      formaPagamento: mapa['formaPagamento'] ?? 'PIX',
      obraId: mapa['obraId'],
      clienteId: mapa['clienteId'],
      clienteNome: mapa['clienteNome'],
      obraTitulo: mapa['obraTitulo'],
      comprovanteUrl: mapa['comprovanteUrl'],
    );
  }

  Map<String, dynamic> paraMapa() {
    return {
      'tipo': tipo,
      'categoria': categoria,
      'valor': valor,
      'descricao': descricao,
      'dataTransacao': Timestamp.fromDate(dataTransacao),
      'status': status,
      'formaPagamento': formaPagamento,
      'obraId': obraId,
      'clienteId': clienteId,
      'clienteNome': clienteNome,
      'obraTitulo': obraTitulo,
      'comprovanteUrl': comprovanteUrl,
    };
  }
}
