import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paintmanager_app/src/apresentacao/widgets/status_chip.dart';
import 'package:paintmanager_app/src/core/tema/cores_app.dart';

void main() {
  // Tema mínimo, sem google_fonts (os testes não têm internet).
  Widget emApp(Widget filho, CoresApp cores) => MaterialApp(
        theme: ThemeData(extensions: [cores]),
        home: Scaffold(body: Center(child: filho)),
      );

  final temas = {'claro': CoresApp.claro, 'escuro': CoresApp.escuro};

  temas.forEach((nome, cores) {
    testWidgets('StatusChip mostra rótulo, ícone e cor no tema $nome', (tester) async {
      await tester.pumpWidget(emApp(const StatusChip('Em Andamento'), cores));

      expect(find.text('Em andamento'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
      final texto = tester.widget<Text>(find.text('Em andamento'));
      expect(texto.style?.color, cores.info);
    });
  });
}
