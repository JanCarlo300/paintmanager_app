import '../entidades/relatorio_geral.dart';
import '../../../financeiro/dominio/entidades/transacao.dart';
import '../../../obras/dominio/entidades/obra.dart';
import '../../../orcamentos/dominio/entidades/orcamento.dart';

/// Contrato do repositório de Relatórios.
abstract class RepositorioRelatorio {
  Future<RelatorioGeral> gerarRelatorio(DateTime inicio, DateTime fim);

  // === Etapa 8.1 — dados dos PDFs (RF012) ===

  /// Lançamentos do período (opcionalmente só de uma obra).
  Future<List<Transacao>> listarLancamentos(DateTime inicio, DateTime fim, {int? obraId});

  /// Status das obras citadas nos lançamentos (id da obra -> status).
  Future<Map<int, String>> statusDasObras(Iterable<int> ids);

  /// Orçamentos Aprovados criados no período (opcionalmente de uma obra).
  Future<List<Orcamento>> listarOrcamentosAprovados(DateTime inicio, DateTime fim, {int? obraId});

  /// Obras já iniciadas cujo período cruza o período do relatório.
  Future<List<Obra>> listarObrasParaProgresso(DateTime inicio, DateTime fim, {int? obraId});

  /// Obras Não Iniciada cadastradas até o fim do período (seção "Obras a
  /// iniciar" do Relatório de Progresso).
  Future<List<Obra>> listarObrasAIniciar(DateTime fim, {int? obraId});
}
