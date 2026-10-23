import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/modules/obras/dominio/entidades/etapa_servico.dart';
import 'package:paintmanager_app/src/modules/obras/dominio/entidades/obra.dart';

Obra obra({
  String endereco = 'Rua Rodezir Baylão',
  String numero = '',
  String complemento = '',
  String cep = '',
  String bairro = '',
  String cidade = '',
  String uf = '',
  double? lat,
  double? lng,
  bool exata = false,
  List<EtapaServico> etapas = const [],
}) =>
    Obra(
      idCliente: 1,
      clienteNome: 'Maria',
      tituloDaObra: 'Pintura',
      endereco: endereco,
      numero: numero,
      complemento: complemento,
      cep: cep,
      bairro: bairro,
      cidade: cidade,
      uf: uf,
      dataInicio: DateTime(2026, 10, 1),
      dataPrevisaoTermino: DateTime(2026, 10, 10),
      etapasServico: etapas,
      latitude: lat,
      longitude: lng,
      localizacaoExata: exata,
    );

void main() {
  group('endereço', () {
    test('enderecoCompleto junta só as partes preenchidas', () {
      final o = obra(numero: '120', complemento: 'Qd N, Lt 19', bairro: 'Eldorado', cidade: 'Rio Verde', uf: 'GO');
      expect(o.enderecoCompleto, 'Rua Rodezir Baylão, 120, Qd N, Lt 19 - Eldorado, Rio Verde - GO');
      expect(obra().enderecoCompleto, 'Rua Rodezir Baylão');
    });

    test('enderecoParaRota leva CEP e Brasil e deixa quadra/lote de fora', () {
      final o = obra(numero: '120', complemento: 'Qd N, Lt 19', cep: '75907210', bairro: 'Eldorado', cidade: 'Rio Verde', uf: 'GO');
      expect(o.enderecoParaRota, 'Rua Rodezir Baylão, 120, Eldorado, Rio Verde - GO, 75907-210, Brasil');
      expect(o.enderecoParaRota, isNot(contains('Lt')));
    });

    test('cepFormatado', () {
      expect(obra(cep: '75907210').cepFormatado, '75907-210');
      expect(obra().cepFormatado, '');
    });

    test('temCidade exige cidade e UF', () {
      expect(obra(cidade: 'Rio Verde').temCidade, isFalse);
      expect(obra(cidade: 'Rio Verde', uf: 'GO').temCidade, isTrue);
    });

    test('ponto exato só vale com coordenada E marcado como exato', () {
      expect(obra(lat: -17.8, lng: -50.9).temPontoExato, isFalse); // aproximado pela busca
      expect(obra(lat: -17.8, lng: -50.9, exata: true).temPontoExato, isTrue);
      expect(obra(exata: true).temPontoExato, isFalse); // sem coordenada
    });
  });

  test('progresso calculado pelas etapas concluídas', () {
    final o = obra(etapas: [
      EtapaServico(nome: 'A', concluida: true),
      EtapaServico(nome: 'B', concluida: false),
      EtapaServico(nome: 'C', concluida: true),
      EtapaServico(nome: 'D', concluida: false),
    ]);
    expect(o.progresso, 50);
    expect(o.todasEtapasConcluidas, isFalse);
  });
}
