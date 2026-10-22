import '../../dominio/entidades/obra.dart';
import '../../dominio/entidades/etapa_servico.dart';
import '../../dominio/entidades/item_material.dart';

/// Modelo de dados — converte entre Map (Supabase/PostgreSQL) e a entidade Obra.
class ObraModelo extends Obra {
  ObraModelo({
    super.id,
    required super.idCliente,
    required super.clienteNome,
    required super.tituloDaObra,
    required super.endereco,
    super.numero,
    super.complemento,
    super.cep,
    super.bairro,
    super.cidade,
    super.uf,
    required super.dataInicio,
    required super.dataPrevisaoTermino,
    super.dataConclusao,
    super.status,
    super.progresso,
    required super.etapasServico,
    super.listaMateriais,
    super.latitude,
    super.longitude,
    super.localizacaoExata,
    super.criadoEm,
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

    // Deserializa lista_materiais (JSONB → List<ItemMaterial>)
    final materiaisRaw = mapa['lista_materiais'];
    final materiais = materiaisRaw is List
        ? materiaisRaw
            .whereType<Map>()
            .map((m) => ItemMaterial.deMapa(Map<String, dynamic>.from(m)))
            .toList()
        : <ItemMaterial>[];

    return ObraModelo(
      id: mapa['id_obra'],
      idCliente: mapa['id_cliente'] ?? 0,
      clienteNome: mapa['cliente_nome'] ?? '',
      tituloDaObra: mapa['titulo_da_obra'] ?? '',
      endereco: mapa['endereco'] ?? '',
      numero: mapa['numero'] ?? '',
      complemento: mapa['complemento'] ?? '',
      cep: mapa['cep'] ?? '',
      bairro: mapa['bairro'] ?? '',
      cidade: mapa['cidade'] ?? '',
      uf: (mapa['uf'] ?? '').toString().trim(),
      dataInicio: DateTime.tryParse(mapa['data_inicio'] ?? '') ?? DateTime.now(),
      dataPrevisaoTermino: DateTime.tryParse(mapa['data_previsao_termino'] ?? '') ?? DateTime.now(),
      dataConclusao: mapa['data_conclusao'] != null
          ? DateTime.tryParse(mapa['data_conclusao'])
          : null,
      status: mapa['status'] ?? 'Não Iniciada',
      progresso: (mapa['progresso'] ?? 0).toDouble(),
      etapasServico: etapas,
      listaMateriais: materiais,
      latitude: (mapa['latitude'] as num?)?.toDouble(),
      longitude: (mapa['longitude'] as num?)?.toDouble(),
      localizacaoExata: mapa['localizacao_exata'] == true,
      criadoEm: DateTime.tryParse(mapa['created_at']?.toString() ?? '')?.toLocal(),
    );
  }

  /// Converte para Map compatível com insert/update do Supabase (snake_case).
  /// Não inclui id_obra (gerado automaticamente pelo banco).
  /// Não inclui created_at/updated_at (gerenciados pelo banco/trigger).
  Map<String, dynamic> paraMapa() {
    return {
      'id_cliente': idCliente,
      'titulo_da_obra': tituloDaObra,
      'cliente_nome': clienteNome,
      'endereco': endereco,
      'numero': numero.trim().isEmpty ? null : numero.trim(),
      'complemento': complemento.trim().isEmpty ? null : complemento.trim(),
      'cep': cep.replaceAll(RegExp(r'[^0-9]'), '').length == 8 ? cep.replaceAll(RegExp(r'[^0-9]'), '') : null,
      'bairro': bairro.trim().isEmpty ? null : bairro.trim(),
      'cidade': cidade.trim().isEmpty ? null : cidade.trim(),
      'uf': uf.trim().isEmpty ? null : uf.trim().toUpperCase(),
      'data_inicio': dataInicio.toIso8601String().split('T').first,           // DATE
      'data_previsao_termino': dataPrevisaoTermino.toIso8601String().split('T').first,
      'data_conclusao': dataConclusao?.toIso8601String().split('T').first,
      'status': status,
      'progresso': progresso,
      'etapas_servico': etapasServico.map((e) => e.paraMapa()).toList(),       // JSONB
      'lista_materiais': listaMateriais.map((m) => m.paraMapa()).toList(),    // JSONB
      'latitude': latitude,
      'localizacao_exata': localizacaoExata && latitude != null && longitude != null,
      'longitude': longitude,
    };
  }
}
