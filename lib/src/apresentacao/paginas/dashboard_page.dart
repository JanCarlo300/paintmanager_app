import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/cliente.dart';
import '../../dominio/entidades/obra.dart';
import '../../dominio/entidades/orcamento.dart';
import '../../dominio/entidades/transacao.dart';
import '../../dominio/entidades/usuario.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cliente_controller.dart';
import '../controllers/financeiro_controller.dart';
import '../controllers/obra_controller.dart';
import '../controllers/orcamento_controller.dart';
import '../controllers/usuario_controller.dart';
import '../widgets/drawer_comum.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // ─── Paleta PaintManager ───
  static const Color _corPrimaria = Colors.black;
  static const Color _corAccent = Color(0xFFFF9800); // Laranja
  static const Color _corAccentClaro = Color(0xFFFFF3E0);
  static const Color _corFundo = Color(0xFFF5F6FA);
  static const Color _corCard = Colors.white;
  static const Color _corVerdeReceita = Color(0xFF43A047);
  static const Color _corVermelhoDespesa = Color(0xFFE53935);
  static const Color _corAzulInfo = Color(0xFF1E88E5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _corFundo,
      drawer: const DrawerComum(),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── AppBar com gradiente ───
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF212121), Color(0xFF424242)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Conteúdo ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── 4 Cards de Resumo ───
                  _buildSectionTitle('Resumo Geral'),
                  const SizedBox(height: 12),
                  _buildResumoCards(context),
                  const SizedBox(height: 28),

                  // ─── Resumo Financeiro ───
                  _buildSectionTitle('Financeiro do Mês'),
                  const SizedBox(height: 12),
                  _buildResumoFinanceiro(context),
                  const SizedBox(height: 28),

                  // ─── Obras Recentes ───
                  _buildSectionTitle('Obras Recentes'),
                  const SizedBox(height: 12),
                  _buildObrasRecentes(context),
                  const SizedBox(height: 28),

                  // ─── Atalhos Rápidos ───
                  _buildSectionTitle('Acesso Rápido'),
                  const SizedBox(height: 12),
                  _buildAtalhosRapidos(context),
                  const SizedBox(height: 24),
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
  Widget _buildSectionTitle(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF212121),
        letterSpacing: 0.3,
      ),
    );
  }

  // ═══════════════════════════════════════════
  // 4 CARDS DE RESUMO
  // ═══════════════════════════════════════════
  Widget _buildResumoCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            // Card Clientes Ativos
            StreamBuilder<List<Cliente>>(
              stream: context.watch<ClienteController>().clientes,
              builder: (context, snapshot) {
                final total = snapshot.data?.where((c) => c.ativo).length ?? 0;
                return _buildResumoCard(
                  icon: Icons.people_rounded,
                  label: 'Clientes Ativos',
                  valor: total.toString(),
                  corIcone: _corAzulInfo,
                  corFundoIcone: const Color(0xFFE3F2FD),
                );
              },
            ),
            // Card Obras em Andamento
            StreamBuilder<List<Obra>>(
              stream: context.watch<ObraController>().obras,
              builder: (context, snapshot) {
                final total = snapshot.data
                        ?.where((o) => o.status == 'Em Andamento')
                        .length ??
                    0;
                return _buildResumoCard(
                  icon: Icons.construction_rounded,
                  label: 'Obras Ativas',
                  valor: total.toString(),
                  corIcone: _corAccent,
                  corFundoIcone: _corAccentClaro,
                );
              },
            ),
            // Card Receita do Mês
            StreamBuilder<List<Transacao>>(
              stream: context.watch<FinanceiroController>().transacoes,
              builder: (context, snapshot) {
                final agora = DateTime.now();
                final receitaMes = (snapshot.data ?? [])
                    .where((t) =>
                        t.tipo == 'Receita' &&
                        t.status != 'Pendente' &&
                        t.dataTransacao.month == agora.month &&
                        t.dataTransacao.year == agora.year)
                    .fold<double>(0, (soma, t) => soma + t.valor);
                return _buildResumoCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Receita Mês',
                  valor: _formatarMoeda(receitaMes),
                  corIcone: _corVerdeReceita,
                  corFundoIcone: const Color(0xFFE8F5E9),
                  fontSizeValor: receitaMes > 99999 ? 16 : null,
                );
              },
            ),
            // Card Orçamentos Pendentes
            StreamBuilder<List<Orcamento>>(
              stream: context.watch<OrcamentoController>().orcamentos,
              builder: (context, snapshot) {
                final total = snapshot.data
                        ?.where((o) => o.status == 'Pendente')
                        .length ??
                    0;
                return _buildResumoCard(
                  icon: Icons.request_quote_rounded,
                  label: 'Orç. Pendentes',
                  valor: total.toString(),
                  corIcone: const Color(0xFF8E24AA),
                  corFundoIcone: const Color(0xFFF3E5F5),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildResumoCard({
    required IconData icon,
    required String label,
    required String valor,
    required Color corIcone,
    required Color corFundoIcone,
    double? fontSizeValor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _corCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: corFundoIcone,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: corIcone, size: 20),
          ),
          const Spacer(),
          Text(
            valor,
            style: TextStyle(
              fontSize: fontSizeValor ?? 22,
              fontWeight: FontWeight.w800,
              color: _corPrimaria,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
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
    return StreamBuilder<List<Transacao>>(
      stream: context.watch<FinanceiroController>().transacoes,
      builder: (context, snapshot) {
        final agora = DateTime.now();
        final transacoesMes = (snapshot.data ?? []).where((t) =>
            t.dataTransacao.month == agora.month &&
            t.dataTransacao.year == agora.year);

        final receitas = transacoesMes
            .where((t) => t.tipo == 'Receita' && t.status != 'Pendente')
            .fold<double>(0, (s, t) => s + t.valor);
        final despesas = transacoesMes
            .where((t) => t.tipo == 'Despesa' && t.status != 'Pendente')
            .fold<double>(0, (s, t) => s + t.valor);
        final saldo = receitas - despesas;
        final maxValor = receitas > despesas ? receitas : despesas;
        final fracReceita = maxValor > 0 ? receitas / maxValor : 0.0;
        final fracDespesa = maxValor > 0 ? despesas / maxValor : 0.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _corCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Saldo destaque
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: saldo >= 0
                        ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
                        : [const Color(0xFFC62828), const Color(0xFFE53935)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Saldo do Mês',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          saldo >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatarMoeda(saldo.abs()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Barras Receitas e Despesas
              _buildBarraFinanceira(
                label: 'Receitas',
                valor: receitas,
                frac: fracReceita,
                cor: _corVerdeReceita,
                icon: Icons.arrow_circle_up_rounded,
              ),
              const SizedBox(height: 14),
              _buildBarraFinanceira(
                label: 'Despesas',
                valor: despesas,
                frac: fracDespesa,
                cor: _corVermelhoDespesa,
                icon: Icons.arrow_circle_down_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBarraFinanceira({
    required String label,
    required double valor,
    required double frac,
    required Color cor,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: cor, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const Spacer(),
            Text(
              _formatarMoeda(valor),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 8,
            backgroundColor: cor.withValues(alpha: 0.12),
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
    return StreamBuilder<List<Obra>>(
      stream: context.watch<ObraController>().obras,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.construction_outlined,
            mensagem: 'Nenhuma obra cadastrada',
          );
        }

        // Ordenar por data de início (mais recentes primeiro) e pegar top 3
        final obrasOrdenadas = List<Obra>.from(snapshot.data!)
          ..sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
        final obrasRecentes = obrasOrdenadas.take(3).toList();

        return Column(
          children: obrasRecentes.map((obra) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _corCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF212121),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              obra.clienteNome,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(obra.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Barra de progresso
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: obra.progresso / 100,
                            minHeight: 8,
                            backgroundColor: _corAccent.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              obra.progresso >= 100
                                  ? _corVerdeReceita
                                  : _corAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${obra.progresso.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: obra.progresso >= 100
                              ? _corVerdeReceita
                              : _corAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color corBadge;
    Color corTexto;
    switch (status) {
      case 'Em Andamento':
        corBadge = const Color(0xFFFFF3E0);
        corTexto = _corAccent;
        break;
      case 'Concluída':
        corBadge = const Color(0xFFE8F5E9);
        corTexto = _corVerdeReceita;
        break;
      case 'Pausada':
        corBadge = const Color(0xFFFFEBEE);
        corTexto = _corVermelhoDespesa;
        break;
      default: // Não Iniciada
        corBadge = const Color(0xFFECEFF1);
        corTexto = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: corBadge,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: corTexto,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ATALHOS RÁPIDOS
  // ═══════════════════════════════════════════
  Widget _buildAtalhosRapidos(BuildContext context) {
    final atalhos = [
      _AtalhoItem(icon: Icons.person_add_rounded, label: 'Novo\nCliente', rota: '/cliente-formulario'),
      _AtalhoItem(icon: Icons.request_quote_rounded, label: 'Novo\nOrçamento', rota: '/orcamento-formulario'),
      _AtalhoItem(icon: Icons.add_business_rounded, label: 'Nova\nObra', rota: '/obra-formulario'),
      _AtalhoItem(icon: Icons.people_rounded, label: 'Clientes', rota: '/clientes'),
      _AtalhoItem(icon: Icons.bar_chart_rounded, label: 'Relatórios', rota: '/relatorios'),
      _AtalhoItem(icon: Icons.attach_money_rounded, label: 'Financeiro', rota: '/financeiro'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 6 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: atalhos.length,
          itemBuilder: (context, index) {
            final atalho = atalhos[index];
            return Material(
              color: _corCard,
              borderRadius: BorderRadius.circular(14),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                splashColor: _corAccent.withValues(alpha: 0.12),
                highlightColor: _corAccent.withValues(alpha: 0.06),
                onTap: () {
                  if (atalho.rota.contains('formulario')) {
                    Navigator.pushNamed(context, atalho.rota);
                  } else {
                    Navigator.pushReplacementNamed(context, atalho.rota);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _corAccentClaro,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(atalho.icon, color: _corAccent, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        atalho.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
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
  Widget _buildEmptyState({required IconData icon, required String mensagem}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: _corCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            mensagem,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatarMoeda(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2)
        .format(valor);
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