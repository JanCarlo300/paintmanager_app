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
      final usuario = await _repositorio.entrarComCpfESenha(cpf, senha);

      if (usuario != null && context.mounted) {
        // VERIFICAÇÃO DE SEGURANÇA: Se for primeiro acesso, obriga a troca de senha
        if (usuario.primeiroAcesso) {
          Navigator.of(context).pushReplacementNamed('/redefinir-senha-obrigatoria');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (context.mounted) {
        final mensagemErro = e.toString().replaceFirst('Exception: ', '').replaceFirst('Exception', '');
        _mostrarMensagem(context, mensagemErro, isErro: true);
      }
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // NOVO: Método para processar a redefinição obrigatória
  Future<void> redefinirSenhaObrigatoria(BuildContext context, String novaSenha) async {
    if (novaSenha.length < 6) {
      _mostrarMensagem(context, "A senha deve ter no mínimo 6 caracteres.");
      return;
    }

    _carregando = true;
    notifyListeners();

    try {
      // Chama o repositório para atualizar a senha e mudar a flag 'primeiroAcesso' para false
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