import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../dominio/entidades/orcamento.dart';
import '../../dominio/entidades/cliente.dart';
import '../controllers/orcamento_controller.dart';
import '../controllers/cliente_controller.dart';
import '../widgets/drawer_comum.dart';

class OrcamentoListPage extends StatefulWidget {
  const OrcamentoListPage({super.key});

  @override
  State<OrcamentoListPage> createState() => _OrcamentoListPageState();
}

class _OrcamentoListPageState extends State<OrcamentoListPage> {
  String _termoBusca = '';

  final _formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _formatoData = DateFormat('dd/MM/yyyy');

  List<Orcamento> _filtrar(List<Orcamento> orcamentos) {
    if (_termoBusca.isEmpty) return orcamentos;
    final termo = _termoBusca.toLowerCase();
    return orcamentos.where((o) =>
      o.clienteNome.toLowerCase().contains(termo) ||
      o.descricao.toLowerCase().contains(termo) ||
      o.status.toLowerCase().contains(termo)
    ).toList();
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'Aprovado': return Colors.green;
      case 'Rejeitado': return Colors.red;
      case 'Concluído': return Colors.blue;
      default: return Colors.orange;
    }
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
    final cliente = clientes.where((c) => c.id == orc.clienteId).firstOrNull;

    if (cliente == null || cliente.telefone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cliente sem telefone cadastrado."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    // Limpar telefone (remover caracteres não numéricos)
    final telefone = cliente.telefone.replaceAll(RegExp(r'[^0-9]'), '');
    final telefoneCompleto = telefone.length <= 11 ? '55$telefone' : telefone;
    final mensagem = _formatarMensagem(orc);

    final url = Uri.parse('https://wa.me/$telefoneCompleto?text=${Uri.encodeComponent(mensagem)}');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao abrir WhatsApp: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // === ENVIAR POR E-MAIL ===
  Future<void> _enviarEmail(Orcamento orc, List<Cliente> clientes) async {
    final cliente = clientes.where((c) => c.id == orc.clienteId).firstOrNull;

    if (cliente == null || cliente.email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cliente sem e-mail cadastrado."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    // Montar mensagem sem markdown (para e-mail)
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao abrir e-mail: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // === DIALOG DE ENVIO ===
  void _mostrarOpcoesEnvio(Orcamento orc, List<Cliente> clientes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Enviar Orçamento", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("Enviar para ${orc.clienteNome}", style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),

              // WhatsApp
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: const Color(0xFF25D366).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.chat, color: Color(0xFF25D366)),
                ),
                title: const Text("Enviar por WhatsApp", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Abre o WhatsApp com a mensagem pronta"),
                onTap: () {
                  Navigator.pop(context);
                  _enviarWhatsApp(orc, clientes);
                },
              ),
              const SizedBox(height: 8),

              // E-mail
              ListTile(
                leading: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.email_outlined, color: Colors.blue),
                ),
                title: const Text("Enviar por E-mail", style: TextStyle(fontWeight: FontWeight.w600)),
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

  @override
  Widget build(BuildContext context) {
    final controller = context.read<OrcamentoController>();
    final clienteController = context.read<ClienteController>();
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: const DrawerComum(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text("Orçamentos", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<Orcamento>>(
        stream: controller.orcamentos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Erro ao carregar orçamentos."));
          }

          final todos = snapshot.data ?? [];
          final filtrados = _filtrar(todos);
          final pendentes = todos.where((o) => o.status == 'Pendente').length;
          final aprovados = todos.where((o) => o.status == 'Aprovado').length;

          return StreamBuilder<List<Cliente>>(
            stream: clienteController.clientes,
            builder: (context, clienteSnapshot) {
              final clientes = clienteSnapshot.data ?? [];

              return SingleChildScrollView(
                padding: EdgeInsets.all(isWide ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ---
                    const Text("Gestão de Orçamentos", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Crie e gerencie orçamentos para seus clientes.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: isWide ? null : double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/orcamento-formulario'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Novo Orçamento"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- SUMMARY CARDS ---
                    _buildSummaryCards(todos.length, pendentes, aprovados, isWide),
                    const SizedBox(height: 24),

                    // --- TABELA ---
                    Container(
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
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Orçamentos Cadastrados", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text("${filtrados.length} orçamento(s) encontrado(s)", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 40,
                                  child: TextField(
                                    onChanged: (v) => setState(() => _termoBusca = v),
                                    decoration: InputDecoration(
                                      hintText: "Buscar orçamentos...",
                                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                                      prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                                      filled: true, fillColor: Colors.grey[100],
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),

                          if (filtrados.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.request_quote_outlined, size: 48, color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text("Nenhum orçamento encontrado.", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: isWide ? MediaQuery.of(context).size.width - 100 : 700),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                                  headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13),
                                  dataRowMinHeight: 60, dataRowMaxHeight: 72,
                                  columnSpacing: 24, horizontalMargin: 20,
                                  columns: const [
                                    DataColumn(label: Text('Cliente')),
                                    DataColumn(label: Text('Descrição')),
                                    DataColumn(label: Text('Valor Total')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Data')),
                                    DataColumn(label: Text('Ações')),
                                  ],
                                  rows: filtrados.map((orc) {
                                    return DataRow(cells: [
                                      DataCell(Text(orc.clienteNome, style: const TextStyle(fontWeight: FontWeight.w600))),
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 200),
                                          child: Text(orc.descricao, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                                        ),
                                      ),
                                      DataCell(Text(_formatoMoeda.format(orc.valorTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _corStatus(orc.status).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(orc.status, style: TextStyle(color: _corStatus(orc.status), fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_formatoData.format(orc.dataCriacao), style: const TextStyle(fontSize: 12)),
                                            Text("Val: ${_formatoData.format(orc.dataValidade)}", style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Botão ENVIAR (WhatsApp/Email)
                                            IconButton(
                                              icon: const Icon(Icons.send_outlined, size: 20),
                                              color: const Color(0xFF25D366),
                                              tooltip: "Enviar para o cliente",
                                              onPressed: () => _mostrarOpcoesEnvio(orc, clientes),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 20),
                                              color: Colors.grey[700],
                                              tooltip: "Editar",
                                              onPressed: () => Navigator.pushNamed(context, '/orcamento-formulario', arguments: orc),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 20),
                                              color: Colors.red[400],
                                              tooltip: "Excluir",
                                              onPressed: () => _confirmarExclusao(context, orc, controller),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(int total, int pendentes, int aprovados, bool isWide) {
    final cards = [
      _buildSummaryCard("Total de Orçamentos", total.toString(), "Todos os orçamentos", Colors.blue),
      _buildSummaryCard("Pendentes", pendentes.toString(), "Aguardando aprovação", Colors.orange),
      _buildSummaryCard("Aprovados", aprovados.toString(), "Prontos para execução", Colors.green),
    ];

    if (isWide) {
      return Row(
        children: cards.map((card) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6), child: card,
        ))).toList(),
      );
    } else {
      return Column(
        children: cards.map((card) => Padding(padding: const EdgeInsets.only(bottom: 12), child: card)).toList(),
      );
    }
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        border: Border(top: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  void _confirmarExclusao(BuildContext context, Orcamento orcamento, OrcamentoController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Excluir Orçamento?"),
        content: Text("Tem certeza que deseja remover o orçamento \"${orcamento.descricao}\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              controller.excluir(orcamento.id!);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Excluir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
