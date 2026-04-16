import 'package:flutter/material.dart';
import '../../dominio/entidades/transacao.dart';
import '../../dominio/repositorios/repositorio_transacao.dart';

/// Controller do módulo Financeiro — Supabase.
/// Segue o padrão Future + notifyListeners (consistente com OrcamentoController).
/// Mantém a lógica de filtros por mês/ano e cálculos de KPIs do controlador legado.
class FinanceiroController extends ChangeNotifier {
  final RepositorioTransacao _repositorio;
  FinanceiroController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  List<Transacao> _transacoes = [];
  List<Transacao> get transacoes => _transacoes;

  // Mês e ano selecionados para filtro
  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;

  int get mesSelecionado => _mesSelecionado;
  int get anoSelecionado => _anoSelecionado;

  /// Carrega a lista de transações do Supabase
  Future<void> carregarTransacoes() async {
    _carregando = true;
    notifyListeners();
    try {
      _transacoes = await _repositorio.listarTransacoes();
    } catch (e) {
      _transacoes = [];
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Salva (insere ou atualiza) uma transação e recarrega a lista
  Future<void> salvar(Transacao transacao) async {
    _carregando = true;
    notifyListeners();
    try {
      await _repositorio.salvarTransacao(transacao);
      await carregarTransacoes(); // Recarrega após salvar
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Exclui permanentemente uma transação
  Future<void> excluir(int id) async {
    await _repositorio.excluirTransacao(id);
    await carregarTransacoes();
  }

  // ============================================================
  // FILTROS E CÁLCULOS DE KPIs (preservados do controller legado)
  // ============================================================

  void alterarMes(int mes, int ano) {
    _mesSelecionado = mes;
    _anoSelecionado = ano;
    notifyListeners();
  }

  void mesAnterior() {
    if (_mesSelecionado == 1) {
      _mesSelecionado = 12;
      _anoSelecionado--;
    } else {
      _mesSelecionado--;
    }
    notifyListeners();
  }

  void mesProximo() {
    if (_mesSelecionado == 12) {
      _mesSelecionado = 1;
      _anoSelecionado++;
    } else {
      _mesSelecionado++;
    }
    notifyListeners();
  }

  /// Filtra transações pelo mês/ano selecionado
  List<Transacao> filtrarPorMes(List<Transacao> todas) {
    return todas.where((t) =>
      t.dataTransacao.month == _mesSelecionado &&
      t.dataTransacao.year == _anoSelecionado
    ).toList();
  }

  /// Calcula total de receitas do mês
  double calcularReceitas(List<Transacao> transacoesMes) {
    return transacoesMes
        .where((t) => t.tipo == 'Receita' && t.status != 'Pendente')
        .fold<double>(0, (soma, t) => soma + t.valor);
  }

  /// Calcula total de despesas do mês
  double calcularDespesas(List<Transacao> transacoesMes) {
    return transacoesMes
        .where((t) => t.tipo == 'Despesa' && t.status != 'Pendente')
        .fold<double>(0, (soma, t) => soma + t.valor);
  }

  /// Calcula saldo (receitas - despesas)
  double calcularSaldo(List<Transacao> transacoesMes) {
    return calcularReceitas(transacoesMes) - calcularDespesas(transacoesMes);
  }

  /// Calcula total pendente
  double calcularPendentes(List<Transacao> transacoesMes) {
    return transacoesMes
        .where((t) => t.status == 'Pendente')
        .fold<double>(0, (soma, t) => t.tipo == 'Receita' ? soma + t.valor : soma - t.valor);
  }
}
