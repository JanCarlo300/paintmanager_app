import 'package:flutter/material.dart';
import '../../dominio/entidades/relatorio_geral.dart';
import '../../dominio/repositorios/repositorio_relatorio.dart';

class RelatorioController extends ChangeNotifier {
  final RepositorioRelatorio _repositorio;

  bool _carregando = false;
  bool get carregando => _carregando;

  String? _erro;
  String? get erro => _erro;

  RelatorioGeral? _relatorio;
  RelatorioGeral? get relatorio => _relatorio;

  // Filtros de período
  String _filtroSelecionado = 'Este Mês';
  String get filtroSelecionado => _filtroSelecionado;

  late DateTime _inicio;
  late DateTime _fim;
  DateTime get inicio => _inicio;
  DateTime get fim => _fim;

  RelatorioController(this._repositorio) {
    _ajustarPeriodo('Este Mês');
  }

  void _ajustarPeriodo(String filtro) {
    final agora = DateTime.now();
    switch (filtro) {
      case 'Últimos 7 dias':
        _inicio = agora.subtract(const Duration(days: 7));
        _fim = agora;
        break;
      case 'Este Mês':
        _inicio = DateTime(agora.year, agora.month, 1);
        _fim = DateTime(agora.year, agora.month + 1, 0, 23, 59, 59);
        break;
      case 'Últimos 30 dias':
        _inicio = agora.subtract(const Duration(days: 30));
        _fim = agora;
        break;
      case 'Últimos 90 dias':
        _inicio = agora.subtract(const Duration(days: 90));
        _fim = agora;
        break;
      case 'Este Ano':
        _inicio = DateTime(agora.year, 1, 1);
        _fim = DateTime(agora.year, 12, 31, 23, 59, 59);
        break;
      default:
        break;
    }
    _filtroSelecionado = filtro;
  }

  Future<void> carregarRelatorio() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      _relatorio = await _repositorio.gerarRelatorio(_inicio, _fim);
    } catch (e) {
      _erro = 'Erro ao carregar relatório: $e';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  void alterarFiltro(String filtro) {
    _ajustarPeriodo(filtro);
    notifyListeners();
    carregarRelatorio();
  }

  void alterarPeriodoPersonalizado(DateTime inicio, DateTime fim) {
    _filtroSelecionado = 'Personalizado';
    _inicio = inicio;
    _fim = fim;
    notifyListeners();
    carregarRelatorio();
  }
}
