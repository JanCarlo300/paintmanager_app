import '../../dominio/entidades/mensagem_obra.dart';

class MensagemObraModelo extends MensagemObra {
  const MensagemObraModelo({
    super.id,
    required super.obraId,
    super.usuarioId,
    super.autorNome,
    super.autorFuncao,
    required super.texto,
    required super.criadoEm,
  });

  factory MensagemObraModelo.deMapa(Map<String, dynamic> mapa) {
    return MensagemObraModelo(
      id: mapa['id_mensagem'] as int?,
      obraId: mapa['obra_id'] as int,
      usuarioId: mapa['usuario_id'] as int?,
      autorNome: mapa['autor_nome'] ?? '',
      autorFuncao: mapa['autor_funcao'] ?? '',
      texto: mapa['texto'] ?? '',
      criadoEm: DateTime.tryParse(mapa['criado_em'] ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}
