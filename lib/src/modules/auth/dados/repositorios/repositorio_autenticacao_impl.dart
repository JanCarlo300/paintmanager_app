import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/repositorio_autenticacao.dart';
import '../modelos/usuario_modelo.dart';

class RepositorioAutenticacaoImpl implements RepositorioAutenticacao {
  final SupabaseClient _supabase = SupabaseConfig.client;

  @override
  Future<Usuario?> entrarComCpfESenha(String cpf, String senha) async {
    try {
      // Garante sanitização: remove qualquer caractere que não seja número
      final cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

      // 1. Descobre o e-mail pelo CPF via função segura do banco: sem sessão,
      // ninguém lê a tabela 'usuario' — a função devolve só o e-mail de um
      // usuário ativo, nada mais.
      final String? emailReal;
      try {
        emailReal = await _supabase.rpc(
          'buscar_email_por_login',
          params: {'p_login': cleanCpf},
        ) as String?;
      } catch (_) {
        throw 'Não foi possível conectar ao servidor. Verifique sua internet e tente novamente.';
      }

      // Mesma mensagem de senha errada: não revela se o CPF existe.
      if (emailReal == null || emailReal.isEmpty) {
        throw 'CPF ou senha incorretos.';
      }

      // 2. Faz o login no Supabase Auth usando o e-mail recuperado
      final authResponse = await _supabase.auth.signInWithPassword(
        email: emailReal,
        password: senha,
      );

      if (authResponse.user == null) {
        throw 'Falha ao autenticar usuário.';
      }

      // 3. Agora autenticado (RLS liberado), busca todos os dados do usuário
      final resultado = await _supabase
          .from('usuario')
          .select('id_usuario, auth_id, nome, email, cpf, telefone, funcao, status, primeiro_acesso, criado_em')
          .eq('auth_id', authResponse.user!.id)
          .maybeSingle();

      if (resultado == null) {
        throw 'Dados do usuário não encontrados na base principal.';
      }

      // 4. Verifica se o usuário está ativo
      final statusUsuario = resultado['status'] as bool? ?? true;
      if (!statusUsuario) {
        throw 'Usuário inativo. Entre em contato com o administrador.';
      }

      return UsuarioModelo.deMapa(resultado);
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw 'CPF ou senha incorretos.';
      }
      if (e.message.contains('Email not confirmed')) {
        throw 'E-mail não confirmado. Verifique sua caixa de entrada.';
      }
      throw e.message;
    } catch (e) {
      // Re-throw mensagens customizadas (strings) sem prefixo
      if (e is String) rethrow;
      throw 'Erro ao realizar login: ${e.toString()}';
    }
  }

  @override
  Future<String?> buscarEmailPorLogin(String cpfOuEmail) async {
    try {
      final resultado = await _supabase.rpc(
        'buscar_email_por_login',
        params: {'p_login': cpfOuEmail},
      );
      return resultado as String?;
    } catch (_) {
      // Falha de rede/infra: tratamos como "não encontrado" para não
      // travar o fluxo nem revelar detalhes técnicos ao usuário.
      return null;
    }
  }

  @override
  Future<void> recuperarSenha(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (_) {
      throw 'Erro ao enviar código de recuperação. Tente novamente.';
    } catch (_) {
      throw 'Erro ao enviar código de recuperação. Tente novamente.';
    }
  }

  @override
  Future<void> verificarCodigoRecuperacao(String email, String codigo) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: codigo,
        type: OtpType.recovery,
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('expired')) {
        throw 'Código expirado. Solicite um novo código.';
      }
      throw 'Código inválido. Verifique e tente novamente.';
    } catch (_) {
      throw 'Código inválido. Verifique e tente novamente.';
    }
  }

  @override
  Future<String?> buscarCpfUsuarioLogado() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final resultado = await _supabase
        .from('usuario')
        .select('cpf')
        .eq('auth_id', user.id)
        .maybeSingle();

    return resultado?['cpf'] as String?;
  }

  @override
  Future<void> definirNovaSenha(String novaSenha) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'Sessão expirada. Refaça o processo.';

      // 1. Atualiza a senha no Supabase Auth
      await _supabase.auth.updateUser(
        UserAttributes(password: novaSenha),
      );

      // 2. Atualiza a flag 'primeiro_acesso' na tabela 'usuario'
      await _supabase
          .from('usuario')
          .update({'primeiro_acesso': false})
          .eq('auth_id', user.id);
    } on AuthException catch (e) {
      throw 'Erro ao atualizar senha: ${e.message}';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Erro técnico: ${e.toString()}';
    }
  }

  @override
  Future<void> alterarSenha(String senhaAtual, String novaSenha) async {
    final email = _supabase.auth.currentUser?.email;
    if (email == null) throw 'Sessão expirada. Entre novamente.';

    // 1. Confere a senha atual: quem pegar o celular desbloqueado não troca
    // a senha sem saber a antiga.
    try {
      await _supabase.auth.signInWithPassword(email: email, password: senhaAtual);
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw 'Senha atual incorreta.';
      }
      throw 'Não foi possível conferir a senha atual. Tente novamente.';
    } catch (_) {
      throw 'Não foi possível conectar ao servidor. Verifique sua internet e tente novamente.';
    }

    // 2. Grava a nova senha
    try {
      await _supabase.auth.updateUser(UserAttributes(password: novaSenha));
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('different from the old')) {
        throw 'A nova senha deve ser diferente da atual.';
      }
      throw 'Erro ao alterar senha: ${e.message}';
    } catch (_) {
      throw 'Não foi possível conectar ao servidor. Verifique sua internet e tente novamente.';
    }
  }

  @override
  Future<void> sair() async {
    await _supabase.auth.signOut();
  }

  @override
  Stream<Usuario?> get usuarioAtual {
    // Emite o estado atual + escuta mudanças futuras
    return _supabase.auth.onAuthStateChange.asyncMap((data) async {
      final session = data.session;
      if (session == null) return null;

      final userId = session.user.id;

      // Busca dados completos do usuário na tabela 'usuario'
      final resultado = await _supabase
          .from('usuario')
          .select()
          .eq('auth_id', userId)
          .maybeSingle();

      if (resultado == null) return null;

      return UsuarioModelo.deMapa(resultado);
    });
  }
}
