import '../entidades/obra.dart';
import '../../../auth/dominio/entidades/usuario.dart';

/// Contrato do repositório de Obras.
abstract class RepositorioObra {
  Future<List<Obra>> listarObras();
  Future<void> salvarObra(Obra obra);
  Future<void> excluirObra(int id);

  /// RF010 - Alocar Equipe à Obra
  Future<List<Usuario>> listarFuncionariosAlocados(int obraId);
  Future<void> alocarFuncionario(int obraId, int usuarioId);
  Future<void> desalocarFuncionario(int obraId, int usuarioId);
}
