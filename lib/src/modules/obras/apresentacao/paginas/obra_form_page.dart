import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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
import '../../../../core/servicos/localizacao_service.dart';
import '../../../../core/servicos/cep_service.dart';
import 'confirmar_local_page.dart';
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
  late TextEditingController _cepController;
  late TextEditingController _numeroController;
  late TextEditingController _complementoController;
  late TextEditingController _bairroController;
  final _cepMask = MaskTextInputFormatter(mask: '#####-###', filter: {"#": RegExp(r'[0-9]')});
  bool _buscandoCep = false;
  late TextEditingController _cidadeController;
  String? _uf;

  /// Ponto exato (GPS no local ou link de localização). Com ele, o
  /// "Como chegar" vai direto ao pino em vez de procurar o endereço.
  Coordenada? _pontoExato;
  bool _buscandoPonto = false;
  final _materialDescricaoController = TextEditingController();
  final _materialQuantidadeController = TextEditingController();
  final _materialUnidadeController = TextEditingController();
  late DateTime _dataInicio;
  late DateTime _dataPrevisao;

  final List<TextEditingController> _etapasControllers = [];
  final List<ItemMaterial> _listaMateriais = [];

  bool get _obraConcluida => widget.obraParaEdicao?.status == 'Concluída';

  static const _ufs = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA',
    'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

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
    _cepController = TextEditingController(text: obra?.cepFormatado);
    _numeroController = TextEditingController(text: obra?.numero);
    _complementoController = TextEditingController(text: obra?.complemento);
    _bairroController = TextEditingController(text: obra?.bairro);
    _cidadeController = TextEditingController(text: obra?.cidade);
    _uf = _ufs.contains(obra?.uf) ? obra!.uf : null;
    if (obra != null && obra.temPontoExato) {
      _pontoExato = Coordenada(latitude: obra.latitude!, longitude: obra.longitude!);
    }
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
    _cepController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
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

  // --- PONTO EXATO DA OBRA -------------------------------------------------

  Future<void> _obterPonto(Future<Coordenada> Function() obter) async {
    setState(() => _buscandoPonto = true);
    try {
      final ponto = await obter();
      if (!mounted) return;
      setState(() => _pontoExato = ponto);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponto exato gravado. Salve a obra para guardar.')),
      );
    } catch (e) {
      if (mounted) _avisarErro('$e');
    } finally {
      if (mounted) setState(() => _buscandoPonto = false);
    }
  }

  Future<void> _colarLink() async {
    final campo = TextEditingController();
    final texto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Colar localização'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Abra a localização no Google Maps, toque em Compartilhar e copie o link. '
              'Também vale colar coordenadas, como -17.7912, -50.9231.',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: ctx.cores.inkMuted),
            ),
            const SizedBox(height: Espaco.x3),
            TextField(
              controller: campo,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Link ou coordenadas',
                suffixIcon: IconButton(
                  tooltip: 'Colar',
                  icon: const Icon(Symbols.content_paste_rounded),
                  onPressed: () async {
                    final dados = await Clipboard.getData(Clipboard.kTextPlain);
                    if (dados?.text != null) campo.text = dados!.text!;
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, campo.text), child: const Text('Usar')),
        ],
      ),
    );
    campo.dispose();
    if (texto == null || texto.trim().isEmpty) return;
    await _obterPonto(() => LocalizacaoService().deTexto(texto));
  }

  /// Como no checkout de uma loja: CEP completo preenche rua, bairro, cidade e UF.
  Future<void> _preencherPorCep() async {
    if (_buscandoCep) return;
    setState(() => _buscandoCep = true);
    try {
      final e = await CepService().buscar(_cepController.text);
      if (!mounted) return;
      setState(() {
        if (e.logradouro.isNotEmpty) _enderecoController.text = e.logradouro;
        if (e.bairro.isNotEmpty) _bairroController.text = e.bairro;
        _cidadeController.text = e.cidade;
        if (_ufs.contains(e.uf)) _uf = e.uf;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.logradouro.isEmpty
            ? 'CEP da cidade inteira: preencha a rua.'
            : 'Endereço preenchido pelo CEP. Agora o número e o complemento.')),
      );
    } catch (erro) {
      if (mounted) _avisarErro('$erro');
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  /// Abre o mapa no ponto já salvo ou no ponto aproximado do endereço, para
  /// o usuário arrastar até o lote (como nos apps de entrega).
  Future<void> _confirmarNoMapa() async {
    final enderecoTexto = [
      [_enderecoController.text.trim(), _numeroController.text.trim(), _complementoController.text.trim()]
          .where((p) => p.isNotEmpty)
          .join(', '),
      _bairroController.text.trim(),
      [_cidadeController.text.trim(), _uf ?? ''].where((p) => p.isNotEmpty).join(' - '),
    ].where((p) => p.isNotEmpty).join(' - ');

    var inicial = _pontoExato;
    final aproximado = inicial == null;
    if (inicial == null) {
      setState(() => _buscandoPonto = true);
      inicial = await GeocodificacaoService().buscarCoordenadasObra(
        endereco: _enderecoController.text,
        numero: _numeroController.text,
        bairro: _bairroController.text,
        cidade: _cidadeController.text,
        uf: _uf ?? '',
        cep: _cepController.text,
        aceitarSoCidade: true,
      );
      if (!mounted) return;
      setState(() => _buscandoPonto = false);
    }
    if (inicial == null) {
      _avisarErro('Não achei esse endereço no mapa. Preencha CEP ou cidade e UF e tente de novo.');
      return;
    }

    final escolhido = await Navigator.of(context).push<Coordenada>(
      MaterialPageRoute(
        builder: (_) => ConfirmarLocalPage(
          inicial: inicial!,
          endereco: enderecoTexto,
          pontoAproximado: aproximado,
        ),
      ),
    );
    if (escolhido != null && mounted) {
      setState(() => _pontoExato = escolhido);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local confirmado. Salve a obra para guardar.')),
      );
    }
  }

  Widget _localizacaoExata() {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final ponto = _pontoExato;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Espaco.x3),
      decoration: BoxDecoration(
        color: ponto != null ? c.successSoft : c.surfaceSunken,
        borderRadius: BorderRadius.circular(Raio.campo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ponto != null ? Symbols.where_to_vote_rounded : Symbols.my_location_rounded,
                size: TamanhoIcone.pequeno,
                color: ponto != null ? c.success : c.primary,
              ),
              const SizedBox(width: Espaco.x2),
              Expanded(
                child: Text('Ponto exato no mapa (opcional)',
                    style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: Espaco.x1),
          Text(
            ponto != null
                ? 'Gravado: ${ponto.latitude.toStringAsFixed(6)}, ${ponto.longitude.toStringAsFixed(6)}. '
                    'O "Como chegar" vai direto a este ponto.'
                : 'Para o "Como chegar" levar até o lote: confirme o ponto no mapa, '
                    'grave o GPS estando no local ou cole o link da localização que o cliente mandou.',
            style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0),
          ),
          if (_buscandoPonto) ...[
            const SizedBox(height: Espaco.x2),
            const LinearProgressIndicator(minHeight: 3),
          ],
          const SizedBox(height: Espaco.x2),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _buscandoPonto ? null : _confirmarNoMapa,
              icon: const Icon(Symbols.pin_drop_rounded, size: TamanhoIcone.pequeno),
              label: Text(ponto != null ? 'Ajustar no mapa' : 'Confirmar no mapa'),
            ),
          ),
          const SizedBox(height: Espaco.x2),
          Wrap(
            spacing: Espaco.x2,
            runSpacing: Espaco.x1,
            children: [
              OutlinedButton.icon(
                onPressed: _buscandoPonto ? null : () => _obterPonto(LocalizacaoService().localizacaoAtual),
                icon: const Icon(Symbols.my_location_rounded, size: 18),
                label: const Text('Usar minha localização'),
              ),
              OutlinedButton.icon(
                onPressed: _buscandoPonto ? null : _colarLink,
                icon: const Icon(Symbols.link_rounded, size: 18),
                label: const Text('Colar link'),
              ),
              if (ponto != null)
                TextButton.icon(
                  onPressed: _buscandoPonto ? null : () => setState(() => _pontoExato = null),
                  style: TextButton.styleFrom(foregroundColor: c.error),
                  icon: const Icon(Symbols.close_rounded, size: 18),
                  label: const Text('Remover'),
                ),
            ],
          ),
        ],
      ),
    );
  }

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
      final numero = _numeroController.text.trim();
      final complemento = _complementoController.text.trim();
      final cep = CepService.soDigitos(_cepController.text);
      final bairro = _bairroController.text.trim();
      final cidade = _cidadeController.text.trim();
      final uf = _uf ?? '';

      // Item 3.2 — coordenada para o mapa dos detalhes (OpenStreetMap/Nominatim,
      // gratuito). Endereço igual ao anterior: reaproveita a coordenada. Mudou:
      // busca de novo; se não achar, fica sem mapa (melhor que um ponto errado).
      final mesmoEndereco = original != null &&
          original.endereco.trim() == enderecoDigitado &&
          original.numero.trim() == numero &&
          original.cep == cep &&
          original.bairro.trim() == bairro &&
          original.cidade.trim() == cidade &&
          original.uf.trim() == uf;
      // Ponto exato escolhido pelo usuário tem prioridade e dispensa a busca.
      final coordenada = _pontoExato ??
          (mesmoEndereco && original.temCoordenadas && !original.localizacaoExata
              ? Coordenada(latitude: original.latitude!, longitude: original.longitude!)
              : await GeocodificacaoService().buscarCoordenadasObra(
                  endereco: enderecoDigitado, numero: numero, bairro: bairro, cidade: cidade, uf: uf, cep: cep));

      final obra = Obra(
        id: widget.obraParaEdicao?.id,
        dataConclusao: widget.obraParaEdicao?.dataConclusao,
        idCliente: _clienteSelecionadoId ?? widget.obraParaEdicao?.idCliente ?? 0,
        clienteNome: _clienteNomeSelecionado,
        tituloDaObra: _tituloController.text.trim(),
        endereco: enderecoDigitado,
        numero: numero,
        complemento: complemento,
        cep: cep,
        bairro: bairro,
        cidade: cidade,
        uf: uf,
        dataInicio: _dataInicio,
        dataPrevisaoTermino: _dataPrevisao,
        status: widget.obraParaEdicao?.status ?? 'Não Iniciada',
        etapasServico: etapas,
        listaMateriais: _listaMateriais,
        latitude: coordenada?.latitude,
        longitude: coordenada?.longitude,
        localizacaoExata: _pontoExato != null,
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
                    // CEP primeiro, como no checkout de uma loja: preenche o resto sozinho.
                    TextFormField(
                      controller: _cepController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cepMask],
                      onChanged: (v) {
                        if (CepService.soDigitos(v).length == 8) _preencherPorCep();
                      },
                      decoration: InputDecoration(
                        labelText: "CEP",
                        hintText: "00000-000",
                        helperText: "Preenche rua, bairro e cidade sozinho",
                        prefixIcon: const Icon(Symbols.markunread_mailbox_rounded, size: TamanhoIcone.pequeno),
                        suffixIcon: _buscandoCep
                            ? const Padding(
                                padding: EdgeInsets.all(Espaco.x3),
                                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : IconButton(
                                tooltip: "Buscar CEP",
                                icon: const Icon(Symbols.search_rounded),
                                onPressed: _preencherPorCep,
                              ),
                      ),
                    ),
                    const SizedBox(height: Espaco.x4),
                    _textField("Rua / Avenida", _enderecoController, Symbols.location_on_rounded, "Ex: Rua Rodezir Baylão"),
                    const SizedBox(height: Espaco.x4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 112,
                          child: _textField("Número", _numeroController, Symbols.tag_rounded, "S/N", obrigatorio: false),
                        ),
                        const SizedBox(width: Espaco.x3),
                        Expanded(
                          child: _textField("Complemento", _complementoController, Symbols.grid_view_rounded,
                              "Qd N, Lt 19", obrigatorio: false),
                        ),
                      ],
                    ),
                    const SizedBox(height: Espaco.x4),
                    _textField("Bairro (opcional)", _bairroController, Symbols.holiday_village_rounded, "Ex: Eldorado", obrigatorio: false),
                    const SizedBox(height: Espaco.x4),
                    // Cidade e UF: sem eles o mapa e o "Como chegar" não acham a obra.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _textField("Cidade", _cidadeController, Symbols.location_city_rounded, "Ex: Rio Verde"),
                        ),
                        const SizedBox(width: Espaco.x3),
                        SizedBox(
                          width: 104,
                          child: DropdownButtonFormField<String>(
                            // A chave recria o campo quando o CEP preenche a UF.
                            key: ValueKey(_uf),
                            initialValue: _uf,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: "UF"),
                            items: _ufs.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: (v) => setState(() => _uf = v),
                            validator: (v) => v == null ? "UF" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Espaco.x4),
                    _localizacaoExata(),
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

  Widget _textField(String label, TextEditingController c, IconData ic, String hint, {bool obrigatorio = true}) => TextFormField(
    controller: c,
    textCapitalization: TextCapitalization.words,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(ic, size: TamanhoIcone.pequeno),
    ),
    validator: obrigatorio ? (v) => v == null || v.trim().isEmpty ? "Campo obrigatório" : null : null,
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
