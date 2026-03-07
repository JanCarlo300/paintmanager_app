import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    // Pegamos a rota atual para destacar o item selecionado
    String? rotaAtual = ModalRoute.of(context)?.settings.name;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // 1. Cabeçalho com Logo e Nome do App
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.format_paint, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "PaintManager",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // 2. Informações do Usuário Logado
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "João Silva",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "admin@pinturas.com",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Administrador",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // 3. Lista de Navegação
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _itemMenu(context, Icons.bar_chart, "Dashboard", "/home", rotaAtual == "/home"),
                _itemMenu(context, Icons.people_outline, "Usuários", "/usuarios", rotaAtual == "/usuarios"),
                _itemMenu(context, Icons.person_outline, "Clientes", "/clientes", rotaAtual == "/clientes"),
                _itemMenu(context, Icons.business, "Obras", "/obras", rotaAtual == "/obras"),
                _itemMenu(context, Icons.description_outlined, "Orçamentos", "/orcamentos", rotaAtual == "/orcamentos"),
                _itemMenu(context, Icons.attach_money, "Financeiro", "/financeiro", rotaAtual == "/financeiro"),
                _itemMenu(context, Icons.analytics_outlined, "Relatórios", "/relatorios", rotaAtual == "/relatorios"),
                _itemMenu(context, Icons.settings_outlined, "Configurações", "/configuracoes", rotaAtual == "/configuracoes"),
              ],
            ),
          ),

          // 4. Botão Sair no Rodapé
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              onTap: () {
                context.read<AuthController>().sair();
                Navigator.pushReplacementNamed(context, '/');
              },
              leading: const Icon(Icons.logout, color: Colors.black),
              title: const Text("Sair", style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemMenu(BuildContext context, IconData icone, String titulo, String rota, bool selecionado) {
    return ListTile(
      leading: Icon(icone, color: selecionado ? Colors.black : Colors.grey[600]),
      title: Text(
        titulo,
        style: TextStyle(
          color: selecionado ? Colors.black : Colors.grey[800],
          fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selecionado,
      selectedTileColor: Colors.grey[100], // Fundo cinza claro para o item ativo
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        if (!selecionado) {
          Navigator.pushReplacementNamed(context, rota);
        } else {
          Navigator.pop(context);
        }
      },
    );
  }
}