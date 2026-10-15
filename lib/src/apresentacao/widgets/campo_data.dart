import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/tema/paleta_sahara.dart';

/// Campo de data padrão do app (etapa 3): caixa com rótulo pequeno em cima
/// ("De", "Até", "Validade"...) e a data em dd/MM/aaaa + dia da semana.
/// Ao tocar, abre o calendário do tema (português, cores Sahara).
class CampoData extends StatelessWidget {
  const CampoData({
    super.key,
    required this.rotulo,
    required this.data,
    required this.aoMudar,
    this.primeiraData,
    this.ultimaData,
    this.tituloCalendario,
    this.icone = Icons.calendar_today_outlined,
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
    final diaSemana = _formatoDiaSemana.format(data);

    return Material(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _abrir(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(icone, size: 20, color: PaletaSahara.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rotulo,
                      style: const TextStyle(fontSize: 11, color: PaletaSahara.onSurfaceMuted),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatoData.format(data),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: PaletaSahara.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      diaSemana[0].toUpperCase() + diaSemana.substring(1),
                      style: const TextStyle(fontSize: 11, color: PaletaSahara.onSurfaceMuted),
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
