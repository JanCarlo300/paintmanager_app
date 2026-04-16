import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
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

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;
      
      if (mounted) {
        setState(() {
          _isAuthenticated = session != null;
          _isLoading = false;
        });

        if (event == AuthChangeEvent.signedIn) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (event == AuthChangeEvent.signedOut) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    });
  }

  void _checkInitialAuth() {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() {
      _isAuthenticated = session != null;
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
      return const DashboardPage();
    }
    
    return const LoginPage();
  }
}
