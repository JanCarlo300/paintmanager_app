class Usuario {
  final String? id;
  final String nome;
  final String email;
  final String cpf;
  final String telefone;
  final String funcao;
  final bool status;
  final String senha; // Verifique se esta linha existe
  final DateTime criadoEm;

  Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.telefone,
    required this.funcao,
    this.status = true,
    required this.senha, // Verifique aqui
    required this.criadoEm,
  });
}