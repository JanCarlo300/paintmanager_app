import '../entidades/obra.dart';

/// Contrato do repositório de Obras.
/// Usa Future (Supabase) ao invés de Stream (Firebase).
abstract class RepositorioObra {
  Future<List<Obra>> listarObras();
  Future<void> salvarObra(Obra obra);
  Future<void> excluirObra(int id);
}
