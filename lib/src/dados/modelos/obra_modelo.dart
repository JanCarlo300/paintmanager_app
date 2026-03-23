import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/obra.dart';
import '../../dominio/entidades/etapa_servico.dart';

class ObraModelo extends Obra {
  ObraModelo({
    super.id,
    super.orcamentoId,
    required super.clienteId,
    required super.clienteNome,
    required super.tituloDaObra,
    required super.endereco,
    required super.dataInicio,
    required super.dataPrevisaoTermino,
    super.dataConclusao,
    super.status,
    super.progresso,
    required super.etapasServico,
    super.anotacoes,
    super.materiaisFaltantes,
  });

  /// Converte um documento do Firestore para ObraModelo
  factory ObraModelo.deMapa(Map<String, dynamic> mapa, String id) {
    final etapasRaw = mapa['etapasServico'] is List ? mapa['etapasServico'] as List<dynamic> : <dynamic>[];
    final etapas = etapasRaw.map((e) {
      final m = e as Map<String, dynamic>;
      return EtapaServico(
        nome: m['nome'] ?? '',
        concluida: m['concluida'] ?? false,
      );
    }).toList();

    final materiaisRaw = mapa['materiaisFaltantes'] is List ? mapa['materiaisFaltantes'] as List<dynamic> : <dynamic>[];
    final materiais = materiaisRaw.map((m) => m.toString()).toList();

    return ObraModelo(
      id: id,
      orcamentoId: mapa['orcamentoId'],
      clienteId: mapa['clienteId'] ?? '',
      clienteNome: mapa['clienteNome'] ?? '',
      tituloDaObra: mapa['tituloDaObra'] ?? '',
      endereco: mapa['endereco'] ?? '',
      dataInicio: (mapa['dataInicio'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataPrevisaoTermino: (mapa['dataPrevisaoTermino'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataConclusao: (mapa['dataConclusao'] as Timestamp?)?.toDate(),
      status: mapa['status'] ?? 'Não Iniciada',
      progresso: (mapa['progresso'] ?? 0).toDouble(),
      etapasServico: etapas,
      anotacoes: mapa['anotacoes'] ?? '',
      materiaisFaltantes: materiais,
    );
  }

  /// Converte o ObraModelo para um mapa para salvar no Firestore
  Map<String, dynamic> paraMapa() {
    return {
      'orcamentoId': orcamentoId,
      'clienteId': clienteId,
      'clienteNome': clienteNome,
      'tituloDaObra': tituloDaObra,
      'endereco': endereco,
      'dataInicio': Timestamp.fromDate(dataInicio),
      'dataPrevisaoTermino': Timestamp.fromDate(dataPrevisaoTermino),
      'dataConclusao': dataConclusao != null ? Timestamp.fromDate(dataConclusao!) : null,
      'status': status,
      'progresso': progresso,
      'etapasServico': etapasServico.map((e) => {
        'nome': e.nome,
        'concluida': e.concluida,
      }).toList(),
      'anotacoes': anotacoes,
      'materiaisFaltantes': materiaisFaltantes,
    };
  }
}
