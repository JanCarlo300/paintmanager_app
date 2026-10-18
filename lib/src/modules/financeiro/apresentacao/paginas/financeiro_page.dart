import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/transacao.dart';
import '../controllers/financeiro_controller.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../apresentacao/widgets/card_destaque.dart';
import '../../../../apresentacao/widgets/drawer_comum.dart';
import '../../../../apresentacao/widgets/tela_vazia.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';
import '../../../auth/apresentacao/controllers/auth_controller.dart';

class FinanceiroPage extends StatefulWidget {
  const FinanceiroPage({super.key});

  @override
  State<FinanceiroPage> createState() => _FinanceiroPageState();
}

class _FinanceiroPageState extends State<FinanceiroPage> {
  static const _meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

  @override
  void initState() {
    super.initState();
    // Carrega as transações do Supabase de forma segura pós-build
    final controller = context.read<FinanceiroController>();
    Future.microtask(() => controller.carregarTransacoes());
  }

  /// Cor do texto e do fundo de cada status de lançamento.
  (Color, Color) _coresStatus(String status) {
    final c = context.cores;
    switch (status) {
      case 'Efetivado': return (c.success, c.successSoft);
      case 'Pendente': return (c.warning, c.warningSoft);
      case 'Atrasado': return (c.error, c.errorSoft);
      default: return (c.inkMuted, c.surfaceSunken);
    }
  }

  IconData _iconeTipo(String tipo) => tipo == 'Receita' ? Symbols.arrow_upward_rounded : Symbols.arrow_downward_rounded;
  Color _corTipo(String tipo) => tipo == 'Receita' ? context.cores.success : context.cores.error;
  Color _fundoTipo(String tipo) => tipo == 'Receita' ? context.cores.successSoft : context.cores.errorSoft;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatoData = DateFormat('dd/MM/yyyy');
    // Regra de negócio: só administrador exclui registros financeiros.
    final podeExcluir = context.watch<AuthController>().usuarioLogado?.funcao == 'Administrador';

