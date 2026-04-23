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
    // Helper para garantir parse de inteiro
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    // Helper para parse booleano seguro
    bool parseBool(dynamic value, {bool padrao = true}) {
      if (value == null) return padrao;
      if (value is bool) return value;
      final str = value.toString().toLowerCase();
      if (str == 'true' || str == '1' || str == 't' || str == 'yes') return true;
      if (str == 'false' || str == '0' || str == 'f' || str == 'no') return false;
      return padrao;
    }

    return ClienteModelo(
      id: parseInt(mapa['id_cliente']) ?? parseInt(mapa['id']),
      nome: mapa['nome']?.toString() ?? '',
      email: mapa['email']?.toString() ?? '',
      telefone: mapa['telefone']?.toString() ?? '',
      endereco: mapa['endereco']?.toString() ?? '',
      cpfOuCnpj: mapa['cpf_cnpj']?.toString() ?? '',
      ativo: parseBool(mapa['status'], padrao: true),
      criadoEm: DateTime.tryParse(mapa['created_at']?.toString() ?? '') ?? DateTime.now(),
      atualizadoEm: mapa['updated_at'] != null
          ? DateTime.tryParse(mapa['updated_at'].toString())
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
