import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../dominio/entidades/orcamento.dart';
import '../../dominio/entidades/item_servico.dart';
import '../../../obras/dominio/entidades/obra.dart';
import '../controllers/orcamento_controller.dart';
import '../../../obras/apresentacao/controllers/obra_controller.dart';
import '../../../clientes/apresentacao/controllers/cliente_controller.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';
import '../../../../core/tema/status_visual.dart';
import '../../../../apresentacao/widgets/campo_busca_selecao.dart';
import '../../../../apresentacao/widgets/campo_data.dart';

class OrcamentoFormPage extends StatefulWidget {
  final Orcamento? orcamentoParaEdicao;

  const OrcamentoFormPage({super.key, this.orcamentoParaEdicao});

  @override
  State<OrcamentoFormPage> createState() => _OrcamentoFormPageState();
}

class _OrcamentoFormPageState extends State<OrcamentoFormPage> {
  final _formKey = GlobalKey<FormState>();

  Obra? _obraSelecionada;
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
        } else {
          void listener() {
            if (!mounted) return;
            final lista = context.read<ObraController>().obras;
            final found = lista.where((o) => o.id == orc.idObra);
            if (found.isNotEmpty) {
              setState(() => _obraSelecionada = found.first);
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
    _status = orc?.status ?? 'Pendente';
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

  void _avisarErro(String mensagem) {
    final c = context.cores;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem, style: TextStyle(color: c.onError)), backgroundColor: c.error),
    );
  }

  void _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final obraId = _obraSelecionada?.id ?? widget.orcamentoParaEdicao?.idObra;
    if (obraId == null) {
      _avisarErro("Selecione uma obra para vincular o orçamento.");
      return;
    }

    if (_itensForm.isEmpty) {
      _avisarErro("Adicione pelo menos um item de serviço.");
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

    // Recusado editado = nova proposta para o cliente: volta a aguardar resposta.
    final reenvio = widget.orcamentoParaEdicao?.status == 'Recusado' && _status == 'Recusado';

    final orcamento = Orcamento(
      id: widget.orcamentoParaEdicao?.id,
      idObra: obraId,
      clienteNome: clienteNome,
      descricao: _descricaoController.text.trim(),
      dataCriacao: widget.orcamentoParaEdicao?.dataCriacao ?? DateTime.now(),
      dataValidade: _dataValidade,
      status: reenvio ? 'Pendente' : _status,
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
      if (!mounted) return;
      if (reenvio) {
        setState(() => _status = 'Pendente');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Orçamento recusado foi editado: status voltou para Pendente.")),
        );
      }
      _mostrarDialogEnvio(orcamento);
    } catch (e) {
      if (mounted) _avisarErro("Erro ao salvar: $e");
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
      if (mounted) _avisarErro("Cliente sem telefone cadastrado.");
      return;
    }

    final telefone = cliente.telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final telefoneCompleto = telefone.length <= 11 ? '55$telefone' : telefone;
    final url = Uri.parse(
        'https://wa.me/$telefoneCompleto?text=${Uri.encodeComponent(_formatarMensagem(orc))}');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) _avisarErro("Erro ao abrir WhatsApp: $e");
    }
  }

  Future<void> _enviarEmail(Orcamento orc) async {
    final clientes = context.read<ClienteController>().clientes;
    final cliente = clientes.where((c) => c.nome == orc.clienteNome).firstOrNull;

    if (cliente == null || cliente.email.isEmpty) {
      if (mounted) _avisarErro("Cliente sem e-mail cadastrado.");
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
      if (mounted) _avisarErro("Erro ao abrir e-mail: $e");
    }
  }

  void _mostrarDialogEnvio(Orcamento orc) {
    final c = context.cores;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: c.successSoft,
              child: Icon(Symbols.check_circle_rounded, fill: 1, color: c.success, size: 28),
            ),
            const SizedBox(width: Espaco.x3),
            const Expanded(child: Text("Orçamento Salvo!")),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Envie o orçamento para ${orc.clienteNome} aprovar ou recusar:",
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: Espaco.x5),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _enviarWhatsApp(orc);
                  Navigator.pop(context);
                },
                icon: const Icon(Symbols.chat_rounded, size: TamanhoIcone.pequeno),
                label: const Text("Enviar por WhatsApp"),
                style: FilledButton.styleFrom(backgroundColor: c.success, foregroundColor: c.onPrimary),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _enviarEmail(orc);
                  Navigator.pop(context);
                },
                icon: const Icon(Symbols.mail_rounded, size: TamanhoIcone.pequeno),
                label: const Text("Enviar por E-mail"),
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
                        content: Text("Orçamento salvo! Você pode enviá-lo depois pela listagem.")),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: c.inkMuted),
                child: const Text("Enviar depois"),
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
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(isEdicao ? "Editar Orçamento" : "Novo Orçamento")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Espaco.margemTela),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === SEÇÃO 0: STATUS (só edição) ===
                    if (isEdicao) ...[
                      _buildSectionTitle("Status do Orçamento", Symbols.flag_rounded),
                      const SizedBox(height: Espaco.x3),
                      _buildStatusEditor(),
                      const SizedBox(height: Espaco.x6),
                    ],

                    // === SEÇÃO 1: OBRA VINCULADA ===
                    _buildSectionTitle("Obra Vinculada", Symbols.construction_rounded),
                    const SizedBox(height: Espaco.x3),
                    _buildSectionCard(
                      child: isEdicao ? _buildObraReadOnly() : _buildObraSearch(),
                    ),
                    const SizedBox(height: Espaco.x6),

                    // === SEÇÃO 2: DETALHES DO ORÇAMENTO ===
                    _buildSectionTitle("Detalhes do Orçamento", Symbols.description_rounded),
                    const SizedBox(height: Espaco.x3),
                    _buildSectionCard(
                      child: Column(
                        children: [
                          _buildTextField(
                              "Descrição do Serviço",
                              _descricaoController,
                              Symbols.construction_rounded,
                              "Ex: Pintura residencial completa"),
                          const SizedBox(height: Espaco.x4),
                          _buildDataPicker(),
                          const SizedBox(height: Espaco.x4),
                          _buildDropdownPagamento(),
                        ],
                      ),
                    ),
                    const SizedBox(height: Espaco.x6),

                    // === SEÇÃO 3: ITENS DE SERVIÇO ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: _buildSectionTitle("Itens de Serviço", Symbols.format_list_numbered_rounded)),
                        TextButton.icon(
                          onPressed: _adicionarItem,
                          icon: const Icon(Symbols.add_circle_rounded, size: TamanhoIcone.pequeno),
                          label: const Text("Adicionar Item"),
                        ),
                      ],
                    ),
                    const SizedBox(height: Espaco.x3),
                    ...List.generate(_itensForm.length, (i) => _buildItemServicoCard(i)),
                    const SizedBox(height: Espaco.x6),

                    // === SEÇÃO 4: CUSTOS ===
                    _buildSectionTitle("Custos", Symbols.payments_rounded),
                    const SizedBox(height: Espaco.x3),
                    _buildSectionCard(
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Materiais inclusos no orçamento?"),
                            subtitle: Text(
                              "Marque se o pintor fornecerá o material",
                              style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0),
                            ),
                            value: _materiaisInclusos,
                            onChanged: (val) => setState(() => _materiaisInclusos = val),
                          ),
                          if (_materiaisInclusos) ...[
                            const SizedBox(height: Espaco.x3),
                            _buildMoneyField("Valor dos Materiais", _valorMateriaisController),
                          ],
                          const SizedBox(height: Espaco.x3),
                          _buildMoneyField("Valor da Mão de Obra", _valorMaoDeObraController),
                          const SizedBox(height: Espaco.x3),
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

          // === RODAPÉ FIXO (sem sombra: só uma borda separa do conteúdo) ===
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Espaco.x4, vertical: Espaco.x3),
            decoration: BoxDecoration(
              color: c.surfaceCard,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Valor Total", style: texto.bodyMedium?.copyWith(color: c.inkMuted)),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatoMoeda.format(_calcularValorTotal()),
                            style: texto.displayMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: carregando ? null : _salvar,
                      icon: carregando
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: c.inkMuted, strokeWidth: 2))
                          : const Icon(Symbols.save_rounded, size: TamanhoIcone.pequeno),
                      label: Text(carregando ? "Salvando..." : "Salvar Orçamento"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: TamanhoIcone.pequeno, color: context.cores.primary),
        const SizedBox(width: Espaco.x2),
        Flexible(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
      ],
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return SizedBox(width: double.infinity, child: CardApp(child: child));
  }

  /// Busca de obra no banco — filtra por título e nome do cliente
  Widget _buildObraSearch() {
    final obraController = context.read<ObraController>();
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampoBuscaSelecao<Obra>(
          rotulo: "Pesquisar Obra",
          dica: "Digite o título ou nome do cliente...",
          icone: Symbols.search_rounded,
          iconeItem: Symbols.construction_rounded,
          mensagemObrigatorio: "Selecione uma obra",
          buscar: obraController.buscarObras,
          tituloDe: (o) => o.tituloDaObra,
          subtituloDe: (o) => "Cliente: ${o.clienteNome}  •  ${o.status}",
          aoSelecionar: (obra) => setState(() => _obraSelecionada = obra),
          aoLimpar: () => setState(() => _obraSelecionada = null),
        ),
        // Chip do cliente preenchido automaticamente
        if (_obraSelecionada != null)
          Padding(
            padding: const EdgeInsets.only(top: Espaco.x3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Espaco.x3, vertical: 10),
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(Raio.campo),
              ),
              child: Row(
                children: [
                  Icon(Symbols.person_rounded, size: 16, color: c.primary),
                  const SizedBox(width: Espaco.x2),
                  Text("Cliente: ", style: texto.bodyMedium?.copyWith(color: c.inkMuted)),
                  Expanded(
                    child: Text(
                      _obraSelecionada!.clienteNome,
                      style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
        _buildInfoTile("Obra", obraTitle, Symbols.construction_rounded),
        const SizedBox(height: Espaco.x3),
        _buildInfoTile("Cliente", clienteNome, Symbols.person_rounded),
      ],
    );
  }

  // Campos: fundo, borda, foco e erro vêm do tema (InputDecorationTheme).
  Widget _buildInfoTile(String label, String value, [IconData icon = Symbols.info_rounded]) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: TamanhoIcone.pequeno),
        fillColor: context.cores.disabledBg,
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
        prefixIcon: Icon(icon, size: TamanhoIcone.pequeno),
      ),
      validator: (val) => val == null || val.isEmpty ? "Campo obrigatório" : null,
    );
  }

  Widget _buildDataPicker() {
    return CampoData(
      rotulo: "Validade do orçamento",
      data: _dataValidade,
      tituloCalendario: "Validade do orçamento",
      icone: Symbols.event_rounded,
      primeiraData: DateUtils.dateOnly(DateTime.now()),
      ultimaData: DateTime.now().add(const Duration(days: 365)),
      aoMudar: (d) => setState(() => _dataValidade = d),
    );
  }

  Widget _buildDropdownPagamento() {
    return DropdownButtonFormField<String>(
      value: _formaPagamento,
      decoration: const InputDecoration(
        labelText: "Forma de Pagamento",
        prefixIcon: Icon(Symbols.credit_card_rounded, size: TamanhoIcone.pequeno),
      ),
      items: ['PIX', 'Cartão', 'Dinheiro', 'Transferência', 'Boleto']
          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
          .toList(),
      onChanged: (val) => setState(() => _formaPagamento = val!),
    );
  }

  // Os 3 status do DERS, com cor e ícone de core/tema/status_visual.dart.
  Widget _buildStatusEditor() {
    const statusOptions = ['Pendente', 'Aprovado', 'Recusado'];
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return _buildSectionCard(
      child: Row(
        children: statusOptions.map((valor) {
          final visual = visualDoStatus(valor, c);
          final isSelected = _status == valor;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _status = valor),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: Espaco.x1),
                padding: const EdgeInsets.symmetric(vertical: Espaco.x3),
                decoration: BoxDecoration(
                  color: isSelected ? visual.fundo : c.surfaceSunken,
                  borderRadius: BorderRadius.circular(Raio.botao),
                  border: Border.all(
                    color: isSelected ? visual.cor : c.border,
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      visual.icone,
                      size: 22,
                      fill: isSelected ? 1 : 0,
                      color: isSelected ? visual.cor : c.inkMuted,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      valor,
                      textAlign: TextAlign.center,
                      style: texto.labelSmall?.copyWith(
                        letterSpacing: 0,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? visual.cor : c.inkMuted,
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
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.x3),
      child: CardApp(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Item ${index + 1}", style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted)),
                if (_itensForm.length > 1)
                  IconButton(
                    icon: Icon(Symbols.close_rounded, size: 18, color: c.error),
                    onPressed: () => _removerItem(index),
                    tooltip: "Remover item",
                  ),
              ],
            ),
            const SizedBox(height: Espaco.x2),
            TextFormField(
              controller: _itensForm[index].descricao,
              decoration: _inputDeco("Descrição do ambiente/serviço", Symbols.meeting_room_rounded),
              validator: (val) => val == null || val.isEmpty ? "Obrigatório" : null,
            ),
            const SizedBox(height: Espaco.x3),
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
                    decoration: _inputDeco("Metragem (m²)", Symbols.square_foot_rounded),
                    onChanged: (_) => setState(() {}),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Obrigatório" : null,
                  ),
                ),
                const SizedBox(width: Espaco.x3),
                Expanded(
                  child: TextFormField(
                    controller: _itensForm[index].valorUnitario,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))
                    ],
                    decoration: _inputDeco("Valor/m² (R\$)", Symbols.payments_rounded),
                    onChanged: (_) => setState(() {}),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Obrigatório" : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Espaco.x2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Subtotal: ${_formatoMoeda.format(_calcularSubtotalItem(index))}",
                style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
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
        prefixIcon: const Icon(Symbols.payments_rounded, size: TamanhoIcone.pequeno),
        prefixText: "R\$ ",
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
      prefixIcon: Icon(icon, size: TamanhoIcone.pequeno),
    );
  }
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
