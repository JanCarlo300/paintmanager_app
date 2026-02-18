import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuta as mudanças no AuthController
    final authController = context.watch<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text("PaintManager - Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "E-mail",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senhaController,
              decoration: const InputDecoration(
                labelText: "Senha",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                // Desativa o botão se estiver carregando [cite: 612]
                onPressed: authController.carregando
                    ? null
                    : () {
                        authController.realizarLogin(
                          context,
                          _emailController.text.trim(),
                          _senhaController.text.trim(),
                        );
                      },
                child: authController.carregando
                    ? const CircularProgressIndicator()
                    : const Text("Entrar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
