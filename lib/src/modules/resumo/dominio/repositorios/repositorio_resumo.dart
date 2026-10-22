import '../entidades/alerta.dart';
import '../entidades/resumo_geral.dart';

/// Contrato do repositório do Resumo Geral.
abstract class RepositorioResumo {
  /// Números do mês de [agora] e as 3 obras de início mais recente.
  Future<ResumoGeral> carregarResumo(DateTime agora);

  /// Dados para os alertas (a regra fica em calcularAlertas).
  Future<List<OrcamentoPendente>> listarOrcamentosPendentes();
  Future<List<ObraEmAberto>> listarObrasEmAberto();
}
