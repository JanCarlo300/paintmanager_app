import 'package:flutter/material.dart';
import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/repositorio_usuario.dart';

class UsuarioController extends ChangeNotifier {
  final RepositorioUsuario _repositorio;
  UsuarioController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  Stream<List<Usuario>> get listaUsuarios => _repositorio.listarUsuarios();

  Future<void> salvar(Usuario usuario) async {
    _carregando = true;
    notifyListeners();
    try {
      await _repositorio.salvarUsuario(usuario);
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // NOVO MÉTODO: Em vez de excluir, ele apenas inverte o status
  Future<void> alternarStatus(Usuario usuario) async {
    final usuarioEditado = Usuario(
      id: usuario.id,
      nome: usuario.nome,
      email: usuario.email,
      cpf: usuario.cpf,
      telefone: usuario.telefone,
      funcao: usuario.funcao,
      status: !usuario.status, // Se está ativo, inativa. Se está inativo, ativa.
      senha: usuario.senha,
      criadoEm: usuario.criadoEm,
    );
    
    await _repositorio.salvarUsuario(usuarioEditado);
  }
}