import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../dominio/entidades/relatorio_geral.dart';
import '../../dominio/repositorios/repositorio_relatorio.dart';
import '../../dominio/pdf_relatorios.dart';
import '../../../obras/dominio/entidades/obra.dart';

/// Controller do módulo Relatórios — Supabase.
/// Segue o padrão Future + notifyListeners.
/// Preserva toda a lógica de filtros de período do controller legado.
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

  // === Etapa 8.1 — PDFs (RF012), no período selecionado na tela ===

  Future<Uint8List> gerarPdfFinanceiro({Obra? obra}) async {
    final todos = await _repositorio.listarLancamentos(_inicio, _fim, obraId: obra?.id);
    final status = await _repositorio.statusDasObras(todos.map((t) => t.idObra).whereType<int>());
    final orcamentos = await _repositorio.listarOrcamentosAprovados(_inicio, _fim, obraId: obra?.id);
    return gerarPdfRelatorioFinanceiro(
      inicio: _inicio,
      fim: _fim,
      obraTitulo: obra?.tituloDaObra,
      lancamentos: filtrarLancamentosValidos(todos, status),
      orcamentosAprovados: orcamentos,
    );
  }

  Future<Uint8List> gerarPdfProgresso({Obra? obra}) async {
    final obras = await _repositorio.listarObrasParaProgresso(_inicio, _fim, obraId: obra?.id);
    return gerarPdfRelatorioProgresso(
      inicio: _inicio,
      fim: _fim,
      obraTitulo: obra?.tituloDaObra,
      obras: obras,
    );
  }

  void alterarPeriodoPersonalizado(DateTime inicio, DateTime fim) {
    _filtroSelecionado = 'Personalizado';
    _inicio = inicio;
    _fim = fim;
    notifyListeners();
    carregarRelatorio();
  }
}
