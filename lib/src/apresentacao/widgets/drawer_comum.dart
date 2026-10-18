import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../modules/auth/apresentacao/controllers/auth_controller.dart';
import '../../core/tema/cores_app.dart';
import '../../core/tema/medidas_app.dart';
import 'logo_app.dart';

class DrawerComum extends StatelessWidget {
  const DrawerComum({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final usuarioLogado = authController.usuarioLogado;
    final funcao = usuarioLogado?.funcao ?? '';
    final rotaAtual = ModalRoute.of(context)?.settings.name;
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Drawer(
      child: Column(
        children: [
          // Cabeçalho com Logo + Info do Usuário
          Builder(
            builder: (context) {
              final nome = usuarioLogado?.nome ?? '...';

              return Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + Espaco.x6,
                  bottom: Espaco.x5,
                  left: Espaco.x5,
                  right: Espaco.x5,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Assinatura do manual da marca (ícone + nome do app)
                    AssinaturaApp(
                      tamanhoLogo: 40,
                      estilo: texto.titleLarge,
                    ),
                    const SizedBox(height: Espaco.x4),
                    // Nome do usuário logado
                    Text(
                      nome,
                      style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    // Cargo / Função
                    if (funcao.isNotEmpty)
                      Text(funcao, style: texto.bodySmall?.copyWith(color: c.primary)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: Espaco.x2),

          // Itens de Navegação (scrollable para evitar overflow), filtrados por função.
          // Ordem do manual da marca: Usuários perto do fim, antes de Configurações.
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (funcao != 'Funcionário')
                  _buildMenuItem(context, icon: Symbols.dashboard_rounded, title: "Resumo Geral", route: '/home', rotaAtual: rotaAtual),
                if (funcao != 'Funcionário')
                  _buildMenuItem(context, icon: Symbols.group_rounded, title: "Clientes", route: '/clientes', rotaAtual: rotaAtual),
                _buildMenuItem(context, icon: Symbols.construction_rounded, title: "Obras", route: '/obras', rotaAtual: rotaAtual),
                if (funcao != 'Funcionário')
                  _buildMenuItem(context, icon: Symbols.request_quote_rounded, title: "Orçamentos", route: '/orcamentos', rotaAtual: rotaAtual),
                if (funcao != 'Funcionário')
                  _buildMenuItem(context, icon: Symbols.account_balance_wallet_rounded, title: "Financeiro", route: '/financeiro', rotaAtual: rotaAtual),
                if (funcao != 'Funcionário')
                  _buildMenuItem(context, icon: Symbols.bar_chart_rounded, title: "Relatórios", route: '/relatorios', rotaAtual: rotaAtual),
                if (funcao == 'Administrador')
                  _buildMenuItem(context, icon: Symbols.manage_accounts_rounded, title: "Usuários", route: '/usuarios', rotaAtual: rotaAtual),
                _buildMenuItem(context, icon: Symbols.settings_rounded, title: "Configurações", route: '/configuracoes', rotaAtual: rotaAtual),
              ],
            ),
          ),
          const Divider(height: 1),

          // Botão de Sair
          ListTile(
            leading: Icon(Symbols.logout_rounded, color: c.error),
            title: Text(
              "Sair do Sistema",
              style: texto.bodyMedium?.copyWith(color: c.error, fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              await authController.sair();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
          ),
          const SizedBox(height: Espaco.x4),
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
    final c = context.cores;

    // Item ativo: ícone preenchido em primary sobre primarySoft (manual da marca).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Espaco.x2, vertical: 2),
      child: ListTile(
        selected: selecionado,
        leading: Icon(
          icon,
          fill: selecionado ? 1 : 0,
          color: selecionado ? c.primary : c.inkMuted,
          size: TamanhoIcone.medio,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
                color: selecionado ? c.primary : c.ink,
              ),
        ),
        dense: true,
        onTap: () {
          Navigator.pop(context);
          if (rotaAtual == route) return;

          // Mantém a tela inicial do usuário na base da pilha: o botão voltar
          // do Android leva de volta a ela e só ali fecha o app.
          final funcao = context.read<AuthController>().usuarioLogado?.funcao ?? '';
          final inicial = rotaInicialParaFuncao(funcao);
          bool ehBase(Route<dynamic> r) => r.settings.name == inicial || r.isFirst;

          if (route == inicial) {
            Navigator.popUntil(context, ehBase);
          } else {
            Navigator.pushNamedAndRemoveUntil(context, route, ehBase);
          }
        },
      ),
    );
  }
}
