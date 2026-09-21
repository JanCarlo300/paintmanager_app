# Arquitetura — PaintManager

## Visão Geral

O PaintManager é um aplicativo Flutter que segue os princípios da **Clean Architecture**, organizando o código em camadas independentes dentro de módulos de funcionalidade. O backend é inteiramente baseado no **Supabase** (PostgreSQL + Auth), e o gerenciamento de estado usa o padrão **Provider / ChangeNotifier**.

---

## Estrutura de Pastas

```
lib/
├── main.dart                        # Ponto de entrada, MultiProvider e rotas
└── src/
    ├── core/                        # Infraestrutura transversal
    │   └── config/
    │       └── supabase_config.dart  # Configuração e acesso ao cliente Supabase
    │
    ├── apresentacao/                # UI compartilhada entre módulos
    │   ├── controllers/
    │   │   └── dashboard_controller.dart
    │   ├── paginas/
    │   │   ├── dashboard_page.dart
    │   │   └── em_construcao_page.dart
    │   └── widgets/
    │       ├── drawer_comum.dart
    │       └── menu_lateral.dart
    │
    └── modules/                     # Módulos de funcionalidade
        ├── auth/
        ├── clientes/
        ├── obras/
        ├── orcamentos/
        ├── financeiro/
        └── relatorios/
```

---

## Camadas por Módulo

Cada módulo é dividido em **três camadas**:

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

### Exemplo: módulo `clientes`

| Arquivo | Camada | Responsabilidade |
|---|---|---|
| `dominio/entidades/cliente.dart` | Domínio | Classe pura `Cliente` com campos e igualdade |
| `dominio/repositorios/repositorio_cliente.dart` | Domínio | Interface abstrata com os contratos CRUD |
| `dados/modelos/cliente_modelo.dart` | Dados | `ClienteModelo extends Cliente` com `deMapa()` e `paraMapa()` |
| `dados/repositorios/repositorio_cliente_impl.dart` | Dados | Implementação real com chamadas ao Supabase |
| `apresentacao/controllers/cliente_controller.dart` | Apresentação | `ChangeNotifier` que expõe `_clientes`, `_carregando` e ações |
| `apresentacao/paginas/cliente_list_page.dart` | Apresentação | Tela de listagem com `context.watch<ClienteController>()` |
| `apresentacao/paginas/cliente_form_page.dart` | Apresentação | Formulário de criação e edição |

---

## Módulos de Funcionalidade

| Módulo | Entidades principais | Funcionalidades |
|---|---|---|
| **auth** | `Usuario` | Login por CPF + senha, recuperação de senha, troca obrigatória no primeiro acesso, logout |
| **clientes** | `Cliente` | Listagem, criação, edição, inativação (soft delete) |
| **obras** | `Obra`, `EtapaServico` | CRUD completo, detalhamento de etapas e acompanhamento de progresso |
| **orcamentos** | `Orcamento`, `ItemServico` | CRUD completo, cálculo automático de totais |
| **financeiro** | `Transacao` | Registro de receitas e despesas, edição, exclusão, categorização |
| **relatorios** | `RelatorioGeral` | KPIs agregados: receitas, despesas, obras, taxa de aprovação |

---

## Padrões de Código

### Entidade (domínio puro)

```dart
class Cliente {
  final int?   id;
  final String nome;
  final String email;
  final bool   ativo;

  const Cliente({required this.id, required this.nome, ...});

  @override
  bool operator ==(Object other) => other is Cliente && other.id == id;
}
```

### Modelo (camada de dados)

```dart
class ClienteModelo extends Cliente {
  factory ClienteModelo.deMapa(Map<String, dynamic> mapa) {
    return ClienteModelo(
      id:    mapa['id_cliente'] as int?,
      nome:  mapa['nome']?.toString() ?? '',
      email: mapa['email']?.toString() ?? '',
      ativo: mapa['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> paraMapa() => {
    'nome':  nome,
    'email': email,
    'ativo': ativo,
    // id e timestamps são gerenciados pelo banco
  };
}
```

### Repositório (implementação)

```dart
class RepositorioClienteImpl implements RepositorioCliente {
  final _supabase = SupabaseConfig.client;

  @override
  Future<List<Cliente>> listarClientes() async {
    final data = await _supabase.from('cliente').select().order('nome');
    return data.map((m) => ClienteModelo.deMapa(m)).toList();
  }

  @override
  Future<void> salvarCliente(Cliente cliente) async {
    final modelo = ClienteModelo.fromCliente(cliente);
    if (cliente.id == null) {
      await _supabase.from('cliente').insert(modelo.paraMapa());
    } else {
      await _supabase.from('cliente').update(modelo.paraMapa()).eq('id_cliente', cliente.id!);
    }
  }
}
```

