import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/usuario.dart';
import '../controllers/usuario_controller.dart';
import '../widgets/drawer_comum.dart';

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

  @override
  Widget build(BuildContext context) {
    final controller = context.read<UsuarioController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: const DrawerComum(),
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text("Usuários", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<Usuario>>(
        stream: controller.usuarios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Erro ao carregar usuários."));
          }

          final todosUsuarios = snapshot.data ?? [];
          final usuariosFiltradosPorStatus = _filtrarPorStatus(todosUsuarios);
          final usuariosFiltrados = _filtrarPorTexto(usuariosFiltradosPorStatus);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                const Text("Gestão de Usuários", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text("Gerencie usuários e suas permissões no sistema.",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),

                // --- BOTÃO NOVO USUÁRIO ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _exibirDialogoUsuario(context),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text("Novo Usuário"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- FILTRO POR STATUS ---
                _buildFiltroChips(todosUsuarios),
                const SizedBox(height: 16),

                // --- BARRA DE BUSCA ---
                _buildBarraBusca(),
                const SizedBox(height: 8),

                // --- CONTADOR ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "${usuariosFiltrados.length} usuário(s) encontrado(s)",
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ),

                // --- LISTA DE CARDS ---
                if (usuariosFiltrados.isEmpty)
                  _buildVazio()
                else
                  ...usuariosFiltrados.map((u) => _buildUsuarioCard(u, controller)),
              ],
            ),
          );
        },
      ),
    );
  }

  // === FILTRO CHIPS ===
  Widget _buildFiltroChips(List<Usuario> todosUsuarios) {
    final qtdAtivos = todosUsuarios.where((u) => u.status).length;
    final qtdInativos = todosUsuarios.where((u) => !u.status).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filtroChip("Todos Ativos", FiltroUsuario.todosAtivos, qtdAtivos, Colors.green),
          const SizedBox(width: 8),
          _filtroChip("Inativos", FiltroUsuario.inativos, qtdInativos, Colors.grey),
        ],
      ),
    );
  }

  Widget _filtroChip(String label, FiltroUsuario filtro, int count, Color cor) {
    final selecionado = _filtroAtual == filtro;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(
            fontSize: 12,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
            color: selecionado ? Colors.white : Colors.grey[700],
          )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: selecionado ? Colors.white.withValues(alpha: 0.3) : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: selecionado ? Colors.white : Colors.grey[700]),
            ),
          ),
        ],
      ),
      selected: selecionado,
      selectedColor: cor,
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filtroAtual = filtro),
    );
  }

  // === BARRA DE BUSCA ===
  Widget _buildBarraBusca() {
    return SizedBox(
      height: 42,
      child: TextField(
        onChanged: (v) => setState(() => _termoBusca = v),
        decoration: InputDecoration(
          hintText: "Buscar por nome, e-mail ou função...",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black, width: 1.5),
          ),
        ),
      ),
    );
  }

  // === CARD DO USUÁRIO ===
  Widget _buildUsuarioCard(Usuario usuario, UsuarioController controller) {
    final dataCriacao = DateFormat('dd/MM/yyyy').format(usuario.criadoEm);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _mostrarOpcoes(context, usuario, controller),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome + Badges
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: usuario.status ? Colors.black : Colors.grey[400],
                      child: Text(
                        usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nome e data
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario.nome,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Desde $dataCriacao",
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    // Badges
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildFuncaoBadge(usuario.funcao),
                        const SizedBox(height: 4),
                        _badge(
                          usuario.status ? "Ativo" : "Inativo",
                          usuario.status ? Colors.green : Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // Info de contato
                Row(
                  children: [
                    Expanded(
                      child: _infoItem(Icons.email_outlined, usuario.email.isNotEmpty ? usuario.email : '—'),
                    ),
                    Expanded(
                      child: _infoItem(Icons.phone_outlined, usuario.telefone.isNotEmpty ? usuario.telefone : '—'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuncaoBadge(String funcao) {
    Color cor;
    switch (funcao) {
      case 'Administrador':
        cor = const Color(0xFFC04651);
      case 'Gerente':
        cor = Colors.orange;
      default:
        cor = Colors.black;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        funcao,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor),
      ),
    );
  }

  Widget _badge(String label, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // === BOTTOM SHEET COM OPÇÕES ===
  void _mostrarOpcoes(BuildContext context, Usuario usuario, UsuarioController controller) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              // Nome do usuário
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black,
                      child: Text(
                        usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(usuario.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                          Text(usuario.funcao, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Editar
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                ),
                title: const Text("Editar", style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text("Alterar dados do usuário", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _exibirDialogoUsuario(context, usuario: usuario);
                },
              ),
              // Inativar / Ativar
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (usuario.status ? Colors.red : Colors.green).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    usuario.status ? Icons.person_off_outlined : Icons.person_outlined,
                    color: usuario.status ? Colors.red : Colors.green,
                    size: 20,
                  ),
                ),
                title: Text(
                  usuario.status ? "Inativar" : "Ativar",
                  style: TextStyle(fontWeight: FontWeight.w500, color: usuario.status ? Colors.red : Colors.green),
                ),
                subtitle: Text(
                  usuario.status ? "O usuário perderá acesso ao sistema" : "Reativar acesso do usuário",
                  style: const TextStyle(fontSize: 12),
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
    final acao = usuario.status ? "Inativar" : "Ativar";
    final msg = usuario.status
        ? "O usuário ${usuario.nome} será inativado e perderá acesso ao sistema. Você pode reativá-lo pelo filtro 'Inativos'."
        : "O usuário ${usuario.nome} será reativado e voltará a ter acesso ao sistema.";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("$acao Usuário?"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.alternarStatus(usuario);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Usuário ${usuario.status ? 'inativado' : 'ativado'} com sucesso!"),
                  backgroundColor: usuario.status ? Colors.orange : Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: usuario.status ? Colors.red : Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(acao, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // === VAZIO ===
  Widget _buildVazio() {
    String mensagem;
    IconData icone;
    switch (_filtroAtual) {
      case FiltroUsuario.todosAtivos:
        mensagem = "Nenhum usuário ativo encontrado.";
        icone = Icons.person_outline;
      case FiltroUsuario.inativos:
        mensagem = "Nenhum usuário inativo.";
        icone = Icons.person_off_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icone, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(mensagem, style: TextStyle(color: Colors.grey[600], fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // === DIÁLOGO DE CRIAÇÃO / EDIÇÃO ===
  void _exibirDialogoUsuario(BuildContext context, {Usuario? usuario}) {
    final nomeController = TextEditingController(text: usuario?.nome);
    final emailController = TextEditingController(text: usuario?.email);
    final cpfController = TextEditingController(text: usuario?.cpf);
    final telefoneController = TextEditingController(text: usuario?.telefone);
    String funcaoSelecionada = usuario?.funcao ?? "Funcionário";
    bool statusAtivo = usuario?.status ?? true;

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
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: cpfController,
                  decoration: const InputDecoration(labelText: "CPF"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: telefoneController,
                  decoration: const InputDecoration(labelText: "Telefone"),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                
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
                  title: const Text("Status Ativo"),
                  value: statusAtivo,
                  onChanged: (val) {
                    setDialogState(() => statusAtivo = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                final novoUser = Usuario(
                  id: usuario?.id,
                  nome: nomeController.text,
                  email: emailController.text,
                  cpf: cpfController.text,
                  telefone: telefoneController.text,
                  funcao: funcaoSelecionada,
                  status: statusAtivo,
                  senha: usuario?.senha ?? cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                  primeiroAcesso: usuario?.primeiroAcesso ?? true,
                  criadoEm: usuario?.criadoEm ?? DateTime.now(),
                );
                context.read<UsuarioController>().salvar(novoUser);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text(
                "Salvar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}