    return Scaffold(
      drawer: const DrawerComum(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(icon: const Icon(Symbols.menu_rounded), onPressed: () => Scaffold.of(ctx).openDrawer()),
        ),
        title: const Text("Financeiro"),
      ),
      body: controller.carregando
          ? const Center(child: CircularProgressIndicator())
          : _buildConteudo(controller, formatoMoeda, formatoData, podeExcluir),
    );
  }

  Widget _buildConteudo(FinanceiroController controller, NumberFormat formatoMoeda, DateFormat formatoData, bool podeExcluir) {
    final todas = controller.transacoes;
    final doMes = controller.filtrarPorMes(todas);
    final receitas = controller.calcularReceitas(doMes);
    final despesas = controller.calcularDespesas(doMes);
    final saldo = controller.calcularSaldo(doMes);
    final pendentes = controller.calcularPendentes(doMes);
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Espaco.margemTela),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Text("Gestão Financeira", style: texto.headlineMedium),
          const SizedBox(height: Espaco.x1),
          Text("Controle receitas, despesas e fluxo de caixa.", style: texto.bodyMedium?.copyWith(color: c.inkMuted)),
          const SizedBox(height: Espaco.x4),

          // No topo (como "Nova Obra"/"Novo Orçamento"): o botão flutuante
          // ficava por cima do lápis e da lixeira da última transação.
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _mostrarOpcoesNovaTransacao(context),
              icon: const Icon(Symbols.add_rounded, size: TamanhoIcone.pequeno),
              label: const Text("Nova Transação"),
            ),
          ),
          const SizedBox(height: Espaco.x6),

          // --- SELETOR DE MÊS ---
          _buildSeletorMes(controller),
          const SizedBox(height: Espaco.x6),

          // --- CARDS DE RESUMO ---
          _buildCardsResumo(formatoMoeda, receitas, despesas, saldo, pendentes),
          const SizedBox(height: Espaco.x6),

          // --- LISTA DE TRANSAÇÕES ---
          _buildListaTransacoes(context, doMes, formatoMoeda, formatoData, controller, podeExcluir),
        ],
      ),
    );
  }

  // --- SELETOR DE MÊS ---
  Widget _buildSeletorMes(FinanceiroController controller) {
    return CardApp(
      padding: const EdgeInsets.symmetric(horizontal: Espaco.x4, vertical: Espaco.x2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: "Mês anterior",
            icon: const Icon(Symbols.chevron_left_rounded),
            onPressed: controller.mesAnterior,
          ),
          const SizedBox(width: Espaco.x2),
          Text(
            "${_meses[controller.mesSelecionado - 1]} ${controller.anoSelecionado}",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(width: Espaco.x2),
          IconButton(
            tooltip: "Próximo mês",
            icon: const Icon(Symbols.chevron_right_rounded),
            onPressed: controller.mesProximo,
          ),
        ],
      ),
    );
  }

  // --- CARDS DE RESUMO ---
  // O saldo é o valor principal da tela: vai no card destaque (um só por tela).
  Widget _buildCardsResumo(NumberFormat fmt, double receitas, double despesas, double saldo, double pendentes) {
    final c = context.cores;
    return Column(
      children: [
        CardDestaque(
          rotulo: "Saldo do Mês",
          valor: "${saldo < 0 ? '− ' : ''}${fmt.format(saldo.abs())}",
          legenda: "Pendente: ${fmt.format(pendentes)}",
        ),
        const SizedBox(height: Espaco.x3),
        Row(
          children: [
            Expanded(child: _buildCard("Receitas", fmt.format(receitas), c.success, Symbols.trending_up_rounded)),
            const SizedBox(width: Espaco.x3),
            Expanded(child: _buildCard("Despesas", fmt.format(despesas), c.error, Symbols.trending_down_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(String titulo, String valor, Color cor, IconData icone) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return CardApp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(titulo, style: texto.bodyMedium?.copyWith(color: c.inkMuted))),
              Icon(icone, color: cor, size: TamanhoIcone.pequeno),
            ],
          ),
          const SizedBox(height: Espaco.x2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: texto.titleMedium?.copyWith(color: cor, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // --- LISTA DE TRANSAÇÕES ---
  Widget _buildListaTransacoes(BuildContext context, List<Transacao> transacoes, NumberFormat fmt, DateFormat fmtData, FinanceiroController controller, bool podeExcluir) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final legenda = texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0);

    Widget selo(String rotulo, Color cor, Color fundo) => Container(
          padding: const EdgeInsets.symmetric(horizontal: Espaco.x2, vertical: 2),
          decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(Raio.pilula)),
          child: Text(rotulo, style: texto.labelSmall?.copyWith(color: cor, letterSpacing: 0)),
        );

    return SizedBox(
      width: double.infinity,
      child: CardApp(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Espaco.x5, Espaco.x5, Espaco.x5, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text("Transações do Mês", style: texto.titleMedium)),
                  Text("${transacoes.length} registro(s)", style: texto.bodyMedium?.copyWith(color: c.inkMuted)),
                ],
              ),
            ),
            const SizedBox(height: Espaco.x3),
            const Divider(height: 1),

            if (transacoes.isEmpty)
              const TelaVazia(
                ilustracao: IlustracaoVazia.busca,
                titulo: "Nenhuma transação neste mês",
                texto: "Troque o mês acima ou registre uma nova transação.",
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transacoes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final t = transacoes[i];
                  final (corStatus, fundoStatus) = _coresStatus(t.status);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: Espaco.x5, vertical: Espaco.x2),
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _fundoTipo(t.tipo),
                        borderRadius: BorderRadius.circular(Raio.botao),
                      ),
                      child: Icon(_iconeTipo(t.tipo), color: _corTipo(t.tipo), size: TamanhoIcone.pequeno),
                    ),
                    title: Text(t.descricao, style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: Espaco.x1),
                        // Wrap: se categoria + status não couberem (valor grande à
                        // direita, fonte grande), o status desce para a linha de baixo.
                        Wrap(
                          spacing: 6,
                          runSpacing: Espaco.x1,
                          children: [
                            selo(t.categoria, c.inkMuted, c.surfaceSunken),
                            selo(t.status, corStatus, fundoStatus),
                          ],
                        ),
                        const SizedBox(height: Espaco.x1),
                        Text("${fmtData.format(t.dataTransacao)} • ${t.formaPagamento}", style: legenda),
                        if (t.obraTitulo != null && t.obraTitulo!.isNotEmpty)
                          Row(
                            children: [
                              Icon(Symbols.construction_rounded, size: 14, color: c.inkMuted),
                              const SizedBox(width: Espaco.x1),
                              Flexible(child: Text(t.obraTitulo!, style: legenda, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${t.tipo == 'Receita' ? '+' : '-'} ${fmt.format(t.valor)}",
                          style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: _corTipo(t.tipo)),
                        ),
                        const SizedBox(height: Espaco.x1),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(Raio.pilula),
                              onTap: () async {
                                final ctrl = context.read<FinanceiroController>();
                                await Navigator.pushNamed(context, '/transacao-formulario', arguments: t);
                                if (mounted) ctrl.carregarTransacoes();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(Espaco.x1),
                                child: Icon(Symbols.edit_rounded, size: 18, color: c.inkMuted),
                              ),
                            ),
                            if (podeExcluir) ...[
                              const SizedBox(width: Espaco.x1),
                              InkWell(
                                borderRadius: BorderRadius.circular(Raio.pilula),
                                onTap: () => _confirmarExclusao(context, t, controller),
                                child: Padding(
                                  padding: const EdgeInsets.all(Espaco.x1),
                                  child: Icon(Symbols.delete_rounded, size: 18, color: c.error),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarOpcoesNovaTransacao(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    Widget icone(IconData i, Color cor, Color fundo) => Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(Raio.botao)),
          child: Icon(i, color: cor),
        );

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Espaco.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Nova Transação", style: texto.titleMedium),
              const SizedBox(height: Espaco.x5),
              ListTile(
                leading: icone(Symbols.arrow_upward_rounded, c.success, c.successSoft),
                title: Text("Nova Receita", style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: const Text("Pagamento de cliente, adiantamento..."),
                onTap: () async {
                  final ctrl = context.read<FinanceiroController>();
                  Navigator.pop(ctx);
                  await Navigator.pushNamed(context, '/transacao-formulario', arguments: {'tipo': 'Receita'});
                  if (mounted) ctrl.carregarTransacoes();
                },
              ),
              const SizedBox(height: Espaco.x2),
              ListTile(
                leading: icone(Symbols.arrow_downward_rounded, c.error, c.errorSoft),
                title: Text("Nova Despesa", style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: const Text("Material, transporte, alimentação..."),
                onTap: () async {
                  final ctrl = context.read<FinanceiroController>();
                  Navigator.pop(ctx);
                  await Navigator.pushNamed(context, '/transacao-formulario', arguments: {'tipo': 'Despesa'});
                  if (mounted) ctrl.carregarTransacoes();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, Transacao t, FinanceiroController controller) {
    final c = context.cores;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Transação?"),
        content: Text("Tem certeza que deseja remover \"${t.descricao}\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          FilledButton(
            onPressed: () {
              controller.excluir(t.id!);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: c.error, foregroundColor: c.onError),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
  }
}
