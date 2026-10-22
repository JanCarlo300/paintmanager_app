import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../dominio/entidades/transacao.dart';
import '../../../clientes/dominio/entidades/cliente.dart';
import '../../../obras/dominio/entidades/obra.dart';
import '../controllers/financeiro_controller.dart';
import '../../../clientes/apresentacao/controllers/cliente_controller.dart';
import '../../../obras/apresentacao/controllers/obra_controller.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';
import '../../../../apresentacao/widgets/campo_data.dart';
import '../../../../apresentacao/widgets/campo_busca_selecao.dart';

class TransacaoFormPage extends StatefulWidget {
  final Transacao? transacaoParaEdicao;
  final String? tipoInicial;

  const TransacaoFormPage({super.key, this.transacaoParaEdicao, this.tipoInicial});

  @override
  State<TransacaoFormPage> createState() => _TransacaoFormPageState();
}

class _TransacaoFormPageState extends State<TransacaoFormPage> {
  final _formKey = GlobalKey<FormState>();

  late String _tipo;
  late String _categoria;
  late String _status;
  late String _formaPagamento;
  late TextEditingController _valorController;
  late TextEditingController _descricaoController;
  late DateTime _dataTransacao;

  int? _clienteId;
  String? _clienteNome;
  // RF011: vínculo real com a obra (antes só o título era guardado).
  int? _obraId;
  String? _obraTitulo;

  final _categoriasReceita = ['Mão de Obra', 'Outros'];
  final _categoriasDespesa = ['Materiais', 'Ferramentas', 'Transporte', 'Alimentação', 'Outros'];

  @override
  void initState() {
    super.initState();
    final t = widget.transacaoParaEdicao;

    _tipo = t?.tipo ?? widget.tipoInicial ?? 'Receita';
    _categoria = t?.categoria ?? (_tipo == 'Receita' ? 'Mão de Obra' : 'Materiais');
    _status = t?.status ?? 'Efetivado';
    _formaPagamento = t?.formaPagamento ?? 'PIX';
    _valorController = TextEditingController(text: t != null ? t.valor.toStringAsFixed(2) : '');
    _descricaoController = TextEditingController(text: t?.descricao);
    _dataTransacao = t?.dataTransacao ?? DateTime.now();
    _obraId = t?.idObra;
    _obraTitulo = (t?.obraTitulo?.isNotEmpty ?? false) ? t!.obraTitulo : null;
    _clienteId = t?.idCliente;
    _clienteNome = (t?.clienteNome?.isNotEmpty ?? false) ? t!.clienteNome : null;
  }

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  List<String> get _categoriasAtuais => _tipo == 'Receita' ? _categoriasReceita : _categoriasDespesa;

