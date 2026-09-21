import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../controllers/auth_controller.dart';

// Paleta Sahara
class _Sahara {
  static const background = Color(0xFFFAF5EE);
  static const primary = Color(0xFFC2652A);
  static const tertiary = Color(0xFF8C3C3C);
  static const border = Color(0xFFD8D0C8);
  static const cardSurface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF3A302A);
  static const onSurfaceMuted = Color(0xFF9A8E85);
}

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
      backgroundColor: _Sahara.background,
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
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _Sahara.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.format_paint_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 20),
        Text(
          "PaintManager",
          style: GoogleFonts.ebGaramond(
            fontSize: 34,
            fontWeight: FontWeight.w600,
            color: _Sahara.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Gestão de Serviços de Pintura",
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: _Sahara.onSurfaceMuted,
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
        color: _Sahara.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Sahara.border.withValues(alpha: 0.6), width: 1),
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
              color: _Sahara.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Use seu CPF para acessar o sistema",
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: _Sahara.onSurfaceMuted,
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
                _senhaVisivel ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: _Sahara.onSurfaceMuted,
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
        color: _Sahara.onSurface,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<dynamic>? formatters,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: formatters != null ? [...formatters] : null,
      style: GoogleFonts.manrope(fontSize: 14, color: _Sahara.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(
          fontSize: 14,
          color: _Sahara.onSurfaceMuted,
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _Sahara.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _Sahara.primary, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _Sahara.border, width: 1),
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
          backgroundColor: _Sahara.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _Sahara.border,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/recuperar-senha'),
          child: Text(
            "Esqueci minha senha",
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: _Sahara.onSurfaceMuted,
              decoration: TextDecoration.underline,
              decorationColor: _Sahara.onSurfaceMuted,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _mostrarDicaPrimeiroAcesso(context),
          child: Text(
            "Primeiro Acesso?",
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _Sahara.tertiary,
              decoration: TextDecoration.underline,
              decorationColor: _Sahara.tertiary,
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarDicaPrimeiroAcesso(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _Sahara.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: _Sahara.primary, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                "Instruções de Acesso",
                style: GoogleFonts.ebGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _Sahara.onSurface,
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
                color: _Sahara.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "1. Digite seu CPF no campo indicado.\n2. No campo Senha, use inicialmente apenas os números do seu CPF.",
              style: GoogleFonts.manrope(fontSize: 13, color: _Sahara.onSurface),
            ),
            const SizedBox(height: 16),
            Divider(color: _Sahara.border, thickness: 1),
            const SizedBox(height: 16),
            Text(
              "Deseja definir uma senha pessoal?",
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _Sahara.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Após entrar no sistema pela primeira vez, recomendamos que utilize a opção 'Esqueci minha senha' para cadastrar uma senha definitiva.",
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: _Sahara.onSurfaceMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: _Sahara.primary),
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
