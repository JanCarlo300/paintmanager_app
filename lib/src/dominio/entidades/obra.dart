import 'etapa_servico.dart';

class Obra {
  final String? id;
  final String? orcamentoId;
  final String clienteId;
  final String clienteNome;
  final String tituloDaObra;
  final String endereco;
  final DateTime dataInicio;
  final DateTime dataPrevisaoTermino;
  final DateTime? dataConclusao;
  final String status; // Não Iniciada, Em Andamento, Pausada, Concluída
  final double progresso; // 0 a 100
  final List<EtapaServico> etapasServico;
  final String anotacoes;
  final List<String> materiaisFaltantes;

  Obra({
    this.id,
    this.orcamentoId,
    required this.clienteId,
    required this.clienteNome,
    required this.tituloDaObra,
    required this.endereco,
    required this.dataInicio,
    required this.dataPrevisaoTermino,
    this.dataConclusao,
    this.status = 'Não Iniciada',
    double? progresso,
    required this.etapasServico,
    this.anotacoes = '',
    this.materiaisFaltantes = const [],
  }) : progresso = progresso ?? _calcularProgresso(etapasServico);

  /// Calcula o progresso automaticamente baseado nas etapas concluídas
  static double _calcularProgresso(List<EtapaServico> etapas) {
    if (etapas.isEmpty) return 0;
    final concluidas = etapas.where((e) => e.concluida).length;
    return (concluidas / etapas.length) * 100;
  }

  /// Verifica se todas as etapas estão concluídas
  bool get todasEtapasConcluidas =>
      etapasServico.isNotEmpty && etapasServico.every((e) => e.concluida);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Obra && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
