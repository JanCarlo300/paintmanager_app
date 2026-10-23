import 'dart:convert';
import 'package:http/http.dart' as http;

/// Coordenada geográfica simples (latitude/longitude).
class Coordenada {
  final double latitude;
  final double longitude;
  const Coordenada({required this.latitude, required this.longitude});
}

/// Item 3.2 — Geocodificação gratuita via Nominatim (OpenStreetMap).
/// Sem chave de API, sem cartão de crédito. Respeita a política de uso
/// do Nominatim (https://operations.osmfoundation.org/policies/nominatim/):
/// identifica o app via User-Agent e faz no máximo 1 requisição por segundo.
///
/// O resultado é APROXIMADO (o mapa gratuito não conhece quadra/lote e tem
/// falhas em ruas novas). Ele serve de ponto de partida para o "Confirmar no
/// mapa", onde o usuário arrasta o pino até o lote — esse sim é o ponto exato.
class GeocodificacaoService {
  /// [cliente] e [intervalo] permitem testar sem internet e sem espera.
  GeocodificacaoService({http.Client? cliente, this.intervalo = const Duration(milliseconds: 1100)})
      : _cliente = cliente;
  final http.Client? _cliente;

  /// Espera entre tentativas (política do Nominatim: 1 requisição por segundo).
  final Duration intervalo;

  static const _userAgent = 'PaintManagerApp/1.0 (TFC UniRV; contato: jancarloalmeida36@gmail.com)';
  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// "QD.N Lt19", "Quadra 38 Lote 800", "Ch 5"... atrapalham a busca no mapa.
  static final _quadraLote = RegExp(
    r'\b(qd|quadra|ql|lt|lote|ch|ch[aá]cara)\.?\s*[\w-]+',
    caseSensitive: false,
  );

  /// Tira quadra/lote e sobras de pontuação: "Rua X QD.N Lt19" → "Rua X".
  static String semQuadraLote(String endereco) => endereco
      .replaceAll(_quadraLote, ' ')
      .replaceAll(RegExp(r'\s*,\s*,+'), ',')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .replaceAll(RegExp(r'^[\s,.-]+|[\s,.-]+$'), '')
      .trim();

  /// Tenta achar a obra do mais específico para o mais geral; a última
  /// tentativa é só o CEP ou a cidade (para o mapa de confirmação abrir
  /// perto). Retorna `null` se nada for encontrado ou houver falha — a falha
  /// aqui nunca deve impedir o cadastro da obra.
  Future<Coordenada?> buscarCoordenadasObra({
    required String endereco,
    String numero = '',
    String bairro = '',
    String cidade = '',
    String uf = '',
    String cep = '',
    bool aceitarSoCidade = false,
  }) async {
    final rua = semQuadraLote(endereco);
    final num = numero.trim().toUpperCase() == 'S/N' ? '' : numero.trim();
    final cepDigitos = cep.replaceAll(RegExp(r'[^0-9]'), '');
    final cepFmt = cepDigitos.length == 8 ? '${cepDigitos.substring(0, 5)}-${cepDigitos.substring(5)}' : '';
    String juntar(List<String> partes) =>
        [...partes.map((p) => p.trim()).where((p) => p.isNotEmpty), 'Brasil'].join(', ');

    final tentativas = <Future<Coordenada?> Function()>[
      if (rua.isNotEmpty && cidade.trim().isNotEmpty)
        () => _buscar({
              'street': [num, rua].where((p) => p.isNotEmpty).join(' '),
              'city': cidade.trim(),
              if (uf.trim().isNotEmpty) 'state': uf.trim(),
              if (cepFmt.isNotEmpty) 'postalcode': cepFmt,
              'country': 'Brasil',
            }),
      if (rua.isNotEmpty) () => buscarCoordenadas(juntar(['$rua${num.isEmpty ? '' : ', $num'}', bairro, cidade, uf])),
      if (rua.isNotEmpty && cidade.trim().isNotEmpty) () => buscarCoordenadas(juntar([rua, cidade, uf])),
      if (aceitarSoCidade && cepFmt.isNotEmpty) () => _buscar({'postalcode': cepFmt, 'country': 'Brasil'}),
      if (aceitarSoCidade && cidade.trim().isNotEmpty) () => buscarCoordenadas(juntar([cidade, uf])),
    ];

    for (var i = 0; i < tentativas.length; i++) {
      if (i > 0) await Future<void>.delayed(intervalo);
      final coordenada = await tentativas[i]();
      if (coordenada != null) return coordenada;
    }
    return null;
  }

  /// Converte um endereço em texto para coordenadas (uma única busca).
  Future<Coordenada?> buscarCoordenadas(String endereco) async {
    final enderecoLimpo = endereco.trim();
    if (enderecoLimpo.isEmpty) return null;
    return _buscar({'q': enderecoLimpo});
  }

  Future<Coordenada?> _buscar(Map<String, String> parametros) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        ...parametros,
        'format': 'json',
        'limit': '1',
        'countrycodes': 'br',
      });

      final cabecalhos = {'User-Agent': _userAgent};
      final resposta = await (_cliente?.get(uri, headers: cabecalhos) ?? http.get(uri, headers: cabecalhos))
          .timeout(const Duration(seconds: 10));

      if (resposta.statusCode != 200) return null;

      final resultados = jsonDecode(resposta.body) as List;
      if (resultados.isEmpty) return null;

      final primeiro = resultados.first as Map<String, dynamic>;
      final lat = double.tryParse(primeiro['lat']?.toString() ?? '');
      final lon = double.tryParse(primeiro['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;

      return Coordenada(latitude: lat, longitude: lon);
    } catch (_) {
      return null;
    }
  }
}
