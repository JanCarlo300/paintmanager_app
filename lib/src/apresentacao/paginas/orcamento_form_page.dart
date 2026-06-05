import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../modules/orcamentos/dominio/entidades/orcamento.dart';
import '../../modules/orcamentos/dominio/entidades/item_servico.dart';
import '../../modules/obras/dominio/entidades/obra.dart';
import '../../modules/orcamentos/apresentacao/controllers/orcamento_controller.dart';
import '../../modules/obras/apresentacao/controllers/obra_controller.dart';
import '../../modules/clientes/apresentacao/controllers/cliente_controller.dart';

class OrcamentoFormPage extends StatefulWidget {
  final Orcamento? orcamentoParaEdicao;

  const OrcamentoFormPage({super.key, this.orcamentoParaEdicao});

  @override
  State<OrcamentoFormPage> createState() => _OrcamentoFormPageState();
}

class _OrcamentoFormPageState extends State<OrcamentoFormPage> {
  final _formKey = GlobalKey<FormState>();

  Obra? _obraSelecionada;
  late TextEditingController _obraSearchController;
  late TextEditingController _descricaoController;
  late DateTime _dataValidade;
  String _formaPagamento = 'PIX';
  String _status = 'Pendente';

  final List<_ItemServicoForm> _itensForm = [];

  bool _materiaisInclusos = false;
  late TextEditingController _valorMateriaisController;
  late TextEditingController _valorMaoDeObraController;
  late TextEditingController _descontoController;

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    final orc = widget.orcamentoParaEdicao;

    _obraSearchController = TextEditingController();

    Future.microtask(() {
      if (!mounted) return;
      final obraCtrl = context.read<ObraController>();
      if (obraCtrl.obras.isEmpty && !obraCtrl.carregando) {
        obraCtrl.carregarObras();
      }
      final clienteCtrl = context.read<ClienteController>();
      if (clienteCtrl.clientes.isEmpty && !clienteCtrl.carregando) {
        clienteCtrl.carregarClientes();
      }
    });

