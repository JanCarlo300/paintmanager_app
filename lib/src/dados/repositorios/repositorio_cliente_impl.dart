import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/cliente.dart';
import '../../dominio/repositorios/repositorio_cliente.dart';
import '../modelos/cliente_model.dart';

class RepositorioClienteImpl implements RepositorioCliente {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> cadastrarCliente(Cliente cliente) async {
    final model = ClienteModel(
      nome: cliente.nome,
      telefone: cliente.telefone,
      email: cliente.email,
      endereco: cliente.endereco,
    );
    await _firestore.collection('clientes').add(model.toMap());
  }

  @override
  Future<void> editarCliente(Cliente cliente) async {
    final model = ClienteModel(
      nome: cliente.nome,
      telefone: cliente.telefone,
      email: cliente.email,
      endereco: cliente.endereco,
    );
    await _firestore
        .collection('clientes')
        .doc(cliente.id)
        .update(model.toMap());
  }

  @override
  Future<void> excluirCliente(String id) async {
    await _firestore.collection('clientes').doc(id).delete();
  }

  @override
  Stream<List<Cliente>> listarClientes() {
    return _firestore.collection('clientes').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ClienteModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}
