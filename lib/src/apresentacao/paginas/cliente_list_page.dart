import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/cliente.dart';
import '../controllers/cliente_controller.dart';
import '../widgets/drawer_comum.dart';

class ClienteListPage extends StatefulWidget {
  const ClienteListPage({super.key});

  @override
  State<ClienteListPage> createState() => _ClienteListPageState();
}

class _ClienteListPageState extends State<ClienteListPage> {
  String _termoBusca = '';

  List<Cliente> _filtrar(List<Cliente> clientes) {
    if (_termoBusca.isEmpty) return clientes;
    final termo = _termoBusca.toLowerCase();
    return clientes.where((c) =>
      c.nome.toLowerCase().contains(termo) ||
      c.email.toLowerCase().contains(termo) ||
      c.telefone.toLowerCase().contains(termo) ||
      c.cpfOuCnpj.toLowerCase().contains(termo) ||
      c.endereco.toLowerCase().contains(termo)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ClienteController>();
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
        title: const Text("Clientes", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<Cliente>>(
        stream: controller.clientes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Erro ao carregar clientes."));
          }

          final todosClientes = snapshot.data ?? [];
          final clientesFiltrados = _filtrar(todosClientes);
          final totalClientes = todosClientes.length;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                const Text("Gestão de Clientes", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Gerencie informações e histórico dos seus clientes.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(
                  width: isWide ? null : double.infinity,
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
                const SizedBox(height: 24),

                // --- SUMMARY CARDS ---
                _buildSummaryCards(totalClientes, isWide),
                const SizedBox(height: 24),

                // --- TABLE SECTION ---
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Table Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Clientes Cadastrados", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              "${clientesFiltrados.length} cliente(s) encontrado(s)",
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 40,
                              child: TextField(
                                onChanged: (v) => setState(() => _termoBusca = v),
                                decoration: InputDecoration(
                                  hintText: "Buscar clientes...",
                                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),

                      // --- TABLE ---
                      if (clientesFiltrados.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.person_add_disabled, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text("Nenhum cliente encontrado.", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        )
                      else
                        _buildClienteTable(clientesFiltrados, controller, isWide),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Summary Cards ---
  Widget _buildSummaryCards(int totalClientes, bool isWide) {
    final cards = [
      _buildSummaryCard("Total de Clientes", totalClientes.toString(), "$totalClientes ativos", Colors.blue),
      _buildSummaryCard("Clientes com Obras", "0", "Clientes ativos com projetos", Colors.orange),
      _buildSummaryCard("Total de Obras", "0", "Obras em todos os clientes", Colors.green),
    ];

    if (isWide) {
      return Row(
        children: cards.map((card) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: card,
        ))).toList(),
      );
    } else {
      return Column(
        children: cards.map((card) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: card,
        )).toList(),
      );
    }
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
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

  // --- Table ---
  Widget _buildClienteTable(List<Cliente> clientes, ClienteController controller, bool isWide) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: isWide ? MediaQuery.of(context).size.width - 100 : 700),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            fontSize: 13,
          ),
          dataRowMinHeight: 60,
          dataRowMaxHeight: 72,
          columnSpacing: 24,
          horizontalMargin: 20,
          columns: const [
            DataColumn(label: Text('Cliente')),
            DataColumn(label: Text('Contato')),
            DataColumn(label: Text('Endereço')),
            DataColumn(label: Text('CPF/CNPJ')),
            DataColumn(label: Text('Ações')),
          ],
          rows: clientes.map((cliente) {
            final dataCriacao = DateFormat('dd/MM/yyyy').format(cliente.criadoEm);
            return DataRow(cells: [
              // Cliente
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cliente.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text("Cliente desde $dataCriacao", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              // Contato
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.email_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Flexible(child: Text(cliente.email, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.phone_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(cliente.telefone, style: const TextStyle(fontSize: 13)),
                    ]),
                  ],
                ),
              ),
              // Endereço
              DataCell(
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.orange[400]),
                    const SizedBox(width: 4),
                    Flexible(child: Text(cliente.endereco.isNotEmpty ? cliente.endereco : '—', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              // CPF/CNPJ
              DataCell(
                Text(cliente.cpfOuCnpj.isNotEmpty ? cliente.cpfOuCnpj : '—', style: const TextStyle(fontSize: 13)),
              ),
              // Ações
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: Colors.grey[700],
                      tooltip: "Editar",
                      onPressed: () => Navigator.pushNamed(context, '/cliente-formulario', arguments: cliente),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red[400],
                      tooltip: "Excluir",
                      onPressed: () => _confirmarExclusao(context, cliente, controller),
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // --- Confirmação ---
  void _confirmarExclusao(BuildContext context, Cliente cliente, ClienteController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Excluir Cliente?"),
        content: Text("Tem certeza que deseja remover ${cliente.nome}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              controller.excluir(cliente.id!);
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