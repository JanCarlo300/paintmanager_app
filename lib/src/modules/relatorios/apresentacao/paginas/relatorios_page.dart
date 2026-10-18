import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../dominio/entidades/relatorio_geral.dart';
import '../controllers/relatorio_controller.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../apresentacao/widgets/card_destaque.dart';
import '../../../../apresentacao/widgets/drawer_comum.dart';
import '../../../../apresentacao/widgets/tela_vazia.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/cores_graficos.dart';
import '../../../../core/tema/medidas_app.dart';
import '../../../../core/pdf/pdf_service.dart';
import '../../../../apresentacao/widgets/campo_busca_selecao.dart';
import '../../../obras/dominio/entidades/obra.dart';
import '../../../obras/apresentacao/controllers/obra_controller.dart';
import 'dart:typed_data';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  Obra? _obraDoPdf;
  String? _gerandoPdf; // 'financeiro' | 'progresso' enquanto gera

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // Carregar relatório ao abrir a tela
    final controller = context.read<RelatorioController>();
    Future.microtask(() => controller.carregarRelatorio());
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RelatorioController>();
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const DrawerComum(),
      appBar: AppBar(
        leading: Builder(builder: (ctx) => IconButton(icon: const Icon(Symbols.menu_rounded), onPressed: () => Scaffold.of(ctx).openDrawer())),
        title: const Text("Relatórios"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Espaco.margemTela),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Text("Análise Financeira", style: texto.headlineMedium),
            const SizedBox(height: Espaco.x1),
            Text("Relatório financeiro do seu negócio.", style: texto.bodyMedium?.copyWith(color: c.inkMuted)),
            const SizedBox(height: Espaco.x6),

            // --- FILTRO DE PERÍODO ---
            _buildFiltroPeriodo(controller),
            const SizedBox(height: Espaco.x4),

            // --- EXPORTAR EM PDF (etapa 8.1 / RF012) ---
            _buildExportarPdf(controller),
            const SizedBox(height: Espaco.x6),

            // --- CONTEÚDO ---
            if (controller.carregando)
              const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.erro != null)
              _buildErro(controller.erro!)
            else if (controller.relatorio == null)
              const TelaVazia(
                ilustracao: IlustracaoVazia.busca,
                titulo: "Escolha um período",
                texto: "Selecione um período acima para ver o relatório.",
              )
            else
              _buildConteudoRelatorio(controller.relatorio!),
          ],
        ),
      ),
    );
  }

  // === FILTRO DE PERÍODO ===
  Widget _buildFiltroPeriodo(RelatorioController controller) {
    final filtros = ['7 dias', 'Este Mês', '30 dias', '90 dias', 'Este Ano'];
    final filtrosValor = ['Últimos 7 dias', 'Este Mês', 'Últimos 30 dias', 'Últimos 90 dias', 'Este Ano'];
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final personalizado = controller.filtroSelecionado == 'Personalizado';

    // Chip selecionado: fundo primarySoft e texto primary (padrão do app).
    TextStyle? estiloChip(bool selecionado) => texto.bodyMedium?.copyWith(
          color: selecionado ? c.primary : c.ink,
          fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
        );
    BorderSide bordaChip(bool selecionado) => BorderSide(color: selecionado ? c.primary : Colors.transparent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Data do período selecionado
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.surfaceCard,
            borderRadius: BorderRadius.circular(Raio.campo),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(Symbols.calendar_today_rounded, size: 16, color: c.inkMuted),
              const SizedBox(width: Espaco.x2),
              Text(
                "${_formatoData.format(controller.inicio)}  —  ${_formatoData.format(controller.fim)}",
                style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: Espaco.x3),
        // Chips de filtro
        Wrap(
          spacing: 6, runSpacing: 6,
          children: [
            ...List.generate(filtros.length, (i) {
              final selecionado = controller.filtroSelecionado == filtrosValor[i];
              return ChoiceChip(
                label: Text(filtros[i]),
                labelStyle: estiloChip(selecionado),
                selected: selecionado,
                selectedColor: c.primarySoft,
                backgroundColor: c.surfaceSunken,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.campo)),
                side: bordaChip(selecionado),
                showCheckmark: false,
                onSelected: (_) => controller.alterarFiltro(filtrosValor[i]),
              );
            }),
            ActionChip(
              label: const Text("Personalizado"),
              labelStyle: estiloChip(personalizado),
              avatar: Icon(Symbols.edit_calendar_rounded, size: 16, color: personalizado ? c.primary : c.inkMuted),
              backgroundColor: personalizado ? c.primarySoft : c.surfaceSunken,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.campo)),
              side: bordaChip(personalizado),
              onPressed: () => _selecionarPeriodoPersonalizado(controller),
            ),
          ],
        ),
      ],
    );
  }

  // === EXPORTAR EM PDF ===
  Widget _buildExportarPdf(RelatorioController controller) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: CardApp(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.picture_as_pdf_rounded, size: TamanhoIcone.pequeno, color: c.primary),
                const SizedBox(width: Espaco.x2),
                Text("Exportar em PDF", style: texto.titleMedium),
              ],
            ),
            const SizedBox(height: Espaco.x1),
            Text(
              "Usa o período selecionado acima. Escolha uma obra para um relatório só dela.",
              style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0),
            ),
            const SizedBox(height: Espaco.x3),
            CampoBuscaSelecao<Obra>(
              rotulo: "Obra (opcional — vazio = todas)",
              dica: "Título da obra ou nome do cliente...",
              icone: Symbols.construction_rounded,
              iconeItem: Symbols.construction_rounded,
              buscar: context.read<ObraController>().buscarObras,
              tituloDe: (o) => o.tituloDaObra,
              subtituloDe: (o) => "Cliente: ${o.clienteNome}  •  ${o.status}",
              aoSelecionar: (o) => setState(() => _obraDoPdf = o),
              aoLimpar: () => setState(() => _obraDoPdf = null),
            ),
            const SizedBox(height: Espaco.x3),
            Row(
              children: [
                Expanded(
                  child: _botaoPdf(
                    "PDF Financeiro",
                    Symbols.payments_rounded,
                    gerando: _gerandoPdf == 'financeiro',
                    aoTocar: () => _exportar(
                      'financeiro',
                      () => controller.gerarPdfFinanceiro(obra: _obraDoPdf),
                      'relatorio-financeiro',
                      controller,
                    ),
                  ),
                ),
                const SizedBox(width: Espaco.x2),
                Expanded(
                  child: _botaoPdf(
                    "PDF de Progresso",
                    Symbols.timeline_rounded,
                    gerando: _gerandoPdf == 'progresso',
                    aoTocar: () => _exportar(
                      'progresso',
                      () => controller.gerarPdfProgresso(obra: _obraDoPdf),
                      'relatorio-progresso',
                      controller,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoPdf(String rotulo, IconData icone, {required bool gerando, required VoidCallback aoTocar}) {
    return OutlinedButton.icon(
      onPressed: _gerandoPdf != null ? null : aoTocar,
      icon: gerando
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icone, size: 18),
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(rotulo)),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: Espaco.x2)),
    );
  }

  Future<void> _exportar(
    String qual,
    Future<Uint8List> Function() gerar,
    String prefixoArquivo,
    RelatorioController controller,
  ) async {
    setState(() => _gerandoPdf = qual);
    final mensageiro = ScaffoldMessenger.of(context);
    final c = context.cores;
    try {
      final bytes = await gerar();
      final periodo = '${DateFormat('ddMMyyyy').format(controller.inicio)}-${DateFormat('ddMMyyyy').format(controller.fim)}';
      final obra = _obraDoPdf != null ? '-${PdfService.nomeSeguro(_obraDoPdf!.tituloDaObra)}' : '';
      await PdfService.compartilhar(bytes, '$prefixoArquivo-$periodo$obra.pdf');
    } catch (e) {
      mensageiro.showSnackBar(
        SnackBar(
          content: Text("Não foi possível gerar o PDF: $e", style: TextStyle(color: c.onError)),
          backgroundColor: c.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _gerandoPdf = null);
    }
  }

  void _selecionarPeriodoPersonalizado(RelatorioController controller) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: controller.inicio, end: controller.fim),
    );
    if (range != null) {
      controller.alterarPeriodoPersonalizado(range.start, range.end);
    }
  }

  // === CONTEÚDO DO RELATÓRIO ===
  Widget _buildConteudoRelatorio(RelatorioGeral rel) {
    final semDados = rel.totalReceitas == 0 && rel.totalDespesas == 0 &&
        rel.quantidadeObrasConcluidas == 0 && rel.totalOrcamentosGerados == 0;

    if (semDados) {
      return const TelaVazia(
        ilustracao: IlustracaoVazia.busca,
        titulo: "Nada neste período",
        texto: "Nenhuma movimentação encontrada. Tente um período maior.",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- CARDS KPI ---
        _buildKPIs(rel),
        const SizedBox(height: Espaco.x6),

        // --- GRÁFICO DE BARRAS: Receitas vs Despesas ---
        _buildGraficoBarras(rel),
        const SizedBox(height: Espaco.x6),

        // --- GRÁFICO DE PIZZA: Despesas por Categoria ---
        _buildGraficoPizza(rel),
        const SizedBox(height: Espaco.x6),

        // --- MÉTRICAS DE OPERAÇÃO ---
        _buildMetricasOperacao(rel),
        const SizedBox(height: Espaco.x6),
      ],
    );
  }

  // === CARDS KPI ===
  // O lucro é o valor principal da tela: vai no card destaque (um só por tela).
  Widget _buildKPIs(RelatorioGeral rel) {
    final c = context.cores;
    final lucro = rel.lucroLiquido;
    return Column(
      children: [
        CardDestaque(
          rotulo: "Lucro Líquido",
          valor: "${lucro < 0 ? '− ' : ''}${_formatoMoeda.format(lucro.abs())}",
          legenda: lucro >= 0 ? "Receitas maiores que despesas" : "Despesas maiores que receitas",
        ),
        const SizedBox(height: Espaco.x3),
        Row(
          children: [
            Expanded(child: _kpiCard("Receitas", _formatoMoeda.format(rel.totalReceitas), c.success, c.successSoft, Symbols.trending_up_rounded)),
            const SizedBox(width: Espaco.x3),
            Expanded(child: _kpiCard("Despesas", _formatoMoeda.format(rel.totalDespesas), c.error, c.errorSoft, Symbols.trending_down_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String titulo, String valor, Color cor, Color fundo, IconData icone) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return CardApp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: fundo, child: Icon(icone, color: cor, size: 18)),
              const SizedBox(width: Espaco.x2),
              Flexible(child: Text(titulo, style: texto.bodyMedium?.copyWith(color: c.inkMuted), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: Espaco.x2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: cor)),
          ),
        ],
      ),
    );
  }

  Widget _tituloCard(String titulo, IconData icone) => Row(
        children: [
          Icon(icone, size: TamanhoIcone.pequeno, color: context.cores.primary),
          const SizedBox(width: Espaco.x2),
          Flexible(child: Text(titulo, style: Theme.of(context).textTheme.titleMedium)),
        ],
      );

  // === GRÁFICO DE BARRAS ===
  Widget _buildGraficoBarras(RelatorioGeral rel) {
    if (rel.receitasPorMes.isEmpty && rel.despesasPorMes.isEmpty) {
      return const SizedBox.shrink();
    }
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final legendaEixo = texto.labelSmall?.copyWith(color: c.inkMuted, letterSpacing: 0);

    // Unir meses de receitas e despesas
    final meses = {...rel.receitasPorMes.keys, ...rel.despesasPorMes.keys}.toList();

    return SizedBox(
      width: double.infinity,
      child: CardApp(
        padding: const EdgeInsets.all(Espaco.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloCard("Receitas vs Despesas", Symbols.bar_chart_rounded),
            const SizedBox(height: Espaco.x2),
            // Legenda
            Row(
              children: [
                _legendaItem("Receitas", c.success),
                const SizedBox(width: Espaco.x4),
                _legendaItem("Despesas", c.error),
              ],
            ),
            const SizedBox(height: Espaco.x5),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _maxValorBarras(rel) * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => c.inverseSurface,
                      getTooltipItem: (group, gi, rod, ri) {
                        final valor = rod.toY;
                        return BarTooltipItem(
                          _formatoMoeda.format(valor),
                          texto.labelSmall?.copyWith(color: c.inverseInk, fontWeight: FontWeight.w700, letterSpacing: 0) ??
                              TextStyle(color: c.inverseInk),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < meses.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: Espaco.x2),
                              child: Text(meses[idx], style: legendaEixo),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (val, meta) => Text(_formatarValorCurto(val), style: legendaEixo),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _maxValorBarras(rel) / 4,
                    getDrawingHorizontalLine: (v) => FlLine(color: c.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(meses.length, (i) {
                    final mes = meses[i];
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: rel.receitasPorMes[mes] ?? 0,
                          color: c.success,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: rel.despesasPorMes[mes] ?? 0,
                          color: c.error,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _maxValorBarras(RelatorioGeral rel) {
    double max = 0;
    for (final v in rel.receitasPorMes.values) { if (v > max) max = v; }
    for (final v in rel.despesasPorMes.values) { if (v > max) max = v; }
    return max == 0 ? 1000 : max;
  }

  Widget _legendaItem(String label, Color cor) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: Espaco.x1),
    Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.cores.inkMuted, letterSpacing: 0)),
  ]);

  String _formatarValorCurto(double valor) {
    if (valor >= 1000) return '${(valor / 1000).toStringAsFixed(1)}K';
    return valor.toStringAsFixed(0);
  }

  // === GRÁFICO DE PIZZA ===
  // Cor fixa por categoria (core/tema/cores_graficos.dart) e, abaixo, uma
  // linha por categoria com nome, % e valor: a leitura não depende da cor.
  Widget _buildGraficoPizza(RelatorioGeral rel) {
    if (rel.despesasPorCategoria.isEmpty) return const SizedBox.shrink();

    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final brilho = Theme.of(context).brightness;
    final total = rel.despesasPorCategoria.values.fold<double>(0, (s, v) => s + v);
    final categorias = rel.despesasPorCategoria.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return SizedBox(
      width: double.infinity,
      child: CardApp(
        padding: const EdgeInsets.all(Espaco.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloCard("Despesas por Categoria", Symbols.pie_chart_rounded),
            const SizedBox(height: Espaco.x5),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 48,
                  sections: [
                    for (final cat in categorias)
                      PieChartSectionData(
                        color: corDaCategoria(cat.key, brilho),
                        value: cat.value,
                        showTitle: false,
                        radius: 52,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Espaco.x4),
            const Divider(),
            const SizedBox(height: Espaco.x2),
            // Detalhamento por categoria: cor + nome + % + valor
            ...categorias.map((cat) {
              final pct = total > 0 ? (cat.value / total) * 100 : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: Espaco.x2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: corDaCategoria(cat.key, brilho),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: Espaco.x2),
                    Expanded(child: Text(cat.key, style: texto.bodyMedium, overflow: TextOverflow.ellipsis)),
                    Text("${pct.toStringAsFixed(0)}%", style: texto.bodyMedium?.copyWith(color: c.inkMuted)),
                    const SizedBox(width: Espaco.x3),
                    Text(_formatoMoeda.format(cat.value), style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // === MÉTRICAS DE OPERAÇÃO ===
  Widget _buildMetricasOperacao(RelatorioGeral rel) {
    final c = context.cores;
    final concluidas = _metricaCard("Obras Concluídas", rel.quantidadeObrasConcluidas.toString(), Symbols.check_circle_rounded, c.success);
    final andamento = _metricaCard("Obras em Andamento", rel.quantidadeObrasEmAndamento.toString(), Symbols.autorenew_rounded, c.info);
    final orcamentos = _metricaCard("Orçamentos Gerados", rel.totalOrcamentosGerados.toString(), Symbols.request_quote_rounded, c.primary);
    final conversao = _metricaCard("Taxa de Conversão", "${rel.taxaConversaoOrcamentos.toStringAsFixed(1)}%", Symbols.trending_up_rounded, c.secondary);

    return SizedBox(
      width: double.infinity,
      child: CardApp(
        padding: const EdgeInsets.all(Espaco.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloCard("Métricas de Operação", Symbols.insights_rounded),
            const SizedBox(height: Espaco.x5),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 340;
                if (isNarrow) {
                  return Column(
                    children: [
                      concluidas,
                      const SizedBox(height: Espaco.x3),
                      andamento,
                      const SizedBox(height: Espaco.x3),
                      orcamentos,
                      const SizedBox(height: Espaco.x3),
                      conversao,
                    ],
                  );
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: concluidas),
                        const SizedBox(width: Espaco.x3),
                        Expanded(child: andamento),
                      ],
                    ),
                    const SizedBox(height: Espaco.x3),
                    Row(
                      children: [
                        Expanded(child: orcamentos),
                        const SizedBox(width: Espaco.x3),
                        Expanded(child: conversao),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricaCard(String label, String valor, IconData icone, Color cor) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(Raio.botao),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: TamanhoIcone.medio),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(valor, style: texto.headlineMedium?.copyWith(color: c.ink)),
          ),
          const SizedBox(height: Espaco.x1),
          Text(
            label,
            style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildErro(String msg) {
    final c = context.cores;
    return SizedBox(
      width: double.infinity,
      child: CardApp(
        padding: const EdgeInsets.all(Espaco.x8),
        child: Column(
          children: [
            Icon(Symbols.error_rounded, size: 48, color: c.error),
            const SizedBox(height: Espaco.x3),
            Text(
              msg,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
