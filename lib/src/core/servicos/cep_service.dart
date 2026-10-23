import 'dart:convert';
import 'package:http/http.dart' as http;

/// Endereço devolvido pela consulta de CEP.
class EnderecoCep {
  final String cep;        // só números
  final String logradouro; // pode vir vazio em CEP de cidade inteira
  final String bairro;
  final String cidade;
  final String uf;

  const EnderecoCep({
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.cidade,
    required this.uf,
  });
}

/// Busca o endereço pelo CEP no ViaCEP (gratuito, sem chave de API) — o mesmo
/// preenchimento automático dos sites de compra. Os erros chegam como
/// `String`, prontas para mostrar ao usuário.
class CepService {
  /// [cliente] permite testar sem internet (MockClient); no app fica nulo.
  CepService({http.Client? cliente}) : _cliente = cliente;
  final http.Client? _cliente;

  static String soDigitos(String cep) => cep.replaceAll(RegExp(r'[^0-9]'), '');

  Future<EnderecoCep> buscar(String cep) async {
    final digitos = soDigitos(cep);
    if (digitos.length != 8) throw 'O CEP tem 8 números.';

    final http.Response resposta;
    try {
      final uri = Uri.parse('https://viacep.com.br/ws/$digitos/json/');
      resposta = await (_cliente?.get(uri) ?? http.get(uri))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw 'Não foi possível consultar o CEP. Confira a internet.';
    }
    if (resposta.statusCode != 200) throw 'CEP inválido.';

    final dados = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    if (dados['erro'] != null) throw 'CEP não encontrado. Confira os números.';

    return EnderecoCep(
      cep: digitos,
      logradouro: (dados['logradouro'] ?? '').toString(),
      bairro: (dados['bairro'] ?? '').toString(),
      cidade: (dados['localidade'] ?? '').toString(),
      uf: (dados['uf'] ?? '').toString(),
    );
  }
}
