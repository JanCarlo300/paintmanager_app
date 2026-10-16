import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../dominio/entidades/mensagem_obra.dart';
import '../controllers/obra_controller.dart';
import '../../../../core/tema/paleta_sahara.dart';
import '../../../auth/apresentacao/controllers/auth_controller.dart';

/// Item 2.3 — chat da obra em tempo real (substitui o antigo campo "Anotações").
class ChatObraCard extends StatefulWidget {
  final int obraId;

  const ChatObraCard({super.key, required this.obraId});

  @override
  State<ChatObraCard> createState() => _ChatObraCardState();
}

class _ChatObraCardState extends State<ChatObraCard> {
  // Criado uma única vez: a página pai reconstrói a cada notifyListeners e
  // recriar o stream ali abriria uma nova assinatura de Realtime a cada vez.
  late final Stream<List<MensagemObra>> _mensagens;
  final _textoController = TextEditingController();
  bool _enviando = false;

  int? _totalLido;

  @override
  void initState() {
    super.initState();
    final controller = context.read<ObraController>();
    // Etapa 7: com o chat aberto, o que chega já conta como lido.
    _mensagens = controller.escutarMensagens(widget.obraId).map((lista) {
      if (mounted && lista.length != _totalLido) {
        _totalLido = lista.length;
        controller.marcarChatLido(widget.obraId);
      }
      return lista;
    });
  }

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _textoController.text.trim();
    if (texto.isEmpty || _enviando) return;

    final usuario = context.read<AuthController>().usuarioLogado;
    if (usuario?.id == null) {
      _avisar('Não foi possível identificar o usuário logado.');
      return;
    }

    setState(() => _enviando = true);
    try {
      await context.read<ObraController>().enviarMensagem(
            obraId: widget.obraId,
            usuarioId: usuario!.id!,
            texto: texto,
          );
      _textoController.clear();
    } catch (e) {
      _avisar('$e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _avisar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meuId = context.watch<AuthController>().usuarioLogado?.id;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PaletaSahara.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: StreamBuilder<List<MensagemObra>>(
              stream: _mensagens,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Não foi possível carregar o chat.', style: TextStyle(color: Colors.red)),
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: PaletaSahara.primary)),
                  );
                }
                final mensagens = snapshot.data!;
                if (mensagens.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nenhuma mensagem ainda. Comece a conversa!',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  );
                }
                // reverse: true mantém a lista "grudada" na mensagem mais recente.
                return ListView.builder(
                  shrinkWrap: true,
                  reverse: true,
                  itemCount: mensagens.length,
                  itemBuilder: (context, i) {
                    final m = mensagens[mensagens.length - 1 - i];
                    return _BalaoMensagem(mensagem: m, minha: m.usuarioId != null && m.usuarioId == meuId);
                  },
                );
              },
            ),
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textoController,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Escreva uma mensagem...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey[200]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey[200]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: PaletaSahara.primary, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _enviando ? null : _enviar,
                style: IconButton.styleFrom(backgroundColor: PaletaSahara.primary, foregroundColor: Colors.white),
                icon: _enviando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalaoMensagem extends StatelessWidget {
  final MensagemObra mensagem;
  final bool minha;

  const _BalaoMensagem({required this.mensagem, required this.minha});

  String _horario(DateTime d) {
    final agora = DateTime.now();
    final hoje = d.year == agora.year && d.month == agora.month && d.day == agora.day;
    return DateFormat(hoje ? 'HH:mm' : 'dd/MM HH:mm').format(d);
  }

  @override
  Widget build(BuildContext context) {
    if (mensagem.importada) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.history, size: 14, color: Colors.amber[800]),
              const SizedBox(width: 4),
              Text('Observação importada das antigas Anotações',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber[900])),
            ]),
            const SizedBox(height: 6),
            Text(mensagem.texto, style: const TextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: minha ? PaletaSahara.primary.withValues(alpha: 0.12) : Colors.grey[100],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(minha ? 12 : 2),
              bottomRight: Radius.circular(minha ? 2 : 12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: minha ? 'Você' : mensagem.autorNome,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: PaletaSahara.tertiary),
                  ),
                  TextSpan(
                    text: '  ·  ${mensagem.autorFuncao}',
                    style: const TextStyle(fontSize: 11, color: PaletaSahara.onSurfaceMuted),
                  ),
                ]),
              ),
              const SizedBox(height: 2),
              Text(mensagem.texto, style: const TextStyle(fontSize: 14, color: PaletaSahara.onSurface)),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(_horario(mensagem.criadoEm),
                    style: const TextStyle(fontSize: 10, color: PaletaSahara.onSurfaceMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
