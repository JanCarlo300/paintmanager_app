# 🎨 PaintManager

> **Aplicativo de Gestão de Serviços de Pintura** — TFC II (UniRV)

Aplicativo multiplataforma desenvolvido em **Flutter/Dart** para gestão completa de serviços de pintura, voltado a profissionais autônomos e microempresários do setor. O sistema abrange cadastro de clientes, orçamentos, controle de obras, gestão financeira e relatórios gerenciais.

---

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Stack Tecnológico](#-stack-tecnológico)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação e Execução](#-instalação-e-execução)
- [Variáveis de Ambiente](#-variáveis-de-ambiente)
- [Arquitetura](#-arquitetura)
- [Estrutura de Pastas](#-estrutura-de-pastas)
- [Identidade Visual](#-identidade-visual)
- [Módulos](#-módulos)
- [Banco de Dados](#-banco-de-dados)
- [Roteamento](#-roteamento)
- [Testes](#-testes)
- [Dependências](#-dependências)
- [Convenções do Projeto](#-convenções-do-projeto)
- [Autor](#-autor)

---

## 🔍 Visão Geral

O PaintManager resolve os principais desafios da gestão de serviços de pintura:

| Problema | Solução no App |
|---|---|
| Controle manual de clientes | Módulo de **Clientes** com CRUD completo e soft delete |
| Orçamentos em papel | Módulo de **Orçamentos** com cálculo automático de totais |
| Acompanhamento informal de obras | Módulo de **Obras** com etapas, progresso e status |
| Falta de controle financeiro | Módulo **Financeiro** com receitas, despesas e categorização |
| Ausência de indicadores | Módulo de **Relatórios** com KPIs e gráficos |

---

## 🛠 Stack Tecnológico

| Camada | Tecnologia | Versão |
|---|---|---|
| **Framework** | Flutter | SDK Dart ^3.11.0 |
| **Linguagem** | Dart | — |
| **Backend** | Supabase (PostgreSQL + Auth) | `supabase_flutter` ^2.12.2 |
| **Gerenciamento de Estado** | Provider / ChangeNotifier | `provider` ^6.1.5 |
| **Gráficos** | FL Chart | `fl_chart` ^0.70.2 |
| **Tipografia** | Google Fonts (EB Garamond + Manrope) | `google_fonts` ^6.2.1 |
| **Ícones** | Material Symbols Rounded | `material_symbols_icons` ^4.2960.0 |
| **Tema** | Claro/escuro do manual da marca (`core/tema`) | `shared_preferences` ^2.5.6 |
| **Variáveis de Ambiente** | flutter_dotenv | ^5.2.1 |

---

## ✅ Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ^3.9.2
- Conta no [Supabase](https://supabase.com/) com projeto configurado
- Git

---

## 🚀 Instalação e Execução

```bash
# 1. Clone o repositório
git clone https://github.com/JanCarlo300/paintmanager_app.git
cd paintmanager_app

# 2. Instale as dependências
flutter pub get

# 3. Configure as variáveis de ambiente (veja seção abaixo)
cp .env.example .env
# Copie .env.example para .env e preencha SUPABASE_URL e SUPABASE_ANON_KEY

# 4. Execute as migrações SQL no Supabase Dashboard
# (veja a pasta db/)

# 5. Execute o aplicativo
flutter run
```

---

## 🔐 Variáveis de Ambiente

Copie `.env.example` para `.env` e preencha com os dados do seu projeto Supabase (*Project Settings > API*):

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anon-publica
```

> ⚠️ O `.env` é **empacotado dentro do APK** (asset do Flutter). Coloque nele **somente** essas duas chaves públicas — a segurança dos dados vem do RLS. Chaves de administrador (`service_role`, access token, senha do banco) **nunca** entram no `.env`: guarde-as em `.env.servidor`, que fica fora do app e do git. A Edge Function `criar-usuario` recebe a chave de serviço do próprio Supabase.

O `.env` é lido pelo `flutter_dotenv` na classe `SupabaseConfig` (`lib/src/core/config/supabase_config.dart`).

---

## 🏗 Arquitetura

O projeto segue os princípios da **Clean Architecture**, organizado em camadas independentes dentro de módulos de funcionalidade:

```
┌──────────────────────────────────────────┐
│               Apresentação               │
│  (Widgets, Pages, Controllers)           │
│  context.watch<Controller>() ← reativo   │
│  controller.acao()           → mutação   │
├──────────────────────────────────────────┤
│               Domínio                    │
│  (Entidades, Interfaces de Repositório)  │
│  Regras de negócio puras                 │
├──────────────────────────────────────────┤
│               Dados                      │
│  (Modelos/DTOs, Repositórios Impl)       │
│  Supabase ← PostgreSQL + RLS            │
└──────────────────────────────────────────┘
```

### Fluxo de Dados

```
Página (Widget)
    │  context.watch<Controller>()   ← estado reativo
    │  controller.acao()             → dispara mutação
    ▼
Controller (ChangeNotifier)
    │  _carregando = true / notifyListeners()
    │  await _repositorio.metodo()
    │  _carregando = false / notifyListeners()
    ▼
Repositório (Implementação)
    │  SupabaseConfig.client.from('tabela')...
    ▼
Supabase (PostgreSQL + RLS)
    │  retorna Map<String, dynamic>
    ▼
Modelo.deMapa()  →  Entidade
    │
    └─ retorna para o Controller, que atualiza o estado
```

### Injeção de Dependência

A injeção é feita manualmente no `main.dart` via `MultiProvider`. Cada controller recebe sua implementação de repositório:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthController(RepositorioAutenticacaoImpl())),
    ChangeNotifierProvider(create: (_) => ClienteController(RepositorioClienteImpl())),
    ChangeNotifierProvider(create: (_) => OrcamentoController(RepositorioOrcamentoImpl())),
    ChangeNotifierProvider(create: (_) => ObraController(RepositorioObraImpl())),
    ChangeNotifierProvider(create: (_) => FinanceiroController(RepositorioTransacaoImpl())),
    ChangeNotifierProvider(create: (_) => RelatorioController(RepositorioRelatorioImpl())),
    // ...
  ],
)
```

---

## 📁 Estrutura de Pastas

```
paintmanager_app/
├── lib/
│   ├── main.dart                          # Ponto de entrada, MultiProvider e rotas
│   └── src/
│       ├── core/                          # Infraestrutura transversal
│       │   ├── config/                    # Cliente Supabase
│       │   ├── tema/                      # Identidade visual: cores, fontes, medidas, temas
│       │   ├── pdf/                       # PdfService (PDFs gerados no celular)
│       │   ├── filtros/                   # FiltroLista (ordenação, período, prazo)
│       │   ├── servicos/                  # Geocodificação (OpenStreetMap)
│       │   └── validadores/               # ValidadorCpf
│       │
│       ├── apresentacao/                  # UI compartilhada entre módulos
│       │   ├── controllers/               # Dashboard e alertas (sino)
│       │   ├── paginas/
│       │   │   └── dashboard_page.dart    # Resumo Geral
│       │   └── widgets/                   # Menu lateral, GuardaRota, CardApp, StatusChip,
│       │                                  # TelaVazia, LogoApp, busca, data, filtros...
│       │
│       └── modules/                       # Módulos de funcionalidade
│           ├── auth/                      # Autenticação e Usuários
│           ├── clientes/                  # Gestão de Clientes
│           ├── obras/                     # Gestão de Obras
│           ├── orcamentos/                # Gestão de Orçamentos
│           ├── financeiro/                # Gestão Financeira
│           └── relatorios/                # Relatórios e KPIs
│
├── db/                                    # Scripts SQL de migração
│   ├── supabase_migration.sql             # Migração principal (usuario + admin)
│   ├── supabase_migrate_cliente.sql       # Migração do módulo cliente
│   ├── supabase_migrate_orcamento.sql     # Migração do módulo orçamento
│   ├── supabase_migrate_obra.sql          # Migração do módulo obra
│   ├── supabase_migrate_financeiro.sql    # Migração do módulo financeiro
│   ├── supabase_seed_admin.sql            # Seed do usuário administrador
│   └── rls_policy_usuario.sql             # Políticas RLS para a tabela usuario
│
├── test/                                  # Testes automatizados
│   ├── docs/
│   │   └── qa_audit_report.md             # Relatório de auditoria de qualidade
│   └── modules/
│       ├── auth/
│       │   └── dados/modelos/
│       │       └── usuario_modelo_test.dart
│       └── clientes/
│           └── dados/modelos/
│               └── cliente_modelo_test.dart
│
├── assets/                                # Ícone do app, logo, ilustrações e fontes do PDF
├── docs/identidade_visual/                # Plano, passo a passo e progresso da identidade visual
├── tool/identidade_visual/                # Auditoria de valores fixos (verificar.dart)
├── pubspec.yaml                           # Dependências e configuração do projeto
├── analysis_options.yaml                  # Regras de linting
├── ARCHITECTURE.md                        # Documentação detalhada da arquitetura
└── .env                                   # Variáveis de ambiente (não versionado)
```

### Estrutura Interna de Cada Módulo

```
<módulo>/
├── dominio/          # Regras de negócio puras (sem dependências externas)
│   ├── entidades/    # Objetos de domínio imutáveis
│   └── repositorios/ # Interfaces (contratos abstratos)
│
├── dados/            # Implementação de acesso a dados
│   ├── modelos/      # DTOs: estendem entidades, mapeiam JSON ↔ objeto
│   └── repositorios/ # Implementações concretas usando Supabase
│
└── apresentacao/     # Interface do usuário
    ├── controllers/  # ChangeNotifiers: orquestram estado e lógica de UI
    └── paginas/      # Widgets (telas e formulários)
```

---

## 🎨 Identidade Visual

Toda a aparência do app vem de `lib/src/core/tema/`, seguindo o manual da marca (PaintManager Design System, aprovado em 15/10/2026). Plano e passo a passo da implantação: `docs/identidade_visual/`.

**Regra do projeto: nenhuma cor, tamanho de fonte ou sombra fixos fora de `core/tema`.** As telas usam `Theme.of(context)` e a extensão `context.cores`. A auditoria abaixo confere isso.

| Arquivo | Conteúdo |
|---|---|
| `cores_app.dart` | `CoresApp` (`ThemeExtension`) com os tokens nos temas claro e escuro: `primary`, `brand`, `ink`, `inkMuted`, `surface`, `surfaceCard`, `success`/`error`/`warning`/`info` e versões `Soft`, `inverseSurface`... Acesso: `context.cores` |
| `tipografia_app.dart` | `TextTheme` com EB Garamond (títulos) e Manrope (texto e valores em R$) |
| `medidas_app.dart` | `Espaco`, `Raio`, `TamanhoIcone` e `alturaToque` (48) |
| `status_visual.dart` | Mapa único status → rótulo, ícone e cores (orçamentos e obras) |
| `cores_graficos.dart` | Cor fixa por categoria de despesa nos gráficos |
| `tema_app.dart` | `temaClaro()` e `temaEscuro()`: botões, cards sem sombra, campos, diálogos, calendário |
| `tema_controller.dart` | `TemaController`: Automático (segue o celular), Claro ou Escuro, salvo com `shared_preferences` |

**Componentes compartilhados** (`lib/src/apresentacao/widgets/`): `CardApp`, `CardDestaque` (um por tela), `StatusChip`, `IconeModulo`, `TelaVazia` (ilustração clara/escura), `LogoApp`/`AssinaturaApp`, `ChipsFiltroStatus`, `CampoBuscaSelecao`, `CampoData`.

**Ícones:** Material Symbols Rounded (`material_symbols_icons`). **Marca:** ícone do app, logo e ilustrações em `assets/` (ícone gerado com `dart run flutter_launcher_icons`). Os PDFs ficam sempre claros (documento para o cliente).

**Auditoria** (análise + testes + valores fixos; registra em `docs/identidade_visual/PROGRESSO.md`):

```bash
dart run tool/identidade_visual/verificar.dart --final
```

---

## 📦 Módulos

### 🔐 Auth (Autenticação e Usuários)

**Entidade:** `Usuario` — `id`, `authId` (UUID do Supabase Auth), `nome`, `email`, `cpf` (login), `telefone`, `funcao`, `status` (ativo/inativo), `primeiroAcesso`, `criadoEm`.

**Funções e permissões** (valem nas telas, pelo `GuardaRota`, e no banco, por RLS — `db/seguranca_2_permissoes_por_funcao.sql`):

| | Administrador | Gerente | Funcionário |
|---|---|---|---|
| Clientes, Orçamentos | tudo (cliente: só ele exclui) | tudo, menos excluir cliente | — |
| Financeiro | tudo | tudo, menos excluir | — |
| Obras | tudo | tudo, menos excluir | só as obras em que está alocado: vê, marca o checklist e usa o chat |
| Usuários | tudo | — | — |
| Resumo Geral e Relatórios | ✓ | ✓ | — |

**Funcionalidades:**
- Login por CPF + senha: a função `buscar_email_por_login` (SECURITY DEFINER) devolve só o e-mail; ninguém lê a tabela `usuario` sem sessão.
- Recuperação de senha por código enviado ao e-mail (3 passos) e troca obrigatória no primeiro acesso, com regra de senha (`ValidadorSenha`).
- Cadastro de usuário pela **Edge Function** `supabase/functions/criar-usuario` (cria a conta no Auth sem trocar a sessão do administrador; usa a chave de serviço do próprio Supabase, nunca a do app).
- Usuário inativado perde o acesso no banco mesmo com a sessão aberta.
- Configurações: dados da conta, alterar senha (confere a senha atual), aparência (claro/escuro/automático) e versão do app.

---

### 👥 Clientes

**Entidade:** `Cliente` — `id`, `nome`, `email`, `telefone`, `endereco`, `cpfOuCnpj`, `ativo`, `criadoEm`, `atualizadoEm`.

**Funcionalidades:** listagem com filtros (com obra ativa, ativos, inativos) e busca; cadastro e edição; inativação (soft delete). CPF opcional, validado pelo Módulo 11 no app (`ValidadorCpf`) e no banco (trigger, `db/rf_item_3_1_validacao_cpf.sql`). Busca no banco sem diferenciar acentos (`buscar_clientes`).

---

### 📝 Orçamentos

**Entidade:** `Orcamento` — `id`, `idObra` (obrigatório), `clienteNome`, `descricao`, `dataCriacao`, `dataValidade`, `status`, `itensServico` (JSONB: descrição, metragem, valor/m², subtotal), `materiaisInclusos`, `valorMateriais`, `valorMaoDeObra`, `desconto`, `valorTotal` (calculado), `formaPagamento`.

**Regras:**
- Status do DERS: **Pendente, Aprovado, Recusado** (trava `CHECK` no banco). Orçamento Recusado que é editado volta para Pendente.
- A obra só sai de "Não Iniciada" se tiver um orçamento **Aprovado** (app + trigger, `db/rf_item_1_2_obra_inicia_com_orcamento_aprovado.sql`).

**Funcionalidades:** lista com chips de status, busca e filtros (período de criação, vencidos, vencendo em 7 dias); envio ao cliente por **WhatsApp** ou **e-mail** com a mensagem pronta.

---

### 🏗 Obras

**Entidade:** `Obra` — `id`, `idOrcamento`, `idCliente`, `clienteNome`, `tituloDaObra`, `endereco`, `dataInicio`, `dataPrevisaoTermino`, `dataConclusao`, `status` (Não Iniciada / Em Andamento / Pausada / Concluída), `progresso` (calculado pelas etapas), `etapasServico` (JSONB), `listaMateriais` (JSONB: descrição, quantidade, unidade), `latitude`/`longitude`, `criadoEm`.

**Funcionalidades:**
- **Equipe** (`equipe_obra`): Administrador e Gerente alocam funcionários; o Funcionário só vê as obras em que está alocado (RLS).
- **Checklist de etapas** com progresso automático. Obra **Concluída é definitiva**: status, etapas e progresso travam (app + trigger, `db/etapa_5_obra_concluida_travada.sql`).
- **Chat da obra** em tempo real (Supabase Realtime, tabela `obra_mensagem`): autor e cargo preenchidos pelo banco, mensagens não editáveis. Sino com obras que têm mensagens novas (`chat_leitura`, `chat_nao_lidas()`).
- **Mapa:** o endereço vira coordenada (OpenStreetMap/Nominatim, gratuito); mapa nos detalhes e botão "Como chegar".
- **Lista de materiais** editável na obra e **PDF** para compartilhar (WhatsApp, e-mail, salvar).
- Lista com chips de status, busca e filtros (período, atrasadas, terminando em 7 dias).

---

### 💰 Financeiro

**Entidade:** `Transacao` — `id`, `tipo` (Receita/Despesa), `categoria`, `valor` (sempre positivo), `descricao`, `dataTransacao`, `status` (Efetivado/Pendente/Atrasado), `formaPagamento`, `idCliente`, `idOrcamento`, `idObra` (opcional), `clienteNome`, `obraTitulo`, `comprovanteUrl`.

**Regras:** o vínculo com a obra é real (`id_obra`) e só aceita obras **Em Andamento** ou **Concluída** (app + trigger, `db/rf011_transacao_obra.sql`); com obra vinculada, o cliente é o da obra. Só o Administrador exclui lançamentos.

**Funcionalidades:** painel por mês (saldo, pendente, receitas, despesas), lista de lançamentos, cadastro e edição.

---

### 📊 Relatórios

**Entidade:** `RelatorioGeral` — receitas, despesas, lucro líquido, obras concluídas e em andamento, orçamentos gerados e aprovados, taxa de conversão, despesas por categoria e evolução mensal.

**Funcionalidades:** filtros de período (7/30/90 dias, mês, ano, personalizado), gráfico de barras receita × despesa, pizza por categoria (cor fixa por categoria), métricas de operação e **exportação em PDF** — Financeiro e de Progresso — por período e, opcionalmente, por obra. Conta só orçamentos aprovados e obras em andamento ou concluídas (regra do DERS).

---

### 🔔 Alertas (Resumo Geral)

Sino com alertas calculados dos dados já existentes, sem push: orçamentos pendentes vencidos ou vencendo em 3 dias e obras com prazo estourado.

---

## 🗄 Banco de Dados

O backend utiliza **Supabase (PostgreSQL)** com **Row Level Security (RLS)** em todas as tabelas e regras de negócio também em triggers.

### Tabelas

| Tabela | Descrição |
|---|---|
| `usuario` | Usuários do sistema (ligados ao `auth.users` por `auth_id`) |
| `cliente` | Clientes |
| `orcamento` | Orçamentos, itens em JSONB |
| `obra` | Obras: etapas e lista de materiais em JSONB, coordenadas |
| `equipe_obra` | Funcionários alocados em cada obra |
| `obra_mensagem` | Chat de cada obra |
| `chat_leitura` | Até onde cada usuário leu o chat de cada obra |
| `transacao` | Receitas e despesas, com vínculo opcional à obra |

### Scripts (`db/`)

Execute no **SQL Editor do Supabase**. Todos podem rodar duas vezes sem estragar nada. Ordem em que foram aplicados neste projeto:

1. **Estrutura:** `supabase_migration.sql`, `supabase_migrate_cliente.sql`, `supabase_migrate_orcamento.sql`, `supabase_migrate_obra.sql`, `supabase_migrate_financeiro.sql`, `supabase_migrate_equipe_obra.sql`
2. **Administrador inicial:** `supabase_seed_admin.sql` (troque os marcadores `<CPF_DO_ADMIN>`, `<EMAIL_DO_ADMIN>` etc. antes de rodar)
3. **Login:** `rf002_fase_a_buscar_email_login.sql`
4. **Funcionalidades:** `rf_item_2_1_rls_obra_por_alocacao.sql`, `rf_item_3_2_coordenadas_obra.sql`, `rf_item_2_3_chat_obra.sql`, `fix_cliente_tamanho_colunas.sql`, `rf_item_3_1_validacao_cpf.sql`, `fix_colunas_curtas_obra_usuario.sql`, `orcamento_status_3_opcoes.sql`, `rf_item_1_2_obra_inicia_com_orcamento_aprovado.sql`, `etapa_2_busca_com_filtro.sql`, `etapa_5_obra_concluida_travada.sql`, `etapa_6_lista_materiais.sql`, `etapa_7_chat_leitura.sql`, `rf011_transacao_obra.sql`
5. **Segurança (por último):** `seguranca_1_login_sem_leitura_anonima.sql`, `seguranca_2_permissoes_por_funcao.sql`

> ⚠️ **Não rode** `rls_policy_usuario.sql`: é antigo e reabre a leitura anônima da tabela de usuários (substituído pelos scripts de segurança). `diagnostico_*.sql` e `limpeza_*.sql` só serviram para limpar as tabelas do modelo do TFC I num banco antigo.

---

## 🗺 Roteamento

### Rotas Estáticas

| Rota | Tela | Quem acessa |
|---|---|---|
| `/login` | `LoginPage` | todos |
| `/recuperar-senha` | `RecuperarSenhaPage` | todos |
| `/redefinir-senha-obrigatoria` | `RedefinirSenhaObrigatoriaPage` | primeiro acesso |
| `/home` | `DashboardPage` (Resumo Geral) | Administrador, Gerente |
| `/clientes` | `ClienteListPage` | Administrador, Gerente |
| `/usuarios` | `UsuarioListPage` | Administrador |
| `/orcamentos` | `OrcamentoListPage` | Administrador, Gerente |
| `/obras` | `ObraListPage` | todos (Funcionário: só as alocadas) |
| `/financeiro` | `FinanceiroPage` | Administrador, Gerente |
| `/relatorios` | `RelatoriosPage` | Administrador, Gerente |
| `/configuracoes` | `ConfiguracoesPage` | todos |

### Rotas Dinâmicas (`onGenerateRoute`)

| Rota | Argumento | Tela |
|---|---|---|
| `/cliente-formulario` | `Cliente?` | `ClienteFormPage` |
| `/orcamento-formulario` | `Orcamento?` | `OrcamentoFormPage` |
| `/obra-formulario` | `Obra?` | `ObraFormPage` |
| `/obra-detalhes` | `Obra` | `ObraDetalhesPage` |
| `/transacao-formulario` | `Transacao?` ou `Map{tipo}` | `TransacaoFormPage` |

---

## 🧪 Testes

O projeto utiliza `flutter_test` + `mocktail` para testes unitários:

```bash
# Executar todos os testes
flutter test

# Executar com cobertura
flutter test --coverage
```

### Testes Existentes (114)

| Área | O que cobre |
|---|---|
| Modelos | `UsuarioModelo`, `ClienteModelo`, `ItemMaterial` |
| Regras | `ValidadorCpf`, `FiltroLista`, regras dos relatórios |
| PDFs | Lista de materiais, relatório financeiro e de progresso |
| Tema | Contraste WCAG (≥ 4,5:1) nos temas claro e escuro, `status_visual`, `StatusChip`, `TemaController`, cores dos gráficos |

---

## 📚 Dependências

### Produção

| Pacote | Versão | Uso |
|---|---|---|
| `flutter` | SDK | Framework UI |
| `supabase_flutter` | ^2.12.2 | Backend: autenticação e banco de dados |
| `provider` | ^6.1.5 | Gerenciamento de estado (ChangeNotifier) |
| `flutter_dotenv` | ^5.2.1 | Variáveis de ambiente (`.env`) |
| `google_fonts` | ^6.2.1 | Tipografia: EB Garamond + Manrope |
| `mask_text_input_formatter` | ^2.5.0 | Máscara de CPF/CNPJ |
| `intl` | ^0.20.2 | Localização pt_BR (datas e números) |
| `fl_chart` | ^0.70.2 | Gráficos no módulo financeiro |
| `url_launcher` | ^6.3.1 | Abertura de links externos |
| `cupertino_icons` | ^1.0.8 | Ícones iOS-style |
| `material_symbols_icons` | ^4.2960.0 | Ícones Material Symbols Rounded |
| `flutter_svg` | ^2.3.0 | Logo e ilustrações em SVG |
| `shared_preferences` | ^2.5.6 | Guarda a aparência escolhida (claro/escuro) |
| `pdf` / `printing` | ^3.13.1 / ^5.15.1 | PDFs gerados no celular e compartilhamento |
| `flutter_map` / `latlong2` | ^7.0.2 / ^0.9.1 | Mapa da obra (OpenStreetMap) |
| `http` | ^1.2.2 | Geocodificação do endereço |
| `package_info_plus` | ^10.2.2 | Versão do app em Configurações |

### Desenvolvimento

| Pacote | Versão | Uso |
|---|---|---|
| `flutter_test` | SDK | Framework de testes |
| `flutter_lints` | ^5.0.0 | Regras de linting |
| `mocktail` | ^1.0.5 | Mocks para testes unitários |
| `flutter_launcher_icons` | ^0.14.4 | Gera o ícone do app a partir de `assets/icone/` |

---

## 📐 Convenções do Projeto

| Convenção | Descrição |
|---|---|
| **Nomes em português** | Entidades, métodos e variáveis seguem a língua do domínio de negócio |
| **Clean Architecture** | Separação em camadas domínio → dados → apresentação |
| **Erros como `String`** | Repositórios lançam `String`; controllers capturam e exibem ao usuário |
| **Reload após mutação** | Após criar/editar/excluir, o controller recarrega a lista completa |
| **Desnormalização proposital** | Campos como `clienteNome` copiados na gravação para evitar JOINs |
| **Soft delete** | Inativação em vez de exclusão física (`ativo: false`) |
| **Visual só pelo tema** | Nenhuma cor, fonte ou sombra fixa fora de `core/tema`; telas usam `Theme.of(context)` e `context.cores` |
| **Dados complexos em JSONB** | Itens de orçamento e etapas de obra armazenados como JSONB no PostgreSQL |

---

## 🎯 Plataformas Suportadas

| Plataforma | Status |
|---|---|
| Android | ✅ Suportado |
| iOS | ✅ Suportado |
| Web | ✅ Suportado |
| Windows | ✅ Suportado |
| macOS | ✅ Suportado |
| Linux | ✅ Suportado |

---

## 👤 Autor

**Jan Carlo** — TFC II — UniRV (Universidade de Rio Verde)

---

## 📄 Licença

Este projeto é de uso acadêmico (TFC II — UniRV). Todos os direitos reservados.
