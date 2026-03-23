import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../../dominio/entidades/usuario.dart';

class DrawerComum extends StatelessWidget {
  const DrawerComum({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();
    final rotaAtual = ModalRoute.of(context)?.settings.name;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Cabeçalho com Logo + Info do Usuário
          StreamBuilder<Usuario?>(
            stream: authController.usuarioAtual,
            builder: (context, snapshot) {
              final usuario = snapshot.data;
              final nome = usuario?.nome ?? '...';
              final funcao = usuario?.funcao ?? '';

              return Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 24,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo como avatar circular
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(Icons.format_paint, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 14),
                    // Nome do usuário logado
                    Text(
                      nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Cargo / Função
                    if (funcao.isNotEmpty)
                      Text(
                        funcao,
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Itens de Navegação (scrollable para evitar overflow)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(context, icon: Icons.dashboard_outlined, title: "Dashboard", route: '/home', rotaAtual: rotaAtual),
                _buildMenuItem(context, icon: Icons.people_outline, title: "Usuários", route: '/usuarios', rotaAtual: rotaAtual),
                _buildMenuItem(context, icon: Icons.person_outline, title: "Clientes", route: '/clientes', rotaAtual: rotaAtual),
                _buildMenuItem(context, icon: Icons.construction_outlined, title: "Obras", route: '/obras', rotaAtual: rotaAtual),
                _buildMenuItem(context, icon: Icons.request_quote_outlined, title: "Orçamentos", route: '/orcamentos', rotaAtual: rotaAtual),
                _buildMenuItem(context, icon: Icons.attach_money, title: "Financeiro", route: '/financeiro', rotaAtual: rotaAtual),
                _buildMenuItem(context, icon: Icons.bar_chart_outlined, title: "Relatórios", route: '/relatorios', rotaAtual: rotaAtual),
                _buildMenuItem(context, icon: Icons.settings_outlined, title: "Configurações", route: '/configuracoes', rotaAtual: rotaAtual),
              ],
            ),
          ),
          const Divider(height: 1),

          // Botão de Sair
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Sair do Sistema", style: TextStyle(color: Colors.red, fontSize: 14)),
            onTap: () async {
              await authController.sair();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    String? rotaAtual,
  }) {
    final selecionado = rotaAtual == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: selecionado ? Colors.orange.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: selecionado ? Colors.orange : Colors.grey[700], size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selecionado ? FontWeight.w600 : FontWeight.normal,
            color: selecionado ? Colors.orange[800] : Colors.grey[800],
          ),
        ),
        dense: true,
        onTap: () {
          Navigator.pop(context);
          if (rotaAtual != route) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}