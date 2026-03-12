import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/relatorio_geral.dart';
import '../../dominio/repositorios/repositorio_relatorio.dart';

class RepositorioRelatorioImpl implements RepositorioRelatorio {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<RelatorioGeral> gerarRelatorio(DateTime inicio, DateTime fim) async {
    final tsInicio = Timestamp.fromDate(inicio);
    final tsFim = Timestamp.fromDate(fim);

    // Busca paralela nas 3 coleções com filtro de data
    final resultados = await Future.wait([
      _buscarTransacoes(tsInicio, tsFim),
      _buscarObras(tsInicio, tsFim),
      _buscarOrcamentos(tsInicio, tsFim),
    ]);

    final transacoes = resultados[0] as Map<String, dynamic>;
    final obras = resultados[1] as Map<String, dynamic>;
    final orcamentos = resultados[2] as Map<String, dynamic>;

    return RelatorioGeral(
      periodoInicio: inicio,
      periodoFim: fim,
      totalReceitas: transacoes['receitas'] as double,
      totalDespesas: transacoes['despesas'] as double,
      quantidadeObrasConcluidas: obras['concluidas'] as int,
      quantidadeObrasEmAndamento: obras['emAndamento'] as int,
      totalOrcamentosGerados: orcamentos['gerados'] as int,
      totalOrcamentosAprovados: orcamentos['aprovados'] as int,
      despesasPorCategoria: transacoes['despesasPorCategoria'] as Map<String, double>,
      receitasPorMes: transacoes['receitasPorMes'] as Map<String, double>,
      despesasPorMes: transacoes['despesasPorMes'] as Map<String, double>,
    );
  }

  Future<Map<String, dynamic>> _buscarTransacoes(Timestamp inicio, Timestamp fim) async {
    final snapshot = await _firestore
        .collection('transacoes')
        .where('dataTransacao', isGreaterThanOrEqualTo: inicio)
        .where('dataTransacao', isLessThanOrEqualTo: fim)
        .get();

    double receitas = 0;
    double despesas = 0;
    final despesasPorCategoria = <String, double>{};
    final receitasPorMes = <String, double>{};
    final despesasPorMes = <String, double>{};
    final formatoMes = DateFormat('MMM', 'pt_BR');

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final valor = (data['valor'] ?? 0).toDouble();
      final tipo = data['tipo'] ?? '';
      final categoria = data['categoria'] ?? 'Outros';
      final dataTransacao = (data['dataTransacao'] as Timestamp?)?.toDate() ?? DateTime.now();
      final chMes = formatoMes.format(dataTransacao);

      if (tipo == 'Receita') {
        receitas += valor;
        receitasPorMes[chMes] = (receitasPorMes[chMes] ?? 0) + valor;
      } else if (tipo == 'Despesa') {
        despesas += valor;
        despesasPorCategoria[categoria] = (despesasPorCategoria[categoria] ?? 0) + valor;
        despesasPorMes[chMes] = (despesasPorMes[chMes] ?? 0) + valor;
      }
    }

    return {
      'receitas': receitas,
      'despesas': despesas,
      'despesasPorCategoria': despesasPorCategoria,
      'receitasPorMes': receitasPorMes,
      'despesasPorMes': despesasPorMes,
    };
  }

  Future<Map<String, dynamic>> _buscarObras(Timestamp inicio, Timestamp fim) async {
    final snapshot = await _firestore
        .collection('obras')
        .get();

    int concluidas = 0;
    int emAndamento = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'] ?? '';
      final dataInicio = (data['dataInicio'] as Timestamp?)?.toDate();

      // Filtrar apenas obras do período
      if (dataInicio != null && dataInicio.isAfter(inicio.toDate().subtract(const Duration(days: 1))) && dataInicio.isBefore(fim.toDate().add(const Duration(days: 1)))) {
        if (status == 'Concluída') concluidas++;
        if (status == 'Em Andamento') emAndamento++;
      }
    }

    return {'concluidas': concluidas, 'emAndamento': emAndamento};
  }

  Future<Map<String, dynamic>> _buscarOrcamentos(Timestamp inicio, Timestamp fim) async {
    final snapshot = await _firestore
        .collection('orcamentos')
        .where('dataCriacao', isGreaterThanOrEqualTo: inicio)
        .where('dataCriacao', isLessThanOrEqualTo: fim)
        .get();

    int gerados = snapshot.docs.length;
    int aprovados = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'Aprovado') aprovados++;
    }

    return {'gerados': gerados, 'aprovados': aprovados};
  }
}
