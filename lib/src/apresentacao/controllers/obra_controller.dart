import 'package:flutter/material.dart';
import '../../dominio/entidades/obra.dart';
import '../../dominio/entidades/etapa_servico.dart';
import '../../dominio/repositorios/repositorio_obra.dart';

class ObraController extends ChangeNotifier {
  final RepositorioObra _repositorio;
  ObraController(this._repositorio);

  bool _carregando = false;
  bool get carregando => _carregando;

  Stream<List<Obra>> get obras => _repositorio.listarObras();

  Future<void> salvar(Obra obra) async {
    _carregando = true;
    notifyListeners();
    try {
      await _repositorio.salvarObra(obra);
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> excluir(String id) async {
    await _repositorio.excluirObra(id);
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
      orcamentoId: obra.orcamentoId,
      clienteId: obra.clienteId,
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
      orcamentoId: obra.orcamentoId,
      clienteId: obra.clienteId,
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
