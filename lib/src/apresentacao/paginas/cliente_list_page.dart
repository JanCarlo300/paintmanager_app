import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dominio/entidades/cliente.dart';
import '../controllers/cliente_controller.dart';

class ClienteListPage extends StatelessWidget {
  const ClienteListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ClienteController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Meus Clientes")),
      body: StreamBuilder<List<Cliente>>(
        stream: controller.listaClientes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final clientes = snapshot.data ?? [];

          if (clientes.isEmpty) {
            return const Center(child: Text("Nenhum cliente cadastrado."));
          }

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              return ListTile(
                title: Text(cliente.nome),
                subtitle: Text(cliente.telefone),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => controller.removerCliente(cliente.id!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _exibirDialogoCadastro(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Função simples para abrir um popup de cadastro
  void _exibirDialogoCadastro(BuildContext context) {
    final nomeController = TextEditingController();
    final telefoneController = TextEditingController();
    final emailController = TextEditingController(); // Novo
    final enderecoController = TextEditingController(); // Novo

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Novo Cliente"),
        // SingleChildScrollView evita que o teclado cubra os campos em telas menores
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: "Nome *"),
              ),
              TextField(
                controller: telefoneController,
                decoration: const InputDecoration(labelText: "Telefone *"),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "E-mail"),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: enderecoController,
                decoration: const InputDecoration(labelText: "Endereço"),
                maxLines: 2, // Permite endereços mais longos
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
              // Validação simples: Nome e Telefone são obrigatórios
              if (nomeController.text.isNotEmpty &&
                  telefoneController.text.isNotEmpty) {
                final novoCliente = Cliente(
                  nome: nomeController.text,
                  telefone: telefoneController.text,
                  email: emailController.text.isEmpty
                      ? null
                      : emailController.text,
                  endereco: enderecoController.text.isEmpty
                      ? null
                      : enderecoController.text,
                );

                context.read<ClienteController>().salvarCliente(novoCliente);
                Navigator.pop(context);
              } else {
                // Alerta caso falte dados obrigatórios
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Preencha Nome e Telefone!")),
                );
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }
}
