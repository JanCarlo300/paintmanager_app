import 'package:flutter/material.dart';
import '../../dominio/entidades/cliente.dart';
import '../../dominio/repositorios/repositorio_cliente.dart';

class ClienteController extends ChangeNotifier {
  final RepositorioCliente _repositorio;

  ClienteController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  // Stream que traz a lista de clientes em tempo real do Firestore
  Stream<List<Cliente>> get listaClientes => _repositorio.listarClientes();

  Future<void> salvarCliente(Cliente cliente) async {
    _carregando = true;
    notifyListeners();

    try {
      if (cliente.id == null) {
        await _repositorio.cadastrarCliente(cliente);
      } else {
        await _repositorio.editarCliente(cliente);
      }
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> removerCliente(String id) async {
    await _repositorio.excluirCliente(id);
  }
}
