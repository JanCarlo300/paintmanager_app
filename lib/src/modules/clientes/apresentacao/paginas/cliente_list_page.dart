import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dominio/entidades/cliente.dart';
import '../controllers/cliente_controller.dart';
import '../../../obras/apresentacao/controllers/obra_controller.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../apresentacao/widgets/chips_filtro_status.dart';
import '../../../../apresentacao/widgets/drawer_comum.dart';
import '../../../../apresentacao/widgets/tela_vazia.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';

/// Filtros disponíveis na tela de clientes
enum FiltroCliente { comObraAtiva, todosAtivos, inativos }

class ClienteListPage extends StatefulWidget {
  const ClienteListPage({super.key});

  @override
  State<ClienteListPage> createState() => _ClienteListPageState();
}

class _ClienteListPageState extends State<ClienteListPage> {
  String _termoBusca = '';
  FiltroCliente _filtroAtual = FiltroCliente.comObraAtiva;

  @override
  void initState() {
    super.initState();
    // Carrega a lista de clientes ao abrir a página (padrão Supabase)
    Future.microtask(() {
      if (!mounted) return;
      context.read<ClienteController>().carregarClientes();
    });
  }

  /// Aplica filtro de busca por texto
  List<Cliente> _filtrarPorTexto(List<Cliente> clientes) {
    if (_termoBusca.isEmpty) return clientes;
    final termo = _termoBusca.toLowerCase();
    return clientes.where((c) =>
      c.nome.toLowerCase().contains(termo) ||
      c.email.toLowerCase().contains(termo) ||
      c.telefone.toLowerCase().contains(termo)
    ).toList();
  }

