import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../dominio/entidades/obra.dart';
import '../controllers/obra_controller.dart';
import '../widgets/chat_obra_card.dart';
import '../widgets/pdf_lista_materiais_acao.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../apresentacao/widgets/status_chip.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';
import '../../../auth/apresentacao/controllers/auth_controller.dart';
import '../../../auth/dominio/entidades/usuario.dart';
import '../../../../apresentacao/widgets/campo_busca_selecao.dart';

class ObraDetalhesPage extends StatefulWidget {
  final Obra obra;

  /// Etapa 7: aberta pelo sino de mensagens — já desce até o chat.
  final bool rolarParaChat;

  const ObraDetalhesPage({super.key, required this.obra, this.rolarParaChat = false});

  @override
  State<ObraDetalhesPage> createState() => _ObraDetalhesPageState();
}

class _ObraDetalhesPageState extends State<ObraDetalhesPage> {
  final _chaveChat = GlobalKey();
  bool _rolouParaChat = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final controller = context.read<ObraController>();
      controller.carregarObras();
      if (widget.obra.id != null) controller.carregarEquipe(widget.obra.id!);

      // Item 2.1: carrega as alocações do Funcionário, para checar se ele
      // tem permissão de ver esta obra específica (bloqueia acesso direto).
      final usuario = context.read<AuthController>().usuarioLogado;
      if (usuario?.funcao == 'Funcionário' && usuario?.id != null) {
        controller.carregarObraIdsAlocados(usuario!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ObraController>();
    final formatoData = DateFormat('dd/MM/yyyy');
    final usuarioLogado = context.watch<AuthController>().usuarioLogado;
    final ehFuncionario = usuarioLogado?.funcao == 'Funcionário';
    // Só o responsável técnico (Gerente/Administrador) confirma mudanças de
    // status e mexe na equipe alocada — Funcionário só acompanha.
    final podeGerenciarObra = !ehFuncionario;
    final c = context.cores;

    // Item 2.1: só decide "acesso restrito" com as alocações DELE carregadas.
    final idFuncionario = ehFuncionario ? usuarioLogado?.id : null;
    if (idFuncionario != null) controller.garantirAlocacoes(idFuncionario);
    final aguardandoAlocacoes = idFuncionario != null && !controller.alocacoesProntasPara(idFuncionario);

    if (controller.carregando || aguardandoAlocacoes) {
      return Scaffold(
        appBar: AppBar(title: const Text("Detalhes da Obra")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Item 2.1: Funcionário não pode abrir uma obra em que não está alocado,
    // mesmo navegando direto (não é só esconder da lista).
    if (ehFuncionario && !controller.obraIdsAlocados.contains(widget.obra.id)) {
      return Scaffold(
        appBar: AppBar(title: const Text("Acesso restrito")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Espaco.x6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.lock_rounded, size: 56, color: c.inkMuted),
                const SizedBox(height: Espaco.x4),
                Text(
                  'Você não está alocado nesta obra.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: Espaco.x6),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Encontrar a versão mais atualizada desta obra
    final obraAtual = controller.obras.where((o) => o.id == widget.obra.id).firstOrNull ?? widget.obra;

    if (widget.rolarParaChat && !_rolouParaChat) {
      _rolouParaChat = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _chaveChat.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes da Obra"),
        actions: [
          if (podeGerenciarObra)
            IconButton(
              icon: const Icon(Symbols.edit_rounded),
              tooltip: "Editar obra",
              onPressed: () => Navigator.pushNamed(context, '/obra-formulario', arguments: obraAtual),
            ),
          if (podeGerenciarObra && obraAtual.status == 'Concluída')
            Padding(
              padding: const EdgeInsets.only(right: Espaco.x3),
              child: Tooltip(
                message: "Obra concluída: status definitivo",
                child: Icon(Symbols.lock_rounded, color: c.inkMuted),
              ),
            )
          else if (podeGerenciarObra)
            PopupMenuButton<String>(
              icon: const Icon(Symbols.more_vert_rounded),
              onSelected: (status) => _atualizarStatus(context, obraAtual, controller, status),
              itemBuilder: (context) => [
                'Não Iniciada', 'Em Andamento', 'Pausada', 'Concluída',
              ].where((s) => s != obraAtual.status)
                  .map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Espaco.margemTela),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === CABEÇALHO ===
            _buildCabecalho(obraAtual, formatoData, context),
            const SizedBox(height: Espaco.x6),

            // === BARRA DE PROGRESSO ===
            _buildProgressoCard(obraAtual),
            const SizedBox(height: Espaco.x6),

            // === EQUIPE ALOCADA ===
            _sectionTitle("Equipe Alocada", Symbols.groups_rounded),
            const SizedBox(height: Espaco.x3),
            _buildEquipeCard(context, obraAtual, controller, podeGerenciarObra),
            const SizedBox(height: Espaco.x6),

            // === CHECKLIST DE ETAPAS ===
            _sectionTitle("Checklist de Etapas", Symbols.checklist_rounded),
            const SizedBox(height: Espaco.x3),
            _buildChecklistCard(context, obraAtual, controller),
            const SizedBox(height: Espaco.x6),


            // === LISTA DE MATERIAIS (etapa 6b — só leitura; edição pelo lápis) ===
            if (podeGerenciarObra) ...[
              _sectionTitle("Lista de Materiais", Symbols.inventory_2_rounded),
              const SizedBox(height: Espaco.x3),
              _buildListaMateriaisCard(context, obraAtual),
              const SizedBox(height: Espaco.x6),
            ],

            // === CHAT DA OBRA (item 2.3) ===
            if (obraAtual.id != null) ...[
              KeyedSubtree(key: _chaveChat, child: _sectionTitle("Chat da Obra", Symbols.forum_rounded)),
              const SizedBox(height: Espaco.x3),
              ChatObraCard(obraId: obraAtual.id!),
              const SizedBox(height: Espaco.x6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t, IconData ic) => Row(children: [
    Icon(ic, size: TamanhoIcone.pequeno, color: context.cores.primary), const SizedBox(width: Espaco.x2),
    Text(t, style: Theme.of(context).textTheme.titleMedium),
  ]);

  Widget _card({required Widget child}) => SizedBox(
    width: double.infinity,
    child: CardApp(padding: const EdgeInsets.all(Espaco.x5), child: child),
  );

  // --- CABEÇALHO ---
  Widget _buildCabecalho(Obra obraAtual, DateFormat fmt, BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(obraAtual.tituloDaObra, style: texto.titleLarge)),
              const SizedBox(width: Espaco.x2),
              StatusChip(obraAtual.status),
            ],
          ),
          const SizedBox(height: Espaco.x4),

          // Cliente
          _infoRow(Symbols.person_rounded, "Cliente", obraAtual.clienteNome),
          const SizedBox(height: 10),

          // Endereço com botão de mapa
          Row(
            children: [
              Icon(Symbols.location_on_rounded, size: TamanhoIcone.pequeno, color: c.inkMuted),
              const SizedBox(width: Espaco.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Endereço", style: _legenda()),
                    Text(obraAtual.endereco, style: texto.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Symbols.directions_rounded, color: c.info),
                tooltip: "Como chegar",
                onPressed: () => _abrirMapa(obraAtual),
              ),
            ],
          ),
          if (obraAtual.temCoordenadas) ...[
            const SizedBox(height: 10),
            // Os blocos do OpenStreetMap são sempre claros; aqui só borda e cantos.
            Container(
              height: 160,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Raio.botao),
                border: Border.all(color: c.border),
              ),
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(obraAtual.latitude!, obraAtual.longitude!),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.paintmanager.app',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(obraAtual.latitude!, obraAtual.longitude!),
                        width: 36,
                        height: 36,
                        child: Icon(Symbols.location_on_rounded, fill: 1, color: c.error, size: 36),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Datas
          Row(
            children: [
              Expanded(child: _infoRow(Symbols.calendar_today_rounded, "Início", fmt.format(obraAtual.dataInicio))),
              Expanded(child: _infoRow(Symbols.event_rounded, "Previsão", fmt.format(obraAtual.dataPrevisaoTermino))),
            ],
          ),
          if (obraAtual.dataConclusao != null) ...[
            const SizedBox(height: 10),
            _infoRow(Symbols.check_circle_rounded, "Concluída em", fmt.format(obraAtual.dataConclusao!)),
          ],
        ],
      ),
    );
  }

  TextStyle? _legenda() =>
      Theme.of(context).textTheme.bodySmall?.copyWith(color: context.cores.inkMuted, letterSpacing: 0);

  Widget _infoRow(IconData ic, String label, String value) => Row(
    children: [
      Icon(ic, size: TamanhoIcone.pequeno, color: context.cores.inkMuted),
      const SizedBox(width: Espaco.x2),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _legenda()),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    ],
  );

  // --- PROGRESSO ---
  Widget _buildProgressoCard(Obra obraAtual) {
    final concluidas = obraAtual.etapasServico.where((e) => e.concluida).length;
    final total = obraAtual.etapasServico.length;
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Progresso Geral", style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
              Text("$concluidas/$total etapas", style: texto.bodyMedium?.copyWith(color: c.inkMuted)),
            ],
          ),
          const SizedBox(height: Espaco.x3),
          // Trilho surfaceSunken e preenchimento brand vêm do tema.
          ClipRRect(
            borderRadius: BorderRadius.circular(Raio.pilula),
            child: LinearProgressIndicator(value: obraAtual.progresso / 100, minHeight: 12),
          ),
          const SizedBox(height: Espaco.x2),
          Text(
            "${obraAtual.progresso.toStringAsFixed(0)}% concluído",
            style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // --- EQUIPE ALOCADA (RF010) ---
  Widget _buildEquipeCard(BuildContext context, Obra obraAtual, ObraController controller, bool podeGerenciar) {
    final equipe = controller.equipeObraAtual;
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.carregandoEquipe)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(Espaco.x2),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (equipe.isEmpty)
            Text("Nenhum funcionário alocado.", style: texto.bodyMedium?.copyWith(color: c.inkMuted))
          else
            Wrap(
              spacing: Espaco.x2,
              runSpacing: Espaco.x2,
              children: equipe.map((u) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: c.primary,
                    child: Text(
                      u.nome.isNotEmpty ? u.nome[0].toUpperCase() : '?',
                      style: texto.labelSmall?.copyWith(color: c.onPrimary, letterSpacing: 0),
                    ),
                  ),
                  label: Text(u.nome, style: texto.bodyMedium),
                  onDeleted: podeGerenciar && obraAtual.id != null && u.id != null
                      ? () => controller.desalocarFuncionario(obraAtual.id!, u.id!)
                      : null,
                  backgroundColor: c.primarySoft,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                );
              }).toList(),
            ),
          if (podeGerenciar) ...[
            const SizedBox(height: Espaco.x3),
            OutlinedButton.icon(
              onPressed: () => _mostrarSelecionarFuncionario(context, obraAtual, controller),
              icon: const Icon(Symbols.person_add_rounded, size: TamanhoIcone.pequeno),
              label: const Text("Adicionar funcionário"),
            ),
          ],
        ],
      ),
    );
  }

  void _mostrarSelecionarFuncionario(BuildContext context, Obra obraAtual, ObraController obraController) {
    if (obraAtual.id == null) return;
    final obraId = obraAtual.id!;
    final texto = Theme.of(context).textTheme;
    final c = context.cores;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          // Sobe o painel junto com o teclado para a lista não ficar escondida.
          padding: EdgeInsets.fromLTRB(Espaco.x5, Espaco.x5, Espaco.x5, Espaco.x5 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Adicionar funcionário", style: texto.titleMedium),
              const SizedBox(height: Espaco.x1),
              Text(
                "Funcionários ativos que ainda não estão nesta obra.",
                style: texto.bodyMedium?.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: Espaco.x4),
              CampoBuscaSelecao<Usuario>(
                rotulo: "Pesquisar funcionário",
                dica: "Digite o nome...",
                icone: Symbols.person_search_rounded,
                autofocus: true,
                buscar: (termo) => obraController.buscarFuncionariosDisponiveis(obraId, termo),
                tituloDe: (u) => u.nome,
                subtituloDe: (u) => u.telefone.isNotEmpty ? u.telefone : u.email,
                aoSelecionar: (u) {
                  Navigator.pop(ctx);
                  if (u.id != null) obraController.alocarFuncionario(obraId, u.id!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  // --- CHECKLIST DE ETAPAS ---
  Widget _buildChecklistCard(BuildContext context, Obra obraAtual, ObraController controller) {
    final bloqueada = obraAtual.status == 'Concluída';
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return _card(
      child: Column(
        children: [
          if (bloqueada)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: Espaco.x3),
              padding: const EdgeInsets.symmetric(horizontal: Espaco.x3, vertical: 10),
              decoration: BoxDecoration(
                color: c.infoSoft,
                borderRadius: BorderRadius.circular(Raio.campo),
              ),
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
          ...List.generate(obraAtual.etapasServico.length, (i) {
          final etapa = obraAtual.etapasServico[i];
          return Container(
            margin: EdgeInsets.only(bottom: i < obraAtual.etapasServico.length - 1 ? Espaco.x2 : 0),
            child: Material(
              color: etapa.concluida ? c.successSoft : c.surfaceSunken,
              borderRadius: BorderRadius.circular(Raio.botao),
              child: InkWell(
                borderRadius: BorderRadius.circular(Raio.botao),
                // Área de toque grande para canteiro de obras
                onTap: bloqueada ? null : () => controller.alternarEtapa(obraAtual, i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Espaco.x4, vertical: 14),
                  child: Row(
                    children: [
                      // Checkbox grande para facilitar uso com mãos sujas
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: etapa.concluida ? c.success : c.surfaceCard,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: etapa.concluida ? c.success : c.decor, width: 2),
                        ),
                        child: etapa.concluida
                            ? Icon(Symbols.check_rounded, color: c.surfaceCard, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          etapa.nome,
                          style: texto.bodyLarge?.copyWith(
                            decoration: etapa.concluida ? TextDecoration.lineThrough : null,
                            color: etapa.concluida ? c.inkMuted : c.ink,
                          ),
                        ),
                      ),
                      Text(
                        etapa.concluida ? "Concluído" : "Pendente",
                        style: texto.labelSmall?.copyWith(
                          letterSpacing: 0,
                          color: etapa.concluida ? c.success : c.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          }),
        ],
      ),
    );
  }

  Widget _buildListaMateriaisCard(BuildContext context, Obra obraAtual) {
    final materiais = obraAtual.listaMateriais;
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (materiais.isEmpty)
            Text(
              "Nenhum material na lista. Use o lápis para adicionar.",
              style: texto.bodyMedium?.copyWith(color: c.inkMuted),
            )
          else ...[
            for (final (i, item) in materiais.indexed)
              Padding(
                padding: EdgeInsets.only(bottom: i < materiais.length - 1 ? 10 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text("${i + 1}.", style: texto.bodyMedium?.copyWith(color: c.inkMuted)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.descricao, style: texto.bodyMedium),
                          if (item.quantidadeComUnidade.isNotEmpty)
                            Text(item.quantidadeComUnidade, style: _legenda()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: Espaco.x4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => gerarECompartilharPdfListaMateriais(context, obraAtual),
                icon: const Icon(Symbols.picture_as_pdf_rounded, size: TamanhoIcone.pequeno),
                label: const Text("Gerar PDF"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _atualizarStatus(BuildContext context, Obra obraAtual, ObraController controller, String novoStatus) async {
    var marcarPendentes = false;
    if (novoStatus == 'Concluída') {
      final pendentes = obraAtual.etapasServico.where((e) => !e.concluida).length;
      final confirmou = await _confirmarConclusao(context, pendentes);
      if (confirmou != true) return;
      marcarPendentes = pendentes > 0;
    }
    if (!context.mounted) return;

    final erro = await controller.atualizarStatus(
      obraAtual,
      novoStatus,
      marcarEtapasPendentes: marcarPendentes,
    );
    if (context.mounted) {
      final c = context.cores;
      if (erro != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erro, style: TextStyle(color: c.onError)), backgroundColor: c.error),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status atualizado para: $novoStatus")),
        );
      }
    }
  }

  // Concluir é definitivo (status e checklist travam), então sempre confirma.
  Future<bool?> _confirmarConclusao(BuildContext context, int pendentes) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Concluir obra?"),
        content: Text(
          "${pendentes > 0 ? "Ainda há $pendentes etapa(s) pendente(s). Todas serão marcadas como concluídas.\n\n" : ""}"
          "Depois de concluída, a obra não pode ser reaberta: o status e as etapas ficam bloqueados.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(pendentes > 0 ? "Marcar todas e concluir" : "Concluir"),
          ),
        ],
      ),
    );
  }

  void _abrirMapa(Obra obra) async {
    // Item 3.2 — prefere a coordenada geocodificada (mais precisa); se a obra
    // não tiver coordenada (geocodificação falhou ou obra antiga), cai para
    // a busca por texto do endereço.
    final uri = obra.temCoordenadas
        ? Uri.parse("https://www.google.com/maps/dir/?api=1&destination=${obra.latitude},${obra.longitude}")
        : Uri.parse("https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(obra.endereco)}");
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Falha silenciosa se não conseguir abrir
    }
  }
}
