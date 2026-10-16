# Passo a passo — nova identidade visual do PaintManager

Guia de execução, fase por fase, para você (Jan) e o seu agente trabalharem juntos. O **PLANO_IDENTIDADE_VISUAL.md** é a especificação (o quê e por quê); este arquivo é a ordem de execução (como e quando).

**Legenda:** 👤 você · 🤖 agente · ✅ verificação · 🛑 o agente pergunta antes

---

## O que tem no kit

```
kit_identidade_visual/
├── PLANO_IDENTIDADE_VISUAL.md   especificação: tokens, regras, lotes
├── PASSO_A_PASSO.md             este arquivo
├── assets/                      ícone do app (PNG), logo e ilustrações (SVG)
├── modelos/                     código pronto: tema, componentes e testes
│   ├── lib/src/core/tema/       cores_app, medidas_app, tipografia_app,
│   │                            status_visual, tema_app, tema_controller
│   ├── lib/src/apresentacao/widgets/  status_chip, card_app, card_destaque,
│   │                            icone_modulo, tela_vazia, logo_app
│   └── test/                    contraste (WCAG), status, chip, controller
└── ferramentas/                 scripts em Dart (rodam no Windows)
    ├── preparar.dart            Fase 0: branch, assets, pubspec, dependências
    ├── aplicar.dart <fase>      copia os modelos da fase 1, 2, 3 ou 5
    ├── verificar.dart           analyze + test + auditoria de valores fixos
    └── comum.dart               funções usadas pelos três
```

**Os três comandos que se repetem** (sempre na raiz do `paintmanager_app`):

```
dart run kit_identidade_visual/ferramentas/preparar.dart
dart run kit_identidade_visual/ferramentas/aplicar.dart 1
dart run kit_identidade_visual/ferramentas/verificar.dart --lote E
```

O `verificar` roda `flutter analyze`, `flutter test` e uma **auditoria** que conta, arquivo por arquivo, as cores, tamanhos de fonte, ícones antigos, sombras e `GoogleFonts` que ainda estão fixos nas telas. Cada execução vira uma linha em `docs/identidade_visual/PROGRESSO.md`, que é o seu placar.

> Os modelos foram escritos para o Flutter 3.47 / Dart 3.11 do projeto, mas não puderam ser compilados fora do seu computador. Se o `flutter analyze` apontar algo neles, o agente corrige (veja "Se algo der errado").

---

## Antes de começar (uma vez)

1. 👤 Extraia o zip na **raiz do projeto**, para ficar `paintmanager_app/kit_identidade_visual/`.
2. 👤 Abra o terminal na raiz e confira que está tudo commitado: `git status` deve mostrar só a pasta do kit.
3. 👤 Cole no agente o **prompt inicial**:

```
Vamos implementar a nova identidade visual do PaintManager.
Leia, antes de qualquer coisa:
- kit_identidade_visual/PLANO_IDENTIDADE_VISUAL.md (especificação)
- kit_identidade_visual/PASSO_A_PASSO.md (ordem de execução)

Regras:
- Uma fase (ou um lote da Fase 4) por vez, na ordem do PASSO_A_PASSO.
- Antes de cada fase, me diga em poucas linhas o que vai mudar.
- Use os scripts de kit_identidade_visual/ferramentas/ e os modelos de
  kit_identidade_visual/modelos/; não reescreva do zero o que já está pronto.
- Pontos marcados com 🛑 você me pergunta antes de fazer.
- Só me chame para testar no celular quando o verificar.dart sair APROVADO.
- Não faça commit sem a minha aprovação; use as mensagens sugeridas.
- Nenhuma mudança de regra, permissão ou banco: é só troca visual.

Comece pela Fase 0.
```

---

## Fase 0 — Preparação

