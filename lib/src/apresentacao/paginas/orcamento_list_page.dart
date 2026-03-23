import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../dominio/entidades/orcamento.dart';
import '../../dominio/entidades/cliente.dart';
import '../controllers/orcamento_controller.dart';
import '../controllers/cliente_controller.dart';
import '../widgets/drawer_comum.dart';

/// Filtros disponíveis na tela de orçamentos
enum FiltroOrcamento { todos, pendentes, aprovados, rejeitados, concluidos }

class OrcamentoListPage extends StatefulWidget {
  const OrcamentoListPage({super.key});

  @override
  State<OrcamentoListPage> createState() => _OrcamentoListPageState();
}

class _OrcamentoListPageState extends State<OrcamentoListPage> {
  String _termoBusca = '';
  FiltroOrcamento _filtroAtual = FiltroOrcamento.todos;

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
      case FiltroOrcamento.rejeitados:
        return orcamentos.where((o) => o.status == 'Rejeitado').toList();
      case FiltroOrcamento.concluidos:
        return orcamentos.where((o) => o.status == 'Concluído').toList();
    }
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'Aprovado': return Colors.green;
      case 'Rejeitado': return Colors.red;
      case 'Concluído': return Colors.blue;
      default: return Colors.orange;
    }
  }

  IconData _iconeStatus(String status) {
    switch (status) {
      case 'Aprovado': return Icons.check_circle_outline;
      case 'Rejeitado': return Icons.cancel_outlined;
      case 'Concluído': return Icons.task_alt_outlined;
      default: return Icons.schedule_outlined;
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

  @override
  Widget build(BuildContext context) {
    final controller = context.read<OrcamentoController>();
    final clienteController = context.read<ClienteController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: const DrawerComum(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
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
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Erro ao carregar orçamentos."));
          }

          final todos = snapshot.data ?? [];
          final filtradosPorStatus = _filtrarPorStatus(todos);
          final filtrados = _filtrarPorTexto(filtradosPorStatus);

          return StreamBuilder<List<Cliente>>(
            stream: clienteController.clientes,
            builder: (context, clienteSnapshot) {
              final clientes = clienteSnapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ---
                    const Text("Gestão de Orçamentos", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Crie e gerencie orçamentos para seus clientes.",
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 16),

                    // --- BOTÃO NOVO ORÇAMENTO ---
                    SizedBox(
                      width: double.infinity,
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
                    const SizedBox(height: 20),

                    // --- FILTRO POR STATUS ---
                    _buildFiltroChips(todos),
                    const SizedBox(height: 16),

                    // --- BARRA DE BUSCA ---
                    _buildBarraBusca(),
                    const SizedBox(height: 8),

                    // --- CONTADOR ---
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "${filtrados.length} orçamento(s) encontrado(s)",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),

                    // --- LISTA DE CARDS ---
                    if (filtrados.isEmpty)
                      _buildVazio()
                    else
                      ...filtrados.map((orc) => _buildOrcamentoCard(orc, controller, clientes)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // === FILTRO CHIPS ===
  Widget _buildFiltroChips(List<Orcamento> todos) {
    final qtdTodos = todos.length;
    final qtdPendentes = todos.where((o) => o.status == 'Pendente').length;
    final qtdAprovados = todos.where((o) => o.status == 'Aprovado').length;
    final qtdRejeitados = todos.where((o) => o.status == 'Rejeitado').length;
    final qtdConcluidos = todos.where((o) => o.status == 'Concluído').length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filtroChip("Todos", FiltroOrcamento.todos, qtdTodos, Colors.blue),
          const SizedBox(width: 8),
          _filtroChip("Pendentes", FiltroOrcamento.pendentes, qtdPendentes, Colors.orange),
          const SizedBox(width: 8),
          _filtroChip("Aprovados", FiltroOrcamento.aprovados, qtdAprovados, Colors.green),
          const SizedBox(width: 8),
          _filtroChip("Rejeitados", FiltroOrcamento.rejeitados, qtdRejeitados, Colors.red),
          const SizedBox(width: 8),
          _filtroChip("Concluídos", FiltroOrcamento.concluidos, qtdConcluidos, Colors.blue[700]!),
        ],
      ),
    );
  }

  Widget _filtroChip(String label, FiltroOrcamento filtro, int count, Color cor) {
    final selecionado = _filtroAtual == filtro;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(
            fontSize: 12,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
            color: selecionado ? Colors.white : Colors.grey[700],
          )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: selecionado ? Colors.white.withValues(alpha: 0.3) : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: selecionado ? Colors.white : Colors.grey[700]),
            ),
          ),
        ],
      ),
      selected: selecionado,
      selectedColor: cor,
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filtroAtual = filtro),
    );
  }

  // === BARRA DE BUSCA ===
  Widget _buildBarraBusca() {
    return SizedBox(
      height: 42,
      child: TextField(
        onChanged: (v) => setState(() => _termoBusca = v),
        decoration: InputDecoration(
          hintText: "Buscar por cliente ou descrição...",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black, width: 1.5),
          ),
        ),
      ),
    );
  }

  // === CARD DO ORÇAMENTO ===
  Widget _buildOrcamentoCard(Orcamento orc, OrcamentoController controller, List<Cliente> clientes) {
    final corSt = _corStatus(orc.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _mostrarOpcoes(context, orc, controller, clientes),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cliente + Status Badge
                Row(
                  children: [
                    // Avatar com iniciais do cliente
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: corSt.withValues(alpha: 0.15),
                      child: Icon(_iconeStatus(orc.status), color: corSt, size: 22),
                    ),
                    const SizedBox(width: 12),
                    // Cliente e descrição
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orc.clienteNome,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            orc.descricao,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge de status
                    _badge(orc.status, corSt),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // Valor + Datas
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(Icons.attach_money, _formatoMoeda.format(orc.valorTotal), fontWeight: FontWeight.w700),
                    ),
                    Expanded(
                      child: _infoItem(Icons.calendar_today_outlined, _formatoData.format(orc.dataCriacao)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(Icons.payments_outlined, orc.formaPagamento),
                    ),
                    Expanded(
                      child: _infoItem(
                        Icons.event_outlined,
                        "Val: ${_formatoData.format(orc.dataValidade)}",
                        color: orc.dataValidade.isBefore(DateTime.now()) ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text, {FontWeight? fontWeight, Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color ?? Colors.grey[500]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: color ?? Colors.grey[700], fontWeight: fontWeight),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // === BOTTOM SHEET COM OPÇÕES ===
  void _mostrarOpcoes(BuildContext context, Orcamento orc, OrcamentoController controller, List<Cliente> clientes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              // Info do orçamento
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _corStatus(orc.status).withValues(alpha: 0.15),
                      child: Icon(_iconeStatus(orc.status), color: _corStatus(orc.status), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(orc.clienteNome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                          Text(orc.descricao, style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Text(
                      _formatoMoeda.format(orc.valorTotal),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Enviar
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.send_outlined, color: Color(0xFF25D366), size: 20),
                ),
                title: const Text("Enviar para o Cliente", style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text("WhatsApp ou E-mail", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _mostrarOpcoesEnvio(orc, clientes);
                },
              ),
              // Editar
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                ),
                title: const Text("Editar", style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text("Alterar dados do orçamento", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/orcamento-formulario', arguments: orc);
                },
              ),
              // Excluir
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                ),
                title: const Text("Excluir", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
                subtitle: const Text("Remover este orçamento", style: TextStyle(fontSize: 12)),
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

  // === CONFIRMAÇÃO DE EXCLUSÃO ===
  void _confirmarExclusao(BuildContext context, Orcamento orcamento, OrcamentoController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Excluir Orçamento?"),
        content: Text("Tem certeza que deseja remover o orçamento \"${orcamento.descricao}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.excluir(orcamento.id!);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Orçamento excluído com sucesso!"),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Excluir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // === VAZIO ===
  Widget _buildVazio() {
    String mensagem;
    IconData icone;
    switch (_filtroAtual) {
      case FiltroOrcamento.todos:
        mensagem = "Nenhum orçamento cadastrado.";
        icone = Icons.request_quote_outlined;
      case FiltroOrcamento.pendentes:
        mensagem = "Nenhum orçamento pendente.";
        icone = Icons.schedule_outlined;
      case FiltroOrcamento.aprovados:
        mensagem = "Nenhum orçamento aprovado.";
        icone = Icons.check_circle_outline;
      case FiltroOrcamento.rejeitados:
        mensagem = "Nenhum orçamento rejeitado.";
        icone = Icons.cancel_outlined;
      case FiltroOrcamento.concluidos:
        mensagem = "Nenhum orçamento concluído.";
        icone = Icons.task_alt_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icone, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(mensagem, style: TextStyle(color: Colors.grey[600], fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
