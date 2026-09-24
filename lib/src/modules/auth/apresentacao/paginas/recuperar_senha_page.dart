import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

/// RF002 - Recuperar Senha, em 3 passos dentro da mesma tela:
/// 1) CPF ou e-mail  2) código recebido por e-mail  3) nova senha
enum _EtapaRecuperacao { identificacao, codigo, novaSenha }

class RecuperarSenhaPage extends StatefulWidget {
  const RecuperarSenhaPage({super.key});

  @override
  State<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends State<RecuperarSenhaPage> {
  _EtapaRecuperacao _etapa = _EtapaRecuperacao.identificacao;

  final _loginController = TextEditingController();
  final _codigoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();
  bool _ocultarSenha = true;
  bool _ocultarConfirmacao = true;

  @override
  void dispose() {
    _loginController.dispose();
    _codigoController.dispose();
    _senhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  Future<void> _avancarParaCodigo(AuthController authController) async {
    await authController.solicitarCodigoRecuperacao(_loginController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Se o CPF ou e-mail estiver cadastrado, um código foi enviado."),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
    setState(() => _etapa = _EtapaRecuperacao.codigo);
  }

  Future<void> _confirmarCodigo(AuthController authController) async {
    final ok = await authController.verificarCodigoRecuperacao(context, _codigoController.text);
    if (!mounted || !ok) return;
    setState(() => _etapa = _EtapaRecuperacao.novaSenha);
  }

  Future<void> _salvarNovaSenha(AuthController authController) async {
    final ok = await authController.definirNovaSenha(
      context,
      _senhaController.text,
      _confirmacaoController.text,
    );
    if (!mounted || !ok) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Senha alterada!"),
        content: const Text("Sua senha foi definida com sucesso. Faça login novamente com a nova senha."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendi"),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
        child: switch (_etapa) {
          _EtapaRecuperacao.identificacao => _buildEtapaIdentificacao(authController),
          _EtapaRecuperacao.codigo => _buildEtapaCodigo(authController),
          _EtapaRecuperacao.novaSenha => _buildEtapaNovaSenha(authController),
        },
      ),
    );
  }

  // === PASSO 1: CPF OU E-MAIL ===
  Widget _buildEtapaIdentificacao(AuthController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_reset_outlined, color: Colors.black, size: 40),
        const SizedBox(height: 24),
        const Text("Recuperar Senha", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          "Informe seu CPF ou e-mail cadastrado. Enviaremos um código de verificação por e-mail.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 40),
        TextField(controller: _loginController, decoration: _decoracao("CPF ou e-mail")),
        const SizedBox(height: 40),
        _botaoPrimario(
          texto: "Enviar código",
          carregando: c.carregando,
          onPressed: () => _avancarParaCodigo(c),
        ),
      ],
    );
  }

  // === PASSO 2: CÓDIGO DE 6 DÍGITOS ===
  Widget _buildEtapaCodigo(AuthController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.mark_email_read_outlined, color: Colors.black, size: 40),
        const SizedBox(height: 24),
        const Text("Digite o código", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          "Verifique seu e-mail e digite o código que enviamos.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _codigoController,
          keyboardType: TextInputType.number,
          maxLength: 10,
          decoration: _decoracao("Código recebido por e-mail"),
        ),
        const SizedBox(height: 24),
        _botaoPrimario(
          texto: "Confirmar código",
          carregando: c.carregando,
          onPressed: () => _confirmarCodigo(c),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: c.carregando ? null : () => setState(() => _etapa = _EtapaRecuperacao.identificacao),
            child: const Text("Voltar", style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  // === PASSO 3: NOVA SENHA ===
  Widget _buildEtapaNovaSenha(AuthController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.password_outlined, color: Colors.black, size: 40),
        const SizedBox(height: 24),
        const Text("Nova senha", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          "Mínimo de 8 caracteres, com letras e números, diferente do seu CPF.",
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _senhaController,
          obscureText: _ocultarSenha,
          decoration: _decoracao("Nova senha").copyWith(
            suffixIcon: IconButton(
              icon: Icon(_ocultarSenha ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _confirmacaoController,
          obscureText: _ocultarConfirmacao,
          decoration: _decoracao("Confirmar nova senha").copyWith(
            suffixIcon: IconButton(
              icon: Icon(_ocultarConfirmacao ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _ocultarConfirmacao = !_ocultarConfirmacao),
            ),
          ),
        ),
        const SizedBox(height: 40),
        _botaoPrimario(
          texto: "Salvar nova senha",
          carregando: c.carregando,
          onPressed: () => _salvarNovaSenha(c),
        ),
      ],
    );
  }

  InputDecoration _decoracao(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  Widget _botaoPrimario({required String texto, required bool carregando, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: carregando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: carregando
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(texto, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
