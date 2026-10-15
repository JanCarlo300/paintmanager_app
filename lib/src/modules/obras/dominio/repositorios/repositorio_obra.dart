import '../entidades/obra.dart';
import '../entidades/mensagem_obra.dart';
import '../../../auth/dominio/entidades/usuario.dart';

/// Contrato do repositório de Obras.
abstract class RepositorioObra {
  Future<List<Obra>> listarObras({bool maisRecentes = true});
  Future<void> salvarObra(Obra obra);
  Future<void> excluirObra(int id);

  /// RF010 - Alocar Equipe à Obra
  Future<List<Usuario>> listarFuncionariosAlocados(int obraId);
  Future<void> alocarFuncionario(int obraId, int usuarioId);
  Future<void> desalocarFuncionario(int obraId, int usuarioId);

  /// Item 2.1 — ids das obras em que este usuário está alocado (visão do Funcionário)
  Future<List<int>> listarObraIdsAlocados(int usuarioId);

  /// Etapa 2 — buscas no banco (no máximo 20 resultados cada)
  Future<List<Obra>> buscarObras(String termo);
  Future<List<Usuario>> buscarFuncionariosDisponiveis(int obraId, String termo);

  /// Item 1.2 — a obra só sai de "Não Iniciada" com orçamento Aprovado
  Future<bool> obraTemOrcamentoAprovado(int obraId);

  /// Item 2.3 — chat da obra (tempo real)
  Stream<List<MensagemObra>> escutarMensagens(int obraId);
  Future<void> enviarMensagem({required int obraId, required int usuarioId, required String texto});
}
