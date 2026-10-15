import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../dominio/entidades/obra.dart';
import '../../dominio/repositorios/repositorio_obra.dart';
import '../modelos/obra_modelo.dart';
import '../modelos/mensagem_obra_modelo.dart';
import '../../dominio/entidades/mensagem_obra.dart';
import '../../../auth/dominio/entidades/usuario.dart';
import '../../../auth/dados/modelos/usuario_modelo.dart';

/// Implementação do repositório de Obras usando Supabase (PostgreSQL).
/// Todas as operações usam métodos nativos do SupabaseClient.
class RepositorioObraImpl implements RepositorioObra {
  final SupabaseClient _supabase = SupabaseConfig.client;

  @override
  Future<List<Obra>> listarObras() async {
    try {
      final resultado = await _supabase
          .from('obra')
          .select()
          .order('data_inicio', ascending: false);

      return (resultado as List)
          .map((mapa) => ObraModelo.deMapa(mapa))
          .toList();
    } catch (e) {
      throw 'Erro ao listar obras: $e';
    }
  }

  @override
  Future<void> salvarObra(Obra obra) async {
    try {
      final modelo = ObraModelo(
        id: obra.id,
        idOrcamento: obra.idOrcamento,
        idCliente: obra.idCliente,
        clienteNome: obra.clienteNome,
        tituloDaObra: obra.tituloDaObra,
        endereco: obra.endereco,
        dataInicio: obra.dataInicio,
        dataPrevisaoTermino: obra.dataPrevisaoTermino,
        dataConclusao: obra.dataConclusao,
        status: obra.status,
        progresso: obra.progresso,
        etapasServico: obra.etapasServico,
        materiaisFaltantes: obra.materiaisFaltantes,
        latitude: obra.latitude,
        longitude: obra.longitude,
      );

      if (obra.id == null) {
        // INSERT — nova obra
        await _supabase.from('obra').insert(modelo.paraMapa());
      } else {
        // UPDATE — obra existente
        await _supabase
            .from('obra')
            .update(modelo.paraMapa())
            .eq('id_obra', obra.id!);
      }
    } catch (e) {
      throw 'Erro ao salvar obra: $e';
    }
  }

  @override
  Future<void> excluirObra(int id) async {
    try {
      await _supabase.from('obra').delete().eq('id_obra', id);
    } catch (e) {
      throw 'Erro ao excluir obra: $e';
    }
  }

  // === RF010 - Alocar Equipe à Obra ===

  @override
  Future<List<Usuario>> listarFuncionariosAlocados(int obraId) async {
    try {
      final vinculos = await _supabase
          .from('equipe_obra')
          .select('usuario_id')
          .eq('obra_id', obraId);

      final idsAlocados = (vinculos as List)
          .map((v) => v['usuario_id'] as int)
          .toList();

      if (idsAlocados.isEmpty) return [];

      final usuarios = await _supabase
          .from('usuario')
          .select()
          .inFilter('id_usuario', idsAlocados);

      return (usuarios as List)
          .map((mapa) => UsuarioModelo.deMapa(mapa))
          .toList();
    } catch (e) {
      throw 'Erro ao listar equipe alocada: $e';
    }
  }

  @override
  Future<void> alocarFuncionario(int obraId, int usuarioId) async {
    try {
      await _supabase.from('equipe_obra').insert({
        'obra_id': obraId,
        'usuario_id': usuarioId,
      });
    } catch (e) {
      throw 'Erro ao alocar funcionário: $e';
    }
  }

  @override
  Future<void> desalocarFuncionario(int obraId, int usuarioId) async {
    try {
      await _supabase
          .from('equipe_obra')
          .delete()
          .eq('obra_id', obraId)
          .eq('usuario_id', usuarioId);
    } catch (e) {
      throw 'Erro ao desalocar funcionário: $e';
    }
  }

  @override
  Future<List<int>> listarObraIdsAlocados(int usuarioId) async {
    try {
      final vinculos = await _supabase
          .from('equipe_obra')
          .select('obra_id')
          .eq('usuario_id', usuarioId);

      return (vinculos as List).map((v) => v['obra_id'] as int).toList();
    } catch (e) {
      throw 'Erro ao listar obras alocadas: $e';
    }
  }

  @override
  Future<List<Obra>> buscarObras(String termo) async {
    try {
      final resultado = await _supabase.rpc('buscar_obras', params: {
        'termo': termo,
        'limite': 20,
      });
      return (resultado as List)
          .map((mapa) => ObraModelo.deMapa(Map<String, dynamic>.from(mapa)))
          .toList();
    } catch (e) {
      throw 'Erro ao buscar obras: $e';
    }
  }

  @override
  Future<List<Usuario>> buscarFuncionariosDisponiveis(int obraId, String termo) async {
    try {
      final resultado = await _supabase.rpc('buscar_funcionarios_disponiveis', params: {
        'p_obra_id': obraId,
        'termo': termo,
        'limite': 20,
      });
      return (resultado as List)
          .map((mapa) => UsuarioModelo.deMapa(Map<String, dynamic>.from(mapa)))
          .toList();
    } catch (e) {
      throw 'Erro ao buscar funcionários: $e';
    }
  }

  @override
  Future<bool> obraTemOrcamentoAprovado(int obraId) async {
    try {
      final resultado = await _supabase
          .from('orcamento')
          .select('id_orcamento')
          .eq('id_obra', obraId)
          .eq('status', 'Aprovado')
          .limit(1);
      return (resultado as List).isNotEmpty;
    } catch (e) {
      throw 'Erro ao verificar orçamento da obra: $e';
    }
  }

  // === Item 2.3 — Chat da Obra ===

  @override
  Stream<List<MensagemObra>> escutarMensagens(int obraId) {
    return _supabase
        .from('obra_mensagem')
        .stream(primaryKey: ['id_mensagem'])
        .eq('obra_id', obraId)
        .order('criado_em')
        .map((linhas) => linhas.map(MensagemObraModelo.deMapa).toList());
  }

  @override
  Future<void> enviarMensagem({required int obraId, required int usuarioId, required String texto}) async {
    try {
      await _supabase.from('obra_mensagem').insert({
        'obra_id': obraId,
        'usuario_id': usuarioId,
        'texto': texto,
      });
    } catch (e) {
      throw 'Erro ao enviar mensagem: $e';
    }
  }
}
