import 'etapa_servico.dart';
import 'item_material.dart';

/// Entidade de domínio — Obra.
class Obra {
  final int? id;
  final int? idOrcamento;
  final int idCliente;
  final String clienteNome;     // cache desnormalizado para exibição rápida
  final String tituloDaObra;
  final String endereco;        // rua/avenida (obras antigas: o texto inteiro)
  final String numero;          // número da casa ("S/N" quando não tem)
  final String complemento;     // quadra, lote, bloco...
  final String cep;             // só números (8 dígitos)
  final String bairro;
  final String cidade;
  final String uf;              // sigla do estado (ex.: GO)
  final DateTime dataInicio;
  final DateTime dataPrevisaoTermino;
  final DateTime? dataConclusao;
  final String status;          // Não Iniciada | Em Andamento | Pausada | Concluída
  final double progresso;       // 0 a 100
  final List<EtapaServico> etapasServico;
  final List<ItemMaterial> listaMateriais;
  final double? latitude;   // item 3.2 — geocodificado a partir do endereço (Nominatim/OSM)
  final double? longitude;
  /// true = ponto do GPS/link (exato, guia o "Como chegar"); false = aproximado pelo endereço.
  final bool localizacaoExata;
  final DateTime? criadoEm; // gerado pelo banco (created_at); usado nos filtros da lista

  Obra({
    this.id,
    this.idOrcamento,
    required this.idCliente,
    required this.clienteNome,
    required this.tituloDaObra,
    required this.endereco,
    this.numero = '',
    this.complemento = '',
    this.cep = '',
    this.bairro = '',
    this.cidade = '',
    this.uf = '',
    required this.dataInicio,
    required this.dataPrevisaoTermino,
    this.dataConclusao,
    this.status = 'Não Iniciada',
    double? progresso,
    required this.etapasServico,
    this.listaMateriais = const [],
    this.latitude,
    this.longitude,
    this.localizacaoExata = false,
    this.criadoEm,
  }) : progresso = progresso ?? _calcularProgresso(etapasServico);

  bool get temCoordenadas => latitude != null && longitude != null;

  bool get temPontoExato => localizacaoExata && temCoordenadas;

  /// Obras cadastradas antes dos campos Cidade/UF não os têm.
  bool get temCidade => cidade.trim().isNotEmpty && uf.trim().isNotEmpty;

  /// CEP formatado: 75900000 -> 75900-000.
  String get cepFormatado {
    final d = cep.replaceAll(RegExp(r'[^0-9]'), '');
    return d.length == 8 ? '${d.substring(0, 5)}-${d.substring(5)}' : d;
  }

  /// "Rua X, 123, Qd N Lt 19 - Eldorado, Rio Verde - GO" (só as partes preenchidas).
  String get enderecoCompleto {
    final ruaENumero = [endereco.trim(), numero.trim(), complemento.trim()]
        .where((p) => p.isNotEmpty)
        .join(', ');
    final b = bairro.trim();
    final local = [cidade.trim(), uf.trim()].where((p) => p.isNotEmpty).join(' - ');
    final partes = <String>[
      if (ruaENumero.isNotEmpty) b.isNotEmpty ? '$ruaENumero - $b' : ruaENumero else if (b.isNotEmpty) b,
      if (local.isNotEmpty) local,
    ];
    return partes.join(', ');
  }

  /// Texto para o Google Maps achar a porta: rua, número, bairro, cidade,
  /// UF e CEP. Quadra/lote ficam de fora (o Google não os conhece e eles
  /// atrapalham a busca); para chegar ao lote vale o ponto exato.
  String get enderecoParaRota => [
        [endereco.trim(), numero.trim()].where((p) => p.isNotEmpty).join(', '),
        bairro.trim(),
        [cidade.trim(), uf.trim()].where((p) => p.isNotEmpty).join(' - '),
        cepFormatado,
        'Brasil',
      ].where((p) => p.isNotEmpty).join(', ');

  /// Calcula o progresso automaticamente baseado nas etapas concluídas
  static double _calcularProgresso(List<EtapaServico> etapas) {
    if (etapas.isEmpty) return 0;
    final concluidas = etapas.where((e) => e.concluida).length;
    return (concluidas / etapas.length) * 100;
  }

  /// Verifica se todas as etapas estão concluídas
  bool get todasEtapasConcluidas =>
      etapasServico.isNotEmpty && etapasServico.every((e) => e.concluida);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Obra && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
