import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'alterar_senha_page.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../apresentacao/widgets/drawer_comum.dart';
import '../../../../apresentacao/widgets/icone_modulo.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';
import '../../../../core/tema/tema_controller.dart';
import '../../../../core/validadores/validador_cpf.dart';

/// Configurações: dados da conta do usuário logado, troca de senha e
/// versão do app. Disponível para as 3 funções.
class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

  static String _formatarCpf(String cpf) {
    final d = ValidadorCpf.apenasDigitos(cpf);
    if (d.length != 11) return cpf;
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }

  static String _formatarTelefone(String telefone) {
    final d = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.length == 11) return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
    if (d.length == 10) return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
    return telefone;
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuarioLogado;
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      drawer: const DrawerComum(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Symbols.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Configurações'),
      ),
      body: usuario == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(Espaco.margemTela),
              children: [
                const _TituloSecao('Minha conta'),
                CardApp(
                  padding: const EdgeInsets.symmetric(vertical: Espaco.x2),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: c.primary,
                          foregroundColor: c.onPrimary,
                          child: Text(usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : '?'),
                        ),
                        title: Text(usuario.nome, style: texto.titleMedium),
                        subtitle: Text(usuario.funcao, style: texto.bodyMedium?.copyWith(color: c.primary)),
                      ),
                      const Divider(indent: Espaco.x4, endIndent: Espaco.x4),
                      _LinhaDado(icone: Symbols.badge_rounded, rotulo: 'CPF', valor: _formatarCpf(usuario.cpf)),
                      _LinhaDado(icone: Symbols.mail_rounded, rotulo: 'E-mail', valor: usuario.email),
                      if (usuario.telefone.isNotEmpty)
                        _LinhaDado(icone: Symbols.call_rounded, rotulo: 'Telefone', valor: _formatarTelefone(usuario.telefone)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Espaco.x1, Espaco.x2, Espaco.x1, 0),
                  child: Text(
                    usuario.funcao == 'Administrador'
                        ? 'Para corrigir seus dados, use a tela Usuários.'
                        : 'Para corrigir seus dados, fale com o administrador.',
                    style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0),
                  ),
                ),
                const SizedBox(height: Espaco.x6),
                const _TituloSecao('Aparência'),
                const CardApp(child: _SeletorAparencia()),
                const SizedBox(height: Espaco.x6),
                const _TituloSecao('Segurança'),
                CardApp(
                  padding: EdgeInsets.zero,
                  aoTocar: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AlterarSenhaPage()),
                  ),
                  child: const ListTile(
                    leading: IconeModulo(Symbols.lock_rounded),
                    title: Text('Alterar senha'),
                    trailing: Icon(Symbols.chevron_right_rounded),
                  ),
                ),
                const SizedBox(height: Espaco.x6),
                const _TituloSecao('Sobre'),
                CardApp(
                  padding: EdgeInsets.zero,
                  child: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final versao = snapshot.data?.version;
                      return ListTile(
                        leading: const IconeModulo(Symbols.info_rounded),
                        title: const Text('PaintManager'),
                        subtitle: Text(
                          versao == null ? 'Versão —' : 'Versão $versao',
                          style: texto.bodyMedium?.copyWith(color: c.inkMuted),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

/// Automático (segue o celular), Claro ou Escuro. A escolha fica salva no
/// aparelho pelo TemaController e vale assim que é tocada.
class _SeletorAparencia extends StatelessWidget {
  const _SeletorAparencia();

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaController>();
    final c = context.cores;
    final legenda = Theme.of(context).textTheme.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0);

    // Lista de opções (e não 3 botões lado a lado): não estoura com a
    // fonte grande do celular.
    Widget opcao(ThemeMode modo, IconData icone, String titulo, String descricao) => RadioListTile<ThemeMode>(
          value: modo,
          contentPadding: EdgeInsets.zero,
          secondary: Icon(icone, color: tema.modo == modo ? c.primary : c.inkMuted),
          title: Text(titulo),
          subtitle: Text(descricao, style: legenda),
        );

    return RadioGroup<ThemeMode>(
      groupValue: tema.modo,
      onChanged: (modo) {
        if (modo != null) tema.definir(modo);
      },
      child: Column(
        children: [
          opcao(ThemeMode.system, Symbols.brightness_auto_rounded, 'Automático', 'Acompanha o tema do celular'),
          opcao(ThemeMode.light, Symbols.light_mode_rounded, 'Claro', 'Sempre claro'),
          opcao(ThemeMode.dark, Symbols.dark_mode_rounded, 'Escuro', 'Sempre escuro'),
        ],
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  final String texto;
  const _TituloSecao(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Espaco.x1, bottom: Espaco.x2),
      child: Text(
        texto.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.cores.inkMuted),
      ),
    );
  }
}

class _LinhaDado extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;
  const _LinhaDado({required this.icone, required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    return ListTile(
      dense: true,
      leading: Icon(icone, color: c.inkMuted),
      title: Text(rotulo, style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0)),
      subtitle: Text(valor, style: texto.bodyLarge),
    );
  }
}
