import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/transacao.dart';
import '../../dominio/repositorios/repositorio_transacao.dart';
import '../modelos/transacao_modelo.dart';

class RepositorioTransacaoImpl implements RepositorioTransacao {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Transacao>> listarTransacoes() {
    return _firestore
        .collection('transacoes')
        .orderBy('dataTransacao', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransacaoModelo.deMapa(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> salvarTransacao(Transacao transacao) async {
    final modelo = TransacaoModelo(
      id: transacao.id,
      tipo: transacao.tipo,
      categoria: transacao.categoria,
      valor: transacao.valor,
      descricao: transacao.descricao,
      dataTransacao: transacao.dataTransacao,
      status: transacao.status,
      formaPagamento: transacao.formaPagamento,
      obraId: transacao.obraId,
      clienteId: transacao.clienteId,
      clienteNome: transacao.clienteNome,
      obraTitulo: transacao.obraTitulo,
      comprovanteUrl: transacao.comprovanteUrl,
    );

    if (transacao.id == null) {
      await _firestore.collection('transacoes').add(modelo.paraMapa());
    } else {
      await _firestore.collection('transacoes').doc(transacao.id).update(modelo.paraMapa());
    }
  }

  @override
  Future<void> excluirTransacao(String id) async {
    await _firestore.collection('transacoes').doc(id).delete();
  }
}
