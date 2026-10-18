# PaintManager — Plano de implementação da nova identidade visual

> **Concluído em 18/10/2026.** Este documento guiou a implantação e foi mantido como registro. A pasta `kit_identidade_visual/` citada abaixo foi removida na Fase 6: o código dos modelos está em `lib/src/core/tema/` e `lib/src/apresentacao/widgets/`, e a auditoria continua disponível com `dart run tool/identidade_visual/verificar.dart --final`. Placar em `PROGRESSO.md`.

> **Para o agente:** este arquivo organiza a troca da identidade visual "Sahara" pela identidade aprovada pelo Jan em 15/10/2026 (manual: *PaintManager Design System*). Leia tudo antes de começar. Execute **uma fase por vez, na ordem**, e só avance depois que o Jan testar e aprovar. Base: `main` em `19c5f31`.

> **Como executar:** siga o `PASSO_A_PASSO.md`. Ele usa os scripts de `ferramentas/` (preparar, aplicar, verificar) e o código pronto de `modelos/` (tema, componentes e testes), que já seguem os tokens deste plano.

---

## Regras de trabalho

1. **Uma fase (ou um lote da Fase 4) por vez.** Antes, diga em poucas linhas o que vai mudar. Depois, liste o que o Jan deve testar no celular.
2. **🛑 CONSULTAR** = perguntar ao Jan antes de implementar.
3. **Um commit por fase/lote**, no padrão do projeto (`feat(tema): ...`, `refactor(obras): ...`).
4. **Nenhuma cor, tamanho de fonte ou sombra fixos nas telas.** Tudo vem do tema (`Theme.of(context)`) ou da extensão `CoresApp` (`context.cores`). Hex só existe dentro de `lib/src/core/tema/`.
5. **Não mudar comportamento.** Esta é uma troca visual: regras, permissões e consultas ao banco continuam iguais.
6. Os **42 testes** precisam continuar passando ao fim de cada fase (`flutter test`), e `flutter analyze` sem erros novos.
7. Ao fim de cada fase, atualize o `RELATORIO_STATUS_PROJETO.md` e o `HISTORICO_DO_PROJETO.md`.

---

## Situação atual (levantada no código em 16/10)