🤖 **Agente:**
1. 🛑 Confirma com você as 4 dependências novas: `flutter_svg` (logo e ilustrações), `material_symbols_icons` (ícones), `shared_preferences` (guardar o modo escuro) e `flutter_launcher_icons` (gerar o ícone do app; só no desenvolvimento).
2. Roda `dart run kit_identidade_visual/ferramentas/preparar.dart`. O script:
   - confere que não há alterações sem commit;
   - cria a branch **`feat/identidade-visual`** (a `main` fica intacta até o fim);
   - copia `assets/` e registra as pastas no `pubspec.yaml`;
   - tira a pasta do kit da análise;
   - adiciona as dependências;
   - grava a **linha de base** no `PROGRESSO.md`.

✅ **Esperado:** sem erros de análise, os 42 testes passando e cerca de **1.330 valores fixos em 28 arquivos** (o número exato fica no `PROGRESSO.md`).

👤 **Você:** `flutter run` no celular. O app deve abrir **igual a antes**.

**Commit:** `chore(tema): fase 0 - kit, assets e dependências da nova identidade visual`

---

## Fase 1 — Fundação do tema

🤖 **Agente:**
1. `dart run kit_identidade_visual/ferramentas/aplicar.dart 1`. O script:
   - copia `cores_app`, `medidas_app`, `tipografia_app`, `status_visual`, `tema_app` e 2 testes;
   - transforma `paleta_sahara.dart` numa **ponte temporária** com os valores novos.
2. Edita o `main.dart`:
   ```dart
   import 'src/core/tema/tema_app.dart';
   // ...
   theme: temaClaro(),
   darkTheme: temaEscuro(),
   themeMode: ThemeMode.light, // a Fase 5 troca pelo TemaController
   ```
   e apaga o `ThemeData(...)` antigo (o calendário já está no tema novo).
3. `dart run kit_identidade_visual/ferramentas/verificar.dart --etapa "Fase 1"` e corrige o que o analyze apontar.

✅ **Esperado:** sem erros; testes = 42 + os novos de contraste e status. O contraste checa 23 combinações de cor nos dois temas.

👤 **Você, no celular:**
- Botões e destaques num terracota um pouco **mais escuro** (`#A5521F`).
- Textos secundários mais legíveis.
- Campos com fundo bege-claro e cantos de 8.
- Calendário igual, em português.
- Nada quebrado.

**Commit:** `feat(tema): fase 1 - tema claro/escuro, tipografia e medidas do manual da marca`

---

## Fase 2 — Componentes compartilhados

🤖 **Agente:**
1. `dart run kit_identidade_visual/ferramentas/aplicar.dart 2`. Copia `StatusChip`, `CardApp`, `CardDestaque`, `IconeModulo`, `TelaVazia`, `LogoApp`/`AssinaturaApp` e o teste do chip.
2. Confere no banco a grafia dos status de obra. O `status_visual.dart` já aceita "Em Andamento", "Em andamento", "Não Iniciada" e "Rejeitado".
3. `verificar.dart --etapa "Fase 2"`.

👤 **Você:** nada muda na tela ainda; os componentes entram em uso na Fase 4.

**Commit:** `feat(tema): fase 2 - componentes StatusChip, CardApp, TelaVazia e logo`

---

## Fase 3 — Marca: ícone, login, menu, PDF

🤖 **Agente:**
1. 🛑 Pergunta a cor da tela de abertura do Android (sugestão: grafite `#3A302A`).
2. `dart run kit_identidade_visual/ferramentas/aplicar.dart 3`. Grava a configuração do `flutter_launcher_icons` no `pubspec.yaml` e gera os ícones.
3. **Login:** `AssinaturaApp(tamanhoLogo: 64)` no lugar do ícone `format_paint`; remove a classe local `_Sahara`.
4. **Menu lateral:** `LogoApp(tamanho: 40)` + nome no cabeçalho.
5. **PDF (`pdf_service.dart`):**
   - cor secundária `#9A8E85` → `#6B5E55`, título `#A5521F`;
   - `assets/marca/simbolo.svg` no cabeçalho com `pw.SvgImage`. Carregar o SVG fora do gerador e passar por parâmetro opcional, para os testes de PDF não dependerem de asset.
6. `verificar.dart --etapa "Fase 3"`.

