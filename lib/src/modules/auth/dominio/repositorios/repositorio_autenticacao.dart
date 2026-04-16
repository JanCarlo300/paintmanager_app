import '../entidades/usuario.dart';

abstract class RepositorioAutenticacao {
  /// RF001 - Realizar Login utilizando CPF + Senha via Supabase Auth
  Future<Usuario?> entrarComCpfESenha(String cpf, String senha);

  /// RF002 - Recuperar Senha via Supabase Auth
  Future<void> recuperarSenha(String email);

  /// Finaliza o primeiro acesso atualizando a senha e a flag no banco
  Future<void> atualizarSenhaPrimeiroAcesso(String novaSenha);

  /// Finalizar sessão
  Future<void> sair();

  /// Stream para monitorar o estado de autenticação em tempo real
  Stream<Usuario?> get usuarioAtual;
}
