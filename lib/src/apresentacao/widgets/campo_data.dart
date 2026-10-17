import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/tema/cores_app.dart';
import '../../core/tema/medidas_app.dart';

/// Campo de data padrão do app (etapa 3): caixa com rótulo pequeno em cima
/// ("De", "Até", "Validade"...) e a data em dd/MM/aaaa + dia da semana.
/// Ao tocar, abre o calendário do tema (português, cores da marca).
class CampoData extends StatelessWidget {
  const CampoData({
    super.key,
    required this.rotulo,
    required this.data,
    required this.aoMudar,
    this.primeiraData,
    this.ultimaData,
    this.tituloCalendario,
    this.icone = Symbols.calendar_today_rounded,
  });

  final String rotulo;
  final DateTime data;
  final ValueChanged<DateTime> aoMudar;
  final DateTime? primeiraData;
  final DateTime? ultimaData;

  /// Texto no topo do calendário (ex.: "Início da obra").
  final String? tituloCalendario;
  final IconData icone;

  static final _formatoData = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final _formatoDiaSemana = DateFormat('EEEE', 'pt_BR');

  Future<void> _abrir(BuildContext context) async {
    final primeira = primeiraData ?? DateTime(2020);
    final ultima = ultimaData ?? DateTime(DateTime.now().year + 10, 12, 31);
    // showDatePicker trava (assert) se a data inicial estiver fora do intervalo,
    // o que acontece ao editar registros antigos (ex.: validade já vencida).
    var inicial = data;
    if (inicial.isBefore(primeira)) inicial = primeira;
    if (inicial.isAfter(ultima)) inicial = ultima;

    final escolhida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primeira,
      lastDate: ultima,
      helpText: tituloCalendario,
    );
    if (escolhida != null) aoMudar(escolhida);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;
    final diaSemana = _formatoDiaSemana.format(data);
    final legenda = texto.bodySmall?.copyWith(color: c.inkMuted, letterSpacing: 0);

    // Mesmo visual dos campos de texto do tema: fundo surfaceSunken, raio 8.
    return Material(
      color: c.surfaceSunken,
      borderRadius: BorderRadius.circular(Raio.campo),
      child: InkWell(
        borderRadius: BorderRadius.circular(Raio.campo),
        onTap: () => _abrir(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Espaco.x3, vertical: 10),
          child: Row(
            children: [
              Icon(icone, size: TamanhoIcone.pequeno, color: c.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rotulo, style: legenda),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatoData.format(data),
                        style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      diaSemana[0].toUpperCase() + diaSemana.substring(1),
                      style: legenda,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
