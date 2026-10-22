import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'geocodificacao_service.dart';

/// Ponto exato da obra (latitude/longitude), igual a uma localização enviada
/// pelo WhatsApp: com ele, o "Como chegar" leva até o lote, coisa que a busca
/// por endereço em texto não consegue em bairros sem quadra/lote no mapa.
///
/// Duas formas de obter o ponto:
///  * GPS do celular, estando no local ([localizacaoAtual]);
///  * link do Google Maps / WhatsApp ou coordenadas digitadas ([deTexto]).
///
/// Os erros chegam como `String`, prontas para mostrar ao usuário.
class LocalizacaoService {
  // --- GPS -----------------------------------------------------------------

  Future<Coordenada> localizacaoAtual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'A localização do celular está desligada. Ligue o GPS e tente de novo.';
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied) {
      throw 'Sem permissão de localização, não dá para gravar o ponto.';
    }
    if (permissao == LocationPermission.deniedForever) {
      throw 'A permissão de localização foi negada. Libere em Configurações do Android > Apps > PaintManager > Permissões.';
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 25),
        ),
      );
      return Coordenada(latitude: p.latitude, longitude: p.longitude);
    } catch (_) {
      throw 'Não foi possível pegar a localização. Vá para um lugar aberto e tente de novo.';
    }
  }

  // --- Link / texto --------------------------------------------------------

  static final _url = RegExp(r'https?://\S+');
  static final _par = r'(-?\d{1,2}(?:\.\d+)?)\s*,\s*(-?\d{1,3}(?:\.\d+)?)';

  /// Lê o ponto de um texto colado: "-17.79, -50.92", um link do Google Maps
  /// (inclusive o curto maps.app.goo.gl do botão Compartilhar) ou a mensagem
  /// inteira do compartilhamento (nome do lugar + link).
  Future<Coordenada> deTexto(String texto) async {
    final limpo = texto.trim();
    if (limpo.isEmpty) throw 'Cole o link da localização ou as coordenadas.';

    final link = _url.firstMatch(limpo)?.group(0);
    if (link == null) {
      final c = extrairCoordenada(limpo);
      if (c != null) return c;
      throw 'Não reconheci esse texto. Cole o link do Google Maps ou coordenadas como -17.7912, -50.9231.';
    }

    var url = link;
    final direta = extrairCoordenada(url);
    if (direta != null) return direta;

    // Link curto: segue os redirecionamentos até o endereço completo do Maps.
    url = await _resolverRedirecionamentos(url);
    final c = extrairCoordenada(url);
    if (c != null) return c;
    throw 'Esse link não traz o ponto exato. No Google Maps, toque e segure no lote '
        'para soltar um alfinete, toque em Compartilhar e cole o link aqui.';
  }

  /// Extrai a coordenada de um link do Google Maps ou de "lat, lng".
  /// Prioridade: ponto do alfinete (!3d…!4d…) > parâmetro q/query/ll/destination
  /// > centro do mapa (@lat,lng) > texto "lat, lng".
  static Coordenada? extrairCoordenada(String texto) {
    final t = Uri.decodeFull(texto);
    final padroes = [
      RegExp(r'!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)'),
      RegExp('[?&](?:q|query|ll|destination|daddr|center)=(?:loc:)?$_par'),
      RegExp('@$_par'),
      RegExp('^$_par\$'),
    ];
    for (final p in padroes) {
      final m = p.firstMatch(t.trim());
      if (m == null) continue;
      final lat = double.tryParse(m.group(1)!);
      final lng = double.tryParse(m.group(2)!);
      if (lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180 && (lat != 0 || lng != 0)) {
        return Coordenada(latitude: lat, longitude: lng);
      }
    }
    return null;
  }

  /// Segue o link curto até achar as coordenadas. Devolve a URL final ou,
  /// se o Google responder com uma página, o trecho dela que tem o ponto.
  Future<String> _resolverRedirecionamentos(String inicial) async {
    final cliente = http.Client();
    var atual = Uri.parse(inicial);
    // Como navegador: alguns links do Google respondem diferente para apps.
    const cabecalhos = {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Mobile Safari/537.36',
      'Accept-Language': 'pt-BR,pt;q=0.9',
    };
    try {
      for (var i = 0; i < 8; i++) {
        final req = http.Request('GET', atual)
          ..followRedirects = false
          ..headers.addAll(cabecalhos);
        final resp = await cliente.send(req).timeout(const Duration(seconds: 12));
        final destino = resp.headers['location'];

        if (resp.statusCode >= 300 && resp.statusCode < 400 && destino != null) {
          await resp.stream.drain<void>();
          atual = atual.resolve(destino);
          // Página de consentimento do Google: o destino vem em ?continue=
          final continuar = atual.queryParameters['continue'];
          if (atual.host.contains('consent.') && continuar != null) atual = Uri.parse(continuar);
          if (extrairCoordenada(atual.toString()) != null) return atual.toString();
          continue;
        }

        // Sem redirecionamento: procura o ponto dentro da página.
        final corpo = await resp.stream.bytesToString();
        final noCorpo = RegExp(r'!3d-?\d+(?:\.\d+)?!4d-?\d+(?:\.\d+)?|@-?\d{1,2}\.\d+,-?\d{1,3}\.\d+|[?&](?:q|ll|center)=-?\d{1,2}\.\d+(?:,|%2C)-?\d{1,3}\.\d+')
            .firstMatch(corpo)
            ?.group(0);
        return noCorpo ?? atual.toString();
      }
      return atual.toString();
    } catch (_) {
      throw 'Não foi possível abrir o link. Confira a internet e tente de novo.';
    } finally {
      cliente.close();
    }
  }
}
