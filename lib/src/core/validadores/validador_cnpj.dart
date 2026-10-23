import 'validador_cpf.dart';

/// Validação de CNPJ pelo Módulo 11 (mesma ideia do CPF, outros pesos).
/// A mesma regra roda no banco (função public.cnpj_valido).
class ValidadorCnpj {
  static bool ehValido(String cnpj) {
    final digitos = ValidadorCpf.apenasDigitos(cnpj);
    if (digitos.length != 14) return false;
    // 00.000.000/0000-00, 11.111.111/1111-11... passam na conta, mas não existem.
    if (RegExp(r'^(\d)\1{13}$').hasMatch(digitos)) return false;

    final n = digitos.split('').map(int.parse).toList();
    return n[12] == _digito(n, const [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]) &&
        n[13] == _digito(n, const [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
  }

  static int _digito(List<int> n, List<int> pesos) {
    var soma = 0;
    for (var i = 0; i < pesos.length; i++) {
      soma += n[i] * pesos[i];
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }
}

/// CPF (11 dígitos) ou CNPJ (14 dígitos), como no cadastro de cliente.
class ValidadorDocumento {
  /// Mensagem de erro para formulários, ou `null` se válido.
  static String? mensagemErro(String? valor, {bool obrigatorio = false}) {
    final d = ValidadorCpf.apenasDigitos(valor ?? '');
    if (d.isEmpty) return obrigatorio ? 'Informe o CPF ou CNPJ.' : null;
    if (d.length == 11) return ValidadorCpf.ehValido(d) ? null : 'CPF inválido.';
    if (d.length == 14) return ValidadorCnpj.ehValido(d) ? null : 'CNPJ inválido.';
    return 'Use 11 números (CPF) ou 14 (CNPJ).';
  }

  /// 52998224725 → 529.982.247-25; 11222333000181 → 11.222.333/0001-81.
  static String formatar(String valor) {
    final d = ValidadorCpf.apenasDigitos(valor);
    final b = StringBuffer();
    if (d.length <= 11) {
      for (var i = 0; i < d.length; i++) {
        if (i == 3 || i == 6) b.write('.');
        if (i == 9) b.write('-');
        b.write(d[i]);
      }
    } else {
      for (var i = 0; i < d.length && i < 14; i++) {
        if (i == 2 || i == 5) b.write('.');
        if (i == 8) b.write('/');
        if (i == 12) b.write('-');
        b.write(d[i]);
      }
    }
    return b.toString();
  }
}
