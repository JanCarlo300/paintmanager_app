import 'package:flutter/material.dart';

/// Cores fixas das categorias de despesa nos gráficos (manual da marca,
/// aprovado pelo Jan no Lote H). Cada categoria tem sempre a mesma cor, em
/// qualquer período; no escuro, versões mais claras das mesmas cores.
/// Os gráficos também escrevem nome e valor de cada categoria, para a
/// leitura não depender só da cor.
Color corDaCategoria(String categoria, Brightness brilho) {
  final escuro = brilho == Brightness.dark;
  switch (categoria.trim().toLowerCase()) {
    case 'mão de obra':
      return escuro ? const Color(0xFFE07B3F) : const Color(0xFFC2652A); // terracota
    case 'materiais':
      return escuro ? const Color(0xFF7DB3DE) : const Color(0xFF2F6690); // azul
    case 'ferramentas':
      return escuro ? const Color(0xFFD88A8A) : const Color(0xFF8C3C3C); // vinho
    case 'transporte':
      return escuro ? const Color(0xFFE3B341) : const Color(0xFF8A6100); // âmbar
    case 'alimentação':
      return escuro ? const Color(0xFFB8ABA0) : const Color(0xFF6B5E55); // grafite claro
    case 'outros':
      return escuro ? const Color(0xFF4A3D34) : const Color(0xFFD8D0C8); // areia
    default:
      // Categoria nova ainda sem cor própria: tom neutro decorativo.
      return escuro ? const Color(0xFF6B5E55) : const Color(0xFF9A8E85);
  }
}
