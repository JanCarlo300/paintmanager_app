import '../entidades/obra.dart';

abstract class RepositorioObra {
  Stream<List<Obra>> listarObras();
  Future<void> salvarObra(Obra obra);
  Future<void> excluirObra(String id);
}
