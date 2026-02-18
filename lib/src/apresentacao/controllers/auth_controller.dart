import 'package:flutter/material.dart';
import '../../dominio/repositorios/repositorio_autenticacao.dart';

class AuthController extends ChangeNotifier {
  final RepositorioAutenticacao _repositorio;

  AuthController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  // RF001 - Realizar Login
  Future<void> realizarLogin(
    BuildContext context,
    String email,
    String senha,
  ) async {
    _carregando = true;
    notifyListeners(); // Notifica a UI para mostrar um indicador de progresso

    try {
      final usuario = await _repositorio.entrarComEmailESenha(email, senha);

      if (usuario != null && context.mounted) {
        // Redireciona para a Home se o login for bem-sucedido
        // Precisamos definir a rota '/home' no main.dart
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      // Exibe o erro (ex: "Senha incorreta") numa SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      _carregando = false;
      notifyListeners(); // Esconde o indicador de progresso
    }
  }
}
