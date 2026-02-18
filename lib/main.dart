import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'src/apresentacao/paginas/login_page.dart';
import 'src/apresentacao/controllers/auth_controller.dart';
import 'src/dados/repositorios/repositorio_autenticacao_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase usando as opções automáticas [cite: 632]
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    // Provedor para injetar o controlador de autenticação em todo o app
    ChangeNotifierProvider(
      create: (_) => AuthController(RepositorioAutenticacaoImpl()),
      child: const PaintManagerApp(),
    ),
  );
}

class PaintManagerApp extends StatelessWidget {
  const PaintManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PaintManager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Definição das rotas para navegação após o login
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const Scaffold(
          body: Center(child: Text("Bem-vindo ao PaintManager!")),
        ),
      },
    );
  }
}
