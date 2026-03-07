import '../entidades/usuario.dart';

abstract class RepositorioAutenticacao {
  // RF001 - Realizar Login utilizando CPF para buscar o e-mail no Firestore
  // Alterado de entrarComEmailESenha para entrarComCpfESenha para alinhar com o Controller
  Future<Usuario?> entrarComCpfESenha(String cpf, String senha);

  // RF002 - Recuperar Senha
  // Mantemos o e-mail aqui, pois o Firebase Auth exige e-mail para o link de redefinição
  Future<void> recuperarSenha(String email);

  // Finalizar sessão
  Future<void> sair();

  // Stream para monitorar se o usuário está logado em tempo real
  Stream<Usuario?> get usuarioAtual;
}