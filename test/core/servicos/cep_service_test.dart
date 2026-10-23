import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paintmanager_app/src/core/servicos/cep_service.dart';

void main() {
  http.Response json(Object corpo, [int status = 200]) =>
      http.Response.bytes(utf8.encode(jsonEncode(corpo)), status, headers: {'content-type': 'application/json'});

  test('CEP válido preenche rua, bairro, cidade e UF (com acentos)', () async {
    late Uri chamada;
    final servico = CepService(
      cliente: MockClient((req) async {
        chamada = req.url;
        return json({
          'cep': '75907-210',
          'logradouro': 'Rua Rodezir Baylão',
          'bairro': 'Eldorado',
          'localidade': 'Rio Verde',
          'uf': 'GO',
        });
      }),
    );

    final e = await servico.buscar('75907-210');

    expect(chamada.toString(), 'https://viacep.com.br/ws/75907210/json/');
    expect(e.cep, '75907210');
    expect(e.logradouro, 'Rua Rodezir Baylão');
    expect(e.bairro, 'Eldorado');
    expect(e.cidade, 'Rio Verde');
    expect(e.uf, 'GO');
  });

  test('CEP com menos de 8 números nem chega a consultar', () async {
    var consultou = false;
    final servico = CepService(cliente: MockClient((_) async {
      consultou = true;
      return json({});
    }));

    expect(() => servico.buscar('7590'), throwsA('O CEP tem 8 números.'));
    expect(consultou, isFalse);
  });

  test('CEP inexistente avisa que não foi encontrado', () async {
    final servico = CepService(cliente: MockClient((_) async => json({'erro': 'true'})));
    expect(() => servico.buscar('00000000'), throwsA('CEP não encontrado. Confira os números.'));
  });

  test('sem internet avisa para conferir a conexão', () async {
    final servico = CepService(cliente: MockClient((_) async => throw Exception('sem rede')));
    expect(() => servico.buscar('75907210'), throwsA(contains('internet')));
  });
}
