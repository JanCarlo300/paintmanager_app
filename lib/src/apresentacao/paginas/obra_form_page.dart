import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../modules/obras/dominio/entidades/obra.dart';
import '../../modules/obras/dominio/entidades/etapa_servico.dart';
import '../../modules/clientes/dominio/entidades/cliente.dart';
import '../../modules/obras/apresentacao/controllers/obra_controller.dart';
import '../../modules/clientes/apresentacao/controllers/cliente_controller.dart';

class ObraFormPage extends StatefulWidget {
  final Obra? obraParaEdicao;

  const ObraFormPage({super.key, this.obraParaEdicao});

  @override
  State<ObraFormPage> createState() => _ObraFormPageState();
}

class _ObraFormPageState extends State<ObraFormPage> {
  final _formKey = GlobalKey<FormState>();

  int? _clienteSelecionadoId;
  late TextEditingController _tituloController;
  late TextEditingController _enderecoController;
  late TextEditingController _anotacoesController;
  late TextEditingController _materialController;
  late TextEditingController _clienteSearchController;
  late DateTime _dataInicio;
  late DateTime _dataPrevisao;

  final List<TextEditingController> _etapasControllers = [];
  final List<String> _materiaisFaltantes = [];

  final _etapasPadrao = [
    'Preparação/Emassamento',
    'Lixamento',
    'Primeira Demão',
    'Segunda Demão',
    'Acabamento',
  ];

