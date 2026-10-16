// Funções compartilhadas pelos scripts do kit de identidade visual.
// Rodar sempre a partir da pasta raiz do paintmanager_app.
import 'dart:io';

const String nomePastaKit = 'kit_identidade_visual';
const String branchTrabalho = 'feat/identidade-visual';
const String arquivoProgresso = 'docs/identidade_visual/PROGRESSO.md';

/// Pasta do kit, descoberta pelo caminho do script (ou pelo nome padrão).
final Directory raizKit = () {
  try {
    final pasta = File.fromUri(Platform.script).parent.parent;
    if (Directory('${pasta.path}/modelos').existsSync()) return pasta;
  } catch (_) {
    // Platform.script nem sempre é um arquivo (ex.: snapshot); usa o padrão.
  }
  return Directory(nomePastaKit);
}();

// ---------------------------------------------------------------------------
// Saída no terminal
// ---------------------------------------------------------------------------

void titulo(String texto) => stdout.writeln('\n=== $texto ===');
void ok(String texto) => stdout.writeln('  [ok] $texto');
void aviso(String texto) => stdout.writeln('  [!]  $texto');
void info(String texto) => stdout.writeln('       $texto');

Never falhar(String texto) {
  stderr.writeln('\n  [ERRO] $texto\n');
  exit(1);
}

// ---------------------------------------------------------------------------
// Projeto e comandos
// ---------------------------------------------------------------------------

/// Confere se o terminal está na raiz do paintmanager_app.
void exigirRaizProjeto() {
  final pubspec = File('pubspec.yaml');
  final nomeCerto = RegExp(r'^name:\s*paintmanager_app\s*$', multiLine: true);
  if (!pubspec.existsSync() || !nomeCerto.hasMatch(pubspec.readAsStringSync())) {
    falhar('Rode este script na pasta raiz do paintmanager_app (onde fica o pubspec.yaml).');
  }
  if (!Directory(nomePastaKit).existsSync()) {
    falhar('Não achei a pasta $nomePastaKit/ na raiz do projeto. Extraia o kit lá.');
  }
}

class ResultadoComando {
  const ResultadoComando(this.codigo, this.saida);
  final int codigo;
  final String saida;
  bool get sucesso => codigo == 0;
}

/// Roda um comando (flutter, dart, git) e devolve código e saída.
Future<ResultadoComando> rodar(String executavel, List<String> argumentos, {bool mostrarSaida = true}) async {
  stdout.writeln('  > $executavel ${argumentos.join(' ')}');
  final r = await Process.run(executavel, argumentos, runInShell: true);
  final saida = '${r.stdout}${r.stderr}';
  if (mostrarSaida && saida.trim().isNotEmpty) {
    for (final linha in saida.trimRight().split('\n')) {
      stdout.writeln('    $linha');
    }
  }
  return ResultadoComando(r.exitCode, saida);
}

/// Copia os arquivos de [origem] para [destino], mantendo as subpastas.
/// Não sobrescreve arquivo existente, a não ser com [sobrescrever].
List<String> copiarPasta(Directory origem, Directory destino, {bool sobrescrever = false}) {
  final copiados = <String>[];
  for (final entidade in origem.listSync(recursive: true)) {
    if (entidade is! File) continue;
    final relativo = entidade.path.substring(origem.path.length + 1);
    final alvo = File('${destino.path}${Platform.pathSeparator}$relativo');
    if (alvo.existsSync() && !sobrescrever) {
      aviso('já existe, mantido: ${alvo.path}');
      continue;
    }
    alvo.parent.createSync(recursive: true);
    entidade.copySync(alvo.path);
    copiados.add(alvo.path);
  }
  return copiados;
}

/// Copia um arquivo dos modelos do kit para o mesmo caminho no projeto.
bool copiarModelo(String caminhoRelativo, {bool sobrescrever = false}) {
  final origem = File('${raizKit.path}/modelos/$caminhoRelativo');
  final destino = File(caminhoRelativo);
  if (!origem.existsSync()) falhar('Modelo não encontrado no kit: $caminhoRelativo');
  if (destino.existsSync() && !sobrescrever) {
    aviso('já existe, mantido (use --forcar para substituir): $caminhoRelativo');
    return false;
  }
  destino.parent.createSync(recursive: true);
  origem.copySync(destino.path);
  ok('criado: $caminhoRelativo');
  return true;
}

