 Relatório Técnico de Auditoria de QA e Testes Unitários

**Projeto:** PaintManager App  
**Data da Auditoria:** 13 de Abril de 2026  
**Responsável:** QA & Senior Software Engineer (Agent)  
**Escopo da Auditoria:** Módulos Fundamentais (Modelos de Domínio e Dados da Nova Arquitetura — Auth e Clientes)

---

## 1. Resumo Executivo

No âmbito da migração de arquitetura do projeto PaintManager (Firebase para Supabase / Clean Architecture), este ciclo inicial de testes definiu a linha base ("baseline") de cobertura. Por tratar-se de uma aplicação em transição massiva sem testes legados confiáveis, o escopo inicial incidiu exclusivamente sobre os **Modelos de Dados** e **Entidades de Domínio** dos módulos principais (`Auth` e `Clientes`).

A biblioteca `mocktail` foi previamente configurada para suportar a injeção de dependências nos testes das próximas camadas (Repositórios e Controladores).

> [!NOTE]
> **Métricas de Cobertura (Arquivos Testados)**
> - **Total de Linhas Mapeadas (LF):** 51 linhas  
> - **Total de Linhas Cobertas (LH):** 47 linhas  
> - **Cobertura Relativa (Statement/Branches nos Modelos):** ~92.1%  
> - **Cobertura Global do Projeto:** < 1% (O baseline global será elevado iterativamente conforme outros repositórios e controllers recebam testes).

---

## 2. Casos de Teste Estruturados

Abaixo, detalhamos os testes isolados implementados e validados nas classes responsáveis pela serialização dos dados JSON do backend (Supabase) para o Flutter.

| Test ID | Suíte / Módulo | Descrição do Cenário | Entradas Utilizadas | Resultado Esperado | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-AUTH-001** | `usuario_modelo_test.dart` | Conversão `deMapa` (JSON p/ Object) | Map contendo chaves snake_case válidas simulando retorno SQL | Retornar instância de `UsuarioModelo` com atributos correspondentes mapeados corretamente. | ✔️ Pass |
| **TC-AUTH-002** | `usuario_modelo_test.dart` | Conversão `paraMapa` (Object p/ JSON) | Instância popualada de `UsuarioModelo` com timezone gerada em `toUtc()` | Retornar Map snake_case compatível com `insert`/`update` no Supabase. | ✔️ Pass |
| **TC-CLI-001** | `cliente_modelo_test.dart` | Conversão `deMapa` (JSON p/ Object) | Map com chaves `id_cliente` e datas `created_at`/`updated_at` | Retornar `ClienteModelo` mantendo a tipagem Data e os `nullables` corretos. | ✔️ Pass |
| **TC-CLI-002** | `cliente_modelo_test.dart` | Conversão `paraMapa` (Object p/ JSON) | Instância povoada de `ClienteModelo` | Retornar Map snake_case **excluindo** IDs e timestamps controlados por banco de dados. | ✔️ Pass |

---

## 3. Relatório de Falhas

Durante a primeira execução oficial do pipeline com os testes reescritos, **nenhuma falha crítica de lógica de serialização** foi observada nos testes dos Modelos.  

> [!TIP]
> **Sugestão de Melhoria (Débito Técnico Identificado):**
> No arquivo `cliente.dart` (Entidades), os overrides de operador de igualdade (`operator ==` e `hashCode`) não estão sendo atingidos pela atual suíte (cobertura registrou falta nas linhas 26-32 de `cliente.dart`). É recomendado, em Pull Requests futuras, adicionar testes isolados confirmando que duas instâncias de `Cliente` com o mesmo `id` são efetivamente a mesma entidade na alocação de memória (Data equality tests).

---

## 4. Logs de Execução (Pipeline Local)

A execução ocorreu usando o binário principal `flutter test` com a tag de extração de relatórios lcov para CI/CDs.

```sh
$ flutter test --coverage
00:00 +0: C:/Users/janca/Documents/TFCII/paintmanager_app/test/modules/auth/dados/modelos/usuario_modelo_test.dart: UsuarioModelo Tests deMapa deve retornar um UsuarioModelo valido
00:00 +1: C:/Users/janca/Documents/TFCII/paintmanager_app/test/modules/auth/dados/modelos/usuario_modelo_test.dart: UsuarioModelo Tests paraMapa deve retornar um Map contendo os dados corretos
00:01 +2: C:/Users/janca/Documents/TFCII/paintmanager_app/test/modules/clientes/dados/modelos/cliente_modelo_test.dart: ClienteModelo Tests deMapa deve retornar um ClienteModelo valido
00:01 +3: C:/Users/janca/Documents/TFCII/paintmanager_app/test/modules/clientes/dados/modelos/cliente_modelo_test.dart: ClienteModelo Tests paraMapa deve retornar um Map contendo os dados corretos limitados (sem keys geradas)
00:02 +4: All tests passed!

Exit code: 0
```

---

## 5. Próximos Passos (Next Steps p/ Code Review)

Para a expansão deste processo na equipe, sugere-se a seguinte progressão:

1. **Repositórios de Dados:** Utilizar o recém-inserido pacote `mocktail` para simular requisições de rede `SupabaseClient` no módulo de autenticação.
2. **State Controllers:** Aplicar os mocks dos repositórios injetando-os via construtores para validar os fluxos em `ChangeNotifier` ou `BLoC` (disparo de `NotifyListeners`).
3. **CI/CD Hook:** Adicionar o comando `flutter test --coverage` nas pre-commit hooks ou no GitHub Actions.
