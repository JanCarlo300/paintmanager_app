// FASE 0 — Preparação do projeto para a nova identidade visual.
//
// Uso (na raiz do paintmanager_app):
//   dart run kit_identidade_visual/ferramentas/preparar.dart
//
// O que faz:
//   1. Confere que está na pasta certa e que não há alterações sem commit.
//   2. Cria (ou entra) na branch feat/identidade-visual.
//   3. Copia assets/ do kit (ícone, marca, ilustrações) para o projeto.
//   4. Registra as pastas de assets no pubspec.yaml.
//   5. Exclui a pasta do kit da análise (analysis_options.yaml).
//   6. Adiciona as dependências: flutter_svg, material_symbols_icons,
//      shared_preferences e (dev) flutter_launcher_icons.
//   7. Roda a verificação e registra a linha de base em docs/identidade_visual/PROGRESSO.md.
import 'dart:io';

import 'comum.dart';

Future<void> main(List<String> args) async {
  final pularGit = args.contains('--sem-git');
  final pularDependencias = args.contains('--sem-dependencias');

  titulo('Fase 0 — Preparação');
  exigirRaizProjeto();
  ok('pasta do projeto encontrada');

  // 1-2. Git
  if (!pularGit) {
    titulo('Git');
    final status = await rodar('git', ['status', '--porcelain'], mostrarSaida: false);
    final pendentes = status.saida
        .split('\n')
        .where((l) => l.trim().isNotEmpty && !l.contains(nomePastaKit))
        .toList();
    if (pendentes.isNotEmpty) {
      for (final p in pendentes) {
        info(p);
      }
      falhar('Há alterações sem commit. Faça commit (ou git stash) antes de começar.');
    }
    ok('nenhuma alteração pendente');

    final atual = (await rodar('git', ['branch', '--show-current'], mostrarSaida: false)).saida.trim();
    if (atual == branchTrabalho) {
      ok('já está na branch $branchTrabalho');
    } else {
      final existe = (await rodar('git', ['branch', '--list', branchTrabalho], mostrarSaida: false)).saida.trim().isNotEmpty;
      final r = await rodar('git', existe ? ['checkout', branchTrabalho] : ['checkout', '-b', branchTrabalho]);
      if (!r.sucesso) falhar('Não consegui trocar para a branch $branchTrabalho.');
      ok('trabalhando na branch $branchTrabalho (a main fica intacta até o fim)');
    }
  }

  // 3. Assets
  titulo('Assets (ícone, marca, ilustrações)');
  final copiados = copiarPasta(Directory('${raizKit.path}/assets'), Directory('assets'));
  ok('${copiados.length} arquivo(s) copiado(s) para assets/');

  // 4. pubspec: pastas de assets
  titulo('pubspec.yaml — pastas de assets');
  final inseridas = inserirDepoisDe(File('pubspec.yaml'), RegExp(r'^  assets:\s*$'), [
    '    # Identidade visual (manual da marca)',
    '    - assets/marca/',
    '    - assets/ilustracoes/claro/',
    '    - assets/ilustracoes/escuro/',
  ]);
  if (inseridas < 0) {
    falhar('Não achei a linha "  assets:" dentro de "flutter:" no pubspec.yaml. Registre as pastas à mão.');
  }
  ok(inseridas == 0 ? 'pastas já registradas' : '$inseridas linha(s) adicionada(s)');

  // 5. analysis_options: ignorar o kit
  titulo('analysis_options.yaml — ignorar a pasta do kit');
  final excluidas = inserirDepoisDe(File('analysis_options.yaml'), RegExp(r'^  exclude:\s*$'), [
    '    - $nomePastaKit/**',
  ]);
  if (excluidas < 0) {
    aviso('não achei "  exclude:" em analysis_options.yaml; adicione "$nomePastaKit/**" à mão');
  } else {
    ok(excluidas == 0 ? 'já estava excluída' : 'pasta do kit excluída da análise');
  }

  // 6. Dependências
  if (!pularDependencias) {
    titulo('Dependências');
    final r = await rodar('flutter', [
      'pub',
      'add',
      'flutter_svg',
      'material_symbols_icons',
      'shared_preferences',
      'dev:flutter_launcher_icons',
    ]);
    if (!r.sucesso) falhar('flutter pub add falhou. Confira a internet e rode de novo.');
    ok('dependências adicionadas');
  }

  // 7. Linha de base
  titulo('Linha de base');
  final v = await verificarProjeto();
  registrarProgresso('Fase 0 — linha de base', v);

  titulo('Pronto');
  if (v.errosAnalise > 0 || (v.testesRodaram && v.testesFalhos > 0)) {
    aviso('O projeto já tinha erros ou testes falhando ANTES da troca. Corrija antes da Fase 1.');
  }
  info('Próximo passo: revise as mudanças (git diff) e faça o commit da Fase 0:');
  info('  git add -A && git commit -m "chore(tema): fase 0 - kit, assets e dependências da nova identidade visual"');
  info('Depois: dart run $nomePastaKit/ferramentas/aplicar.dart 1');
  exit(0);
}
