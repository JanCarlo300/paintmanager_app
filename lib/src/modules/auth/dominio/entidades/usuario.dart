class Usuario {
  final int? id;
  final String? authId;
  final String nome;
  final String email;
  final String cpf;
  final String telefone;
  final String funcao;
  final bool status;
  final bool primeiroAcesso;
  final DateTime criadoEm;

  Usuario({
    this.id,
    this.authId,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.telefone,
    required this.funcao,
    this.status = true,
    this.primeiroAcesso = true,
    required this.criadoEm,
  });
}
