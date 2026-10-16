import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/pdf/pdf_service.dart';
import '../../financeiro/dominio/entidades/transacao.dart';
import '../../obras/dominio/entidades/obra.dart';
import '../../orcamentos/dominio/entidades/orcamento.dart';

/// Etapa 8.1 (RF012) — relatórios em PDF: Financeiro e Progresso, por
/// período e, opcionalmente, por obra.

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _data = DateFormat('dd/MM/yyyy', 'pt_BR');

const statusObraComFinanceiro = {'Em Andamento', 'Concluída'};

/// Regra do DERS: relatório financeiro só considera obras em andamento ou
/// concluídas. Lançamento sem obra (despesa geral) entra normalmente.
List<Transacao> filtrarLancamentosValidos(List<Transacao> transacoes, Map<int, String> statusDasObras) {
  return transacoes
      .where((t) => t.idObra == null || statusObraComFinanceiro.contains(statusDasObras[t.idObra]))
      .toList();
}

class ResumoFinanceiro {
  final double receitas;
  final double despesas;
  final Map<String, double> despesasPorCategoria;

  const ResumoFinanceiro({
    required this.receitas,
    required this.despesas,
    required this.despesasPorCategoria,
  });

  double get saldo => receitas - despesas;

  factory ResumoFinanceiro.calcular(List<Transacao> transacoes) {
    var receitas = 0.0;
    var despesas = 0.0;
    final porCategoria = <String, double>{};
    for (final t in transacoes) {
      if (t.isReceita) {
        receitas += t.valor;
      } else if (t.isDespesa) {
        despesas += t.valor;
        porCategoria[t.categoria] = (porCategoria[t.categoria] ?? 0) + t.valor;
      }
    }
    return ResumoFinanceiro(receitas: receitas, despesas: despesas, despesasPorCategoria: porCategoria);
  }
}

pw.Widget _filtros(DateTime inicio, DateTime fim, String? obraTitulo) => PdfService.secao('Filtros', [
      PdfService.campo('Período', '${_data.format(inicio)} a ${_data.format(fim)}'),
      PdfService.campo('Obra', obraTitulo ?? 'Todas as obras'),
    ]);

pw.Widget _tabela({
  required List<String> cabecalho,
  required List<List<String>> linhas,
  Map<int, pw.TableColumnWidth>? larguras,
  Map<int, pw.Alignment>? alinhamentos,
}) {
  return pw.TableHelper.fromTextArray(
    headers: cabecalho,
    data: linhas,
    headerStyle: pw.TextStyle(fontSize: 9, color: PdfService.corTexto, fontWeight: pw.FontWeight.bold),
    cellStyle: pw.TextStyle(fontSize: 9, color: PdfService.corTexto),
    headerDecoration: pw.BoxDecoration(color: PdfService.corFundoClaro),
    border: pw.TableBorder.all(color: PdfService.corBorda, width: 0.5),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    columnWidths: larguras,
    cellAlignments: alinhamentos ?? const {},
  );
}

pw.Widget _vazio(String texto) =>
    pw.Text(texto, style: pw.TextStyle(fontSize: 10, color: PdfService.corSecundaria));

