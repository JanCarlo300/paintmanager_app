import 'package:flutter/services.dart';
import 'validador_cnpj.dart';

/// Máscara que se adapta: até 11 números formata como CPF; a partir do 12º,
/// como CNPJ. Aceita no máximo 14 números.
class DocumentoInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    var digitos = novo.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.length > 14) digitos = digitos.substring(0, 14);
    final texto = ValidadorDocumento.formatar(digitos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
