import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/filtros/filtro_lista.dart';
import '../../core/tema/paleta_sahara.dart';

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
      backgroundColor: PaletaSahara.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

    return SizedBox(
      height: 42,
      width: 42,
      child: Badge(
        isLabelVisible: ativos > 0,
        label: Text('$ativos'),
        backgroundColor: PaletaSahara.tertiary,
        child: Material(
          color: ativos > 0 ? PaletaSahara.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _abrir(context),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ativos > 0 ? PaletaSahara.primary : Colors.grey[200]!),
              ),
              child: Icon(
                Icons.tune,
                size: 20,
                color: ativos > 0 ? Colors.white : Colors.grey[600],
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Ordenar e filtrar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                icone: Icons.date_range,
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PaletaSahara.onSurface,
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Limpar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _filtro),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PaletaSahara.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PaletaSahara.onSurfaceMuted),
        ),
      );

  Widget _opcoes(List<Widget> chips) => Wrap(spacing: 8, runSpacing: 8, children: chips);

  Widget _opcao(String rotulo, bool selecionado, VoidCallback aoTocar, {IconData? icone}) {
    return ChoiceChip(
      avatar: icone != null
          ? Icon(icone, size: 16, color: selecionado ? Colors.white : Colors.grey[700])
          : null,
      label: Text(rotulo),
      selected: selecionado,
      onSelected: (_) => aoTocar(),
      showCheckmark: false,
      selectedColor: PaletaSahara.primary,
      backgroundColor: Colors.grey[100],
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: TextStyle(
        fontSize: 13,
        color: selecionado ? Colors.white : Colors.grey[800],
        fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
