import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/transacao.dart';
import '../controllers/financeiro_controller.dart';
import '../widgets/drawer_comum.dart';

class FinanceiroPage extends StatelessWidget {
  const FinanceiroPage({super.key});

  static const _meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

  Color _corStatus(String status) {
    switch (status) {
      case 'Efetivado': return Colors.green;
      case 'Pendente': return Colors.orange;
      case 'Atrasado': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _iconeTipo(String tipo) => tipo == 'Receita' ? Icons.arrow_upward : Icons.arrow_downward;
  Color _corTipo(String tipo) => tipo == 'Receita' ? Colors.green : Colors.red;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FinanceiroController>();
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formatoData = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: const DrawerComum(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(ctx).openDrawer()),
        ),
        title: const Text("Financeiro", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarOpcoesNovaTransacao(context),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Nova Transação", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<Transacao>>(
        stream: controller.transacoes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          final todas = snapshot.data ?? [];
          final doMes = controller.filtrarPorMes(todas);
          final receitas = controller.calcularReceitas(doMes);
          final despesas = controller.calcularDespesas(doMes);
          final saldo = controller.calcularSaldo(doMes);
          final pendentes = controller.calcularPendentes(doMes);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                const Text("Gestão Financeira", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Controle receitas, despesas e fluxo de caixa.", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),

                // --- SELETOR DE MÊS ---
                _buildSeletorMes(controller),
                const SizedBox(height: 24),

                // --- CARDS DE RESUMO ---
                _buildCardsResumo(formatoMoeda, receitas, despesas, saldo, pendentes),
                const SizedBox(height: 24),

                // --- LISTA DE TRANSAÇÕES ---
                _buildListaTransacoes(context, doMes, formatoMoeda, formatoData, controller),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- SELETOR DE MÊS ---
  Widget _buildSeletorMes(FinanceiroController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: controller.mesAnterior,
          ),
          const SizedBox(width: 8),
          Text(
            "${_meses[controller.mesSelecionado - 1]} ${controller.anoSelecionado}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: controller.mesProximo,
          ),
        ],
      ),
    );
  }

  // --- CARDS DE RESUMO ---
  Widget _buildCardsResumo(NumberFormat fmt, double receitas, double despesas, double saldo, double pendentes) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCard("Receitas", fmt.format(receitas), Colors.green, Icons.trending_up)),
            const SizedBox(width: 12),
            Expanded(child: _buildCard("Despesas", fmt.format(despesas), Colors.red, Icons.trending_down)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildCard("Saldo Atual", fmt.format(saldo), saldo >= 0 ? Colors.blue : Colors.red, Icons.account_balance_wallet)),
            const SizedBox(width: 12),
            Expanded(child: _buildCard("Pendente", fmt.format(pendentes), Colors.orange, Icons.schedule)),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(String titulo, String valor, Color cor, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        border: Border(top: BorderSide(color: cor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titulo, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Icon(icone, color: cor.withValues(alpha: 0.5), size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cor)),
        ],
      ),
    );
  }

  // --- LISTA DE TRANSAÇÕES ---
  Widget _buildListaTransacoes(BuildContext context, List<Transacao> transacoes, NumberFormat fmt, DateFormat fmtData, FinanceiroController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Transações do Mês", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("${transacoes.length} registro(s)", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          if (transacoes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text("Nenhuma transação neste mês.", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transacoes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = transacoes[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _corTipo(t.tipo).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_iconeTipo(t.tipo), color: _corTipo(t.tipo), size: 20),
                  ),
                  title: Text(t.descricao, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                            child: Text(t.categoria, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _corStatus(t.status).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(t.status, style: TextStyle(fontSize: 11, color: _corStatus(t.status), fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text("${fmtData.format(t.dataTransacao)} • ${t.formaPagamento}", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      if (t.obraTitulo != null && t.obraTitulo!.isNotEmpty)
                        Text("🏗 ${t.obraTitulo}", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${t.tipo == 'Receita' ? '+' : '-'} ${fmt.format(t.valor)}",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _corTipo(t.tipo)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => Navigator.pushNamed(context, '/transacao-formulario', arguments: t),
                            child: Icon(Icons.edit_outlined, size: 16, color: Colors.grey[500]),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _confirmarExclusao(context, t, controller),
                            child: Icon(Icons.delete_outline, size: 16, color: Colors.red[300]),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _mostrarOpcoesNovaTransacao(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Nova Transação", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_upward, color: Colors.green),
                ),
                title: const Text("Nova Receita", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Pagamento de cliente, adiantamento..."),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/transacao-formulario', arguments: {'tipo': 'Receita'});
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_downward, color: Colors.red),
                ),
                title: const Text("Nova Despesa", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Material, transporte, alimentação..."),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/transacao-formulario', arguments: {'tipo': 'Despesa'});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, Transacao t, FinanceiroController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Excluir Transação?"),
        content: Text("Tem certeza que deseja remover \"${t.descricao}\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              controller.excluir(t.id!);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}