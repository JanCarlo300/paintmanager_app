import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/obra.dart';
import '../../dominio/entidades/etapa_servico.dart';
import '../../../clientes/dominio/entidades/cliente.dart';
import '../controllers/obra_controller.dart';
import '../../../clientes/apresentacao/controllers/cliente_controller.dart';
import '../../../../core/tema/paleta_sahara.dart';
import '../../../../core/servicos/geocodificacao_service.dart';
import '../../../../apresentacao/widgets/campo_busca_selecao.dart';
import '../../../../apresentacao/widgets/campo_data.dart';

class ObraFormPage extends StatefulWidget {
  final Obra? obraParaEdicao;

  const ObraFormPage({super.key, this.obraParaEdicao});

  @override
  State<ObraFormPage> createState() => _ObraFormPageState();
}

class _ObraFormPageState extends State<ObraFormPage> {
  final _formKey = GlobalKey<FormState>();

  int? _clienteSelecionadoId;
  String _clienteNomeSelecionado = '';
  late TextEditingController _tituloController;
  late TextEditingController _enderecoController;
  late TextEditingController _materialController;
  late DateTime _dataInicio;
  late DateTime _dataPrevisao;

  final List<TextEditingController> _etapasControllers = [];
  final List<String> _materiaisFaltantes = [];

  bool get _obraConcluida => widget.obraParaEdicao?.status == 'Concluída';

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

    _tituloController = TextEditingController(text: obra?.tituloDaObra);
    _enderecoController = TextEditingController(text: obra?.endereco);
    _materialController = TextEditingController();
    _dataInicio = obra?.dataInicio ?? DateTime.now();
    _dataPrevisao = obra?.dataPrevisaoTermino ?? DateTime.now().add(const Duration(days: 15));

