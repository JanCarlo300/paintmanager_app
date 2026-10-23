import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/modules/auth/dominio/validador_senha.dart';

void main() {
  group('ValidadorSenha (RF002 e primeiro acesso)', () {
    test('senha boa passa', () {
      expect(ValidadorSenha.validar('pintura2026', 'pintura2026', cpf: '529.982.247-25'), isNull);
    });

    test('menos de 8 caracteres', () {
      expect(ValidadorSenha.validar('abc123', 'abc123'), contains('8 caracteres'));
    });

    test('sem letra', () {
      expect(ValidadorSenha.validar('12345678', '12345678'), contains('letra'));
    });

    test('sem número', () {
      expect(ValidadorSenha.validar('abcdefgh', 'abcdefgh'), contains('número'));
    });

    test('senha igual ao CPF é recusada', () {
      // A senha inicial é o CPF; ele só tem números, então a regra "precisa
      // ter letra" já barra antes da comparação com o CPF.
      expect(ValidadorSenha.validar('52998224725', '52998224725', cpf: '529.982.247-25'), isNotNull);
    });

    test('confirmação diferente', () {
      expect(ValidadorSenha.validar('pintura2026', 'pintura2025'), contains('não coincidem'));
    });
  });
}
