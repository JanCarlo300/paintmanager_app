import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/core/tema/cores_graficos.dart';

void main() {
  const categorias = ['Mão de Obra', 'Materiais', 'Ferramentas', 'Transporte', 'Alimentação', 'Outros'];

  for (final brilho in Brightness.values) {
    group('corDaCategoria (${brilho.name})', () {
      test('cada categoria tem uma cor diferente', () {
        final cores = categorias.map((c) => corDaCategoria(c, brilho)).toSet();
        expect(cores.length, categorias.length);
      });

      test('a cor não depende de maiúsculas nem de espaços', () {
        expect(corDaCategoria('  materiais ', brilho), corDaCategoria('Materiais', brilho));
      });

      test('categoria desconhecida usa um tom neutro diferente das conhecidas', () {
        final neutra = corDaCategoria('Categoria nova', brilho);
        expect(categorias.map((c) => corDaCategoria(c, brilho)), isNot(contains(neutra)));
      });
    });
  }

  test('claro e escuro usam tons diferentes para a mesma categoria', () {
    for (final c in categorias) {
      expect(corDaCategoria(c, Brightness.light), isNot(corDaCategoria(c, Brightness.dark)));
    }
  });
}
