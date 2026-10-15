import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/core/filtros/filtro_lista.dart';

void main() {
  // Quarta-feira, 15/10/2026, 14:30 — "agora" fixo para os testes.
  final agora = DateTime(2026, 10, 15, 14, 30);

  group('FiltroLista.quantidadeAtivos', () {
    test('padrão não tem filtro ativo', () {
      expect(const FiltroLista().quantidadeAtivos, 0);
    });

    test('conta ordenação, período e prazo fora do padrão', () {
      const f = FiltroLista(
        maisRecentes: false,
        periodo: PeriodoCriacao.hoje,
        prazo: FiltroPrazo.atrasados,
      );
      expect(f.quantidadeAtivos, 3);
    });
  });

  group('FiltroLista.criadoNoPeriodo', () {
    test('"Todos" aceita qualquer data, inclusive sem data', () {
      const f = FiltroLista();
      expect(f.criadoNoPeriodo(null, agora: agora), isTrue);
      expect(f.criadoNoPeriodo(DateTime(2020), agora: agora), isTrue);
    });

    test('com período ativo, registro sem data fica de fora', () {
      const f = FiltroLista(periodo: PeriodoCriacao.hoje);
      expect(f.criadoNoPeriodo(null, agora: agora), isFalse);
    });

    test('"Hoje" pega o dia inteiro, da meia-noite até 23:59', () {
      const f = FiltroLista(periodo: PeriodoCriacao.hoje);
      expect(f.criadoNoPeriodo(DateTime(2026, 10, 15, 0, 0), agora: agora), isTrue);
      expect(f.criadoNoPeriodo(DateTime(2026, 10, 15, 23, 59), agora: agora), isTrue);
      expect(f.criadoNoPeriodo(DateTime(2026, 10, 14, 23, 59), agora: agora), isFalse);
      expect(f.criadoNoPeriodo(DateTime(2026, 10, 16), agora: agora), isFalse);
    });

    test('"Ontem" pega só o dia anterior', () {
      const f = FiltroLista(periodo: PeriodoCriacao.ontem);
      expect(f.criadoNoPeriodo(DateTime(2026, 10, 14, 9), agora: agora), isTrue);
      expect(f.criadoNoPeriodo(DateTime(2026, 10, 15, 9), agora: agora), isFalse);
      expect(f.criadoNoPeriodo(DateTime(2026, 10, 13, 9), agora: agora), isFalse);
    });

    test('"Últimos 7 dias" inclui hoje e os 6 dias anteriores', () {
      const f = FiltroLista(periodo: PeriodoCriacao.ultimos7Dias);
      expect(f.criadoNoPeriodo(DateTime(2026, 10, 9), agora: agora), isTrue);
      expect(f.criadoNoPeriodo(DateTime(2026, 10, 8, 23, 59), agora: agora), isFalse);
    });

    test('"Últimos 30 dias" inclui hoje e os 29 dias anteriores', () {
      const f = FiltroLista(periodo: PeriodoCriacao.ultimos30Dias);
      expect(f.criadoNoPeriodo(DateTime(2026, 9, 16), agora: agora), isTrue);
      expect(f.criadoNoPeriodo(DateTime(2026, 9, 15, 23, 59), agora: agora), isFalse);
    });

    test('período personalizado inclui o último dia inteiro', () {
      final f = FiltroLista(
        periodo: PeriodoCriacao.personalizado,
        inicioPersonalizado: DateTime(2026, 10, 1),
        fimPersonalizado: DateTime(2026, 10, 5),
      );
      expect(f.criadoNoPeriodo(DateTime(2026, 10, 1), agora: agora), isTrue);
      expect(f.criadoNoPeriodo(DateTime(2026, 10, 5, 22), agora: agora), isTrue);
      expect(f.criadoNoPeriodo(DateTime(2026, 10, 6), agora: agora), isFalse);
      expect(f.criadoNoPeriodo(DateTime(2026, 9, 30, 23), agora: agora), isFalse);
    });
  });

  group('FiltroLista.dentroDoPrazo', () {
    test('"Todos" aceita tudo', () {
      const f = FiltroLista();
      expect(f.dentroDoPrazo(null, emAberto: false, agora: agora), isTrue);
    });

    test('"Atrasados" = prazo antes de hoje e ainda em aberto', () {
      const f = FiltroLista(prazo: FiltroPrazo.atrasados);
      expect(f.dentroDoPrazo(DateTime(2026, 10, 14), emAberto: true, agora: agora), isTrue);
      expect(f.dentroDoPrazo(DateTime(2026, 10, 15), emAberto: true, agora: agora), isFalse);
      // Já concluído/resolvido não conta como atrasado.
      expect(f.dentroDoPrazo(DateTime(2026, 10, 1), emAberto: false, agora: agora), isFalse);
    });

    test('"Próximos 7 dias" = de hoje até daqui a 7 dias', () {
      const f = FiltroLista(prazo: FiltroPrazo.proximos7Dias);
      expect(f.dentroDoPrazo(DateTime(2026, 10, 15), emAberto: true, agora: agora), isTrue);
      expect(f.dentroDoPrazo(DateTime(2026, 10, 22), emAberto: true, agora: agora), isTrue);
      expect(f.dentroDoPrazo(DateTime(2026, 10, 23), emAberto: true, agora: agora), isFalse);
      expect(f.dentroDoPrazo(DateTime(2026, 10, 14), emAberto: true, agora: agora), isFalse);
    });
  });
}
