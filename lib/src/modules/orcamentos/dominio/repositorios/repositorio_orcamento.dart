import '../entidades/orcamento.dart';

/// Contrato do repositório de Orçamentos.
/// Usa Future (Supabase) ao invés de Stream (Firebase).
abstract class RepositorioOrcamento {
  Future<List<Orcamento>> listarOrcamentos();
  Future<void> salvarOrcamento(Orcamento orcamento);
  Future<void> excluirOrcamento(int id);
}
