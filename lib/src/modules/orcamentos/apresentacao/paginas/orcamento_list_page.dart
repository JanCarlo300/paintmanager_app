import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../dominio/entidades/orcamento.dart';
import '../../../clientes/dominio/entidades/cliente.dart';
import '../controllers/orcamento_controller.dart';
import '../../../clientes/apresentacao/controllers/cliente_controller.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../apresentacao/widgets/drawer_comum.dart';
import '../../../../apresentacao/widgets/status_chip.dart';
import '../../../../apresentacao/widgets/tela_vazia.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';
import '../../../../core/tema/status_visual.dart';
import '../../../../core/filtros/filtro_lista.dart';
import '../../../../apresentacao/widgets/painel_filtro_lista.dart';
import '../../../../apresentacao/widgets/chips_filtro_status.dart';

/// Filtros disponíveis na tela de orçamentos
enum FiltroOrcamento { todos, pendentes, aprovados, recusados }

class OrcamentoListPage extends StatefulWidget {
  const OrcamentoListPage({super.key});

  @override
  State<OrcamentoListPage> createState() => _OrcamentoListPageState();
}

class _OrcamentoListPageState extends State<OrcamentoListPage> {
  String _termoBusca = '';
  FiltroOrcamento _filtroAtual = FiltroOrcamento.todos;
  late FiltroLista _filtro =
      FiltroLista(maisRecentes: context.read<OrcamentoController>().maisRecentes);

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  /// Aplica filtro de busca por texto
  List<Orcamento> _filtrarPorTexto(List<Orcamento> orcamentos) {
    if (_termoBusca.isEmpty) return orcamentos;
    final termo = _termoBusca.toLowerCase();
    return orcamentos.where((o) =>
      o.clienteNome.toLowerCase().contains(termo) ||
      o.descricao.toLowerCase().contains(termo)
    ).toList();
  }

  /// Aplica filtro por status
  List<Orcamento> _filtrarPorStatus(List<Orcamento> orcamentos) {
    switch (_filtroAtual) {
      case FiltroOrcamento.todos:
        return orcamentos;
      case FiltroOrcamento.pendentes:
        return orcamentos.where((o) => o.status == 'Pendente').toList();
      case FiltroOrcamento.aprovados:
        return orcamentos.where((o) => o.status == 'Aprovado').toList();
      case FiltroOrcamento.recusados:
        return orcamentos.where((o) => o.status == 'Recusado').toList();
    }
  }

