// Copia os modelos de código do kit para o projeto, fase a fase.
//
// Uso (na raiz do paintmanager_app):
//   dart run kit_identidade_visual/ferramentas/aplicar.dart <fase> [--forcar]
//
//   1  Fundação do tema: lib/src/core/tema/ (cores, medidas, tipografia,
//      status, tema) + ponte temporária da PaletaSahara + testes.
//   2  Componentes: StatusChip, CardApp, CardDestaque, IconeModulo,
//      TelaVazia, LogoApp/AssinaturaApp + teste.
//   3  Ícone do app: configuração do flutter_launcher_icons e geração.
//   5  Modo escuro: TemaController + teste.
//
// --forcar substitui arquivos que já existem.
//
// O script NÃO edita telas nem o main.dart: isso é trabalho do agente,
// seguindo o PASSO_A_PASSO.md.
import 'dart:io';

import 'comum.dart';

Future<void> main(List<String> args) async {
  exigirRaizProjeto();
  final fase = args.where((a) => !a.startsWith('--')).firstOrNull;
  final forcar = args.contains('--forcar');

  switch (fase) {
    case '1':
      _fase1(forcar);
    case '2':
      _fase2(forcar);
    case '3':
      await _fase3();
    case '5':
      _fase5(forcar);
    default:
      falhar('Informe a fase: 1, 2, 3 ou 5. Ex.: dart run $nomePastaKit/ferramentas/aplicar.dart 1');
  }
  exit(0);
}

void _fase1(bool forcar) {
  titulo('Fase 1 — Fundação do tema');
  for (final arquivo in [
    'lib/src/core/tema/cores_app.dart',
    'lib/src/core/tema/medidas_app.dart',
    'lib/src/core/tema/tipografia_app.dart',
    'lib/src/core/tema/status_visual.dart',
    'lib/src/core/tema/tema_app.dart',
    'test/core/tema/cores_app_test.dart',
    'test/core/tema/status_visual_test.dart',
  ]) {
    copiarModelo(arquivo, sobrescrever: forcar);
  }

  // Ponte: as telas antigas continuam usando PaletaSahara até a Fase 4,
  // mas já com os valores novos do manual.
  final paleta = File('lib/src/core/tema/paleta_sahara.dart');
  if (paleta.existsSync() && !paleta.readAsStringSync().contains('PONTE TEMPORÁRIA')) {
    paleta.writeAsStringSync('''import 'package:flutter/material.dart';

/// PONTE TEMPORÁRIA da identidade visual (Fase 1).
///
/// Mantém as telas antigas compilando com os valores NOVOS do manual
/// (tema claro) enquanto elas migram para `context.cores` na Fase 4.
/// Este arquivo é apagado na Fase 5. Não use em código novo.
class PaletaSahara {
  PaletaSahara._();

  static const background = Color(0xFFFAF5EE); // surface
  static const primary = Color(0xFFA5521F); // primary (antes #C2652A)
  static const tertiary = Color(0xFF8C3C3C); // secondary
  static const border = Color(0xFFD8D0C8); // border
  static const cardSurface = Color(0xFFFFFFFF); // surfaceCard
  static const onSurface = Color(0xFF3A302A); // ink
  static const onSurfaceMuted = Color(0xFF6B5E55); // inkMuted (antes #9A8E85)
}
''');
    ok('paleta_sahara.dart virou ponte temporária com os valores novos');
  } else {
    aviso('paleta_sahara.dart não encontrada ou já convertida');
  }

  titulo('Agora é com o agente (PASSO_A_PASSO.md, Fase 1)');
  info('1. No main.dart: import do tema_app.dart; theme: temaClaro(), darkTheme: temaEscuro(),');
  info('   themeMode: ThemeMode.light. Remover o ThemeData antigo (o datePickerTheme já está no tema novo).');
  info('2. Rodar: dart run $nomePastaKit/ferramentas/verificar.dart --etapa "Fase 1"');
}

void _fase2(bool forcar) {
  titulo('Fase 2 — Componentes compartilhados');
  for (final arquivo in [
    'lib/src/apresentacao/widgets/status_chip.dart',
    'lib/src/apresentacao/widgets/card_app.dart',
    'lib/src/apresentacao/widgets/card_destaque.dart',
    'lib/src/apresentacao/widgets/icone_modulo.dart',
    'lib/src/apresentacao/widgets/tela_vazia.dart',
    'lib/src/apresentacao/widgets/logo_app.dart',
    'test/apresentacao/widgets/status_chip_test.dart',
  ]) {
    copiarModelo(arquivo, sobrescrever: forcar);
  }
  titulo('Próximo');
  info('Rodar: dart run $nomePastaKit/ferramentas/verificar.dart --etapa "Fase 2"');
}

Future<void> _fase3() async {
  titulo('Fase 3 — Ícone do app');
  final pubspec = File('pubspec.yaml');
  final texto = pubspec.readAsStringSync();
  if (texto.contains(RegExp(r'^flutter_launcher_icons:', multiLine: true))) {
    ok('configuração do flutter_launcher_icons já existe no pubspec.yaml');
  } else {
    pubspec.writeAsStringSync('''${texto.trimRight()}

# Ícone do app (manual da marca, opção D — pincel). Gerar com:
#   dart run flutter_launcher_icons
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icone/icone_app.png"
  remove_alpha_ios: true
  adaptive_icon_background: "#3A302A"
  adaptive_icon_foreground: "assets/icone/icone_foreground.png"
  adaptive_icon_monochrome: "assets/icone/icone_monocromatico.png"
''');
    ok('configuração adicionada ao fim do pubspec.yaml');
  }
  final r = await rodar('dart', ['run', 'flutter_launcher_icons']);
  if (!r.sucesso) falhar('A geração do ícone falhou. Confira se a Fase 0 adicionou o flutter_launcher_icons.');
  ok('ícones gerados em android/app/src/main/res e ios/Runner/Assets.xcassets');
  titulo('Agora é com o agente (PASSO_A_PASSO.md, Fase 3)');
  info('Login, menu lateral e PDF com a marca nova. Depois desinstale o app do celular e instale de novo');
  info('para o Android mostrar o ícone novo.');
}

void _fase5(bool forcar) {
  titulo('Fase 5 — Modo escuro');
  copiarModelo('lib/src/core/tema/tema_controller.dart', sobrescrever: forcar);
  copiarModelo('test/core/tema/tema_controller_test.dart', sobrescrever: forcar);
  titulo('Agora é com o agente (PASSO_A_PASSO.md, Fase 5)');
  info('main.dart: SharedPreferences.getInstance() antes do runApp, TemaController no MultiProvider,');
  info('themeMode: context.watch<TemaController>().modo; tela Configurações; apagar paleta_sahara.dart.');
}
