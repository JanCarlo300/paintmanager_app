import '../entidades/orcamento.dart';

/// Contrato do repositório de Orçamentos.
abstract class RepositorioOrcamento {
  Future<List<Orcamento>> listarOrcamentos({bool maisRecentes = true});
  Future<void> salvarOrcamento(Orcamento orcamento);
  Future<void> excluirOrcamento(int id);
}
