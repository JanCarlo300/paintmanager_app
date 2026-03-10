import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/cliente.dart';
import '../../dominio/repositorios/repositorio_cliente.dart';
import '../modelos/cliente_modelo.dart'; // O import agora será utilizado abaixo

class RepositorioClienteImpl implements RepositorioCliente {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Cliente>> listarClientes() {
    return _firestore
        .collection('clientes')
        .orderBy('nome')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClienteModelo.deMapa(doc.data(), doc.id)) // USO DO MODELO AQUI
            .toList());
  }

  @override
  Future<void> salvarCliente(Cliente cliente) async {
    // Convertemos a Entidade em Modelo para usar o 'paraMapa()'
    final modelo = ClienteModelo(
      id: cliente.id,
      nome: cliente.nome,
      email: cliente.email,
      telefone: cliente.telefone,
      endereco: cliente.endereco,
      cpfOuCnpj: cliente.cpfOuCnpj,
      criadoEm: cliente.criadoEm,
    );

    if (cliente.id == null) {
      // Criação de novo cliente
      await _firestore.collection('clientes').add(modelo.paraMapa());
    } else {
      // Atualização de cliente existente
      await _firestore.collection('clientes').doc(cliente.id).update(modelo.paraMapa());
    }
  }

  @override
  Future<void> excluirCliente(String id) async {
    await _firestore.collection('clientes').doc(id).delete();
  }
}