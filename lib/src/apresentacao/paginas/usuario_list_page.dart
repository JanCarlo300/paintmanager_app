import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/usuario.dart';
import '../controllers/usuario_controller.dart';
import '../widgets/drawer_comum.dart';

class UsuarioListPage extends StatelessWidget {
  const UsuarioListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UsuarioController>();

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
        title: const Text("Usuários", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Gestão de Usuários",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Gerencie usuários e suas permissões no sistema.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _exibirDialogoUsuario(context),
                icon: const Icon(Icons.person_add_outlined),
                label: const Text("Novo Usuário"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A0A0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildTabelaUsuarios(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaUsuarios(
    BuildContext context,
    UsuarioController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: StreamBuilder<List<Usuario>>(
        stream: controller.usuarios, 
        builder: (context, snapshot) {
          final usuarios = snapshot.data ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "${usuarios.length} usuário(s) encontrado(s)",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Nome")),
                    DataColumn(label: Text("Função")),
                    DataColumn(label: Text("Status")),
                    DataColumn(label: Text("Criado em")),
                    DataColumn(label: Text("Ações")),
                  ],
                  rows: usuarios.map((user) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(_buildFuncaoBadge(user.funcao)),
                        DataCell(_buildStatusBadge(user.status)),
                        DataCell(
                          Text(DateFormat('dd/MM/yyyy').format(user.criadoEm)),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _exibirDialogoUsuario(
                                  context,
                                  usuario: user,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  user.status
                                      ? Icons.block_flipped
                                      : Icons.check_circle_outline,
                                  size: 20,
                                  color: user.status ? Colors.orange : Colors.green,
                                ),
                                tooltip: user.status ? "Inativar Usuário" : "Ativar Usuário",
                                onPressed: () => controller.alternarStatus(user),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFuncaoBadge(String funcao) {
    Color cor = funcao == "Administrador" ? const Color(0xFFC04651) : Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        funcao,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool ativo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ativo ? Colors.black : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        ativo ? "Ativo" : "Inativo",
        style: TextStyle(
          color: ativo ? Colors.white : Colors.black54,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

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
                
                // CORREÇÃO: initialValue aplicado conforme o aviso de depreciação
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