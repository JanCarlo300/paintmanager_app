import 'package:flutter/material.dart';

import '../../core/tema/cores_app.dart';

/// Ícone de módulo num círculo terracota clarinho (menu e Resumo Geral).
class IconeModulo extends StatelessWidget {
  const IconeModulo(this.icone, {super.key, this.diametro = 40, this.ativo = false});

  final IconData icone;
  final double diametro;

  /// No menu, o item selecionado usa o ícone preenchido.
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icone, size: diametro * 0.55, color: c.primary, fill: ativo ? 1 : 0),
    );
  }
}
