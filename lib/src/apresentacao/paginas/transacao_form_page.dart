import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/transacao.dart';
import '../../dominio/entidades/cliente.dart';
import '../../dominio/entidades/obra.dart';
import '../controllers/financeiro_controller.dart';
import '../controllers/cliente_controller.dart';
import '../controllers/obra_controller.dart';

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

  Cliente? _clienteSelecionado;
  Obra? _obraSelecionada;

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
  }

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  List<String> get _categoriasAtuais => _tipo == 'Receita' ? _categoriasReceita : _categoriasDespesa;

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      final valor = double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0;
      if (valor <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("O valor deve ser maior que zero."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
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
        clienteId: _clienteSelecionado?.id ?? widget.transacaoParaEdicao?.clienteId,
        clienteNome: _clienteSelecionado?.nome ?? widget.transacaoParaEdicao?.clienteNome,
        obraId: _obraSelecionada?.id ?? widget.transacaoParaEdicao?.obraId,
        obraTitulo: _obraSelecionada?.tituloDaObra ?? widget.transacaoParaEdicao?.obraTitulo,
      );

      try {
        await controller.salvar(transacao);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Transação salva com sucesso!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
          );
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

  @override
  Widget build(BuildContext context) {
    final carregando = context.watch<FinanceiroController>().carregando;
    final isEdicao = widget.transacaoParaEdicao != null;
    final isReceita = _tipo == 'Receita';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(isEdicao ? "Editar Transação" : "Nova ${_tipo}", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === TIPO (Receita / Despesa) ===
              _sectionTitle("Tipo de Transação", Icons.swap_vert),
              const SizedBox(height: 12),
              _card(
                child: Row(
                  children: [
                    Expanded(child: _tipoButton("Receita", Icons.arrow_upward, Colors.green, isReceita)),
                    const SizedBox(width: 12),
                    Expanded(child: _tipoButton("Despesa", Icons.arrow_downward, Colors.red, !isReceita)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === VALOR E DATA ===
              _sectionTitle("Valor e Data", Icons.attach_money),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _valorController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Valor (R\$)",
                        prefixText: "R\$ ",
                        prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isReceita ? Colors.green : Colors.red),
                        prefixIcon: Icon(Icons.attach_money, color: isReceita ? Colors.green : Colors.red),
                        filled: true, fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isReceita ? Colors.green : Colors.red, width: 1.5)),
                      ),
                      validator: (v) => v == null || v.isEmpty ? "Informe o valor" : null,
                    ),
                    const SizedBox(height: 16),
                    _datePicker(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === DETALHES ===
              _sectionTitle("Detalhes", Icons.description_outlined),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _descricaoController,
                      maxLines: 2,
                      decoration: _inputDeco(
                        "Descrição",
                        Icons.edit_note,
                        isReceita ? "Ex: Sinal de 50% da pintura externa" : "Ex: Compra de 2 latas de massa corrida",
                      ),
                      validator: (v) => v == null || v.isEmpty ? "Campo obrigatório" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown("Categoria", _categoria, _categoriasAtuais, Icons.category_outlined, (v) {
                      setState(() => _categoria = v!);
                    }),
                    const SizedBox(height: 16),
                    _buildDropdown("Status", _status, ['Efetivado', 'Pendente', 'Atrasado'], Icons.flag_outlined, (v) {
                      setState(() => _status = v!);
                    }),
                    const SizedBox(height: 16),
                    _buildDropdown("Pagamento", _formaPagamento, ['PIX', 'Cartão de Crédito', 'Dinheiro', 'Boleto', 'Transferência'], Icons.payment, (v) {
                      setState(() => _formaPagamento = v!);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === VINCULAÇÃO (opcional) ===
              _sectionTitle("Vincular (opcional)", Icons.link),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  children: [
                    _clienteDropdown(),
                    const SizedBox(height: 16),
                    _obraDropdown(),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // === BOTÃO SALVAR ===
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: carregando ? null : _salvar,
                  icon: carregando
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined, size: 20),
                  label: Text(carregando ? "Salvando..." : "Salvar Transação", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _sectionTitle(String t, IconData ic) => Row(children: [
    Icon(ic, size: 20, color: Colors.grey[700]), const SizedBox(width: 8),
    Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  ]);

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
    child: child,
  );

  Widget _tipoButton(String label, IconData icon, Color cor, bool selecionado) {
    return InkWell(
      onTap: () => setState(() {
        _tipo = label;
        // Ajustar categoria padrão ao trocar tipo
        _categoria = label == 'Receita' ? 'Mão de Obra' : 'Materiais';
      }),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selecionado ? cor.withValues(alpha: 0.12) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selecionado ? cor : Colors.grey[300]!, width: selecionado ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selecionado ? cor : Colors.grey[400], size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14,
              color: selecionado ? cor : Colors.grey[400],
            )),
          ],
        ),
      ),
    );
  }

  Widget _datePicker() => InkWell(
    onTap: () async {
      final d = await showDatePicker(context: context, initialDate: _dataTransacao,
        firstDate: DateTime(2020), lastDate: DateTime(2030));
      if (d != null) setState(() => _dataTransacao = d);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: "Data da Transação",
        prefixIcon: Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
        filled: true, fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Text(DateFormat('dd/MM/yyyy').format(_dataTransacao)),
    ),
  );

  Widget _buildDropdown(String label, String value, List<String> options, IconData icon, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : options.first,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        filled: true, fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
      items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _clienteDropdown() {
    final cc = context.read<ClienteController>();
    return StreamBuilder<List<Cliente>>(
      stream: cc.clientes,
      builder: (context, snap) {
        final clientes = snap.data ?? [];
        return DropdownButtonFormField<Cliente>(
          value: _clienteSelecionado,
          decoration: InputDecoration(
            labelText: "Vincular ao Cliente (opcional)",
            prefixIcon: Icon(Icons.person_outline, size: 20, color: Colors.grey[600]),
            filled: true, fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
          ),
          items: [
            const DropdownMenuItem<Cliente>(value: null, child: Text("Nenhum", style: TextStyle(color: Colors.grey))),
            ...clientes.map((c) => DropdownMenuItem(value: c, child: Text(c.nome))),
          ],
          onChanged: (v) => setState(() => _clienteSelecionado = v),
        );
      },
    );
  }

  Widget _obraDropdown() {
    final oc = context.read<ObraController>();
    return StreamBuilder<List<Obra>>(
      stream: oc.obras,
      builder: (context, snap) {
        final obras = snap.data ?? [];
        return DropdownButtonFormField<Obra>(
          value: _obraSelecionada,
          decoration: InputDecoration(
            labelText: "Vincular à Obra (opcional)",
            prefixIcon: Icon(Icons.construction, size: 20, color: Colors.grey[600]),
            filled: true, fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
          ),
          items: [
            const DropdownMenuItem<Obra>(value: null, child: Text("Nenhuma", style: TextStyle(color: Colors.grey))),
            ...obras.map((o) => DropdownMenuItem(value: o, child: Text(o.tituloDaObra))),
          ],
          onChanged: (v) => setState(() => _obraSelecionada = v),
        );
      },
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, String hint) => InputDecoration(
    labelText: label, hintText: hint, hintStyle: TextStyle(color: Colors.grey[400]),
    prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
    filled: true, fillColor: Colors.grey[50],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
  );
}
