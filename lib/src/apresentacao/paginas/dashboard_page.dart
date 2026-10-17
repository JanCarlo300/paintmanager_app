import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../modules/auth/dominio/entidades/usuario.dart';
import '../../modules/auth/apresentacao/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/notificacao_controller.dart';
import '../widgets/card_app.dart';
import '../widgets/card_destaque.dart';
import '../widgets/drawer_comum.dart';
import '../widgets/icone_modulo.dart';
import '../widgets/status_chip.dart';
import '../widgets/tela_vazia.dart';
import '../../core/tema/cores_app.dart';
import '../../core/tema/medidas_app.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificacaoController = context.watch<NotificacaoController>();
    final qtdAlertas = notificacaoController.alertas.length;
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const DrawerComum(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Cabeçalho: saudação + data ───
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Symbols.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Alertas',
                icon: Badge(
                  label: Text('$qtdAlertas'),
                  isLabelVisible: qtdAlertas > 0,
                  backgroundColor: c.secondary,
                  textColor: c.onSecondary,
                  child: const Icon(Symbols.notifications_rounded),
                ),
                onPressed: () => _mostrarAlertas(context, notificacaoController),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Espaco.x5, 50, Espaco.x5, Espaco.x4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      StreamBuilder<Usuario?>(
                        stream: context.read<AuthController>().usuarioAtual,
                        builder: (context, snapshot) {
                          final nome = snapshot.data?.nome ?? 'Usuário';
                          final primeiroNome = nome.split(' ').first;
                          return Text(
                            'Olá, $primeiroNome! 👋',
                            style: texto.headlineMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                      const SizedBox(height: Espaco.x1),
                      Text(
                        _capitalizar(DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(DateTime.now())),
                        style: texto.bodyMedium?.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Conteúdo ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Espaco.margemTela),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── 4 Cards de Resumo ───
                  _buildSectionTitle(context, 'Resumo Geral'),
                  const SizedBox(height: Espaco.x3),
                  _buildResumoCards(context),
                  const SizedBox(height: 28),

                  // ─── Resumo Financeiro ───
                  _buildSectionTitle(context, 'Financeiro do Mês'),
                  const SizedBox(height: Espaco.x3),
                  _buildResumoFinanceiro(context),
                  const SizedBox(height: 28),

                  // ─── Obras Recentes ───
                  _buildSectionTitle(context, 'Obras Recentes'),
                  const SizedBox(height: Espaco.x3),
                  _buildObrasRecentes(context),
                  const SizedBox(height: 28),

                  // ─── Atalhos Rápidos ───
                  _buildSectionTitle(context, 'Acesso Rápido'),
                  const SizedBox(height: Espaco.x3),
                  _buildAtalhosRapidos(context),
                  const SizedBox(height: Espaco.x6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SECTION TITLE
  // ═══════════════════════════════════════════
  Widget _buildSectionTitle(BuildContext context, String titulo) {
    return Text(titulo, style: Theme.of(context).textTheme.titleLarge);
  }

  // ═══════════════════════════════════════════
  // 4 CARDS DE RESUMO
  // ═══════════════════════════════════════════
  Widget _buildResumoCards(BuildContext context) {
    final dashboardCtrl = context.watch<DashboardController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Espaco.x3,
          crossAxisSpacing: Espaco.x3,
          childAspectRatio: 1.2,
          children: [
            _buildResumoCard(
              context,
              icon: Symbols.construction_rounded,
              label: 'Obras Ativas',
              valor: dashboardCtrl.carregando ? '...' : dashboardCtrl.obrasAtivas.toString(),
            ),
            _buildResumoCard(
              context,
              icon: Symbols.trending_up_rounded,
              label: 'Receita Mês',
              valor: dashboardCtrl.carregando ? '...' : _formatarMoeda(dashboardCtrl.receitaMes),
            ),
            _buildResumoCard(
              context,
              icon: Symbols.trending_down_rounded,
              label: 'Despesa Mês',
              valor: dashboardCtrl.carregando ? '...' : _formatarMoeda(dashboardCtrl.despesaMes),
            ),
            _buildResumoCard(
              context,
              icon: Symbols.request_quote_rounded,
              label: 'Orç. Pendentes',
              valor: dashboardCtrl.carregando ? '...' : dashboardCtrl.orcamentosPendentes.toString(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResumoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String valor,
  }) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return CardApp(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconeModulo(icon),
          const Spacer(),
          // Valores grandes (R$ 100.000,00) diminuem para caber, sem cortar.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(valor, style: texto.displayMedium?.copyWith(color: c.ink), maxLines: 1),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // RESUMO FINANCEIRO
  // ═══════════════════════════════════════════
  Widget _buildResumoFinanceiro(BuildContext context) {
    final dashboardCtrl = context.watch<DashboardController>();
    final c = context.cores;
    if (dashboardCtrl.carregando) {
      return const Padding(
        padding: EdgeInsets.all(Espaco.x8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final receitas = dashboardCtrl.receitaMes;
    final despesas = dashboardCtrl.despesaMes;
    final saldo = receitas - despesas;
    final maxValor = receitas > despesas ? receitas : despesas;
    final fracReceita = maxValor > 0 ? receitas / maxValor : 0.0;
    final fracDespesa = maxValor > 0 ? despesas / maxValor : 0.0;

    return Column(
      children: [
        // Saldo: o card destaque da tela (um só, como pede o manual).
        CardDestaque(
          rotulo: 'Saldo do Mês',
          valor: '${saldo < 0 ? '− ' : ''}${_formatarMoeda(saldo.abs())}',
          legenda: saldo >= 0 ? 'Receitas maiores que despesas' : 'Despesas maiores que receitas',
        ),
        const SizedBox(height: Espaco.x3),
        CardApp(
          padding: const EdgeInsets.all(Espaco.x5),
          child: Column(
            children: [
              _buildBarraFinanceira(
                context,
                label: 'Receitas',
                valor: receitas,
                frac: fracReceita,
                cor: c.success,
                icon: Symbols.arrow_circle_up_rounded,
              ),
              const SizedBox(height: 14),
              _buildBarraFinanceira(
                context,
                label: 'Despesas',
                valor: despesas,
                frac: fracDespesa,
                cor: c.error,
                icon: Symbols.arrow_circle_down_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarraFinanceira(
    BuildContext context, {
    required String label,
    required double valor,
    required double frac,
    required Color cor,
    required IconData icon,
  }) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: cor, size: TamanhoIcone.pequeno),
            const SizedBox(width: 6),
            Text(label, style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: c.inkMuted)),
            const Spacer(),
            Text(_formatarMoeda(valor), style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: cor)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(Raio.pilula),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 8,
            backgroundColor: c.surfaceSunken,
            valueColor: AlwaysStoppedAnimation<Color>(cor),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // OBRAS RECENTES
  // ═══════════════════════════════════════════
  Widget _buildObrasRecentes(BuildContext context) {
    final dashboardCtrl = context.watch<DashboardController>();
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    if (dashboardCtrl.carregando) {
      return const Padding(
        padding: EdgeInsets.all(Espaco.x8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final obrasRecentes = dashboardCtrl.obrasRecentes;
    if (obrasRecentes.isEmpty) {
      return const TelaVazia(
        ilustracao: IlustracaoVazia.obras,
        titulo: 'Nenhuma obra cadastrada',
        texto: 'As obras mais recentes aparecem aqui.',
      );
    }

    return Column(
      children: obrasRecentes.map((obra) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Espaco.x3),
          child: CardApp(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            obra.tituloDaObra,
                            style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            obra.clienteNome,
                            style: texto.bodyMedium?.copyWith(color: c.inkMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Espaco.x2),
                    StatusChip(obra.status),
                  ],
                ),
                const SizedBox(height: 14),
                // Barra de progresso: trilho surfaceSunken, preenchimento brand.
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Raio.pilula),
                        child: LinearProgressIndicator(
                          value: obra.progresso / 100,
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: Espaco.x3),
                    Text(
                      '${obra.progresso.toStringAsFixed(0)}%',
                      style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════
  // ATALHOS RÁPIDOS
  // ═══════════════════════════════════════════
  Widget _buildAtalhosRapidos(BuildContext context) {
    final atalhos = [
      _AtalhoItem(icon: Symbols.person_add_rounded, label: 'Novo\nCliente', rota: '/cliente-formulario'),
      _AtalhoItem(icon: Symbols.request_quote_rounded, label: 'Novo\nOrçamento', rota: '/orcamento-formulario'),
      _AtalhoItem(icon: Symbols.add_business_rounded, label: 'Nova\nObra', rota: '/obra-formulario'),
      _AtalhoItem(icon: Symbols.group_rounded, label: 'Clientes', rota: '/clientes'),
      _AtalhoItem(icon: Symbols.bar_chart_rounded, label: 'Relatórios', rota: '/relatorios'),
      _AtalhoItem(icon: Symbols.account_balance_wallet_rounded, label: 'Financeiro', rota: '/financeiro'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 6 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: Espaco.x3,
            crossAxisSpacing: Espaco.x3,
            childAspectRatio: 1.0,
          ),
          itemCount: atalhos.length,
          itemBuilder: (context, index) {
            final atalho = atalhos[index];
            return CardApp(
              padding: const EdgeInsets.all(Espaco.x2),
              aoTocar: () => Navigator.pushNamed(context, atalho.rota),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconeModulo(atalho.icon, diametro: 44),
                  const SizedBox(height: Espaco.x2),
                  Flexible(
                    child: Text(
                      atalho.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 0, height: 1.2),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════
  String _formatarMoeda(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2)
        .format(valor);
  }

  String _capitalizar(String texto) =>
      texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

  // ═══════════════════════════════════════════
  // ALERTAS (RF013 simplificado)
  // ═══════════════════════════════════════════
  void _mostrarAlertas(BuildContext context, NotificacaoController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Espaco.x5),
          child: Consumer<NotificacaoController>(
            builder: (context, ctrl, _) {
              final c = context.cores;
              final texto = Theme.of(context).textTheme;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Alertas", style: texto.titleMedium),
                      IconButton(
                        icon: const Icon(Symbols.refresh_rounded, size: TamanhoIcone.pequeno),
                        tooltip: "Atualizar",
                        onPressed: () => ctrl.carregarAlertas(),
                      ),
                    ],
                  ),
                  if (ctrl.carregando)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: Espaco.x6),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (ctrl.alertas.isEmpty)
                    const TelaVazia(
                      ilustracao: IlustracaoVazia.notificacoes,
                      titulo: 'Tudo em dia',
                      texto: 'Sem pendências no momento.',
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: ctrl.alertas.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final a = ctrl.alertas[i];
                          final cor = a.urgente ? c.error : c.warning;
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: a.urgente ? c.errorSoft : c.warningSoft,
                              child: Icon(a.icone, color: cor, size: TamanhoIcone.pequeno),
                            ),
                            title: Text(a.titulo, style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              a.subtitulo,
                              style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(context, a.rota);
                            },
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Modelo auxiliar para atalhos ───
class _AtalhoItem {
  final IconData icon;
  final String label;
  final String rota;

  const _AtalhoItem({
    required this.icon,
    required this.label,
    required this.rota,
  });
}
