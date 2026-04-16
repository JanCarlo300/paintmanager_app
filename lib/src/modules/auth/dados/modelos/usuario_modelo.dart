import '../../dominio/entidades/usuario.dart';

class UsuarioModelo extends Usuario {
  UsuarioModelo({
    super.id,
    super.authId,
    required super.nome,
    required super.email,
    required super.cpf,
    required super.telefone,
    required super.funcao,
    super.status,
    super.primeiroAcesso,
    required super.criadoEm,
  });

  /// Cria um UsuarioModelo a partir de um Map retornado pelo Supabase (PostgreSQL snake_case)
  factory UsuarioModelo.deMapa(Map<String, dynamic> mapa) {
    return UsuarioModelo(
      id: mapa['id_usuario'],
      authId: mapa['auth_id'],
      nome: mapa['nome'] ?? '',
      email: mapa['email'] ?? '',
      cpf: mapa['cpf'] ?? '',
      telefone: mapa['telefone'] ?? '',
      funcao: mapa['funcao'] ?? 'Funcionário',
      status: mapa['status'] ?? true,
      primeiroAcesso: mapa['primeiro_acesso'] ?? true,
      criadoEm: DateTime.tryParse(mapa['criado_em'] ?? '') ?? DateTime.now(),
    );
  }

  /// Converte para Map compatível com insert/update do Supabase (snake_case)
  Map<String, dynamic> paraMapa() {
    return {
      if (authId != null) 'auth_id': authId,
      'nome': nome,
      'email': email,
      'cpf': cpf,
      'telefone': telefone,
      'funcao': funcao,
      'status': status,
      'primeiro_acesso': primeiroAcesso,
      'criado_em': criadoEm.toUtc().toIso8601String(),
    };
  }
}
