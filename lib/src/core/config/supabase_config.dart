import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Acesso centralizado às variáveis de ambiente e instância do Supabase.
/// Sempre use esta classe para obter as configurações — nunca hardcode.
class SupabaseConfig {
  // Impede instanciação
  SupabaseConfig._();

  /// URL pública do projeto Supabase
  static String get url => dotenv.env['SUPABASE_URL']!;

  /// Chave anônima (segura para uso no cliente Flutter)
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY']!;

  /// Instância centralizada do SupabaseClient
  static SupabaseClient get client => Supabase.instance.client;
}
