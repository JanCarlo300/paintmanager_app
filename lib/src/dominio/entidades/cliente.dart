class Cliente {
  final String? id;
  final String nome;
  final String email;
  final String telefone;
  final String endereco;
  final String cpfOuCnpj;
  final DateTime criadoEm;

  Cliente({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.endereco,
    required this.cpfOuCnpj,
    required this.criadoEm,
  });
}