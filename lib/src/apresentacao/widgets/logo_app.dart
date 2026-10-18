import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/tema/cores_app.dart';
import '../../core/tema/medidas_app.dart';

/// Ícone do PaintManager (pincel sobre fundo grafite).
class LogoApp extends StatelessWidget {
  const LogoApp({super.key, this.tamanho = 40});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/marca/icone.svg',
      width: tamanho,
      height: tamanho,
      semanticsLabel: 'PaintManager',
    );
  }
}

/// Assinatura horizontal: ícone + "PaintManager" em EB Garamond.
/// "Paint" na cor da marca e "Manager" na cor do texto.
class AssinaturaApp extends StatelessWidget {
  const AssinaturaApp({super.key, this.tamanhoLogo = 56, this.estilo});

  final double tamanhoLogo;

  /// Padrão: displaySmall (40 px). No menu lateral, use titleLarge.
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final base = estilo ?? Theme.of(context).textTheme.displaySmall;
    final escuro = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'PaintManager',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LogoApp(tamanho: tamanhoLogo),
          const SizedBox(width: Espaco.x3),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Paint',
                  style: base?.copyWith(
                    color: escuro ? c.accent : c.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: 'Manager',
                  style: base?.copyWith(color: c.ink, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