### Controller (apresentação)

```dart
class ClienteController extends ChangeNotifier {
  final RepositorioCliente _repositorio;
  
  bool         _carregando = false;
  List<Cliente> _clientes  = [];

  bool          get carregando => _carregando;
  List<Cliente> get clientes   => _clientes;

  Future<void> carregarClientes() async {
    _carregando = true;
    notifyListeners();
    try {
      _clientes = await _repositorio.listarClientes();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> salvar(Cliente cliente) async {
    await _repositorio.salvarCliente(cliente);
    await carregarClientes(); // Recarrega a lista após mutação
  }
}
```

---

## Injeção de Dependência

A injeção é feita **manualmente no `main.dart`** via `MultiProvider`. Cada controller recebe sua implementação de repositório na criação:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthController(RepositorioAutenticacaoImpl())),
    ChangeNotifierProvider(create: (_) => ClienteController(RepositorioClienteImpl())),
    ChangeNotifierProvider(create: (_) => ObraController(RepositorioObraImpl())),
    // ...
  ],
  child: const PaintManagerApp(),
)
```

Os widgets acessam os controllers via `context.read<T>()` (uma ação) ou `context.watch<T>()` (reativo a mudanças).

---

## Roteamento

As rotas são declaradas em `main.dart` em dois grupos:

**Rotas estáticas** (sem argumentos):

| Rota | Destino |
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

**Rotas dinâmicas** (`onGenerateRoute`, recebem objetos como argumentos):

| Rota | Argumento | Destino |
|---|---|---|
| `/cliente-formulario` | `Cliente?` | `ClienteFormPage` |
| `/orcamento-formulario` | `Orcamento?` | `OrcamentoFormPage` |
| `/obra-formulario` | `Obra?` | `ObraFormPage` |
| `/obra-detalhes` | `Obra` | `ObraDetalhesPage` |
| `/transacao-formulario` | `Transacao?` ou `Map{tipo}` | `TransacaoFormPage` |

---

## Autenticação e Sessão

O `AuthCheck` é definido como `home:` no `MaterialApp` e funciona como guarda de rota inicial:

```
App inicia
    │
    ▼
AuthCheck.initState()
    │
    ├─ Supabase.currentSession existe? ──► DashboardPage
    │
    └─ Não existe ──────────────────────► LoginPage

Enquanto o app está aberto, escuta onAuthStateChange:
    signedIn  ──► navega para /home
    signedOut ──► navega para /login
```

O login funciona em duas etapas no Supabase: primeiro busca o e-mail pelo CPF na tabela `usuario` (acesso anônimo), depois chama `auth.signInWithPassword()` com as credenciais reais.

---

## Fluxo de Dados

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

---

## Dependências Externas

| Pacote | Versão | Uso |
|---|---|---|
| `supabase_flutter` | ^2.12.2 | Backend: autenticação, banco de dados |
| `provider` | ^6.1.5 | Gerenciamento de estado (ChangeNotifier) |
| `flutter_dotenv` | ^5.2.1 | Variáveis de ambiente (`.env`) |
| `google_fonts` | ^6.2.1 | Tipografia: EB Garamond + Manrope |
| `mask_text_input_formatter` | ^2.5.0 | Máscara de CPF |
| `intl` | ^0.20.2 | Localização pt_BR (datas e números) |
| `fl_chart` | ^0.70.2 | Gráficos no módulo financeiro |
| `url_launcher` | ^6.3.1 | Abertura de links externos |

---

## Convenções e Decisões de Design

- **Nomes em português:** entidades, métodos e variáveis seguem a língua do domínio de negócio.
- **Erros como `String`:** os repositórios lançam `String` ao invés de exceções tipadas; os controllers capturam e exibem ao usuário.
- **Reload após mutação:** após criar, editar ou excluir, o controller sempre recarrega a lista completa — simples e previsível.
- **Desnormalização proposital:** campos como `Obra.clienteNome` são copiados na gravação para evitar JOINs nas consultas de listagem.
- **Soft delete:** inativação em vez de exclusão física (`ativo: false`, `status: 'inativo'`).
- **`core/` minimalista:** apenas a configuração do Supabase hoje; pronto para receber utilitários, constantes e abstrações base conforme o projeto cresce.
