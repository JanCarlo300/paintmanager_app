import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/supabase_config.dart';
import '../../dominio/entidades/relatorio_geral.dart';
import '../../dominio/repositorios/repositorio_relatorio.dart';
import '../../../financeiro/dominio/entidades/transacao.dart';
import '../../../financeiro/dados/modelos/transacao_modelo.dart';
import '../../../obras/dominio/entidades/obra.dart';
import '../../../obras/dados/modelos/obra_modelo.dart';
import '../../../orcamentos/dominio/entidades/orcamento.dart';
import '../../../orcamentos/dados/modelos/orcamento_modelo.dart';

/// Implementação do repositório de Relatórios usando Supabase (PostgreSQL).
/// Agrega dados de 3 tabelas: transacao, obra, orcamento.
/// Usa Future.wait para busca paralela e processamento no Dart.
class RepositorioRelatorioImpl implements RepositorioRelatorio {
  final SupabaseClient _supabase = SupabaseConfig.client;

  @override
  Future<RelatorioGeral> gerarRelatorio(DateTime inicio, DateTime fim) async {
    final strInicio = inicio.toIso8601String().split('T').first;
    final strFim = fim.toIso8601String().split('T').first;

    // Busca paralela nas 3 tabelas com filtro de data
    final resultados = await Future.wait([
      _buscarTransacoes(strInicio, strFim),
      _buscarObras(strInicio, strFim),
      _buscarOrcamentos(strInicio, strFim),
    ]);

    final transacoes = resultados[0];
    final obras = resultados[1];
    final orcamentos = resultados[2];

    return RelatorioGeral(
      periodoInicio: inicio,
      periodoFim: fim,
      totalReceitas: transacoes['receitas'] as double,
      totalDespesas: transacoes['despesas'] as double,
      quantidadeObrasConcluidas: obras['concluidas'] as int,
      quantidadeObrasEmAndamento: obras['emAndamento'] as int,
      totalOrcamentosGerados: orcamentos['gerados'] as int,
      totalOrcamentosAprovados: orcamentos['aprovados'] as int,
      despesasPorCategoria: transacoes['despesasPorCategoria'] as Map<String, double>,
      receitasPorMes: transacoes['receitasPorMes'] as Map<String, double>,
      despesasPorMes: transacoes['despesasPorMes'] as Map<String, double>,
    );
  }

  // === Etapa 8.1 — dados dos PDFs (RF012) ===

