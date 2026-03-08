import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _cpfController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;

  // 1. Definição da Máscara de CPF para entrada de dados
  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##', 
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F4F8), Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Circular do PaintManager
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.format_paint, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  "PaintManager",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Sistema de Gestão de Serviços de Pintura",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Card de Login Principal
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Entrar",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "Use seu CPF para acessar o sistema",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 24),

                      // Campo CPF com Máscara
                      const Text("CPF", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cpfController,
                        inputFormatters: [cpfMask],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "000.000.000-00",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Campo Senha
                      const Text("Senha", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _senhaController,
                        obscureText: !_senhaVisivel,
                        decoration: InputDecoration(
                          hintText: "Sua senha",
                          filled: true,
                          fillColor: Colors.grey[100],
                          suffixIcon: IconButton(
                            icon: Icon(
                              _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botão Entrar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: authController.carregando
                              ? null
                              : () => authController.realizarLogin(
                                    context,
                                    cpfMask.getUnmaskedText(), // Envia apenas números
                                    _senhaController.text,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: authController.carregando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("Entrar", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Links de Apoio: Esqueci Senha e Primeiro Acesso
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/recuperar-senha'),
                            child: const Text(
                              "Esqueci minha senha",
                              style: TextStyle(color: Colors.black, fontSize: 13),
                            ),
                          ),
                          // Botão de Dica para Primeiro Acesso atualizado
                          TextButton(
                            onPressed: () => _mostrarDicaPrimeiroAcesso(context),
                            child: const Text(
                              "Primeiro Acesso?",
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Função atualizada para orientar sobre o login inicial e troca posterior de senha
  void _mostrarDicaPrimeiroAcesso(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 10),
            Text("Instruções de Acesso"),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Para realizar seu primeiro login:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text("1. Digite seu CPF no campo indicado."),
            Text("2. No campo Senha, use inicialmente apenas os números do seu CPF."),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            Text(
              "Deseja definir uma senha pessoal?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Após entrar no sistema pela primeira vez, recomendamos que saia e utilize a opção 'Esqueci minha senha' para cadastrar uma senha definitiva de sua preferência.",
              style: TextStyle(color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Entendi",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}