import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../dominio/entidades/obra.dart';
import '../../dominio/entidades/etapa_servico.dart';
import '../controllers/obra_controller.dart';

class ObraDetalhesPage extends StatelessWidget {
  final Obra obra;

  const ObraDetalhesPage({super.key, required this.obra});

  Color _corStatus(String status) {
    switch (status) {
      case 'Em Andamento': return Colors.green;
      case 'Pausada': return Colors.orange;
      case 'Concluída': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ObraController>();
    final formatoData = DateFormat('dd/MM/yyyy');

    // Usamos StreamBuilder para ouvir atualizações em tempo real
    return StreamBuilder<List<Obra>>(
      stream: controller.obras,
      builder: (context, snapshot) {
        // Encontrar a versão mais atualizada desta obra
        final obras = snapshot.data ?? [];
        final obraAtual = obras.where((o) => o.id == obra.id).firstOrNull ?? obra;
        final cor = _corStatus(obraAtual.status);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text("Detalhes da Obra", style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0.5,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (status) => _atualizarStatus(context, obraAtual, controller, status),
                itemBuilder: (context) => [
                  'Não Iniciada', 'Em Andamento', 'Pausada', 'Concluída',
                ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === CABEÇALHO ===
                _buildCabecalho(obraAtual, cor, formatoData, context),
                const SizedBox(height: 24),

                // === BARRA DE PROGRESSO ===
                _buildProgressoCard(obraAtual, cor),
                const SizedBox(height: 24),

                // === CHECKLIST DE ETAPAS ===
                _sectionTitle("Checklist de Etapas", Icons.checklist),
                const SizedBox(height: 12),
                _buildChecklistCard(context, obraAtual, controller),
                const SizedBox(height: 24),

                // === MATERIAIS FALTANTES ===
                _sectionTitle("Materiais Faltantes", Icons.shopping_cart_outlined),
                const SizedBox(height: 12),
                _buildMateriaisCard(context, obraAtual, controller),
                const SizedBox(height: 24),

                // === ANOTAÇÕES ===
                _sectionTitle("Anotações", Icons.notes),
                const SizedBox(height: 12),
                _buildAnotacoesCard(context, obraAtual, controller),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String t, IconData ic) => Row(children: [
    Icon(ic, size: 20, color: Colors.grey[700]), const SizedBox(width: 8),
    Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  ]);

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
    child: child,
  );

  // --- CABEÇALHO ---
  Widget _buildCabecalho(Obra obraAtual, Color cor, DateFormat fmt, BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(obraAtual.tituloDaObra, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text(obraAtual.status, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cliente
          _infoRow(Icons.person_outline, "Cliente", obraAtual.clienteNome),
          const SizedBox(height: 10),

          // Endereço com botão de mapa
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Endereço", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    Text(obraAtual.endereco, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined, color: Colors.blue),
                tooltip: "Abrir no mapa",
                onPressed: () => _abrirMapa(obraAtual.endereco),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Datas
          Row(
            children: [
              Expanded(child: _infoRow(Icons.calendar_today, "Início", fmt.format(obraAtual.dataInicio))),
              Expanded(child: _infoRow(Icons.event, "Previsão", fmt.format(obraAtual.dataPrevisaoTermino))),
            ],
          ),
          if (obraAtual.dataConclusao != null) ...[
            const SizedBox(height: 10),
            _infoRow(Icons.check_circle_outline, "Concluída em", fmt.format(obraAtual.dataConclusao!)),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData ic, String label, String value) => Row(
    children: [
      Icon(ic, size: 18, color: Colors.grey[500]),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    ],
  );

  // --- PROGRESSO ---
  Widget _buildProgressoCard(Obra obraAtual, Color cor) {
    final concluidas = obraAtual.etapasServico.where((e) => e.concluida).length;
    final total = obraAtual.etapasServico.length;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Progresso Geral", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              Text("$concluidas/$total etapas", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: obraAtual.progresso / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(cor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text("${obraAtual.progresso.toStringAsFixed(0)}% concluído",
              style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  // --- CHECKLIST DE ETAPAS ---
  Widget _buildChecklistCard(BuildContext context, Obra obraAtual, ObraController controller) {
    return _card(
      child: Column(
        children: List.generate(obraAtual.etapasServico.length, (i) {
          final etapa = obraAtual.etapasServico[i];
          return Container(
            margin: EdgeInsets.only(bottom: i < obraAtual.etapasServico.length - 1 ? 8 : 0),
            child: Material(
              color: etapa.concluida ? Colors.green.withValues(alpha: 0.06) : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                // Área de toque grande para canteiro de obras
                onTap: () => controller.alternarEtapa(obraAtual, i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Checkbox grande para facilitar uso com mãos sujas
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: etapa.concluida ? Colors.green : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: etapa.concluida ? Colors.green : Colors.grey[400]!, width: 2),
                        ),
                        child: etapa.concluida
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          etapa.nome,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            decoration: etapa.concluida ? TextDecoration.lineThrough : null,
                            color: etapa.concluida ? Colors.grey[500] : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        etapa.concluida ? "Concluído" : "Pendente",
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: etapa.concluida ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- MATERIAIS FALTANTES ---
  Widget _buildMateriaisCard(BuildContext context, Obra obraAtual, ObraController controller) {
    final textController = TextEditingController();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: "Adicionar material...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.add_shopping_cart, size: 20, color: Colors.grey[600]),
                    filled: true, fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (texto) {
                    if (texto.trim().isNotEmpty) {
                      final novosMateriais = List<String>.from(obraAtual.materiaisFaltantes)..add(texto.trim());
                      _salvarComMateriais(controller, obraAtual, novosMateriais);
                      textController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.black),
                onPressed: () {
                  final texto = textController.text.trim();
                  if (texto.isNotEmpty) {
                    final novosMateriais = List<String>.from(obraAtual.materiaisFaltantes)..add(texto);
                    _salvarComMateriais(controller, obraAtual, novosMateriais);
                    textController.clear();
                  }
                },
              ),
            ],
          ),
          if (obraAtual.materiaisFaltantes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: obraAtual.materiaisFaltantes.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value, style: const TextStyle(fontSize: 13)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    final novosMateriais = List<String>.from(obraAtual.materiaisFaltantes)..removeAt(entry.key);
                    _salvarComMateriais(controller, obraAtual, novosMateriais);
                  },
                  backgroundColor: Colors.amber.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: Colors.amber[300]!),
                );
              }).toList(),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text("Nenhum material pendente.", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ),
        ],
      ),
    );
  }

  void _salvarComMateriais(ObraController controller, Obra obraAtual, List<String> materiais) {
    controller.salvar(Obra(
      id: obraAtual.id, orcamentoId: obraAtual.orcamentoId,
      clienteId: obraAtual.clienteId, clienteNome: obraAtual.clienteNome,
      tituloDaObra: obraAtual.tituloDaObra, endereco: obraAtual.endereco,
      dataInicio: obraAtual.dataInicio, dataPrevisaoTermino: obraAtual.dataPrevisaoTermino,
      dataConclusao: obraAtual.dataConclusao, status: obraAtual.status,
      progresso: obraAtual.progresso, etapasServico: obraAtual.etapasServico,
      anotacoes: obraAtual.anotacoes, materiaisFaltantes: materiais,
    ));
  }

  // --- ANOTAÇÕES ---
  Widget _buildAnotacoesCard(BuildContext context, Obra obraAtual, ObraController controller) {
    final textController = TextEditingController(text: obraAtual.anotacoes);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: textController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Observações do dia, detalhes importantes...",
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true, fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                controller.salvar(Obra(
                  id: obraAtual.id, orcamentoId: obraAtual.orcamentoId,
                  clienteId: obraAtual.clienteId, clienteNome: obraAtual.clienteNome,
                  tituloDaObra: obraAtual.tituloDaObra, endereco: obraAtual.endereco,
                  dataInicio: obraAtual.dataInicio, dataPrevisaoTermino: obraAtual.dataPrevisaoTermino,
                  dataConclusao: obraAtual.dataConclusao, status: obraAtual.status,
                  progresso: obraAtual.progresso, etapasServico: obraAtual.etapasServico,
                  anotacoes: textController.text.trim(),
                  materiaisFaltantes: obraAtual.materiaisFaltantes,
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Anotações salvas!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                );
              },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text("Salvar Anotações"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _atualizarStatus(BuildContext context, Obra obraAtual, ObraController controller, String novoStatus) async {
    final erro = await controller.atualizarStatus(obraAtual, novoStatus);
    if (context.mounted) {
      if (erro != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erro), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status atualizado para: $novoStatus"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _abrirMapa(String endereco) async {
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(endereco)}");
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Falha silenciosa se não conseguir abrir
    }
  }
}
