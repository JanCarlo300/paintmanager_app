import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../modules/obras/dominio/entidades/obra.dart';

class DashboardController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool carregando = true;
  int obrasAtivas = 0;
  int orcamentosPendentes = 0;
  double receitaMes = 0.0;
  double despesaMes = 0.0;
  List<Obra> obrasRecentes = [];

  DashboardController() {
    carregarResumo();
  }

  Future<void> carregarResumo() async {
    carregando = true;
    notifyListeners();

    try {
      // 1. Obras em Andamento
      final obrasReq = await _supabase
          .from('obra')
          .select('id_obra')
          .eq('status', 'Em Andamento');
      obrasAtivas = obrasReq.length;
    } catch (e) {
      print("Erro Obras: $e");
    }

    try {
      // 2. Orçamentos Pendentes
      final orcamentosReq = await _supabase
          .from('orcamento')
          .select('id_orcamento')
          .eq('status', 'Pendente');
      orcamentosPendentes = orcamentosReq.length;
    } catch (e) {
      print("Erro Orçamentos: $e");
    }

    try {
      // 3. Resumo Financeiro (Mês Atual)
      final agora = DateTime.now();
      final primeiroDia = DateTime(agora.year, agora.month, 1).toIso8601String();
      final ultimoDia = DateTime(agora.year, agora.month + 1, 0, 23, 59, 59).toIso8601String();

      final transacoesReq = await _supabase
          .from('transacao')
          .select('valor, tipo, status')
          .gte('data_transacao', primeiroDia)
          .lte('data_transacao', ultimoDia);

      double rec = 0.0;
      double des = 0.0;
      for (var t in transacoesReq) {
        if (t['status'] != 'Pendente') {
          final valor = (t['valor'] ?? 0).toDouble();
          if (t['tipo'] == 'Receita') rec += valor;
          if (t['tipo'] == 'Despesa') des += valor;
        }
      }
      receitaMes = rec;
      despesaMes = des;
    } catch (e) {
      print("Erro Transações: $e");
    }

    try {
      // 4. Obras Recentes
      final recentesReq = await _supabase
          .from('obra')
          .select()
          .order('data_inicio', ascending: false)
          .limit(3);

      obrasRecentes = recentesReq.map<Obra>((mapa) {
        return Obra(
          id: mapa['id_obra'] as int?,
          idCliente: (mapa['id_cliente'] ?? 0) as int,
          clienteNome: mapa['cliente_nome'] ?? 'Desconhecido',
          tituloDaObra: mapa['titulo_da_obra'] ?? 'Obra sem título',
          endereco: mapa['endereco'] ?? '',
          dataInicio: _parseDate(mapa['data_inicio']),
          dataPrevisaoTermino: _parseDate(mapa['data_previsao_termino']),
          status: mapa['status'] ?? 'Não Iniciada',
          progresso: (mapa['progresso'] ?? 0).toDouble(),
          etapasServico: [],
        );
      }).toList();
    } catch (e) {
      print("Erro Obras Recentes: $e");
    }

    carregando = false;
    notifyListeners();
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is String) return DateTime.tryParse(dateValue) ?? DateTime.now();
    return DateTime.now();
  }
}
