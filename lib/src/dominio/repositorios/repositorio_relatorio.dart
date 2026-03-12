import '../entidades/relatorio_geral.dart';

abstract class RepositorioRelatorio {
  Future<RelatorioGeral> gerarRelatorio(DateTime inicio, DateTime fim);
}
