import '../entidades/usuario.dart';

abstract class RepositorioAutenticacao {
  // RF001 - Realizar Login utilizando CPF
  Future<Usuario?> entrarComCpfESenha(String cpf, String senha);

  // RF002 - Recuperar Senha via Firebase Auth
  Future<void> recuperarSenha(String email);

  // NOVO: Finaliza o primeiro acesso atualizando a senha e mudando a flag no banco
  Future<void> atualizarSenhaPrimeiroAcesso(String novaSenha);

  // Finalizar sessão
  Future<void> sair();

  // Stream para monitorar o estado de autenticação em tempo real
  Stream<Usuario?> get usuarioAtual;
}
