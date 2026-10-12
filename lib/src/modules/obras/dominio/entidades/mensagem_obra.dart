/// Entidade de domínio — mensagem do chat da obra (item 2.3).
class MensagemObra {
  final int? id;
  final int obraId;
  final int? usuarioId; // null = observação importada do antigo campo "Anotações"
  final String autorNome;
  final String autorFuncao;
  final String texto;
  final DateTime criadoEm;

  const MensagemObra({
    this.id,
    required this.obraId,
    this.usuarioId,
    this.autorNome = '',
    this.autorFuncao = '',
    required this.texto,
    required this.criadoEm,
  });

  bool get importada => usuarioId == null;
}
