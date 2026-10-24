import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/core/validadores/documento_input_formatter.dart';
import 'package:paintmanager_app/src/core/validadores/validador_cnpj.dart';

void main() {
  group('ValidadorCnpj (Módulo 11)', () {
    test('CNPJs válidos, com e sem máscara', () {
      expect(ValidadorCnpj.ehValido('11.222.333/0001-81'), isTrue);
      expect(ValidadorCnpj.ehValido('11444777000161'), isTrue);
    });

    test('dígito verificador errado, repetido ou incompleto', () {
      expect(ValidadorCnpj.ehValido('11.222.333/0001-80'), isFalse);
      expect(ValidadorCnpj.ehValido('11.111.111/1111-11'), isFalse);
      expect(ValidadorCnpj.ehValido('1122233300'), isFalse);
    });
  });

  group('ValidadorDocumento (campo CPF ou CNPJ do cliente)', () {
    test('vazio é aceito (campo opcional)', () {
      expect(ValidadorDocumento.mensagemErro(''), isNull);
      expect(ValidadorDocumento.mensagemErro('', obrigatorio: true), isNotNull);
    });

    test('decide pelo tamanho: 11 = CPF, 14 = CNPJ', () {
      expect(ValidadorDocumento.mensagemErro('529.982.247-25'), isNull);
      expect(ValidadorDocumento.mensagemErro('529.982.247-24'), 'CPF inválido.');
      expect(ValidadorDocumento.mensagemErro('11.222.333/0001-81'), isNull);
      expect(ValidadorDocumento.mensagemErro('11.222.333/0001-80'), 'CNPJ inválido.');
      expect(ValidadorDocumento.mensagemErro('1234567'), contains('11 números'));
    });

    test('formatar', () {
      expect(ValidadorDocumento.formatar('52998224725'), '529.982.247-25');
      expect(ValidadorDocumento.formatar('11222333000181'), '11.222.333/0001-81');
      expect(ValidadorDocumento.formatar('5299'), '529.9');
    });
  });

  group('DocumentoInputFormatter', () {
    TextEditingValue digitar(String texto) =>
        DocumentoInputFormatter().formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: texto));

    test('vira CPF até 11 números e CNPJ a partir do 12º', () {
      expect(digitar('52998224725').text, '529.982.247-25');
      expect(digitar('112223330001').text, '11.222.333/0001');
      expect(digitar('11222333000181').text, '11.222.333/0001-81');
    });

    test('ignora letras e corta no 14º número', () {
      expect(digitar('11a222b333000181999').text, '11.222.333/0001-81');
    });
  });
}
