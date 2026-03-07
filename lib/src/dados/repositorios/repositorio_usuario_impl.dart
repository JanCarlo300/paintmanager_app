import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/repositorio_usuario.dart';
import '../modelos/usuario_modelo.dart';

class RepositorioUsuarioImpl implements RepositorioUsuario {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> salvarUsuario(Usuario usuario) async {
    try {
      final modelo = UsuarioModelo(
        id: usuario.id,
        nome: usuario.nome,
        email: usuario.email,
        cpf: usuario.cpf,
        telefone: usuario.telefone,
        funcao: usuario.funcao,
        status: usuario.status,
        senha: usuario.senha, 
        criadoEm: usuario.criadoEm,
      );

      if (usuario.id == null) {
        // Cria novo usuário
        await _firestore.collection('usuarios').add(modelo.paraMapa());
      } else {
        // Atualiza usuário existente (é aqui que a inativação acontece)
        await _firestore.collection('usuarios').doc(usuario.id).update(modelo.paraMapa());
      }
    } catch (e) {
      throw 'Erro ao salvar/atualizar usuário: $e';
    }
  }

  @override
  Stream<List<Usuario>> listarUsuarios() {
    return _firestore.collection('usuarios').orderBy('nome').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UsuarioModelo.deMapa(doc.data(), doc.id);
      }).toList();
    });
  }
}