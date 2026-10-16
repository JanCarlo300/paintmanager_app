import 'package:flutter/material.dart';

import '../../core/tema/cores_app.dart';
import '../../core/tema/medidas_app.dart';

/// Card padrão do PaintManager: fundo branco (escuro no modo escuro), borda
/// fina, cantos de 16 e sem sombra. Ao tocar, o fundo fica terracota clarinho.
class CardApp extends StatelessWidget {
  const CardApp({
    super.key,
    required this.child,
    this.aoTocar,
    this.aoSegurar,
    this.padding = const EdgeInsets.all(Espaco.x4),
  });

  final Widget child;
  final VoidCallback? aoTocar;
  final VoidCallback? aoSegurar;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Material(
      color: c.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Raio.card),
        side: BorderSide(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        onLongPress: aoSegurar,
        highlightColor: c.primarySoft,
        splashColor: c.primarySoft,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
