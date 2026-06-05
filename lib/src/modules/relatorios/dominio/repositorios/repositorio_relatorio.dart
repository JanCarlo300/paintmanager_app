import '../entidades/relatorio_geral.dart';

/// Contrato do repositório de Relatórios.
abstract class RepositorioRelatorio {
  Future<RelatorioGeral> gerarRelatorio(DateTime inicio, DateTime fim);
}
