import 'package:flutter/material.dart';
import '../../dominio/entidades/cliente.dart';
import '../../dominio/repositorios/repositorio_cliente.dart';

/// Controller do módulo Clientes — Supabase.
/// Segue o mesmo padrão do UsuarioController (Future + notifyListeners).
class ClienteController extends ChangeNotifier {
  final RepositorioCliente _repositorio;
  ClienteController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  List<Cliente> _clientes = [];
  List<Cliente> get clientes => _clientes;

  /// Carrega a lista de clientes do Supabase
  Future<void> carregarClientes() async {
    _carregando = true;
    notifyListeners();
    try {
      _clientes = await _repositorio.listarClientes();
    } catch (e) {
      _clientes = [];
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Salva (insere ou atualiza) um cliente e recarrega a lista
  Future<void> salvar(Cliente cliente) async {
    _carregando = true;
    notifyListeners();
    try {
      await _repositorio.salvarCliente(cliente);
      await carregarClientes(); // Recarrega após salvar
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Inativa um cliente (soft delete)
  Future<void> inativar(int id) async {
    await _repositorio.atualizarStatus(id, false);
    await carregarClientes();
  }

  /// Reativa um cliente
  Future<void> ativar(int id) async {
    await _repositorio.atualizarStatus(id, true);
    await carregarClientes();
  }

  /// Exclui permanentemente um cliente
  Future<void> excluir(int id) async {
    await _repositorio.excluirCliente(id);
    await carregarClientes();
  }
}
