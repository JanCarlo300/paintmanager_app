import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/usuario.dart';
import '../controllers/usuario_controller.dart';
import '../../../../apresentacao/widgets/lista_paginada.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../apresentacao/widgets/chips_filtro_status.dart';
import '../../../../apresentacao/widgets/drawer_comum.dart';
import '../../../../apresentacao/widgets/tela_vazia.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';
import '../../../../core/validadores/validador_cpf.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Filtros disponíveis na tela de usuários
enum FiltroUsuario { todosAtivos, inativos }

class UsuarioListPage extends StatefulWidget {
  const UsuarioListPage({super.key});

  @override
  State<UsuarioListPage> createState() => _UsuarioListPageState();
}

class _UsuarioListPageState extends State<UsuarioListPage> {
  String _termoBusca = '';
  FiltroUsuario _filtroAtual = FiltroUsuario.todosAtivos;

  @override
  void initState() {
    super.initState();
    // Carrega a lista de usuários ao abrir a página
    Future.microtask(() {
      if (!mounted) return;
      context.read<UsuarioController>().carregarUsuarios();
    });
  }

  /// Aplica filtro de busca por texto
  List<Usuario> _filtrarPorTexto(List<Usuario> usuarios) {
    if (_termoBusca.isEmpty) return usuarios;
    final termo = _termoBusca.toLowerCase();
    return usuarios.where((u) =>
      u.nome.toLowerCase().contains(termo) ||
      u.email.toLowerCase().contains(termo) ||
      u.funcao.toLowerCase().contains(termo)
    ).toList();
  }

  /// Aplica filtro por status (ativo/inativo)
  List<Usuario> _filtrarPorStatus(List<Usuario> usuarios) {
    switch (_filtroAtual) {
      case FiltroUsuario.todosAtivos:
        return usuarios.where((u) => u.status).toList();
      case FiltroUsuario.inativos:
        return usuarios.where((u) => !u.status).toList();
    }
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Symbols.menu_rounded),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: const Text("Usuários"),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UsuarioController>();
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    if (controller.carregando) {
      return Scaffold(
        drawer: const DrawerComum(),
        appBar: _appBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final todosUsuarios = controller.usuarios;
    final usuariosFiltradosPorStatus = _filtrarPorStatus(todosUsuarios);
    final usuariosFiltrados = _filtrarPorTexto(usuariosFiltradosPorStatus);

    return Scaffold(
      drawer: const DrawerComum(),
      appBar: _appBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Espaco.margemTela),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Text("Gestão de Usuários", style: texto.headlineMedium),
            const SizedBox(height: Espaco.x1),
            Text(
              "Gerencie usuários e suas permissões no sistema.",
              style: texto.bodyMedium?.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: Espaco.x4),

            // --- BOTÃO NOVO USUÁRIO ---
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _exibirDialogoUsuario(context),
                icon: const Icon(Symbols.person_add_rounded, size: TamanhoIcone.pequeno),
                label: const Text("Novo Usuário"),
              ),
            ),
            const SizedBox(height: Espaco.x5),

            // --- FILTRO POR STATUS ---
            ChipsFiltroStatus<FiltroUsuario>(
              opcoes: [
                OpcaoStatus("Todos Ativos", FiltroUsuario.todosAtivos,
                    todosUsuarios.where((u) => u.status).length, c.success),
                OpcaoStatus("Inativos", FiltroUsuario.inativos,
                    todosUsuarios.where((u) => !u.status).length, c.inkMuted),
              ],
              selecionado: _filtroAtual,
              aoSelecionar: (f) => setState(() => _filtroAtual = f),
            ),
            const SizedBox(height: Espaco.x4),

            // --- BARRA DE BUSCA ---
            TextField(
              onChanged: (v) => setState(() => _termoBusca = v),
              decoration: const InputDecoration(
                hintText: "Buscar por nome, e-mail ou função...",
                prefixIcon: Icon(Symbols.search_rounded, size: TamanhoIcone.pequeno),
              ),
            ),
            const SizedBox(height: Espaco.x2),