    // Pré-popular obra em modo edição
    if (orc != null && orc.idObra != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final obras = context.read<ObraController>().obras;
        final match = obras.where((o) => o.id == orc.idObra);
        if (match.isNotEmpty) {
          setState(() => _obraSelecionada = match.first);
          _obraSearchController.text = match.first.tituloDaObra;
        } else {
          void listener() {
            if (!mounted) return;
            final lista = context.read<ObraController>().obras;
            final found = lista.where((o) => o.id == orc.idObra);
            if (found.isNotEmpty) {
              setState(() => _obraSelecionada = found.first);
              _obraSearchController.text = found.first.tituloDaObra;
              context.read<ObraController>().removeListener(listener);
            }
          }
          context.read<ObraController>().addListener(listener);
        }
      });
    }

    _descricaoController = TextEditingController(text: orc?.descricao);
    _dataValidade = orc?.dataValidade ?? DateTime.now().add(const Duration(days: 30));
    _formaPagamento = orc?.formaPagamento ?? 'PIX';
    final rawStatus = orc?.status ?? 'Pendente';
    // Normaliza 'Rejeitado' → 'Recusado' para compatibilidade com dados antigos
    _status = rawStatus == 'Rejeitado' ? 'Recusado' : rawStatus;
    _materiaisInclusos = orc?.materiaisInclusos ?? false;
    _valorMateriaisController = TextEditingController(
        text: orc != null ? orc.valorMateriais.toStringAsFixed(2) : '');
    _valorMaoDeObraController = TextEditingController(
        text: orc != null ? orc.valorMaoDeObra.toStringAsFixed(2) : '');
    _descontoController = TextEditingController(
        text: orc != null && orc.desconto > 0 ? orc.desconto.toStringAsFixed(2) : '');

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
    _obraSearchController.dispose();
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
    final valorUnitario =
        double.tryParse(_itensForm[index].valorUnitario.text.replaceAll(',', '.')) ?? 0;
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
    final maoDeObra =
        double.tryParse(_valorMaoDeObraController.text.replaceAll(',', '.')) ?? 0;
    final desconto =
        double.tryParse(_descontoController.text.replaceAll(',', '.')) ?? 0;
    return totalItens + materiais + maoDeObra - desconto;
  }

  void _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final obraId = _obraSelecionada?.id ?? widget.orcamentoParaEdicao?.idObra;
    if (obraId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Selecione uma obra para vincular o orçamento."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (_itensForm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Adicione pelo menos um item de serviço."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final itens = _itensForm.map((item) {
      final metragem =
          double.tryParse(item.metragem.text.replaceAll(',', '.')) ?? 0;
      final valorUnitario =
          double.tryParse(item.valorUnitario.text.replaceAll(',', '.')) ?? 0;
      return ItemServico(
        descricao: item.descricao.text.trim(),
        metragem: metragem,
        valorUnitario: valorUnitario,
      );
    }).toList();

    final clienteNome = _obraSelecionada?.clienteNome ??
        widget.orcamentoParaEdicao?.clienteNome ??
        '';

    final orcamento = Orcamento(
      id: widget.orcamentoParaEdicao?.id,
      idObra: obraId,
      clienteNome: clienteNome,
      descricao: _descricaoController.text.trim(),
      dataCriacao: widget.orcamentoParaEdicao?.dataCriacao ?? DateTime.now(),
      dataValidade: _dataValidade,
      status: _status,
      itensServico: itens,
      materiaisInclusos: _materiaisInclusos,
      valorMateriais: _materiaisInclusos
          ? (double.tryParse(_valorMateriaisController.text.replaceAll(',', '.')) ?? 0)
          : 0,
      valorMaoDeObra:
          double.tryParse(_valorMaoDeObraController.text.replaceAll(',', '.')) ?? 0,
      desconto: double.tryParse(_descontoController.text.replaceAll(',', '.')) ?? 0,
      formaPagamento: _formaPagamento,
    );

    try {
      await context.read<OrcamentoController>().salvar(orcamento);
      if (mounted) _mostrarDialogEnvio(orcamento);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erro ao salvar: $e"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

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

  Future<void> _enviarWhatsApp(Orcamento orc) async {
    final clientes = context.read<ClienteController>().clientes;
    final cliente = clientes.where((c) => c.nome == orc.clienteNome).firstOrNull;

    if (cliente == null || cliente.telefone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Cliente sem telefone cadastrado."),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    final telefone = cliente.telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final telefoneCompleto = telefone.length <= 11 ? '55$telefone' : telefone;
    final url = Uri.parse(
        'https://wa.me/$telefoneCompleto?text=${Uri.encodeComponent(_formatarMensagem(orc))}');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erro ao abrir WhatsApp: $e"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _enviarEmail(Orcamento orc) async {
    final clientes = context.read<ClienteController>().clientes;
    final cliente = clientes.where((c) => c.nome == orc.clienteNome).firstOrNull;

    if (cliente == null || cliente.email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Cliente sem e-mail cadastrado."),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    final assunto = 'Orçamento - ${orc.descricao} | PaintManager';
    final url = Uri(
      scheme: 'mailto',
      path: cliente.email,
      query:
          'subject=${Uri.encodeComponent(assunto)}&body=${Uri.encodeComponent(_formatarMensagem(orc).replaceAll('*', ''))}',
    );

    try {
      await launchUrl(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erro ao abrir e-mail: $e"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _mostrarDialogEnvio(Orcamento orc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
                child: Text("Orçamento Salvo!",
                    style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Envie o orçamento para ${orc.clienteNome} aprovar ou recusar:",
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _enviarWhatsApp(orc);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.chat, size: 20),
                label: const Text("Enviar por WhatsApp",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _enviarEmail(orc);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.email_outlined, size: 20),
                label: const Text("Enviar por E-mail",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Orçamento salvo! Você pode enviá-lo depois pela listagem."),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating),
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
        title: Text(isEdicao ? "Editar Orçamento" : "Novo Orçamento",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === SEÇÃO 0: STATUS (só edição) ===
                    if (isEdicao) ...[
                      _buildSectionTitle("Status do Orçamento", Icons.flag_outlined),
                      const SizedBox(height: 12),
                      _buildStatusEditor(),
                      const SizedBox(height: 24),
                    ],

                    // === SEÇÃO 1: OBRA VINCULADA ===
                    _buildSectionTitle("Obra Vinculada", Icons.construction),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      child: isEdicao ? _buildObraReadOnly() : _buildObraSearch(),
                    ),
                    const SizedBox(height: 24),

                    // === SEÇÃO 2: DETALHES DO ORÇAMENTO ===
                    _buildSectionTitle("Detalhes do Orçamento", Icons.description_outlined),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      child: Column(
                        children: [
                          _buildTextField(
                              "Descrição do Serviço",
                              _descricaoController,
                              Icons.construction,
                              "Ex: Pintura residencial completa"),
                          const SizedBox(height: 16),
                          _buildDataPicker(),
                          const SizedBox(height: 16),
                          _buildDropdownPagamento(),
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
                    ...List.generate(_itensForm.length, (i) => _buildItemServicoCard(i)),
                    const SizedBox(height: 24),

                    // === SEÇÃO 4: CUSTOS ===
                    _buildSectionTitle("Custos", Icons.attach_money),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Materiais inclusos no orçamento?",
                                style: TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: const Text("Marque se o pintor fornecerá o material",
                                style: TextStyle(fontSize: 12)),
                            value: _materiaisInclusos,
                            activeThumbColor: Colors.black,
                            onChanged: (val) => setState(() => _materiaisInclusos = val),
                          ),
                          if (_materiaisInclusos) ...[
                            const SizedBox(height: 12),
                            _buildMoneyField("Valor dos Materiais", _valorMateriaisController),
                          ],
                          const SizedBox(height: 12),
                          _buildMoneyField("Valor da Mão de Obra", _valorMaoDeObraController),
                          const SizedBox(height: 12),
                          _buildMoneyField("Desconto", _descontoController,
                              obrigatorio: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
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
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2))
              ],
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
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_outlined, size: 20),
                    label: Text(carregando ? "Salvando..." : "Salvar Orçamento",
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: child,
    );
  }

  /// Busca de obra com autocomplete — filtra por título e nome do cliente
  Widget _buildObraSearch() {
    final obras = context.watch<ObraController>().obras;

    return FormField<int>(
      initialValue: _obraSelecionada?.id,
      validator: (v) => v == null ? "Selecione uma obra" : null,
      builder: (FormFieldState<int> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return Autocomplete<Obra>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return obras;
                    final query = textEditingValue.text.toLowerCase();
                    return obras.where((o) =>
                        o.tituloDaObra.toLowerCase().contains(query) ||
                        o.clienteNome.toLowerCase().contains(query));
                  },
                  displayStringForOption: (Obra o) => o.tituloDaObra,
                  onSelected: (Obra obra) {
                    setState(() => _obraSelecionada = obra);
                    field.didChange(obra.id);
                  },
                  fieldViewBuilder: (context, textController, focusNode, _) {
                    if (_obraSearchController.text.isNotEmpty &&
                        textController.text.isEmpty) {
                      textController.text = _obraSearchController.text;
                    }
                    _obraSearchController = textController;

                    return TextFormField(
                      controller: textController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: "Pesquisar Obra",
                        hintText: "Digite o título ou nome do cliente...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[600]),
                        suffixIcon: textController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    size: 18, color: Colors.grey[500]),
                                onPressed: () {
                                  textController.clear();
                                  setState(() => _obraSelecionada = null);
                                  field.didChange(null);
                                },
                              )
                            : Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: field.hasError ? Colors.red : Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: field.hasError ? Colors.red : Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: field.hasError ? Colors.red : Colors.black,
                              width: 1.5),
                        ),
                      ),
                      onChanged: (value) {
                        if (_obraSelecionada != null &&
                            value != _obraSelecionada!.tituloDaObra) {
                          setState(() => _obraSelecionada = null);
                          field.didChange(null);
                        }
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAlias,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight: 280, maxWidth: constraints.maxWidth),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey[200]),
                            itemBuilder: (context, index) {
                              final obra = options.elementAt(index);
                              final isSelected = obra.id == _obraSelecionada?.id;
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      isSelected ? Colors.black : Colors.grey[200],
                                  child: Icon(Icons.construction,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[700]),
                                ),
                                title: Text(
                                  obra.tituloDaObra,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                subtitle: Text(
                                  "Cliente: ${obra.clienteNome}  •  ${obra.status}",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[500]),
                                ),
                                selected: isSelected,
                                selectedTileColor: Colors.grey[100],
                                onTap: () => onSelected(obra),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // Chip do cliente preenchido automaticamente
            if (_obraSelecionada != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text("Cliente: ",
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600])),
                      Expanded(
                        child: Text(
                          _obraSelecionada!.clienteNome,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  field.errorText!,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Exibição read-only em modo edição
  Widget _buildObraReadOnly() {
    final obraTitle = _obraSelecionada?.tituloDaObra ??
        'Obra #${widget.orcamentoParaEdicao?.idObra}';
    final clienteNome = _obraSelecionada?.clienteNome ??
        widget.orcamentoParaEdicao?.clienteNome ??
        '';
    return Column(
      children: [
        _buildInfoTile("Obra", obraTitle, Icons.construction),
        const SizedBox(height: 12),
        _buildInfoTile("Cliente", clienteNome, Icons.person_outline),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, [IconData icon = Icons.info_outline]) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[100],
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      IconData icon, String hint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black, width: 1.5)),
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
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!)),
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[200]!)),
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
      items: ['Pendente', 'Aprovado', 'Recusado', 'Concluído']
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (val) => setState(() => _status = val!),
    );
  }

  Widget _buildStatusEditor() {
    const statusOptions = [
      _StatusOption('Pendente',  Colors.orange, Icons.hourglass_empty),
      _StatusOption('Aprovado',  Colors.green,  Icons.check_circle_outline),
      _StatusOption('Recusado',  Colors.red,    Icons.cancel_outlined),
      _StatusOption('Concluído', Colors.blue,   Icons.done_all),
    ];

    return _buildSectionCard(
      child: Row(
        children: statusOptions.map((opt) {
          final isSelected = _status == opt.valor;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _status = opt.valor),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? opt.cor.withValues(alpha: 0.12)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? opt.cor : Colors.grey[300]!,
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(opt.icone,
                        size: 22,
                        color: isSelected ? opt.cor : Colors.grey[400]),
                    const SizedBox(height: 5),
                    Text(
                      opt.valor,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? opt.cor : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemServicoCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Item ${index + 1}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey[700])),
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
                  ],
                  decoration: _inputDeco("Metragem (m²)", Icons.square_foot),
                  onChanged: (_) => setState(() {}),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Obrigatório" : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _itensForm[index].valorUnitario,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
                  ],
                  decoration: _inputDeco("Valor/m² (R\$)", Icons.attach_money),
                  onChanged: (_) => setState(() {}),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Obrigatório" : null,
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

  Widget _buildMoneyField(String label, TextEditingController controller,
      {bool obrigatorio = true}) {
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black, width: 1.5)),
      ),
      onChanged: (_) => setState(() {}),
      validator: obrigatorio
          ? (val) => val == null || val.isEmpty ? "Campo obrigatório" : null
          : null,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black, width: 1.5)),
    );
  }
}

class _StatusOption {
  final String valor;
  final Color cor;
  final IconData icone;
  const _StatusOption(this.valor, this.cor, this.icone);
}

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
