import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/repositorio_autenticacao.dart';
import '../modelos/usuario_modelo.dart';

class RepositorioAutenticacaoImpl implements RepositorioAutenticacao {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Usuario?> entrarComCpfESenha(String cpf, String senha) async {
    try {
      // 1. Busca o e-mail vinculado ao CPF no Firestore (RF001)
      final consulta = await _firestore
          .collection('usuarios')
          .where('cpf', isEqualTo: cpf)
          .limit(1)
          .get();

      if (consulta.docs.isEmpty) {
        throw 'CPF não cadastrado no sistema.';
      }

      final dadosUsuario = consulta.docs.first.data();
      final emailReal = dadosUsuario['email'];

      // 2. Faz o login no Firebase Auth usando o E-MAIL recuperado
      final UserCredential credencial = await _auth.signInWithEmailAndPassword(
        email: emailReal,
        password: senha,
      );

      if (credencial.user != null) {
        // Retorna o modelo preenchido com os dados do Firestore
        return UsuarioModelo.deMapa(dadosUsuario, consulta.docs.first.id);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Tratamento de erros específicos do Firebase
      if (e.code == 'user-not-found') throw 'Usuário não encontrado para este e-mail.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') throw 'Senha incorreta.';
      if (e.code == 'network-request-failed') throw 'Sem conexão com a internet.';
      throw e.message ?? 'Erro ao realizar login.';
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  Future<void> recuperarSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw 'Erro ao enviar e-mail de recuperação. Verifique o endereço.';
    }
  }

  @override
  Future<void> sair() async {
    await _auth.signOut();
  }

  @override
  Stream<Usuario?> get usuarioAtual {
    // Monitora o estado da autenticação (Persistent Session)
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;

      // Busca os dados do usuário no Firestore pelo e-mail (mais seguro que o UID se o cadastro for híbrido)
      final snapshot = await _firestore
          .collection('usuarios')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return UsuarioModelo.deMapa(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    });
  }
}