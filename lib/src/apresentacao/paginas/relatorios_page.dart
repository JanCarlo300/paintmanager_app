import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../dominio/entidades/relatorio_geral.dart';
import '../controllers/relatorio_controller.dart';
import '../widgets/drawer_comum.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  static const _coresCategorias = [
    Color(0xFF2196F3), Color(0xFFF44336), Color(0xFFFF9800),
    Color(0xFF4CAF50), Color(0xFF9C27B0), Color(0xFF009688),
    Color(0xFFFFC107), Color(0xFF607D8B),
  ];

  @override
  void initState() {
    super.initState();
    // Carregar relatório ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RelatorioController>().carregarRelatorio();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RelatorioController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: const DrawerComum(),
      appBar: AppBar(
        leading: Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(ctx).openDrawer())),
        title: const Text("Relatórios", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            const Text("Dashboard Analítico", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Acompanhe os indicadores do seu negócio.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // --- FILTRO DE PERÍODO ---
            _buildFiltroPeriodo(controller),
            const SizedBox(height: 24),

            // --- CONTEÚDO ---
            if (controller.carregando)
              const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator(color: Colors.black)),
              )
            else if (controller.erro != null)
              _buildMensagemVazia(controller.erro!, Icons.error_outline, Colors.red)
            else if (controller.relatorio == null)
              _buildMensagemVazia("Selecione um período e clique em filtrar.", Icons.filter_alt_outlined, Colors.grey)
            else
              _buildConteudoRelatorio(controller.relatorio!),
          ],
        ),
      ),
    );
  }

  // === FILTRO DE PERÍODO ===
  Widget _buildFiltroPeriodo(RelatorioController controller) {
    final filtros = ['Últimos 7 dias', 'Este Mês', 'Últimos 30 dias', 'Últimos 90 dias', 'Este Ano'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              const Text("Período", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text("${_formatoData.format(controller.inicio)} - ${_formatoData.format(controller.fim)}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ...filtros.map((f) => ChoiceChip(
                label: Text(f, style: TextStyle(fontSize: 12, fontWeight: controller.filtroSelecionado == f ? FontWeight.bold : FontWeight.normal)),
                selected: controller.filtroSelecionado == f,
                selectedColor: Colors.black,
                labelStyle: TextStyle(color: controller.filtroSelecionado == f ? Colors.white : Colors.grey[700]),
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: BorderSide.none,
                onSelected: (_) => controller.alterarFiltro(f),
              )),
              ActionChip(
                label: const Text("Personalizado", style: TextStyle(fontSize: 12)),
                avatar: const Icon(Icons.edit_calendar, size: 16),
                backgroundColor: controller.filtroSelecionado == 'Personalizado' ? Colors.black : Colors.grey[100],
                labelStyle: TextStyle(color: controller.filtroSelecionado == 'Personalizado' ? Colors.white : Colors.grey[700]),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: BorderSide.none,
                onPressed: () => _selecionarPeriodoPersonalizado(controller),
              ),
            ],
          ),
        ],
      ),
    );
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
      return _buildMensagemVazia("Nenhuma movimentação encontrada neste período.", Icons.inbox_outlined, Colors.grey);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- CARDS KPI ---
        _buildKPIs(rel),
        const SizedBox(height: 24),

        // --- GRÁFICO DE BARRAS: Receitas vs Despesas ---
        _buildGraficoBarras(rel),
        const SizedBox(height: 24),

        // --- GRÁFICO DE PIZZA: Despesas por Categoria ---
        _buildGraficoPizza(rel),
        const SizedBox(height: 24),

        // --- MÉTRICAS DE OPERAÇÃO ---
        _buildMetricasOperacao(rel),
        const SizedBox(height: 24),
      ],
    );
  }

  // === CARDS KPI ===
  Widget _buildKPIs(RelatorioGeral rel) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _kpiCard("Receitas", _formatoMoeda.format(rel.totalReceitas), Colors.green, Icons.trending_up)),
            const SizedBox(width: 12),
            Expanded(child: _kpiCard("Despesas", _formatoMoeda.format(rel.totalDespesas), Colors.red, Icons.trending_down)),
          ],
        ),
        const SizedBox(height: 12),
        _kpiCard(
          "Lucro Líquido",
          _formatoMoeda.format(rel.lucroLiquido),
          rel.lucroLiquido >= 0 ? Colors.blue : Colors.red,
          rel.lucroLiquido >= 0 ? Icons.sentiment_satisfied_alt : Icons.sentiment_dissatisfied,
        ),
      ],
    );
  }

  Widget _kpiCard(String titulo, String valor, Color cor, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        border: Border(top: BorderSide(color: cor, width: 3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 8),
              Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cor)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icone, color: cor, size: 24),
          ),
        ],
      ),
    );
  }

  // === GRÁFICO DE BARRAS ===
  Widget _buildGraficoBarras(RelatorioGeral rel) {
    if (rel.receitasPorMes.isEmpty && rel.despesasPorMes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Unir meses de receitas e despesas
    final meses = {...rel.receitasPorMes.keys, ...rel.despesasPorMes.keys}.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              const Text("Receitas vs Despesas", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          // Legenda
          Row(
            children: [
              _legendaItem("Receitas", Colors.green),
              const SizedBox(width: 16),
              _legendaItem("Despesas", Colors.red),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxValorBarras(rel) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gi, rod, ri) {
                      final valor = rod.toY;
                      return BarTooltipItem(
                        _formatoMoeda.format(valor),
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(meses[idx], style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
                      getTitlesWidget: (val, meta) => Text(
                        _formatarValorCurto(val),
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _maxValorBarras(rel) / 4,
                  getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(meses.length, (i) {
                  final mes = meses[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: rel.receitasPorMes[mes] ?? 0,
                        color: Colors.green,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: rel.despesasPorMes[mes] ?? 0,
                        color: Colors.red,
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
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
  ]);

  String _formatarValorCurto(double valor) {
    if (valor >= 1000) return '${(valor / 1000).toStringAsFixed(1)}K';
    return valor.toStringAsFixed(0);
  }

  // === GRÁFICO DE PIZZA ===
  Widget _buildGraficoPizza(RelatorioGeral rel) {
    if (rel.despesasPorCategoria.isEmpty) return const SizedBox.shrink();

    final total = rel.despesasPorCategoria.values.fold<double>(0, (s, v) => s + v);
    final categorias = rel.despesasPorCategoria.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              const Text("Despesas por Categoria", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: List.generate(categorias.length, (i) {
                        final cat = categorias[i];
                        final pct = (cat.value / total) * 100;
                        return PieChartSectionData(
                          color: _coresCategorias[i % _coresCategorias.length],
                          value: cat.value,
                          title: '${pct.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          radius: 50,
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(categorias.length, (i) {
                      final cat = categorias[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(
                              color: _coresCategorias[i % _coresCategorias.length], borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 6),
                            Expanded(child: Text(cat.key, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          // Detalhamento por categoria
          ...categorias.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(cat.key, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                Text(_formatoMoeda.format(cat.value), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // === MÉTRICAS DE OPERAÇÃO ===
  Widget _buildMetricasOperacao(RelatorioGeral rel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              const Text("Métricas de Operação", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _metricaCard("Obras Concluídas", rel.quantidadeObrasConcluidas.toString(), Icons.check_circle_outline, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _metricaCard("Obras em Andamento", rel.quantidadeObrasEmAndamento.toString(), Icons.construction, Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _metricaCard("Orçamentos Gerados", rel.totalOrcamentosGerados.toString(), Icons.request_quote_outlined, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _metricaCard("Taxa de Conversão", "${rel.taxaConversaoOrcamentos.toStringAsFixed(1)}%", Icons.trending_up, Colors.purple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricaCard(String label, String valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 28),
          const SizedBox(height: 8),
          Text(valor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: cor)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMensagemVazia(String msg, IconData icone, Color cor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icone, size: 48, color: cor.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: Colors.grey[600], fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
