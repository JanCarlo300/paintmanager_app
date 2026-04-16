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

      // 1. Busca APENAS o e-mail vinculado ao CPF na tabela 'usuario' (anônimo)
      final authData = await _supabase
          .from('usuario')
          .select('email')
          .eq('cpf', cleanCpf)
          .maybeSingle();

      if (authData == null) {
        throw 'CPF não cadastrado no sistema.';
      }

      final emailReal = authData['email'] as String;

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
  Future<void> atualizarSenhaPrimeiroAcesso(String novaSenha) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'Sessão expirada. Refaça o login.';

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
  Future<void> recuperarSenha(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (_) {
      throw 'Erro ao enviar e-mail de recuperação. Verifique o endereço.';
    } catch (_) {
      throw 'Erro ao enviar e-mail de recuperação. Verifique o endereço.';
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
      print("Session found! User ID: $userId");
      final resultado = await _supabase
          .from('usuario')
          .select()
          .eq('auth_id', userId)
          .maybeSingle();

      print("Resultado tabela usuario: $resultado");
      if (resultado == null) return null;

      return UsuarioModelo.deMapa(resultado);
    });
  }
}