    // Em edição o cliente já vem escolhido (o nome está guardado na própria obra)
    if (obra != null) {
      _clienteSelecionadoId = obra.idCliente;
      _clienteNomeSelecionado = obra.clienteNome;
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
    _materialController.dispose();
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

      if (DateUtils.dateOnly(_dataPrevisao).isBefore(DateUtils.dateOnly(_dataInicio))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("A previsão de término não pode ser anterior à data de início."),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final controller = context.read<ObraController>();
      final original = widget.obraParaEdicao;
      // Na edição, cada etapa mantém se já estava concluída (pelo nome);
      // antes o formulário recriava todas como pendentes e zerava o progresso.
      final jaConcluidas = {
        for (final e in original?.etapasServico ?? const <EtapaServico>[])
          if (e.concluida) e.nome.trim(),
      };
      final etapas = _obraConcluida
          ? original!.etapasServico
          : _etapasControllers
              .map((c) => c.text.trim())
              .where((nome) => nome.isNotEmpty)
              .map((nome) => EtapaServico(nome: nome, concluida: jaConcluidas.contains(nome)))
              .toList();

      final enderecoDigitado = _enderecoController.text.trim();

      // Item 3.2 — geocodifica o endereço (gratuito, via OpenStreetMap/Nominatim).
      // Se falhar (sem internet, endereço não encontrado), mantém a coordenada
      // anterior em vez de apagar o que já tinha funcionado antes.
      final coordenada = await GeocodificacaoService().buscarCoordenadas(enderecoDigitado);

      final obra = Obra(
        id: widget.obraParaEdicao?.id,
        idOrcamento: widget.obraParaEdicao?.idOrcamento,
        dataConclusao: widget.obraParaEdicao?.dataConclusao,
        idCliente: _clienteSelecionadoId ?? widget.obraParaEdicao?.idCliente ?? 0,
        clienteNome: _clienteNomeSelecionado,
        tituloDaObra: _tituloController.text.trim(),
        endereco: enderecoDigitado,
        dataInicio: _dataInicio,
        dataPrevisaoTermino: _dataPrevisao,
        status: widget.obraParaEdicao?.status ?? 'Não Iniciada',
        etapasServico: etapas,
        materiaisFaltantes: _materiaisFaltantes,
        latitude: coordenada?.latitude ?? widget.obraParaEdicao?.latitude,
        longitude: coordenada?.longitude ?? widget.obraParaEdicao?.longitude,
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
      backgroundColor: PaletaSahara.background,
      appBar: AppBar(
        title: Text(isEdicao ? "Editar Obra" : "Nova Obra", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: PaletaSahara.cardSurface,
        foregroundColor: PaletaSahara.onSurface,
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
                    _periodoDaObra(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // === SEÇÃO 3: ETAPAS ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle("Etapas do Serviço", Icons.checklist),
                  if (!_obraConcluida)
                    TextButton.icon(
                      onPressed: _adicionarEtapa,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text("Adicionar"),
                      style: TextButton.styleFrom(foregroundColor: PaletaSahara.primary),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_obraConcluida)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text("Obra concluída: etapas bloqueadas",
                          style: TextStyle(fontSize: 13, color: Colors.blue[800])),
                    ],
                  ),
                ),
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
                          icon: const Icon(Icons.add_circle, color: PaletaSahara.primary),
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
                    backgroundColor: PaletaSahara.primary,
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
    decoration: BoxDecoration(color: PaletaSahara.cardSurface, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
    child: child,
  );

  Widget _clienteDropdown() {
    final clienteController = context.read<ClienteController>();

    return CampoBuscaSelecao<Cliente>(
      rotulo: "Pesquisar Cliente",
      dica: "Nome, CPF ou telefone do cliente...",
      icone: Icons.person_search_outlined,
      mensagemObrigatorio: "Selecione um cliente",
      buscar: clienteController.buscar,
      tituloDe: (c) => c.nome,
      subtituloDe: (c) => c.telefone,
      aoSelecionar: (cliente) => setState(() {
        _clienteSelecionadoId = cliente.id;
        _clienteNomeSelecionado = cliente.nome;
      }),
      aoLimpar: () => setState(() {
        _clienteSelecionadoId = null;
        _clienteNomeSelecionado = '';
      }),
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: PaletaSahara.primary, width: 1.5))),
    validator: (v) => v == null || v.isEmpty ? "Campo obrigatório" : null,
  );

  Widget _periodoDaObra() {
    final dias = DateUtils.dateOnly(_dataPrevisao).difference(DateUtils.dateOnly(_dataInicio)).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Período da obra", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              dias == 1 ? "1 dia" : "$dias dias",
              style: const TextStyle(fontSize: 12, color: PaletaSahara.onSurfaceMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CampoData(
                rotulo: "De",
                data: _dataInicio,
                tituloCalendario: "Início da obra",
                aoMudar: _mudarInicio,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, size: 18, color: PaletaSahara.onSurfaceMuted),
            ),
            Expanded(
              child: CampoData(
                rotulo: "Até",
                data: _dataPrevisao,
                tituloCalendario: "Previsão de término",
                icone: Icons.event_available_outlined,
                primeiraData: DateUtils.dateOnly(_dataInicio),
                aoMudar: (d) => setState(() => _dataPrevisao = d),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // A previsão de término nunca fica antes do início: se o início passar
  // dela, ela acompanha e o usuário é avisado.
  void _mudarInicio(DateTime novoInicio) {
    final ajustar = DateUtils.dateOnly(_dataPrevisao).isBefore(DateUtils.dateOnly(novoInicio));
    setState(() {
      _dataInicio = novoInicio;
      if (ajustar) _dataPrevisao = novoInicio;
    });
    if (ajustar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Previsão de término ajustada para ${DateFormat('dd/MM/yyyy').format(novoInicio)}."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _etapaCard(int i) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _etapasControllers[i],
            readOnly: _obraConcluida,
            decoration: _inputDeco("Etapa ${i + 1}", Icons.check_circle_outline),
            validator: (v) => v == null || v.isEmpty ? "Obrigatório" : null,
          ),
        ),
        if (_etapasControllers.length > 1 && !_obraConcluida)
          IconButton(icon: Icon(Icons.close, size: 18, color: Colors.red[400]), onPressed: () => _removerEtapa(i)),
      ],
    ),
  );

  InputDecoration _inputDeco(String label, IconData ic) => InputDecoration(
    labelText: label, prefixIcon: Icon(ic, size: 20, color: Colors.grey[600]),
    filled: true, fillColor: Colors.grey[50],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: PaletaSahara.primary, width: 1.5)),
  );
}
