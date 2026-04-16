import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/modules/auth/dados/modelos/usuario_modelo.dart';

void main() {
  group('UsuarioModelo Tests', () {
    final tCriadoEm = DateTime(2023, 1, 1).toUtc();
    
    final tUsuarioModelo = UsuarioModelo(
      id: 1,
      authId: 'auth-123',
      nome: 'João Teste',
      email: 'joao@teste.com',
      cpf: '12345678900',
      telefone: '11999999999',
      funcao: 'Admin',
      status: true,
      primeiroAcesso: false,
      criadoEm: tCriadoEm,
    );

    test('deMapa deve retornar um UsuarioModelo valido', () {
      final mapa = {
        'id_usuario': 1,
        'auth_id': 'auth-123',
        'nome': 'João Teste',
        'email': 'joao@teste.com',
        'cpf': '12345678900',
        'telefone': '11999999999',
        'funcao': 'Admin',
        'status': true,
        'primeiro_acesso': false,
        'criado_em': tCriadoEm.toIso8601String(),
      };

      final result = UsuarioModelo.deMapa(mapa);

      expect(result.id, tUsuarioModelo.id);
      expect(result.nome, tUsuarioModelo.nome);
      expect(result.email, tUsuarioModelo.email);
      expect(result.cpf, tUsuarioModelo.cpf);
      expect(result.funcao, tUsuarioModelo.funcao);
      expect(result.status, tUsuarioModelo.status);
      expect(result.primeiroAcesso, tUsuarioModelo.primeiroAcesso);
      expect(result.criadoEm, tUsuarioModelo.criadoEm);
    });

    test('paraMapa deve retornar um Map contendo os dados corretos', () {
      final expectedMap = {
        'auth_id': 'auth-123',
        'nome': 'João Teste',
        'email': 'joao@teste.com',
        'cpf': '12345678900',
        'telefone': '11999999999',
        'funcao': 'Admin',
        'status': true,
        'primeiro_acesso': false,
        'criado_em': tCriadoEm.toIso8601String(),
      };

      final result = tUsuarioModelo.paraMapa();

      expect(result, expectedMap);
    });
  });
}