            // --- CONTADOR ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Espaco.x2),
              child: Text(
                "${usuariosFiltrados.length} usuário(s) encontrado(s)",
                style: texto.bodyMedium?.copyWith(color: c.inkMuted),
              ),
            ),

            // --- LISTA DE CARDS ---
            if (usuariosFiltrados.isEmpty)
              _buildVazio()
            else
              ListaPaginada<Usuario>(
                key: ValueKey('$_termoBusca|$_filtroAtual'),
                itens: usuariosFiltrados,
                construir: (u) => _buildUsuarioCard(u, controller),
              ),
          ],
        ),
      ),
    );
  }

  // === CARD DO USUÁRIO ===
  Widget _buildUsuarioCard(Usuario usuario, UsuarioController controller) {
    final dataCriacao = DateFormat('dd/MM/yyyy').format(usuario.criadoEm);
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.x3),
      child: CardApp(
        aoTocar: () => _mostrarOpcoes(context, usuario, controller),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome + Badges
            Row(
              children: [
                _avatar(usuario, raio: 20),
                const SizedBox(width: Espaco.x3),
                // Nome e data
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario.nome,
                        style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Desde $dataCriacao",
                        style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0),
                      ),
                    ],
                  ),
                ),
                // Badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildFuncaoBadge(usuario.funcao),
                    const SizedBox(height: Espaco.x1),
                    usuario.status
                        ? _badge("Ativo", c.success, c.successSoft)
                        : _badge("Inativo", c.inkMuted, c.surfaceSunken),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Espaco.x3),
            const Divider(height: 1),
            const SizedBox(height: Espaco.x3),
            // Info de contato
            Row(
              children: [
                Expanded(
                  child: _infoItem(Symbols.mail_rounded, usuario.email.isNotEmpty ? usuario.email : '—'),
                ),
                Expanded(
                  child: _infoItem(Symbols.call_rounded, usuario.telefone.isNotEmpty ? usuario.telefone : '—'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Inicial do nome num círculo: terracota se ativo, apagado se inativo.
  Widget _avatar(Usuario usuario, {required double raio}) {
    final c = context.cores;
    return CircleAvatar(
      radius: raio,
      backgroundColor: usuario.status ? c.primary : c.disabledBg,
      child: Text(
        usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : '?',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: usuario.status ? c.onPrimary : c.disabledInk,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _buildFuncaoBadge(String funcao) {
    final c = context.cores;
    return switch (funcao) {
      'Administrador' => _badge(funcao, c.secondary, c.errorSoft),
      'Gerente' => _badge(funcao, c.primary, c.primarySoft),
      _ => _badge(funcao, c.inkMuted, c.surfaceSunken),
    };
  }

  Widget _badge(String label, Color cor, Color fundo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Espaco.x2, vertical: 3),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(Raio.pilula),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cor, letterSpacing: 0),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    final c = context.cores;
    return Row(
      children: [
        Icon(icon, size: 16, color: c.inkMuted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.inkMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Ícone de ação num quadrado arredondado com fundo suave.
  Widget _iconeAcao(IconData icone, Color cor, Color fundo) {
    return Container(
      padding: const EdgeInsets.all(Espaco.x2),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(Raio.campo)),
      child: Icon(icone, color: cor, size: TamanhoIcone.pequeno),
    );
  }

  // === BOTTOM SHEET COM OPÇÕES ===
  void _mostrarOpcoes(BuildContext context, Usuario usuario, UsuarioController controller) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final corStatus = usuario.status ? c.error : c.success;
    final fundoStatus = usuario.status ? c.errorSoft : c.successSoft;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Espaco.x2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: Espaco.x3),
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
              // Nome do usuário
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Espaco.x5, vertical: Espaco.x2),
                child: Row(
                  children: [
                    _avatar(usuario, raio: 18),
                    const SizedBox(width: Espaco.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(usuario.nome, style: texto.titleMedium, overflow: TextOverflow.ellipsis),
                          Text(usuario.funcao, style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Editar
              ListTile(
                leading: _iconeAcao(Symbols.edit_rounded, c.info, c.infoSoft),
                title: const Text("Editar"),
                subtitle: Text("Alterar dados do usuário", style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0)),
                onTap: () {
                  Navigator.pop(ctx);
                  _exibirDialogoUsuario(context, usuario: usuario);
                },
              ),
              // Inativar / Ativar
              ListTile(
                leading: _iconeAcao(
                  usuario.status ? Symbols.person_off_rounded : Symbols.person_rounded,
                  corStatus,
                  fundoStatus,
                ),
                title: Text(
                  usuario.status ? "Inativar" : "Ativar",
                  style: TextStyle(color: corStatus),
                ),
                subtitle: Text(
                  usuario.status ? "O usuário perderá acesso ao sistema" : "Reativar acesso do usuário",
                  style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmarAlteracaoStatus(context, usuario, controller);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === CONFIRMAÇÃO DE INATIVAÇÃO / ATIVAÇÃO ===
  void _confirmarAlteracaoStatus(BuildContext context, Usuario usuario, UsuarioController controller) {
    final c = context.cores;
    final acao = usuario.status ? "Inativar" : "Ativar";
    final msg = usuario.status
        ? "O usuário ${usuario.nome} será inativado e perderá acesso ao sistema. Você pode reativá-lo pelo filtro 'Inativos'."
        : "O usuário ${usuario.nome} será reativado e voltará a ter acesso ao sistema.";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("$acao Usuário?"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: c.inkMuted),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () {
              controller.alternarStatus(usuario);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Usuário ${usuario.status ? 'inativado' : 'ativado'} com sucesso!"),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: usuario.status ? c.error : c.success,
              foregroundColor: usuario.status ? c.onError : c.onPrimary,
            ),
            child: Text(acao),
          ),
        ],
      ),
    );
  }

  // === VAZIO ===
  Widget _buildVazio() {
    final (titulo, texto) = switch (_filtroAtual) {
      FiltroUsuario.todosAtivos => ("Nenhum usuário ativo encontrado", "Confira a busca ou cadastre um novo usuário."),
      FiltroUsuario.inativos => ("Nenhum usuário inativo", "Usuários inativados aparecem aqui."),
    };
    return TelaVazia(ilustracao: IlustracaoVazia.busca, titulo: titulo, texto: texto);
  }

  // === DIÁLOGO DE CRIAÇÃO / EDIÇÃO ===
  void _exibirDialogoUsuario(BuildContext context, {Usuario? usuario}) {
    final nomeController = TextEditingController(text: usuario?.nome);
    final emailController = TextEditingController(text: usuario?.email);
    final cpfMask = MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {"#": RegExp(r'[0-9]')},
      initialText: usuario?.cpf ?? '',
    );
    final cpfController = TextEditingController(text: cpfMask.getMaskedText());
    final telefoneController = TextEditingController(text: usuario?.telefone);
    String funcaoSelecionada = usuario?.funcao ?? "Funcionário";
    bool statusAtivo = usuario?.status ?? true;
    String? erroCpf;
    String? erroGeral;
    bool salvando = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(usuario == null ? "Novo Usuário" : "Editar Usuário"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: "Nome"),
                ),
                const SizedBox(height: Espaco.x3),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: Espaco.x3),
                TextField(
                  controller: cpfController,
                  decoration: InputDecoration(labelText: "CPF", errorText: erroCpf),
                  keyboardType: TextInputType.number,
                  inputFormatters: [cpfMask],
                  onChanged: (_) {
                    if (erroCpf != null) setDialogState(() => erroCpf = null);
                  },
                ),
                const SizedBox(height: Espaco.x3),
                TextField(
                  controller: telefoneController,
                  decoration: const InputDecoration(labelText: "Telefone"),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: Espaco.x3),

                DropdownButtonFormField<String>(
                  initialValue: funcaoSelecionada,
                  items: ["Funcionário", "Gerente", "Administrador"]
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() => funcaoSelecionada = val!);
                  },
                  decoration: const InputDecoration(labelText: "Função"),
                ),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Status Ativo"),
                  value: statusAtivo,
                  onChanged: (val) {
                    setDialogState(() => statusAtivo = val);
                  },
                ),
                if (erroGeral != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Espaco.x2),
                    child: Text(
                      erroGeral!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.cores.error),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: salvando ? null : () async {
                final erro = ValidadorCpf.mensagemErro(cpfController.text);
                if (erro != null) {
                  setDialogState(() => erroCpf = erro);
                  return;
                }
                final novoUser = Usuario(
                  id: usuario?.id,
                  authId: usuario?.authId,
                  nome: nomeController.text,
                  email: emailController.text,
                  // O login busca o CPF só com números; com máscara o usuário não entraria.
                  cpf: ValidadorCpf.apenasDigitos(cpfController.text),
                  telefone: telefoneController.text,
                  funcao: funcaoSelecionada,
                  status: statusAtivo,
                  primeiroAcesso: usuario?.primeiroAcesso ?? true,
                  criadoEm: usuario?.criadoEm ?? DateTime.now(),
                );
                setDialogState(() => salvando = true);
                try {
                  await context.read<UsuarioController>().salvar(novoUser);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  setDialogState(() {
                    salvando = false;
                    erroGeral = '$e';
                  });
                }
              },
              child: Text(salvando ? "Salvando..." : "Salvar"),
            ),
          ],
        ),
      ),
    );
  }
}
