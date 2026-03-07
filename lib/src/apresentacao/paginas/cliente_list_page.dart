import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dominio/entidades/cliente.dart';
import '../controllers/cliente_controller.dart';
import '../widgets/menu_lateral.dart'; // O widget que criamos antes

class ClienteListPage extends StatelessWidget {
  const ClienteListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClienteController>();

    return Scaffold(
      drawer: const MenuLateral(),
      appBar: AppBar(
        title: const Text("Clientes", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Gestão de Clientes", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Gerencie informações e histórico dos seus clientes.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            
            // Botão Novo Cliente (Estilo Dark conforme protótipo)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {}, // Implementar diálogo completo depois
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text("Novo Cliente"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Cards de Resumo
            _buildResumoCards(context),
            const SizedBox(height: 30),

            // Seção da Tabela
            _buildTabelaClientes(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCards(BuildContext context) {
    return Column(
      children: [
        _cardInformativo("Total de Clientes", "4", "3 ativos"),
        const SizedBox(height: 15),
        _cardInformativo("Clientes com Obras", "3", "Clientes ativos com projetos"),
        const SizedBox(height: 15),
        _cardInformativo("Total de Obras", "9", "Obras em todos os clientes"),
      ],
    );
  }

  Widget _cardInformativo(String titulo, String valor, String subtitulo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 10),
          Text(valor, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(subtitulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTabelaClientes(BuildContext context, ClienteController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: StreamBuilder<List<Cliente>>(
        stream: controller.listaClientes,
        builder: (context, snapshot) {
          final clientes = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Clientes Cadastrados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 25,
                  columns: const [
                    DataColumn(label: Text("Contato")),
                    DataColumn(label: Text("Localização")),
                    DataColumn(label: Text("Obras")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("")),
                  ],
                  rows: clientes.map((cliente) {
                    return DataRow(cells: [
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cliente.email ?? "Sem e-mail", style: const TextStyle(fontSize: 13)),
                          Text(cliente.telefone, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )),
                      DataCell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cliente.cidade ?? "Rio Verde", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(cliente.endereco ?? "", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      )),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
                        child: Text("${cliente.obrasCount} obra(s)", style: const TextStyle(fontSize: 11)),
                      )),
                      DataCell(_buildStatusBadge(cliente.status)),
                      DataCell(IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () {})),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(bool ativo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ativo ? Colors.black : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        ativo ? "Ativo" : "Inativo",
        style: TextStyle(color: ativo ? Colors.white : Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}