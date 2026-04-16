import 'package:flutter/material.dart';
import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/repositorio_autenticacao.dart';

class AuthController extends ChangeNotifier {
  final RepositorioAutenticacao _repositorio;
  
  AuthController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  // --- SESSÃO PERSISTENTE ---
  Stream<Usuario?> get usuarioAtual => _repositorio.usuarioAtual;

  // RF001 - Realizar Login com Verificação de Primeiro Acesso
  Future<void> realizarLogin(BuildContext context, String cpf, String senha) async {
    if (cpf.isEmpty || senha.isEmpty) {
      _mostrarMensagem(context, "Preencha todos os campos.");
      return;
    }

    _carregando = true;
    notifyListeners();

    try {
      print("Tentando realizar login com CPF: $cpf");
      final usuario = await _repositorio.entrarComCpfESenha(cpf, senha);
      print("Resultado do login: $usuario");

      if (usuario != null && context.mounted) {
        // Se é primeiro acesso e não é Administrador, obriga troca de senha
        if (usuario.primeiroAcesso && usuario.funcao != 'Administrador') {
          print("Redirecionando para redefinir senha");
          Navigator.of(context).pushReplacementNamed('/redefinir-senha-obrigatoria');
        } else {
          print("Redirecionando para home");
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      print("Erro no login recebido pelo controller: $e");
      if (context.mounted) {
        final mensagemErro = e.toString().replaceFirst('Exception: ', '').replaceFirst('Exception', '');
        _mostrarMensagem(context, mensagemErro, isErro: true);
      }
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // Redefinição obrigatória de senha no primeiro acesso
  Future<void> redefinirSenhaObrigatoria(BuildContext context, String novaSenha) async {
    if (novaSenha.length < 6) {
      _mostrarMensagem(context, "A senha deve ter no mínimo 6 caracteres.");
      return;
    }

    _carregando = true;
    notifyListeners();

    try {
      await _repositorio.atualizarSenhaPrimeiroAcesso(novaSenha);

      if (context.mounted) {
        _mostrarMensagem(context, "Senha definida com sucesso!", isErro: false);
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (context.mounted) {
        _mostrarMensagem(context, e.toString(), isErro: true);
      }
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // RF002 - Recuperar Senha
  Future<void> recuperarSenha(BuildContext context, String email) async {
    if (email.isEmpty) {
      _mostrarMensagem(context, "Por favor, informe o e-mail.");
      return;
    }

    _carregando = true;
    notifyListeners();

    try {
      await _repositorio.recuperarSenha(email);
      if (context.mounted) {
        _mostrarMensagem(context, "Link de recuperação enviado para $email", isErro: false);
        Navigator.of(context).pop(); 
      }
    } catch (e) {
      if (context.mounted) {
        _mostrarMensagem(context, e.toString(), isErro: true);
      }
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // Logout do Sistema
  Future<void> sair() async {
    await _repositorio.sair();
    notifyListeners(); 
  }

  void _mostrarMensagem(BuildContext context, String mensagem, {bool isErro = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isErro ? Colors.red : Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
