import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/cliente.dart';
import '../../dominio/repositorios/repositorio_cliente.dart';
import '../modelos/cliente_modelo.dart';

class RepositorioClienteImpl implements RepositorioCliente {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Cliente>> listarClientes() {
    return _firestore
        .collection('clientes')
        .orderBy('nome')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClienteModelo.deMapa(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> salvarCliente(Cliente cliente) async {
    final modelo = ClienteModelo(
      id: cliente.id,
      nome: cliente.nome,
      email: cliente.email,
      telefone: cliente.telefone,
      endereco: cliente.endereco,
      cpfOuCnpj: cliente.cpfOuCnpj,
      criadoEm: cliente.criadoEm,
      ativo: cliente.ativo,
    );

    if (cliente.id == null) {
      await _firestore.collection('clientes').add(modelo.paraMapa());
    } else {
      await _firestore.collection('clientes').doc(cliente.id).update(modelo.paraMapa());
    }
  }

  @override
  Future<void> excluirCliente(String id) async {
    await _firestore.collection('clientes').doc(id).delete();
  }

  @override
  Future<void> atualizarStatus(String id, bool ativo) async {
    await _firestore.collection('clientes').doc(id).update({'ativo': ativo});
  }
}