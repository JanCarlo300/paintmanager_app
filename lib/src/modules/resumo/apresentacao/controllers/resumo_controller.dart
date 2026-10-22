import 'package:flutter/material.dart';
import '../../../obras/dominio/entidades/obra.dart';
import '../../dominio/entidades/alerta.dart';
import '../../dominio/entidades/resumo_geral.dart';
import '../../dominio/repositorios/repositorio_resumo.dart';

/// Controller do Resumo Geral: números do mês, obras recentes e o sino de
/// alertas (RF013). Carrega quando a tela abre — não no início do app, que
/// pode ser antes do login.
class ResumoController extends ChangeNotifier {
  final RepositorioResumo _repositorio;
  final DateTime Function() _agora;

  ResumoController(this._repositorio, {DateTime Function()? agora}) : _agora = agora ?? DateTime.now;

  // --- Resumo -----------------------------------------------------------------
  bool _carregando = false;
  bool get carregando => _carregando;

  ResumoGeral _resumo = ResumoGeral.vazio;
  ResumoGeral get resumo => _resumo;

  String? _erro;
  String? get erro => _erro;

  int get obrasAtivas => _resumo.obrasAtivas;
  int get orcamentosPendentes => _resumo.orcamentosPendentes;
  double get receitaMes => _resumo.receitaMes;
  double get despesaMes => _resumo.despesaMes;
  List<Obra> get obrasRecentes => _resumo.obrasRecentes;

  // --- Alertas ----------------------------------------------------------------
  bool _carregandoAlertas = false;
  bool get carregandoAlertas => _carregandoAlertas;

  List<Alerta> _alertas = [];
  List<Alerta> get alertas => _alertas;

  Future<void> carregarTudo() => Future.wait([carregarResumo(), carregarAlertas()]);

  Future<void> carregarResumo() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      _resumo = await _repositorio.carregarResumo(_agora());
    } catch (e) {
      _erro = '$e';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Uma consulta que falha não apaga os alertas da outra.
  Future<void> carregarAlertas() async {
    _carregandoAlertas = true;
    notifyListeners();

    List<OrcamentoPendente> orcamentos = const [];
    List<ObraEmAberto> obras = const [];
    try {
      orcamentos = await _repositorio.listarOrcamentosPendentes();
    } catch (_) {}
    try {
      obras = await _repositorio.listarObrasEmAberto();
    } catch (_) {}

    _alertas = calcularAlertas(orcamentos: orcamentos, obras: obras, hoje: _agora());
    _carregandoAlertas = false;
    notifyListeners();
  }
}
