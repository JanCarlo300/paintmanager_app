import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/obra.dart';
import '../../dominio/entidades/etapa_servico.dart';
import '../../dominio/entidades/item_material.dart';
import '../../../clientes/dominio/entidades/cliente.dart';
import '../controllers/obra_controller.dart';
import '../../../clientes/apresentacao/controllers/cliente_controller.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';
import '../../../../core/servicos/geocodificacao_service.dart';
import '../../../../apresentacao/widgets/campo_busca_selecao.dart';
import '../../../../apresentacao/widgets/campo_data.dart';
import '../widgets/pdf_lista_materiais_acao.dart';

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
  final _materialDescricaoController = TextEditingController();
  final _materialQuantidadeController = TextEditingController();
  final _materialUnidadeController = TextEditingController();
  late DateTime _dataInicio;
  late DateTime _dataPrevisao;

  final List<TextEditingController> _etapasControllers = [];
  final List<ItemMaterial> _listaMateriais = [];

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
    _dataInicio = obra?.dataInicio ?? DateTime.now();
    _dataPrevisao = obra?.dataPrevisaoTermino ?? DateTime.now().add(const Duration(days: 15));

    // Em edição o cliente já vem escolhido (o nome está guardado na própria obra)
    if (obra != null) {
      _clienteSelecionadoId = obra.idCliente;
      _clienteNomeSelecionado = obra.clienteNome;
    }

    if (obra != null) _listaMateriais.addAll(obra.listaMateriais);

    if (obra != null && obra.etapasServico.isNotEmpty) {
      for (final etapa in obra.etapasServico) {
        _etapasControllers.add(TextEditingController(text: etapa.nome));
      }
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
    _materialDescricaoController.dispose();
    _materialQuantidadeController.dispose();
    _materialUnidadeController.dispose();
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

  /// Retorna false se o material digitado é inválido (e avisa o usuário).
  bool _adicionarMaterial() {
    final descricao = _materialDescricaoController.text.trim();
    if (descricao.isEmpty) {
      _avisarMaterial("Informe a descrição do material.");
      return false;
    }
    final textoQtd = _materialQuantidadeController.text.trim().replaceAll(',', '.');
    final quantidade = textoQtd.isEmpty ? null : double.tryParse(textoQtd);
    if (textoQtd.isNotEmpty && (quantidade == null || quantidade <= 0)) {
      _avisarMaterial("Quantidade inválida. Use um número maior que zero (ex.: 3 ou 2,5).");
      return false;
    }
    setState(() {
      _listaMateriais.add(ItemMaterial(
        descricao: descricao,
        quantidade: quantidade,
        unidade: _materialUnidadeController.text.trim(),
      ));
      _materialDescricaoController.clear();
      _materialQuantidadeController.clear();
      _materialUnidadeController.clear();
    });
    return true;
  }

  void _avisarMaterial(String mensagem) => _avisarErro(mensagem);

  void _avisarErro(String mensagem) {
    final c = context.cores;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem, style: TextStyle(color: c.onError)), backgroundColor: c.error),
    );
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      if (_clienteSelecionadoId == null && widget.obraParaEdicao == null) {
        _avisarErro("Selecione um cliente.");
        return;
      }

      if (DateUtils.dateOnly(_dataPrevisao).isBefore(DateUtils.dateOnly(_dataInicio))) {
        _avisarErro("A previsão de término não pode ser anterior à data de início.");
        return;
      }

      // Material digitado sem tocar no "+" entra na lista em vez de se perder.
      if (_materialDescricaoController.text.trim().isNotEmpty && !_adicionarMaterial()) return;

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
        listaMateriais: _listaMateriais,
        latitude: coordenada?.latitude ?? widget.obraParaEdicao?.latitude,
        longitude: coordenada?.longitude ?? widget.obraParaEdicao?.longitude,
      );

      try {
        await controller.salvar(obra);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Obra salva com sucesso!")),
        );
        // Etapa 6b: com materiais na lista, oferece o PDF na hora (pode recusar).
        if (obra.listaMateriais.isNotEmpty) {
          await gerarECompartilharPdfListaMateriais(
            context,
            obra,
            titulo: "Obra salva! Gerar o PDF da lista de materiais?",
            rotuloCancelar: "Agora não",
          );
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) _avisarErro("Erro ao salvar: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.obraParaEdicao != null;
    final carregando = context.watch<ObraController>().carregando;

    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(isEdicao ? "Editar Obra" : "Nova Obra")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Espaco.margemTela),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === SEÇÃO 1: CLIENTE ===
              _sectionTitle("Dados do Cliente", Symbols.person_rounded),
              const SizedBox(height: Espaco.x3),
              _card(child: isEdicao
                  ? _readOnlyField("Cliente", widget.obraParaEdicao!.clienteNome)
                  : _clienteDropdown()),
              const SizedBox(height: Espaco.x6),

              // === SEÇÃO 2: DADOS DA OBRA ===
              _sectionTitle("Dados da Obra", Symbols.construction_rounded),
              const SizedBox(height: Espaco.x3),
              _card(
                child: Column(
                  children: [
                    _textField("Título da Obra", _tituloController, Symbols.title_rounded, "Ex: Pintura Externa Casa Centro"),
                    const SizedBox(height: Espaco.x4),
                    _textField("Endereço", _enderecoController, Symbols.location_on_rounded, "Rua, Número, Bairro, Cidade"),
                    const SizedBox(height: Espaco.x4),
                    _periodoDaObra(),
                  ],
                ),
              ),
              const SizedBox(height: Espaco.x6),

              // === SEÇÃO 3: ETAPAS ===
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: _sectionTitle("Etapas do Serviço", Symbols.checklist_rounded)),
                  if (!_obraConcluida)
                    TextButton.icon(
                      onPressed: _adicionarEtapa,
                      icon: const Icon(Symbols.add_circle_rounded, size: TamanhoIcone.pequeno),
                      label: const Text("Adicionar"),
                    ),
                ],
              ),
              const SizedBox(height: Espaco.x3),
              if (_obraConcluida)
                Padding(
                  padding: const EdgeInsets.only(bottom: Espaco.x2),
                  child: Row(
                    children: [
                      Icon(Symbols.lock_rounded, size: 16, color: c.info),
                      const SizedBox(width: Espaco.x2),
                      Expanded(
                        child: Text(
                          "Obra concluída: etapas bloqueadas",
                          style: texto.bodyMedium?.copyWith(color: c.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ...List.generate(_etapasControllers.length, (i) => _etapaCard(i)),
              const SizedBox(height: Espaco.x6),

              // === SEÇÃO 4: LISTA DE MATERIAIS ===
              _sectionTitle("Lista de Materiais", Symbols.inventory_2_rounded),
              const SizedBox(height: Espaco.x3),
              _card(child: _listaMateriaisEditor()),
              const SizedBox(height: Espaco.x8),

              // === BOTÃO SALVAR ===
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: carregando ? null : _salvar,
                  icon: carregando
                      ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: c.inkMuted, strokeWidth: 2))
                      : const Icon(Symbols.save_rounded, size: TamanhoIcone.pequeno),
                  label: Text(carregando ? "Salvando..." : "Salvar Obra"),
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

  Widget _sectionTitle(String t, IconData ic) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(ic, size: TamanhoIcone.pequeno, color: context.cores.primary), const SizedBox(width: Espaco.x2),
    Flexible(child: Text(t, style: Theme.of(context).textTheme.titleMedium)),
  ]);

  Widget _card({required Widget child}) => SizedBox(
    width: double.infinity,
    child: CardApp(padding: const EdgeInsets.all(Espaco.x5), child: child),
  );

  Widget _clienteDropdown() {
    final clienteController = context.read<ClienteController>();

    return CampoBuscaSelecao<Cliente>(
      rotulo: "Pesquisar Cliente",
      dica: "Nome, CPF ou telefone do cliente...",
      icone: Symbols.person_search_rounded,
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

  // Campos: fundo, borda, foco e erro vêm do tema (InputDecorationTheme).
  Widget _readOnlyField(String label, String value) => TextFormField(
    initialValue: value, readOnly: true,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Symbols.person_rounded, size: TamanhoIcone.pequeno),
      fillColor: context.cores.disabledBg,
    ),
  );

  Widget _textField(String label, TextEditingController c, IconData ic, String hint) => TextFormField(
    controller: c,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(ic, size: TamanhoIcone.pequeno),
    ),
    validator: (v) => v == null || v.isEmpty ? "Campo obrigatório" : null,
  );

  Widget _periodoDaObra() {
    final dias = DateUtils.dateOnly(_dataPrevisao).difference(DateUtils.dateOnly(_dataInicio)).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("Período da obra", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(
              dias == 1 ? "1 dia" : "$dias dias",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.cores.inkMuted, letterSpacing: 0),
            ),
          ],
        ),
        const SizedBox(height: Espaco.x2),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Symbols.arrow_forward_rounded, size: 18, color: context.cores.inkMuted),
            ),
            Expanded(
              child: CampoData(
                rotulo: "Até",
                data: _dataPrevisao,
                tituloCalendario: "Previsão de término",
                icone: Symbols.event_available_rounded,
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
        ),
      );
    }
  }

  Widget _listaMateriaisEditor() {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _materialDescricaoController,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDeco("Descrição (ex.: Tinta acrílica fosca)", Symbols.add_shopping_cart_rounded),
        ),
        const SizedBox(height: Espaco.x2),
        Row(
          children: [
            SizedBox(
              width: 96,
              child: TextField(
                controller: _materialQuantidadeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoSemIcone("Qtd."),
              ),
            ),
            const SizedBox(width: Espaco.x2),
            Expanded(
              child: TextField(
                controller: _materialUnidadeController,
                decoration: _inputDecoSemIcone("Unidade (ex.: lata 18 L)"),
                onSubmitted: (_) => _adicionarMaterial(),
              ),
            ),
            const SizedBox(width: Espaco.x1),
            IconButton.filled(
              onPressed: _adicionarMaterial,
              tooltip: "Adicionar material",
              icon: const Icon(Symbols.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: Espaco.x3),
        if (_listaMateriais.isEmpty)
          Text("Nenhum material na lista.", style: texto.bodyMedium?.copyWith(color: c.inkMuted))
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(Raio.campo),
            ),
            child: Column(
              children: [
                for (final (i, item) in _listaMateriais.indexed) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    title: Text(item.descricao, style: texto.bodyMedium),
                    subtitle: item.quantidadeComUnidade.isEmpty
                        ? null
                        : Text(item.quantidadeComUnidade,
                            style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0)),
                    trailing: IconButton(
                      icon: Icon(Symbols.close_rounded, size: 18, color: c.error),
                      tooltip: "Remover",
                      onPressed: () => setState(() => _listaMateriais.removeAt(i)),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoSemIcone(String label) => InputDecoration(labelText: label);

  Widget _etapaCard(int i) => Container(
    margin: const EdgeInsets.only(bottom: Espaco.x2),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _etapasControllers[i],
            readOnly: _obraConcluida,
            decoration: _inputDeco("Etapa ${i + 1}", Symbols.check_circle_rounded),
            validator: (v) => v == null || v.isEmpty ? "Obrigatório" : null,
          ),
        ),
        if (_etapasControllers.length > 1 && !_obraConcluida)
          IconButton(
            icon: Icon(Symbols.close_rounded, size: 18, color: context.cores.error),
            tooltip: "Remover etapa",
            onPressed: () => _removerEtapa(i),
          ),
      ],
    ),
  );

  InputDecoration _inputDeco(String label, IconData ic) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(ic, size: TamanhoIcone.pequeno),
  );
}
