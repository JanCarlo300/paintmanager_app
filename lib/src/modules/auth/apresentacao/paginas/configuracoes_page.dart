import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'alterar_senha_page.dart';
import '../../../../apresentacao/widgets/drawer_comum.dart';
import '../../../../core/tema/paleta_sahara.dart';
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

    return Scaffold(
      backgroundColor: PaletaSahara.background,
      drawer: const DrawerComum(),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Configurações', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: PaletaSahara.cardSurface,
        foregroundColor: PaletaSahara.onSurface,
        elevation: 0.5,
      ),
      body: usuario == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _TituloSecao('Minha conta'),
                Card(
                  color: PaletaSahara.cardSurface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: PaletaSahara.primary,
                            foregroundColor: Colors.white,
                            child: Text(usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : '?'),
                          ),
                          title: Text(usuario.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(usuario.funcao),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _LinhaDado(icone: Icons.badge_outlined, rotulo: 'CPF', valor: _formatarCpf(usuario.cpf)),
                        _LinhaDado(icone: Icons.email_outlined, rotulo: 'E-mail', valor: usuario.email),
                        if (usuario.telefone.isNotEmpty)
                          _LinhaDado(icone: Icons.phone_outlined, rotulo: 'Telefone', valor: _formatarTelefone(usuario.telefone)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Text(
                    usuario.funcao == 'Administrador'
                        ? 'Para corrigir seus dados, use a tela Usuários.'
                        : 'Para corrigir seus dados, fale com o administrador.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 24),
                const _TituloSecao('Segurança'),
                Card(
                  color: PaletaSahara.cardSurface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline, color: PaletaSahara.primary),
                    title: const Text('Alterar senha'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AlterarSenhaPage()),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const _TituloSecao('Sobre'),
                Card(
                  color: PaletaSahara.cardSurface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final versao = snapshot.data?.version;
                      return ListTile(
                        leading: const Icon(Icons.info_outline, color: PaletaSahara.primary),
                        title: const Text('PaintManager'),
                        subtitle: Text(versao == null ? 'Versão —' : 'Versão $versao'),
                      );
                    },
                  ),
                ),
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
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        texto.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Colors.grey[600]),
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
    return ListTile(
      dense: true,
      leading: Icon(icone, color: Colors.grey[600]),
      title: Text(rotulo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      subtitle: Text(valor, style: const TextStyle(fontSize: 15, color: PaletaSahara.onSurface)),
    );
  }
}
