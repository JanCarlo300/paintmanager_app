# Registro de falhas — Verificação e Validação (TFC II)

Falhas encontradas na rodada 1 das evidências (`docs/evidencias_rodada1/`), feita em 24/10/2026 sobre o commit `af9dd31`.

- **Testes automatizados (`flutter test`):** 175 executados, 175 com sucesso e 0 falhas (100%).
- **Análise estática (`flutter analyze`):** 1 problema de nível *info*, corrigido abaixo.

| Nº | Data | Teste / verificação | Falha observada | Causa técnica | Correção aplicada | Arquivos alterados | Commit |
|---|---|---|---|---|---|---|---|
| 1 | 24/10/2026 | Análise estática (`flutter analyze`, regra `unnecessary_import`) em `test/core/validadores/validador_cnpj_test.dart:1:8` | `info - The import of 'package:flutter/services.dart' is unnecessary because all of the used elements are also provided by the import of 'package:flutter_test/flutter_test.dart'` | O teste importava `flutter/services.dart` para usar `TextEditingValue` no teste do formatador de CPF/CNPJ. Como o `flutter_test` já reexporta essa classe, o import ficou redundante. Ele entrou no commit `87854da` (23/10/2026). | Removi a linha do import. Depois disso, o `flutter analyze` deu `No issues found!` e os 7 testes do arquivo continuaram passando. | `test/core/validadores/validador_cnpj_test.dart` | `aefb4de` |
