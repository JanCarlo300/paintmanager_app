import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../apresentacao/widgets/card_app.dart';
import '../../../../core/servicos/geocodificacao_service.dart';
import '../../../../core/servicos/localizacao_service.dart';
import '../../../../core/tema/cores_app.dart';
import '../../../../core/tema/medidas_app.dart';

/// "Confirmar no mapa" — como nos apps de entrega: o pino fica parado no
/// centro e o usuário arrasta o mapa até ele ficar em cima do lote. Devolve a
/// [Coordenada] escolhida (ponto exato da obra) ou `null` se cancelar.
class ConfirmarLocalPage extends StatefulWidget {
  const ConfirmarLocalPage({
    super.key,
    required this.inicial,
    required this.endereco,
    this.pontoAproximado = true,
  });

  /// Onde o mapa abre: ponto já salvo, resultado da busca ou a cidade.
  final Coordenada inicial;
  final String endereco;

  /// true = o ponto inicial veio da busca pelo endereço (pode estar fora do lote).
  final bool pontoAproximado;

  @override
  State<ConfirmarLocalPage> createState() => _ConfirmarLocalPageState();
}

class _ConfirmarLocalPageState extends State<ConfirmarLocalPage> {
  final _mapa = MapController();
  bool _buscandoGps = false;

  Future<void> _irParaMinhaLocalizacao() async {
    setState(() => _buscandoGps = true);
    try {
      final c = await LocalizacaoService().localizacaoAtual();
      _mapa.move(LatLng(c.latitude, c.longitude), 18);
    } catch (e) {
      if (!mounted) return;
      final cores = context.cores;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e', style: TextStyle(color: cores.onError)), backgroundColor: cores.error),
      );
    } finally {
      if (mounted) setState(() => _buscandoGps = false);
    }
  }

  void _confirmar() {
    final centro = _mapa.camera.center;
    Navigator.pop(context, Coordenada(latitude: centro.latitude, longitude: centro.longitude));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar no mapa')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapa,
            options: MapOptions(
              initialCenter: LatLng(widget.inicial.latitude, widget.inicial.longitude),
              initialZoom: widget.pontoAproximado ? 17 : 18,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.paintmanager.app',
                maxZoom: 19,
              ),
              const SimpleAttributionWidget(source: Text('OpenStreetMap')),
            ],
          ),

          // Pino fixo no centro: a ponta dele marca o ponto escolhido.
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Icon(Symbols.location_on_rounded, fill: 1, size: 48, color: c.error),
              ),
            ),
          ),

          // Instrução no topo
          Positioned(
            left: Espaco.margemTela,
            right: Espaco.margemTela,
            top: Espaco.x3,
            child: CardApp(
              padding: const EdgeInsets.all(Espaco.x3),
              child: Text(
                widget.pontoAproximado
                    ? 'O pino está no ponto aproximado do endereço. Arraste o mapa até ele ficar em cima do lote.'
                    : 'Arraste o mapa até o pino ficar em cima do lote.',
                style: texto.bodyMedium,
              ),
            ),
          ),

          // Endereço + ações
          Positioned(
            left: Espaco.margemTela,
            right: Espaco.margemTela,
            bottom: Espaco.x4,
            child: SafeArea(
              top: false,
              child: CardApp(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Symbols.home_pin_rounded, color: c.primary, size: TamanhoIcone.pequeno),
                        const SizedBox(width: Espaco.x2),
                        Expanded(
                          child: Text(
                            widget.endereco.isEmpty ? 'Endereço da obra' : widget.endereco,
                            style: texto.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Espaco.x3),
                    OutlinedButton.icon(
                      onPressed: _buscandoGps ? null : _irParaMinhaLocalizacao,
                      icon: _buscandoGps
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Symbols.my_location_rounded, size: 18),
                      label: const Text('Estou no local: usar meu GPS'),
                    ),
                    const SizedBox(height: Espaco.x2),
                    FilledButton.icon(
                      onPressed: _confirmar,
                      icon: const Icon(Symbols.check_rounded, size: TamanhoIcone.pequeno),
                      label: const Text('Confirmar este local'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
