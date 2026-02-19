class Cliente {
  final String? id;
  final String nome;
  final String telefone;
  final String? email;
  final String? endereco;

  Cliente({
    this.id,
    required this.nome,
    required this.telefone,
    this.email,
    this.endereco,
  });
}
