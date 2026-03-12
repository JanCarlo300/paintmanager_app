import 'package:flutter/material.dart';
import '../../dominio/entidades/transacao.dart';
import '../../dominio/repositorios/repositorio_transacao.dart';

class FinanceiroController extends ChangeNotifier {
  final RepositorioTransacao _repositorio;
  FinanceiroController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  // Mês e ano selecionados para filtro
  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;

  int get mesSelecionado => _mesSelecionado;
  int get anoSelecionado => _anoSelecionado;

  Stream<List<Transacao>> get transacoes => _repositorio.listarTransacoes();

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

  Future<void> salvar(Transacao transacao) async {
    _carregando = true;
    notifyListeners();
    try {
      await _repositorio.salvarTransacao(transacao);
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> excluir(String id) async {
    await _repositorio.excluirTransacao(id);
  }
}
