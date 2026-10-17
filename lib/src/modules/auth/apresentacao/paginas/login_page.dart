import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/tema/paleta_sahara.dart';
import '../../../../apresentacao/widgets/logo_app.dart';

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
      backgroundColor: PaletaSahara.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
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
        const SizedBox(height: 12),
        Text(
          "Gestão de Serviços de Pintura",
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: PaletaSahara.onSurfaceMuted,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(AuthController authController) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: PaletaSahara.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PaletaSahara.border.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A3A302A),
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Entrar",
            style: GoogleFonts.ebGaramond(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: PaletaSahara.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Use seu CPF para acessar o sistema",
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: PaletaSahara.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 28),

          _buildLabel("CPF"),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _cpfController,
            hint: "000.000.000-00",
            formatters: [cpfMask],
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          _buildLabel("Senha"),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _senhaController,
            hint: "Sua senha",
            obscureText: !_senhaVisivel,
            suffixIcon: IconButton(
              icon: Icon(
                _senhaVisivel
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: PaletaSahara.onSurfaceMuted,
              ),
              onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
            ),
          ),
          const SizedBox(height: 28),

          _buildPrimaryButton(authController),
          const SizedBox(height: 20),

          _buildFooterLinks(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: PaletaSahara.onSurface,
        letterSpacing: 0.1,
      ),
    );
  }

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
      style: GoogleFonts.manrope(fontSize: 14, color: PaletaSahara.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(
          fontSize: 14,
          color: PaletaSahara.onSurfaceMuted,
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: PaletaSahara.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PaletaSahara.primary, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: PaletaSahara.border, width: 1),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(AuthController authController) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: authController.carregando
            ? null
            : () => authController.realizarLogin(
                context,
                cpfMask.getUnmaskedText(),
                _senhaController.text,
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: PaletaSahara.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: PaletaSahara.border,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: authController.carregando
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                "Entrar",
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  Widget _buildFooterLinks() {
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
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: PaletaSahara.onSurfaceMuted,
                decoration: TextDecoration.underline,
                decorationColor: PaletaSahara.onSurfaceMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _mostrarDicaPrimeiroAcesso(context),
            child: Text(
              "Primeiro Acesso?",
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PaletaSahara.tertiary,
                decoration: TextDecoration.underline,
                decorationColor: PaletaSahara.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDicaPrimeiroAcesso(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PaletaSahara.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: PaletaSahara.primary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                "Instruções de Acesso",
                style: GoogleFonts.ebGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: PaletaSahara.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Para realizar seu primeiro login:",
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: PaletaSahara.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "1. Digite seu CPF no campo indicado.\n2. No campo Senha, use inicialmente apenas os números do seu CPF.",
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: PaletaSahara.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: PaletaSahara.border, thickness: 1),
            const SizedBox(height: 16),
            Text(
              "E a minha senha definitiva?",
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: PaletaSahara.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Ao entrar com o CPF, o sistema vai pedir automaticamente que você cadastre uma senha definitiva antes de continuar.",
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: PaletaSahara.onSurfaceMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: PaletaSahara.primary),
            child: Text(
              "Entendi",
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
