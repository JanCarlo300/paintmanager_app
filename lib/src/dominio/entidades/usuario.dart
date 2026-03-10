class Usuario {
  final String? id;
  final String nome;
  final String email;
  final String cpf;
  final String telefone;
  final String funcao;
  final bool status;
  final String senha;
  final bool? primeiroAcesso; // NOVO CAMPO (null = primeiro acesso)
  final DateTime criadoEm;

  Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.telefone,
    required this.funcao,
    this.status = true,
    required this.senha,
    this.primeiroAcesso, // null = primeiro acesso, false = já redefiniu a senha
    required this.criadoEm,
  });
}