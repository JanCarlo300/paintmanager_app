import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// Imports de Autenticação
import 'src/apresentacao/paginas/login_page.dart';
import 'src/apresentacao/paginas/recuperar_senha_page.dart';
import 'src/apresentacao/paginas/auth_check.dart';
import 'src/apresentacao/paginas/redefinir_senha_obrigatoria_page.dart';
import 'src/apresentacao/controllers/auth_controller.dart';
import 'src/dados/repositorios/repositorio_autenticacao_impl.dart';

// Imports de Dashboard
import 'src/apresentacao/paginas/dashboard_page.dart';

// Imports de Clientes
import 'src/apresentacao/paginas/cliente_list_page.dart';
import 'src/apresentacao/paginas/cliente_form_page.dart';
import 'src/apresentacao/controllers/cliente_controller.dart';
import 'src/dados/repositorios/repositorio_cliente_impl.dart';
import 'src/dominio/entidades/cliente.dart';

// Imports de Usuários
import 'src/apresentacao/paginas/usuario_list_page.dart';
import 'src/apresentacao/controllers/usuario_controller.dart';
import 'src/dados/repositorios/repositorio_usuario_impl.dart';

// Imports de Financeiro (se houver página real, importe aqui. Se não, use o placeholder abaixo)
import 'src/apresentacao/paginas/financeiro_page.dart';

// Import da página placeholder
import 'src/apresentacao/paginas/em_construcao_page.dart';

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
        ChangeNotifierProvider(
          create: (_) => UsuarioController(RepositorioUsuarioImpl()),
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const AuthCheck(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/recuperar-senha': (context) => RecuperarSenhaPage(),
        '/home': (context) => const DashboardPage(),
        '/redefinir-senha-obrigatoria': (context) => const RedefinirSenhaObrigatoriaPage(),
        '/clientes': (context) => const ClienteListPage(),
        '/usuarios': (context) => const UsuarioListPage(),
        '/financeiro': (context) => const FinanceiroPage(),

        // Telas em construção
        '/obras': (context) => const EmConstrucaoPage(titulo: 'Obras'),
        '/orcamentos': (context) => const EmConstrucaoPage(titulo: 'Orçamentos'),
        '/relatorios': (context) => const EmConstrucaoPage(titulo: 'Relatórios'),
        '/configuracoes': (context) => const EmConstrucaoPage(titulo: 'Configurações'),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/cliente-formulario') {
          final cliente = settings.arguments as Cliente?;
          return MaterialPageRoute(
            builder: (context) => ClienteFormPage(clienteParaEdicao: cliente),
          );
        }
        return null;
      },
    );
  }
}