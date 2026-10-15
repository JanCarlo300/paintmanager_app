import 'package:flutter/material.dart';
import '../../dominio/entidades/obra.dart';
import '../../dominio/entidades/etapa_servico.dart';
import '../../dominio/entidades/mensagem_obra.dart';
import '../../dominio/repositorios/repositorio_obra.dart';
import '../../../auth/dominio/entidades/usuario.dart';

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

  // Guardada aqui para que recarregar depois de salvar mantenha a ordem escolhida.
  bool _maisRecentes = true;
  bool get maisRecentes => _maisRecentes;

  Future<void> ordenar({required bool maisRecentes}) async {
    if (_maisRecentes == maisRecentes) return;
    _maisRecentes = maisRecentes;
    await carregarObras();
  }

  /// Carrega a lista de obras do Supabase
  Future<void> carregarObras() async {
    _carregando = true;
    notifyListeners();
    try {
      _obras = await _repositorio.listarObras(maisRecentes: _maisRecentes);
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
    // Etapa 5: obra concluída é definitiva — o checklist não muda mais.
    if (obra.status == 'Concluída') return;

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
      materiaisFaltantes: obra.materiaisFaltantes,
      latitude: obra.latitude,
      longitude: obra.longitude,
    );

    await salvar(obraAtualizada);
  }

  /// Atualiza o status da obra. Ao concluir com etapas pendentes, só segue se
  /// [marcarEtapasPendentes] (o usuário confirmou marcar todas como concluídas).
  Future<String?> atualizarStatus(Obra obra, String novoStatus, {bool marcarEtapasPendentes = false}) async {
    // Etapa 5: concluída é definitiva — ninguém reabre.
    if (obra.status == 'Concluída') {
      return 'Obra concluída: o status não pode mais ser alterado.';
    }

    final concluindo = novoStatus == 'Concluída';
    if (concluindo && obra.etapasServico.any((e) => !e.concluida) && !marcarEtapasPendentes) {
      return 'Não é possível concluir a obra. Existem etapas pendentes.';
    }

    // Item 1.2: orçamento Pendente ou Recusado não libera o início da obra.
    if (novoStatus != 'Não Iniciada' &&
        obra.id != null &&
        !await _repositorio.obraTemOrcamentoAprovado(obra.id!)) {
      return 'A obra só pode ser iniciada depois que um orçamento dela for Aprovado.';
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
      dataConclusao: concluindo ? DateTime.now() : obra.dataConclusao,
      status: novoStatus,
      progresso: concluindo ? 100 : obra.progresso,
      etapasServico: concluindo
          ? obra.etapasServico.map((e) => e.copiarCom(concluida: true)).toList()
          : obra.etapasServico,
      materiaisFaltantes: obra.materiaisFaltantes,
      latitude: obra.latitude,
      longitude: obra.longitude,
    );

    await salvar(obraAtualizada);
    return null; // Sem erro
  }

  // === RF010 - Alocar Equipe à Obra ===

  List<Usuario> _equipeObraAtual = [];
  List<Usuario> get equipeObraAtual => _equipeObraAtual;

  bool _carregandoEquipe = false;
  bool get carregandoEquipe => _carregandoEquipe;

  Future<void> carregarEquipe(int obraId) async {
    _carregandoEquipe = true;
    notifyListeners();
    try {
      _equipeObraAtual = await _repositorio.listarFuncionariosAlocados(obraId);
    } catch (e) {
      _equipeObraAtual = [];
    } finally {
      _carregandoEquipe = false;
      notifyListeners();
    }
  }

  Future<void> alocarFuncionario(int obraId, int usuarioId) async {
    await _repositorio.alocarFuncionario(obraId, usuarioId);
    await carregarEquipe(obraId);
  }

  Future<void> desalocarFuncionario(int obraId, int usuarioId) async {
    await _repositorio.desalocarFuncionario(obraId, usuarioId);
    await carregarEquipe(obraId);
  }

  // === Item 2.1 — obras alocadas ao usuário logado (visão do Funcionário) ===

  List<int> _obraIdsAlocados = [];
  List<int> get obraIdsAlocados => _obraIdsAlocados;

  bool _carregandoAlocacoes = false;
  bool get carregandoAlocacoes => _carregandoAlocacoes;

  Future<void> carregarObraIdsAlocados(int usuarioId) async {
    _carregandoAlocacoes = true;
    notifyListeners();
    try {
      _obraIdsAlocados = await _repositorio.listarObraIdsAlocados(usuarioId);
    } catch (e) {
      _obraIdsAlocados = [];
    } finally {
      _carregandoAlocacoes = false;
      notifyListeners();
    }
  }

  // === Etapa 2 — buscas no banco (não mexem nas listas da tela) ===

  Future<List<Obra>> buscarObras(String termo) => _repositorio.buscarObras(termo);

  Future<List<Usuario>> buscarFuncionariosDisponiveis(int obraId, String termo) =>
      _repositorio.buscarFuncionariosDisponiveis(obraId, termo);

  // === Item 2.3 — Chat da Obra ===

  Stream<List<MensagemObra>> escutarMensagens(int obraId) =>
      _repositorio.escutarMensagens(obraId);

  Future<void> enviarMensagem({required int obraId, required int usuarioId, required String texto}) =>
      _repositorio.enviarMensagem(obraId: obraId, usuarioId: usuarioId, texto: texto);
}
