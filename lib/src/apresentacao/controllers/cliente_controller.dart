import 'package:flutter/material.dart';
import '../../dominio/entidades/cliente.dart';
import '../../dominio/repositorios/repositorio_cliente.dart';

class ClienteController extends ChangeNotifier {
  final RepositorioCliente _repositorio;
  ClienteController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  Stream<List<Cliente>> get clientes => _repositorio.listarClientes();

  Future<void> salvar(Cliente cliente) async {
    _carregando = true;
    notifyListeners();
    try {
      await _repositorio.salvarCliente(cliente);
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> excluir(String id) async {
    await _repositorio.excluirCliente(id);
  }
}