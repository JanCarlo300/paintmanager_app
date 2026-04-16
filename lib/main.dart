import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'src/core/config/supabase_config.dart';

// ============================
// Módulo Auth (Supabase)
// ============================
import 'src/modules/auth/apresentacao/paginas/login_page.dart';
import 'src/modules/auth/apresentacao/paginas/recuperar_senha_page.dart';
import 'src/modules/auth/apresentacao/paginas/auth_check.dart';
import 'src/modules/auth/apresentacao/paginas/redefinir_senha_obrigatoria_page.dart';
import 'src/modules/auth/apresentacao/controllers/auth_controller.dart';
import 'src/modules/auth/dados/repositorios/repositorio_autenticacao_impl.dart';
import 'src/modules/auth/apresentacao/controllers/usuario_controller.dart';
import 'src/modules/auth/dados/repositorios/repositorio_usuario_impl.dart';

// Imports de Dashboard
import 'src/apresentacao/paginas/dashboard_page.dart';
import 'src/apresentacao/controllers/dashboard_controller.dart';

// Imports de Clientes (Supabase — módulo migrado)
import 'src/apresentacao/paginas/cliente_list_page.dart';
import 'src/apresentacao/paginas/cliente_form_page.dart';
import 'src/modules/clientes/apresentacao/controllers/cliente_controller.dart';
import 'src/modules/clientes/dados/repositorios/repositorio_cliente_impl.dart';
import 'src/modules/clientes/dominio/entidades/cliente.dart';

// Imports de Usuários (página de listagem)
import 'src/apresentacao/paginas/usuario_list_page.dart';

// Imports de Financeiro (Supabase — módulo migrado)
import 'src/apresentacao/paginas/financeiro_page.dart';
import 'src/apresentacao/paginas/transacao_form_page.dart';
import 'src/modules/financeiro/apresentacao/controllers/financeiro_controller.dart';
import 'src/modules/financeiro/dados/repositorios/repositorio_transacao_impl.dart';
import 'src/modules/financeiro/dominio/entidades/transacao.dart';

// Imports de Orçamento (Supabase — módulo migrado)
import 'src/apresentacao/paginas/orcamento_list_page.dart';
import 'src/apresentacao/paginas/orcamento_form_page.dart';
import 'src/modules/orcamentos/apresentacao/controllers/orcamento_controller.dart';
import 'src/modules/orcamentos/dados/repositorios/repositorio_orcamento_impl.dart';
import 'src/modules/orcamentos/dominio/entidades/orcamento.dart';

// Imports de Obras (Supabase — módulo migrado)
import 'src/apresentacao/paginas/obra_list_page.dart';
import 'src/apresentacao/paginas/obra_form_page.dart';
import 'src/apresentacao/paginas/obra_detalhes_page.dart';
import 'src/modules/obras/apresentacao/controllers/obra_controller.dart';
import 'src/modules/obras/dados/repositorios/repositorio_obra_impl.dart';
import 'src/modules/obras/dominio/entidades/obra.dart';

// Import da página placeholder
import 'src/apresentacao/paginas/em_construcao_page.dart';

// Imports de Relatórios (Supabase — módulo migrado)
import 'src/apresentacao/paginas/relatorios_page.dart';
import 'src/modules/relatorios/apresentacao/controllers/relatorio_controller.dart';
import 'src/modules/relatorios/dados/repositorios/repositorio_relatorio_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega variáveis de ambiente
  await dotenv.load(fileName: '.env');

  // Inicializa Supabase (único backend para Auth & Usuários)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await initializeDateFormatting('pt_BR', null);

  runApp(
    MultiProvider(
      providers: [
        // Dashboard
        ChangeNotifierProvider(
          create: (_) => DashboardController(),
        ),
        // Auth & Usuários — Supabase
        ChangeNotifierProvider(
          create: (_) => AuthController(RepositorioAutenticacaoImpl()),
        ),
        ChangeNotifierProvider(
          create: (_) => UsuarioController(RepositorioUsuarioImpl()),
        ),
        // Clientes — Supabase (migrado)
        ChangeNotifierProvider(
          create: (_) => ClienteController(RepositorioClienteImpl()),
        ),
        // Orçamentos — Supabase (migrado)
        ChangeNotifierProvider(
          create: (_) => OrcamentoController(RepositorioOrcamentoImpl()),
        ),
        // Obras — Supabase (migrado)
        ChangeNotifierProvider(
          create: (_) => ObraController(RepositorioObraImpl()),
        ),
        // Financeiro — Supabase (módulo migrado)
        ChangeNotifierProvider(
          create: (_) => FinanceiroController(RepositorioTransacaoImpl()),
        ),
        // Relatórios — Supabase (módulo migrado)
        ChangeNotifierProvider(
          create: (_) => RelatorioController(RepositorioRelatorioImpl()),
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

        // Orçamentos
        '/orcamentos': (context) => const OrcamentoListPage(),

        // Obras
        '/obras': (context) => const ObraListPage(),

        // Relatórios
        '/relatorios': (context) => const RelatoriosPage(),
        '/configuracoes': (context) => const EmConstrucaoPage(titulo: 'Configurações'),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/cliente-formulario') {
          final cliente = settings.arguments as Cliente?;
          return MaterialPageRoute(
            builder: (context) => ClienteFormPage(clienteParaEdicao: cliente),
          );
        }
        if (settings.name == '/orcamento-formulario') {
          final orcamento = settings.arguments as Orcamento?;
          return MaterialPageRoute(
            builder: (context) => OrcamentoFormPage(orcamentoParaEdicao: orcamento),
          );
        }
        if (settings.name == '/obra-formulario') {
          final obra = settings.arguments as Obra?;
          return MaterialPageRoute(
            builder: (context) => ObraFormPage(obraParaEdicao: obra),
          );
        }
        if (settings.name == '/obra-detalhes') {
          final obra = settings.arguments as Obra;
          return MaterialPageRoute(
            builder: (context) => ObraDetalhesPage(obra: obra),
          );
        }
        if (settings.name == '/transacao-formulario') {
          final args = settings.arguments;
          Transacao? transacao;
          String? tipoInicial;
          if (args is Transacao) {
            transacao = args;
          } else if (args is Map) {
            tipoInicial = args['tipo'] as String?;
          }
          return MaterialPageRoute(
            builder: (context) => TransacaoFormPage(
              transacaoParaEdicao: transacao,
              tipoInicial: tipoInicial,
            ),
          );
        }
        return null;
      },
    );
  }
}