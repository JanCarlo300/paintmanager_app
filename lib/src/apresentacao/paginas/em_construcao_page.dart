import 'package:flutter/material.dart';
import '../widgets/drawer_comum.dart';
import '../../core/tema/paleta_sahara.dart';

/// Página placeholder para módulos ainda não implementados.
class EmConstrucaoPage extends StatelessWidget {
  final String titulo;

  const EmConstrucaoPage({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PaletaSahara.background,
      drawer: const DrawerComum(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: PaletaSahara.cardSurface,
        foregroundColor: PaletaSahara.onSurface,
        elevation: 0.5,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              titulo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Tela em construção",
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            Text(
              "Este módulo será implementado em breve.",
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
