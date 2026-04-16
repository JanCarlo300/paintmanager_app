import 'package:flutter/material.dart';
import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/repositorio_usuario.dart';

class UsuarioController extends ChangeNotifier {
  final RepositorioUsuario _repositorio;
  UsuarioController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  List<Usuario> _usuarios = [];
  List<Usuario> get usuarios => _usuarios;

  /// Carrega a lista de usuários do Supabase (substitui o antigo Stream)
  Future<void> carregarUsuarios() async {
    _carregando = true;
    notifyListeners();
    try {
      _usuarios = await _repositorio.listarUsuarios();
    } catch (e) {
      _usuarios = [];
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> salvar(Usuario usuario) async {
    _carregando = true;
    notifyListeners();
    try {
      await _repositorio.salvarUsuario(usuario);
      await carregarUsuarios(); // Recarrega após salvar
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // RF003 - Inativação de Usuário (Soft Delete)
  Future<void> alternarStatus(Usuario usuario) async {
    final usuarioEditado = Usuario(
      id: usuario.id,
      authId: usuario.authId,
      nome: usuario.nome,
      email: usuario.email,
      cpf: usuario.cpf,
      telefone: usuario.telefone,
      funcao: usuario.funcao,
      status: !usuario.status,
      primeiroAcesso: usuario.primeiroAcesso,
      criadoEm: usuario.criadoEm,
    );
    
    await _repositorio.salvarUsuario(usuarioEditado);
    await carregarUsuarios(); // Recarrega após alteração
  }
}
