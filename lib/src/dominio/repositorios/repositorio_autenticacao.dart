import '../entidades/usuario.dart';

abstract class RepositorioAutenticacao {
  // RF001 - Realizar Login [cite: 223]
  Future<Usuario?> entrarComEmailESenha(String email, String senha);

  // RF002 - Recuperar Senha [cite: 226]
  Future<void> recuperarSenha(String emailOuCpf);

  // Finalizar sessão
  Future<void> sair();

  // Stream para monitorar se o usuário está logado em tempo real
  Stream<Usuario?> get usuarioAtual;
}
