import 'package:flutter/material.dart';
import '../widgets/menu_lateral.dart';

class FinanceiroPage extends StatelessWidget {
  const FinanceiroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MenuLateral(),
      appBar: AppBar(
        title: const Text("Financeiro", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Gestão Financeira", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Controle receitas, despesas e fluxo de caixa das obras.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.attach_money),
                label: const Text("Nova Transação"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // O sifrão agora está escapado com \ para não dar erro
            _cardSaldo("Total de Receitas", "R\$ 8.450", Colors.green, Icons.trending_up),
            const SizedBox(height: 15),
            _cardSaldo("Total de Despesas", "R\$ 970", Colors.red, Icons.trending_down),
            const SizedBox(height: 15),
            _cardSaldo("Saldo", "R\$ 7.480", Colors.green, Icons.attach_money),
            const SizedBox(height: 15),
            _cardSaldo("Pendente", "R\$ -1.200", Colors.orange, Icons.calendar_today_outlined),
            
            const SizedBox(height: 30),

            _buildTabelaTransacoes(),
          ],
        ),
      ),
    );
  }

  Widget _cardSaldo(String titulo, String valor, Color cor, IconData icone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 8),
              Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cor)),
            ],
          ),
          Icon(icone, color: cor.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildTabelaTransacoes() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Transações", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Data")),
                DataColumn(label: Text("Tipo")),
                DataColumn(label: Text("Categoria")),
                DataColumn(label: Text("Descrição")),
              ],
              rows: [
                _buildDataRow("19/01/2024", "Receita", "Pagamento de Cliente", "Residência Silva"),
                _buildDataRow("17/01/2024", "Despesa", "Material", "Compra de tinta"),
                _buildDataRow("21/01/2024", "Despesa", "Combustível", "Deslocamento"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(String data, String tipo, String categoria, String desc) {
    bool isReceita = tipo == "Receita";
    return DataRow(cells: [
      DataCell(Text(data, style: const TextStyle(fontSize: 12))),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isReceita ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(tipo, style: TextStyle(color: isReceita ? Colors.white : Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
      )),
      DataCell(Text(categoria, style: const TextStyle(fontSize: 12))),
      DataCell(Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey))),
    ]);
  }
}