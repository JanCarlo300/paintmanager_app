import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/obra.dart';
import '../controllers/obra_controller.dart';
import '../widgets/drawer_comum.dart';

class ObraListPage extends StatefulWidget {
  const ObraListPage({super.key});

  @override
  State<ObraListPage> createState() => _ObraListPageState();
}

class _ObraListPageState extends State<ObraListPage> {
  String _termoBusca = '';

  List<Obra> _filtrar(List<Obra> obras) {
    if (_termoBusca.isEmpty) return obras;
    final termo = _termoBusca.toLowerCase();
    return obras.where((o) =>
      o.tituloDaObra.toLowerCase().contains(termo) ||
      o.clienteNome.toLowerCase().contains(termo) ||
      o.status.toLowerCase().contains(termo)
    ).toList();
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'Em Andamento': return Colors.green;
      case 'Pausada': return Colors.orange;
      case 'Concluída': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _iconeStatus(String status) {
    switch (status) {
      case 'Em Andamento': return Icons.play_circle_outline;
      case 'Pausada': return Icons.pause_circle_outline;
      case 'Concluída': return Icons.check_circle_outline;
      default: return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ObraController>();
    final formatoData = DateFormat('dd/MM/yyyy');
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
        title: const Text("Obras", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<Obra>>(
        stream: controller.obras,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          final todas = snapshot.data ?? [];
          final filtradas = _filtrar(todas);
          final emAndamento = todas.where((o) => o.status == 'Em Andamento').length;
          final concluidas = todas.where((o) => o.status == 'Concluída').length;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                const Text("Gestão de Obras", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Acompanhe o progresso de cada serviço.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(
                  width: isWide ? null : double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/obra-formulario'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Nova Obra"),
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
                _buildSummaryRow(todas.length, emAndamento, concluidas),
                const SizedBox(height: 24),

                // --- BUSCA ---
                TextField(
                  onChanged: (v) => setState(() => _termoBusca = v),
                  decoration: InputDecoration(
                    hintText: "Buscar obras...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[200]!)),
                  ),
                ),
                const SizedBox(height: 20),

                // --- LISTA DE CARDS ---
                if (filtradas.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.construction_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text("Nenhuma obra encontrada.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtradas.map((obra) => _buildObraCard(obra, formatoData)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(int total, int emAndamento, int concluidas) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(width: double.infinity, child: _buildSummaryCard("Total", total.toString(), Colors.blue)),
        SizedBox(width: double.infinity, child: Row(children: [
          Expanded(child: _buildSummaryCard("Em Andamento", emAndamento.toString(), Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildSummaryCard("Concluídas", concluidas.toString(), Colors.blue.shade800)),
        ])),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        border: Border(top: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildObraCard(Obra obra, DateFormat formatoData) {
    final cor = _corStatus(obra.status);
    final progresso = obra.progresso / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(context, '/obra-detalhes', arguments: obra),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(obra.tituloDaObra, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconeStatus(obra.status), size: 14, color: cor),
                        const SizedBox(width: 4),
                        Text(obra.status, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Cliente
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(obra.clienteNome, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),

              // Endereço
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(obra.endereco, style: TextStyle(color: Colors.grey[600], fontSize: 13), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Datas
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text("${formatoData.format(obra.dataInicio)} → ${formatoData.format(obra.dataPrevisaoTermino)}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),

              // Barra de progresso
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progresso,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(cor),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text("${obra.progresso.toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