  void _avisarErro(String mensagem) {
    final c = context.cores;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem, style: TextStyle(color: c.onError)), backgroundColor: c.error),
    );
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      final valor = double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0;
      if (valor <= 0) {
        _avisarErro("O valor deve ser maior que zero.");
        return;
      }

      final controller = context.read<FinanceiroController>();

      final transacao = Transacao(
        id: widget.transacaoParaEdicao?.id,
        tipo: _tipo,
        categoria: _categoria,
        valor: valor,
        descricao: _descricaoController.text.trim(),
        dataTransacao: _dataTransacao,
        status: _status,
        formaPagamento: _formaPagamento,
        idCliente: _clienteId,
        clienteNome: _clienteNome,
        idObra: _obraId,
        obraTitulo: _obraTitulo,
      );

      try {
        await controller.salvar(transacao);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Transação salva com sucesso!")),
          );
        }
      } catch (e) {
        if (mounted) _avisarErro("Erro ao salvar: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final carregando = context.watch<FinanceiroController>().carregando;
    final isEdicao = widget.transacaoParaEdicao != null;
    final isReceita = _tipo == 'Receita';
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final corTipo = isReceita ? c.success : c.error;

    return Scaffold(
      appBar: AppBar(title: Text(isEdicao ? "Editar Transação" : "Nova $_tipo")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Espaco.margemTela),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === TIPO (Receita / Despesa) ===
              _sectionTitle("Tipo de Transação", Symbols.swap_vert_rounded),
              const SizedBox(height: Espaco.x3),
              _card(
                child: Row(
                  children: [
                    Expanded(child: _tipoButton("Receita", Symbols.arrow_upward_rounded, c.success, c.successSoft, isReceita)),
                    const SizedBox(width: Espaco.x3),
                    Expanded(child: _tipoButton("Despesa", Symbols.arrow_downward_rounded, c.error, c.errorSoft, !isReceita)),
                  ],
                ),
              ),
              const SizedBox(height: Espaco.x6),

              // === VALOR E DATA ===
              _sectionTitle("Valor e Data", Symbols.payments_rounded),
              const SizedBox(height: Espaco.x3),
              _card(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _valorController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                      style: texto.displayMedium,
                      decoration: InputDecoration(
                        labelText: "Valor (R\$)",
                        prefixText: "R\$ ",
                        prefixStyle: texto.displayMedium?.copyWith(color: corTipo),
                        prefixIcon: Icon(Symbols.payments_rounded, color: corTipo),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Raio.campo),
                          borderSide: BorderSide(color: corTipo, width: 1.5),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty ? "Informe o valor" : null,
                    ),
                    const SizedBox(height: Espaco.x4),
                    _datePicker(),
                  ],
                ),
              ),
              const SizedBox(height: Espaco.x6),

              // === DETALHES ===
              _sectionTitle("Detalhes", Symbols.description_rounded),
              const SizedBox(height: Espaco.x3),
              _card(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _descricaoController,
                      maxLines: 2,
                      decoration: _inputDeco(
                        "Descrição",
                        Symbols.edit_note_rounded,
                        isReceita ? "Ex: Sinal de 50% da pintura externa" : "Ex: Compra de 2 latas de massa corrida",
                      ),
                      validator: (v) => v == null || v.isEmpty ? "Campo obrigatório" : null,
                    ),
                    const SizedBox(height: Espaco.x4),
                    _buildDropdown("Categoria", _categoria, _categoriasAtuais, Symbols.category_rounded, (v) {
                      setState(() => _categoria = v!);
                    }),
                    const SizedBox(height: Espaco.x4),
                    _buildDropdown("Status", _status, ['Efetivado', 'Pendente', 'Atrasado'], Symbols.flag_rounded, (v) {
                      setState(() => _status = v!);
                    }),
                    const SizedBox(height: Espaco.x4),
                    _buildDropdown("Pagamento", _formaPagamento, ['PIX', 'Cartão de Crédito', 'Dinheiro', 'Boleto', 'Transferência'], Symbols.credit_card_rounded, (v) {
                      setState(() => _formaPagamento = v!);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: Espaco.x6),

              // === VINCULAÇÃO (opcional) ===
              _sectionTitle("Vincular (opcional)", Symbols.link_rounded),
              const SizedBox(height: Espaco.x3),
              _card(
                child: Column(
                  children: [
                    _obraDropdown(),
                    const SizedBox(height: Espaco.x4),
                    _clienteDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: Espaco.x8),

              // === BOTÃO SALVAR ===
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: carregando ? null : _salvar,
                  icon: carregando
                      ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: c.inkMuted, strokeWidth: 2))
                      : const Icon(Symbols.save_rounded, size: TamanhoIcone.pequeno),
                  label: Text(carregando ? "Salvando..." : "Salvar Transação"),
                ),
              ),
              const SizedBox(height: Espaco.x6),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _sectionTitle(String t, IconData ic) => Row(children: [
    Icon(ic, size: TamanhoIcone.pequeno, color: context.cores.primary), const SizedBox(width: Espaco.x2),
    Flexible(child: Text(t, style: Theme.of(context).textTheme.titleMedium)),
  ]);

  Widget _card({required Widget child}) => SizedBox(
    width: double.infinity,
    child: CardApp(child: child),
  );

  Widget _tipoButton(String label, IconData icon, Color cor, Color fundo, bool selecionado) {
    final c = context.cores;
    return InkWell(
      onTap: () => setState(() {
        _tipo = label;
        // Ajustar categoria padrão ao trocar tipo
        _categoria = label == 'Receita' ? 'Mão de Obra' : 'Materiais';
      }),
      borderRadius: BorderRadius.circular(Raio.botao),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Espaco.x4),
        decoration: BoxDecoration(
          color: selecionado ? fundo : c.surfaceSunken,
          borderRadius: BorderRadius.circular(Raio.botao),
          border: Border.all(color: selecionado ? cor : c.border, width: selecionado ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selecionado ? cor : c.inkMuted, size: 28),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: selecionado ? cor : c.inkMuted,
            )),
          ],
        ),
      ),
    );
  }

  Widget _datePicker() => CampoData(
    rotulo: "Data da transação",
    data: _dataTransacao,
    tituloCalendario: "Data da transação",
    aoMudar: (d) => setState(() => _dataTransacao = d),
  );

  // Campos: fundo, borda, foco e erro vêm do tema (InputDecorationTheme).
  Widget _buildDropdown(String label, String currentValue, List<String> options, IconData icon, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: options.contains(currentValue) ? currentValue : options.first,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: TamanhoIcone.pequeno),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _clienteDropdown() {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    // Com obra vinculada, o cliente é o da obra (não pode divergir dela).
    if (_obraId != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Espaco.x3),
        decoration: BoxDecoration(
          color: c.disabledBg,
          borderRadius: BorderRadius.circular(Raio.campo),
        ),
        child: Row(
          children: [
            Icon(Symbols.person_rounded, size: TamanhoIcone.pequeno, color: c.inkMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Cliente (da obra)", style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0)),
                  Text(
                    (_clienteNome?.isNotEmpty ?? false) ? _clienteNome! : '—',
                    style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Ao desvincular a obra este campo nasce de novo, já com o cliente que veio dela.
    return CampoBuscaSelecao<Cliente>(
      rotulo: "Vincular ao Cliente (opcional)",
      dica: "Nome, CPF ou telefone do cliente...",
      icone: Symbols.person_search_rounded,
      textoInicial: _clienteNome,
      buscar: context.read<ClienteController>().buscar,
      tituloDe: (c) => c.nome,
      subtituloDe: (c) => c.telefone,
      aoSelecionar: (c) => setState(() {
        _clienteId = c.id;
        _clienteNome = c.nome;
      }),
      aoLimpar: () => setState(() {
        _clienteId = null;
        _clienteNome = null;
      }),
    );
  }

  Widget _obraDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampoBuscaSelecao<Obra>(
          rotulo: "Vincular à Obra (opcional)",
          dica: "Título da obra ou nome do cliente...",
          icone: Symbols.construction_rounded,
          iconeItem: Symbols.construction_rounded,
          textoInicial: _obraTitulo,
          buscar: context.read<ObraController>().buscarObrasParaLancamento,
          tituloDe: (o) => o.tituloDaObra,
          subtituloDe: (o) => "Cliente: ${o.clienteNome}  •  ${o.status}",
          aoSelecionar: (o) => setState(() {
            _obraId = o.id;
            _obraTitulo = o.tituloDaObra;
            _clienteId = o.idCliente;
            _clienteNome = o.clienteNome;
          }),
          aoLimpar: () => setState(() {
            _obraId = null;
            _obraTitulo = null;
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(left: Espaco.x1, top: 6),
          child: Text(
            "Só aparecem obras Em Andamento ou Concluídas.",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.cores.inkMuted, letterSpacing: 0),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, size: TamanhoIcone.pequeno),
  );
}
