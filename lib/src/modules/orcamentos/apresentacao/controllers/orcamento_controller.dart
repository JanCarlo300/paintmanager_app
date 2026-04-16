import 'package:flutter/material.dart';
import '../../dominio/entidades/orcamento.dart';
import '../../dominio/repositorios/repositorio_orcamento.dart';

/// Controller do módulo Orçamentos — Supabase.
/// Segue o padrão Future + notifyListeners (consistente com ObraController e ClienteController).
class OrcamentoController extends ChangeNotifier {
  final RepositorioOrcamento _repositorio;
  OrcamentoController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  List<Orcamento> _orcamentos = [];
  List<Orcamento> get orcamentos => _orcamentos;

  /// Carrega a lista de orçamentos do Supabase
  Future<void> carregarOrcamentos() async {
    _carregando = true;
    notifyListeners();
    try {
      _orcamentos = await _repositorio.listarOrcamentos();
    } catch (e) {
      _orcamentos = [];
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Salva (insere ou atualiza) um orçamento e recarrega a lista
  Future<void> salvar(Orcamento orcamento) async {
    _carregando = true;
    notifyListeners();
    try {
      await _repositorio.salvarOrcamento(orcamento);
      await carregarOrcamentos(); // Recarrega após salvar
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Exclui permanentemente um orçamento
  Future<void> excluir(int id) async {
    await _repositorio.excluirOrcamento(id);
    await carregarOrcamentos();
  }

  /// Atualiza o status de um orçamento
  Future<void> atualizarStatus(Orcamento orcamento, String novoStatus) async {
    final atualizado = Orcamento(
      id: orcamento.id,
      idObra: orcamento.idObra,
      clienteNome: orcamento.clienteNome,
      descricao: orcamento.descricao,
      dataCriacao: orcamento.dataCriacao,
      dataValidade: orcamento.dataValidade,
      status: novoStatus,
      itensServico: orcamento.itensServico,
      materiaisInclusos: orcamento.materiaisInclusos,
      valorMateriais: orcamento.valorMateriais,
      valorMaoDeObra: orcamento.valorMaoDeObra,
      desconto: orcamento.desconto,
      valorTotal: orcamento.valorTotal,
      formaPagamento: orcamento.formaPagamento,
    );
    await salvar(atualizado);
  }
}
