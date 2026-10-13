import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/core/validadores/validador_cpf.dart';

void main() {
  group('ValidadorCpf.ehValido', () {
    test('aceita CPFs válidos, com ou sem máscara', () {
      expect(ValidadorCpf.ehValido('529.982.247-25'), isTrue);
      expect(ValidadorCpf.ehValido('52998224725'), isTrue);
      expect(ValidadorCpf.ehValido('111.444.777-35'), isTrue);
    });

    test('aplica a regra resto < 2 => dígito 0', () {
      // Soma do 1º dígito dá resto 1, então o 1º verificador é 0.
      expect(ValidadorCpf.ehValido('123.456.789-09'), isTrue);
    });

    test('rejeita dígito verificador errado', () {
      expect(ValidadorCpf.ehValido('529.982.247-24'), isFalse);
      expect(ValidadorCpf.ehValido('529.982.247-35'), isFalse);
    });

    test('rejeita sequências de dígitos repetidos', () {
      for (var d = 0; d <= 9; d++) {
        expect(ValidadorCpf.ehValido('$d' * 11), isFalse, reason: 'sequência $d');
      }
      expect(ValidadorCpf.ehValido('111.111.111-11'), isFalse);
    });

    test('rejeita tamanho diferente de 11 dígitos', () {
      expect(ValidadorCpf.ehValido(''), isFalse);
      expect(ValidadorCpf.ehValido('5299822472'), isFalse);
      expect(ValidadorCpf.ehValido('529982247250'), isFalse);
    });
  });

  group('ValidadorCpf.mensagemErro', () {
    test('CPF válido não gera erro', () {
      expect(ValidadorCpf.mensagemErro('529.982.247-25'), isNull);
    });

    test('vazio é erro só quando obrigatório', () {
      expect(ValidadorCpf.mensagemErro(''), 'Informe o CPF.');
      expect(ValidadorCpf.mensagemErro('', obrigatorio: false), isNull);
      expect(ValidadorCpf.mensagemErro(null, obrigatorio: false), isNull);
    });

    test('incompleto e inválido têm mensagens diferentes', () {
      expect(ValidadorCpf.mensagemErro('529.982'), 'O CPF deve ter 11 dígitos.');
      expect(ValidadorCpf.mensagemErro('111.111.111-11'), 'CPF inválido.');
    });
  });
}