Future<Uint8List> gerarPdfRelatorioFinanceiro({
  required DateTime inicio,
  required DateTime fim,
  String? obraTitulo,
  required List<Transacao> lancamentos,
  required List<Orcamento> orcamentosAprovados,
  DateTime? geradoEm,
}) {
  final resumo = ResumoFinanceiro.calcular(lancamentos);
  final totalAprovado = orcamentosAprovados.fold<double>(0, (s, o) => s + o.valorTotal);
  final ordenados = [...lancamentos]..sort((a, b) => a.dataTransacao.compareTo(b.dataTransacao));

  return PdfService.gerar(
    titulo: 'Relatório Financeiro',
    geradoEm: geradoEm,
    conteudo: [
      _filtros(inicio, fim, obraTitulo),
      PdfService.secao('Resumo', [
        PdfService.campo('Receitas', _moeda.format(resumo.receitas)),
        PdfService.campo('Despesas', _moeda.format(resumo.despesas)),
        PdfService.campo(resumo.saldo >= 0 ? 'Lucro' : 'Prejuízo', _moeda.format(resumo.saldo.abs())),
        PdfService.campo(
          'Orçamentos aprovados no período',
          '${orcamentosAprovados.length} (total ${_moeda.format(totalAprovado)})',
        ),
      ]),
      PdfService.secao('Despesas por categoria', [
        if (resumo.despesasPorCategoria.isEmpty)
          _vazio('Nenhuma despesa no período.')
        else
          _tabela(
            cabecalho: ['Categoria', 'Valor'],
            linhas: [
              for (final e in (resumo.despesasPorCategoria.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value))))
                [e.key, _moeda.format(e.value)],
            ],
            alinhamentos: {1: pw.Alignment.centerRight},
          ),
      ]),
      PdfService.secao('Lançamentos (${ordenados.length})', [
        if (ordenados.isEmpty)
          _vazio('Nenhum lançamento no período.')
        else
          _tabela(
            cabecalho: ['Data', 'Tipo', 'Descrição', 'Obra', 'Status', 'Valor'],
            linhas: [
              for (final t in ordenados)
                [
                  _data.format(t.dataTransacao),
                  t.tipo,
                  t.descricao,
                  (t.obraTitulo?.isNotEmpty ?? false) ? t.obraTitulo! : '—',
                  t.status,
                  '${t.isDespesa ? '-' : ''}${_moeda.format(t.valor)}',
                ],
            ],
            larguras: {
              0: const pw.FixedColumnWidth(54),
              1: const pw.FixedColumnWidth(46),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FixedColumnWidth(52),
              5: const pw.FixedColumnWidth(66),
            },
            alinhamentos: {5: pw.Alignment.centerRight},
          ),
      ]),
      pw.Text(
        'Considera apenas lançamentos sem obra ou de obras Em Andamento/Concluídas, '
        'e apenas orçamentos Aprovados (regra do DERS).',
        style: pw.TextStyle(fontSize: 8, color: PdfService.corSecundaria),
      ),
    ],
  );
}

Future<Uint8List> gerarPdfRelatorioProgresso({
  required DateTime inicio,
  required DateTime fim,
  String? obraTitulo,
  required List<Obra> obras,
  DateTime? hoje,
  DateTime? geradoEm,
}) {
  final dia = DateTime((hoje ?? DateTime.now()).year, (hoje ?? DateTime.now()).month, (hoje ?? DateTime.now()).day);

  return PdfService.gerar(
    titulo: 'Relatório de Progresso',
    geradoEm: geradoEm,
    conteudo: [
      _filtros(inicio, fim, obraTitulo),
      if (obras.isEmpty)
        _vazio('Nenhuma obra iniciada no período.')
      else ...[
        PdfService.secao('Resumo', [
          PdfService.campo('Obras', '${obras.length}'),
          PdfService.campo('Em andamento', '${obras.where((o) => o.status == 'Em Andamento').length}'),
          PdfService.campo('Pausadas', '${obras.where((o) => o.status == 'Pausada').length}'),
          PdfService.campo('Concluídas', '${obras.where((o) => o.status == 'Concluída').length}'),
        ]),
        for (final o in obras)
          PdfService.secao(o.tituloDaObra, [
            PdfService.campo('Cliente', o.clienteNome),
            PdfService.campo(
              'Status',
              o.status != 'Concluída' && o.dataPrevisaoTermino.isBefore(dia)
                  ? '${o.status} (atrasada)'
                  : o.status,
            ),
            PdfService.campo(
              'Período',
              '${_data.format(o.dataInicio)} a ${_data.format(o.dataPrevisaoTermino)}'
                  '${o.dataConclusao != null ? ' — concluída em ${_data.format(o.dataConclusao!)}' : ''}',
            ),
            PdfService.campo('Progresso', '${o.progresso.toStringAsFixed(0)}%'),
            pw.SizedBox(height: 4),
            if (o.etapasServico.isEmpty)
              _vazio('Sem etapas cadastradas.')
            else
              _tabela(
                cabecalho: ['#', 'Etapa', 'Situação'],
                linhas: [
                  for (final (i, e) in o.etapasServico.indexed)
                    ['${i + 1}', e.nome, e.concluida ? 'Concluída' : 'Pendente'],
                ],
                larguras: {
                  0: const pw.FixedColumnWidth(22),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FixedColumnWidth(64),
                },
                alinhamentos: {0: pw.Alignment.center},
              ),
          ]),
      ],
    ],
  );
}
