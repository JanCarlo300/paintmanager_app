import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda a preferência de aparência (Automático, Claro ou Escuro).
///
/// O padrão é seguir o celular ([ThemeMode.system]). A escolha fica salva
/// no aparelho e sobrevive ao fechar o app.
class TemaController extends ChangeNotifier {
  TemaController(this._prefs) : _modo = _ler(_prefs);

  static const chavePreferencia = 'aparencia_tema';

  final SharedPreferences _prefs;
  ThemeMode _modo;

  ThemeMode get modo => _modo;

  Future<void> definir(ThemeMode novo) async {
    if (novo == _modo) return;
    _modo = novo;
    notifyListeners();
    await _prefs.setString(chavePreferencia, _paraTexto(novo));
  }

  static ThemeMode _ler(SharedPreferences prefs) {
    switch (prefs.getString(chavePreferencia)) {
      case 'claro':
        return ThemeMode.light;
      case 'escuro':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _paraTexto(ThemeMode modo) {
    switch (modo) {
      case ThemeMode.light:
        return 'claro';
      case ThemeMode.dark:
        return 'escuro';
      case ThemeMode.system:
        return 'sistema';
    }
  }
}