/// Insere [novasLinhas] logo depois da primeira linha que casa com [ancora],
/// pulando as que já existem no arquivo. Devolve quantas foram inseridas.
int inserirDepoisDe(File arquivo, RegExp ancora, List<String> novasLinhas) {
  final linhas = arquivo.readAsLinesSync();
  final indice = linhas.indexWhere(ancora.hasMatch);
  if (indice < 0) return -1;
  final faltando = novasLinhas.where((l) => !linhas.any((x) => x.trim() == l.trim())).toList();
  if (faltando.isEmpty) return 0;
  linhas.insertAll(indice + 1, faltando);
  arquivo.writeAsStringSync('${linhas.join('\n')}\n');
  return faltando.length;
}

// ---------------------------------------------------------------------------
// Auditoria: cores, fontes, ícones e sombras fixos nas telas
// ---------------------------------------------------------------------------

/// Arquivos de cada lote da Fase 4 (caminhos a partir de lib/src/, ou
/// começando com lib/).
const Map<String, List<String>> lotes = {
  'A': [
    'lib/main.dart',
    'modules/auth/apresentacao/controllers/auth_controller.dart',
    'apresentacao/widgets/drawer_comum.dart',
    'apresentacao/widgets/guarda_rota.dart',
    'modules/auth/apresentacao/paginas/configuracoes_page.dart',
    'apresentacao/widgets/campo_busca_selecao.dart',
    'apresentacao/widgets/campo_data.dart',
    'apresentacao/widgets/painel_filtro_lista.dart',
    'apresentacao/widgets/chips_filtro_status.dart',
    'modules/auth/apresentacao/paginas/auth_check.dart',
    'apresentacao/controllers/notificacao_controller.dart',
  ],
  'B': [
    'modules/auth/apresentacao/paginas/login_page.dart',
    'modules/auth/apresentacao/paginas/recuperar_senha_page.dart',
    'modules/auth/apresentacao/paginas/redefinir_senha_obrigatoria_page.dart',
    'modules/auth/apresentacao/paginas/alterar_senha_page.dart',
    'modules/auth/apresentacao/paginas/usuario_list_page.dart',
  ],
  'C': [
    'apresentacao/paginas/dashboard_page.dart',
  ],
  'D': [
    'modules/clientes/apresentacao/paginas/cliente_list_page.dart',
    'modules/clientes/apresentacao/paginas/cliente_form_page.dart',
  ],
  'E': [
    'modules/obras/apresentacao/paginas/obra_list_page.dart',
    'modules/obras/apresentacao/paginas/obra_form_page.dart',
    'modules/obras/apresentacao/paginas/obra_detalhes_page.dart',
    'modules/obras/apresentacao/widgets/chat_obra_card.dart',
    'modules/obras/apresentacao/widgets/pdf_lista_materiais_acao.dart',
  ],
  'F': [
    'modules/orcamentos/apresentacao/paginas/orcamento_list_page.dart',
    'modules/orcamentos/apresentacao/paginas/orcamento_form_page.dart',
  ],
  'G': [
    'modules/financeiro/apresentacao/paginas/financeiro_page.dart',
    'modules/financeiro/apresentacao/paginas/transacao_form_page.dart',
  ],
  'H': [
    'modules/relatorios/apresentacao/paginas/relatorios_page.dart',
  ],
};

class Achados {
  int cores = 0;
  int fontes = 0;
  int icones = 0;
  int sombras = 0;
  int googleFonts = 0;

  int get total => cores + fontes + icones + sombras + googleFonts;

  void somar(Achados outro) {
    cores += outro.cores;
    fontes += outro.fontes;
    icones += outro.icones;
    sombras += outro.sombras;
    googleFonts += outro.googleFonts;
  }
}

final _cor = [
  RegExp(r'Colors\.(?!transparent\b)[A-Za-z]+'),
  RegExp(r'\bColor\(0x'),
  RegExp(r'\bPaletaSahara\b'),
  RegExp(r'\b_Sahara\b'),
];
final _fonte = RegExp(r'\bfontSize\s*:');
final _icone = RegExp(r'\bIcons\.[a-z_0-9]+');
final _sombra = [
  RegExp(r'\bboxShadow\s*:'),
  RegExp(r'\belevation\s*:\s*(?!0\b|0\.0\b)[0-9]'),
];
final _googleFonts = RegExp(r'\bGoogleFonts\.');

