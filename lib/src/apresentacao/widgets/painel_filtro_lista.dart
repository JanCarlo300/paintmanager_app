import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/filtros/filtro_lista.dart';
import '../../core/tema/cores_app.dart';
import '../../core/tema/medidas_app.dart';

/// Etapa 4 — botão de filtro que fica ao lado da busca. Mostra quantos
/// filtros estão ativos e abre o painel de ordenação e filtros.
class BotaoFiltroLista extends StatelessWidget {
  const BotaoFiltroLista({
    super.key,
    required this.filtro,
    required this.aoAplicar,
    required this.rotuloAtrasados,
    required this.rotuloProximos7Dias,
  });

  final FiltroLista filtro;
  final ValueChanged<FiltroLista> aoAplicar;

  /// Textos do filtro de prazo, que mudam por tela (obra x orçamento).
  final String rotuloAtrasados;
  final String rotuloProximos7Dias;

  Future<void> _abrir(BuildContext context) async {
    final resultado = await showModalBottomSheet<FiltroLista>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PainelFiltro(
        inicial: filtro,
        rotuloAtrasados: rotuloAtrasados,
        rotuloProximos7Dias: rotuloProximos7Dias,
      ),
    );
    if (resultado != null) aoAplicar(resultado);
  }

  @override
  Widget build(BuildContext context) {
    final ativos = filtro.quantidadeAtivos;
    final c = context.cores;

    return SizedBox(
      height: 42,
      width: 42,
      child: Badge(
        isLabelVisible: ativos > 0,
        label: Text('$ativos'),
        backgroundColor: c.secondary,
        textColor: c.onSecondary,
        child: Material(
          color: ativos > 0 ? c.primary : c.surfaceCard,
          borderRadius: BorderRadius.circular(Raio.campo),
          child: InkWell(
            borderRadius: BorderRadius.circular(Raio.campo),
            onTap: () => _abrir(context),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Raio.campo),
                border: Border.all(color: ativos > 0 ? c.primary : c.border),
              ),
              child: Icon(
                Symbols.tune_rounded,
                size: TamanhoIcone.pequeno,
                color: ativos > 0 ? c.onPrimary : c.inkMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PainelFiltro extends StatefulWidget {
  const _PainelFiltro({
    required this.inicial,
    required this.rotuloAtrasados,
    required this.rotuloProximos7Dias,
  });

  final FiltroLista inicial;
  final String rotuloAtrasados;
  final String rotuloProximos7Dias;

  @override
  State<_PainelFiltro> createState() => _PainelFiltroState();
}

class _PainelFiltroState extends State<_PainelFiltro> {
  late FiltroLista _filtro = widget.inicial;
  static final _formato = DateFormat('dd/MM', 'pt_BR');

  String get _rotuloPersonalizado {
    final ini = _filtro.inicioPersonalizado;
    final fim = _filtro.fimPersonalizado;
    if (_filtro.periodo == PeriodoCriacao.personalizado && ini != null && fim != null) {
      return '${_formato.format(ini)} – ${_formato.format(fim)}';
    }
    return 'Escolher período';
  }

  Future<void> _escolherPeriodo() async {
    final agora = DateTime.now();
    final ini = _filtro.inicioPersonalizado;
    final fim = _filtro.fimPersonalizado;
    final intervalo = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(agora.year, agora.month, agora.day),
      initialDateRange: ini != null && fim != null ? DateTimeRange(start: ini, end: fim) : null,
      helpText: 'Criados entre',
    );
    if (intervalo != null) {
      setState(() => _filtro = _filtro.copiarCom(
            periodo: PeriodoCriacao.personalizado,
            inicioPersonalizado: intervalo.start,
            fimPersonalizado: intervalo.end,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Espaco.x5, Espaco.x3, Espaco.x5, Espaco.x5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Espaco.x4),
            Text('Ordenar e filtrar', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),

            _titulo('Ordenar por'),
            _opcoes([
              _opcao('Mais recentes', _filtro.maisRecentes,
                  () => setState(() => _filtro = _filtro.copiarCom(maisRecentes: true))),
              _opcao('Mais antigos', !_filtro.maisRecentes,
                  () => setState(() => _filtro = _filtro.copiarCom(maisRecentes: false))),
            ]),
            const SizedBox(height: 20),

            _titulo('Criado em'),
            _opcoes([
              for (final p in const [
                (PeriodoCriacao.todos, 'Qualquer data'),
                (PeriodoCriacao.hoje, 'Hoje'),
                (PeriodoCriacao.ontem, 'Ontem'),
                (PeriodoCriacao.ultimos7Dias, 'Últimos 7 dias'),
                (PeriodoCriacao.ultimos30Dias, 'Últimos 30 dias'),
              ])
                _opcao(p.$2, _filtro.periodo == p.$1,
                    () => setState(() => _filtro = _filtro.copiarCom(periodo: p.$1))),
              _opcao(
                _rotuloPersonalizado,
                _filtro.periodo == PeriodoCriacao.personalizado,
                _escolherPeriodo,
                icone: Symbols.date_range_rounded,
              ),
            ]),
            const SizedBox(height: 20),

            _titulo('Prazo'),
            _opcoes([
              _opcao('Qualquer prazo', _filtro.prazo == FiltroPrazo.todos,
                  () => setState(() => _filtro = _filtro.copiarCom(prazo: FiltroPrazo.todos))),
              _opcao(widget.rotuloAtrasados, _filtro.prazo == FiltroPrazo.atrasados,
                  () => setState(() => _filtro = _filtro.copiarCom(prazo: FiltroPrazo.atrasados))),
              _opcao(widget.rotuloProximos7Dias, _filtro.prazo == FiltroPrazo.proximos7Dias,
                  () => setState(() => _filtro = _filtro.copiarCom(prazo: FiltroPrazo.proximos7Dias))),
            ]),
            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, const FiltroLista()),
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: Espaco.x3),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _filtro),
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: Espaco.x2),
        child: Text(
          texto.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.cores.inkMuted),
        ),
      );

  Widget _opcoes(List<Widget> chips) => Wrap(spacing: 8, runSpacing: 8, children: chips);

  // Selecionado: fundo primarySoft com texto primary (chip ativo do manual).
  Widget _opcao(String rotulo, bool selecionado, VoidCallback aoTocar, {IconData? icone}) {
    final c = context.cores;
    return ChoiceChip(
      avatar: icone != null
          ? Icon(icone, size: 16, color: selecionado ? c.primary : c.inkMuted)
          : null,
      label: Text(rotulo),
      selected: selecionado,
      onSelected: (_) => aoTocar(),
      showCheckmark: false,
      selectedColor: c.primarySoft,
      backgroundColor: c.surfaceSunken,
      side: BorderSide(color: selecionado ? c.primary : Colors.transparent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raio.campo)),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selecionado ? c.primary : c.ink,
            fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
          ),
    );
  }
}
