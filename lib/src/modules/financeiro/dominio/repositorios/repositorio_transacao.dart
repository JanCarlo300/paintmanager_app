import '../entidades/transacao.dart';

/// Contrato do repositório de Transações Financeiras.
/// Usa Future (Supabase) ao invés de Stream (Firebase).
abstract class RepositorioTransacao {
  Future<List<Transacao>> listarTransacoes();
  Future<void> salvarTransacao(Transacao transacao);
  Future<void> excluirTransacao(int id);
}
