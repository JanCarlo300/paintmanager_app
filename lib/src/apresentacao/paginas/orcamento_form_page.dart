import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../dominio/entidades/orcamento.dart';
import '../../dominio/entidades/item_servico.dart';
import '../../dominio/entidades/cliente.dart';
import '../controllers/orcamento_controller.dart';
import '../controllers/cliente_controller.dart';

class OrcamentoFormPage extends StatefulWidget {
  final Orcamento? orcamentoParaEdicao;

  const OrcamentoFormPage({super.key, this.orcamentoParaEdicao});

  @override
  State<OrcamentoFormPage> createState() => _OrcamentoFormPageState();
}

class _OrcamentoFormPageState extends State<OrcamentoFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Dados do orçamento
  Cliente? _clienteSelecionado;
  late TextEditingController _descricaoController;
  late DateTime _dataValidade;
  String _formaPagamento = 'PIX';
  String _status = 'Pendente';

  // Itens de serviço (lista dinâmica)
  final List<_ItemServicoForm> _itensForm = [];

  // Custos
  bool _materiaisInclusos = false;
  late TextEditingController _valorMateriaisController;
  late TextEditingController _valorMaoDeObraController;
  late TextEditingController _descontoController;

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    final orc = widget.orcamentoParaEdicao;

    _descricaoController = TextEditingController(text: orc?.descricao);
    _dataValidade = orc?.dataValidade ?? DateTime.now().add(const Duration(days: 30));
    _formaPagamento = orc?.formaPagamento ?? 'PIX';
    _status = orc?.status ?? 'Pendente';
    _materiaisInclusos = orc?.materiaisInclusos ?? false;
    _valorMateriaisController = TextEditingController(text: orc != null ? orc.valorMateriais.toStringAsFixed(2) : '');
    _valorMaoDeObraController = TextEditingController(text: orc != null ? orc.valorMaoDeObra.toStringAsFixed(2) : '');
    _descontoController = TextEditingController(text: orc != null && orc.desconto > 0 ? orc.desconto.toStringAsFixed(2) : '');

    // Carregar itens existentes ou começar com um vazio
    if (orc != null && orc.itensServico.isNotEmpty) {
      for (final item in orc.itensServico) {
        _itensForm.add(_ItemServicoForm(
          descricao: TextEditingController(text: item.descricao),
          metragem: TextEditingController(text: item.metragem.toStringAsFixed(2)),
          valorUnitario: TextEditingController(text: item.valorUnitario.toStringAsFixed(2)),
        ));
      }
    } else {
      _adicionarItem();
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorMateriaisController.dispose();
    _valorMaoDeObraController.dispose();
    _descontoController.dispose();
    for (final item in _itensForm) {
      item.descricao.dispose();
      item.metragem.dispose();
      item.valorUnitario.dispose();
    }
    super.dispose();
  }

  void _adicionarItem() {
    setState(() {
      _itensForm.add(_ItemServicoForm(
        descricao: TextEditingController(),
        metragem: TextEditingController(),
        valorUnitario: TextEditingController(),
      ));
    });
  }

  void _removerItem(int index) {
    setState(() {
      _itensForm[index].descricao.dispose();
      _itensForm[index].metragem.dispose();
      _itensForm[index].valorUnitario.dispose();
      _itensForm.removeAt(index);
    });
  }

  double _calcularSubtotalItem(int index) {
    final metragem = double.tryParse(_itensForm[index].metragem.text.replaceAll(',', '.')) ?? 0;
    final valorUnitario = double.tryParse(_itensForm[index].valorUnitario.text.replaceAll(',', '.')) ?? 0;
    return metragem * valorUnitario;
  }

  double _calcularTotalItens() {
    double total = 0;
    for (int i = 0; i < _itensForm.length; i++) {
      total += _calcularSubtotalItem(i);
    }
    return total;
  }

  double _calcularValorTotal() {
    final totalItens = _calcularTotalItens();
    final materiais = _materiaisInclusos
        ? (double.tryParse(_valorMateriaisController.text.replaceAll(',', '.')) ?? 0)
        : 0.0;
    final maoDeObra = double.tryParse(_valorMaoDeObraController.text.replaceAll(',', '.')) ?? 0;
    final desconto = double.tryParse(_descontoController.text.replaceAll(',', '.')) ?? 0;
    return totalItens + materiais + maoDeObra - desconto;
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      if (_clienteSelecionado == null && widget.orcamentoParaEdicao == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecione um cliente."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
        return;
      }

      if (_itensForm.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Adicione pelo menos um item de serviço."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
        return;
      }

      final controller = context.read<OrcamentoController>();

      final itens = _itensForm.map((item) {
        final metragem = double.tryParse(item.metragem.text.replaceAll(',', '.')) ?? 0;
        final valorUnitario = double.tryParse(item.valorUnitario.text.replaceAll(',', '.')) ?? 0;
        return ItemServico(
          descricao: item.descricao.text.trim(),
          metragem: metragem,
          valorUnitario: valorUnitario,
        );
      }).toList();

      final orcamento = Orcamento(
        id: widget.orcamentoParaEdicao?.id,
        clienteId: _clienteSelecionado?.id ?? widget.orcamentoParaEdicao?.clienteId ?? '',
        clienteNome: _clienteSelecionado?.nome ?? widget.orcamentoParaEdicao?.clienteNome ?? '',
        descricao: _descricaoController.text.trim(),
        dataCriacao: widget.orcamentoParaEdicao?.dataCriacao ?? DateTime.now(),
        dataValidade: _dataValidade,
        status: _status,
        itensServico: itens,
        materiaisInclusos: _materiaisInclusos,
        valorMateriais: _materiaisInclusos
            ? (double.tryParse(_valorMateriaisController.text.replaceAll(',', '.')) ?? 0)
            : 0,
        valorMaoDeObra: double.tryParse(_valorMaoDeObraController.text.replaceAll(',', '.')) ?? 0,
        desconto: double.tryParse(_descontoController.text.replaceAll(',', '.')) ?? 0,
        formaPagamento: _formaPagamento,
      );

      try {
        await controller.salvar(orcamento);
        if (mounted) {
          // Mostrar dialog de envio ao cliente
          _mostrarDialogEnvio(orcamento);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao salvar: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  // === FORMATAÇÃO DA MENSAGEM ===
  String _formatarMensagem(Orcamento orc) {
    final itensTexto = orc.itensServico.map((item) {
      return "  • ${item.descricao} — ${item.metragem.toStringAsFixed(1)}m² × ${_formatoMoeda.format(item.valorUnitario)} = ${_formatoMoeda.format(item.subtotal)}";
    }).join('\n');

    return '''
📋 *ORÇAMENTO - PaintManager*
━━━━━━━━━━━━━━━━━━━━━━

👤 *Cliente:* ${orc.clienteNome}
📝 *Descrição:* ${orc.descricao}
📅 *Data:* ${DateFormat('dd/MM/yyyy').format(orc.dataCriacao)}
⏳ *Validade:* ${DateFormat('dd/MM/yyyy').format(orc.dataValidade)}

🔧 *Itens de Serviço:*
$itensTexto

💰 *Resumo de Valores:*
  • Serviços: ${_formatoMoeda.format(orc.itensServico.fold<double>(0, (s, i) => s + i.subtotal))}${orc.materiaisInclusos ? '\n  • Materiais: ${_formatoMoeda.format(orc.valorMateriais)}' : ''}
  • Mão de Obra: ${_formatoMoeda.format(orc.valorMaoDeObra)}${orc.desconto > 0 ? '\n  • Desconto: -${_formatoMoeda.format(orc.desconto)}' : ''}

💲 *VALOR TOTAL: ${_formatoMoeda.format(orc.valorTotal)}*

💳 *Pagamento:* ${orc.formaPagamento}

━━━━━━━━━━━━━━━━━━━━━━
Por favor, responda esta mensagem com:
✅ *APROVADO* — para aceitar o orçamento
❌ *REJEITADO* — para recusar o orçamento

_Orçamento gerado pelo PaintManager_
''';
  }

  // === ENVIAR POR WHATSAPP ===
  Future<void> _enviarWhatsApp(Orcamento orc) async {
    final clienteController = context.read<ClienteController>();
    Cliente? cliente;
    await clienteController.clientes.first.then((clientes) {
      cliente = clientes.where((c) => c.id == orc.clienteId).firstOrNull;
    });

    if (cliente == null || cliente!.telefone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cliente sem telefone cadastrado."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    final telefone = cliente!.telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final telefoneCompleto = telefone.length <= 11 ? '55$telefone' : telefone;
    final mensagem = _formatarMensagem(orc);
    final url = Uri.parse('https://wa.me/$telefoneCompleto?text=${Uri.encodeComponent(mensagem)}');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao abrir WhatsApp: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // === ENVIAR POR E-MAIL ===
  Future<void> _enviarEmail(Orcamento orc) async {
    final clienteController = context.read<ClienteController>();
    Cliente? cliente;
    await clienteController.clientes.first.then((clientes) {
      cliente = clientes.where((c) => c.id == orc.clienteId).firstOrNull;
    });

    if (cliente == null || cliente!.email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cliente sem e-mail cadastrado."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    final mensagemEmail = _formatarMensagem(orc).replaceAll('*', '');
    final assunto = 'Orçamento - ${orc.descricao} | PaintManager';
    final url = Uri(
      scheme: 'mailto',
      path: cliente!.email,
      query: 'subject=${Uri.encodeComponent(assunto)}&body=${Uri.encodeComponent(mensagemEmail)}',
    );

    try {
      await launchUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao abrir e-mail: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // === DIALOG DE ENVIO (pós-salvar) ===
  void _mostrarDialogEnvio(Orcamento orc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text("Orçamento Salvo!", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Envie o orçamento para ${orc.clienteNome} aprovar ou recusar:",
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 20),

            // WhatsApp
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _enviarWhatsApp(orc);
                  Navigator.pop(context); // Volta para a lista
                },
                icon: const Icon(Icons.chat, size: 20),
                label: const Text("Enviar por WhatsApp", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // E-mail
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _enviarEmail(orc);
                  Navigator.pop(context); // Volta para a lista
                },
                icon: const Icon(Icons.email_outlined, size: 20),
                label: const Text("Enviar por E-mail", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Enviar depois
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Volta para a lista
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Orçamento salvo! Você pode enviá-lo depois pela listagem."), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                  );
                },
                child: Text("Enviar depois", style: TextStyle(color: Colors.grey[600])),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carregando = context.watch<OrcamentoController>().carregando;
    final isEdicao = widget.orcamentoParaEdicao != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(isEdicao ? "Editar Orçamento" : "Novo Orçamento", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Conteúdo scrollável
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === SEÇÃO 1: DADOS DO CLIENTE ===
                    _buildSectionTitle("Dados do Cliente", Icons.person_outline),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      child: isEdicao
                          ? _buildInfoTile("Cliente", widget.orcamentoParaEdicao!.clienteNome)
                          : _buildClienteDropdown(),
                    ),
                    const SizedBox(height: 24),

                    // === SEÇÃO 2: DETALHES DO ORÇAMENTO ===
                    _buildSectionTitle("Detalhes do Orçamento", Icons.description_outlined),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      child: Column(
                        children: [
                          _buildTextField("Descrição da Obra", _descricaoController, Icons.construction, "Ex: Pintura residencial completa"),
                          const SizedBox(height: 16),
                          _buildDataPicker(),
                          const SizedBox(height: 16),
                          _buildDropdownPagamento(),
                          if (isEdicao) ...[
                            const SizedBox(height: 16),
                            _buildDropdownStatus(),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // === SEÇÃO 3: ITENS DE SERVIÇO ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle("Itens de Serviço", Icons.format_list_numbered),
                        TextButton.icon(
                          onPressed: _adicionarItem,
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text("Adicionar Item"),
                          style: TextButton.styleFrom(foregroundColor: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_itensForm.length, (index) => _buildItemServicoCard(index)),
                    const SizedBox(height: 24),

                    // === SEÇÃO 4: CUSTOS ===
                    _buildSectionTitle("Custos", Icons.attach_money),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Materiais inclusos no orçamento?", style: TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: const Text("Marque se o pintor fornecerá o material", style: TextStyle(fontSize: 12)),
                            value: _materiaisInclusos,
                            activeColor: Colors.black,
                            onChanged: (val) => setState(() => _materiaisInclusos = val),
                          ),
                          if (_materiaisInclusos) ...[
                            const SizedBox(height: 12),
                            _buildMoneyField("Valor dos Materiais", _valorMateriaisController),
                          ],
                          const SizedBox(height: 12),
                          _buildMoneyField("Valor da Mão de Obra", _valorMaoDeObraController),
                          const SizedBox(height: 12),
                          _buildMoneyField("Desconto", _descontoController, obrigatorio: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Espaço para o rodapé fixo
                  ],
                ),
              ),
            ),
          ),

          // === RODAPÉ FIXO ===
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Valor Total", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    Text(
                      _formatoMoeda.format(_calcularValorTotal()),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: carregando ? null : _salvar,
                    icon: carregando
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_outlined, size: 20),
                    label: Text(carregando ? "Salvando..." : "Salvar Orçamento", style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: child,
    );
  }

  Widget _buildClienteDropdown() {
    final clienteController = context.read<ClienteController>();
    return StreamBuilder<List<Cliente>>(
      stream: clienteController.clientes,
      builder: (context, snapshot) {
        final clientes = snapshot.data ?? [];
        return DropdownButtonFormField<Cliente>(
          value: _clienteSelecionado,
          decoration: InputDecoration(
            labelText: "Selecione o Cliente",
            prefixIcon: Icon(Icons.person_outline, size: 20, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
          ),
          items: clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.nome))).toList(),
          onChanged: (val) => setState(() => _clienteSelecionado = val),
          validator: (val) => val == null ? "Selecione um cliente" : null,
        );
      },
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.person_outline, size: 20, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String hint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      ),
      validator: (val) => val == null || val.isEmpty ? "Campo obrigatório" : null,
    );
  }

  Widget _buildDataPicker() {
    return InkWell(
      onTap: () async {
        final data = await showDatePicker(
          context: context,
          initialDate: _dataValidade,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (data != null) setState(() => _dataValidade = data);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Data de Validade",
          prefixIcon: Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(_dataValidade)),
      ),
    );
  }

  Widget _buildDropdownPagamento() {
    return DropdownButtonFormField<String>(
      value: _formaPagamento,
      decoration: InputDecoration(
        labelText: "Forma de Pagamento",
        prefixIcon: Icon(Icons.payment, size: 20, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
      items: ['PIX', 'Cartão', 'Dinheiro', 'Transferência', 'Boleto']
          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
          .toList(),
      onChanged: (val) => setState(() => _formaPagamento = val!),
    );
  }

  Widget _buildDropdownStatus() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: InputDecoration(
        labelText: "Status do Orçamento",
        prefixIcon: Icon(Icons.flag_outlined, size: 20, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
      items: ['Pendente', 'Aprovado', 'Rejeitado', 'Concluído']
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (val) => setState(() => _status = val!),
    );
  }

  Widget _buildItemServicoCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Item ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
              if (_itensForm.length > 1)
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: Colors.red[400]),
                  onPressed: () => _removerItem(index),
                  tooltip: "Remover item",
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _itensForm[index].descricao,
            decoration: _inputDeco("Descrição do ambiente/serviço", Icons.room_outlined),
            validator: (val) => val == null || val.isEmpty ? "Obrigatório" : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _itensForm[index].metragem,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  decoration: _inputDeco("Metragem (m²)", Icons.square_foot),
                  onChanged: (_) => setState(() {}),
                  validator: (val) => val == null || val.isEmpty ? "Obrigatório" : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _itensForm[index].valorUnitario,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  decoration: _inputDeco("Valor/m² (R\$)", Icons.attach_money),
                  onChanged: (_) => setState(() {}),
                  validator: (val) => val == null || val.isEmpty ? "Obrigatório" : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Subtotal: ${_formatoMoeda.format(_calcularSubtotalItem(index))}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyField(String label, TextEditingController controller, {bool obrigatorio = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.attach_money, size: 20, color: Colors.grey[600]),
        prefixText: "R\$ ",
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      ),
      onChanged: (_) => setState(() {}),
      validator: obrigatorio ? (val) => val == null || val.isEmpty ? "Campo obrigatório" : null : null,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
    );
  }
}

/// Classe auxiliar para armazenar os controllers de cada item de serviço no formulário
class _ItemServicoForm {
  final TextEditingController descricao;
  final TextEditingController metragem;
  final TextEditingController valorUnitario;

  _ItemServicoForm({
    required this.descricao,
    required this.metragem,
    required this.valorUnitario,
  });
}
