import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/core/servicos/localizacao_service.dart';

void main() {
  group('extrairCoordenada (link do Google Maps / WhatsApp)', () {
    test('prefere o ponto do alfinete (!3d…!4d…) ao centro do mapa (@…)', () {
      final c = LocalizacaoService.extrairCoordenada(
        'https://www.google.com/maps/place/X/@-17.7900,-50.9200,17z/data=!3m1!4b1!4m4!3m3!8m2!3d-17.7912345!4d-50.9231234',
      );
      expect(c?.latitude, -17.7912345);
      expect(c?.longitude, -50.9231234);
    });

    test('lê ?q=lat,lng (inclusive com vírgula codificada %2C)', () {
      expect(LocalizacaoService.extrairCoordenada('https://maps.google.com/?q=-17.79123,-50.92312')?.latitude, -17.79123);
      expect(LocalizacaoService.extrairCoordenada('https://maps.google.com/maps?q=-17.79%2C-50.92&z=17')?.longitude, -50.92);
    });

    test('lê o centro do mapa (@lat,lng)', () {
      final c = LocalizacaoService.extrairCoordenada('https://www.google.com/maps/@-17.7912,-50.9231,18z');
      expect(c?.latitude, -17.7912);
    });

    test('aceita coordenadas digitadas', () {
      final c = LocalizacaoService.extrairCoordenada('-17.7912, -50.9231');
      expect(c?.latitude, -17.7912);
      expect(c?.longitude, -50.9231);
    });

    test('link sem ponto e texto qualquer não viram coordenada', () {
      expect(LocalizacaoService.extrairCoordenada('https://maps.app.goo.gl/abc'), isNull);
      expect(LocalizacaoService.extrairCoordenada('Rua do Mogno'), isNull);
    });

    test('recusa coordenada impossível e o ponto 0,0', () {
      expect(LocalizacaoService.extrairCoordenada('95.0, -50.0'), isNull);
      expect(LocalizacaoService.extrairCoordenada('0, 0'), isNull);
    });
  });

  group('deTexto', () {
    test('texto vazio pede o link', () {
      expect(() => LocalizacaoService().deTexto('  '), throwsA(contains('Cole o link')));
    });

    test('mensagem de compartilhamento com nome do lugar + link direto', () async {
      final c = await LocalizacaoService().deTexto('Casa da Maria\nhttps://maps.google.com/?q=-17.8,-50.9');
      expect(c.latitude, -17.8);
      expect(c.longitude, -50.9);
    });
  });
}
