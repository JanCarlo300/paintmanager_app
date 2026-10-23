import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:paintmanager_app/src/modules/clientes/apresentacao/controllers/cliente_controller.dart';
import 'package:paintmanager_app/src/modules/clientes/dominio/entidades/cliente.dart';
import 'package:paintmanager_app/src/modules/clientes/dominio/repositorios/repositorio_cliente.dart';

class _RepositorioClienteFalso extends Mock implements RepositorioCliente {}

Cliente cliente(int id, {bool ativo = true}) => Cliente(
      id: id,
      nome: 'Cliente $id',
      email: '',
      telefone: '',
      endereco: '',
      cpfOuCnpj: '',
      criadoEm: DateTime(2026, 10, 1),
      ativo: ativo,
    );

void main() {
  late _RepositorioClienteFalso repo;
  late ClienteController controller;

  setUp(() {
    repo = _RepositorioClienteFalso();
    controller = ClienteController(repo);
    when(() => repo.listarClientes()).thenAnswer((_) async => [cliente(1)]);
    when(() => repo.atualizarStatus(any(), any())).thenAnswer((_) async {});
  });

  test('inativar é soft delete: só muda o status e recarrega', () async {
    await controller.inativar(1);
    verify(() => repo.atualizarStatus(1, false)).called(1);
    verify(() => repo.listarClientes()).called(1);
  });

  test('ativar devolve o status', () async {
    await controller.ativar(1);
    verify(() => repo.atualizarStatus(1, true)).called(1);
  });

  test('falha ao listar deixa a lista vazia e para de carregar', () async {
    when(() => repo.listarClientes()).thenThrow('sem conexão');
    await controller.carregarClientes();
    expect(controller.clientes, isEmpty);
    expect(controller.carregando, isFalse);
  });
}
