import 'package:flutter/material.dart';
import '../../dominio/repositorios/repositorio_autenticacao.dart';

class AuthController extends ChangeNotifier {
  final RepositorioAutenticacao _repositorio;
  
  AuthController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  // RF001 - Realizar Login adaptado para CPF
  Future<void> realizarLogin(BuildContext context, String cpf, String senha) async {
    // Validação básica antes de iniciar o processo
    if (cpf.isEmpty || senha.isEmpty) {
      _mostrarMensagem(context, "Preencha todos os campos.");
      return;
    }

    _carregando = true;
    notifyListeners();

    try {
      // O repositório agora recebe o CPF, busca o e-mail no Firestore 
      // e autentica no Firebase Auth internamente.
      final usuario = await _repositorio.entrarComCpfESenha(cpf, senha);

      if (usuario != null && context.mounted) {
        // Navegação para a Home após sucesso
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (context.mounted) {
        // Remove prefixos genéricos de erro para o usuário final
        final mensagemErro = e.toString().replaceFirst('Exception: ', '').replaceFirst('Exception', '');
        _mostrarMensagem(context, mensagemErro, isErro: true);
      }
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // RF002 - Recuperar Senha (E-mail necessário para o Firebase)
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
        _mostrarMensagem(
          context, 
          "Link de recuperação enviado para $email", 
          isErro: false
        );
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

  // Logout do Sistema (RF001)
  Future<void> sair() async {
    await _repositorio.sair();
    notifyListeners(); 
  }

  // Função auxiliar para mensagens rápidas (SnackBars)
  void _mostrarMensagem(BuildContext context, String mensagem, {bool isErro = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isErro ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating, // Dá um aspecto mais moderno
        duration: const Duration(seconds: 3),
      ),
    );
  }
}