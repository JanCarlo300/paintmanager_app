import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../dominio/entidades/obra.dart';
import '../../dominio/repositorios/repositorio_obra.dart';
import '../modelos/obra_modelo.dart';

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
        anotacoes: obra.anotacoes,
        materiaisFaltantes: obra.materiaisFaltantes,
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
}
