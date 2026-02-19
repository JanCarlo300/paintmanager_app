import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'src/apresentacao/paginas/login_page.dart';
import 'src/apresentacao/controllers/auth_controller.dart';
import 'src/dados/repositorios/repositorio_autenticacao_impl.dart';
import 'src/apresentacao/paginas/cliente_list_page.dart';
import 'src/apresentacao/controllers/cliente_controller.dart';
import 'src/dados/repositorios/repositorio_cliente_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(RepositorioAutenticacaoImpl()),
        ),

        ChangeNotifierProvider(
          create: (_) => ClienteController(RepositorioClienteImpl()),
        ),
      ],
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

      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),

        '/home': (context) => const ClienteListPage(),
      },
    );
  }
}
