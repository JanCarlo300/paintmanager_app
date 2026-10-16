import '../entidades/cliente.dart';

/// Contrato do repositório de Clientes.
abstract class RepositorioCliente {
  Future<List<Cliente>> listarClientes();

  Future<Cliente?> buscarClientePorId(int id);

  /// Busca no banco por nome, CPF/CNPJ ou telefone (no máximo 20 resultados)
  Future<List<Cliente>> buscarClientes(String termo);
  Future<void> salvarCliente(Cliente cliente);
  Future<void> excluirCliente(int id);
  Future<void> atualizarStatus(int id, bool ativo);
}
