import 'package:flutter/material.dart';
import '../../dominio/entidades/obra.dart';
import '../../dominio/entidades/etapa_servico.dart';
import '../../dominio/repositorios/repositorio_obra.dart';

/// Controller do módulo Obras — Supabase.
/// Segue o padrão Future + notifyListeners (consistente com ClienteController).
/// Preserva toda a lógica de negócio do controller anterior (alternarEtapa, atualizarStatus).
class ObraController extends ChangeNotifier {
  final RepositorioObra _repositorio;
  ObraController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  List<Obra> _obras = [];
  List<Obra> get obras => _obras;

  /// Carrega a lista de obras do Supabase
  Future<void> carregarObras() async {
    _carregando = true;
    notifyListeners();
    try {
      _obras = await _repositorio.listarObras();
    } catch (e) {
      _obras = [];
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Salva (insere ou atualiza) uma obra e recarrega a lista
  Future<void> salvar(Obra obra) async {
    _carregando = true;
    notifyListeners();
    try {
      await _repositorio.salvarObra(obra);
      await carregarObras(); // Recarrega após salvar
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Exclui permanentemente uma obra
  Future<void> excluir(int id) async {
    await _repositorio.excluirObra(id);
    await carregarObras();
  }

  /// Alterna o status de uma etapa e recalcula o progresso
  Future<void> alternarEtapa(Obra obra, int indiceEtapa) async {
    final novasEtapas = List<EtapaServico>.from(obra.etapasServico);
    novasEtapas[indiceEtapa] = novasEtapas[indiceEtapa].copiarCom(
      concluida: !novasEtapas[indiceEtapa].concluida,
    );

    // Recalcular progresso
    final concluidas = novasEtapas.where((e) => e.concluida).length;
    final novoProgresso = (concluidas / novasEtapas.length) * 100;

    final obraAtualizada = Obra(
      id: obra.id,
      idOrcamento: obra.idOrcamento,
      idCliente: obra.idCliente,
      clienteNome: obra.clienteNome,
      tituloDaObra: obra.tituloDaObra,
      endereco: obra.endereco,
      dataInicio: obra.dataInicio,
      dataPrevisaoTermino: obra.dataPrevisaoTermino,
      dataConclusao: obra.dataConclusao,
      status: obra.status,
      progresso: novoProgresso,
      etapasServico: novasEtapas,
      anotacoes: obra.anotacoes,
      materiaisFaltantes: obra.materiaisFaltantes,
    );

    await salvar(obraAtualizada);
  }

  /// Atualiza o status da obra (com validação de etapas para conclusão)
  Future<String?> atualizarStatus(Obra obra, String novoStatus) async {
    // Regra de negócio: não permitir concluir se houver etapas pendentes
    if (novoStatus == 'Concluída' && !obra.todasEtapasConcluidas) {
      return 'Não é possível concluir a obra. Existem etapas pendentes.';
    }

    final obraAtualizada = Obra(
      id: obra.id,
      idOrcamento: obra.idOrcamento,
      idCliente: obra.idCliente,
      clienteNome: obra.clienteNome,
      tituloDaObra: obra.tituloDaObra,
      endereco: obra.endereco,
      dataInicio: obra.dataInicio,
      dataPrevisaoTermino: obra.dataPrevisaoTermino,
      dataConclusao: novoStatus == 'Concluída' ? DateTime.now() : obra.dataConclusao,
      status: novoStatus,
      progresso: obra.progresso,
      etapasServico: obra.etapasServico,
      anotacoes: obra.anotacoes,
      materiaisFaltantes: obra.materiaisFaltantes,
    );

    await salvar(obraAtualizada);
    return null; // Sem erro
  }
}
