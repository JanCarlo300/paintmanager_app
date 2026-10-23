import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:paintmanager_app/src/core/servicos/geocodificacao_service.dart';

void main() {
  group('semQuadraLote', () {
    test('tira quadra e lote nos formatos comuns', () {
      expect(GeocodificacaoService.semQuadraLote('Rua Rodezir Baylao QD.N Lt19'), 'Rua Rodezir Baylao');
      expect(GeocodificacaoService.semQuadraLote('Rua do Mogno QD38 LT800'), 'Rua do Mogno');
      expect(GeocodificacaoService.semQuadraLote('Av. Brasil, Quadra 5, Lote 12'), 'Av. Brasil');
    });

    test('endereço sem quadra/lote fica igual', () {
      expect(GeocodificacaoService.semQuadraLote('Rua das Flores, 120'), 'Rua das Flores, 120');
    });
  });

  group('buscarCoordenadasObra', () {
    http.Response resultado(List<Map<String, String>> itens) => http.Response(jsonEncode(itens), 200);

    test('primeiro tenta a busca por campos (rua, cidade, UF, CEP) do Brasil', () async {
      final chamadas = <Uri>[];
      final servico = GeocodificacaoService(
        intervalo: Duration.zero,
        cliente: MockClient((req) async {
          chamadas.add(req.url);
          return resultado([{'lat': '-17.79', 'lon': '-50.92'}]);
        }),
      );

      final c = await servico.buscarCoordenadasObra(
        endereco: 'Rua do Mogno QD38 LT800',
        numero: '15',
        cidade: 'Rio Verde',
        uf: 'GO',
        cep: '75907-210',
      );

      expect(c?.latitude, -17.79);
      expect(c?.longitude, -50.92);
      expect(chamadas, hasLength(1));
      final q = chamadas.single.queryParameters;
      expect(q['street'], '15 Rua do Mogno'); // quadra/lote ficam de fora
      expect(q['city'], 'Rio Verde');
      expect(q['state'], 'GO');
      expect(q['postalcode'], '75907-210');
      expect(q['countrycodes'], 'br');
      expect(chamadas.single.toString(), startsWith('https://nominatim.openstreetmap.org/search'));
    });

    test('se a busca específica não acha, tenta a mais geral', () async {
      var tentativa = 0;
      final servico = GeocodificacaoService(
        intervalo: Duration.zero,
        cliente: MockClient((req) async {
          tentativa++;
          return tentativa < 3 ? resultado([]) : resultado([{'lat': '-17.8', 'lon': '-50.9'}]);
        }),
      );

      final c = await servico.buscarCoordenadasObra(endereco: 'Rua Nova', cidade: 'Rio Verde', uf: 'GO');

      expect(tentativa, 3);
      expect(c?.latitude, -17.8);
    });

    test('nada encontrado devolve null (o cadastro da obra segue sem mapa)', () async {
      final servico = GeocodificacaoService(
        intervalo: Duration.zero,
        cliente: MockClient((_) async => resultado([])),
      );
      expect(await servico.buscarCoordenadasObra(endereco: 'Rua X', cidade: 'Y', uf: 'GO'), isNull);
    });

    test('falha de rede não quebra: devolve null', () async {
      final servico = GeocodificacaoService(
        intervalo: Duration.zero,
        cliente: MockClient((_) async => throw Exception('sem rede')),
      );
      expect(await servico.buscarCoordenadasObra(endereco: 'Rua X', cidade: 'Y', uf: 'GO'), isNull);
    });
  });
}
