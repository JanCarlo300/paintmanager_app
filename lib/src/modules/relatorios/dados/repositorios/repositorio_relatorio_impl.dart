import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/supabase_config.dart';
import '../../dominio/entidades/relatorio_geral.dart';
import '../../dominio/repositorios/repositorio_relatorio.dart';

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