/// Pastas onde valores fixos são permitidos.
bool _ignorado(String caminho) {
  final c = caminho.replaceAll('\\', '/');
  return c.contains('lib/src/core/tema/') || c.contains('lib/src/core/pdf/');
}

Achados auditarArquivo(File arquivo) {
  final a = Achados();
  for (final linhaBruta in arquivo.readAsLinesSync()) {
    final linha = linhaBruta.trimLeft();
    if (linha.startsWith('//')) continue;
    for (final r in _cor) {
      a.cores += r.allMatches(linha).length;
    }
    a.fontes += _fonte.allMatches(linha).length;
    a.icones += _icone.allMatches(linha).length;
    for (final r in _sombra) {
      a.sombras += r.allMatches(linha).length;
    }
    a.googleFonts += _googleFonts.allMatches(linha).length;
  }
  return a;
}

/// Audita todos os .dart de lib/, fora das pastas permitidas.
Map<String, Achados> auditarProjeto() {
  final resultado = <String, Achados>{};
  for (final e in Directory('lib').listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart') || _ignorado(e.path)) continue;
    // Geradores de PDF usam o pacote pdf, com cores e fontes próprias do documento.
    if (e.readAsStringSync().contains("import 'package:pdf/")) continue;
    final achados = auditarArquivo(e);
    if (achados.total > 0) resultado[e.path.replaceAll('\\', '/')] = achados;
  }
  return resultado;
}

String tabelaAuditoria(Map<String, Achados> mapa, {int limite = 40}) {
  final linhas = mapa.entries.toList()..sort((a, b) => b.value.total.compareTo(a.value.total));
  final b = StringBuffer()
    ..writeln('  ${'arquivo'.padRight(70)} cores fontes ícones sombras gfonts')
    ..writeln('  ${'-' * 70} ----- ------ ------ ------- ------');
  for (final e in linhas.take(limite)) {
    final a = e.value;
    final nome = e.key.replaceFirst('lib/src/', '');
    b.writeln('  ${nome.padRight(70)} ${'${a.cores}'.padLeft(5)} ${'${a.fontes}'.padLeft(6)} '
        '${'${a.icones}'.padLeft(6)} ${'${a.sombras}'.padLeft(7)} ${'${a.googleFonts}'.padLeft(6)}');
  }
  if (linhas.length > limite) b.writeln('  ... e mais ${linhas.length - limite} arquivos');
  return b.toString();
}

// ---------------------------------------------------------------------------
// Verificação completa (analyze + test + auditoria)
// ---------------------------------------------------------------------------

class ResultadoVerificacao {
  int errosAnalise = 0;
  int avisosAnalise = 0;
  int testesOk = 0;
  int testesFalhos = 0;
  bool testesRodaram = false;
  final Achados totalAuditoria = Achados();
  int arquivosComValoresFixos = 0;
  List<String> pendenciasEstritas = [];

  bool get aprovado =>
      errosAnalise == 0 && testesRodaram && testesFalhos == 0 && pendenciasEstritas.isEmpty;
}

