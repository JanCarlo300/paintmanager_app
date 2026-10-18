import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/tema/cores_app.dart';
import '../../core/tema/medidas_app.dart';

/// Campo de busca com seleção (etapa 2). Substitui as caixas seletoras que
/// listam todos os registros: digita-se, a busca roda no banco (aguardando
/// 300 ms depois da última tecla) e os resultados aparecem logo abaixo do
/// campo, sem cobrir o teclado. A lista fecha ao selecionar, limpar, tocar
/// fora, apertar voltar ou esconder o teclado.
class CampoBuscaSelecao<T> extends StatefulWidget {
  const CampoBuscaSelecao({
    super.key,
    required this.rotulo,
    required this.dica,
    required this.buscar,
    required this.tituloDe,
    required this.aoSelecionar,
    this.aoLimpar,
    this.subtituloDe,
    this.icone = Symbols.search_rounded,
    this.iconeItem,
    this.textoInicial,
    this.mensagemObrigatorio,
    this.autofocus = false,
  });

  final String rotulo;
  final String dica;
  final Future<List<T>> Function(String termo) buscar;
  final String Function(T item) tituloDe;
  final String? Function(T item)? subtituloDe;
  final void Function(T item) aoSelecionar;
  final VoidCallback? aoLimpar;
  final IconData icone;
  final IconData? iconeItem;

  /// Texto de um valor já escolhido (edição): o campo abre como selecionado.
  final String? textoInicial;

  /// Se informado, o campo vira obrigatório e mostra esta mensagem no validate().
  final String? mensagemObrigatorio;
  final bool autofocus;

  @override
  State<CampoBuscaSelecao<T>> createState() => _CampoBuscaSelecaoState<T>();
}

