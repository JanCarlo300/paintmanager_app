import '../../dominio/entidades/obra.dart';
import '../../dominio/entidades/etapa_servico.dart';

/// Modelo de dados — converte entre Map (Supabase/PostgreSQL) e a entidade Obra.
/// Nenhuma dependência do Firebase. Segue convenção snake_case do PostgreSQL.
class ObraModelo extends Obra {
  ObraModelo({
    super.id,
    super.idOrcamento,
    required super.idCliente,
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

  /// Cria um ObraModelo a partir do Map retornado pelo Supabase (snake_case)
  factory ObraModelo.deMapa(Map<String, dynamic> mapa) {
    // Deserializa etapas_servico (JSONB → List<EtapaServico>)
    final etapasRaw = mapa['etapas_servico'];
    final etapas = etapasRaw is List
        ? etapasRaw
            .map((e) => EtapaServico.deMapa(Map<String, dynamic>.from(e)))
            .toList()
        : <EtapaServico>[];

    // Deserializa materiais_faltantes (JSONB → List<String>)
    final materiaisRaw = mapa['materiais_faltantes'];
    final materiais = materiaisRaw is List
        ? materiaisRaw.map((m) => m.toString()).toList()
        : <String>[];

    return ObraModelo(
      id: mapa['id_obra'],
      idOrcamento: mapa['id_orcamento'],
      idCliente: mapa['id_cliente'] ?? 0,
      clienteNome: mapa['cliente_nome'] ?? '',
      tituloDaObra: mapa['titulo_da_obra'] ?? '',
      endereco: mapa['endereco'] ?? '',
      dataInicio: DateTime.tryParse(mapa['data_inicio'] ?? '') ?? DateTime.now(),
      dataPrevisaoTermino: DateTime.tryParse(mapa['data_previsao_termino'] ?? '') ?? DateTime.now(),
      dataConclusao: mapa['data_conclusao'] != null
          ? DateTime.tryParse(mapa['data_conclusao'])
          : null,
      status: mapa['status'] ?? 'Não Iniciada',
      progresso: (mapa['progresso'] ?? 0).toDouble(),
      etapasServico: etapas,
      anotacoes: mapa['anotacoes'] ?? '',
      materiaisFaltantes: materiais,
    );
  }

  /// Converte para Map compatível com insert/update do Supabase (snake_case).
  /// Não inclui id_obra (gerado automaticamente pelo banco).
  /// Não inclui created_at/updated_at (gerenciados pelo banco/trigger).
  Map<String, dynamic> paraMapa() {
    return {
      'id_cliente': idCliente,
      'id_orcamento': idOrcamento,
      'titulo_da_obra': tituloDaObra,
      'cliente_nome': clienteNome,
      'endereco': endereco,
      'data_inicio': dataInicio.toIso8601String().split('T').first,           // DATE
      'data_previsao_termino': dataPrevisaoTermino.toIso8601String().split('T').first,
      'data_conclusao': dataConclusao?.toIso8601String().split('T').first,
      'status': status,
      'progresso': progresso,
      'etapas_servico': etapasServico.map((e) => e.paraMapa()).toList(),       // JSONB
      'anotacoes': anotacoes,
      'materiais_faltantes': materiaisFaltantes,                               // JSONB
    };
  }
}
