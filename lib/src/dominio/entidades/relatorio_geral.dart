class RelatorioGeral {
  final DateTime periodoInicio;
  final DateTime periodoFim;
  final double totalReceitas;
  final double totalDespesas;
  final int quantidadeObrasConcluidas;
  final int quantidadeObrasEmAndamento;
  final int totalOrcamentosGerados;
  final int totalOrcamentosAprovados;
  final Map<String, double> despesasPorCategoria;
  final Map<String, double> receitasPorMes;
  final Map<String, double> despesasPorMes;

  RelatorioGeral({
    required this.periodoInicio,
    required this.periodoFim,
    required this.totalReceitas,
    required this.totalDespesas,
    required this.quantidadeObrasConcluidas,
    required this.quantidadeObrasEmAndamento,
    required this.totalOrcamentosGerados,
    required this.totalOrcamentosAprovados,
    required this.despesasPorCategoria,
    required this.receitasPorMes,
    required this.despesasPorMes,
  });

  /// Lucro líquido = Receitas - Despesas
  double get lucroLiquido => totalReceitas - totalDespesas;

  /// Taxa de conversão = Aprovados / Gerados * 100
  double get taxaConversaoOrcamentos =>
      totalOrcamentosGerados > 0
          ? (totalOrcamentosAprovados / totalOrcamentosGerados) * 100
          : 0;
}
