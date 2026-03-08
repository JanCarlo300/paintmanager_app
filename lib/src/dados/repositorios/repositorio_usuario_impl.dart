import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/repositorio_usuario.dart';
import '../modelos/usuario_modelo.dart';

class RepositorioUsuarioImpl implements RepositorioUsuario {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> salvarUsuario(Usuario usuario) async {
    try {
      // 1. Caso seja um NOVO usuário (Cadastro feito pelo ADM)
      if (usuario.id == null) {
        // Criamos uma instância secundária do Firebase para não deslogar o ADM atual
        FirebaseApp secondaryApp = await Firebase.initializeApp(
          name: 'AdminCreatingUser',
          options: Firebase.app().options,
        );

        try {
          // Criamos a senha inicial usando apenas os números do CPF
          String senhaInicial = usuario.cpf.replaceAll(RegExp(r'[^0-9]'), '');

          // Criamos o usuário no Firebase Authentication
          UserCredential credencial = await FirebaseAuth.instanceFor(app: secondaryApp)
              .createUserWithEmailAndPassword(
            email: usuario.email,
            password: senhaInicial,
          );

          // Criamos o modelo com o ID gerado pelo Auth e o status de Primeiro Acesso
          final modelo = UsuarioModelo(
            id: credencial.user!.uid, // O ID do documento será o UID do Auth
            nome: usuario.nome,
            email: usuario.email,
            cpf: usuario.cpf,
            telefone: usuario.telefone,
            funcao: usuario.funcao,
            status: usuario.status,
            senha: usuario.senha,
            primeiroAcesso: true, // Forçamos o primeiro acesso como true
            criadoEm: usuario.criadoEm,
          );

          // Salvamos no Firestore
          await _firestore.collection('usuarios').doc(credencial.user!.uid).set(modelo.paraMapa());
          
          // Limpamos a instância secundária
          await secondaryApp.delete();
          
        } catch (e) {
          await secondaryApp.delete();
          throw 'Erro ao criar conta no Firebase Auth: $e';
        }
      } 
      // 2. Caso seja uma ATUALIZAÇÃO de usuário existente
      else {
        final modelo = UsuarioModelo(
          id: usuario.id,
          nome: usuario.nome,
          email: usuario.email,
          cpf: usuario.cpf,
          telefone: usuario.telefone,
          funcao: usuario.funcao,
          status: usuario.status,
          senha: usuario.senha,
          primeiroAcesso: usuario.primeiroAcesso, // Mantém o estado atual
          criadoEm: usuario.criadoEm,
        );

        await _firestore.collection('usuarios').doc(usuario.id).update(modelo.paraMapa());
      }
    } catch (e) {
      throw 'Erro ao salvar/atualizar usuário no Firestore: $e';
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