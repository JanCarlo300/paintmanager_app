import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/orcamento.dart';
import '../../dominio/entidades/item_servico.dart';
import '../../dominio/repositorios/repositorio_orcamento.dart';
import '../modelos/orcamento_modelo.dart';

class RepositorioOrcamentoImpl implements RepositorioOrcamento {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Orcamento>> listarOrcamentos() {
    return _firestore
        .collection('orcamentos')
        .orderBy('dataCriacao', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrcamentoModelo.deMapa(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> salvarOrcamento(Orcamento orcamento) async {
    final modelo = OrcamentoModelo(
      id: orcamento.id,
      clienteId: orcamento.clienteId,
      clienteNome: orcamento.clienteNome,
      descricao: orcamento.descricao,
      dataCriacao: orcamento.dataCriacao,
      dataValidade: orcamento.dataValidade,
      status: orcamento.status,
      itensServico: orcamento.itensServico,
      materiaisInclusos: orcamento.materiaisInclusos,
      valorMateriais: orcamento.valorMateriais,
      valorMaoDeObra: orcamento.valorMaoDeObra,
      desconto: orcamento.desconto,
      valorTotal: orcamento.valorTotal,
      formaPagamento: orcamento.formaPagamento,
    );

    if (orcamento.id == null) {
      await _firestore.collection('orcamentos').add(modelo.paraMapa());
    } else {
      await _firestore.collection('orcamentos').doc(orcamento.id).update(modelo.paraMapa());
    }
  }

  @override
  Future<void> excluirOrcamento(String id) async {
    await _firestore.collection('orcamentos').doc(id).delete();
  }
}
