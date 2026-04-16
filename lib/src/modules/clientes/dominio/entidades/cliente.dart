/// Entidade de domínio — Cliente (Supabase)
/// Sem dependências de Firebase. Usada por toda a camada de apresentação.
class Cliente {
  final int? id;
  final String nome;
  final String email;
  final String telefone;
  final String endereco;
  final String cpfOuCnpj;
  final bool ativo;
  final DateTime criadoEm;
  final DateTime? atualizadoEm;

  Cliente({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.endereco,
    required this.cpfOuCnpj,
    this.ativo = true,
    required this.criadoEm,
    this.atualizadoEm,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cliente && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
