import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../dominio/entidades/cliente.dart';
import '../controllers/cliente_controller.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';
import '../../../../core/validadores/validador_cpf.dart';

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

  String? _validarDocumento(String? valor) {
    // Clientes antigos podem ter CNPJ (14 dígitos) gravado; só o CPF é validado.
    if (ValidadorCpf.apenasDigitos(valor ?? '').length == 14) return null;
    return ValidadorCpf.mensagemErro(valor, obrigatorio: false);
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
        ativo: widget.clienteParaEdicao?.ativo ?? true,
      );

      try {
        await controller.salvar(novoCliente);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cliente salvo com sucesso!")),
          );
        }
      } catch (e) {
        if (mounted) {
          final c = context.cores;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erro ao salvar: $e", style: TextStyle(color: c.onError)),
              backgroundColor: c.error,
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
      appBar: AppBar(title: Text(isEdicao ? "Editar Cliente" : "Novo Cliente")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Espaco.margemTela),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: CardApp(
              padding: const EdgeInsets.all(Espaco.x6),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      "Nome Completo",
                      _nomeController,
                      Symbols.person_rounded,
                      "Digite o nome completo",
                    ),
                    const SizedBox(height: Espaco.x5),
                    _buildField(
                      "E-mail",
                      _emailController,
                      Symbols.mail_rounded,
                      "exemplo@email.com",
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: Espaco.x5),
                    _buildField(
                      "Telefone/WhatsApp",
                      _telefoneController,
                      Symbols.call_rounded,
                      "(00) 00000-0000",
                      mask: _telefoneMask,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: Espaco.x5),
                    _buildField(
                      "CPF ou CNPJ (opcional)",
                      _documentoController,
                      Symbols.badge_rounded,
                      "000.000.000-00",
                      mask: _documentoMask,
                      keyboardType: TextInputType.number,
                      validator: _validarDocumento,
                    ),
                    const SizedBox(height: Espaco.x5),
                    _buildField(
                      "Endereço",
                      _enderecoController,
                      Symbols.location_on_rounded,
                      "Rua, Número, Bairro, Cidade",
                    ),
                    const SizedBox(height: Espaco.x8),

                    // Botão Salvar
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: carregando ? null : _salvar,
                        child: carregando
                            ? SizedBox(
                                height: TamanhoIcone.pequeno,
                                width: TamanhoIcone.pequeno,
                                child: CircularProgressIndicator(color: context.cores.inkMuted, strokeWidth: 2),
                              )
                            : const Text("Salvar Cliente"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Fundo, borda, foco e erro vêm do tema (InputDecorationTheme).
  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    TextInputType? keyboardType,
    MaskTextInputFormatter? mask,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: Espaco.x2),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: mask != null ? [mask] : [],
          validator: validator ?? (value) => value == null || value.isEmpty ? "Campo obrigatório" : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: TamanhoIcone.pequeno),
          ),
        ),
      ],
    );
  }
}
