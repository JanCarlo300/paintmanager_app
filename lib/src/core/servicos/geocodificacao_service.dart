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
/// identifica o app via User-Agent e não faz mais de 1 requisição por vez.
class GeocodificacaoService {
  static const _userAgent = 'PaintManagerApp/1.0 (TFC UniRV; contato: jancarloalmeida36@gmail.com)';
  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Converte um endereço em texto para coordenadas. Retorna `null` se não
  /// encontrar ou se houver qualquer falha (sem internet, serviço fora do
  /// ar etc.) — a falha aqui nunca deve impedir o cadastro da obra.
  Future<Coordenada?> buscarCoordenadas(String endereco) async {
    final enderecoLimpo = endereco.trim();
    if (enderecoLimpo.isEmpty) return null;

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': enderecoLimpo,
        'format': 'json',
        'limit': '1',
      });

      final resposta = await http
          .get(uri, headers: {'User-Agent': _userAgent})
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
