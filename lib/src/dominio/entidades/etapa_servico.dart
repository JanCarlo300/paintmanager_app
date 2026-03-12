class EtapaServico {
  final String nome;
  final bool concluida;

  EtapaServico({
    required this.nome,
    this.concluida = false,
  });

  EtapaServico copiarCom({bool? concluida}) {
    return EtapaServico(
      nome: nome,
      concluida: concluida ?? this.concluida,
    );
  }
}
