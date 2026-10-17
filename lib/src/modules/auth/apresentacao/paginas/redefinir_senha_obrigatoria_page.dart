import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';

class RedefinirSenhaObrigatoriaPage extends StatefulWidget {
  const RedefinirSenhaObrigatoriaPage({super.key});

  @override
  State<RedefinirSenhaObrigatoriaPage> createState() => _RedefinirSenhaObrigatoriaPageState();
}

class _RedefinirSenhaObrigatoriaPageState extends State<RedefinirSenhaObrigatoriaPage> {
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();
  bool _ocultarSenha = true;
  bool _ocultarConfirmacao = true;

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar(AuthController authController) async {
    final ok = await authController.definirNovaSenha(
      context,
      _senhaController.text.trim(),
      _confirmacaoController.text.trim(),
    );
    if (!mounted || !ok) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Senha alterada!'),
        content: const Text('Sua senha foi definida com sucesso. Faça login novamente com a nova senha.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    await authController.sair();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redefinir Senha'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Espaco.x6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: c.primarySoft,
                  child: Icon(Symbols.lock_reset_rounded, size: 48, color: c.primary),
                ),
              ),
              const SizedBox(height: Espaco.x6),
              Text(
                'Primeiro Acesso',
                style: texto.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Espaco.x2),
              Text(
                'Por segurança, cadastre uma nova senha para continuar.\nMínimo de 8 caracteres, com letras e números, diferente do seu CPF.',
                style: texto.bodyMedium?.copyWith(color: c.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Espaco.x8),
              TextField(
                controller: _senhaController,
                obscureText: _ocultarSenha,
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  prefixIcon: const Icon(Symbols.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_ocultarSenha ? Symbols.visibility_rounded : Symbols.visibility_off_rounded),
                    onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
                  ),
                ),
              ),
              const SizedBox(height: Espaco.x4),
              TextField(
                controller: _confirmacaoController,
                obscureText: _ocultarConfirmacao,
                decoration: InputDecoration(
                  labelText: 'Confirmar nova senha',
                  prefixIcon: const Icon(Symbols.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_ocultarConfirmacao ? Symbols.visibility_rounded : Symbols.visibility_off_rounded),
                    onPressed: () => setState(() => _ocultarConfirmacao = !_ocultarConfirmacao),
                  ),
                ),
              ),
              const SizedBox(height: Espaco.x6),
              FilledButton(
                onPressed: authController.carregando ? null : () => _salvar(authController),
                child: authController.carregando
                    ? SizedBox(
                        height: TamanhoIcone.pequeno,
                        width: TamanhoIcone.pequeno,
                        child: CircularProgressIndicator(color: c.inkMuted, strokeWidth: 2),
                      )
                    : const Text('Salvar e Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
