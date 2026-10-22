import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:paintmanager_app/src/modules/financeiro/dominio/entidades/transacao.dart';
import 'package:paintmanager_app/src/modules/obras/dominio/entidades/etapa_servico.dart';
import 'package:paintmanager_app/src/modules/obras/dominio/entidades/obra.dart';
import 'package:paintmanager_app/src/modules/orcamentos/dominio/entidades/item_servico.dart';
import 'package:paintmanager_app/src/modules/orcamentos/dominio/entidades/orcamento.dart';
import 'package:paintmanager_app/src/modules/relatorios/dominio/pdf_relatorios.dart';

Transacao _t(String tipo, double valor, {String categoria = 'Outros', int? idObra}) => Transacao(
      tipo: tipo,
      categoria: categoria,
      valor: valor,
      descricao: '$tipo de teste',
      dataTransacao: DateTime(2026, 10, 10),
      idObra: idObra,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('ResumoFinanceiro.calcular', () {
    test('soma receitas, despesas, saldo e despesas por categoria', () {
      final r = ResumoFinanceiro.calcular([
        _t('Receita', 1000),
        _t('Receita', 500),
        _t('Despesa', 200, categoria: 'Materiais'),
        _t('Despesa', 50, categoria: 'Materiais'),
        _t('Despesa', 100, categoria: 'Transporte'),
      ]);

      expect(r.receitas, 1500);
      expect(r.despesas, 350);
      expect(r.saldo, 1150);
      expect(r.despesasPorCategoria, {'Materiais': 250, 'Transporte': 100});
    });

    test('lista vazia dá tudo zero', () {
      final r = ResumoFinanceiro.calcular([]);
      expect(r.receitas, 0);
      expect(r.despesas, 0);
      expect(r.saldo, 0);
      expect(r.despesasPorCategoria, isEmpty);
    });
  });

  group('filtrarLancamentosValidos (regra do DERS)', () {
    test('mantém sem obra e de obras Em Andamento/Concluída; tira as demais', () {
      final lancamentos = [
        _t('Despesa', 10),               // sem obra -> entra
        _t('Receita', 20, idObra: 1),    // Em Andamento -> entra
        _t('Receita', 30, idObra: 2),    // Concluída -> entra
        _t('Despesa', 40, idObra: 3),    // Não Iniciada -> sai
        _t('Despesa', 50, idObra: 4),    // obra sem status conhecido -> sai
      ];
      final validos = filtrarLancamentosValidos(lancamentos, {
        1: 'Em Andamento',
        2: 'Concluída',
        3: 'Não Iniciada',
      });

      expect(validos.map((t) => t.valor), [10, 20, 30]);
    });
  });

  group('obraEmExecucaoNoPeriodo (relatório de progresso)', () {
    final inicio = DateTime(2026, 10, 1);
    final fim = DateTime(2026, 10, 31);

    Obra obra(String status, DateTime ini, DateTime previsao, {DateTime? concluida}) => Obra(
          idCliente: 1,
          clienteNome: 'C',
          tituloDaObra: 'O',
          endereco: '',
          dataInicio: ini,
          dataPrevisaoTermino: previsao,
          dataConclusao: concluida,
          status: status,
          etapasServico: const [],
        );

    test('Não Iniciada nunca entra', () {
      expect(obraEmExecucaoNoPeriodo(obra('Não Iniciada', DateTime(2026, 10, 5), DateTime(2026, 10, 20)), inicio, fim), isFalse);
    });

    test('Em Andamento com início depois do período: não entra se ainda não chegou', () {
      final o = obra('Em Andamento', DateTime(2026, 11, 2), DateTime(2026, 11, 20));
      // Relatório de outubro tirado em dezembro: começou em novembro, fora.
      expect(obraEmExecucaoNoPeriodo(o, inicio, fim, hoje: DateTime(2026, 12, 1)), isFalse);
      // Mas se já está rodando hoje (21/10), está em execução em outubro.
      expect(obraEmExecucaoNoPeriodo(o, inicio, fim, hoje: DateTime(2026, 10, 21)), isTrue);
    });

    test('Em Andamento atrasada (previsão antes do período) entra', () {
      expect(obraEmExecucaoNoPeriodo(obra('Em Andamento', DateTime(2026, 9, 1), DateTime(2026, 9, 20)), inicio, fim), isTrue);
    });

    test('Pausada que começou antes entra', () {
      expect(obraEmExecucaoNoPeriodo(obra('Pausada', DateTime(2026, 8, 1), DateTime(2026, 12, 1)), inicio, fim), isTrue);
    });

    test('Concluída: entra se terminou no período ou depois; sai se terminou antes', () {
      final noPeriodo = obra('Concluída', DateTime(2026, 9, 1), DateTime(2026, 9, 30), concluida: DateTime(2026, 10, 3));
      final antes = obra('Concluída', DateTime(2026, 9, 1), DateTime(2026, 9, 30), concluida: DateTime(2026, 9, 28));
      final semDataConclusao = obra('Concluída', DateTime(2026, 9, 1), DateTime(2026, 10, 1));

      expect(obraEmExecucaoNoPeriodo(noPeriodo, inicio, fim), isTrue);
      expect(obraEmExecucaoNoPeriodo(antes, inicio, fim), isFalse);
      expect(obraEmExecucaoNoPeriodo(semDataConclusao, inicio, fim), isTrue);
    });

    test('Concluída antes do início previsto entra pelo dia da conclusão', () {
      // Caso real: "Pintura Quarto", início previsto 07/11, concluída 19/10.
      final o = obra('Concluída', DateTime(2026, 11, 7), DateTime(2026, 11, 30), concluida: DateTime(2026, 10, 19));
      expect(obraEmExecucaoNoPeriodo(o, inicio, fim), isTrue);
      expect(obraEmExecucaoNoPeriodo(o, DateTime(2026, 11, 1), DateTime(2026, 11, 30)), isFalse);
    });
  });

  group('PDFs do RF012', () {
    test('Relatório Financeiro gera PDF válido', () async {
      final bytes = await gerarPdfRelatorioFinanceiro(
        inicio: DateTime(2026, 10, 1),
        fim: DateTime(2026, 10, 31),
        obraTitulo: 'Pintura Externa — Casa Centro',
        lancamentos: [_t('Receita', 1500), _t('Despesa', 230.5, categoria: 'Materiais')],
        orcamentosAprovados: [
          Orcamento(
            clienteNome: 'José',
            descricao: 'Pintura',
            dataCriacao: DateTime(2026, 10, 2),
            dataValidade: DateTime(2026, 11, 2),
            status: 'Aprovado',
            itensServico: [ItemServico(descricao: 'Parede', metragem: 10, valorUnitario: 20)],
            valorMaoDeObra: 300,
          ),
        ],
      );
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('Relatório de Progresso gera PDF válido, inclusive sem obras', () async {
      final obra = Obra(
        idCliente: 1,
        clienteNome: 'Maria',
        tituloDaObra: 'Fachada',
        endereco: 'Rua A',
        dataInicio: DateTime(2026, 10, 1),
        dataPrevisaoTermino: DateTime(2026, 10, 5),
        status: 'Em Andamento',
        etapasServico: [EtapaServico(nome: 'Lixamento', concluida: true), EtapaServico(nome: 'Pintura')],
      );

      final comObras = await gerarPdfRelatorioProgresso(
        inicio: DateTime(2026, 10, 1),
        fim: DateTime(2026, 10, 31),
        obras: [obra],
        hoje: DateTime(2026, 10, 15),
      );
      final semObras = await gerarPdfRelatorioProgresso(
        inicio: DateTime(2026, 10, 1),
        fim: DateTime(2026, 10, 31),
        obras: const [],
      );

      expect(ascii.decode(comObras.sublist(0, 5)), '%PDF-');
      expect(ascii.decode(semObras.sublist(0, 5)), '%PDF-');
    });
  });
}
