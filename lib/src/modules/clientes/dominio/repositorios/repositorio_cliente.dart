import '../entidades/cliente.dart';

/// Contrato do repositório de Clientes.
/// Usa Future (Supabase) ao invés de Stream (Firebase).
abstract class RepositorioCliente {
  Future<List<Cliente>> listarClientes();
  Future<void> salvarCliente(Cliente cliente);
  Future<void> excluirCliente(int id);
  Future<void> atualizarStatus(int id, bool ativo);
}