👤 **Você:**
1. **Desinstale** o app do celular e instale de novo. Sem isso, o Android pode manter o ícone antigo em cache.
2. Confira o ícone na tela inicial: pincel sobre grafite. No Android 13+, teste também o ícone temático.
3. Confira o login, o menu e um PDF de relatório e outro da lista de materiais.

**Commit:** `feat(marca): fase 3 - ícone do app, logo no login, menu e PDFs`

---

## Fase 4 — Migração das telas (lotes A → H)

Para **cada lote**, o ciclo é o mesmo:

1. 👤 Cole o prompt do lote (abaixo, trocando a letra).
2. 🤖 O agente migra os arquivos seguindo o checklist da Fase 4 do PLANO e roda `verificar.dart --lote X` até sair **APROVADO**.
3. 👤 Você testa no celular o que está na tabela.
4. 👤 Aprovado, você autoriza o commit.

**Prompt do lote:**

```
Fase 4, Lote X. Migre os arquivos do lote X (lista no PLANO e no
ferramentas/comum.dart) seguindo o checklist da Fase 4 do PLANO:
cores → context.cores/Theme, fontes → textTheme, Icons → Symbols (rounded),
cards → CardApp sem sombra, status → StatusChip, lista vazia → TelaVazia.
Não mude comportamento. Ao terminar, rode
dart run kit_identidade_visual/ferramentas/verificar.dart --lote X
e só me chame quando sair APROVADO, com a lista do que devo testar.
```

| Lote | Telas | O que você confere no celular |
|---|---|---|
| **A · Estrutura** (+ `main.dart`, `auth_controller`) | Menu lateral, guarda de rota, campos de busca e data, filtros, avisos | Menu com ícones novos e item ativo destacado; "Acesso restrito"; busca de cliente/obra; mensagens de aviso (snackbar). 🛑 **Ordem do menu:** Usuários em 2º (como hoje) ou em 7º (como no manual)? |
| **B · Acesso** | Login, recuperar senha, primeiro acesso, Usuários | Login completo, recuperação com código, troca de senha, lista e cadastro de usuário |
| **C · Resumo Geral** | Dashboard | Indicadores com ícone no círculo, card destaque grafite, sino de alertas |
| **D · Clientes** | Lista e formulário | Busca, cards, máscara de CPF/CNPJ, inativar |
| **E · Obras** | Lista, formulário, detalhes, chat, PDF da lista de materiais | Filtros, chips de status, barra de progresso, equipe, chat com contador vinho, obra concluída travada, mapa, PDF |
| **F · Orçamentos** | Lista e formulário | Status Pendente/Aprovado/Recusado, total, envio por WhatsApp/e-mail |
| **G · Financeiro** | Painel e formulário | Receita em verde, despesa em vermelho, vínculo com obra, excluir só como Administrador |
| **H · Relatórios** | Painel e PDFs | 🛑 **Cores dos gráficos por categoria** (proposta no PLANO). Gráficos, filtros, exportação |

**Ver o lote no modo escuro (opcional, recomendado a partir do Lote C):** peça ao agente para trocar temporariamente `themeMode: ThemeMode.light` por `ThemeMode.dark`, rode o app, olhe e **volte para `light` antes do commit**.

**Commit de cada lote:** `refactor(<módulo>): fase 4 lote X - <telas> na identidade visual nova`

---

## Fase 5 — Modo escuro e Configurações

🤖 **Agente:**
1. `dart run kit_identidade_visual/ferramentas/aplicar.dart 5`. Copia o `TemaController` e o teste.
2. `main.dart`:
   ```dart
   final prefs = await SharedPreferences.getInstance(); // antes do runApp
   // no MultiProvider:
   ChangeNotifierProvider(create: (_) => TemaController(prefs)),
   // no MaterialApp:
   themeMode: context.watch<TemaController>().modo,
   ```
3. **Tela Configurações**, no lugar da `EmConstrucaoPage`, para as 3 funções:
   - seção **Aparência** com Automático (conforme o celular), Claro e Escuro;
   - componente `SegmentedButton` ou `RadioListTile`.
4. Apaga `lib/src/core/tema/paleta_sahara.dart`.
5. `dart run kit_identidade_visual/ferramentas/verificar.dart --final`. Precisa sair **APROVADO**, com zero valores fixos no app inteiro.

