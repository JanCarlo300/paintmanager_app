# 📘 PaintManager — Histórico Completo do Projeto

> **Aplicativo de Gestão de Serviços de Pintura** — TFC II (UniRV)
> **Autor:** Jan Carlo Almeida Leal
> **Período coberto:** 09/02/2026 (criação do repositório) até 28/09/2026
> **Base deste documento:** histórico do Git (37 commits), código-fonte atual, scripts SQL e documentação existente.

---

## 📋 Índice

1. [Resumo Executivo](#1-resumo-executivo)
2. [Números do Projeto](#2-números-do-projeto)
3. [Linha do Tempo Resumida](#3-linha-do-tempo-resumida)
4. [Fase 1 — Criação do Projeto (fev/2026)](#4-fase-1--criação-do-projeto-fev2026)
5. [Fase 2 — Primeira Versão com Firebase (fev–mar/2026)](#5-fase-2--primeira-versão-com-firebase-fevmar2026)
6. [Fase 3 — Migração para Supabase e Clean Architecture (abr/2026)](#6-fase-3--migração-para-supabase-e-clean-architecture-abr2026)
7. [Fase 4 — Reformulação dos Formulários e Reorganização (jun/2026)](#7-fase-4--reformulação-dos-formulários-e-reorganização-jun2026)
8. [Fase 5 — Segurança, Controle de Acesso e Novos Requisitos (set/2026)](#8-fase-5--segurança-controle-de-acesso-e-novos-requisitos-set2026)
8A. [Fase 6 — Ajustes de Outubro, Segurança no Banco e Nova Identidade Visual (out/2026)](#8a-fase-6--ajustes-de-outubro-segurança-no-banco-e-nova-identidade-visual-out2026)
9. [Estado Atual do Sistema](#9-estado-atual-do-sistema)
10. [Requisitos Funcionais — Situação](#10-requisitos-funcionais--situação)
11. [Banco de Dados (Supabase)](#11-banco-de-dados-supabase)
12. [Testes e Qualidade](#12-testes-e-qualidade)
13. [Decisões Técnicas Importantes](#13-decisões-técnicas-importantes)
14. [Pendências e Próximos Passos](#14-pendências-e-próximos-passos)
15. [Apêndice A — Lista Completa de Commits](#apêndice-a--lista-completa-de-commits)

---

## 1. Resumo Executivo

O **PaintManager** é um aplicativo multiplataforma em **Flutter/Dart** voltado a pintores autônomos e microempresas do setor de pintura. Ele reúne em um só lugar o cadastro de **clientes**, a elaboração de **orçamentos**, o acompanhamento de **obras**, o controle **financeiro**, **relatórios** gerenciais e a gestão de **usuários** com permissões por função.

O projeto passou por **cinco fases** principais:

| Fase | Período | Marco |
|---|---|---|
| 1 | fev/2026 | Criação do repositório e estrutura Flutter inicial |
| 2 | fev–mar/2026 | Primeira versão funcional sobre **Firebase** (login, clientes, financeiro, relatórios, obras, orçamentos) |
| 3 | abr/2026 | **Migração completa para Supabase** (PostgreSQL + Auth) e adoção de **Clean Architecture** por módulos |
| 4 | jun/2026 | Reformulação dos formulários de Obras/Orçamentos e reorganização final da arquitetura |
| 5 | set/2026 | **RF002** (recuperação de senha), Edge Function de cadastro, **controle de acesso por função**, **RF010** (equipe da obra), **RF013** (alertas), identidade visual Sahara e build Android |

Hoje o app está **funcional de ponta a ponta** sobre Supabase, sem nenhuma dependência de Firebase, com APK Android gerado com sucesso pela primeira vez em 25/09/2026.

---

## 2. Números do Projeto

| Métrica | Valor |
|---|---|
| Commits no repositório | **37** |
| Dias com commits | 17 |
| Primeiro commit | 09/02/2026 |
| Último commit | 25/09/2026 |
| Arquivos Dart em `lib/` | **59** |
| Linhas de código Dart em `lib/` | ≈ **10.860** |
| Módulos de funcionalidade | 6 (auth, clientes, obras, orçamentos, financeiro, relatórios) + dashboard |
| Scripts SQL em `db/` | 9 (≈ 610 linhas) |
| Edge Functions (Supabase) | 1 (`criar-usuario`, TypeScript/Deno) |
| Tabelas no banco | 6 (`usuario`, `cliente`, `obra`, `orcamento`, `transacao`, `equipe_obra`) |
| Testes unitários | 4 casos (modelos de Usuário e Cliente) |

**Maiores telas (linhas):** `orcamento_form_page.dart` (1.160), `dashboard_page.dart` (781), `orcamento_list_page.dart` (740), `usuario_list_page.dart` (646), `obra_detalhes_page.dart` (607), `relatorios_page.dart` (604).

---

## 3. Linha do Tempo Resumida

```
2026
 fev ──┬─ 09  Initial commit (repositório criado no GitHub)
       ├─ 11  Estrutura inicial do projeto Flutter
       └─ 18  Login funcional com Firebase (RF001) + CRUD de Clientes
 mar ──┬─ 06  Cadastro de usuários pelo administrador
       ├─ 08  Usuário redefine a própria senha após cadastro
       ├─ 09  Menu lateral único (DrawerComum) + telas de Clientes refeitas
       ├─ 12  Financeiro, Relatórios (fl_chart), Obras, Orçamentos, responsividade mobile
       └─ 23  Redesign de Usuários, Orçamentos e Relatórios (layout em cards)
 abr ──┬─ 15  ★ MIGRAÇÃO PARA SUPABASE + CLEAN ARCHITECTURE (9 commits no dia)
       ├─ 16  Remoção completa do Firebase no código Dart
       ├─ 17  Estabilização dos dropdowns dos formulários
       └─ 22  Parsing seguro no repositório de Clientes
 jun ──┬─ 05  Formulários de Obras/Orçamentos reformulados (autocomplete, status)
       └─ 05  Reorganização final: cada módulo com suas próprias páginas
 set ──┬─ 21  Checkpoint (docs, novo visual do login)
       ├─ 22  RF002 Fase A — função SQL buscar_email_por_login
       ├─ 24  ★ RF002 — recuperação de senha por código + primeiro acesso reforçado
       └─ 25  Edge Function criar-usuario, correções do code review,
              remoção do Firebase no Android, paleta Sahara no app inteiro,
              ★ controle de acesso por função, ★ RF010, ★ RF013, build APK
```

---

## 4. Fase 1 — Criação do Projeto (fev/2026)

### `b987e26` — 09/02/2026 — *Initial commit*
Criação do repositório no GitHub (apenas o `README.md`).

### `85e2f98` — 11/02/2026 — *estrutura inicial do projeto Flutter*
- Projeto gerado com `flutter create` (132 arquivos, ~4.950 linhas), incluindo as pastas de plataforma **Android, iOS, Web, Windows, macOS e Linux** e todos os ícones padrão.
- Criados os primeiros arquivos (ainda vazios) do módulo de autenticação: `auth_controller.dart`, `login_page.dart`, `register_page.dart`.

### `163efe5` — 11/02/2026 — *merge: resolver conflito do README*
Merge entre o README criado no GitHub e o gerado localmente.

---

## 5. Fase 2 — Primeira Versão com Firebase (fev–mar/2026)

Nesta fase o backend era o **Firebase** (Authentication + Cloud Firestore), e o código seguia uma organização em camadas **globais** (`lib/src/dominio`, `lib/src/dados`, `lib/src/apresentacao`), ainda não separada por módulo.

### `c8a939e` — 18/02/2026 — *base do sistema vinculada ao Firebase e login funcional (RF001)*
- Configuração do Firebase (`firebase.json`, `lib/firebase_options.dart` gerado pelo `flutterfire configure`).
- Primeira arquitetura em camadas: entidade `Usuario`, `UsuarioModelo`, interface `RepositorioAutenticacao` e sua implementação, `AuthController` e `LoginPage`.
- **RF001 — Login** funcionando.

### `8e2c37f` — 18/02/2026 — *CRUD completo de Clientes*
Cadastro e listagem de clientes com atualização **em tempo real** (streams do Firestore).

### `1367e6a` — 06/03/2026 — *login de usuário com cadastro*
Ajustes na integração com Firebase e fluxo de cadastro de usuários (≈1.150 linhas adicionadas).

### `5bf8e36` — 08/03/2026 — *usuário redefine a própria senha*
Após o administrador cadastrar um usuário, este consegue redefinir a própria senha e fazer login.

### `4cef982` — 09/03/2026 — *padronizar navegação com sidebar única*
- Criado o **`DrawerComum`** unificado com 8 itens: Dashboard, Usuários, Clientes, Obras, Orçamentos, Financeiro, Relatórios e Configurações.
- Reconstruídas as telas de **listagem** (cards de resumo, busca, tabela) e **formulário** de Clientes.
- Criada a `EmConstrucaoPage` para módulos futuros.
- Criada a `RedefinirSenhaObrigatoriaPage` (primeiro acesso).
- `AppBar` padronizada em todas as telas; navegação com `pushReplacementNamed` para não empilhar rotas.
- `AuthCheck` passa a redirecionar ao Dashboard após login.

### `9a227da` — 12/03/2026 — *Financeiro, Relatórios, Obras, Orçamentos e responsividade mobile*
O maior commit do projeto (41 arquivos, ~4.800 linhas):
- **Módulo Financeiro** completo: entidade `Transacao`, CRUD, dashboard com receitas/despesas.
- **Módulo Relatórios** (Dashboard Analítico) com gráficos **fl_chart** (barras, pizza) e KPIs.
- **Módulo Obras**: listagem, formulário e tela de detalhes, com entidades `Obra` e `EtapaServico`.
- **Módulo Orçamentos**: listagem e formulário (785 linhas), com entidades `Orcamento` e `ItemServico`.
- Responsividade para celular em todas as telas (cabeçalhos verticais, busca em largura total, padding de 16 px, rodapé do orçamento em coluna, correção de overflow no Drawer).

### `b58e5ac` — 23/03/2026 — *Redesign de Usuários, Orçamentos e Relatórios*
- Listagem de usuários e de orçamentos convertidas para **layout em cards** (orçamentos com filtros).
- Relatórios renomeado para **"Análise Financeira"**, com ajustes de UI/UX.
- Ajustes de fontes e espaçamentos para dispositivos móveis.

---

## 6. Fase 3 — Migração para Supabase e Clean Architecture (abr/2026)

Motivação: substituir o Firestore (NoSQL) por um **banco relacional PostgreSQL** com chaves estrangeiras, políticas de segurança por linha (**RLS**) e SQL versionável, e organizar o código em **módulos independentes**.

Em **15/04/2026** foram feitos 9 commits sequenciais:

| Commit | O que foi feito |
|---|---|
| `7d3a8ec` | Dependências `supabase_flutter`, `flutter_dotenv` e `mocktail`; `.gitignore` passa a ignorar `.env` |
| `5af7285` | `SupabaseConfig` — configuração central lida do `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`) |
| `99d5f07` | **Auth migrado**: módulo `modules/auth/` em Clean Architecture; login CPF → e-mail → Supabase Auth; CRUD em `public.usuario`; `AuthController`, `UsuarioController`; telas Login, AuthCheck, RecuperarSenha, RedefinirSenhaObrigatoria |
| `ecfabd6` | **Clientes migrado**: entidade com `operator==`/`hashCode`, `ClienteModelo` (`deMapa`/`paraMapa` em snake_case), repositório Supabase |
| `4d86334` | **Obras migrado**: etapas e materiais em JSONB, chave estrangeira para cliente |
| `e524491` | **Orçamentos migrado**: itens de serviço em JSONB, chave estrangeira para obra |
| `45a634f` | `main.dart` com `MultiProvider` atualizado, novo `DashboardController` com consultas Supabase |
| `144fb08` | **Scripts SQL** de criação das tabelas com RLS, gatilho `updated_at`, índices e seed do administrador |
| `303f7eb` | **Testes unitários** dos modelos de Usuário e Cliente + relatório de auditoria de QA (`test/docs/qa_audit_report.md`) |

### `d234111` — 16/04/2026 — *remoção completa do Firebase*
- Excluídos `firebase_options.dart`, `firebase.json` e as pastas legadas das camadas globais (51 arquivos, −1.592 linhas).
- Refatoração final da UI de Relatórios.

### `ad7e7a0` — 17/04/2026 — *estabilizar dropdowns dos formulários*
Os dropdowns de Obra e Orçamento passaram a comparar **chaves primárias (`int?`)** em vez de instâncias de objeto (que quebravam após recarregar a lista); `value` → `initialValue`; estado inicial protegido com `Future.microtask`.

### `5852d33` — 22/04/2026 — *parsing seguro no repositório de Clientes*
Conversão tolerante a campos nulos/formatos inesperados vindos do banco, com logs de exceção.

---

## 7. Fase 4 — Reformulação dos Formulários e Reorganização (jun/2026)

### `cb3de6f` — 05/06/2026 — *reformulação completa dos formulários*
- **Obra:** campo de cliente com **autocomplete** por nome, validação via `FormField`, modo somente leitura na edição.
- **Orçamento:** o cliente passou a vir da **obra vinculada** (`Autocomplete<Obra>`) — todo orçamento precisa ter obra; o cliente é preenchido automaticamente.
- **Seletor visual de status** do orçamento (Pendente / Aprovado / Recusado / Concluído) com botões coloridos.
- Normalização de dados antigos: `Rejeitado` → `Recusado`.

### `76f20e6` — 05/06/2026 — *versão sem erros*
Pequenos ajustes para o app compilar sem erros.

### `5a6ee3b` — 05/06/2026 — *reorganização completa da arquitetura*
- 11 páginas movidas de `lib/src/apresentacao/paginas/` para dentro dos respectivos módulos.
- Scripts SQL movidos para `db/`.
- Removidos arquivos lixo (`analyze*.txt`, `run_error_log.txt`) e comentários legados sobre Firebase.
- Estrutura final de cada módulo:

```
modules/<modulo>/
├── apresentacao/controllers/
├── apresentacao/paginas/
├── dados/modelos/
├── dados/repositorios/
├── dominio/entidades/
└── dominio/repositorios/
```

---

## 8. Fase 5 — Segurança, Controle de Acesso e Novos Requisitos (set/2026)

### `5763d16` — 21/09/2026 — *checkpoint antes do RF002*
Ponto de retorno seguro: `README.md` e `ARCHITECTURE.md` completos, **novo visual da tela de login** (paleta Sahara), ajustes de Gradle. Pendências registradas na mensagem: resíduos de Firebase no Android, `main.dart` duplicado e divergência de versão do SDK.

### `475746d` — 22/09/2026 — *RF002 Fase A: função `buscar_email_por_login`*
Arquivo `db/rf002_fase_a_buscar_email_login.sql`: função PostgreSQL **`SECURITY DEFINER`** que recebe CPF **ou** e-mail e devolve apenas o e-mail de um usuário **ativo** — sem expor a tabela `usuario` inteira. Testada no Supabase (CPF válido, e-mail válido, CPF inexistente → `NULL`).

### `7c344ef` — 24/09/2026 — *RF002: recuperação de senha e primeiro acesso reforçado*
**Recuperação de senha em 3 passos:**
1. Usuário informa CPF ou e-mail → o app chama `buscar_email_por_login`.
2. Supabase envia um **código de verificação** por e-mail → validado com `verifyOTP`.
3. Usuário define a nova senha.

Por segurança, o app **nunca revela se o CPF/e-mail existe** (mensagem genérica no passo 1).

**Primeiro acesso endurecido:**
- Troca de senha obrigatória para **todos**, inclusive o administrador (antes havia isenção).
- Campo de **confirmação** de senha.
- O `AuthCheck` verifica `primeiro_acesso` também quando já há sessão salva — fecha a brecha de fechar e reabrir o app para pular a troca.
- O evento `passwordRecovery` é ignorado no `AuthCheck` para não interromper o passo 3.

**Nova classe `ValidadorSenha`** (regra única): mínimo 8 caracteres, ao menos uma letra e um número, diferente do CPF, confirmação igual.

Testado manualmente no celular: login normal, reabertura com sessão, primeiro acesso, recuperação com CPF/e-mail existente e inexistente, validações.

### `673367b` — 25/09/2026 — *Edge Function `criar-usuario`*
**Bug corrigido:** ao cadastrar um funcionário, o `signUp()` era chamado no cliente do administrador logado, e a sessão **trocava para o funcionário recém-criado**.

**Solução:** Edge Function `supabase/functions/criar-usuario/index.ts` (Deno/TypeScript), executada no servidor com a `service_role key`:
- Confere se quem chama está autenticado **e é Administrador**.
- Cria a conta já confirmada (`email_confirm: true`), com senha inicial = CPF.
- Insere o registro em `usuario`; se a inserção falhar, **desfaz** a criação no Auth (sem contas órfãs).
- A sessão do administrador não é tocada.

### `8fd3537` — 25/09/2026 — *correções rápidas do code review*
- `pubspec.yaml`: SDK declarado como `^3.11.0`, alinhado ao `pubspec.lock`.
- Login: links "Esqueci minha senha" / "Primeiro Acesso" voltaram a ser `TextButton` (área de toque e acessibilidade).
- Parâmetro `formatters` tipado como `List<TextInputFormatter>`.
- Texto do diálogo de primeiro acesso atualizado para o fluxo do RF002.
- Removido `lib/src/apresentacao/main.dart` (cópia duplicada do `main.dart`).

### `30e6ea8` — 25/09/2026 — *remoção do resíduo do Firebase no Android*
Removidos o plugin Google Services (`settings.gradle.kts`, `app/build.gradle.kts`) e o `google-services.json`, que ainda estava versionado com credenciais reais do projeto Firebase antigo.

### `8678ebf` — 25/09/2026 — *paleta Sahara no app inteiro*
- Nova classe **`PaletaSahara`** (`lib/src/core/tema/paleta_sahara.dart`):

| Token | Cor | Uso |
|---|---|---|
| `background` | `#FAF5EE` | Fundo das telas (bege) |
| `primary` | `#C2652A` | Cor principal (terracota) |
| `tertiary` | `#8C3C3C` | Destaque (vinho) |
| `border` | `#D8D0C8` | Bordas |
| `cardSurface` | `#FFFFFF` | Cartões |
| `onSurface` | `#3A302A` | Texto principal |
| `onSurfaceMuted` | `#9A8E85` | Texto secundário |

- `ThemeData` global montado a partir da paleta; 20 telas convertidas de cores fixas (preto/branco/cinza) para a paleta.
- Mantidas as cores semânticas de status (verde/vermelho/laranja/azul), a cor do WhatsApp e a paleta dos gráficos.

### `27e2424` — 25/09/2026 — *remoção do `menu_lateral.dart`*
Widget órfão, nunca referenciado (o app todo usa `DrawerComum`).

### `64d048b` — 25/09/2026 — *controle de acesso por função*
Antes, a função do usuário era só um rótulo visual. Agora:

- `AuthController` mantém o **usuário logado em cache** (`usuarioLogado`), acessível de qualquer tela.
- **Rota inicial por função:** Funcionário → `/obras`; Administrador e Gerente → `/home`.
- Novo widget **`GuardaRota`**: bloqueia a tela para quem não tem permissão e mostra "acesso restrito" (protege até navegação direta por rota nomeada).
- `DrawerComum` filtra os itens do menu pela função.

**Matriz de permissões aplicada:**

| Recurso | Administrador | Gerente | Funcionário |
|---|:-:|:-:|:-:|
| Dashboard | ✅ | ✅ | ❌ |
| Usuários | ✅ | ❌ | ❌ |
| Clientes | ✅ | ✅ | ❌ |
| Orçamentos | ✅ | ✅ | ❌ |
| Financeiro (ver/lançar/editar) | ✅ | ✅ | ❌ |
| Financeiro (excluir) | ✅ | ❌ | ❌ |
| Relatórios | ✅ | ✅ | ❌ |
| Obras — visualizar | ✅ | ✅ | ✅ |
| Obras — cadastrar / mudar status | ✅ | ✅ | ❌ |
| Obras — etapas, materiais, anotações | ✅ | ✅ | ✅ |

### `7d3a591` — 25/09/2026 — *RF010: alocar equipe à obra*
- Nova tabela **`equipe_obra`** (relação muitos-para-muitos entre `obra` e `usuario`, com `UNIQUE (obra_id, usuario_id)` e `ON DELETE CASCADE`) — script `db/supabase_migrate_equipe_obra.sql`.
- `RepositorioObra`: `listarFuncionariosAlocados`, `alocarFuncionario`, `desalocarFuncionario`.
- `ObraController`: `equipeObraAtual`, `carregarEquipe`, `alocar`, `desalocar`.
- Tela de detalhes da obra ganhou a seção **"Equipe Alocada"** (chips). Administrador/Gerente adicionam (busca entre funcionários ativos ainda não alocados) e removem; Funcionário apenas visualiza.

### `d7afa98` — 25/09/2026 — *RF013 simplificado: alertas no Dashboard*
- Novo **`NotificacaoController`**, que calcula alertas a partir dos dados existentes (sem push notification nem tarefa em segundo plano):
  - Orçamentos **pendentes vencidos** ou **vencendo em até 3 dias**;
  - Obras **não concluídas com prazo de término estourado**.
- O sino do cabeçalho do Dashboard (antes sem ação) exibe um **badge** com a quantidade e abre a lista; tocar em um item leva à tela correspondente.

### `34581b5` — 25/09/2026 — *AGP e Kotlin atualizados*
O Flutter 3.47.3 exige Android Gradle Plugin ≥ 8.11.1 e Kotlin ≥ 2.2.20 (o projeto declarava 8.9.1 e 2.1.0). Após a atualização, o **primeiro APK completo** do projeto foi gerado.

---

## 8A. Fase 6 — Ajustes de Outubro, Segurança no Banco e Nova Identidade Visual (out/2026)

> Adendo de 18/10/2026. As seções 9 a 14 abaixo descrevem o sistema em 28/09; o estado atual completo está em `RELATORIO_STATUS_PROJETO.md`.

### Backlog e plano de ajustes (02 a 15/10)
Itens do backlog de 02/10 e Etapas 1 a 8.1 do plano de outubro, todos testados pelo Jan no Samsung A55: Funcionário só acessa obras alocadas, inclusive no banco (`961d18e`, `1c7b326`); localização da obra por OpenStreetMap (`0699a76`); chat da obra em tempo real (`b8216e3`); validação de CPF pelo Módulo 11 (`1d5b663`); status do orçamento com 3 opções e obra só inicia com orçamento aprovado (`d075ded`); busca com filtro (`c862dfb`); calendário em português (`51d9fb3`); filtros e ordenação (`b84c1b9`); obra concluída travada (`b617267`); lista de materiais e PDF (`b010139`, `c121e37`); aviso de mensagens do chat (`9ec919c`); receita/despesa ligada à obra, RF011 (`4c7ee01`); relatórios em PDF, RF012 (`546446e`); limpeza das tabelas antigas do TFC I (`4417d40`).

### Segurança (16/10)
- `19c5f31` — o login deixa de ler a tabela `usuario` sem sessão (RF002 fase B); dados reais do administrador retirados dos scripts do repositório público.
- `5619247` — permissões por função aplicadas no banco por RLS em todas as tabelas; fecha a brecha em que um usuário podia mudar a própria função para Administrador.
- `42e6ffa` — tela Configurações com "Minha conta" e troca de senha (substitui o placeholder).

### Nova identidade visual (16 a 18/10)
Troca da paleta "Sahara" pelo manual da marca (*PaintManager Design System*, aprovado em 15/10), em branch própria (`feat/identidade-visual`), uma fase por vez, cada uma auditada (`analyze` + testes + busca de valores fixos) e testada no celular antes do commit. Plano, passo a passo e o placar da auditoria em `docs/identidade_visual/`.

| Commit | Fase | O que entrou |
|---|---|---|
| `2f2b5c0` | 0 | Kit, imagens da marca, `flutter_svg`, `material_symbols_icons`, `shared_preferences`, `flutter_launcher_icons`. Linha de base: 1.359 valores fixos em 29 arquivos |
| `03d9b99` | 1 | `lib/src/core/tema/`: `CoresApp` (claro/escuro), tipografia EB Garamond + Manrope, medidas, `status_visual`, `temaClaro()`/`temaEscuro()`; testes de contraste WCAG |
| `86b59f4` | 2 | Componentes `CardApp`, `CardDestaque`, `StatusChip`, `IconeModulo`, `TelaVazia`, `LogoApp` |
| `195c1f0` | 3 | Ícone do app, tela de abertura grafite, logo no login e no menu, PDFs com as cores e o símbolo da marca |
| `b6f0e48` … `c4829a4` | 4 | Lotes A–H: todas as telas migradas para o tema (menu com Usuários em 7º, cores de status unificadas, saldo/lucro no card destaque, paleta fixa por categoria nos gráficos). Fim: **zero valores fixos** fora de `core/tema` e dos PDFs |
| `2c5f78a` | 5 | Modo escuro: `TemaController` segue o celular por padrão; seção Aparência em Configurações; `PaletaSahara` apagada |
| (este) | 6 | README e ARCHITECTURE atualizados; plano e passo a passo em `docs/identidade_visual/`; auditoria em `tool/identidade_visual/`; kit removido. **114 testes** |

Decisões do Jan nesta fase: dependências novas aprovadas; tela de abertura grafite `#3A302A`; Usuários em 7º no menu (ordem do manual); paleta do manual para as categorias dos gráficos.

---

## 9. Estado Atual do Sistema

### 9.1 Stack

| Camada | Tecnologia |
|---|---|
| Framework | Flutter (Dart SDK `^3.11.0`), Material 3 |
| Backend | Supabase — PostgreSQL, Auth, RLS, Edge Functions |
| Estado | Provider / `ChangeNotifier` |
| Gráficos | `fl_chart` ^0.70.2 |
| Tipografia | `google_fonts` (EB Garamond + Manrope) |
| Outros | `intl` (pt_BR), `mask_text_input_formatter`, `url_launcher`, `flutter_dotenv` |
| Testes | `flutter_test`, `mocktail` |

### 9.2 Arquitetura

Clean Architecture por módulo, com injeção de dependência manual no `main.dart` via `MultiProvider`:

```
Página (Widget) ── context.watch / read ──► Controller (ChangeNotifier)
                                                 │
                                                 ▼
                                   Repositório (interface no domínio)
                                                 │
                                                 ▼
                                Repositório Impl (SupabaseConfig.client)
                                                 │
                                                 ▼
                                 Supabase (PostgreSQL + RLS) → Modelo.deMapa() → Entidade
```

### 9.3 Estrutura de `lib/`

```
lib/
├── main.dart                         # Inicialização, MultiProvider, tema, rotas + GuardaRota
└── src/
    ├── core/
    │   ├── config/supabase_config.dart
    │   └── tema/paleta_sahara.dart
    ├── apresentacao/                 # Compartilhado
    │   ├── controllers/  dashboard_controller, notificacao_controller
    │   ├── paginas/      dashboard_page, em_construcao_page
    │   └── widgets/      drawer_comum, guarda_rota
    └── modules/
        ├── auth/         Usuario, ValidadorSenha, login, recuperação, primeiro acesso, usuários
        ├── clientes/     Cliente — lista e formulário
        ├── obras/        Obra, EtapaServico — lista, formulário, detalhes (+ equipe)
        ├── orcamentos/   Orcamento, ItemServico — lista e formulário
        ├── financeiro/   Transacao — painel e formulário
        └── relatorios/   RelatorioGeral — análise financeira com gráficos
```

### 9.4 Módulos e funcionalidades

| Módulo | Funcionalidades principais |
|---|---|
| **Auth / Usuários** | Login por CPF + senha; recuperação por código (CPF ou e-mail); troca obrigatória no primeiro acesso; cadastro via Edge Function; listagem/edição/ativação de usuários; funções Administrador / Gerente / Funcionário |
| **Dashboard** | Indicadores gerais, cabeçalho com gradiente Sahara, sino de alertas (RF013) |
| **Clientes** | CRUD, busca, cards de resumo, CPF/CNPJ com máscara, inativação (soft delete) |
| **Orçamentos** | CRUD, vínculo obrigatório com obra, itens por m² com subtotal, materiais, mão de obra, desconto, total automático, status colorido, validade, forma de pagamento, filtros, **envio ao cliente pelo WhatsApp** |
| **Obras** | CRUD, autocomplete de cliente, etapas com progresso automático, materiais faltantes, anotações, status, **equipe alocada** (RF010) |
| **Financeiro** | Receitas e despesas, categorias, status (Efetivado/Pendente/Atrasado), forma de pagamento, vínculo com cliente/orçamento, exclusão só por Administrador |
| **Relatórios** | Receitas, despesas, lucro líquido, obras concluídas/em andamento, taxa de conversão de orçamentos, despesas por categoria, evolução mensal (barras e pizza) |
| **Configurações** | Placeholder (`EmConstrucaoPage`) |

### 9.5 Rotas

| Rota | Tela | Acesso |
|---|---|---|
| `/` (home) | `AuthCheck` | Público |
| `/login` | `LoginPage` | Público |
| `/recuperar-senha` | `RecuperarSenhaPage` | Público |
| `/redefinir-senha-obrigatoria` | `RedefinirSenhaObrigatoriaPage` | Logado |
| `/home` | `DashboardPage` | Admin, Gerente |
| `/usuarios` | `UsuarioListPage` | Admin |
| `/clientes`, `/cliente-formulario` | Clientes | Admin, Gerente |
| `/orcamentos`, `/orcamento-formulario` | Orçamentos | Admin, Gerente |
| `/financeiro`, `/transacao-formulario` | Financeiro | Admin, Gerente |
| `/relatorios` | `RelatoriosPage` | Admin, Gerente |
| `/obras`, `/obra-detalhes` | Obras | Todas as funções |
| `/obra-formulario` | `ObraFormPage` | Admin, Gerente |
| `/configuracoes` | `EmConstrucaoPage` | Logado |

### 9.6 Fluxo de autenticação

```
App inicia → AuthCheck
  ├─ Sem sessão ─────────────────────────────► LoginPage
  └─ Com sessão
       ├─ primeiro_acesso = true ────────────► RedefinirSenhaObrigatoriaPage
       └─ primeiro_acesso = false
            ├─ Funcionário ─────────────────► /obras
            └─ Administrador / Gerente ─────► /home

Login: CPF → e-mail (tabela usuario) → signInWithPassword → dados do usuário → verifica ativo
Recuperação: CPF/e-mail → buscar_email_por_login (RPC) → código OTP por e-mail → nova senha
Cadastro: Administrador → Edge Function criar-usuario (senha inicial = CPF)
```

---

## 10. Requisitos Funcionais — Situação

| RF | Descrição | Situação | Commit(s) |
|---|---|---|---|
| RF001 | Login | ✅ Concluído (Firebase → Supabase) | `c8a939e`, `99d5f07` |
| RF002 | Recuperar senha / primeiro acesso | ✅ Concluído | `475746d`, `7c344ef` |
| — | Gestão de usuários | ✅ Concluído (cadastro via Edge Function) | `1367e6a`, `673367b` |
| — | Controle de acesso por função | ✅ Concluído (na interface) | `64d048b` |
| — | Clientes | ✅ Concluído | `8e2c37f`, `ecfabd6` |
| — | Orçamentos | ✅ Concluído | `9a227da`, `e524491`, `cb3de6f` |
| — | Obras | ✅ Concluído | `9a227da`, `4d86334`, `cb3de6f` |
| RF010 | Alocar equipe à obra | ✅ Concluído | `7d3a591` |
| — | Financeiro | ✅ Concluído | `9a227da` |
| — | Relatórios | ✅ Concluído | `9a227da`, `b58e5ac`, `d234111` |
| RF013 | Notificações/alertas | 🟡 Versão simplificada (alertas calculados, sem push) | `d7afa98` |
| — | Configurações | ⏳ Não iniciado (placeholder) | — |

> Os números de RF acima são os citados nos commits; os demais requisitos devem ser cruzados com a numeração oficial do DERS.

---

## 11. Banco de Dados (Supabase)

### 11.1 Tabelas

| Tabela | Chave | Relacionamentos / destaques |
|---|---|---|
| `usuario` | `id_usuario` | `auth_id` → `auth.users`; `funcao`, `status`, `primeiro_acesso` |
| `cliente` | `id_cliente` | `ativo` (soft delete), gatilho `updated_at` |
| `obra` | `id_obra` | FK → `cliente`; `etapas_servico` e materiais em JSONB |
| `orcamento` | `id_orcamento` | FK → `obra`; `itens_servico` em JSONB |
| `transacao` | `id_transacao` | Vínculo opcional com cliente/orçamento |
| `equipe_obra` | `id_equipe_obra` | FK → `obra` e `usuario`, `UNIQUE(obra_id, usuario_id)`, `ON DELETE CASCADE` |

### 11.2 Scripts (`db/`) — ordem de execução

1. `supabase_migration.sql` — tabela `usuario` + RLS
2. `supabase_migrate_cliente.sql`
3. `supabase_migrate_obra.sql`
4. `supabase_migrate_orcamento.sql`
5. `supabase_migrate_financeiro.sql`
6. `supabase_migrate_equipe_obra.sql` *(RF010)*
7. `rls_policy_usuario.sql` — leitura anônima para o login por CPF
8. `rf002_fase_a_buscar_email_login.sql` — função `buscar_email_por_login` *(RF002)*
9. `supabase_seed_admin.sql` — administrador inicial

Além disso, a Edge Function `supabase/functions/criar-usuario` precisa estar implantada no painel do Supabase.

### 11.3 Segurança (RLS)
Todas as tabelas têm RLS habilitado. As políticas atuais liberam leitura/escrita para **qualquer usuário autenticado**; a restrição por função (Administrador/Gerente/Funcionário) é aplicada **no aplicativo**. Ver pendências na seção 14.

---

## 12. Testes e Qualidade

- **Testes unitários** (`test/modules/`): 4 casos cobrindo serialização `deMapa`/`paraMapa` de `UsuarioModelo` e `ClienteModelo` — 4/4 passando, ~92% de cobertura nos arquivos testados (auditoria de 13/04/2026, `test/docs/qa_audit_report.md`).
- **Testes manuais** documentados nos commits do RF002, da Edge Function e do controle de acesso, executados em dispositivo Android.
- **Code review** (set/2026) gerou uma lista de itens corrigidos: SDK, acessibilidade do login, tipagem, arquivos duplicados/órfãos, Firebase residual e tema global.
- **Lint:** `flutter_lints` ^5.0.0; imports e campos não usados removidos conforme `flutter analyze`.

---

## 13. Decisões Técnicas Importantes

| Decisão | Motivo |
|---|---|
| Firebase → **Supabase** | Banco relacional com FKs, RLS, SQL versionado, funções no banco e Edge Functions |
| **Clean Architecture por módulo** | Isolar domínio, dados e interface; facilitar testes e manutenção |
| **Provider / ChangeNotifier** | Simples, oficial e suficiente para o porte do app |
| Login por **CPF** | Mais natural para o público-alvo do que e-mail |
| Função SQL **`SECURITY DEFINER`** | Buscar e-mail por CPF sem expor a tabela `usuario` a usuários anônimos |
| **Edge Function** para cadastro | Criar usuários sem trocar a sessão do administrador e sem expor a `service_role key` no app |
| **JSONB** para itens e etapas | Estruturas aninhadas que sempre são lidas junto com o registro-pai |
| **Desnormalização** (`clienteNome` etc.) | Evitar JOINs nas listagens |
| **Soft delete** | Preservar histórico de clientes e usuários |
| **Alertas calculados** (RF013) | Entregar valor sem infraestrutura de push/segundo plano |
| **Paleta Sahara** centralizada | Identidade visual consistente e fácil de alterar |

---

## 14. Pendências e Próximos Passos

### Segurança
- **RF002 Fase B:** o login ainda busca o e-mail direto na tabela `usuario` com acesso anônimo (política `USING (true)` em `rls_policy_usuario.sql`). Trocar o login para a RPC `buscar_email_por_login` e **remover essa política**, que hoje permite a qualquer pessoa ler a tabela de usuários.
- **Permissões no banco:** as políticas RLS liberam tudo para qualquer autenticado; replicar a matriz de funções também no PostgreSQL (hoje só o app impede um Funcionário de, por exemplo, excluir uma transação via API).

### Funcionalidades
- Tela de **Configurações**.
- **RF013 completo** (push notification), se exigido.

### Qualidade
- Ampliar os testes: repositórios (com `mocktail`), controllers, `ValidadorSenha` e widgets.
- Atualizar `README.md` e `ARCHITECTURE.md`: ainda citam SDK `^3.9.2` e `menu_lateral.dart`, e não mencionam `equipe_obra`, `GuardaRota`, `NotificacaoController`, `PaletaSahara` nem a Edge Function.
- Criar um `.env.example` (o README o menciona, mas o arquivo não existe).

### Repositório
- Alteração não commitada em `db/supabase_migrate_equipe_obra.sql` (apenas um espaço em branco).
- `android/build/` aparece como não rastreado — incluir no `.gitignore`.
- Arquivo `hs_err_pid9464.log` (log de crash da JVM) na raiz pode ser apagado.

---

## Apêndice A — Lista Completa de Commits

| # | Hash | Data | Mensagem |
|---|---|---|---|
| 1 | `b987e26` | 09/02/2026 | Initial commit |
| 2 | `85e2f98` | 11/02/2026 | estrutura inicial do projeto Flutter |
| 3 | `163efe5` | 11/02/2026 | merge: resolver conflito do README |
| 4 | `c8a939e` | 18/02/2026 | feat: base do sistema vinculada ao firebase e login funcional (RF001) |
| 5 | `8e2c37f` | 18/02/2026 | feat: CRUD completo de Clientes (Cadastro e Listagem em tempo real) |
| 6 | `1367e6a` | 06/03/2026 | feat: ajustes do sistema vinculado ao firebase e login de usuário com cadastro |
| 7 | `5bf8e36` | 08/03/2026 | feat: usuário consegue redefinir sua própria senha após cadastro pelo adm |
| 8 | `4cef982` | 09/03/2026 | feat: padronizar navegação com sidebar única e telas de CRUD de clientes |
| 9 | `9a227da` | 12/03/2026 | feat: Financeiro, Relatórios (Dashboard Analítico) e responsividade mobile |
| 10 | `b58e5ac` | 23/03/2026 | feat/ui: Redesign das telas de usuários, orçamentos e relatórios |
| 11 | `7d3a8ec` | 15/04/2026 | chore: atualizar gitignore e dependências supabase_flutter, mocktail e dotenv |
| 12 | `5af7285` | 15/04/2026 | feat(core): configuração centralizada do supabase (SupabaseConfig via dotenv) |
| 13 | `99d5f07` | 15/04/2026 | feat(auth): migração completa para supabase auth e public.usuario |
| 14 | `ecfabd6` | 15/04/2026 | feat(clientes): refatoração para clean architecture e supabase |
| 15 | `4d86334` | 15/04/2026 | feat(obras): refatoração para clean architecture e supabase |
| 16 | `e524491` | 15/04/2026 | feat(orcamentos): refatoração para clean architecture e supabase |
| 17 | `45a634f` | 15/04/2026 | feat(ui): atualizar main.dart, dashboard, drawer e páginas compartilhadas |
| 18 | `144fb08` | 15/04/2026 | feat(db): scripts sql de migração supabase com rls |
| 19 | `303f7eb` | 15/04/2026 | test(auth,clientes): testes unitários dos modelos e relatório qa |
| 20 | `d234111` | 16/04/2026 | refactor(core): remoção completa do firebase e refatoração da ui de relatórios |
| 21 | `ad7e7a0` | 17/04/2026 | refactor(ui): estabilizar estado dos dropdowns nos formulários |
| 22 | `5852d33` | 22/04/2026 | fix(clientes): parsing seguro e logs de exceção no repositório |
| 23 | `cb3de6f` | 05/06/2026 | feat(obras,orcamentos): reformulação completa dos formulários com supabase |
| 24 | `76f20e6` | 05/06/2026 | versão sem erros, mas tem coisas pra atualizar |
| 25 | `5a6ee3b` | 05/06/2026 | refactor(arch): reorganização completa da arquitetura — remoção total do firebase |
| 26 | `5763d16` | 21/09/2026 | chore: checkpoint antes do RF002 (recuperar senha) |
| 27 | `475746d` | 22/09/2026 | feat(auth): script SQL Fase A do RF002 — função buscar_email_por_login |
| 28 | `7c344ef` | 24/09/2026 | feat(auth): RF002 — recuperação de senha por código e primeiro acesso reforçado |
| 29 | `673367b` | 25/09/2026 | fix(auth): corrige troca de sessão ao cadastrar usuário (Edge Function) |
| 30 | `8fd3537` | 25/09/2026 | fix: correções rápidas do code review (SDK, login, arquivo duplicado) |
| 31 | `30e6ea8` | 25/09/2026 | fix(android): remove resíduo do Firebase do build Android |
| 32 | `8678ebf` | 25/09/2026 | fix(tema): aplica a paleta Sahara no app inteiro |
| 33 | `27e2424` | 25/09/2026 | chore: remove menu_lateral.dart (widget órfão) |
| 34 | `64d048b` | 25/09/2026 | feat(auth): controle de acesso por função |
| 35 | `7d3a591` | 25/09/2026 | feat(obras): RF010 — alocar equipe à obra |
| 36 | `d7afa98` | 25/09/2026 | feat(dashboard): RF013 simplificado — alertas computados (sem push) |
| 37 | `34581b5` | 25/09/2026 | fix(android): atualiza AGP e Kotlin para a versão mínima exigida pelo Flutter |

---

*Documento gerado em 28/09/2026 a partir do histórico Git e do código-fonte do repositório `paintmanager_app`.*