  /// Aplica filtro por status (ativo/inativo/com obra)
  List<Cliente> _filtrarPorStatus(List<Cliente> clientes, Set<String> clienteIdsComObraAtiva) {
    switch (_filtroAtual) {
      case FiltroCliente.comObraAtiva:
        return clientes.where((c) => c.ativo && clienteIdsComObraAtiva.contains(c.id.toString())).toList();
      case FiltroCliente.todosAtivos:
        return clientes.where((c) => c.ativo).toList();
      case FiltroCliente.inativos:
        return clientes.where((c) => !c.ativo).toList();
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
      title: const Text("Clientes"),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clienteCtrl = context.watch<ClienteController>();

    if (clienteCtrl.carregando) {
      return Scaffold(
        drawer: const DrawerComum(),
        appBar: _appBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: const DrawerComum(),
      appBar: _appBar(),
      body: Builder(
        builder: (context) {
          final c = context.cores;
          final texto = Theme.of(context).textTheme;
          final obraCtrlLocal = context.watch<ObraController>();
          final obras = obraCtrlLocal.obras;
          final clienteIdsComObraAtiva = obras
              .where((o) => o.status != 'Concluída')
              .map((o) => o.idCliente.toString())
              .toSet();

          final todosClientes = clienteCtrl.clientes;
          final clientesFiltradosPorStatus = _filtrarPorStatus(todosClientes, clienteIdsComObraAtiva);
          final clientesFiltrados = _filtrarPorTexto(clientesFiltradosPorStatus);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Espaco.margemTela),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER ---
                Text("Gestão de Clientes", style: texto.headlineMedium),
                const SizedBox(height: Espaco.x1),
                Text(
                  "Gerencie informações e histórico dos seus clientes.",
                  style: texto.bodyMedium?.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: Espaco.x4),

                // --- BOTÃO NOVO CLIENTE ---
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/cliente-formulario'),
                    icon: const Icon(Symbols.person_add_rounded, size: TamanhoIcone.pequeno),
                    label: const Text("Novo Cliente"),
                  ),
                ),
                const SizedBox(height: Espaco.x5),

                // --- FILTRO POR STATUS ---
                ChipsFiltroStatus<FiltroCliente>(
                  opcoes: [
                    OpcaoStatus("Com Obra Ativa", FiltroCliente.comObraAtiva,
                        todosClientes.where((cl) => cl.ativo && clienteIdsComObraAtiva.contains(cl.id.toString())).length,
                        c.info),
                    OpcaoStatus("Todos Ativos", FiltroCliente.todosAtivos,
                        todosClientes.where((cl) => cl.ativo).length, c.success),
                    OpcaoStatus("Inativos", FiltroCliente.inativos,
                        todosClientes.where((cl) => !cl.ativo).length, c.inkMuted),
                  ],
                  selecionado: _filtroAtual,
                  aoSelecionar: (f) => setState(() => _filtroAtual = f),
                ),
                const SizedBox(height: Espaco.x4),

                // --- BARRA DE BUSCA ---
                TextField(
                  onChanged: (v) => setState(() => _termoBusca = v),
                  decoration: const InputDecoration(
                    hintText: "Buscar por nome, e-mail ou telefone...",
                    prefixIcon: Icon(Symbols.search_rounded, size: TamanhoIcone.pequeno),
                  ),
                ),
                const SizedBox(height: Espaco.x2),

                // --- CONTADOR ---
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Espaco.x2),
                  child: Text(
                    "${clientesFiltrados.length} cliente(s) encontrado(s)",
                    style: texto.bodyMedium?.copyWith(color: c.inkMuted),
                  ),
                ),

                // --- LISTA DE CARDS ---
                if (clientesFiltrados.isEmpty)
                  _buildVazio()
                else
                  ...clientesFiltrados.map((cl) => _buildClienteCard(cl, clienteCtrl, clienteIdsComObraAtiva)),
              ],
            ),
          );
        },
      ),
    );
  }

  // === CARD DO CLIENTE ===
  Widget _buildClienteCard(Cliente cliente, ClienteController controller, Set<String> idsComObra) {
    final dataCriacao = DateFormat('dd/MM/yyyy').format(cliente.criadoEm);
    final temObraAtiva = idsComObra.contains(cliente.id.toString());
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.x3),
      child: CardApp(
        aoTocar: () => _mostrarOpcoes(context, cliente, controller),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome + Badge
            Row(
              children: [
                _avatar(cliente, raio: 20),
                const SizedBox(width: Espaco.x3),
                // Nome e data
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nome,
                        style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Cliente desde $dataCriacao",
                        style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0),
                      ),
                    ],
                  ),
                ),
                // Badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    cliente.ativo
                        ? _badge("Ativo", c.success, c.successSoft)
                        : _badge("Inativo", c.inkMuted, c.surfaceSunken),
                    if (temObraAtiva) ...[
                      const SizedBox(height: Espaco.x1),
                      _badge("Obra Ativa", c.info, c.infoSoft),
                    ],
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
                  child: _infoItem(Symbols.call_rounded, cliente.telefone.isNotEmpty ? cliente.telefone : '—'),
                ),
                Expanded(
                  child: _infoItem(Symbols.mail_rounded, cliente.email.isNotEmpty ? cliente.email : '—'),
                ),
              ],
            ),
            if (cliente.endereco.isNotEmpty) ...[
              const SizedBox(height: Espaco.x2),
              _infoItem(Symbols.location_on_rounded, cliente.endereco),
            ],
          ],
        ),
      ),
    );
  }

  /// Inicial do nome num círculo: terracota se ativo, apagado se inativo.
  Widget _avatar(Cliente cliente, {required double raio}) {
    final c = context.cores;
    return CircleAvatar(
      radius: raio,
      backgroundColor: cliente.ativo ? c.primary : c.disabledBg,
      child: Text(
        cliente.nome.isNotEmpty ? cliente.nome[0].toUpperCase() : '?',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: cliente.ativo ? c.onPrimary : c.disabledInk,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
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
  void _mostrarOpcoes(BuildContext context, Cliente cliente, ClienteController controller) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final corStatus = cliente.ativo ? c.error : c.success;
    final fundoStatus = cliente.ativo ? c.errorSoft : c.successSoft;
    final legenda = texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0);

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
              // Nome do cliente
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Espaco.x5, vertical: Espaco.x2),
                child: Row(
                  children: [
                    _avatar(cliente, raio: 18),
                    const SizedBox(width: Espaco.x3),
                    Expanded(
                      child: Text(cliente.nome, style: texto.titleMedium, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Editar
              ListTile(
                leading: _iconeAcao(Symbols.edit_rounded, c.info, c.infoSoft),
                title: const Text("Editar"),
                subtitle: Text("Alterar dados do cliente", style: legenda),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/cliente-formulario', arguments: cliente);
                },
              ),
              // Inativar / Ativar
              ListTile(
                leading: _iconeAcao(
                  cliente.ativo ? Symbols.person_off_rounded : Symbols.person_rounded,
                  corStatus,
                  fundoStatus,
                ),
                title: Text(
                  cliente.ativo ? "Inativar" : "Ativar",
                  style: TextStyle(color: corStatus),
                ),
                subtitle: Text(
                  cliente.ativo ? "O cliente não aparecerá na lista principal" : "Reativar este cliente",
                  style: legenda,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmarAlteracaoStatus(context, cliente, controller);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === CONFIRMAÇÃO DE INATIVAÇÃO / ATIVAÇÃO ===
  void _confirmarAlteracaoStatus(BuildContext context, Cliente cliente, ClienteController controller) {
    final c = context.cores;
    final acao = cliente.ativo ? "Inativar" : "Ativar";
    final msg = cliente.ativo
        ? "O cliente ${cliente.nome} será inativado e não aparecerá mais na lista principal. Você pode reativá-lo pelo filtro 'Inativos'."
        : "O cliente ${cliente.nome} será reativado e voltará a aparecer na lista.";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("$acao Cliente?"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: c.inkMuted),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () {
              if (cliente.ativo) {
                controller.inativar(cliente.id!);
              } else {
                controller.ativar(cliente.id!);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Cliente ${cliente.ativo ? 'inativado' : 'ativado'} com sucesso!"),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: cliente.ativo ? c.error : c.success,
              foregroundColor: cliente.ativo ? c.onError : c.onPrimary,
            ),
            child: Text(acao),
          ),
        ],
      ),
    );
  }

  // === VAZIO ===
  Widget _buildVazio() {
    return switch (_filtroAtual) {
      FiltroCliente.comObraAtiva => TelaVazia(
          ilustracao: IlustracaoVazia.obras,
          titulo: "Nenhum cliente com obra ativa",
          texto: "No momento nenhum cliente tem obra em aberto.",
          acao: OutlinedButton(
            onPressed: () => setState(() => _filtroAtual = FiltroCliente.todosAtivos),
            child: const Text("Ver todos os ativos"),
          ),
        ),
      FiltroCliente.todosAtivos => const TelaVazia(
          ilustracao: IlustracaoVazia.busca,
          titulo: "Nenhum cliente ativo encontrado",
          texto: "Confira a busca ou cadastre um novo cliente.",
        ),
      FiltroCliente.inativos => const TelaVazia(
          ilustracao: IlustracaoVazia.busca,
          titulo: "Nenhum cliente inativo",
          texto: "Clientes inativados aparecem aqui.",
        ),
    };
  }
}
