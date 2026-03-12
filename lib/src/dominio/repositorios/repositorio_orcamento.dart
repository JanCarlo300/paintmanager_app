import '../entidades/orcamento.dart';

abstract class RepositorioOrcamento {
  Stream<List<Orcamento>> listarOrcamentos();
  Future<void> salvarOrcamento(Orcamento orcamento);
  Future<void> excluirOrcamento(String id);
}
