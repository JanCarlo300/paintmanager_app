import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/modules/resumo/dominio/entidades/alerta.dart';

void main() {
  final hoje = DateTime(2026, 10, 22, 15, 30);

  test('orçamento pendente vencido é urgente e leva para Orçamentos', () {
    final a = calcularAlertas(
      orcamentos: [(cliente: 'Maria', validade: DateTime(2026, 10, 20))],
      obras: const [],
      hoje: hoje,
    ).single;
    expect(a.tipo, TipoAlerta.orcamentoVencido);
    expect(a.subtitulo, 'Maria — venceu há 2 dia(s)');
    expect(a.urgente, isTrue);
    expect(a.rota, '/orcamentos');
  });

  test('vencendo hoje e em até 3 dias avisa; com 4 dias não avisa', () {
    final alertas = calcularAlertas(
      orcamentos: [
        (cliente: 'A', validade: DateTime(2026, 10, 22)),
        (cliente: 'B', validade: DateTime(2026, 10, 25)),
        (cliente: 'C', validade: DateTime(2026, 10, 26)),
      ],
      obras: const [],
      hoje: hoje,
    );
    expect(alertas.map((a) => a.subtitulo), ['A — vence hoje', 'B — vence em 3 dia(s)']);
    expect(alertas.every((a) => !a.urgente), isTrue);
  });

  test('obra com previsão passada avisa atraso; no dia da previsão ainda não', () {
    final alertas = calcularAlertas(
      orcamentos: const [],
      obras: [
        (titulo: 'Fachada', previsaoTermino: DateTime(2026, 10, 19)),
        (titulo: 'Quarto', previsaoTermino: DateTime(2026, 10, 22)),
      ],
      hoje: hoje,
    );
    expect(alertas, hasLength(1));
    expect(alertas.single.subtitulo, 'Fachada — atrasada há 3 dia(s)');
    expect(alertas.single.rota, '/obras');
  });

  test('sem dados, sem alertas', () {
    expect(calcularAlertas(orcamentos: const [], obras: const [], hoje: hoje), isEmpty);
  });
}