| Item | Hoje |
|---|---|
| Cores | Classe `PaletaSahara` (7 cores) usada 214 vezes em 26 arquivos, **mais ~700 cores fixas** (`Colors.white` 74, `Colors.red` 68, `Colors.grey[...]` ~260, `Colors.green` 46, `Colors.blue` 21, `Colors.orange` 20...) e 34 `Color(0x...)` em 9 arquivos |
| Paleta própria escondida | `login_page.dart` tem uma classe local `_Sahara` |
| Status | O mapeamento status → cor está repetido em 5 telas (dashboard, financeiro, obra_list, obra_detalhes, orcamento_list) |
| Sombras | 27 `boxShadow` e 27 `elevation:`; o manual pede cards **sem sombra** |
| Fontes | 234 `fontSize:` fixos; `GoogleFonts` usado 16 vezes, fora de um `TextTheme` |
| Ícones | 248 usos de `Icons.*` (117 diferentes); manual pede Material Symbols Rounded |
| Tema | `ThemeData` só claro, em `main.dart`; sem modo escuro |
| Gráficos | `relatorios_page.dart` usa 8 cores Material padrão (azul, vermelho, laranja...) |
| PDF | `pdf_service.dart` usa as cores Sahara (texto secundário #9A8E85, que o manual trocou) |
| Ícone do app | Ícone padrão do Flutter |
| Configurações | `EmConstrucaoPage` |

---

## Kit de arquivos (anexo a este plano)

Copie a pasta `assets/` do kit para a raiz do projeto:

| Arquivo | Uso |
|---|---|
| `assets/icone/icone_app.png` (1024, fundo cheio) | Ícone base (Android antigo e iOS) |
| `assets/icone/icone_foreground.png` (1024, transparente) | Frente do ícone adaptativo do Android; fundo `#3A302A` |
| `assets/icone/icone_monocromatico.png` (1024, branco) | Ícone temático do Android 13+ |
| `assets/marca/icone.svg` | Logo com fundo: login, menu lateral |
| `assets/marca/simbolo.svg` | Pincel sem fundo: cabeçalho dos PDFs |
| `assets/ilustracoes/claro/*.svg` e `assets/ilustracoes/escuro/*.svg` | Telas vazias: `vazio_obras`, `vazio_orcamentos`, `vazio_busca`, `vazio_notificacoes` |

---

## Tokens (valores oficiais)

### Cores — `CoresApp` (claro / escuro)

| Token | Claro | Escuro | Uso |
|---|---|---|---|
| `brand` | `#C2652A` | `#C2652A` | Cor da marca, barra de progresso, gráficos. Não usar com texto branco pequeno |
| `primary` | `#A5521F` | `#E07B3F` | Botão primário, FAB, links, item ativo |
| `primaryPressed` | `#8F4619` | `#EC9561` | Botão primário pressionado |
| `onPrimary` | `#FFFFFF` | `#1E1915` | Texto sobre `primary` |
| `primarySoft` | `#F8E9DD` | `#3D2A1E` | Selecionado, chip ativo, círculo de ícone de módulo |
| `accent` | `#F2B27F` | `#F2B27F` | Pêssego: valor no card destaque, foco |
| `secondary` | `#8C3C3C` | `#B04A4A` | Vinho: contador de não lidas |
| `onSecondary` | `#FFFFFF` | `#FFFFFF` | Texto sobre `secondary` |
| `surface` | `#FAF5EE` | `#1E1915` | Fundo das telas (scaffold) |
| `surfaceCard` | `#FFFFFF` | `#2A231E` | Cards, formulários |
| `surfaceRaised` | `#FFFFFF` | `#3A302A` | Diálogos, menus, bottom sheets |
| `surfaceSunken` | `#EFE8DF` | `#3A302A` | Fundo de campo, trilho de progresso, divisórias leves |
| `border` | `#D8D0C8` | `#4A3D34` | Bordas |
| `ink` | `#3A302A` | `#F3ECE4` | Texto principal |
| `inkMuted` | `#6B5E55` | `#B8ABA0` | Texto secundário (substitui `#9A8E85`) |
| `decor` | `#9A8E85` | `#6B5E55` | Só decorativo, nunca texto |
| `disabledBg` | `#EFE8DF` | `#3A302A` | Botão desativado |
| `disabledInk` | `#9A8E85` | `#6B5E55` | Texto desativado |
| `inverseSurface` | `#3A302A` | `#4A3D34` | Card destaque (um por tela) |
| `inverseInk` | `#FAF5EE` | `#F3ECE4` | Texto sobre `inverseSurface` |
| `inverseInkMuted` | `#D8D0C8` | `#D8D0C8` | Legenda sobre `inverseSurface` |
| `success` / `successSoft` | `#2A7349` / `#E3F1E8` | `#5FBF86` / `#183324` | Aprovado, Concluída, receita |
| `error` / `errorSoft` / `onError` | `#B3261E` / `#F9E1DF` / `#FFFFFF` | `#F2877E` / `#3D1C1A` / `#1E1915` | Recusado, Atrasado, despesa, excluir |
| `warning` / `warningSoft` | `#8A6100` / `#FCF0D2` | `#E3B341` / `#3A2E10` | Pendente, Pausada, vencendo |
| `info` / `infoSoft` | `#2F6690` / `#E1ECF5` | `#7DB3DE` / `#172A3A` | Em andamento, avisos |

### Tipografia — `TextTheme` (via `google_fonts`)

| Estilo Flutter | Fonte · peso · tamanho/altura |
|---|---|
| `displaySmall` | EB Garamond 700 · 40/44 |
| `headlineMedium` | EB Garamond 700 · 28/34 |
| `titleLarge` | EB Garamond 600 · 22/28 |
| `displayMedium` (valores em R$) | Manrope 800 · 32/36 |
| `titleMedium` | Manrope 700 · 18/24 |
| `bodyLarge` | Manrope 500 · 16/24 |
| `bodyMedium` | Manrope 400 · 14/20 |
| `labelLarge` (botões) | Manrope 700 · 15/20 |
| `bodySmall` / `labelSmall` | Manrope 600 · 12/16, letterSpacing 0,96 (0,08em) |

Garamond nunca abaixo de 20 px. Nada abaixo de 12 px. Não travar `textScaler`.

### Medidas — `MedidasApp`

- Espaços: 4, 8, 12, 16, 20, 24, 32. Margem lateral das telas: 16.
- Raios: campo 8 · botão 12 · card, diálogo e FAB 16 · chip e círculo 999.
- Área de toque mínima: 48. Ícones: 20 (junto de texto), 24 (padrão), 32 (Resumo Geral e telas vazias).
- Única sombra: FAB, `0 4 12` com grafite 25% (claro) e preto 50% (escuro).

---

> Ajuste de 16/10: `success` claro passou de `#2E7D4F` para `#2A7349`, porque o verde antigo dava 4,3:1 sobre `successSoft` (mínimo 4,5:1). Manual e canvas já atualizados.

---

## Fase 0 — Preparação

- Copiar o kit de `assets/` e registrar as pastas no `pubspec.yaml`.
- Adicionar dependências: `flutter_svg` (logo e ilustrações), `material_symbols_icons` (ícones), `shared_preferences` (preferência de tema). Em `dev_dependencies`: `flutter_launcher_icons`.
- 🛑 **CONSULTAR:** confirmar as 4 dependências novas com o Jan antes de adicionar.

**Pronto quando:** `flutter pub get` e `flutter test` passam, sem mudança visual.

---

## Fase 1 — Fundação do tema

Criar em `lib/src/core/tema/`:

| Arquivo | Conteúdo |
|---|---|
| `cores_app.dart` | `class CoresApp extends ThemeExtension<CoresApp>` com todos os tokens acima, `static const claro` e `static const escuro`, `copyWith` e `lerp`. Extensão `extension CoresContext on BuildContext { CoresApp get cores => Theme.of(this).extension<CoresApp>()!; }` |
| `tipografia_app.dart` | `TextTheme textThemeApp(Color ink)` com a escala acima |
| `medidas_app.dart` | Classes `Espaco`, `Raio`, `TamanhoIcone` e `alturaToque = 48` |
| `status_visual.dart` | Mapa único status → `(cor, fundo, ícone, rótulo)` para os 7 status (ver Fase 2), lendo de `CoresApp` |
| `tema_app.dart` | `ThemeData temaClaro()` e `ThemeData temaEscuro()` |

O `tema_app.dart` monta:
- `ColorScheme`: `primary`, `onPrimary`, `primaryContainer` = `primarySoft`, `secondary`, `onSecondary`, `surface` = `surfaceCard`, `onSurface` = `ink`, `onSurfaceVariant` = `inkMuted`, `outline` = `border`, `error`, `onError`; `scaffoldBackgroundColor` = `surface`; `extensions: [CoresApp.claro]` (ou escuro).
- Temas de componentes, com os valores do manual:
  - **Botões:** `FilledButton` (primário, altura 48, raio 12, `labelLarge`), `OutlinedButton` (secundário: fundo `surfaceCard`, borda 1,5 `border`, texto `primary`), `TextButton` e `FloatingActionButton` (raio 16, sombra FAB).
  - **Superfícies:** `Card` (elevation 0, borda 1 `border`, raio 16, cor `surfaceCard`), `Dialog` (`surfaceRaised`, raio 16) e `BottomSheet`.
  - **Campos e chips:** `InputDecoration` (preenchido `surfaceSunken`, raio 8, foco `primary`) e `Chip`.
  - **Estrutura:** `AppBar` (fundo `surfaceCard`, texto `ink`, sem sombra), `Drawer` (fundo `surfaceCard`), `Divider` (`border`) e `SnackBar`.
  - **Mantidos:** levar para os dois temas o `DatePickerTheme` que já existe no `main.dart`.
- **Ponte temporária:** `PaletaSahara` passa a apontar para os valores claros novos (`primary` → `#A5521F`, `onSurfaceMuted` → `#6B5E55` etc.), marcada `@Deprecated`, para o app continuar compilando enquanto as telas migram. Ela será apagada na Fase 5.
- `main.dart`: `theme: temaClaro()`, `darkTheme: temaEscuro()`, **`themeMode: ThemeMode.light` por enquanto**. O escuro só é liberado na Fase 5, quando nenhuma tela tiver cor fixa.

**Pronto quando:** o app abre igual, só com botões, campos e cards padronizados pelo tema; testes e analyze passam.

---

## Fase 2 — Componentes compartilhados

Em `lib/src/apresentacao/widgets/`:

| Widget | O que faz | Substitui |
|---|---|---|
| `StatusChip(status)` | Pílula com ícone e texto, cores de `status_visual.dart` | Os 5 mapeamentos repetidos |
| `CardApp` | Card padrão (borda, raio 16, padding 16, sem sombra, toque com fundo `primarySoft`) | `Container` + `BoxDecoration` + `boxShadow` montados à mão |
| `CardDestaque` | Fundo `inverseSurface`, valor em `accent` | Card do valor principal do Resumo Geral |
| `IconeModulo(icone)` | Ícone `primary` num círculo `primarySoft` | Ícones do menu e do Resumo Geral |
| `TelaVazia(tipo, titulo, texto, acao?)` | Ilustração 200×160 (versão clara ou escura conforme `Theme.brightness`) + título + texto + botão opcional | Mensagens de lista vazia |
| `LogoApp(tamanho)` | `assets/marca/icone.svg` | `Icon(Icons.format_paint)` do login e do menu |

**Status (fixos):**

| Status | Ícone (Symbols) | Cor / fundo |
|---|---|---|
| Orçamento Pendente | `schedule` | `warning` / `warningSoft` |
| Orçamento Aprovado | `check_circle` | `success` / `successSoft` |
| Orçamento Recusado | `cancel` | `error` / `errorSoft` |
| Obra Não Iniciada | `radio_button_unchecked` | `inkMuted` / `surfaceSunken` |
| Obra Em Andamento | `autorenew` | `info` / `infoSoft` |
| Obra Pausada | `pause_circle` | `warning` / `warningSoft` |
| Obra Concluída | `check_circle` | `success` / `successSoft` |

Confira no banco a grafia exata dos status de obra (ex.: "Em Andamento" × "Em andamento") e normalize a comparação, sem alterar os dados.

**Pronto quando:** os widgets existem, têm teste de widget simples (StatusChip renderiza o rótulo e o ícone certos para cada status) e ainda não foram aplicados nas telas.

---

## Fase 3 — Marca (ícone, login, menu, PDF)

- **Ícone do app:** configurar o `flutter_launcher_icons` no `pubspec.yaml` com:
  - `image_path`: `assets/icone/icone_app.png`
  - `adaptive_icon_background`: `"#3A302A"`
  - `adaptive_icon_foreground`: `assets/icone/icone_foreground.png`
  - `adaptive_icon_monochrome`: `assets/icone/icone_monocromatico.png`

  Depois, rodar `dart run flutter_launcher_icons`.
- **Login:** `LogoApp` (72 px) + "Paint" (EB Garamond 600, `brand`) "Manager" (EB Garamond 700, `ink`) em `displaySmall`. Remover a classe local `_Sahara`.
- **Cabeçalho do menu lateral:** `LogoApp` (40 px) no lugar do ícone `format_paint`, com o nome ao lado.
- **PDF (`pdf_service.dart`):**
  - cores do manual: `corSecundaria` `#9A8E85` → `#6B5E55`, título `#A5521F`, bordas `#D8D0C8`;
  - `pw.SvgImage` com `assets/marca/simbolo.svg` no cabeçalho.

  Os testes `pdf_relatorios_test` e `pdf_lista_materiais_test` devem continuar passando.
- 🛑 **CONSULTAR:** cor da tela de abertura do Android (splash). Sugestão: fundo `#3A302A` com o ícone.

**Pronto quando:** o ícone novo aparece no celular, e o login, o menu e os PDFs mostram a marca nova.

---

## Fase 4 — Migração das telas (8 lotes)

A auditoria ignora `lib/src/core/tema/` e os geradores de PDF (arquivos que importam `package:pdf`), que têm cores próprias do documento.

Para **cada arquivo** do lote, faça o checklist:

- [ ] `PaletaSahara.*`, `Colors.*` (exceto `transparent`) e `Color(0x...)` → `context.cores.*` ou `Theme.of(context)`.
- [ ] `Colors.grey[...]`: `inkMuted` para texto, `border` para borda, `surfaceSunken` para fundo leve.
- [ ] `Colors.red`/`green`/`orange`/`blue` → `error`/`success`/`warning`/`info` (e versões `Soft` para fundos).
- [ ] `Colors.white` como fundo → `surfaceCard`; como texto sobre botão → `onPrimary`.
- [ ] `boxShadow` e `elevation` de cards → remover (usar `CardApp`). Manter só a sombra do FAB.
- [ ] `fontSize`/`fontWeight` fixos → estilos do `textTheme`.
- [ ] `Icons.*` → `Symbols.*` (rounded, contorno; preenchido só no item ativo do menu e em status).
- [ ] Status → `StatusChip`. Lista vazia → `TelaVazia`.
- [ ] Testar o arquivo no tema claro **e** no escuro (só no seu teste: troque temporariamente o `themeMode` e volte para `light` antes do commit).

| Lote | Arquivos | Linhas com cor fixa (aprox.) |
|---|---|---|
| **A · Estrutura** | `main.dart`, `auth_controller` (snackbar), `drawer_comum`, `guarda_rota`, `em_construcao_page`, `campo_busca_selecao`, `campo_data`, `painel_filtro_lista`, `chips_filtro_status`, `auth_check`, `notificacao_controller` | 70 |
| **B · Acesso** | `login_page`, `recuperar_senha_page`, `redefinir_senha_obrigatoria_page`, `usuario_list_page` | 85 |
| **C · Resumo Geral** | `dashboard_page` | 45 |
| **D · Clientes** | `cliente_list_page`, `cliente_form_page` | 65 |
| **E · Obras** | `obra_list_page`, `obra_form_page`, `obra_detalhes_page`, `chat_obra_card`, `pdf_lista_materiais_acao` | 175 |
| **F · Orçamentos** | `orcamento_list_page`, `orcamento_form_page` | 125 |
| **G · Financeiro** | `financeiro_page`, `transacao_form_page` | 75 |
| **H · Relatórios** | `relatorios_page` | 65 |

**Menu lateral (Lote A):** ícones Symbols `dashboard`, `manage_accounts`, `group`, `construction`, `request_quote`, `account_balance_wallet`, `bar_chart`, `settings`. O item ativo usa o ícone preenchido em `primary` sobre `primarySoft`. "Sair do sistema" usa `logout` em `error`.

🛑 **CONSULTAR (Lote A):** hoje o menu tem Usuários em 2º lugar. O manual o lista em 7º, antes de Configurações. Qual ordem o Jan quer?

**Obras (Lote E):** contador de mensagens não lidas do chat em `secondary` (vinho) com texto `onSecondary`; barra de progresso com trilho `surfaceSunken` e preenchimento `brand`.

**Mapa (Lote E):** os blocos do OpenStreetMap continuam claros no modo escuro. Aceitável; só aplicar borda e raio do card.

🛑 **CONSULTAR (Lote H):** paleta dos gráficos por categoria de despesa. Receita × despesa continua `success` × `error`. Para as categorias, proposta, na ordem:

| Categoria | Claro | Escuro |
|---|---|---|
| Mão de Obra | `#C2652A` (terracota) | `#E07B3F` |
| Materiais | `#2F6690` (azul) | `#7DB3DE` |
| Ferramentas | `#8C3C3C` (vinho) | `#D88A8A` |
| Transporte | `#8A6100` (âmbar) | `#E3B341` |
| Alimentação | `#6B5E55` (grafite claro) | `#B8ABA0` |
| Outros | `#D8D0C8` (areia) | `#4A3D34` |

Cada fatia ou barra leva rótulo com nome e valor, para não depender só da cor.

**Pronto quando:** cada lote estiver aprovado pelo Jan no celular. Ao fim do Lote H, a busca abaixo não pode retornar nada fora de `lib/src/core/tema/`:

```
grep -rnE "Colors\.|Color\(0x|PaletaSahara|fontSize:" lib | grep -v "Colors.transparent" | grep -v "lib/src/core/tema/"
```

---

## Fase 5 — Modo escuro e tela de Configurações

- `TemaController` (`ChangeNotifier`) com `ThemeMode` salvo em `shared_preferences`. O padrão é `ThemeMode.system`.
- `main.dart`: `themeMode: context.watch<TemaController>().modo`.
- **Tela Configurações**, no lugar de `EmConstrucaoPage`, com a seção **Aparência**: três opções (Automático, conforme o celular · Claro · Escuro) em `RadioListTile` ou `SegmentedButton`. Acessível às três funções.
- Apagar `PaletaSahara` e `paleta_sahara.dart`.
- Ilustrações escuras e PDFs: o PDF continua sempre claro, porque é documento para o cliente.

**Pronto quando:** o app inteiro funciona nos dois temas, segue o celular por padrão, a escolha em Configurações sobrevive ao reabrir o app e a busca do grep acima retorna vazio.

---

## Fase 6 — Testes e documentação

- **Testes (contam para V&V do TFC):**
  - `cores_app_test.dart`: calcula o contraste (fórmula WCAG) e garante ≥ 4,5:1 para `ink`/`inkMuted` sobre `surface`, `surfaceCard` e `surfaceRaised`, para `onPrimary` sobre `primary` e para cada cor semântica sobre o seu `Soft`, **nos dois temas**.
  - `status_visual_test.dart`: os 7 status têm cor, fundo, ícone e rótulo.
  - `tema_controller_test.dart`: salva e recupera o modo.
- **Documentação:**
  - atualizar `README.md` e `ARCHITECTURE.md` (pasta `core/tema`, `CoresApp`, componentes, dependências novas);
  - registrar a fase no `HISTORICO_DO_PROJETO.md` e no `RELATORIO_STATUS_PROJETO.md`.
- 📸 Lembrar o Jan de tirar prints das telas novas (claro e escuro) para o relatório do TFC II.

---

## Ordem e dependências

| # | Fase | Depende de | Consultar antes? |
|---|---|---|---|
| 0 | Preparação (kit + dependências) | — | Sim (dependências) |
| 1 | Fundação do tema | 0 | Não |
| 2 | Componentes compartilhados | 1 | Não |
| 3 | Marca: ícone, login, menu, PDF | 1, 2 | Sim (splash) |
| 4 | Migração das telas, lotes A → H | 2 | Sim (ordem do menu; paleta dos gráficos) |
| 5 | Modo escuro + Configurações | 4 completo | Não |
| 6 | Testes e documentação | 5 | Não |
