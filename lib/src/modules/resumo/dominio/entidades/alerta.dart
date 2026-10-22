/// RF013 (versão simplificada): alertas calculados a partir de dados que já
/// existem (orçamentos e obras), sem push nem tarefa em segundo plano.
enum TipoAlerta { orcamentoVencido, orcamentoVencendo, obraAtrasada }

class Alerta {
  final TipoAlerta tipo;
  final String titulo;
  final String subtitulo;

  const Alerta({required this.tipo, required this.titulo, required this.subtitulo});

  /// true = já venceu / atrasou; false = está para vencer.
  bool get urgente => tipo != TipoAlerta.orcamentoVencendo;

  /// Tela que o toque no alerta abre.
  String get rota => tipo == TipoAlerta.obraAtrasada ? '/obras' : '/orcamentos';
}

/// Orçamento Pendente, só com o que o alerta precisa.
typedef OrcamentoPendente = ({String cliente, DateTime validade});

/// Obra ainda não concluída, só com o que o alerta precisa.
typedef ObraEmAberto = ({String titulo, DateTime previsaoTermino});

DateTime _soDia(DateTime d) => DateTime(d.year, d.month, d.day);

/// Regra dos alertas:
/// - orçamento pendente vencido → "Orçamento vencido" (urgente);
/// - orçamento pendente vencendo em até 3 dias → "Orçamento vencendo";
/// - obra não concluída com previsão de término já passada → "Obra com prazo estourado".
List<Alerta> calcularAlertas({
  required List<OrcamentoPendente> orcamentos,
  required List<ObraEmAberto> obras,
  required DateTime hoje,
}) {
  final dia = _soDia(hoje);
  final alertas = <Alerta>[];

  for (final o in orcamentos) {
    final dias = _soDia(o.validade).difference(dia).inDays;
    if (dias < 0) {
      alertas.add(Alerta(
        tipo: TipoAlerta.orcamentoVencido,
        titulo: 'Orçamento vencido',
        subtitulo: '${o.cliente} — venceu há ${-dias} dia(s)',
      ));
    } else if (dias <= 3) {
      alertas.add(Alerta(
        tipo: TipoAlerta.orcamentoVencendo,
        titulo: 'Orçamento vencendo',
        subtitulo: '${o.cliente} — vence ${dias == 0 ? 'hoje' : 'em $dias dia(s)'}',
      ));
    }
  }

  for (final o in obras) {
    final dias = dia.difference(_soDia(o.previsaoTermino)).inDays;
    if (dias <= 0) continue; // ainda dentro do prazo
    alertas.add(Alerta(
      tipo: TipoAlerta.obraAtrasada,
      titulo: 'Obra com prazo estourado',
      subtitulo: '${o.titulo} — atrasada há $dias dia(s)',
    ));
  }

  return alertas;
}
