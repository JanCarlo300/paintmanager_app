import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../controllers/auth_controller.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../apresentacao/widgets/logo_app.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;

  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Espaco.x6, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 40),
                _buildCard(authController),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Assinatura do manual da marca: ícone + "Paint" (terracota) "Manager".
        // scaleDown só entra em telas muito estreitas.
        const FittedBox(
          fit: BoxFit.scaleDown,
          child: AssinaturaApp(tamanhoLogo: 64),
        ),
        const SizedBox(height: Espaco.x3),
        Text(
          "Gestão de Serviços de Pintura",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.cores.inkMuted),
        ),
      ],
    );
  }

  Widget _buildCard(AuthController authController) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return CardApp(
      padding: const EdgeInsets.all(Espaco.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Entrar", style: texto.headlineMedium),
          const SizedBox(height: Espaco.x1),
          Text(
            "Use seu CPF para acessar o sistema",
            style: texto.bodyMedium?.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: 28),

          _buildLabel("CPF"),
          const SizedBox(height: Espaco.x2),
          _buildTextField(
            controller: _cpfController,
            hint: "000.000.000-00",
            formatters: [cpfMask],
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: Espaco.x5),

          _buildLabel("Senha"),
          const SizedBox(height: Espaco.x2),
          _buildTextField(
            controller: _senhaController,
            hint: "Sua senha",
            obscureText: !_senhaVisivel,
            suffixIcon: IconButton(
              icon: Icon(
                _senhaVisivel ? Symbols.visibility_rounded : Symbols.visibility_off_rounded,
                size: TamanhoIcone.pequeno,
              ),
              onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
            ),
          ),
          const SizedBox(height: 28),

          _buildPrimaryButton(authController),
          const SizedBox(height: Espaco.x4),

          _buildFooterLinks(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  // Fundo, borda, foco e cores dos textos vêm do tema (InputDecorationTheme).
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildPrimaryButton(AuthController authController) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: authController.carregando
            ? null
            : () => authController.realizarLogin(
                context,
                cpfMask.getUnmaskedText(),
                _senhaController.text,
              ),
        child: authController.carregando
            ? SizedBox(
                height: TamanhoIcone.pequeno,
                width: TamanhoIcone.pequeno,
                child: CircularProgressIndicator(color: context.cores.inkMuted, strokeWidth: 2),
              )
            : const Text("Entrar"),
      ),
    );
  }

  Widget _buildFooterLinks() {
    final c = context.cores;
    final estilo = Theme.of(context).textTheme.bodyMedium?.copyWith(
          decoration: TextDecoration.underline,
        );

    // Wrap: lado a lado quando cabe; em tela estreita ou fonte grande do
    // celular, o segundo link desce para a linha de baixo (sem estourar).
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/recuperar-senha'),
            child: Text(
              "Esqueci minha senha",
              style: estilo?.copyWith(color: c.inkMuted, decorationColor: c.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () => _mostrarDicaPrimeiroAcesso(context),
            child: Text(
              "Primeiro Acesso?",
              style: estilo?.copyWith(
                fontWeight: FontWeight.w700,
                color: c.secondary,
                decorationColor: c.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDicaPrimeiroAcesso(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final destaque = texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Symbols.info_rounded, color: c.primary),
            const SizedBox(width: 10),
            const Flexible(child: Text("Instruções de Acesso")),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Para realizar seu primeiro login:", style: destaque),
            const SizedBox(height: Espaco.x3),
            const Text(
              "1. Digite seu CPF no campo indicado.\n2. No campo Senha, use inicialmente apenas os números do seu CPF.",
            ),
            const SizedBox(height: Espaco.x4),
            const Divider(),
            const SizedBox(height: Espaco.x4),
            Text("E a minha senha definitiva?", style: destaque),
            const SizedBox(height: Espaco.x2),
            Text(
              "Ao entrar com o CPF, o sistema vai pedir automaticamente que você cadastre uma senha definitiva antes de continuar.",
              style: texto.bodyMedium?.copyWith(color: c.inkMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Entendi"),
          ),
        ],
      ),
    );
  }
}