  void _avisarErro(String mensagem) {
    final c = context.cores;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem, style: TextStyle(color: c.onError)), backgroundColor: c.error),
    );
  }

  // === FORMATAR MENSAGEM DO ORÇAMENTO ===
  String _formatarMensagem(Orcamento orc) {
    final itensTexto = orc.itensServico.map((item) {
      return "  • ${item.descricao} — ${item.metragem.toStringAsFixed(1)}m² × ${_formatoMoeda.format(item.valorUnitario)} = ${_formatoMoeda.format(item.subtotal)}";
    }).join('\n');

    return '''
📋 *ORÇAMENTO - PaintManager*
━━━━━━━━━━━━━━━━━━━━━━

👤 *Cliente:* ${orc.clienteNome}
📝 *Descrição:* ${orc.descricao}
📅 *Data:* ${_formatoData.format(orc.dataCriacao)}
⏳ *Validade:* ${_formatoData.format(orc.dataValidade)}

🔧 *Itens de Serviço:*
$itensTexto

💰 *Resumo de Valores:*
  • Serviços: ${_formatoMoeda.format(orc.itensServico.fold<double>(0, (s, i) => s + i.subtotal))}${orc.materiaisInclusos ? '\n  • Materiais: ${_formatoMoeda.format(orc.valorMateriais)}' : ''}
  • Mão de Obra: ${_formatoMoeda.format(orc.valorMaoDeObra)}${orc.desconto > 0 ? '\n  • Desconto: -${_formatoMoeda.format(orc.desconto)}' : ''}

💲 *VALOR TOTAL: ${_formatoMoeda.format(orc.valorTotal)}*

💳 *Pagamento:* ${orc.formaPagamento}

━━━━━━━━━━━━━━━━━━━━━━
Por favor, responda esta mensagem com:
✅ *APROVADO* — para aceitar o orçamento
❌ *REJEITADO* — para recusar o orçamento

_Orçamento gerado pelo PaintManager_
''';
  }

  // === ENVIAR POR WHATSAPP ===
  Future<void> _enviarWhatsApp(Orcamento orc, List<Cliente> clientes) async {
    final cliente = clientes.where((c) => c.nome == orc.clienteNome).firstOrNull;

    if (cliente == null || cliente.telefone.isEmpty) {
      if (mounted) _avisarErro("Cliente sem telefone cadastrado.");
      return;
    }

    final telefone = cliente.telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final telefoneCompleto = telefone.length <= 11 ? '55$telefone' : telefone;
    final mensagem = _formatarMensagem(orc);

    final url = Uri.parse('https://wa.me/$telefoneCompleto?text=${Uri.encodeComponent(mensagem)}');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) _avisarErro("Erro ao abrir WhatsApp: $e");
    }
  }

  // === ENVIAR POR E-MAIL ===
  Future<void> _enviarEmail(Orcamento orc, List<Cliente> clientes) async {
    final cliente = clientes.where((c) => c.nome == orc.clienteNome).firstOrNull;

    if (cliente == null || cliente.email.isEmpty) {
      if (mounted) _avisarErro("Cliente sem e-mail cadastrado.");
      return;
    }

    final mensagemEmail = _formatarMensagem(orc).replaceAll('*', '');
    final assunto = 'Orçamento - ${orc.descricao} | PaintManager';

    final url = Uri(
      scheme: 'mailto',
      path: cliente.email,
      query: 'subject=${Uri.encodeComponent(assunto)}&body=${Uri.encodeComponent(mensagemEmail)}',
    );

    try {
      await launchUrl(url);
    } catch (e) {
      if (mounted) _avisarErro("Erro ao abrir e-mail: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<OrcamentoController>().carregarOrcamentos();
      context.read<ClienteController>().carregarClientes();
    });
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Symbols.menu_rounded),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: const Text("Orçamentos"),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrcamentoController>();
    final clienteController = context.watch<ClienteController>();
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    if (controller.carregando) {
      return Scaffold(
        drawer: const DrawerComum(),
        appBar: _appBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final todos = controller.orcamentos;
    final filtrados = _filtrarPorTexto(_filtrarPorStatus(todos))
        .where((o) =>
            _filtro.criadoNoPeriodo(o.dataCriacao) &&
            // Prazo de validade só importa enquanto o cliente não respondeu.
            _filtro.dentroDoPrazo(o.dataValidade, emAberto: o.status == 'Pendente'))
        .toList();
    final clientes = clienteController.clientes;

    return Scaffold(
      drawer: const DrawerComum(),
      appBar: _appBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Espaco.margemTela),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Text("Gestão de Orçamentos", style: texto.headlineMedium),
            const SizedBox(height: Espaco.x1),
            Text(
              "Crie e gerencie orçamentos para seus clientes.",
              style: texto.bodyMedium?.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: Espaco.x4),

            // --- BOTÃO NOVO ORÇAMENTO ---
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/orcamento-formulario'),
                icon: const Icon(Symbols.add_rounded, size: TamanhoIcone.pequeno),
                label: const Text("Novo Orçamento"),
              ),
            ),
            const SizedBox(height: Espaco.x5),

            // --- FILTRO POR STATUS ---
            _buildFiltroChips(todos),
            const SizedBox(height: Espaco.x4),

            // --- BARRA DE BUSCA ---
            _buildBarraBusca(),
            const SizedBox(height: Espaco.x2),

            // --- CONTADOR ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Espaco.x2),
              child: Text(
                "${filtrados.length} orçamento(s) encontrado(s)",
                style: texto.bodyMedium?.copyWith(color: c.inkMuted),
              ),
            ),

            // --- LISTA DE CARDS ---
            if (filtrados.isEmpty)
              _buildVazio()
            else
              ...filtrados.map((orc) => _buildOrcamentoCard(orc, controller, clientes)),
          ],
        ),
      ),
    );
  }

  // === FILTRO CHIPS ===
  Widget _buildFiltroChips(List<Orcamento> todos) {
    final c = context.cores;
    int qtd(String status) => todos.where((o) => o.status == status).length;
    // Mesma cor de cada status em todo o app (core/tema/status_visual.dart).
    Color cor(String status) => visualDoStatus(status, c).cor;

    return ChipsFiltroStatus<FiltroOrcamento>(
      selecionado: _filtroAtual,
      aoSelecionar: (f) => setState(() => _filtroAtual = f),
      opcoes: [
        OpcaoStatus("Todos", FiltroOrcamento.todos, todos.length, c.primary),
        OpcaoStatus("Pendentes", FiltroOrcamento.pendentes, qtd('Pendente'), cor('Pendente')),
        OpcaoStatus("Aprovados", FiltroOrcamento.aprovados, qtd('Aprovado'), cor('Aprovado')),
        OpcaoStatus("Recusados", FiltroOrcamento.recusados, qtd('Recusado'), cor('Recusado')),
      ],
    );
  }

  void _aplicarFiltro(FiltroLista novo) {
    setState(() => _filtro = novo);
    context.read<OrcamentoController>().ordenar(maisRecentes: novo.maisRecentes);
  }

  // === BARRA DE BUSCA + BOTÃO DE FILTRO ===
  Widget _buildBarraBusca() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => _termoBusca = v),
            decoration: const InputDecoration(
              hintText: "Buscar por cliente ou descrição...",
              prefixIcon: Icon(Symbols.search_rounded, size: TamanhoIcone.pequeno),
            ),
          ),
        ),
        const SizedBox(width: Espaco.x2),
        BotaoFiltroLista(
          filtro: _filtro,
          aoAplicar: _aplicarFiltro,
          rotuloAtrasados: "Pendentes vencidos",
          rotuloProximos7Dias: "Vencem em 7 dias",
        ),
      ],
    );
  }

  /// Ícone do status num círculo com o fundo suave do status.
  Widget _avatarStatus(String status, {required double raio}) {
    final visual = visualDoStatus(status, context.cores);
    return CircleAvatar(
      radius: raio,
      backgroundColor: visual.fundo,
      child: Icon(visual.icone, color: visual.cor, size: TamanhoIcone.pequeno, fill: 1),
    );
  }

  // === CARD DO ORÇAMENTO ===
  Widget _buildOrcamentoCard(Orcamento orc, OrcamentoController controller, List<Cliente> clientes) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.x3),
      child: CardApp(
        aoTocar: () => _mostrarOpcoes(context, orc, controller, clientes),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cliente + Status
            Row(
              children: [
                _avatarStatus(orc.status, raio: 20),
                const SizedBox(width: Espaco.x3),
                // Cliente e descrição
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orc.clienteNome,
                        style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        orc.descricao,
                        style: texto.bodyMedium?.copyWith(color: c.inkMuted),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Espaco.x2),
                StatusChip(orc.status),
              ],
            ),
            const SizedBox(height: Espaco.x3),
            const Divider(height: 1),
            const SizedBox(height: Espaco.x3),
            // Valor + Datas
            Row(
              children: [
                Expanded(
                  child: _infoItem(Symbols.payments_rounded, _formatoMoeda.format(orc.valorTotal), destaque: true),
                ),
                Expanded(
                  child: _infoItem(Symbols.calendar_today_rounded, _formatoData.format(orc.dataCriacao)),
                ),
              ],
            ),
            const SizedBox(height: Espaco.x2),
            Row(
              children: [
                Expanded(
                  child: _infoItem(Symbols.credit_card_rounded, orc.formaPagamento),
                ),
                Expanded(
                  child: _infoItem(
                    Symbols.event_rounded,
                    "Val: ${_formatoData.format(orc.dataValidade)}",
                    color: orc.dataValidade.isBefore(DateTime.now()) ? c.error : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text, {bool destaque = false, Color? color}) {
    final c = context.cores;
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? c.inkMuted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color ?? (destaque ? c.ink : c.inkMuted),
                  fontWeight: destaque ? FontWeight.w700 : null,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Ícone de ação num quadrado arredondado com fundo suave.
  Widget _iconeAcao(IconData icone, Color cor, Color fundo, {double tamanho = TamanhoIcone.pequeno}) {
    return Container(
      padding: const EdgeInsets.all(Espaco.x2),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(Raio.campo)),
      child: Icon(icone, color: cor, size: tamanho),
    );
  }

  // === BOTTOM SHEET COM OPÇÕES ===
  void _mostrarOpcoes(BuildContext context, Orcamento orc, OrcamentoController controller, List<Cliente> clientes) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final legenda = texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Espaco.x2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: Espaco.x3),
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
              // Info do orçamento
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Espaco.x5, vertical: Espaco.x2),
                child: Row(
                  children: [
                    _avatarStatus(orc.status, raio: 18),
                    const SizedBox(width: Espaco.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(orc.clienteNome, style: texto.titleMedium, overflow: TextOverflow.ellipsis),
                          Text(orc.descricao, style: legenda, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Text(
                      _formatoMoeda.format(orc.valorTotal),
                      style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Enviar
              ListTile(
                leading: _iconeAcao(Symbols.send_rounded, c.success, c.successSoft),
                title: const Text("Enviar para o Cliente"),
                subtitle: Text("WhatsApp ou E-mail", style: legenda),
                onTap: () {
                  Navigator.pop(ctx);
                  _mostrarOpcoesEnvio(orc, clientes);
                },
              ),
              // Editar
              ListTile(
                leading: _iconeAcao(Symbols.edit_rounded, c.info, c.infoSoft),
                title: const Text("Editar"),
                subtitle: Text("Alterar dados do orçamento", style: legenda),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/orcamento-formulario', arguments: orc);
                },
              ),
              // Excluir
              ListTile(
                leading: _iconeAcao(Symbols.delete_rounded, c.error, c.errorSoft),
                title: Text("Excluir", style: TextStyle(color: c.error)),
                subtitle: Text("Remover este orçamento", style: legenda),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmarExclusao(context, orc, controller);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === DIALOG DE ENVIO ===
  void _mostrarOpcoesEnvio(Orcamento orc, List<Cliente> clientes) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Espaco.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Enviar Orçamento", style: texto.titleMedium),
              const SizedBox(height: Espaco.x1),
              Text("Enviar para ${orc.clienteNome}", style: texto.bodyMedium?.copyWith(color: c.inkMuted)),
              const SizedBox(height: Espaco.x5),

              // WhatsApp
              ListTile(
                leading: _iconeAcao(Symbols.chat_rounded, c.success, c.successSoft, tamanho: TamanhoIcone.medio),
                title: Text("Enviar por WhatsApp", style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: const Text("Abre o WhatsApp com a mensagem pronta"),
                onTap: () {
                  Navigator.pop(context);
                  _enviarWhatsApp(orc, clientes);
                },
              ),
              const SizedBox(height: Espaco.x2),

              // E-mail
              ListTile(
                leading: _iconeAcao(Symbols.mail_rounded, c.info, c.infoSoft, tamanho: TamanhoIcone.medio),
                title: Text("Enviar por E-mail", style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: const Text("Abre o cliente de e-mail com o orçamento"),
                onTap: () {
                  Navigator.pop(context);
                  _enviarEmail(orc, clientes);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === CONFIRMAÇÃO DE EXCLUSÃO ===
  void _confirmarExclusao(BuildContext context, Orcamento orcamento, OrcamentoController controller) {
    final c = context.cores;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Orçamento?"),
        content: Text("Tem certeza que deseja remover o orçamento \"${orcamento.descricao}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: c.inkMuted),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () {
              controller.excluir(orcamento.id!);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Orçamento excluído com sucesso!")),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: c.error, foregroundColor: c.onError),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
  }

  // === VAZIO ===
  Widget _buildVazio() {
    if (_filtro.quantidadeAtivos > 0 || _termoBusca.isNotEmpty) {
      return const TelaVazia(
        ilustracao: IlustracaoVazia.busca,
        titulo: "Nenhum orçamento com esses filtros",
        texto: "Mude a busca ou os filtros para ver outros orçamentos.",
      );
    }
    final (titulo, texto) = switch (_filtroAtual) {
      FiltroOrcamento.todos => ("Nenhum orçamento cadastrado", "Crie o primeiro pelo botão Novo Orçamento."),
      FiltroOrcamento.pendentes => ("Nenhum orçamento pendente", "Orçamentos aguardando resposta aparecem aqui."),
      FiltroOrcamento.aprovados => ("Nenhum orçamento aprovado", "Orçamentos aceitos pelo cliente aparecem aqui."),
      FiltroOrcamento.recusados => ("Nenhum orçamento recusado", "Orçamentos recusados pelo cliente aparecem aqui."),
    };
    return TelaVazia(ilustracao: IlustracaoVazia.orcamentos, titulo: titulo, texto: texto);
  }
}