/// [arquivosEstritos]: arquivos que precisam estar com zero valores fixos
/// (os do lote verificado, ou todos com --final).
Future<ResultadoVerificacao> verificarProjeto({List<String>? arquivosEstritos}) async {
  final r = ResultadoVerificacao();

  titulo('1/3 flutter analyze');
  final analise = await rodar('flutter', ['analyze', '--no-fatal-infos', '--no-fatal-warnings'], mostrarSaida: false);
  r.errosAnalise = RegExp(r'^\s*error\s+[•-]', multiLine: true).allMatches(analise.saida).length;
  r.avisosAnalise = RegExp(r'^\s*warning\s+[•-]', multiLine: true).allMatches(analise.saida).length;
  for (final linha in analise.saida.split('\n').where((l) => RegExp(r'^\s*(error|warning)\s+[•-]').hasMatch(l))) {
    info(linha.trim());
  }
  if (r.errosAnalise == 0) {
    ok('sem erros (${r.avisosAnalise} avisos)');
  } else {
    aviso('${r.errosAnalise} erro(s) de análise');
  }

  titulo('2/3 flutter test');
  final testes = await rodar('flutter', ['test', '--reporter', 'compact'], mostrarSaida: false);
  final placar = RegExp(r'\+(\d+)(?: ~\d+)?(?: -(\d+))?: (All tests passed|Some tests failed)')
      .allMatches(testes.saida)
      .toList();
  if (placar.isNotEmpty) {
    r.testesRodaram = true;
    r.testesOk = int.parse(placar.last.group(1)!);
    r.testesFalhos = int.tryParse(placar.last.group(2) ?? '0') ?? 0;
  }
  if (!r.testesRodaram) {
    aviso('os testes não rodaram; saída:');
    info(testes.saida.trim().split('\n').take(30).join('\n       '));
  } else if (r.testesFalhos == 0) {
    ok('${r.testesOk} testes passaram');
  } else {
    aviso('${r.testesFalhos} teste(s) falharam (${r.testesOk} passaram)');
    for (final linha in testes.saida.split('\n').where((l) => l.contains('[E]'))) {
      info(linha.trim());
    }
  }

  titulo('3/3 auditoria de valores fixos (cores, fontes, ícones, sombras)');
  final mapa = auditarProjeto();
  for (final a in mapa.values) {
    r.totalAuditoria.somar(a);
  }
  r.arquivosComValoresFixos = mapa.length;
  if (mapa.isEmpty) {
    ok('nenhum valor fixo fora de core/tema e core/pdf');
  } else {
    stdout.write(tabelaAuditoria(mapa));
    info('total: ${r.totalAuditoria.total} em ${mapa.length} arquivos '
        '(cores ${r.totalAuditoria.cores}, fontes ${r.totalAuditoria.fontes}, '
        'ícones ${r.totalAuditoria.icones}, sombras ${r.totalAuditoria.sombras}, '
        'GoogleFonts ${r.totalAuditoria.googleFonts})');
  }

  if (arquivosEstritos != null) {
    for (final caminho in arquivosEstritos) {
      final arquivo = File(caminho);
      if (!arquivo.existsSync()) {
        r.pendenciasEstritas.add('$caminho (arquivo não encontrado: confira o nome)');
        continue;
      }
      final a = auditarArquivo(arquivo);
      if (a.total > 0) {
        r.pendenciasEstritas.add('$caminho → cores ${a.cores}, fontes ${a.fontes}, '
            'ícones ${a.icones}, sombras ${a.sombras}, GoogleFonts ${a.googleFonts}');
      }
    }
    if (r.pendenciasEstritas.isEmpty) {
      ok('arquivos verificados estão limpos');
    } else {
      aviso('ainda há valores fixos em:');
      for (final p in r.pendenciasEstritas) {
        info(p);
      }
    }
  }
  return r;
}

/// Acrescenta uma linha no docs/identidade_visual/PROGRESSO.md.
void registrarProgresso(String etapa, ResultadoVerificacao r) {
  final arquivo = File(arquivoProgresso);
  if (!arquivo.existsSync()) {
    arquivo.parent.createSync(recursive: true);
    arquivo.writeAsStringSync(
      '# Identidade visual — progresso\n\n'
      'Gerado por `dart run $nomePastaKit/ferramentas/verificar.dart`.\n'
      '"Valores fixos" = cores, tamanhos de fonte, ícones antigos, sombras e GoogleFonts fora de `lib/src/core/tema/`.\n\n'
      '| Data | Etapa | Análise (erros/avisos) | Testes (ok/falhas) | Valores fixos restantes | Arquivos | Resultado |\n'
      '|---|---|---|---|---|---|---|\n',
    );
  }
  final agora = DateTime.now();
  String dois(int n) => n.toString().padLeft(2, '0');
  final data = '${dois(agora.day)}/${dois(agora.month)}/${agora.year} ${dois(agora.hour)}:${dois(agora.minute)}';
  final testes = r.testesRodaram ? '${r.testesOk}/${r.testesFalhos}' : 'não rodaram';
  arquivo.writeAsStringSync(
    '| $data | $etapa | ${r.errosAnalise}/${r.avisosAnalise} | $testes | '
    '${r.totalAuditoria.total} | ${r.arquivosComValoresFixos} | ${r.aprovado ? 'aprovado' : 'pendente'} |\n',
    mode: FileMode.append,
  );
  ok('registrado em $arquivoProgresso');
}
