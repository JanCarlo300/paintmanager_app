import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/obra.dart';
import '../../dominio/entidades/etapa_servico.dart';
import '../../dominio/repositorios/repositorio_obra.dart';
import '../modelos/obra_modelo.dart';

class RepositorioObraImpl implements RepositorioObra {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Obra>> listarObras() {
    return _firestore
        .collection('obras')
        .orderBy('dataInicio', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ObraModelo.deMapa(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> salvarObra(Obra obra) async {
    final modelo = ObraModelo(
      id: obra.id,
      orcamentoId: obra.orcamentoId,
      clienteId: obra.clienteId,
      clienteNome: obra.clienteNome,
      tituloDaObra: obra.tituloDaObra,
      endereco: obra.endereco,
      dataInicio: obra.dataInicio,
      dataPrevisaoTermino: obra.dataPrevisaoTermino,
      dataConclusao: obra.dataConclusao,
      status: obra.status,
      progresso: obra.progresso,
      etapasServico: obra.etapasServico,
      anotacoes: obra.anotacoes,
      materiaisFaltantes: obra.materiaisFaltantes,
    );

    if (obra.id == null) {
      await _firestore.collection('obras').add(modelo.paraMapa());
    } else {
      await _firestore.collection('obras').doc(obra.id).update(modelo.paraMapa());
    }
  }

  @override
  Future<void> excluirObra(String id) async {
    await _firestore.collection('obras').doc(id).delete();
  }
}
