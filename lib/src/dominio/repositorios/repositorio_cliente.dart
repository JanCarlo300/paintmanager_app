import '../entidades/cliente.dart';

abstract class RepositorioCliente {
  Stream<List<Cliente>> listarClientes();
  Future<void> salvarCliente(Cliente cliente);
  Future<void> excluirCliente(String id);
  Future<void> atualizarStatus(String id, bool ativo);
}