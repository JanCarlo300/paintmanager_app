import '../../dominio/entidades/cliente.dart';

/// Modelo de dados — converte entre Map (Supabase/PostgreSQL) e a entidade Cliente.
/// Nenhuma dependência do Firebase. Segue convenção snake_case do PostgreSQL.
class ClienteModelo extends Cliente {
  ClienteModelo({
    super.id,
    required super.nome,
    required super.email,
    required super.telefone,
    required super.endereco,
    required super.cpfOuCnpj,
    super.ativo,
    required super.criadoEm,
    super.atualizadoEm,
  });

  /// Cria um ClienteModelo a partir do Map retornado pelo Supabase (snake_case)
  factory ClienteModelo.deMapa(Map<String, dynamic> mapa) {
    return ClienteModelo(
      id: mapa['id_cliente'],
      nome: mapa['nome'] ?? '',
      email: mapa['email'] ?? '',
      telefone: mapa['telefone'] ?? '',
      endereco: mapa['endereco'] ?? '',
      cpfOuCnpj: mapa['cpf_cnpj'] ?? '',
      ativo: mapa['status'] ?? true,
      criadoEm: DateTime.tryParse(mapa['created_at'] ?? '') ?? DateTime.now(),
      atualizadoEm: mapa['updated_at'] != null
          ? DateTime.tryParse(mapa['updated_at'])
          : null,
    );
  }

  /// Converte para Map compatível com insert/update do Supabase (snake_case)
  /// Não inclui id_cliente (gerado automaticamente pelo banco)
  /// Não inclui created_at/updated_at (gerenciados pelo banco)
  Map<String, dynamic> paraMapa() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'cpf_cnpj': cpfOuCnpj,
      'endereco': endereco,
      'status': ativo,
    };
  }
}
