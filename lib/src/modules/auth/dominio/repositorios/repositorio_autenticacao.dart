import '../entidades/usuario.dart';

abstract class RepositorioAutenticacao {
  /// RF001 - Realizar Login utilizando CPF + Senha via Supabase Auth
  Future<Usuario?> entrarComCpfESenha(String cpf, String senha);

  /// RF002 - Busca o e-mail de um usuário ativo a partir do CPF ou e-mail
  /// (usa a função 'buscar_email_por_login' do banco). Retorna `null` se
  /// não encontrar — nunca revela se o CPF/e-mail existe no sistema.
  Future<String?> buscarEmailPorLogin(String cpfOuEmail);

  /// RF002 - Dispara o código de recuperação para o e-mail informado
  /// (tamanho definido pelo Supabase, não fixo no app)
  Future<void> recuperarSenha(String email);

  /// RF002 - Verifica o código recebido por e-mail. Em caso de
  /// sucesso, autentica uma sessão de recuperação de senha.
  Future<void> verificarCodigoRecuperacao(String email, String codigo);

  /// Busca o CPF do usuário autenticado no momento (usado para validar que
  /// a nova senha é diferente do CPF, tanto na recuperação quanto no
  /// primeiro acesso).
  Future<String?> buscarCpfUsuarioLogado();

  /// Define uma nova senha para o usuário autenticado e marca o primeiro
  /// acesso como concluído. Usado na recuperação (RF002) e na troca
  /// obrigatória de senha no primeiro login.
  Future<void> definirNovaSenha(String novaSenha);

  /// Finalizar sessão
  Future<void> sair();

  /// Stream para monitorar o estado de autenticação em tempo real
  Stream<Usuario?> get usuarioAtual;
}
