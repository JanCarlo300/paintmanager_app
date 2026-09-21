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
| **Framework** | Flutter | SDK ^3.9.2 |
| **Linguagem** | Dart | — |
| **Backend** | Supabase (PostgreSQL + Auth) | `supabase_flutter` ^2.12.2 |
| **Gerenciamento de Estado** | Provider / ChangeNotifier | `provider` ^6.1.5 |
| **Gráficos** | FL Chart | `fl_chart` ^0.70.2 |
| **Tipografia** | Google Fonts (EB Garamond + Manrope) | `google_fonts` ^6.2.1 |
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
# Edite o arquivo .env com suas credenciais do Supabase

# 4. Execute as migrações SQL no Supabase Dashboard
# (veja a pasta db/)

# 5. Execute o aplicativo
flutter run
```

---

## 🔐 Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anonima-aqui
```

> **Nota:** O arquivo `.env` é carregado pela biblioteca `flutter_dotenv` e acessado via a classe `SupabaseConfig` em `lib/src/core/config/supabase_config.dart`.

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
│       │   └── config/
│       │       └── supabase_config.dart   # Configuração e acesso ao cliente Supabase
│       │
│       ├── apresentacao/                  # UI compartilhada entre módulos
│       │   ├── controllers/
│       │   │   └── dashboard_controller.dart
│       │   ├── paginas/
│       │   │   ├── dashboard_page.dart
│       │   │   └── em_construcao_page.dart
│       │   └── widgets/
│       │       ├── drawer_comum.dart
│       │       └── menu_lateral.dart
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

## 📦 Módulos

### 🔐 Auth (Autenticação e Usuários)

**Entidade:** `Usuario`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `int?` | ID do registro na tabela |
| `authId` | `String?` | UUID do Supabase Auth |
| `nome` | `String` | Nome completo |
| `email` | `String` | E-mail |
| `cpf` | `String` | CPF (usado como login) |
| `telefone` | `String` | Telefone de contato |
| `funcao` | `String` | Administrador / Funcionário |
| `status` | `bool` | Ativo/Inativo |
| `primeiroAcesso` | `bool` | Obriga troca de senha no primeiro login |
| `criadoEm` | `DateTime` | Data de criação |

**Funcionalidades:**
- Login por CPF + senha (busca email pelo CPF, depois autentica via Supabase Auth)
- Recuperação de senha
- Troca obrigatória de senha no primeiro acesso
- Gestão de usuários (listagem, criação, edição)
- Logout

**Fluxo de autenticação:**
```
App inicia → AuthCheck
    ├─ Sessão Supabase existe? → DashboardPage
    └─ Não existe            → LoginPage

onAuthStateChange:
    signedIn  → navega para /home
    signedOut → navega para /login
```

---

### 👥 Clientes

**Entidade:** `Cliente`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `int?` | ID do registro |
| `nome` | `String` | Nome completo |
| `email` | `String` | E-mail |
| `telefone` | `String` | Telefone |
| `endereco` | `String` | Endereço |
| `cpfOuCnpj` | `String` | CPF ou CNPJ |
| `ativo` | `bool` | Ativo/Inativo (soft delete) |
| `criadoEm` | `DateTime` | Data de criação |
| `atualizadoEm` | `DateTime?` | Última atualização |

**Funcionalidades:** Listagem, criação, edição, inativação (soft delete)

---

### 📝 Orçamentos

**Entidade:** `Orcamento`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `int?` | ID do registro |
| `idObra` | `int?` | Referência à obra (se vinculado) |
| `clienteNome` | `String` | Nome do cliente (desnormalizado) |
| `descricao` | `String` | Descrição do serviço |
| `dataCriacao` | `DateTime` | Data de criação |
| `dataValidade` | `DateTime` | Data de validade |
| `status` | `String` | Pendente / Aprovado / Rejeitado / Concluído |
| `itensServico` | `List<ItemServico>` | Itens detalhados (JSONB) |
| `materiaisInclusos` | `bool` | Se materiais estão inclusos |
| `valorMateriais` | `double` | Valor dos materiais |
| `valorMaoDeObra` | `double` | Valor da mão de obra |
| `desconto` | `double` | Desconto aplicado |
| `valorTotal` | `double` | **Calculado automaticamente** |
| `formaPagamento` | `String` | PIX / Cartão / Dinheiro / Boleto |

**Sub-entidade:** `ItemServico` — descrição, metragem (m²), valor unitário (R$/m²), subtotal calculado.

**Funcionalidades:** CRUD completo, cálculo automático de totais, verificação de vencimento

---

### 🏗 Obras

**Entidade:** `Obra`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `int?` | ID do registro |
| `idOrcamento` | `int?` | Orçamento vinculado |
| `idCliente` | `int` | Cliente responsável |
| `clienteNome` | `String` | Nome do cliente (desnormalizado) |
| `tituloDaObra` | `String` | Título descritivo |
| `endereco` | `String` | Local da obra |
| `dataInicio` | `DateTime` | Início previsto |
| `dataPrevisaoTermino` | `DateTime` | Término previsto |
| `dataConclusao` | `DateTime?` | Data de conclusão efetiva |
| `status` | `String` | Não Iniciada / Em Andamento / Pausada / Concluída |
| `progresso` | `double` | 0–100% (**calculado automaticamente**) |
| `etapasServico` | `List<EtapaServico>` | Etapas do serviço (JSONB) |
| `anotacoes` | `String` | Observações gerais |
| `materiaisFaltantes` | `List<String>` | Lista de materiais pendentes |

