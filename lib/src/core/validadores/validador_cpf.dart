/// Item 3.1 — validação de CPF pelo algoritmo Módulo 11.
/// A mesma regra roda no banco (função public.cpf_valido) para que nenhum
/// CPF inválido entre por outro caminho que não o app.
class ValidadorCpf {
  static String apenasDigitos(String cpf) => cpf.replaceAll(RegExp(r'[^0-9]'), '');

  static bool ehValido(String cpf) {
    final digitos = apenasDigitos(cpf);
    if (digitos.length != 11) return false;
    // 000.000.000-00, 111.111.111-11 etc. passam na conta, mas não são CPFs reais.
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digitos)) return false;

    final numeros = digitos.split('').map(int.parse).toList();
    return numeros[9] == _digitoVerificador(numeros, 9) &&
        numeros[10] == _digitoVerificador(numeros, 10);
  }

  /// Pesos decrescentes de (quantidade + 1) até 2 sobre os primeiros
  /// [quantidade] dígitos; resto < 2 vira 0, senão 11 - resto.
  static int _digitoVerificador(List<int> numeros, int quantidade) {
    var soma = 0;
    for (var i = 0; i < quantidade; i++) {
      soma += numeros[i] * (quantidade + 1 - i);
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  /// Mensagem de erro para formulários, ou `null` se válido.
  static String? mensagemErro(String? cpf, {bool obrigatorio = true}) {
    final digitos = apenasDigitos(cpf ?? '');
    if (digitos.isEmpty) return obrigatorio ? 'Informe o CPF.' : null;
    if (digitos.length != 11) return 'O CPF deve ter 11 dígitos.';
    if (!ehValido(digitos)) return 'CPF inválido.';
    return null;
  }
}