👤 **Você, no celular:**
1. Em Configurações, escolha **Escuro**, feche e reabra o app: deve continuar escuro.
2. Escolha **Automático** e troque o tema do próprio celular: o app acompanha.
3. Percorra todas as telas no escuro. Os PDFs continuam claros, porque são documentos para o cliente. O mapa continua claro, o que é aceitável.

**Commit:** `feat(tema): fase 5 - modo escuro automático e tela de Configurações`

---

## Fase 6 — Testes, documentação e entrega

🤖 **Agente:**
1. Confere que os testes novos estão rodando: contraste (os dois temas), status, chip e controller.
2. Atualiza `README.md` e `ARCHITECTURE.md`:
   - a pasta `core/tema`, a `CoresApp` (`context.cores`), os componentes e as dependências novas;
   - a regra: "nenhuma cor fixa fora de `core/tema`".
3. Atualiza o `HISTORICO_DO_PROJETO.md` e o `RELATORIO_STATUS_PROJETO.md`.
4. Move `PLANO_IDENTIDADE_VISUAL.md` e `PASSO_A_PASSO.md` para `docs/identidade_visual/`.
   - Copia `ferramentas/` para `tool/identidade_visual/` e ajusta o `raizKit` para não exigir mais a pasta do kit, para a auditoria continuar disponível.
   - Remove `kit_identidade_visual/` e a linha dela no `analysis_options.yaml`.
5. `verificar.dart --final` uma última vez.

👤 **Você:**
1. Tire **prints das telas principais nos dois temas** para o relatório do TFC II (capítulo de implementação). O `PROGRESSO.md` serve de evidência da evolução.
2. Aprovado tudo, junte na `main`:
   ```
   git checkout main
   git merge --no-ff feat/identidade-visual
   git push origin main
   ```

**Commit:** `docs(tema): fase 6 - documentação da identidade visual e testes de contraste`

---

## Se algo der errado

| Problema | O que fazer |
|---|---|
| `flutter analyze` diz que `AppBarTheme`, `InputDecorationTheme`, `CardThemeData` ou `DialogThemeData` não é do tipo esperado | O nome dessas classes mudou entre versões do Flutter. Troque pela versão que o erro pede (ex.: `AppBarTheme` ↔ `AppBarThemeData`); os parâmetros são os mesmos |
| `Symbols.xxx_rounded` não existe | Confira o nome em fonts.google.com/icons; o padrão do pacote é `Symbols.<nome>_rounded` |
| Testes de PDF quebram na Fase 3 | O gerador está lendo asset; passe o SVG por parâmetro opcional |
| `verificar --lote X` não aprova | Ele lista arquivo e categoria (cores, fontes, ícones, sombras). Corrija o que falta e rode de novo |
| Algo ficou feio e quer voltar o lote | Antes do commit: `git restore <arquivos>`. Depois do commit: `git revert <hash>` |
| O script não roda | Rode da raiz do projeto; confira `dart --version`. A pasta tem que se chamar `kit_identidade_visual` |
| Ícone do app não mudou | Desinstale o app e instale de novo |
| Fontes diferentes no teste e no celular | Normal: os testes não baixam Google Fonts; o celular baixa |

---

## Resumo da ordem

| # | Fase | Comando principal | Você testa | 🛑 |
|---|---|---|---|---|
| 0 | Preparação | `preparar.dart` | App igual | Dependências |
| 1 | Tema | `aplicar.dart 1` + `main.dart` | Cores de botões e textos | — |
| 2 | Componentes | `aplicar.dart 2` | Nada visível | — |
| 3 | Marca | `aplicar.dart 3` + login/menu/PDF | Ícone, login, PDFs | Splash |
| 4 | Telas A→H | `verificar.dart --lote X` | Tabela da Fase 4 | Ordem do menu (A), cores dos gráficos (H) |
| 5 | Modo escuro | `aplicar.dart 5` + `verificar --final` | Escuro, claro, automático | — |
| 6 | Entrega | `verificar.dart --final` | Prints + merge na main | — |
