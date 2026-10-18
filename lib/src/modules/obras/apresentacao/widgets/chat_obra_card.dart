import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../dominio/entidades/mensagem_obra.dart';
import '../controllers/obra_controller.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';
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
    final c = context.cores;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: TextStyle(color: c.onError)), backgroundColor: c.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meuId = context.watch<AuthController>().usuarioLogado?.id;
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: CardApp(
        child: Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: StreamBuilder<List<MensagemObra>>(
                stream: _mensagens,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: Espaco.x6),
                      child: Text('Não foi possível carregar o chat.', style: texto.bodyMedium?.copyWith(color: c.error)),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: Espaco.x6),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final mensagens = snapshot.data!;
                  if (mensagens.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: Espaco.x6),
                      child: Text(
                        'Nenhuma mensagem ainda. Comece a conversa!',
                        style: texto.bodyMedium?.copyWith(color: c.inkMuted),
                      ),
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
            const Divider(height: Espaco.x6),
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
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: Espaco.x4, vertical: Espaco.x3),
                      // Campo de chat em pílula; o fundo segue o tema.
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Raio.pilula),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Raio.pilula),
                        borderSide: BorderSide(color: c.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Espaco.x2),
                IconButton.filled(
                  tooltip: 'Enviar',
                  onPressed: _enviando ? null : _enviar,
                  icon: _enviando
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: c.inkMuted, strokeWidth: 2))
                      : const Icon(Symbols.send_rounded, size: TamanhoIcone.pequeno),
                ),
              ],
            ),
          ],
        ),
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
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final legenda = texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0);

    if (mensagem.importada) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(Espaco.x3),
        decoration: BoxDecoration(
          color: c.warningSoft,
          borderRadius: BorderRadius.circular(Raio.botao),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Symbols.history_rounded, size: 16, color: c.warning),
              const SizedBox(width: Espaco.x1),
              Expanded(
                child: Text(
                  'Observação importada das antigas Anotações',
                  style: texto.labelSmall?.copyWith(color: c.warning, letterSpacing: 0),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text(mensagem.texto, style: texto.bodyMedium),
          ],
        ),
      );
    }

    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: Espaco.x1),
          padding: const EdgeInsets.fromLTRB(Espaco.x3, Espaco.x2, Espaco.x3, 6),
          decoration: BoxDecoration(
            color: minha ? c.primarySoft : c.surfaceSunken,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(Raio.botao),
              topRight: const Radius.circular(Raio.botao),
              bottomLeft: Radius.circular(minha ? Raio.botao : 2),
              bottomRight: Radius.circular(minha ? 2 : Raio.botao),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: minha ? 'Você' : mensagem.autorNome,
                    style: texto.labelSmall?.copyWith(color: c.secondary, fontWeight: FontWeight.w700, letterSpacing: 0),
                  ),
                  TextSpan(text: '  ·  ${mensagem.autorFuncao}', style: legenda),
                ]),
              ),
              const SizedBox(height: 2),
              Text(mensagem.texto, style: texto.bodyMedium),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(_horario(mensagem.criadoEm), style: legenda),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
