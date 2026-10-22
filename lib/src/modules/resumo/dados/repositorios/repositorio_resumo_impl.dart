import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../obras/dados/modelos/obra_modelo.dart';
import '../../dominio/entidades/alerta.dart';
import '../../dominio/entidades/resumo_geral.dart';
import '../../dominio/repositorios/repositorio_resumo.dart';

/// Implementação do repositório do Resumo Geral usando Supabase.
/// As consultas respeitam o RLS: cada função só vê o que pode ver.
class RepositorioResumoImpl implements RepositorioResumo {
  final SupabaseClient _supabase = SupabaseConfig.client;

  static String _dia(DateTime d) => d.toIso8601String().split('T').first;

  @override
  Future<ResumoGeral> carregarResumo(DateTime agora) async {
    try {
      final primeiroDia = _dia(DateTime(agora.year, agora.month, 1));
      final ultimoDia = _dia(DateTime(agora.year, agora.month + 1, 0));

      final consultas = await Future.wait([
        _supabase.from('obra').select('id_obra').eq('status', 'Em Andamento'),
        _supabase.from('orcamento').select('id_orcamento').eq('status', 'Pendente'),
        _supabase
            .from('transacao')
            .select('valor, tipo, status')
            .gte('data_transacao', primeiroDia)
            .lte('data_transacao', ultimoDia),
        _supabase.from('obra').select().order('data_inicio', ascending: false).limit(3),
      ]);

      // Receita/despesa do mês: lançamentos pendentes ainda não entraram no caixa.
      double receita = 0;
      double despesa = 0;
      for (final t in consultas[2] as List) {
        if (t['status'] == 'Pendente') continue;
        final valor = ((t['valor'] ?? 0) as num).toDouble();
        if (t['tipo'] == 'Receita') receita += valor;
        if (t['tipo'] == 'Despesa') despesa += valor;
      }

      return ResumoGeral(
        obrasAtivas: (consultas[0] as List).length,
        orcamentosPendentes: (consultas[1] as List).length,
        receitaMes: receita,
        despesaMes: despesa,
        obrasRecentes: (consultas[3] as List).map((m) => ObraModelo.deMapa(m)).toList(),
      );
    } catch (e) {
      throw 'Erro ao carregar o Resumo Geral: $e';
    }
  }

  @override
  Future<List<OrcamentoPendente>> listarOrcamentosPendentes() async {
    try {
      final resultado = await _supabase
          .from('orcamento')
          .select('cliente_nome, data_validade')
          .eq('status', 'Pendente');
      return [
        for (final o in resultado as List)
          if (DateTime.tryParse(o['data_validade']?.toString() ?? '') case final validade?)
            (cliente: (o['cliente_nome'] ?? 'Cliente').toString(), validade: validade),
      ];
    } catch (e) {
      throw 'Erro ao buscar orçamentos pendentes: $e';
    }
  }

  @override
  Future<List<ObraEmAberto>> listarObrasEmAberto() async {
    try {
      final resultado = await _supabase
          .from('obra')
          .select('titulo_da_obra, data_previsao_termino, status')
          .neq('status', 'Concluída');
      return [
        for (final o in resultado as List)
          if (DateTime.tryParse(o['data_previsao_termino']?.toString() ?? '') case final previsao?)
            (titulo: (o['titulo_da_obra'] ?? 'Obra').toString(), previsaoTermino: previsao),
      ];
    } catch (e) {
      throw 'Erro ao buscar obras: $e';
    }
  }
}
