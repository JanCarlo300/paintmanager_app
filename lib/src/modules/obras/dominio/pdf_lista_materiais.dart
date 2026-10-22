import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/pdf/pdf_service.dart';
import 'entidades/obra.dart';

/// Etapa 6b — PDF da Lista de Materiais da obra: cliente, obra, materiais
/// numerados e observação opcional (decisão do Jan, 15/10/2026: sem o
/// período da obra).
Future<Uint8List> gerarPdfListaMateriais(
  Obra obra, {
  String clienteTelefone = '',
  String observacao = '',
  DateTime? geradoEm,
}) {
  final cabecalhoTabela = pw.TextStyle(
    fontSize: 10,
    color: PdfService.corTexto,
    fontWeight: pw.FontWeight.bold,
  );
  final textoTabela = pw.TextStyle(fontSize: 10, color: PdfService.corTexto);

  return PdfService.gerar(
    titulo: 'Lista de Materiais',
    geradoEm: geradoEm,
    conteudo: [
      PdfService.secao('Cliente', [
        PdfService.campo('Nome', obra.clienteNome),
        PdfService.campo('Telefone', clienteTelefone),
      ]),
      PdfService.secao('Obra', [
        PdfService.campo('Título', obra.tituloDaObra),
        PdfService.campo('Endereço', obra.enderecoCompleto),
      ]),
      PdfService.secao('Materiais (${obra.listaMateriais.length})', [
        if (obra.listaMateriais.isEmpty)
          pw.Text('Nenhum material na lista.', style: textoTabela)
        else
          pw.TableHelper.fromTextArray(
            headers: ['#', 'Descrição', 'Qtd.', 'Unidade'],
            data: [
              for (final (i, item) in obra.listaMateriais.indexed)
                ['${i + 1}', item.descricao, item.quantidadeFormatada, item.unidade],
            ],
            headerStyle: cabecalhoTabela,
            cellStyle: textoTabela,
            headerDecoration: pw.BoxDecoration(color: PdfService.corFundoClaro),
            border: pw.TableBorder.all(color: PdfService.corBorda, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FlexColumnWidth(5),
              2: const pw.FixedColumnWidth(48),
              3: const pw.FlexColumnWidth(2),
            },
            cellAlignments: {
              0: pw.Alignment.center,
              2: pw.Alignment.centerRight,
            },
          ),
      ]),
      if (observacao.trim().isNotEmpty)
        PdfService.secao('Observação', [
          pw.Text(observacao.trim(), style: textoTabela),
        ]),
    ],
  );
}
