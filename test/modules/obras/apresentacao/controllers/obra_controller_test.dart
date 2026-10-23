import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paintmanager_app/src/modules/obras/apresentacao/controllers/obra_controller.dart';
import 'package:paintmanager_app/src/modules/obras/dominio/entidades/etapa_servico.dart';
import 'package:paintmanager_app/src/modules/obras/dominio/entidades/obra.dart';
import 'package:paintmanager_app/src/modules/obras/dominio/repositorios/repositorio_obra.dart';

class _RepositorioObraFalso extends Mock implements RepositorioObra {}

Obra obra({
  int id = 1,
  String status = 'Não Iniciada',
  List<EtapaServico>? etapas,
  String cidade = 'Rio Verde',
}) =>
    Obra(
      id: id,
      idCliente: 1,
      clienteNome: 'Maria',
      tituloDaObra: 'Pintura',
      endereco: 'Rua X',
      cidade: cidade,
      uf: 'GO',
      dataInicio: DateTime(2026, 10, 1),
      dataPrevisaoTermino: DateTime(2026, 10, 10),
      status: status,
      etapasServico: etapas ??
          [
            EtapaServico(nome: 'Lixar', concluida: true),
            EtapaServico(nome: 'Pintar', concluida: false),
          ],
    );

void main() {
  late _RepositorioObraFalso repo;
  late ObraController controller;

  setUpAll(() => registerFallbackValue(obra()));

  setUp(() {
    repo = _RepositorioObraFalso();
    controller = ObraController(repo);
    when(() => repo.salvarObra(any())).thenAnswer((_) async {});
    when(() => repo.listarObras(maisRecentes: any(named: 'maisRecentes'))).thenAnswer((_) async => []);
  });

  Obra salva() => verify(() => repo.salvarObra(captureAny())).captured.single as Obra;

  group('atualizarStatus', () {
    test('obra Concluída é definitiva: não muda de status nem salva', () async {
      final erro = await controller.atualizarStatus(obra(status: 'Concluída'), 'Em Andamento');
      expect(erro, contains('não pode mais ser alterado'));
      verifyNever(() => repo.salvarObra(any()));
    });

    test('item 1.2: sem orçamento Aprovado a obra não inicia', () async {
      when(() => repo.obraTemOrcamentoAprovado(1)).thenAnswer((_) async => false);
      final erro = await controller.atualizarStatus(obra(), 'Em Andamento');
      expect(erro, contains('orçamento'));
      verifyNever(() => repo.salvarObra(any()));
    });

    test('com orçamento Aprovado inicia e mantém o endereço', () async {
      when(() => repo.obraTemOrcamentoAprovado(1)).thenAnswer((_) async => true);
      expect(await controller.atualizarStatus(obra(), 'Em Andamento'), isNull);
      final o = salva();
      expect(o.status, 'Em Andamento');
      expect(o.cidade, 'Rio Verde'); // não perde campos ao remontar a obra
    });

    test('concluir com etapas pendentes sem confirmação: recusa', () async {
      final erro = await controller.atualizarStatus(obra(status: 'Em Andamento'), 'Concluída');
      expect(erro, contains('etapas pendentes'));
      verifyNever(() => repo.salvarObra(any()));
    });

    test('concluir confirmando: marca todas as etapas, 100% e data de conclusão', () async {
      when(() => repo.obraTemOrcamentoAprovado(1)).thenAnswer((_) async => true);
      final erro = await controller.atualizarStatus(
        obra(status: 'Em Andamento'),
        'Concluída',
        marcarEtapasPendentes: true,
      );
      expect(erro, isNull);
      final o = salva();
      expect(o.status, 'Concluída');
      expect(o.progresso, 100);
      expect(o.etapasServico.every((e) => e.concluida), isTrue);
      expect(o.dataConclusao, isNotNull);
    });
  });

  group('alternarEtapa (checklist)', () {
    test('marca a etapa e recalcula o progresso', () async {
      await controller.alternarEtapa(obra(status: 'Em Andamento'), 1);
      final o = salva();
      expect(o.etapasServico[1].concluida, isTrue);
      expect(o.progresso, 100);
    });

    test('obra Concluída: checklist travado, nada é salvo', () async {
      await controller.alternarEtapa(obra(status: 'Concluída'), 1);
      verifyNever(() => repo.salvarObra(any()));
    });
  });

  test('excluir tira a obra da lista sem recarregar tudo', () async {
    when(() => repo.listarObras(maisRecentes: any(named: 'maisRecentes')))
        .thenAnswer((_) async => [obra(id: 1), obra(id: 2)]);
    when(() => repo.excluirObra(1)).thenAnswer((_) async {});
    await controller.carregarObras();

    await controller.excluir(1);

    expect(controller.obras.map((o) => o.id), [2]);
    verify(() => repo.listarObras(maisRecentes: any(named: 'maisRecentes'))).called(1);
  });

  test('erro do banco ao excluir chega à tela (e a obra continua na lista)', () async {
    when(() => repo.listarObras(maisRecentes: any(named: 'maisRecentes'))).thenAnswer((_) async => [obra(id: 1)]);
    when(() => repo.excluirObra(1)).thenThrow('Só o Administrador pode excluir obras.');
    await controller.carregarObras();

    expect(() => controller.excluir(1), throwsA(contains('Administrador')));
    expect(controller.obras, hasLength(1));
  });
}
