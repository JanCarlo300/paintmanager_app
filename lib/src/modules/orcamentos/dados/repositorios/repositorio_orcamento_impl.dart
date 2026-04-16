import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../dominio/entidades/orcamento.dart';
import '../../dominio/repositorios/repositorio_orcamento.dart';
import '../modelos/orcamento_modelo.dart';

/// Implementação do repositório de Orçamentos usando Supabase (PostgreSQL).
/// Todas as operações usam métodos nativos do SupabaseClient.
class RepositorioOrcamentoImpl implements RepositorioOrcamento {
  final SupabaseClient _supabase = SupabaseConfig.client;

  @override
  Future<List<Orcamento>> listarOrcamentos() async {
    try {
      final resultado = await _supabase
          .from('orcamento')
          .select()
          .order('data_criacao', ascending: false);

      return (resultado as List)
          .map((mapa) => OrcamentoModelo.deMapa(mapa))
          .toList();
    } catch (e) {
      throw 'Erro ao listar orçamentos: $e';
    }
  }

  @override
  Future<void> salvarOrcamento(Orcamento orcamento) async {
    try {
      final modelo = OrcamentoModelo(
        id: orcamento.id,
        idObra: orcamento.idObra,
        clienteNome: orcamento.clienteNome,
        descricao: orcamento.descricao,
        dataCriacao: orcamento.dataCriacao,
        dataValidade: orcamento.dataValidade,
        status: orcamento.status,
        itensServico: orcamento.itensServico,
        materiaisInclusos: orcamento.materiaisInclusos,
        valorMateriais: orcamento.valorMateriais,
        valorMaoDeObra: orcamento.valorMaoDeObra,
        desconto: orcamento.desconto,
        valorTotal: orcamento.valorTotal,
        formaPagamento: orcamento.formaPagamento,
      );

      if (orcamento.id == null) {
        // INSERT — novo orçamento
        await _supabase.from('orcamento').insert(modelo.paraMapa());
      } else {
        // UPDATE — orçamento existente
        await _supabase
            .from('orcamento')
            .update(modelo.paraMapa())
            .eq('id_orcamento', orcamento.id!);
      }
    } catch (e) {
      throw 'Erro ao salvar orçamento: $e';
    }
  }

  @override
  Future<void> excluirOrcamento(int id) async {
    try {
      await _supabase.from('orcamento').delete().eq('id_orcamento', id);
    } catch (e) {
      throw 'Erro ao excluir orçamento: $e';
    }
  }
}