class _CampoBuscaSelecaoState<T> extends State<CampoBuscaSelecao<T>>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  int _versaoBusca = 0;
  List<T> _resultados = [];
  bool _carregando = false;
  bool _buscou = false;
  String? _erroBusca;
  bool _temSelecao = false;
  bool _tecladoVisivel = false;
  FormFieldState<bool>? _campo;

  bool get _aberta => _focus.hasFocus && !_temSelecao;

  @override
  void initState() {
    super.initState();
    final inicial = widget.textoInicial;
    if (inicial != null && inicial.isNotEmpty) {
      _controller.text = inicial;
      _temSelecao = true;
    }
    _focus.addListener(_aoMudarFoco);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _focus.removeListener(_aoMudarFoco);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Esconder o teclado pelo botão voltar do Android não tira o foco do campo,
  // então a lista ficaria aberta; detecta o teclado sumindo e tira o foco.
  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final visivel = View.of(context).viewInsets.bottom > 0;
    if (_tecladoVisivel && !visivel && _focus.hasFocus) _focus.unfocus();
    _tecladoVisivel = visivel;
  }

  void _aoMudarFoco() {
    if (_focus.hasFocus && !_temSelecao) _buscarAgora();
    if (mounted) setState(() {});
  }

  void _aoDigitar(String texto) {
    if (_temSelecao) {
      _temSelecao = false;
      _campo?.didChange(false);
      widget.aoLimpar?.call();
    }
    _debounce?.cancel();
    setState(() => _carregando = true);
    _debounce = Timer(const Duration(milliseconds: 300), _buscarAgora);
  }

  Future<void> _buscarAgora() async {
    final versao = ++_versaoBusca;
    if (mounted) setState(() { _carregando = true; _erroBusca = null; });
    try {
      final r = await widget.buscar(_controller.text.trim());
      if (!mounted || versao != _versaoBusca) return;
      setState(() {
        _resultados = r;
        _buscou = true;
        _carregando = false;
      });
      _rolarParaVisivel();
    } catch (_) {
      if (!mounted || versao != _versaoBusca) return;
      setState(() {
        _resultados = [];
        _buscou = true;
        _carregando = false;
        _erroBusca = 'Não foi possível buscar. Tente de novo.';
      });
    }
  }

  void _rolarParaVisivel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _aberta) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: 0.1,
        );
      }
    });
  }

  void _selecionar(T item) {
    _debounce?.cancel();
    _versaoBusca++; // descarta busca em andamento
    setState(() {
      _temSelecao = true;
      _resultados = [];
      _carregando = false;
    });
    _controller.text = widget.tituloDe(item);
    _campo?.didChange(true);
    _focus.unfocus();
    widget.aoSelecionar(item);
  }

  void _limpar() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _temSelecao = false);
    _campo?.didChange(false);
    widget.aoLimpar?.call();
    if (_focus.hasFocus) {
      _buscarAgora();
    } else {
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: _temSelecao,
      validator: (v) =>
          widget.mensagemObrigatorio != null && v != true ? widget.mensagemObrigatorio : null,
      builder: (campo) {
        _campo = campo;
        final erro = campo.hasError;
        final c = context.cores;

        return PopScope(
          canPop: !_aberta,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _focus.unfocus();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                onChanged: _aoDigitar,
                onTapOutside: (_) => _focus.unfocus(),
                textInputAction: TextInputAction.search,
                // Fundo, cantos e foco vêm do tema; só a borda de erro é local,
                // porque o erro é do FormField de fora, não do TextField.
                decoration: InputDecoration(
                  labelText: widget.rotulo,
                  hintText: widget.dica,
                  prefixIcon: Icon(widget.icone, size: TamanhoIcone.pequeno),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Symbols.close_rounded, size: TamanhoIcone.pequeno),
                          onPressed: _limpar,
                        )
                      : null,
                  enabledBorder: erro
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Raio.campo),
                          borderSide: BorderSide(color: c.error),
                        )
                      : null,
                  focusedBorder: erro
                      ? OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Raio.campo),
                          borderSide: BorderSide(color: c.error, width: 1.5),
                        )
                      : null,
                ),
              ),
              if (_aberta) _buildLista(),
              if (erro)
                Padding(
                  padding: const EdgeInsets.only(left: Espaco.x3, top: 6),
                  child: Text(
                    campo.errorText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.error, letterSpacing: 0),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // TextFieldTapRegion: tocar na lista não conta como "fora do campo" — senão
  // o foco cairia (e a lista sumiria) antes do toque no item ser registrado.
  Widget _buildLista() {
    final c = context.cores;
    return TextFieldTapRegion(
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        constraints: const BoxConstraints(maxHeight: 240),
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: BorderRadius.circular(Raio.campo),
          border: Border.all(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_carregando)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
              ),
            Flexible(child: _conteudoLista()),
          ],
        ),
      ),
    );
  }

  Widget _conteudoLista() {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    if (_erroBusca != null) {
      return _mensagem(_erroBusca!, cor: c.error);
    }
    if (_resultados.isEmpty) {
      return _buscou && !_carregando
          ? _mensagem('Nenhum resultado')
          : const SizedBox(height: 48);
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _resultados.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = _resultados[i];
        final titulo = widget.tituloDe(item);
        final subtitulo = widget.subtituloDe?.call(item);
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: c.primarySoft,
            child: widget.iconeItem != null
                ? Icon(widget.iconeItem, size: 16, color: c.primary)
                : Text(
                    titulo.isNotEmpty ? titulo[0].toUpperCase() : '?',
                    style: texto.labelSmall?.copyWith(color: c.primary, fontWeight: FontWeight.w700),
                  ),
          ),
          title: Text(titulo, style: texto.bodyMedium?.copyWith(color: c.ink)),
          subtitle: subtitulo != null && subtitulo.isNotEmpty
              ? Text(subtitulo, style: texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0))
              : null,
          onTap: () => _selecionar(item),
        );
      },
    );
  }

  Widget _mensagem(String texto, {Color? cor}) => Padding(
        padding: const EdgeInsets.all(Espaco.x4),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cor ?? context.cores.inkMuted),
        ),
      );
}
