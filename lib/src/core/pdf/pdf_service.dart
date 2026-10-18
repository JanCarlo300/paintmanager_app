import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Serviço de PDF do app (etapa 6b / RF012). Gera o documento no próprio
/// celular — sem internet, sem API, sem custo — com cabeçalho e rodapé
/// padrão nas cores do manual da marca. Os relatórios do RF012 reaproveitam
/// este serviço. O PDF é sempre claro (documento para o cliente).
class PdfService {
  static final corPrimaria = PdfColor.fromInt(0xFFA5521F);
  static final corTexto = PdfColor.fromInt(0xFF3A302A);
  static final corSecundaria = PdfColor.fromInt(0xFF6B5E55);
  static final corBorda = PdfColor.fromInt(0xFFD8D0C8);
  static final corFundoClaro = PdfColor.fromInt(0xFFFAF5EE);

  // A fonte padrão do PDF (Helvetica) não tem Unicode completo: travessão e
  // alguns símbolos saem em branco. Roboto vai embutida nos assets do app.
  static pw.ThemeData? _tema;

  static Future<pw.ThemeData> _carregarTema() async {
    return _tema ??= pw.ThemeData.withFont(
      base: pw.Font.ttf(await rootBundle.load('assets/fonts/roboto-regular.ttf')),
      bold: pw.Font.ttf(await rootBundle.load('assets/fonts/roboto-bold.ttf')),
    );
  }

  // Símbolo da marca (pincel sem fundo) do cabeçalho. Se o arquivo não
  // carregar, o cabeçalho sai só com o texto — o PDF nunca deixa de ser gerado.
  static String? _simbolo;
  static bool _simboloLido = false;

  static Future<String?> _carregarSimbolo() async {
    if (!_simboloLido) {
      _simboloLido = true;
      try {
        _simbolo = await rootBundle.loadString('assets/marca/simbolo.svg');
      } catch (_) {
        _simbolo = null;
      }
    }
    return _simbolo;
  }

  /// Monta o PDF: cabeçalho (símbolo + PaintManager + [titulo] + data de
  /// geração), o [conteudo] e rodapé com número da página. [simboloSvg]
  /// substitui o símbolo padrão (útil em testes).
  static Future<Uint8List> gerar({
    required String titulo,
    required List<pw.Widget> conteudo,
    DateTime? geradoEm,
    String? simboloSvg,
  }) async {
    final data = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(geradoEm ?? DateTime.now());
    final simbolo = simboloSvg ?? await _carregarSimbolo();
    final doc = pw.Document(title: titulo, author: 'PaintManager', theme: await _carregarTema());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          margin: const pw.EdgeInsets.only(bottom: 16),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: corPrimaria, width: 2)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (simbolo != null) ...[
                    pw.SvgImage(svg: simbolo, width: 34, height: 34),
                    pw.SizedBox(width: 8),
                  ],
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PaintManager',
                          style: pw.TextStyle(fontSize: 11, color: corPrimaria, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(titulo,
                          style: pw.TextStyle(fontSize: 18, color: corTexto, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.Text('Gerado em $data', style: pw.TextStyle(fontSize: 9, color: corSecundaria)),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: corSecundaria)),
        ),
        build: (context) => conteudo,
      ),
    );

    return doc.save();
  }

  /// Abre o "compartilhar" do Android/iOS (WhatsApp, e-mail, Drive, salvar).
  static Future<void> compartilhar(Uint8List bytes, String nomeArquivo) {
    return Printing.sharePdf(bytes: bytes, filename: nomeArquivo);
  }

  /// "Pintura Externa — Casa Centro!" -> "pintura-externa-casa-centro"
  static String nomeSeguro(String texto) {
    const deParaAcentos = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
      'é': 'e', 'ê': 'e', 'è': 'e', 'í': 'i', 'î': 'i',
      'ó': 'o', 'ô': 'o', 'õ': 'o', 'ò': 'o', 'ú': 'u', 'ü': 'u', 'ç': 'c',
    };
    final semAcento = texto.toLowerCase().split('').map((c) => deParaAcentos[c] ?? c).join();
    final limpo = semAcento.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    return limpo.isEmpty ? 'documento' : limpo;
  }

  // --- Blocos reutilizáveis de conteúdo ---

  static pw.Widget secao(String titulo, List<pw.Widget> filhos) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(titulo.toUpperCase(),
                style: pw.TextStyle(fontSize: 9, color: corSecundaria, fontWeight: pw.FontWeight.bold, letterSpacing: 0.5)),
            pw.SizedBox(height: 4),
            ...filhos,
          ],
        ),
      );

  static pw.Widget campo(String rotulo, String valor) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(text: '$rotulo: ', style: pw.TextStyle(fontSize: 10, color: corSecundaria)),
            pw.TextSpan(text: valor.isEmpty ? '—' : valor, style: pw.TextStyle(fontSize: 10, color: corTexto)),
          ]),
        ),
      );
}
