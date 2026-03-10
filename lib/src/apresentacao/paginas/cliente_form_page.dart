import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../dominio/entidades/cliente.dart';
import '../controllers/cliente_controller.dart';

class ClienteFormPage extends StatefulWidget {
  final Cliente? clienteParaEdicao;

  const ClienteFormPage({super.key, this.clienteParaEdicao});

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;
  late TextEditingController _enderecoController;
  late TextEditingController _documentoController;

  final _telefoneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  final _documentoMask = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});

  @override
  void initState() {
    super.initState();
    final c = widget.clienteParaEdicao;
    _nomeController = TextEditingController(text: c?.nome);
    _emailController = TextEditingController(text: c?.email);
    _telefoneController = TextEditingController(text: c?.telefone);
    _enderecoController = TextEditingController(text: c?.endereco);
    _documentoController = TextEditingController(text: c?.cpfOuCnpj);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _documentoController.dispose();
    super.dispose();
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      final controller = context.read<ClienteController>();
      
      final novoCliente = Cliente(
        id: widget.clienteParaEdicao?.id,
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        telefone: _telefoneController.text.trim(),
        endereco: _enderecoController.text.trim(),
        cpfOuCnpj: _documentoController.text.trim(),
        criadoEm: widget.clienteParaEdicao?.criadoEm ?? DateTime.now(),
      );

      try {
        await controller.salvar(novoCliente);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cliente salvo com sucesso!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao salvar: $e"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final carregando = context.watch<ClienteController>().carregando;
    final isEdicao = widget.clienteParaEdicao != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isEdicao ? "Editar Cliente" : "Novo Cliente",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(
                    "Nome Completo",
                    _nomeController,
                    Icons.person_outline,
                    "Digite o nome completo",
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    "E-mail",
                    _emailController,
                    Icons.email_outlined,
                    "exemplo@email.com",
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    "Telefone/WhatsApp",
                    _telefoneController,
                    Icons.phone_outlined,
                    "(00) 00000-0000",
                    mask: _telefoneMask,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    "CPF ou CNPJ",
                    _documentoController,
                    Icons.badge_outlined,
                    "000.000.000-00",
                    mask: _documentoMask,
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    "Endereço",
                    _enderecoController,
                    Icons.location_on_outlined,
                    "Rua, Número, Bairro, Cidade",
                  ),
                  const SizedBox(height: 32),
                  
                  // Botão Salvar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: carregando ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: carregando 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "SALVAR CLIENTE",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    TextInputType? keyboardType,
    MaskTextInputFormatter? mask,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: mask != null ? [mask] : [],
          validator: (value) => value == null || value.isEmpty ? "Campo obrigatório" : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}