import '../entidades/transacao.dart';

abstract class RepositorioTransacao {
  Stream<List<Transacao>> listarTransacoes();
  Future<void> salvarTransacao(Transacao transacao);
  Future<void> excluirTransacao(String id);
}
