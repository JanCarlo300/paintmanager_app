/// Etapa de serviço de uma Obra.
/// Cada Obra possui uma lista de etapas armazenadas como JSONB no PostgreSQL.
class EtapaServico {
  final String nome;
  final bool concluida;

  EtapaServico({
    required this.nome,
    this.concluida = false,
  });

  /// Cria uma cópia com campos opcionais substituídos
  EtapaServico copiarCom({bool? concluida}) {
    return EtapaServico(
      nome: nome,
      concluida: concluida ?? this.concluida,
    );
  }

  /// Converte para Map (para serializar no JSONB)
  Map<String, dynamic> paraMapa() {
    return {
      'nome': nome,
      'concluida': concluida,
    };
  }

  /// Cria a partir de um Map (JSONB do PostgreSQL)
  factory EtapaServico.deMapa(Map<String, dynamic> mapa) {
    return EtapaServico(
      nome: mapa['nome'] ?? '',
      concluida: mapa['concluida'] ?? false,
    );
  }
}
