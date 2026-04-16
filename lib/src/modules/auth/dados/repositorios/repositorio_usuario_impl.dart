import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../dominio/entidades/usuario.dart';
import '../../dominio/repositorios/repositorio_usuario.dart';
import '../modelos/usuario_modelo.dart';

class RepositorioUsuarioImpl implements RepositorioUsuario {
  final SupabaseClient _supabase = SupabaseConfig.client;

  @override
  Future<void> salvarUsuario(Usuario usuario) async {
    try {
      // 1. Caso seja um NOVO usuário (cadastro pelo ADM)
      if (usuario.id == null) {
        // Cria a senha inicial usando apenas os números do CPF
        final senhaInicial = usuario.cpf.replaceAll(RegExp(r'[^0-9]'), '');

        // Cria o usuário no Supabase Auth via signUp
        final response = await _supabase.auth.signUp(
          email: usuario.email,
          password: senhaInicial,
        );

        final novoAuthId = response.user?.id;
        if (novoAuthId == null) {
          throw 'Erro ao criar conta: usuário não retornado pelo Supabase Auth.';
        }

        // Insere o registro na tabela 'usuario' do PostgreSQL
        final modelo = UsuarioModelo(
          authId: novoAuthId,
          nome: usuario.nome,
          email: usuario.email,
          cpf: usuario.cpf,
          telefone: usuario.telefone,
          funcao: usuario.funcao,
          status: usuario.status,
          primeiroAcesso: true,
          criadoEm: usuario.criadoEm,
        );

        await _supabase.from('usuario').insert(modelo.paraMapa());

        // Restaura a sessão do ADM que fez o cadastro
        // O signUp pode ter trocado a sessão — fazemos refresh
        await _supabase.auth.refreshSession();
      }
      // 2. Caso seja uma ATUALIZAÇÃO de usuário existente
      else {
        final modelo = UsuarioModelo(
          id: usuario.id,
          authId: usuario.authId,
          nome: usuario.nome,
          email: usuario.email,
          cpf: usuario.cpf,
          telefone: usuario.telefone,
          funcao: usuario.funcao,
          status: usuario.status,
          primeiroAcesso: usuario.primeiroAcesso,
          criadoEm: usuario.criadoEm,
        );

        await _supabase
            .from('usuario')
            .update(modelo.paraMapa())
            .eq('id_usuario', usuario.id!);
      }
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        throw 'Este e-mail já está cadastrado no sistema.';
      }
      throw 'Erro ao criar conta: ${e.message}';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Erro ao salvar/atualizar usuário: $e';
    }
  }

  @override
  Future<List<Usuario>> listarUsuarios() async {
    try {
      final resultado = await _supabase
          .from('usuario')
          .select()
          .order('nome', ascending: true);

      return (resultado as List)
          .map((mapa) => UsuarioModelo.deMapa(mapa))
          .toList();
    } catch (e) {
      throw 'Erro ao listar usuários: $e';
    }
  }
}