**Sub-entidade:** `EtapaServico` — nome da etapa + flag de conclusão.

**Funcionalidades:** CRUD completo, progresso automático baseado em etapas, detalhamento completo

---

### 💰 Financeiro

**Entidade:** `Transacao`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | `int?` | ID do registro |
| `tipo` | `String` | Receita / Despesa |
| `categoria` | `String` | Mão de Obra / Materiais / Ferramentas / Transporte / Alimentação / Outros |
| `valor` | `double` | Valor (sempre positivo no banco) |
| `descricao` | `String` | Descrição da transação |
| `dataTransacao` | `DateTime` | Data da transação |
| `status` | `String` | Efetivado / Pendente / Atrasado |
| `formaPagamento` | `String` | PIX / Cartão de Crédito / Dinheiro / Boleto |
| `idCliente` | `int?` | Cliente associado |
| `idOrcamento` | `int?` | Orçamento associado |
| `clienteNome` | `String?` | Nome do cliente (desnormalizado) |
| `obraTitulo` | `String?` | Título da obra (desnormalizado) |
| `comprovanteUrl` | `String?` | URL do comprovante |

**Funcionalidades:** Registro de receitas e despesas, edição, exclusão, categorização, gráficos (FL Chart)

---

### 📊 Relatórios

**Entidade:** `RelatorioGeral`

| KPI | Descrição |
|---|---|
| `totalReceitas` | Soma de todas as receitas no período |
| `totalDespesas` | Soma de todas as despesas no período |
| `lucroLiquido` | Receitas − Despesas (calculado) |
| `quantidadeObrasConcluidas` | Obras com status "Concluída" |
| `quantidadeObrasEmAndamento` | Obras com status "Em Andamento" |
| `totalOrcamentosGerados` | Quantidade total de orçamentos |
| `totalOrcamentosAprovados` | Orçamentos com status "Aprovado" |
| `taxaConversaoOrcamentos` | Aprovados / Gerados × 100 (calculado) |
| `despesasPorCategoria` | Breakdown por categoria |
| `receitasPorMes` / `despesasPorMes` | Evolução mensal |

---

## 🗄 Banco de Dados

O backend utiliza **Supabase (PostgreSQL)** com **Row Level Security (RLS)** habilitado.

### Tabelas Principais

| Tabela | Descrição |
|---|---|
| `usuario` | Usuários do sistema (vinculados ao `auth.users` via `auth_id`) |
| `cliente` | Clientes cadastrados |
| `orcamento` | Orçamentos com itens em JSONB |
| `obra` | Obras com etapas em JSONB |
| `transacao` | Transações financeiras (receitas e despesas) |

### Scripts de Migração

Os scripts SQL estão na pasta `db/` e devem ser executados no **SQL Editor do Supabase** na seguinte ordem:

1. `supabase_migration.sql` — Tabela `usuario` + RLS + admin inicial
2. `supabase_migrate_cliente.sql` — Tabela `cliente`
3. `supabase_migrate_orcamento.sql` — Tabela `orcamento`
4. `supabase_migrate_obra.sql` — Tabela `obra`
5. `supabase_migrate_financeiro.sql` — Tabela `transacao`
6. `rls_policy_usuario.sql` — Políticas RLS adicionais
7. `supabase_seed_admin.sql` — Seed do administrador

---

## 🗺 Roteamento

### Rotas Estáticas

| Rota | Tela |
|---|---|
| `/login` | `LoginPage` |
| `/home` | `DashboardPage` |
| `/recuperar-senha` | `RecuperarSenhaPage` |
| `/redefinir-senha-obrigatoria` | `RedefinirSenhaObrigatoriaPage` |
| `/clientes` | `ClienteListPage` |
| `/usuarios` | `UsuarioListPage` |
| `/orcamentos` | `OrcamentoListPage` |
| `/obras` | `ObraListPage` |
| `/financeiro` | `FinanceiroPage` |
| `/relatorios` | `RelatoriosPage` |
| `/configuracoes` | `EmConstrucaoPage` |

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

### Testes Existentes

| Arquivo | Módulo | Tipo |
|---|---|---|
| `usuario_modelo_test.dart` | Auth | Unitário (modelo) |
| `cliente_modelo_test.dart` | Clientes | Unitário (modelo) |

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

### Desenvolvimento

| Pacote | Versão | Uso |
|---|---|---|
| `flutter_test` | SDK | Framework de testes |
| `flutter_lints` | ^5.0.0 | Regras de linting |
| `mocktail` | ^1.0.5 | Mocks para testes unitários |

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
| **`core/` minimalista** | Apenas configuração do Supabase; pronto para crescer |
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
