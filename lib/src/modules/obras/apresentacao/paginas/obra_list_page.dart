import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/obra.dart';
import '../controllers/obra_controller.dart';
import 'obra_detalhes_page.dart';
import '../../../../apresentacao/widgets/drawer_comum.dart';
import '../../../../core/tema/paleta_sahara.dart';
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final controller = context.read<ObraController>();
      controller.carregarObras();
      controller.carregarNaoLidas();

      // Item 2.1: Funcionário só vê as obras em que está alocado.
      final usuario = context.read<AuthController>().usuarioLogado;
      if (usuario?.funcao == 'Funcionário' && usuario?.id != null) {
        controller.carregarObraIdsAlocados(usuario!.id!);
      }
    });
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
    int qtd(String status) => todas.where((o) => o.status == status).length;

    return ChipsFiltroStatus<String?>(
      selecionado: _statusSelecionado,
      aoSelecionar: (s) => setState(() => _statusSelecionado = s),
      opcoes: [
        OpcaoStatus("Todas", null, todas.length, PaletaSahara.primary),
        OpcaoStatus("Não Iniciada", "Não Iniciada", qtd("Não Iniciada"), Colors.grey[600]!),
        OpcaoStatus("Em Andamento", "Em Andamento", qtd("Em Andamento"), Colors.green),
        OpcaoStatus("Pausada", "Pausada", qtd("Pausada"), Colors.orange),
        OpcaoStatus("Concluída", "Concluída", qtd("Concluída"), Colors.blue),
      ],
    );
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'Em Andamento': return Colors.green;
      case 'Pausada': return Colors.orange;
      case 'Concluída': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _iconeStatus(String status) {
    switch (status) {
      case 'Em Andamento': return Icons.play_circle_outline;
      case 'Pausada': return Icons.pause_circle_outline;
      case 'Concluída': return Icons.check_circle_outline;
      default: return Icons.schedule;
    }
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

    if (controller.carregando || (ehFuncionario && controller.carregandoAlocacoes)) {
      return Scaffold(
        backgroundColor: PaletaSahara.background,
        drawer: const DrawerComum(),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: const Text("Obras", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: false,
          backgroundColor: PaletaSahara.cardSurface,
          foregroundColor: PaletaSahara.onSurface,
          elevation: 0.5,
        ),
        body: const Center(child: CircularProgressIndicator(color: PaletaSahara.primary)),
      );
    }

    // Item 2.1: Funcionário só enxerga as obras em que está alocado.
    final todas = ehFuncionario
        ? controller.obras.where((o) => controller.obraIdsAlocados.contains(o.id)).toList()
        : controller.obras;
    final filtradas = _filtrar(todas);
    final emAndamento = todas.where((o) => o.status == 'Em Andamento').length;
    final concluidas = todas.where((o) => o.status == 'Concluída').length;

    return Scaffold(
      backgroundColor: PaletaSahara.background,
      drawer: const DrawerComum(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text("Obras", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: PaletaSahara.cardSurface,
        foregroundColor: PaletaSahara.onSurface,
        elevation: 0.5,
        actions: [_buildSinoMensagens(todas)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isWide ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            const Text("Gestão de Obras", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Acompanhe o progresso de cada serviço.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            if (podeGerenciarObras) ...[
              SizedBox(
                width: isWide ? null : double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/obra-formulario'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Nova Obra"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PaletaSahara.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // --- SUMMARY CARDS ---
            _buildSummaryRow(todas.length, emAndamento, concluidas),
            const SizedBox(height: 24),

            // --- FILTRO POR STATUS ---
            _buildChipsStatus(todas),
            const SizedBox(height: 16),

            // --- BUSCA + BOTÃO DE FILTRO ---
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      onChanged: (v) => setState(() => _termoBusca = v),
                      decoration: InputDecoration(
                        hintText: "Buscar obras...",
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: PaletaSahara.primary, width: 1.5)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                BotaoFiltroLista(
                  filtro: _filtro,
                  aoAplicar: _aplicarFiltro,
                  rotuloAtrasados: "Atrasadas",
                  rotuloProximos7Dias: "Terminam em 7 dias",
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "${filtradas.length} obra(s) encontrada(s)",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),

            // --- LISTA DE CARDS ---
            if (filtradas.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.construction_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        _filtro.quantidadeAtivos > 0 || _termoBusca.isNotEmpty || _statusSelecionado != null
                            ? "Nenhuma obra encontrada com esses filtros."
                            : "Nenhuma obra encontrada.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filtradas.map((obra) => _buildObraCard(obra, formatoData)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(int total, int emAndamento, int concluidas) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(width: double.infinity, child: _buildSummaryCard("Total", total.toString(), Colors.blue)),
        SizedBox(width: double.infinity, child: Row(children: [
          Expanded(child: _buildSummaryCard("Em Andamento", emAndamento.toString(), Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildSummaryCard("Concluídas", concluidas.toString(), Colors.blue.shade800)),
        ])),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PaletaSahara.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        border: Border(top: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
    final comNovas = visiveis.where((o) => controller.naoLidasDa(o.id) > 0).toList();

    return IconButton(
      tooltip: "Mensagens novas no chat",
      icon: Badge(
        label: Text('${comNovas.length}'),
        isLabelVisible: comNovas.isNotEmpty,
        backgroundColor: Colors.red,
        child: const Icon(Icons.notifications_none_rounded),
      ),
      onPressed: () => _mostrarObrasComMensagens(comNovas),
    );
  }

  void _mostrarObrasComMensagens(List<Obra> comNovas) {
    final controller = context.read<ObraController>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Mensagens novas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (comNovas.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text("Nenhuma mensagem nova no chat das obras.",
                      style: TextStyle(color: Colors.grey[600])),
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
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x1FC2652A),
                            child: Icon(Icons.forum_outlined, color: PaletaSahara.primary, size: 20),
                          ),
                          title: Text(obra.tituloDaObra, overflow: TextOverflow.ellipsis),
                          subtitle: Text(obra.clienteNome, overflow: TextOverflow.ellipsis),
                          trailing: Badge(
                            label: Text('${controller.naoLidasDa(obra.id)}'),
                            backgroundColor: Colors.red,
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
    final cor = _corStatus(obra.status);
    final progresso = obra.progresso / 100;
    final naoLidas = context.watch<ObraController>().naoLidasDa(obra.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: PaletaSahara.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirObra(obra),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(obra.tituloDaObra, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ),
                  if (naoLidas > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Tooltip(
                        message: "$naoLidas mensagem(ns) nova(s) no chat",
                        child: Badge(
                          label: Text('$naoLidas'),
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.forum_outlined, size: 20, color: PaletaSahara.primary),
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconeStatus(obra.status), size: 14, color: cor),
                        const SizedBox(width: 4),
                        Text(obra.status, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Cliente
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(obra.clienteNome, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),

              // Endereço
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(obra.endereco, style: TextStyle(color: Colors.grey[600], fontSize: 13), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Datas
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text("${formatoData.format(obra.dataInicio)} → ${formatoData.format(obra.dataPrevisaoTermino)}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),

              // Barra de progresso
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progresso,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(cor),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text("${obra.progresso.toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
