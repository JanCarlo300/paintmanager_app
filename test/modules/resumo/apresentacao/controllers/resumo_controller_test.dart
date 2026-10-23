import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paintmanager_app/src/modules/resumo/apresentacao/controllers/resumo_controller.dart';
import 'package:paintmanager_app/src/modules/resumo/dominio/entidades/alerta.dart';
import 'package:paintmanager_app/src/modules/resumo/dominio/entidades/resumo_geral.dart';
import 'package:paintmanager_app/src/modules/resumo/dominio/repositorios/repositorio_resumo.dart';

class _RepositorioResumoFalso extends Mock implements RepositorioResumo {}

void main() {
  final hoje = DateTime(2026, 10, 22);
  late _RepositorioResumoFalso repo;
  late ResumoController controller;

  setUp(() {
    repo = _RepositorioResumoFalso();
    controller = ResumoController(repo, agora: () => hoje);
  });

  test('carrega o resumo do mês de "agora"', () async {
    when(() => repo.carregarResumo(hoje)).thenAnswer((_) async => const ResumoGeral(
          obrasAtivas: 2,
          orcamentosPendentes: 3,
          receitaMes: 1500,
          despesaMes: 400,
          obrasRecentes: [],
        ));

    await controller.carregarResumo();

    expect(controller.carregando, isFalse);
    expect(controller.obrasAtivas, 2);
    expect(controller.orcamentosPendentes, 3);
    expect(controller.resumo.saldoMes, 1100);
    expect(controller.erro, isNull);
  });

  test('erro no resumo vira mensagem e os números ficam zerados', () async {
    when(() => repo.carregarResumo(hoje)).thenThrow('sem conexão');
    await controller.carregarResumo();
    expect(controller.erro, 'sem conexão');
    expect(controller.obrasAtivas, 0);
    expect(controller.carregando, isFalse);
  });

  test('alertas: uma consulta que falha não apaga os alertas da outra', () async {
    when(() => repo.listarOrcamentosPendentes()).thenThrow('falhou');
    when(() => repo.listarObrasEmAberto())
        .thenAnswer((_) async => [(titulo: 'Fachada', previsaoTermino: DateTime(2026, 10, 20))]);

    await controller.carregarAlertas();

    expect(controller.carregandoAlertas, isFalse);
    expect(controller.alertas.single.tipo, TipoAlerta.obraAtrasada);
  });
}
