import 'package:flutter/material.dart';
import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/repositorio_usuario.dart';

class UsuarioController extends ChangeNotifier {
  final RepositorioUsuario _repositorio;
  UsuarioController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  // AJUSTADO: Nome alterado de 'listaUsuarios' para 'usuarios' 
  // para coincidir com a chamada no DashboardPage
  Stream<List<Usuario>> get usuarios => _repositorio.listarUsuarios();

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

  // RF003 - Inativação de Usuário (Soft Delete)
  Future<void> alternarStatus(Usuario usuario) async {
    final usuarioEditado = Usuario(
      id: usuario.id,
      nome: usuario.nome,
      email: usuario.email,
      cpf: usuario.cpf,
      telefone: usuario.telefone,
      funcao: usuario.funcao,
      status: !usuario.status, // Inverte o status atual
      senha: usuario.senha,
      primeiroAcesso: usuario.primeiroAcesso, // Mantém a flag original
      criadoEm: usuario.criadoEm,
    );
    
    await _repositorio.salvarUsuario(usuarioEditado);
  }
}