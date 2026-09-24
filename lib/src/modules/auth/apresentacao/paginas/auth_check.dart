import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'redefinir_senha_obrigatoria_page.dart';
import '../../../../apresentacao/paginas/dashboard_page.dart';

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

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;

      if (event == AuthChangeEvent.signedIn) {
        // Login normal (RF001): verifica se a troca obrigatória de senha
        // do primeiro acesso ainda está pendente antes de decidir a rota.
        final pendente = await _primeiroAcessoEstaPendente();
        if (!mounted) return;
        setState(() {
          _isAuthenticated = true;
          _primeiroAcessoPendente = pendente;
          _isLoading = false;
        });
        Navigator.of(context).pushReplacementNamed(
          pendente ? '/redefinir-senha-obrigatoria' : '/home',
        );
      } else if (event == AuthChangeEvent.signedOut) {
        if (!mounted) return;
        setState(() {
          _isAuthenticated = false;
          _primeiroAcessoPendente = false;
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

  /// Consulta se o usuário autenticado no momento ainda precisa trocar a
  /// senha (RF001/RF002). Em caso de erro de leitura, assume que não está
  /// pendente — nunca bloqueia o acesso por falha de rede.
  Future<bool> _primeiroAcessoEstaPendente() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    try {
      final resultado = await Supabase.instance.client
          .from('usuario')
          .select('primeiro_acesso')
          .eq('auth_id', user.id)
          .maybeSingle();
      return resultado?['primeiro_acesso'] as bool? ?? false;
    } catch (_) {
      return false;
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
    // e reabrindo o app.
    final pendente = await _primeiroAcessoEstaPendente();
    if (!mounted) return;
    setState(() {
      _isAuthenticated = true;
      _primeiroAcessoPendente = pendente;
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
      return _primeiroAcessoPendente ? const RedefinirSenhaObrigatoriaPage() : const DashboardPage();
    }

    return const LoginPage();
  }
}
