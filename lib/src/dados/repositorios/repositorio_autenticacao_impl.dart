import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/repositorio_autenticacao.dart';
import '../modelos/usuario_modelo.dart';

class RepositorioAutenticacaoImpl implements RepositorioAutenticacao {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Usuario?> entrarComEmailESenha(String email, String senha) async {
    try {
      // 1. Autentica o usuário no Firebase Auth (RF001)
      final UserCredential credencial = await _auth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );

      if (credencial.user != null) {
        // 2. Busca os dados complementares no Firestore (Coleção 'usuarios')
        final snapshot = await _firestore
            .collection('usuarios')
            .doc(credencial.user!.uid)
            .get();

        if (snapshot.exists) {
          // Converte o mapa do Firestore para o nosso modelo e retorna como entidade
          return UsuarioModelo.deMapa(snapshot.data()!, snapshot.id);
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Tratamento básico de erros em português para facilitar seu entendimento
      if (e.code == 'user-not-found') throw 'Usuário não encontrado.';
      if (e.code == 'wrong-password') throw 'Senha incorreta.';
      throw e.message ?? 'Erro ao realizar login.';
    }
  }

  @override
  Future<void> recuperarSenha(String email) async {
    // RF002 - Envia e-mail de recuperação
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sair() async {
    await _auth.signOut();
  }

  @override
  Stream<Usuario?> get usuarioAtual {
    // Monitora o estado da autenticação em tempo real
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (snapshot.exists) {
        return UsuarioModelo.deMapa(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }
}
