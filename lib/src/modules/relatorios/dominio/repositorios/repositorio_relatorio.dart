import '../entidades/relatorio_geral.dart';

/// Contrato do repositório de Relatórios.
/// Usa Future (Supabase) ao invés de Stream (Firebase).
abstract class RepositorioRelatorio {
  Future<RelatorioGeral> gerarRelatorio(DateTime inicio, DateTime fim);
}
