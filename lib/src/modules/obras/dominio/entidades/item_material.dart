/// Etapa 6 — item da Lista de Materiais da obra: uma linha de texto livre,
/// ex.: "1 lata de tinta Coral Branco Neve 18 L", "1 lixa 180".
class ItemMaterial {
  final String descricao;

  const ItemMaterial(this.descricao);

  Map<String, dynamic> paraMapa() => {'descricao': descricao};

  factory ItemMaterial.deMapa(Map<String, dynamic> mapa) =>
      ItemMaterial(mapa['descricao']?.toString() ?? '');
}
