import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/core/tema/tema_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('padrão é seguir o celular', () async {
    final prefs = await SharedPreferences.getInstance();
    expect(TemaController(prefs).modo, ThemeMode.system);
  });

  test('a escolha fica salva e volta ao reabrir o app', () async {
    final prefs = await SharedPreferences.getInstance();
    await TemaController(prefs).definir(ThemeMode.dark);

    final reaberto = TemaController(prefs);
    expect(reaberto.modo, ThemeMode.dark);
  });

  test('avisa a tela quando muda', () async {
    final prefs = await SharedPreferences.getInstance();
    final controller = TemaController(prefs);
    var avisos = 0;
    controller.addListener(() => avisos++);

    await controller.definir(ThemeMode.light);
    await controller.definir(ThemeMode.light); // repetido: não avisa de novo

    expect(avisos, 1);
  });
}
