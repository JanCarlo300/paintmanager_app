import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';

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
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Espaco.x8, vertical: Espaco.x5),
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
        ..._cabecalho(
          Symbols.lock_reset_rounded,
          "Recuperar Senha",
          "Informe seu CPF ou e-mail cadastrado. Enviaremos um código de verificação por e-mail.",
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
        ..._cabecalho(
          Symbols.mark_email_read_rounded,
          "Digite o código",
          "Verifique seu e-mail e digite o código que enviamos.",
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
            style: TextButton.styleFrom(foregroundColor: context.cores.inkMuted),
            child: const Text("Voltar"),
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
        ..._cabecalho(
          Symbols.password_rounded,
          "Nova senha",
          "Mínimo de 8 caracteres, com letras e números, diferente do seu CPF.",
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _senhaController,
          obscureText: _ocultarSenha,
          decoration: _decoracao("Nova senha").copyWith(
            suffixIcon: IconButton(
              icon: Icon(_ocultarSenha ? Symbols.visibility_rounded : Symbols.visibility_off_rounded),
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
              icon: Icon(_ocultarConfirmacao ? Symbols.visibility_rounded : Symbols.visibility_off_rounded),
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

  /// Ícone num círculo pêssego + título + explicação, igual nos 3 passos.
  List<Widget> _cabecalho(IconData icone, String titulo, String explicacao) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return [
      CircleAvatar(
        radius: 28,
        backgroundColor: c.primarySoft,
        child: Icon(icone, color: c.primary, size: TamanhoIcone.grande),
      ),
      const SizedBox(height: Espaco.x6),
      Text(titulo, style: texto.headlineMedium),
      const SizedBox(height: Espaco.x3),
      Text(explicacao, style: texto.bodyLarge?.copyWith(color: c.inkMuted)),
    ];
  }

  // Fundo, cantos e foco vêm do tema (InputDecorationTheme).
  InputDecoration _decoracao(String hint) => InputDecoration(
        hintText: hint,
        counterText: "",
      );

  Widget _botaoPrimario({required String texto, required bool carregando, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: carregando ? null : onPressed,
        child: carregando
            ? SizedBox(
                height: TamanhoIcone.pequeno,
                width: TamanhoIcone.pequeno,
                child: CircularProgressIndicator(color: context.cores.inkMuted, strokeWidth: 2),
              )
            : Text(texto),
      ),
    );
  }
}
