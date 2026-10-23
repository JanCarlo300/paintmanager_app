import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/tema/medidas_app.dart';

/// Lista que desenha [porPagina] itens por vez, com "Mostrar mais" no fim.
/// Mantém as telas leves com muitos registros (os filtros e contagens
/// continuam valendo sobre a lista inteira, que já vem filtrada).
///
/// Para voltar aos primeiros itens quando a busca ou o filtro mudam, passe
/// uma [Key] que mude junto (ex.: ValueKey('$busca|$filtro')).
class ListaPaginada<T> extends StatefulWidget {
  const ListaPaginada({
    super.key,
    required this.itens,
    required this.construir,
    this.porPagina = 20,
  });

  final List<T> itens;
  final Widget Function(T item) construir;
  final int porPagina;

  @override
  State<ListaPaginada<T>> createState() => _ListaPaginadaState<T>();
}

class _ListaPaginadaState<T> extends State<ListaPaginada<T>> {
  late int _limite = widget.porPagina;

  @override
  Widget build(BuildContext context) {
    final visiveis = widget.itens.take(_limite).toList();
    final restantes = widget.itens.length - visiveis.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in visiveis) widget.construir(item),
        if (restantes > 0)
          Padding(
            padding: const EdgeInsets.only(top: Espaco.x2, bottom: Espaco.x4),
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _limite += widget.porPagina),
              icon: const Icon(Symbols.expand_more_rounded, size: TamanhoIcone.pequeno),
              label: Text('Mostrar mais ($restantes restante${restantes == 1 ? '' : 's'})'),
            ),
          ),
      ],
    );
  }
}
