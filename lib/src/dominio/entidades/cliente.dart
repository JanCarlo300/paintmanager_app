class Cliente {
  final String? id;
  final String nome;
  final String email;
  final String telefone;
  final String endereco;
  final String cpfOuCnpj;
  final DateTime criadoEm;
  final bool ativo;

  Cliente({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.endereco,
    required this.cpfOuCnpj,
    required this.criadoEm,
    this.ativo = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cliente && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}