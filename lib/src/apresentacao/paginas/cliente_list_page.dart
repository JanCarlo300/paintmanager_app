import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/cliente.dart';
import '../../dominio/entidades/obra.dart';
import '../controllers/cliente_controller.dart';
import '../controllers/obra_controller.dart';
import '../widgets/drawer_comum.dart';

/// Filtros disponíveis na tela de clientes
enum FiltroCliente { comObraAtiva, todosAtivos, inativos }

class ClienteListPage extends StatefulWidget {
  const ClienteListPage({super.key});

  @override
  State<ClienteListPage> createState() => _ClienteListPageState();
}

class _ClienteListPageState extends State<ClienteListPage> {
  String _termoBusca = '';
  FiltroCliente _filtroAtual = FiltroCliente.comObraAtiva;

  /// Aplica filtro de busca por texto
  List<Cliente> _filtrarPorTexto(List<Cliente> clientes) {
    if (_termoBusca.isEmpty) return clientes;
    final termo = _termoBusca.toLowerCase();
    return clientes.where((c) =>
      c.nome.toLowerCase().contains(termo) ||
      c.email.toLowerCase().contains(termo) ||
      c.telefone.toLowerCase().contains(termo)
    ).toList();
  }

  /// Aplica filtro por status (ativo/inativo/com obra)
  List<Cliente> _filtrarPorStatus(List<Cliente> clientes, Set<String> clienteIdsComObraAtiva) {
    switch (_filtroAtual) {
      case FiltroCliente.comObraAtiva:
        return clientes.where((c) => c.ativo && clienteIdsComObraAtiva.contains(c.id)).toList();
      case FiltroCliente.todosAtivos:
        return clientes.where((c) => c.ativo).toList();
      case FiltroCliente.inativos:
        return clientes.where((c) => !c.ativo).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final clienteCtrl = context.read<ClienteController>();
    final obraCtrl = context.read<ObraController>();

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
        title: const Text("Clientes", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<Obra>>(
        stream: obraCtrl.obras,
        builder: (context, obraSnapshot) {
          // Trata erro no stream de obras silenciosamente (usa lista vazia)
          final obras = obraSnapshot.hasError ? <Obra>[] : (obraSnapshot.data ?? <Obra>[]);
          final clienteIdsComObraAtiva = obras
              .where((o) => o.status != 'Concluída')
              .map((o) => o.clienteId)
              .toSet();

          return StreamBuilder<List<Cliente>>(
            stream: clienteCtrl.clientes,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Erro ao carregar clientes."));
              }

              final todosClientes = snapshot.data ?? [];
              final clientesFiltradosPorStatus = _filtrarPorStatus(todosClientes, clienteIdsComObraAtiva);
              final clientesFiltrados = _filtrarPorTexto(clientesFiltradosPorStatus);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ---
                    const Text("Gestão de Clientes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Gerencie informações e histórico dos seus clientes.",
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 16),

                    // --- BOTÃO NOVO CLIENTE ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/cliente-formulario'),
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text("Novo Cliente"),
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
                    _buildFiltroChips(todosClientes, clienteIdsComObraAtiva),
                    const SizedBox(height: 16),

                    // --- BARRA DE BUSCA ---
                    _buildBarraBusca(),
                    const SizedBox(height: 8),

                    // --- CONTADOR ---
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "${clientesFiltrados.length} cliente(s) encontrado(s)",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ),

                    // --- LISTA DE CARDS ---
                    if (clientesFiltrados.isEmpty)
                      _buildVazio()
                    else
                      ...clientesFiltrados.map((c) => _buildClienteCard(c, clienteCtrl, clienteIdsComObraAtiva)),
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
  Widget _buildFiltroChips(List<Cliente> todosClientes, Set<String> idsComObra) {
    final qtdComObra = todosClientes.where((c) => c.ativo && idsComObra.contains(c.id)).length;
    final qtdAtivos = todosClientes.where((c) => c.ativo).length;
    final qtdInativos = todosClientes.where((c) => !c.ativo).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filtroChip("Com Obra Ativa", FiltroCliente.comObraAtiva, qtdComObra, Colors.orange),
          const SizedBox(width: 8),
          _filtroChip("Todos Ativos", FiltroCliente.todosAtivos, qtdAtivos, Colors.green),
          const SizedBox(width: 8),
          _filtroChip("Inativos", FiltroCliente.inativos, qtdInativos, Colors.grey),
        ],
      ),
    );
  }

  Widget _filtroChip(String label, FiltroCliente filtro, int count, Color cor) {
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
          hintText: "Buscar por nome, e-mail ou telefone...",
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

  // === CARD DO CLIENTE ===
  Widget _buildClienteCard(Cliente cliente, ClienteController controller, Set<String> idsComObra) {
    final dataCriacao = DateFormat('dd/MM/yyyy').format(cliente.criadoEm);
    final temObraAtiva = idsComObra.contains(cliente.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _mostrarOpcoes(context, cliente, controller),
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
                // Nome + Badge
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: cliente.ativo ? Colors.black : Colors.grey[400],
                      child: Text(
                        cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nome e data
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente.nome,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Cliente desde $dataCriacao",
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    // Badges
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _badge(
                          cliente.ativo ? "Ativo" : "Inativo",
                          cliente.ativo ? Colors.green : Colors.grey,
                        ),
                        if (temObraAtiva) ...[
                          const SizedBox(height: 4),
                          _badge("Obra Ativa", Colors.orange),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // Info de contato
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(Icons.phone_outlined, cliente.telefone.isNotEmpty ? cliente.telefone : '—'),
                    ),
                    Expanded(
                      child: _infoItem(Icons.email_outlined, cliente.email.isNotEmpty ? cliente.email : '—'),
                    ),
                  ],
                ),
                if (cliente.endereco.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoItem(Icons.location_on_outlined, cliente.endereco),
                ],
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

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // === BOTTOM SHEET COM OPÇÕES ===
  void _mostrarOpcoes(BuildContext context, Cliente cliente, ClienteController controller) {
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
              // Nome do cliente
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black,
                      child: Text(
                        cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(cliente.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const Divider(),
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
                subtitle: const Text("Alterar dados do cliente", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/cliente-formulario', arguments: cliente);
                },
              ),
              // Inativar / Ativar
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (cliente.ativo ? Colors.red : Colors.green).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    cliente.ativo ? Icons.person_off_outlined : Icons.person_outlined,
                    color: cliente.ativo ? Colors.red : Colors.green,
                    size: 20,
                  ),
                ),
                title: Text(
                  cliente.ativo ? "Inativar" : "Ativar",
                  style: TextStyle(fontWeight: FontWeight.w500, color: cliente.ativo ? Colors.red : Colors.green),
                ),
                subtitle: Text(
                  cliente.ativo ? "O cliente não aparecerá na lista principal" : "Reativar este cliente",
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmarAlteracaoStatus(context, cliente, controller);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === CONFIRMAÇÃO DE INATIVAÇÃO / ATIVAÇÃO ===
  void _confirmarAlteracaoStatus(BuildContext context, Cliente cliente, ClienteController controller) {
    final acao = cliente.ativo ? "Inativar" : "Ativar";
    final msg = cliente.ativo
        ? "O cliente ${cliente.nome} será inativado e não aparecerá mais na lista principal. Você pode reativá-lo pelo filtro 'Inativos'."
        : "O cliente ${cliente.nome} será reativado e voltará a aparecer na lista.";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("$acao Cliente?"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (cliente.ativo) {
                controller.inativar(cliente.id!);
              } else {
                controller.ativar(cliente.id!);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Cliente ${cliente.ativo ? 'inativado' : 'ativado'} com sucesso!"),
                  backgroundColor: cliente.ativo ? Colors.orange : Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cliente.ativo ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(acao, style: const TextStyle(color: Colors.white)),
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
      case FiltroCliente.comObraAtiva:
        mensagem = "Nenhum cliente com obra ativa no momento.";
        icone = Icons.construction_outlined;
      case FiltroCliente.todosAtivos:
        mensagem = "Nenhum cliente ativo encontrado.";
        icone = Icons.person_outline;
      case FiltroCliente.inativos:
        mensagem = "Nenhum cliente inativo.";
        icone = Icons.person_off_outlined;
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
          if (_filtroAtual == FiltroCliente.comObraAtiva) ...[
            const SizedBox(height: 8),
            Text("Use o filtro 'Todos Ativos' para ver todos os clientes.",
                style: TextStyle(color: Colors.grey[400], fontSize: 12), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}