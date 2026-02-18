// Define os tipos de usuários permitidos no sistema conforme o TFC [cite: 322]
enum TipoUsuario { administrador, gerente, funcionario }

class Usuario {
  final String id;
  final String nome;
  final String email;
  final String cpf;
  final TipoUsuario tipo;
  final bool estaAtivo;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.tipo,
    this.estaAtivo = true,
  });
}