  static String _dia(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Future<List<Transacao>> listarLancamentos(DateTime inicio, DateTime fim, {int? obraId}) async {
    try {
      var consulta = _supabase
          .from('transacao')
          .select()
          .gte('data_transacao', _dia(inicio))
          .lte('data_transacao', _dia(fim));
      if (obraId != null) consulta = consulta.eq('id_obra', obraId);
      final resultado = await consulta.order('data_transacao');
      return (resultado as List).map((m) => TransacaoModelo.deMapa(m)).toList();
    } catch (e) {
      throw 'Erro ao buscar lançamentos: $e';
    }
  }

  @override
  Future<Map<int, String>> statusDasObras(Iterable<int> ids) async {
    final lista = ids.toSet().toList();
    if (lista.isEmpty) return {};
    try {
      final resultado = await _supabase.from('obra').select('id_obra, status').inFilter('id_obra', lista);
      return {
        for (final m in (resultado as List))
          (m['id_obra'] as num).toInt(): (m['status'] ?? '').toString(),
      };
    } catch (e) {
      throw 'Erro ao buscar status das obras: $e';
    }
  }

  @override
  Future<List<Orcamento>> listarOrcamentosAprovados(DateTime inicio, DateTime fim, {int? obraId}) async {
    try {
      var consulta = _supabase
          .from('orcamento')
          .select()
          .eq('status', 'Aprovado')
          .gte('data_criacao', _dia(inicio))
          .lte('data_criacao', _dia(fim));
      if (obraId != null) consulta = consulta.eq('id_obra', obraId);
      final resultado = await consulta;
      return (resultado as List).map((m) => OrcamentoModelo.deMapa(m)).toList();
    } catch (e) {
      throw 'Erro ao buscar orçamentos: $e';
    }
  }

  @override
  Future<List<Obra>> listarObrasParaProgresso(DateTime inicio, DateTime fim, {int? obraId}) async {
    try {
      var consulta = _supabase.from('obra').select().neq('status', 'Não Iniciada');
      if (obraId != null) {
        consulta = consulta.eq('id_obra', obraId);
      } else {
        // Período da obra cruza o período do relatório.
        consulta = consulta
            .lte('data_inicio', _dia(fim))
            .gte('data_previsao_termino', _dia(inicio));
      }
      final resultado = await consulta.order('data_inicio');
      return (resultado as List).map((m) => ObraModelo.deMapa(m)).toList();
    } catch (e) {
      throw 'Erro ao buscar obras: $e';
    }
  }

  /// Busca transações do período e agrega receitas, despesas e breakdowns
  Future<Map<String, dynamic>> _buscarTransacoes(String inicio, String fim) async {
    try {
      final resultado = await _supabase
          .from('transacao')
          .select()
          .gte('data_transacao', inicio)
          .lte('data_transacao', fim);

      double receitas = 0;
      double despesas = 0;
      final despesasPorCategoria = <String, double>{};
      final receitasPorMes = <String, double>{};
      final despesasPorMes = <String, double>{};
      final formatoMes = DateFormat('MMM', 'pt_BR');

      for (final row in (resultado as List)) {
        final valor = (row['valor'] ?? 0).toDouble();
        final tipo = row['tipo'] ?? '';
        final categoria = row['categoria'] ?? 'Outros';
        final dataTransacao = DateTime.tryParse(row['data_transacao'] ?? '') ?? DateTime.now();
        final chMes = formatoMes.format(dataTransacao);

        if (tipo == 'Receita') {
          receitas += valor;
          receitasPorMes[chMes] = (receitasPorMes[chMes] ?? 0) + valor;
        } else if (tipo == 'Despesa') {
          despesas += valor;
          despesasPorCategoria[categoria] = (despesasPorCategoria[categoria] ?? 0) + valor;
          despesasPorMes[chMes] = (despesasPorMes[chMes] ?? 0) + valor;
        }
      }

      return {
        'receitas': receitas,
        'despesas': despesas,
        'despesasPorCategoria': despesasPorCategoria,
        'receitasPorMes': receitasPorMes,
        'despesasPorMes': despesasPorMes,
      };
    } catch (e) {
      return {
        'receitas': 0.0,
        'despesas': 0.0,
        'despesasPorCategoria': <String, double>{},
        'receitasPorMes': <String, double>{},
        'despesasPorMes': <String, double>{},
      };
    }
  }

  /// Busca obras do período e conta por status
  Future<Map<String, dynamic>> _buscarObras(String inicio, String fim) async {
    try {
      final resultado = await _supabase
          .from('obra')
          .select()
          .gte('data_inicio', inicio)
          .lte('data_inicio', fim);

      int concluidas = 0;
      int emAndamento = 0;

      for (final row in (resultado as List)) {
        final status = row['status'] ?? '';
        if (status == 'Concluída') concluidas++;
        if (status == 'Em Andamento') emAndamento++;
      }

      return {'concluidas': concluidas, 'emAndamento': emAndamento};
    } catch (e) {
      return {'concluidas': 0, 'emAndamento': 0};
    }
  }

  /// Busca orçamentos do período e conta por status
  Future<Map<String, dynamic>> _buscarOrcamentos(String inicio, String fim) async {
    try {
      final resultado = await _supabase
          .from('orcamento')
          .select()
          .gte('data_criacao', inicio)
          .lte('data_criacao', fim);

      final rows = resultado as List;
      int gerados = rows.length;
      int aprovados = 0;

      for (final row in rows) {
        if (row['status'] == 'Aprovado') aprovados++;
      }

      return {'gerados': gerados, 'aprovados': aprovados};
    } catch (e) {
      return {'gerados': 0, 'aprovados': 0};
    }
  }
}
