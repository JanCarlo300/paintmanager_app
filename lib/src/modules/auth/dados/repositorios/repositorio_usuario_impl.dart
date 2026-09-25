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
        // Cria a conta inteiramente no servidor (Edge Function), sem
        // tocar na sessão de quem está chamando. Ver supabase/functions/criar-usuario.
        try {
          await _supabase.functions.invoke(
            'criar-usuario',
            body: {
              'nome': usuario.nome,
              'email': usuario.email,
              'cpf': usuario.cpf,
              'telefone': usuario.telefone,
              'funcao': usuario.funcao,
            },
          );
        } on FunctionException catch (e) {
          final detalhes = e.details;
          if (detalhes is Map && detalhes['error'] is String) {
            throw detalhes['error'] as String;
          }
          throw 'Erro ao criar usuário.';
        }
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
