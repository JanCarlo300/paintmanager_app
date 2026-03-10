import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();

    return Drawer(
      child: Column(
        children: [
          // Cabeçalho do Sidebar com Identidade Visual
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.format_paint, color: Colors.black, size: 40),
            ),
            accountName: Text("PaintManager", style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text("Sistema de Gestão de Pintura"),
          ),

          // Itens de Navegação conforme sua regra de negócio
          _itemMenu(context, Icons.dashboard, "Dashboard", '/home'),
          _itemMenu(context, Icons.person, "Clientes", '/clientes'),
          _itemMenu(context, Icons.group, "Equipe / Usuários", '/usuarios'),
          _itemMenu(context, Icons.construction, "Obras", '/obras'),
          _itemMenu(context, Icons.attach_money, "Financeiro", '/financeiro'),

          const Spacer(), // Empurra o botão de sair para o final
          const Divider(),

          // Botão de Sair (Voltar para o Login)
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Sair do Sistema", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              await authController.sair();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _itemMenu(BuildContext context, IconData icone, String titulo, String rota) {
    return ListTile(
      leading: Icon(icone),
      title: Text(titulo),
      onTap: () {
        Navigator.pop(context); // Fecha o sidebar
        Navigator.pushReplacementNamed(context, rota);
      },
    );
  }
}