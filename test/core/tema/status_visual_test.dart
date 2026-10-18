import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:paintmanager_app/src/core/tema/cores_app.dart';
import 'package:paintmanager_app/src/core/tema/status_visual.dart';

void main() {
  const c = CoresApp.claro;

  group('visualDoStatus', () {
    final casos = {
      // grafia do banco → rótulo exibido
      'Pendente': 'Pendente',
      'Aprovado': 'Aprovado',
      'Recusado': 'Recusado',
      'Rejeitado': 'Recusado', // dado antigo
      'Não Iniciada': 'Não iniciada',
      'Em Andamento': 'Em andamento',
      'Em andamento': 'Em andamento',
      'Pausada': 'Pausada',
      'Concluída': 'Concluída',
      '  concluida ': 'Concluída',
    };

    casos.forEach((entrada, rotulo) {
      test('"$entrada" vira "$rotulo"', () {
        expect(visualDoStatus(entrada, c).rotulo, rotulo);
      });
    });

    test('cores seguem o manual', () {
      expect(visualDoStatus('Aprovado', c).cor, c.success);
      expect(visualDoStatus('Aprovado', c).fundo, c.successSoft);
      expect(visualDoStatus('Recusado', c).cor, c.error);
      expect(visualDoStatus('Pendente', c).cor, c.warning);
      expect(visualDoStatus('Pausada', c).cor, c.warning);
      expect(visualDoStatus('Em Andamento', c).cor, c.info);
      expect(visualDoStatus('Não Iniciada', c).cor, c.inkMuted);
      expect(visualDoStatus('Concluída', c).icone, Symbols.check_circle_rounded);
    });

    test('status desconhecido aparece neutro com o próprio texto', () {
      final v = visualDoStatus('Arquivada', c);
      expect(v.rotulo, 'Arquivada');
      expect(v.cor, c.inkMuted);
    });
  });

  test('normalizarStatus tira acentos, maiúsculas e espaços extras', () {
    expect(normalizarStatus('  Não   Iniciada '), 'nao iniciada');
    expect(normalizarStatus('CONCLUÍDA'), 'concluida');
  });
}
