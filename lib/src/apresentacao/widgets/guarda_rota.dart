import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../modules/auth/apresentacao/controllers/auth_controller.dart';
import '../../core/tema/cores_app.dart';
import '../../core/tema/medidas_app.dart';

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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (papeisPermitidos.contains(usuario.funcao)) {
      return child;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Acesso restrito')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Espaco.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.lock_rounded, size: 56, color: context.cores.inkMuted),
              const SizedBox(height: Espaco.x4),
              Text(
                'Sua função não tem acesso a esta tela.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: Espaco.x6),
              FilledButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  rotaInicialParaFuncao(usuario.funcao),
                  (_) => false,
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
