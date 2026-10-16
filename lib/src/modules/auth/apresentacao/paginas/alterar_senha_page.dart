import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/tema/paleta_sahara.dart';

/// Troca de senha pelo próprio usuário logado (aberta pela tela Configurações).
class AlterarSenhaPage extends StatefulWidget {
  const AlterarSenhaPage({super.key});

  @override
  State<AlterarSenhaPage> createState() => _AlterarSenhaPageState();
}

class _AlterarSenhaPageState extends State<AlterarSenhaPage> {
  final _atualController = TextEditingController();
  final _novaController = TextEditingController();
  final _confirmacaoController = TextEditingController();
  bool _ocultarAtual = true;
  bool _ocultarNova = true;
  bool _ocultarConfirmacao = true;

  @override
  void dispose() {
    _atualController.dispose();
    _novaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  Future<void> _salvar(AuthController authController) async {
    FocusScope.of(context).unfocus();
    final ok = await authController.alterarSenha(
      context,
      _atualController.text.trim(),
      _novaController.text.trim(),
      _confirmacaoController.text.trim(),
    );
    if (!mounted || !ok) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Senha alterada com sucesso.'),
        backgroundColor: PaletaSahara.onSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  Widget _campoSenha({
    required TextEditingController controller,
    required String rotulo,
    required bool oculto,
    required VoidCallback alternar,
  }) {
    return TextField(
      controller: controller,
      obscureText: oculto,
      decoration: InputDecoration(
        labelText: rotulo,
        prefixIcon: const Icon(Icons.lock_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(oculto ? Icons.visibility : Icons.visibility_off),
          onPressed: alternar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: PaletaSahara.background,
      appBar: AppBar(
        title: const Text('Alterar Senha', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: PaletaSahara.cardSurface,
        foregroundColor: PaletaSahara.onSurface,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mínimo de 8 caracteres, com letras e números, diferente do seu CPF.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _campoSenha(
              controller: _atualController,
              rotulo: 'Senha atual',
              oculto: _ocultarAtual,
              alternar: () => setState(() => _ocultarAtual = !_ocultarAtual),
            ),
            const SizedBox(height: 16),
            _campoSenha(
              controller: _novaController,
              rotulo: 'Nova senha',
              oculto: _ocultarNova,
              alternar: () => setState(() => _ocultarNova = !_ocultarNova),
            ),
            const SizedBox(height: 16),
            _campoSenha(
              controller: _confirmacaoController,
              rotulo: 'Confirmar nova senha',
              oculto: _ocultarConfirmacao,
              alternar: () => setState(() => _ocultarConfirmacao = !_ocultarConfirmacao),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: PaletaSahara.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: authController.carregando ? null : () => _salvar(authController),
              child: authController.carregando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Salvar nova senha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
