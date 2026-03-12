import 'package:flutter/material.dart';
import '../../dominio/entidades/orcamento.dart';
import '../../dominio/repositorios/repositorio_orcamento.dart';

class OrcamentoController extends ChangeNotifier {
  final RepositorioOrcamento _repositorio;
  OrcamentoController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  Stream<List<Orcamento>> get orcamentos => _repositorio.listarOrcamentos();

  Future<void> salvar(Orcamento orcamento) async {
    _carregando = true;
    notifyListeners();
    try {
      await _repositorio.salvarOrcamento(orcamento);
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> excluir(String id) async {
    await _repositorio.excluirOrcamento(id);
  }
}
