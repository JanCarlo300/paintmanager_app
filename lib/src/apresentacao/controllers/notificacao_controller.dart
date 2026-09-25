import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// RF013 (versão simplificada) - um alerta computado a partir de dados já
/// existentes (orçamentos e obras), sem depender de push notification nem
/// de nenhuma tarefa rodando em segundo plano.
class AlertaItem {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Color cor;
  final String rota;

  const AlertaItem({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.cor,
    required this.rota,
  });
}

class NotificacaoController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool carregando = false;
  List<AlertaItem> alertas = [];

  NotificacaoController() {
    carregarAlertas();
  }

  Future<void> carregarAlertas() async {
    carregando = true;
    notifyListeners();

    final novosAlertas = <AlertaItem>[];
    final agora = DateTime.now();

    try {
      // Orçamentos pendentes vencidos ou vencendo nos próximos 3 dias
      final orcamentosReq = await _supabase
          .from('orcamento')
          .select('cliente_nome, data_validade')
          .eq('status', 'Pendente');

      for (final o in orcamentosReq) {
        final validade = DateTime.tryParse(o['data_validade']?.toString() ?? '');
        if (validade == null) continue;
        final dias = validade.difference(DateTime(agora.year, agora.month, agora.day)).inDays;
        final cliente = o['cliente_nome']?.toString() ?? 'Cliente';

        if (dias < 0) {
          novosAlertas.add(AlertaItem(
            titulo: 'Orçamento vencido',
            subtitulo: '$cliente — venceu há ${-dias} dia(s)',
            icone: Icons.request_quote_outlined,
            cor: Colors.red,
            rota: '/orcamentos',
          ));
        } else if (dias <= 3) {
          novosAlertas.add(AlertaItem(
            titulo: 'Orçamento vencendo',
            subtitulo: '$cliente — vence ${dias == 0 ? 'hoje' : 'em $dias dia(s)'}',
            icone: Icons.request_quote_outlined,
            cor: Colors.orange,
            rota: '/orcamentos',
          ));
        }
      }
    } catch (_) {
      // Falha ao consultar não deve travar o restante do painel de alertas.
    }

    try {
      // Obras com prazo de término estourado, ainda não concluídas
      final obrasReq = await _supabase
          .from('obra')
          .select('titulo_da_obra, data_previsao_termino, status')
          .neq('status', 'Concluída');

      for (final o in obrasReq) {
        final previsao = DateTime.tryParse(o['data_previsao_termino']?.toString() ?? '');
        if (previsao == null) continue;
        final dias = DateTime(agora.year, agora.month, agora.day).difference(previsao).inDays;
        if (dias <= 0) continue; // ainda dentro do prazo

        novosAlertas.add(AlertaItem(
          titulo: 'Obra com prazo estourado',
          subtitulo: '${o['titulo_da_obra'] ?? 'Obra'} — atrasada há $dias dia(s)',
          icone: Icons.construction_outlined,
          cor: Colors.red,
          rota: '/obras',
        ));
      }
    } catch (_) {
      // Idem: não bloqueia os alertas de orçamento já carregados.
    }

    alertas = novosAlertas;
    carregando = false;
    notifyListeners();
  }
}
