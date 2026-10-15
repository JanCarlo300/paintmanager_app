import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/modules/obras/dominio/entidades/item_material.dart';

void main() {
  group('ItemMaterial', () {
    test('paraMapa e deMapa preservam os dados', () {
      const item = ItemMaterial(descricao: 'Tinta acrílica fosca', quantidade: 3, unidade: 'lata 18 L');
      final copia = ItemMaterial.deMapa(item.paraMapa());

      expect(copia.descricao, 'Tinta acrílica fosca');
      expect(copia.quantidade, 3);
      expect(copia.unidade, 'lata 18 L');
    });

    test('deMapa aceita quantidade inteira, decimal, texto com vírgula ou ausente', () {
      expect(ItemMaterial.deMapa({'descricao': 'a', 'quantidade': 2}).quantidade, 2.0);
      expect(ItemMaterial.deMapa({'descricao': 'a', 'quantidade': 2.5}).quantidade, 2.5);
      expect(ItemMaterial.deMapa({'descricao': 'a', 'quantidade': '1,5'}).quantidade, 1.5);
      expect(ItemMaterial.deMapa({'descricao': 'a'}).quantidade, isNull);
      expect(ItemMaterial.deMapa({'descricao': 'a'}).unidade, '');
    });

    test('quantidade formatada no padrão brasileiro', () {
      expect(const ItemMaterial(descricao: 'a', quantidade: 3).quantidadeFormatada, '3');
      expect(const ItemMaterial(descricao: 'a', quantidade: 2.5).quantidadeFormatada, '2,5');
      expect(const ItemMaterial(descricao: 'a').quantidadeFormatada, '');
    });

    test('quantidadeComUnidade omite partes vazias', () {
      expect(const ItemMaterial(descricao: 'a', quantidade: 3, unidade: 'lata 18 L').quantidadeComUnidade,
          '3 lata 18 L');
      expect(const ItemMaterial(descricao: 'a', unidade: 'galão').quantidadeComUnidade, 'galão');
      expect(const ItemMaterial(descricao: 'a', quantidade: 2).quantidadeComUnidade, '2');
      expect(const ItemMaterial(descricao: 'a').quantidadeComUnidade, '');
    });
  });
}
