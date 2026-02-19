import '../entidades/cliente.dart';

abstract class RepositorioCliente {
  Future<void> cadastrarCliente(Cliente cliente);
  Future<void> editarCliente(Cliente cliente);
  Future<void> excluirCliente(String id);
  Stream<List<Cliente>> listarClientes();
}
