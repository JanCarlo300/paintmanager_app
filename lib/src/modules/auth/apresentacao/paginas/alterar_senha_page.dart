import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';

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
      const SnackBar(content: Text('Senha alterada com sucesso.')),
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
        prefixIcon: const Icon(Symbols.lock_rounded),
        suffixIcon: IconButton(
          icon: Icon(oculto ? Symbols.visibility_rounded : Symbols.visibility_off_rounded),
          onPressed: alternar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final c = context.cores;

    return Scaffold(
      appBar: AppBar(title: const Text('Alterar Senha')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Espaco.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mínimo de 8 caracteres, com letras e números, diferente do seu CPF.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: Espaco.x6),
            _campoSenha(
              controller: _atualController,
              rotulo: 'Senha atual',
              oculto: _ocultarAtual,
              alternar: () => setState(() => _ocultarAtual = !_ocultarAtual),
            ),
            const SizedBox(height: Espaco.x4),
            _campoSenha(
              controller: _novaController,
              rotulo: 'Nova senha',
              oculto: _ocultarNova,
              alternar: () => setState(() => _ocultarNova = !_ocultarNova),
            ),
            const SizedBox(height: Espaco.x4),
            _campoSenha(
              controller: _confirmacaoController,
              rotulo: 'Confirmar nova senha',
              oculto: _ocultarConfirmacao,
              alternar: () => setState(() => _ocultarConfirmacao = !_ocultarConfirmacao),
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
                  : const Text('Salvar nova senha'),
            ),
          ],
        ),
      ),
    );
  }
}
