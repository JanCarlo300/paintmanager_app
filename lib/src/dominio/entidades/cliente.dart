class Cliente {
  final String? id;
  final String nome;
  final String telefone;
  final String? email;
  final String? cidade; 
  final String? endereco;
  final bool status;    
  final int obrasCount; 

  Cliente({
    this.id,
    required this.nome,
    required this.telefone,
    this.email,
    this.cidade,
    this.endereco,
    this.status = true,
    this.obrasCount = 0,
  });
}