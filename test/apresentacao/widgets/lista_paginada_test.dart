import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/apresentacao/widgets/lista_paginada.dart';
import 'package:paintmanager_app/src/core/tema/tema_app.dart';

void main() {
  Widget app(List<int> itens) => MaterialApp(
        theme: temaClaro(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListaPaginada<int>(
              itens: itens,
              porPagina: 5,
              construir: (i) => SizedBox(height: 20, child: Text('item $i')),
            ),
          ),
        ),
      );

  testWidgets('mostra a primeira página e o botão com quantos faltam', (tester) async {
    await tester.pumpWidget(app(List.generate(12, (i) => i)));
    expect(find.text('item 4'), findsOneWidget);
    expect(find.text('item 5'), findsNothing);
    expect(find.text('Mostrar mais (7 restantes)'), findsOneWidget);
  });

  testWidgets('"Mostrar mais" traz a próxima página até acabar', (tester) async {
    await tester.pumpWidget(app(List.generate(7, (i) => i)));
    await tester.tap(find.textContaining('Mostrar mais'));
    await tester.pump();
    expect(find.text('item 6'), findsOneWidget);
    expect(find.textContaining('Mostrar mais'), findsNothing);
  });

  testWidgets('lista curta não mostra o botão', (tester) async {
    await tester.pumpWidget(app([1, 2]));
    expect(find.textContaining('Mostrar mais'), findsNothing);
  });
}
