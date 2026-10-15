import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/tema/paleta_sahara.dart';

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
    this.icone = Icons.search,
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
        final corBorda = erro ? Colors.red : Colors.grey[200]!;

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
                decoration: InputDecoration(
                  labelText: widget.rotulo,
                  hintText: widget.dica,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(widget.icone, size: 20, color: Colors.grey[600]),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18, color: Colors.grey[500]),
                          onPressed: _limpar,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: corBorda),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: corBorda),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: erro ? Colors.red : PaletaSahara.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              if (_aberta) _buildLista(),
              if (erro)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6),
                  child: Text(
                    campo.errorText!,
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
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
    return TextFieldTapRegion(
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        constraints: const BoxConstraints(maxHeight: 240),
        decoration: BoxDecoration(
          color: PaletaSahara.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_carregando)
              const LinearProgressIndicator(
                minHeight: 2,
                color: PaletaSahara.primary,
                backgroundColor: Colors.transparent,
              ),
            Flexible(child: _conteudoLista()),
          ],
        ),
      ),
    );
  }

  Widget _conteudoLista() {
    if (_erroBusca != null) {
      return _mensagem(_erroBusca!, cor: Colors.red[700]);
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
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, i) {
        final item = _resultados[i];
        final titulo = widget.tituloDe(item);
        final subtitulo = widget.subtituloDe?.call(item);
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[200],
            child: widget.iconeItem != null
                ? Icon(widget.iconeItem, size: 14, color: Colors.grey[700])
                : Text(
                    titulo.isNotEmpty ? titulo[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
          ),
          title: Text(titulo, style: TextStyle(color: Colors.grey[800])),
          subtitle: subtitulo != null && subtitulo.isNotEmpty
              ? Text(subtitulo, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
              : null,
          onTap: () => _selecionar(item),
        );
      },
    );
  }

  Widget _mensagem(String texto, {Color? cor}) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: cor ?? Colors.grey[600], fontSize: 13),
        ),
      );
}
