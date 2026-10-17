import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/obra.dart';
import '../controllers/obra_controller.dart';
import 'obra_detalhes_page.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../apresentacao/widgets/drawer_comum.dart';
import '../../../../apresentacao/widgets/status_chip.dart';
import '../../../../apresentacao/widgets/tela_vazia.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';
import '../../../../core/tema/status_visual.dart';
import '../../../auth/apresentacao/controllers/auth_controller.dart';
import '../../../../core/filtros/filtro_lista.dart';
import '../../../../apresentacao/widgets/painel_filtro_lista.dart';
import '../../../../apresentacao/widgets/chips_filtro_status.dart';

class ObraListPage extends StatefulWidget {
  const ObraListPage({super.key});

  @override
  State<ObraListPage> createState() => _ObraListPageState();
}

class _ObraListPageState extends State<ObraListPage> {
  String _termoBusca = '';
  String? _statusSelecionado; // null = todas
  late FiltroLista _filtro =
      FiltroLista(maisRecentes: context.read<ObraController>().maisRecentes);

  late final ObraController _obraController = context.read<ObraController>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final controller = _obraController;
      controller.carregarObras();
      controller.carregarNaoLidas();
      controller.iniciarAvisosChat();

      // Item 2.1: Funcionário só vê as obras em que está alocado.
      final usuario = context.read<AuthController>().usuarioLogado;
      if (usuario?.funcao == 'Funcionário' && usuario?.id != null) {
        controller.carregarObraIdsAlocados(usuario!.id!);
      }
    });
  }

  @override
  void dispose() {
    _obraController.pararAvisosChat();
    super.dispose();
  }

  List<Obra> _filtrar(List<Obra> obras) {
    final termo = _termoBusca.toLowerCase();
    return obras.where((o) {
      if (_statusSelecionado != null && o.status != _statusSelecionado) return false;
      if (termo.isNotEmpty &&
          !o.tituloDaObra.toLowerCase().contains(termo) &&
          !o.clienteNome.toLowerCase().contains(termo) &&
          !o.status.toLowerCase().contains(termo)) {
        return false;
      }
      return _filtro.criadoNoPeriodo(o.criadoEm) &&
          // Obra concluída não está mais "atrasada" nem "terminando".
          _filtro.dentroDoPrazo(o.dataPrevisaoTermino, emAberto: o.status != 'Concluída');
    }).toList();
  }

  void _aplicarFiltro(FiltroLista novo) {
    setState(() => _filtro = novo);
    context.read<ObraController>().ordenar(maisRecentes: novo.maisRecentes);
  }

  Widget _buildChipsStatus(List<Obra> todas) {
    final c = context.cores;
    int qtd(String status) => todas.where((o) => o.status == status).length;
    // Mesma cor de cada status em todo o app (core/tema/status_visual.dart).
    OpcaoStatus<String?> opcao(String status) =>
        OpcaoStatus(status, status, qtd(status), visualDoStatus(status, c).cor);

    return ChipsFiltroStatus<String?>(
      selecionado: _statusSelecionado,
      aoSelecionar: (s) => setState(() => _statusSelecionado = s),
      opcoes: [
        OpcaoStatus("Todas", null, todas.length, c.primary),
        opcao("Não Iniciada"),
        opcao("Em Andamento"),
        opcao("Pausada"),
        opcao("Concluída"),
      ],
    );
  }

  PreferredSizeWidget _appBar({List<Widget>? actions}) {
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Symbols.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text("Obras"),
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ObraController>();
    final formatoData = DateFormat('dd/MM/yyyy');
    final isWide = MediaQuery.of(context).size.width > 800;
    final usuarioLogado = context.watch<AuthController>().usuarioLogado;
    final ehFuncionario = usuarioLogado?.funcao == 'Funcionário';
    // Funcionário só acompanha o andamento das obras — não cadastra novas.
    final podeGerenciarObras = !ehFuncionario;
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    // Item 2.1: o filtro do Funcionário só vale com as alocações DELE carregadas.
    final idFuncionario = ehFuncionario ? usuarioLogado?.id : null;
    if (idFuncionario != null) controller.garantirAlocacoes(idFuncionario);
    final aguardandoAlocacoes = idFuncionario != null && !controller.alocacoesProntasPara(idFuncionario);

    if (controller.carregando || aguardandoAlocacoes) {
      return Scaffold(
        drawer: const DrawerComum(),
        appBar: _appBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Item 2.1: Funcionário só enxerga as obras em que está alocado.
    final todas = ehFuncionario
        ? controller.obras.where((o) => controller.obraIdsAlocados.contains(o.id)).toList()
        : controller.obras;
    final filtradas = _filtrar(todas);
    final emAndamento = todas.where((o) => o.status == 'Em Andamento').length;
    final concluidas = todas.where((o) => o.status == 'Concluída').length;
    final comFiltro = _filtro.quantidadeAtivos > 0 || _termoBusca.isNotEmpty || _statusSelecionado != null;

    return Scaffold(
      drawer: const DrawerComum(),
      appBar: _appBar(actions: [_buildSinoMensagens(todas)]),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? Espaco.x6 : Espaco.margemTela),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Text("Gestão de Obras", style: texto.headlineMedium),
            const SizedBox(height: Espaco.x1),
            Text("Acompanhe o progresso de cada serviço.", style: texto.bodyMedium?.copyWith(color: c.inkMuted)),
            const SizedBox(height: Espaco.x4),
            if (podeGerenciarObras) ...[
              SizedBox(
                width: isWide ? null : double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/obra-formulario'),
                  icon: const Icon(Symbols.add_rounded, size: TamanhoIcone.pequeno),
                  label: const Text("Nova Obra"),
                ),
              ),
              const SizedBox(height: Espaco.x6),
            ],

            // --- SUMMARY CARDS ---
            _buildSummaryRow(todas.length, emAndamento, concluidas),
            const SizedBox(height: Espaco.x6),

            // --- FILTRO POR STATUS ---
            _buildChipsStatus(todas),
            const SizedBox(height: Espaco.x4),

            // --- BUSCA + BOTÃO DE FILTRO ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _termoBusca = v),
                    decoration: const InputDecoration(
                      hintText: "Buscar obras...",
                      prefixIcon: Icon(Symbols.search_rounded, size: TamanhoIcone.pequeno),
                    ),
                  ),
                ),
                const SizedBox(width: Espaco.x2),
                BotaoFiltroLista(
                  filtro: _filtro,
                  aoAplicar: _aplicarFiltro,
                  rotuloAtrasados: "Atrasadas",
                  rotuloProximos7Dias: "Terminam em 7 dias",
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Espaco.x3),
              child: Text(
                "${filtradas.length} obra(s) encontrada(s)",
                style: texto.bodyMedium?.copyWith(color: c.inkMuted),
              ),
            ),

            // --- LISTA DE CARDS ---
            if (filtradas.isEmpty)
              TelaVazia(
                ilustracao: comFiltro ? IlustracaoVazia.busca : IlustracaoVazia.obras,
                titulo: comFiltro ? "Nenhuma obra com esses filtros" : "Nenhuma obra encontrada",
                texto: comFiltro
                    ? "Mude a busca, o status ou os filtros para ver outras obras."
                    : ehFuncionario
                        ? "Você ainda não foi alocado em nenhuma obra."
                        : "Cadastre a primeira obra pelo botão Nova Obra.",
              )
            else
              ...filtradas.map((obra) => _buildObraCard(obra, formatoData)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(int total, int emAndamento, int concluidas) {
    final c = context.cores;
    return Column(
      children: [
        _buildSummaryCard("Total", total.toString(), Symbols.construction_rounded, c.primary),
        const SizedBox(height: Espaco.x3),
        Row(children: [
          Expanded(child: _buildSummaryCard("Em Andamento", emAndamento.toString(), Symbols.autorenew_rounded, c.info)),
          const SizedBox(width: Espaco.x3),
          Expanded(child: _buildSummaryCard("Concluídas", concluidas.toString(), Symbols.check_circle_rounded, c.success)),
        ]),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icone, Color cor) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return CardApp(
      child: Row(
        children: [
          Icon(icone, color: cor, size: TamanhoIcone.medio),
          const SizedBox(width: Espaco.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0), overflow: TextOverflow.ellipsis),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: texto.displayMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ao voltar dos detalhes (onde o chat pode ter sido lido), atualiza os avisos.
  Future<void> _abrirObra(Obra obra, {bool rolarParaChat = false}) async {
    final controller = context.read<ObraController>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ObraDetalhesPage(obra: obra, rolarParaChat: rolarParaChat)),
    );
    if (mounted) controller.carregarNaoLidas();
  }

  Widget _buildSinoMensagens(List<Obra> visiveis) {
    final controller = context.watch<ObraController>();
    final c = context.cores;
    final comNovas = visiveis.where((o) => controller.naoLidasDa(o.id) > 0).toList();

    return IconButton(
      tooltip: "Mensagens novas no chat",
      icon: Badge(
        label: Text('${comNovas.length}'),
        isLabelVisible: comNovas.isNotEmpty,
        backgroundColor: c.secondary,
        textColor: c.onSecondary,
        child: const Icon(Symbols.notifications_rounded),
      ),
      onPressed: () => _mostrarObrasComMensagens(comNovas),
    );
  }

  void _mostrarObrasComMensagens(List<Obra> comNovas) {
    final controller = context.read<ObraController>();
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Espaco.x5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mensagens novas", style: texto.titleMedium),
              const SizedBox(height: Espaco.x3),
              if (comNovas.isEmpty)
                const TelaVazia(
                  ilustracao: IlustracaoVazia.notificacoes,
                  titulo: "Nenhuma mensagem nova",
                  texto: "Quando alguém escrever no chat de uma obra, ela aparece aqui.",
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final obra in comNovas)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: c.primarySoft,
                            child: Icon(Symbols.forum_rounded, color: c.primary, size: TamanhoIcone.pequeno),
                          ),
                          title: Text(obra.tituloDaObra, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            obra.clienteNome,
                            overflow: TextOverflow.ellipsis,
                            style: texto.bodyMedium?.copyWith(color: c.inkMuted),
                          ),
                          trailing: Badge(
                            label: Text('${controller.naoLidasDa(obra.id)}'),
                            backgroundColor: c.secondary,
                            textColor: c.onSecondary,
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _abrirObra(obra, rolarParaChat: true);
                          },
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildObraCard(Obra obra, DateFormat formatoData) {
    final progresso = obra.progresso / 100;
    final naoLidas = context.watch<ObraController>().naoLidasDa(obra.id);
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final estiloInfo = texto.bodyMedium?.copyWith(color: c.inkMuted);

    Widget linha(IconData icone, String valor) => Row(
          children: [
            Icon(icone, size: 16, color: c.inkMuted),
            const SizedBox(width: 6),
            Expanded(child: Text(valor, style: estiloInfo, overflow: TextOverflow.ellipsis)),
          ],
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.x4),
      child: CardApp(
        aoTocar: () => _abrirObra(obra),
        padding: const EdgeInsets.all(Espaco.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    obra.tituloDaObra,
                    style: texto.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (naoLidas > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: Espaco.x2),
                    child: Tooltip(
                      message: "$naoLidas mensagem(ns) nova(s) no chat",
                      child: Badge(
                        label: Text('$naoLidas'),
                        backgroundColor: c.secondary,
                        textColor: c.onSecondary,
                        child: Icon(Symbols.forum_rounded, size: TamanhoIcone.pequeno, color: c.primary),
                      ),
                    ),
                  ),
                StatusChip(obra.status),
              ],
            ),
            const SizedBox(height: Espaco.x2),

            linha(Symbols.person_rounded, obra.clienteNome),
            const SizedBox(height: Espaco.x1),
            linha(Symbols.location_on_rounded, obra.endereco),
            const SizedBox(height: Espaco.x1),
            linha(
              Symbols.calendar_today_rounded,
              "${formatoData.format(obra.dataInicio)} → ${formatoData.format(obra.dataPrevisaoTermino)}",
            ),
            const SizedBox(height: Espaco.x4),

            // Barra de progresso: trilho surfaceSunken, preenchimento brand (tema).
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Raio.pilula),
                    child: LinearProgressIndicator(value: progresso, minHeight: 8),
                  ),
                ),
                const SizedBox(width: Espaco.x3),
                Text(
                  "${obra.progresso.toStringAsFixed(0)}%",
                  style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
