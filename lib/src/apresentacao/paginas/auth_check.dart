import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dominio/entidades/usuario.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';
// Substitua pela importação da sua página inicial real (ex: cliente_list_page.dart)
import 'usuario_list_page.dart'; 

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return StreamBuilder<Usuario?>(
      stream: authController.usuarioAtual,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Usuário está logado: Vai para a tela principal
          return const UsuarioListPage(); // Troque para a sua Home definitiva depois
        }

        // Usuário não está logado: Vai para o Login
        return const LoginPage();
      },
    );
  }
}