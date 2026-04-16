import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/modules/clientes/dados/modelos/cliente_modelo.dart';

void main() {
  group('ClienteModelo Tests', () {
    final tCriadoEm = DateTime(2023, 1, 1).toUtc();
    final tAtualizadoEm = DateTime(2023, 1, 2).toUtc();
    
    final tClienteModelo = ClienteModelo(
      id: 1,
      nome: 'Empresa Teste',
      email: 'contato@empresateste.com',
      telefone: '11888888888',
      endereco: 'Rua das Flores 123',
      cpfOuCnpj: '00.000.000/0001-00',
      ativo: true,
      criadoEm: tCriadoEm,
      atualizadoEm: tAtualizadoEm,
    );

    test('deMapa deve retornar um ClienteModelo valido', () {
      final mapa = {
        'id_cliente': 1,
        'nome': 'Empresa Teste',
        'email': 'contato@empresateste.com',
        'telefone': '11888888888',
        'endereco': 'Rua das Flores 123',
        'cpf_cnpj': '00.000.000/0001-00',
        'status': true,
        'created_at': tCriadoEm.toIso8601String(),
        'updated_at': tAtualizadoEm.toIso8601String(),
      };

      final result = ClienteModelo.deMapa(mapa);

      expect(result.id, tClienteModelo.id);
      expect(result.nome, tClienteModelo.nome);
      expect(result.email, tClienteModelo.email);
      expect(result.cpfOuCnpj, tClienteModelo.cpfOuCnpj);
      expect(result.ativo, tClienteModelo.ativo);
      expect(result.criadoEm, tClienteModelo.criadoEm);
      expect(result.atualizadoEm, tClienteModelo.atualizadoEm);
    });

    test('paraMapa deve retornar um Map contendo os dados corretos limitados (sem keys geradas)', () {
      final expectedMap = {
        'nome': 'Empresa Teste',
        'email': 'contato@empresateste.com',
        'telefone': '11888888888',
        'endereco': 'Rua das Flores 123',
        'cpf_cnpj': '00.000.000/0001-00',
        'status': true,
      };

      final result = tClienteModelo.paraMapa();

      expect(result, expectedMap);
    });
  });
}
