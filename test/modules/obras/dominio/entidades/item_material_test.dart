import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/modules/obras/dominio/entidades/item_material.dart';

void main() {
  group('ItemMaterial', () {
    test('paraMapa e deMapa preservam a linha digitada', () {
      const item = ItemMaterial('1 lata de tinta Coral Branco Neve 18 L');
      final copia = ItemMaterial.deMapa(item.paraMapa());

      expect(item.paraMapa(), {'descricao': '1 lata de tinta Coral Branco Neve 18 L'});
      expect(copia.descricao, '1 lata de tinta Coral Branco Neve 18 L');
    });

    test('deMapa sem descrição vira texto vazio em vez de quebrar', () {
      expect(ItemMaterial.deMapa({}).descricao, '');
    });
  });
}
