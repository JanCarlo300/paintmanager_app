import '../../../obras/dominio/entidades/obra.dart';

/// Números do Resumo Geral (tela inicial do Administrador e do Gerente).
class ResumoGeral {
  final int obrasAtivas;          // obras Em Andamento
  final int orcamentosPendentes;
  final double receitaMes;        // lançamentos não pendentes do mês atual
  final double despesaMes;
  final List<Obra> obrasRecentes; // as 3 de início mais recente

  const ResumoGeral({
    required this.obrasAtivas,
    required this.orcamentosPendentes,
    required this.receitaMes,
    required this.despesaMes,
    required this.obrasRecentes,
  });

  static const vazio = ResumoGeral(
    obrasAtivas: 0,
    orcamentosPendentes: 0,
    receitaMes: 0,
    despesaMes: 0,
    obrasRecentes: [],
  );

  double get saldoMes => receitaMes - despesaMes;
}
