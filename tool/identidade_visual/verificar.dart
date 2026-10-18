// Verificação depois de cada fase ou lote: flutter analyze + flutter test +
// auditoria de cores, fontes, ícones e sombras fixos. Registra o resultado
// em docs/identidade_visual/PROGRESSO.md.
//
// Uso (na raiz do paintmanager_app):
//   dart run tool/identidade_visual/verificar.dart                 só relatório
//   dart run tool/identidade_visual/verificar.dart --lote E        exige o lote E limpo
//   dart run tool/identidade_visual/verificar.dart --final         exige o app inteiro limpo
//   dart run tool/identidade_visual/verificar.dart --etapa "Fase 1"   nome no registro
//
// Sai com código 1 se houver erro de análise, teste falhando ou (com --lote/--final)
// valor fixo restante nos arquivos exigidos.
import 'dart:io';

import 'comum.dart';

Future<void> main(List<String> args) async {
  exigirRaizProjeto();

  String? valorDe(String opcao) {
    final i = args.indexOf(opcao);
    return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
  }

  final lote = valorDe('--lote')?.toUpperCase();
  final ehFinal = args.contains('--final');
  List<String>? estritos;
  var etapa = valorDe('--etapa') ?? 'Verificação';

  if (lote != null) {
    final arquivos = lotes[lote];
    if (arquivos == null) falhar('Lote desconhecido: $lote. Use A, B, C, D, E, F, G ou H.');
    estritos = arquivos.map((a) => a.startsWith('lib/') ? a : 'lib/src/$a').toList();
    if (valorDe('--etapa') == null) etapa = 'Fase 4 — Lote $lote';
  } else if (ehFinal) {
    estritos = auditarProjeto().keys.toList();
    if (valorDe('--etapa') == null) etapa = 'Verificação final';
  }

  final r = await verificarProjeto(arquivosEstritos: estritos);

  titulo('Resultado: ${r.aprovado ? 'APROVADO' : 'PENDENTE'}');
  registrarProgresso(etapa, r);
  if (!r.aprovado) {
    if (r.errosAnalise > 0) aviso('corrigir os erros do flutter analyze');
    if (!r.testesRodaram) aviso('os testes não rodaram');
    if (r.testesFalhos > 0) aviso('corrigir os testes que falharam');
    if (r.pendenciasEstritas.isNotEmpty) aviso('remover os valores fixos listados acima');
    exit(1);
  }
  ok('nenhum valor fixo pendente nos arquivos verificados');
  exit(0);
}
