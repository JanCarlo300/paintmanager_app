import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/tema/paleta_sahara.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    return Scaffold(
      backgroundColor: PaletaSahara.background,
      appBar: AppBar(
        title: const Text('Redefinir Senha'),
        centerTitle: true,
        backgroundColor: PaletaSahara.cardSurface,
        foregroundColor: PaletaSahara.onSurface,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset, size: 80, color: PaletaSahara.primary),
              const SizedBox(height: 24),
              const Text(
                'Primeiro Acesso',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Por segurança, cadastre uma nova senha para continuar.\nMínimo de 8 caracteres, com letras e números, diferente do seu CPF.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _senhaController,
                obscureText: _ocultarSenha,
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_ocultarSenha ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmacaoController,
                obscureText: _ocultarConfirmacao,
                decoration: InputDecoration(
                  labelText: 'Confirmar nova senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_ocultarConfirmacao ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _ocultarConfirmacao = !_ocultarConfirmacao),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: PaletaSahara.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: authController.carregando ? null : () => _salvar(authController),
                child: authController.carregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Salvar e Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