  @override
  void initState() {
    super.initState();
    final obra = widget.obraParaEdicao;

    // Garantir que a lista de clientes esteja presente
    Future.microtask(() {
      if (mounted) {
        final ctrl = context.read<ClienteController>();
        if (ctrl.clientes.isEmpty && !ctrl.carregando) {
          ctrl.carregarClientes();
        }
      }
    });

    _tituloController = TextEditingController(text: obra?.tituloDaObra);
    _enderecoController = TextEditingController(text: obra?.endereco);
    _anotacoesController = TextEditingController(text: obra?.anotacoes);
    _materialController = TextEditingController();
    _clienteSearchController = TextEditingController();
    _dataInicio = obra?.dataInicio ?? DateTime.now();
    _dataPrevisao = obra?.dataPrevisaoTermino ?? DateTime.now().add(const Duration(days: 15));

    // Pré-popular o ID e o nome do cliente quando em edição
    if (obra != null) {
      _clienteSelecionadoId = obra.idCliente;
    }

    // Aguardar clientes carregarem para preencher o campo de pesquisa com o nome
    if (_clienteSelecionadoId != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final clientes = context.read<ClienteController>().clientes;
        final match = clientes.where((c) => c.id == _clienteSelecionadoId);
        if (match.isNotEmpty) {
          _clienteSearchController.text = match.first.nome;
        } else {
          // Clientes ainda carregando — ouvir mudanças para preencher depois
          void listener() {
            if (!mounted) return;
            final lista = context.read<ClienteController>().clientes;
            final found = lista.where((c) => c.id == _clienteSelecionadoId);
            if (found.isNotEmpty) {
              _clienteSearchController.text = found.first.nome;
              context.read<ClienteController>().removeListener(listener);
            }
          }
          context.read<ClienteController>().addListener(listener);
        }
      });
    }

    if (obra != null && obra.etapasServico.isNotEmpty) {
      for (final etapa in obra.etapasServico) {
        _etapasControllers.add(TextEditingController(text: etapa.nome));
      }
      _materiaisFaltantes.addAll(obra.materiaisFaltantes);
    } else {
      for (final nome in _etapasPadrao) {
        _etapasControllers.add(TextEditingController(text: nome));
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _enderecoController.dispose();
    _anotacoesController.dispose();
    _materialController.dispose();
    _clienteSearchController.dispose();
    for (final c in _etapasControllers) { c.dispose(); }
    super.dispose();
  }

  void _adicionarEtapa() {
    setState(() => _etapasControllers.add(TextEditingController()));
  }

  void _removerEtapa(int index) {
    setState(() {
      _etapasControllers[index].dispose();
      _etapasControllers.removeAt(index);
    });
  }

  void _adicionarMaterial() {
    final texto = _materialController.text.trim();
    if (texto.isNotEmpty) {
      setState(() {
        _materiaisFaltantes.add(texto);
        _materialController.clear();
      });
    }
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      if (_clienteSelecionadoId == null && widget.obraParaEdicao == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Selecione um cliente."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
        return;
      }

      final controller = context.read<ObraController>();
      final etapas = _etapasControllers
          .where((c) => c.text.trim().isNotEmpty)
          .map((c) => EtapaServico(nome: c.text.trim()))
          .toList();

      String nomeCliEncontrado = '';
      if (_clienteSelecionadoId != null) {
        try {
          final cliente = context.read<ClienteController>().clientes.firstWhere((x) => x.id == _clienteSelecionadoId);
          nomeCliEncontrado = cliente.nome;
        } catch (_) {}
      }

      final obra = Obra(
        id: widget.obraParaEdicao?.id,
        idCliente: _clienteSelecionadoId ?? widget.obraParaEdicao?.idCliente ?? 0,
        clienteNome: nomeCliEncontrado.isNotEmpty ? nomeCliEncontrado : (widget.obraParaEdicao?.clienteNome ?? ''),
        tituloDaObra: _tituloController.text.trim(),
        endereco: _enderecoController.text.trim(),
        dataInicio: _dataInicio,
        dataPrevisaoTermino: _dataPrevisao,
        status: widget.obraParaEdicao?.status ?? 'Não Iniciada',
        etapasServico: etapas,
        anotacoes: _anotacoesController.text.trim(),
        materiaisFaltantes: _materiaisFaltantes,
      );

      try {
        await controller.salvar(obra);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Obra salva com sucesso!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
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
    final isEdicao = widget.obraParaEdicao != null;
    final carregando = context.watch<ObraController>().carregando;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(isEdicao ? "Editar Obra" : "Nova Obra", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === SEÇÃO 1: CLIENTE ===
              _sectionTitle("Dados do Cliente", Icons.person_outline),
              const SizedBox(height: 12),
              _card(child: isEdicao
                  ? _readOnlyField("Cliente", widget.obraParaEdicao!.clienteNome)
                  : _clienteDropdown()),
              const SizedBox(height: 24),

              // === SEÇÃO 2: DADOS DA OBRA ===
              _sectionTitle("Dados da Obra", Icons.construction),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  children: [
                    _textField("Título da Obra", _tituloController, Icons.title, "Ex: Pintura Externa Casa Centro"),
                    const SizedBox(height: 16),
                    _textField("Endereço", _enderecoController, Icons.location_on_outlined, "Rua, Número, Bairro, Cidade"),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _datePicker("Data Início", _dataInicio, (d) => setState(() => _dataInicio = d))),
                        const SizedBox(width: 16),
                        Expanded(child: _datePicker("Previsão Término", _dataPrevisao, (d) => setState(() => _dataPrevisao = d))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === SEÇÃO 3: ETAPAS ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle("Etapas do Serviço", Icons.checklist),
                  TextButton.icon(
                    onPressed: _adicionarEtapa,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text("Adicionar"),
                    style: TextButton.styleFrom(foregroundColor: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(_etapasControllers.length, (i) => _etapaCard(i)),
              const SizedBox(height: 24),

              // === SEÇÃO 4: MATERIAIS FALTANTES ===
              _sectionTitle("Materiais Faltantes", Icons.shopping_cart_outlined),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _materialController,
                            decoration: _inputDeco("Ex: Tinta Coral 18L Branca", Icons.add_shopping_cart),
                            onSubmitted: (_) => _adicionarMaterial(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _adicionarMaterial,
                          icon: const Icon(Icons.add_circle, color: Colors.black),
                          tooltip: "Adicionar material",
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _materiaisFaltantes.asMap().entries.map((entry) {
                        return Chip(
                          label: Text(entry.value, style: const TextStyle(fontSize: 13)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => setState(() => _materiaisFaltantes.removeAt(entry.key)),
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: Colors.grey[300]!),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === SEÇÃO 5: ANOTAÇÕES ===
              _sectionTitle("Anotações", Icons.notes),
              const SizedBox(height: 12),
              _card(
                child: TextFormField(
                  controller: _anotacoesController,
                  maxLines: 4,
                  decoration: _inputDeco("Observações, notas do dia, detalhes importantes...", Icons.edit_note),
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
                  label: Text(carregando ? "Salvando..." : "Salvar Obra", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
    child: child,
  );

  Widget _clienteDropdown() {
    final cc = context.watch<ClienteController>();
    final clientes = cc.clientes;

    return FormField<int>(
      initialValue: _clienteSelecionadoId,
      validator: (v) => v == null ? "Selecione um cliente" : null,
      builder: (FormFieldState<int> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return Autocomplete<Cliente>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return clientes;
                    }
                    final query = textEditingValue.text.toLowerCase();
                    return clientes.where(
                      (c) => c.nome.toLowerCase().contains(query),
                    );
                  },
                  displayStringForOption: (Cliente c) => c.nome,
                  onSelected: (Cliente cliente) {
                    setState(() => _clienteSelecionadoId = cliente.id);
                    field.didChange(cliente.id);
                  },
                  fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
                    // Sincronizar o controller externo com o interno do Autocomplete
                    if (_clienteSearchController.text.isNotEmpty && textController.text.isEmpty) {
                      textController.text = _clienteSearchController.text;
                    }
                    // Manter referência para atualizações futuras (edição)
                    _clienteSearchController = textController;

                    return TextFormField(
                      controller: textController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: "Pesquisar Cliente",
                        hintText: "Digite o nome do cliente...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.person_search_outlined, size: 20, color: Colors.grey[600]),
                        suffixIcon: textController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, size: 18, color: Colors.grey[500]),
                                onPressed: () {
                                  textController.clear();
                                  setState(() => _clienteSelecionadoId = null);
                                  field.didChange(null);
                                },
                              )
                            : Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: field.hasError ? Colors.red : Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: field.hasError ? Colors.red : Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: field.hasError ? Colors.red : Colors.black, width: 1.5),
                        ),
                      ),
                      onChanged: (value) {
                        // Se o usuário editar o texto manualmente, limpar a seleção
                        if (_clienteSelecionadoId != null) {
                          final nomeAtual = clientes
                              .where((c) => c.id == _clienteSelecionadoId)
                              .map((c) => c.nome)
                              .firstOrNull;
                          if (value != nomeAtual) {
                            setState(() => _clienteSelecionadoId = null);
                            field.didChange(null);
                          }
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
                            maxHeight: 240,
                            maxWidth: constraints.maxWidth,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                            itemBuilder: (context, index) {
                              final cliente = options.elementAt(index);
                              final isSelected = cliente.id == _clienteSelecionadoId;
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isSelected ? Colors.black : Colors.grey[200],
                                  child: Text(
                                    cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.grey[700],
                                    ),
                                  ),
                                ),
                                title: Text(
                                  cliente.nome,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                subtitle: Text(
                                  cliente.telefone,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                                selected: isSelected,
                                selectedTileColor: Colors.grey[100],
                                onTap: () => onSelected(cliente),
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
            // Mensagem de erro de validação
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

  Widget _readOnlyField(String label, String value) => TextFormField(
    initialValue: value, readOnly: true,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(Icons.person_outline, size: 20, color: Colors.grey[600]),
      filled: true, fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
  );

  Widget _textField(String label, TextEditingController c, IconData ic, String hint) => TextFormField(
    controller: c,
    decoration: InputDecoration(labelText: label, hintText: hint, hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(ic, size: 20, color: Colors.grey[600]),
      filled: true, fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5))),
    validator: (v) => v == null || v.isEmpty ? "Campo obrigatório" : null,
  );

  Widget _datePicker(String label, DateTime data, Function(DateTime) onChanged) => InkWell(
    onTap: () async {
      final d = await showDatePicker(context: context, initialDate: data,
        firstDate: DateTime(2020), lastDate: DateTime(2030));
      if (d != null) onChanged(d);
    },
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
        filled: true, fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!))),
      child: Text(DateFormat('dd/MM/yyyy').format(data)),
    ),
  );

  Widget _etapaCard(int i) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _etapasControllers[i],
            decoration: _inputDeco("Etapa ${i + 1}", Icons.check_circle_outline),
            validator: (v) => v == null || v.isEmpty ? "Obrigatório" : null,
          ),
        ),
        if (_etapasControllers.length > 1)
          IconButton(icon: Icon(Icons.close, size: 18, color: Colors.red[400]), onPressed: () => _removerEtapa(i)),
      ],
    ),
  );

  InputDecoration _inputDeco(String label, IconData ic) => InputDecoration(
    labelText: label, prefixIcon: Icon(ic, size: 20, color: Colors.grey[600]),
    filled: true, fillColor: Colors.grey[50],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
  );
}
