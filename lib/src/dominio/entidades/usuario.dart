class Usuario {
  final String? id;
  final String nome;
  final String email;
  final String cpf;
  final String telefone;
  final String funcao;
  final bool status;
  final String senha;
  final bool primeiroAcesso; // NOVO CAMPO
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
    this.primeiroAcesso = true, // Padrão é true para novos cadastros
    required this.criadoEm,
  });
}