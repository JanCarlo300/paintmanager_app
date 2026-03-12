import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cliente_controller.dart';
import '../controllers/usuario_controller.dart';
import '../widgets/drawer_comum.dart'; 

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text("PaintManager", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false, 
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Lógica de atualização opcional
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Bem-vindo de volta!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text("Aqui está o resumo do seu negócio hoje.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      "Clientes",
                      Icons.people,
                      Colors.blue,
                      context.watch<ClienteController>().clientes,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      "Equipe",
                      Icons.engineering,
                      Colors.orange,
                      context.watch<UsuarioController>().usuarios, 
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              const Text("Atalhos Rápidos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildShortcutItem(context, "Gerenciar Clientes", Icons.person_search, '/clientes'),
              _buildShortcutItem(context, "Equipe e Usuários", Icons.group, '/usuarios'),
              _buildShortcutItem(context, "Gestão de Obras", Icons.construction, '/obras'),
              _buildShortcutItem(context, "Relatório Financeiro", Icons.bar_chart, '/financeiro'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, IconData icon, Color color, Stream<List<dynamic>> stream) {
    return StreamBuilder<List<dynamic>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), 
                blurRadius: 10,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 12),
              Text(count.toString(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShortcutItem(BuildContext context, String title, IconData icon, String route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.pushReplacementNamed(context, route), 
      ),
    );
  }
}