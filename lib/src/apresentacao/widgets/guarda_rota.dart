import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../modules/auth/apresentacao/controllers/auth_controller.dart';
import '../../core/tema/paleta_sahara.dart';

/// Bloqueia uma tela para quem não tem a função permitida. É a segunda
/// camada de proteção (além do menu lateral já esconder o que cada
/// função não pode acessar) — cobre navegação direta por rota nomeada.
class GuardaRota extends StatelessWidget {
  final List<String> papeisPermitidos;
  final Widget child;

  const GuardaRota({super.key, required this.papeisPermitidos, required this.child});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuarioLogado;

    if (usuario == null) {
      // Cache do usuário logado (AuthController) ainda carregando de
      // forma assíncrona — não é motivo para negar acesso.
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: PaletaSahara.primary)),
      );
    }

    if (papeisPermitidos.contains(usuario.funcao)) {
      return child;
    }

    return Scaffold(
      backgroundColor: PaletaSahara.background,
      appBar: AppBar(
        title: const Text('Acesso restrito'),
        backgroundColor: PaletaSahara.cardSurface,
        foregroundColor: PaletaSahara.onSurface,
        elevation: 0.5,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Sua função não tem acesso a esta tela.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(
                  rotaInicialParaFuncao(usuario.funcao),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PaletaSahara.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
