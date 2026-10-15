/// Etapa 4 — ordenação e filtros das listas de Obras e Orçamentos.
/// Só regras (sem Flutter), para ser testado com testes unitários.
enum PeriodoCriacao { todos, hoje, ontem, ultimos7Dias, ultimos30Dias, personalizado }

enum FiltroPrazo { todos, atrasados, proximos7Dias }

class FiltroLista {
  const FiltroLista({
    this.maisRecentes = true,
    this.periodo = PeriodoCriacao.todos,
    this.inicioPersonalizado,
    this.fimPersonalizado,
    this.prazo = FiltroPrazo.todos,
  });

  final bool maisRecentes;
  final PeriodoCriacao periodo;
  final DateTime? inicioPersonalizado;
  final DateTime? fimPersonalizado;
  final FiltroPrazo prazo;

  /// Quantos ajustes fogem do padrão — vira o número no botão de filtro.
  int get quantidadeAtivos =>
      (maisRecentes ? 0 : 1) +
      (periodo == PeriodoCriacao.todos ? 0 : 1) +
      (prazo == FiltroPrazo.todos ? 0 : 1);

  FiltroLista copiarCom({
    bool? maisRecentes,
    PeriodoCriacao? periodo,
    DateTime? inicioPersonalizado,
    DateTime? fimPersonalizado,
    FiltroPrazo? prazo,
  }) {
    return FiltroLista(
      maisRecentes: maisRecentes ?? this.maisRecentes,
      periodo: periodo ?? this.periodo,
      inicioPersonalizado: inicioPersonalizado ?? this.inicioPersonalizado,
      fimPersonalizado: fimPersonalizado ?? this.fimPersonalizado,
      prazo: prazo ?? this.prazo,
    );
  }

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  /// O registro foi criado dentro do período escolhido? Os intervalos
  /// incluem o dia inteiro: "Hoje" = de 00:00 de hoje até 00:00 de amanhã.
  bool criadoNoPeriodo(DateTime? criadoEm, {DateTime? agora}) {
    if (periodo == PeriodoCriacao.todos) return true;
    if (criadoEm == null) return false;

    final hoje = _dia(agora ?? DateTime.now());
    final amanha = hoje.add(const Duration(days: 1));
    late final DateTime inicio;
    late final DateTime fim;

    switch (periodo) {
      case PeriodoCriacao.todos:
        return true;
      case PeriodoCriacao.hoje:
        inicio = hoje;
        fim = amanha;
      case PeriodoCriacao.ontem:
        inicio = hoje.subtract(const Duration(days: 1));
        fim = hoje;
      case PeriodoCriacao.ultimos7Dias:
        inicio = hoje.subtract(const Duration(days: 6));
        fim = amanha;
      case PeriodoCriacao.ultimos30Dias:
        inicio = hoje.subtract(const Duration(days: 29));
        fim = amanha;
      case PeriodoCriacao.personalizado:
        if (inicioPersonalizado == null || fimPersonalizado == null) return true;
        inicio = _dia(inicioPersonalizado!);
        fim = _dia(fimPersonalizado!).add(const Duration(days: 1));
    }

    final local = criadoEm.toLocal();
    return !local.isBefore(inicio) && local.isBefore(fim);
  }

  /// Filtro de prazo. [limite] é a data que vence (previsão de término da
  /// obra, validade do orçamento) e [emAberto] diz se o prazo ainda importa
  /// (obra não concluída, orçamento pendente) — prazo de algo já resolvido
  /// não conta como atrasado.
  bool dentroDoPrazo(DateTime? limite, {required bool emAberto, DateTime? agora}) {
    if (prazo == FiltroPrazo.todos) return true;
    if (limite == null || !emAberto) return false;

    final hoje = _dia(agora ?? DateTime.now());
    final dia = _dia(limite.toLocal());

    switch (prazo) {
      case FiltroPrazo.todos:
        return true;
      case FiltroPrazo.atrasados:
        return dia.isBefore(hoje);
      case FiltroPrazo.proximos7Dias:
        return !dia.isBefore(hoje) && !dia.isAfter(hoje.add(const Duration(days: 7)));
    }
  }
}
