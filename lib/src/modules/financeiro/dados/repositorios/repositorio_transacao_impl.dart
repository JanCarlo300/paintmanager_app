import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../dominio/entidades/transacao.dart';
import '../../dominio/repositorios/repositorio_transacao.dart';
import '../modelos/transacao_modelo.dart';

/// Implementação do repositório de Transações usando Supabase (PostgreSQL).
/// Todas as operações usam métodos nativos do SupabaseClient.
/// Substitui completamente a versão Firebase (Stream → Future).
class RepositorioTransacaoImpl implements RepositorioTransacao {
  final SupabaseClient _supabase = SupabaseConfig.client;

  @override
  Future<List<Transacao>> listarTransacoes() async {
    try {
      final resultado = await _supabase
          .from('transacao')
          .select()
          .order('data_transacao', ascending: false);

      return (resultado as List)
          .map((mapa) => TransacaoModelo.deMapa(mapa))
          .toList();
    } catch (e) {
      throw 'Erro ao listar transações: $e';
    }
  }

  @override
  Future<void> salvarTransacao(Transacao transacao) async {
    try {
      final modelo = TransacaoModelo(
        id: transacao.id,
        tipo: transacao.tipo,
        categoria: transacao.categoria,
        valor: transacao.valor,
        descricao: transacao.descricao,
        dataTransacao: transacao.dataTransacao,
        status: transacao.status,
        formaPagamento: transacao.formaPagamento,
        idCliente: transacao.idCliente,
        idOrcamento: transacao.idOrcamento,
        clienteNome: transacao.clienteNome,
        obraTitulo: transacao.obraTitulo,
        comprovanteUrl: transacao.comprovanteUrl,
      );

      if (transacao.id == null) {
        // INSERT — nova transação
        await _supabase.from('transacao').insert(modelo.paraMapa());
      } else {
        // UPDATE — transação existente
        await _supabase
            .from('transacao')
            .update(modelo.paraMapa())
            .eq('id_transacao', transacao.id!);
      }
    } catch (e) {
      throw 'Erro ao salvar transação: $e';
    }
  }

  @override
  Future<void> excluirTransacao(int id) async {
    try {
      await _supabase.from('transacao').delete().eq('id_transacao', id);
    } catch (e) {
      throw 'Erro ao excluir transação: $e';
    }
  }
}
