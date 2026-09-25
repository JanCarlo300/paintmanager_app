import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'redefinir_senha_obrigatoria_page.dart';
import '../../../../apresentacao/paginas/dashboard_page.dart';
import '../../../obras/apresentacao/paginas/obra_list_page.dart';
import '../controllers/auth_controller.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _primeiroAcessoPendente = false;
  String _funcao = '';

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;

      if (event == AuthChangeEvent.signedIn) {
        // Login normal (RF001): verifica se a troca obrigatória de senha
        // do primeiro acesso ainda está pendente, e qual a função do
        // usuário, antes de decidir a rota.
        final dados = await _dadosDoUsuarioLogado();
        if (!mounted) return;
        setState(() {
          _isAuthenticated = true;
          _primeiroAcessoPendente = dados.primeiroAcessoPendente;
          _funcao = dados.funcao;
          _isLoading = false;
        });
        Navigator.of(context).pushReplacementNamed(
          dados.primeiroAcessoPendente
              ? '/redefinir-senha-obrigatoria'
              : rotaInicialParaFuncao(dados.funcao),
        );
      } else if (event == AuthChangeEvent.signedOut) {
        if (!mounted) return;
        setState(() {
          _isAuthenticated = false;
          _primeiroAcessoPendente = false;
          _funcao = '';
          _isLoading = false;
        });
        Navigator.of(context).pushReplacementNamed('/login');
      }
      // AuthChangeEvent.passwordRecovery é ignorado de propósito: é a
      // sessão criada pelo código de recuperação do RF002 (verifyOTP), e a
      // própria RecuperarSenhaPage controla a navegação desse fluxo. Se
      // reagíssemos aqui também, a pessoa seria jogada para o Dashboard
      // no meio da troca de senha.
    });
  }

  /// Consulta a flag de primeiro acesso e a função do usuário autenticado
  /// no momento. Em caso de erro de leitura, assume que a troca não está
  /// pendente e função vazia (tratada como acesso restrito) — nunca
  /// bloqueia por falha de rede, mas também nunca libera de mais.
  Future<_DadosUsuario> _dadosDoUsuarioLogado() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const _DadosUsuario(primeiroAcessoPendente: false, funcao: '');
    try {
      final resultado = await Supabase.instance.client
          .from('usuario')
          .select('primeiro_acesso, funcao')
          .eq('auth_id', user.id)
          .maybeSingle();
      return _DadosUsuario(
        primeiroAcessoPendente: resultado?['primeiro_acesso'] as bool? ?? false,
        funcao: resultado?['funcao'] as String? ?? '',
      );
    } catch (_) {
      return const _DadosUsuario(primeiroAcessoPendente: false, funcao: '');
    }
  }

  Future<void> _checkInitialAuth() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
      return;
    }

    // Já existe sessão salva (app reaberto): confere se a troca obrigatória
    // de senha ficou pendente, para não deixar pular essa etapa fechando
    // e reabrindo o app, e qual a função para saber a tela inicial.
    final dados = await _dadosDoUsuarioLogado();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = true;
      _primeiroAcessoPendente = dados.primeiroAcessoPendente;
      _funcao = dados.funcao;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    if (_isAuthenticated) {
      if (_primeiroAcessoPendente) return const RedefinirSenhaObrigatoriaPage();
      return _funcao == 'Funcionário' ? const ObraListPage() : const DashboardPage();
    }

    return const LoginPage();
  }
}

class _DadosUsuario {
  final bool primeiroAcessoPendente;
  final String funcao;
  const _DadosUsuario({required this.primeiroAcessoPendente, required this.funcao});
}
