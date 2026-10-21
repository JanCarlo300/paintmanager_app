# PaintManager — Relatório de Status do Projeto

**TFC II — UniRV** · Autor: Jan Carlo · **Data de referência: 18/10/2026** (criado em 12/10, atualizado a cada etapa)
Base: código atual da branch `main`, scripts em `db/`, testes em `test/` e o relatório anterior de 01/10/2026.

---

## 1. Resumo

| Indicador | Situação |
|---|---|
| Requisitos funcionais (RF001–RF013) | **13 completos · 0 parciais · 0 não implementados** (atualizado em 15/10) |
| Backlog de 02/10 (itens 1.x, 2.x, 3.x) | **Concluído** — 1.1 e 2.2 encerrados sem alteração por decisão do Jan; 1.2, 2.1, 2.3, 3.1 e 3.2 entregues e aprovados |
| Plano de ajustes de outubro (Etapas 1 a 8.1) | **Todas entregues e aprovadas em 15/10** |
| Testes automatizados | **114 testes passando**: modelos, validador de CPF, filtros das listas, item de material, PDFs, regras dos relatórios e, desde a identidade visual, contraste WCAG dos dois temas, status, `StatusChip`, `TemaController` e cores dos gráficos. Ainda sem testes de repositórios e controllers |
| Identidade visual | **Nova identidade do manual da marca concluída em 18/10** (Fases 0–6), com modo escuro; zero cores/fontes fixas fora de `core/tema` |
| Backend | Supabase (PostgreSQL + Auth + RLS + Edge Function + Realtime) |
| Segurança no banco | **Matriz de funções aplicada por RLS em todas as tabelas** e login sem leitura anônima (16/10) |
| Build Android | APK debug gerando e instalando no Samsung A55 (se o adb não achar o celular, desligar a Ancoragem USB) |
| Cronograma | A Semana 10 (28/09–03/10, "V&V finalizada") passou com cobertura de testes baixa; desde então subiu de 4 para 114 testes |

**Desde o relatório de 01/10:** todo o backlog do brief e todas as etapas do plano de ajustes foram entregues e aprovados por você.

---

## 2. Requisitos Funcionais (DERS)

| RF | Requisito | Status | Observação |
|---|---|---|---|
| RF001 | Realizar Login | ✅ Completo | CPF + senha via Supabase Auth |
| RF002 | Recuperar Senha | ✅ Completo | CPF/e-mail → código por e-mail → nova senha; troca obrigatória no primeiro acesso para todas as funções |
| RF003 | Manter Usuário | ✅ Completo | CRUD com 3 funções; cadastro via Edge Function (sem trocar a sessão do administrador) |
| RF004 | Manter Cliente | ✅ Completo | CRUD com inativação |
| RF005 | Criar Orçamento | ✅ Completo | Itens de serviço estruturados, total automático |
| RF006 | Enviar Orçamento | ✅ Completo | O administrador escolhe enviar por WhatsApp ou e-mail; considerado completo por decisão do autor (13/10) |
| RF007 | Atualizar Status de Orçamento | ✅ Completo | Embutido no formulário; desde 15/10 só os 3 status do DERS (Pendente, Aprovado, Recusado) |
| RF008 | Manter Obra | ✅ Completo | Agora com localização no mapa (item 3.2) |
| RF009 | Registrar Atividades da Obra | ✅ Completo | O chat da obra registra autor, cargo e data/hora de cada mensagem, formando o histórico que o DERS pede; validado em aparelho |
| RF010 | Alocar Equipe à Obra | ✅ Completo | Tabela `equipe_obra`; alocar/desalocar pela tela da obra |
| RF011 | Registrar Despesas e Receitas | ✅ Completo | Desde 15/10, receita/despesa tem vínculo real com a obra (`id_obra`, opcional); só obras Em Andamento ou Concluída recebem lançamentos (app + trigger). `db/rf011_transacao_obra.sql` |
| RF012 | Gerar Relatórios | ✅ Completo | Painel com gráficos + exportação em PDF (Financeiro e Progresso) por período e, opcionalmente, por obra, com a regra do DERS (só orçamentos aprovados e obras em andamento/concluídas) |
| RF013 | Enviar Notificações | ✅ Completo | Alertas calculados no sino do Resumo Geral (orçamentos vencendo, obras atrasadas), dentro do app. Sem push nem e-mail, por decisão do Jan (15/10) |

---

## 3. Entregue nesta etapa

### Item 2.1 — Funcionário só acessa obras em que está alocado ✅ validado
- **App:** a lista mostra só as obras alocadas e abrir uma obra por navegação direta mostra "Acesso restrito".
- **Banco:** nova política RLS em `obra` (`db/rf_item_2_1_rls_obra_por_alocacao.sql`). Administrador e Gerente leem tudo; Funcionário só lê as obras de `equipe_obra`.
- Testado por você com os três perfis.

### Item 2.3 — Chat da obra ✅ validado
- Substitui o campo único de "Anotações". Balões com autor, cargo e horário; suas mensagens à direita, as dos outros à esquerda.
- **Tempo real** com Supabase Realtime.
- O texto antigo de cada obra foi migrado como primeira mensagem ("Observação importada"); a coluna `obra.anotacoes` ficou no banco como backup.
- Segurança no banco: nome e cargo do autor preenchidos por trigger (não dá para falar em nome de outro); mesma regra de alocação do item 2.1; mensagens não são editáveis nem apagáveis.
- Script: `db/rf_item_2_3_chat_obra.sql`.

### Item 3.2 — Localização da obra ✅ validado
- Escolhida a alternativa **gratuita OpenStreetMap/Nominatim** (sem chave de API, sem cobrança).
- Ao salvar a obra, o endereço vira latitude/longitude. Se a busca falhar, a obra é salva normalmente, sem mapa.
- Detalhes da obra: **mapa embutido** com marcador e botão **"Como chegar"**, que abre a rota no Google Maps pela coordenada (ou pelo endereço em texto, se não houver coordenada).
- Script: `db/rf_item_3_2_coordenadas_obra.sql`.
- Também corrigido um bug meu: o repositório não gravava as coordenadas no banco.

### Item 2.2 — Encerrado sem alteração
Por decisão sua, o Administrador mantém acesso ilimitado, inclusive a adicionar material faltante.

### Correção — Botão voltar do Android ✅ validado
O menu lateral e os atalhos trocavam de tela substituindo a anterior, então o voltar fechava o app. Agora a tela inicial do usuário fica na base da pilha, e o voltar só fecha o app nela. "Sair" limpa a pilha.

---

## 4. O que falta

### 4.1 Backlog do seu brief

| Item | Situação | Observação |
|---|---|---|
| **3.1 — parte do CPF (Módulo 11)** | ✅ Concluída e validada pelo Jan em 15/10 | `ValidadorCpf` + 9 testes unitários, formulários de cliente (CPF opcional) e usuário, triggers no banco (`db/rf_item_3_1_validacao_cpf.sql`) |
| **3.1 — escopo** | ✅ Concluído | O pedido original do 3.1 era só a validação do CPF; não há "restante". Melhoria opcional futura: aceitar e validar CNPJ no cadastro de cliente (hoje o campo só aceita CPF) |
| **Calendário de início/fim da obra** | ✅ Atendido pela Etapa 3 | Período "De → Até" em português e com as cores do app |
| **Filtros nas abas de pesquisa** | ✅ Atendido pela Etapa 4 | Em Obras e Orçamentos: ordenação, período de criação, prazo e chips de status (o Jan escolheu período e prazo; valor e cliente ficaram de fora) |
| **1.1 — "Obra pausada" como "obra ativa"** | ✅ Encerrado sem alteração | Decisão do Jan (13/10): a regra atual fica como está |
| **1.2 — Obra só inicia com orçamento Aprovado** | ✅ Feito em 15/10 · ✅ aprovado pelo Jan | `ObraController.atualizarStatus` bloqueia sair de "Não Iniciada" sem orçamento Aprovado; trigger no banco repete a regra; obras "Em Andamento" sem orçamento aprovado voltam para "Não Iniciada" (`db/rf_item_1_2_obra_inicia_com_orcamento_aprovado.sql`). Sem botão "Iniciar obra" — a obra continua sendo iniciada na tela da obra |
| **Etapa 8.1 — Relatórios em PDF (RF012)** | ✅ Feito em 15/10 · ✅ aprovado pelo Jan | Card "Exportar em PDF" na tela de Relatórios: usa o período selecionado e, opcionalmente, uma obra (campo de busca). PDF Financeiro: receitas, despesas, lucro, orçamentos aprovados, despesas por categoria e lançamentos. PDF de Progresso: obras iniciadas no período com status (marca atrasadas), período, % e etapas. Reaproveita o `PdfService`; regras em `relatorios/dominio/pdf_relatorios.dart` com 5 testes unitários |
| **Etapa 7 — Aviso de mensagens do chat na tela de Obras** | ✅ Feito em 15/10 · ✅ aprovado pelo Jan | Sino na tela de Obras com o número de obras que têm mensagens novas (lista as obras e abre direto no chat) e contador no card de cada obra. Vale para todos, cada um nas suas obras; mensagens da própria pessoa não contam. Abrir o chat marca como lido. Banco: tabela `chat_leitura` + funções `chat_nao_lidas()` e `marcar_chat_lido()`, com RLS (`db/etapa_7_chat_leitura.sql`). O sino do Resumo Geral (RF013) continua igual |
| **Etapa 6b — Lista de Materiais visível + PDF (8.2)** | ✅ Feito em 15/10 · ✅ aprovado pelo Jan | Botão "Editar obra" (lápis) nos detalhes — antes não existia nenhuma forma de abrir a edição. Card "Lista de Materiais" só leitura nos detalhes (Administrador e Gerente) com botão "Gerar PDF"; ao salvar uma obra com materiais o app oferece o PDF. PDF gerado no celular (pacotes `pdf`/`printing`, fonte Roboto embutida para acentos): cliente (nome, telefone), obra (título, endereço), materiais numerados (descrição, qtd., unidade) e observação opcional; abre o compartilhar (WhatsApp, e-mail, salvar). Serviço reutilizável `PdfService` (`lib/src/core/pdf/`) para o RF012; 3 testes unitários |
| **Etapa 6 — Lista de Materiais** | ✅ Feito em 15/10 · ✅ aprovado pelo Jan | "Materiais Faltantes" virou "Lista de Materiais" no cadastro/edição da obra, com descrição + quantidade + unidade por item (entidade `ItemMaterial`, 4 testes unitários); editável em "Editar Obra" (Administrador e Gerente). Seção removida dos detalhes da obra — pedidos de material vão pelo chat. Banco: coluna `lista_materiais` (JSONB) no lugar de `materiais_faltantes`, itens de teste antigos descartados por decisão do Jan (`db/etapa_6_lista_materiais.sql`) |
| **Etapa 5 — Obra concluída travada** | ✅ Feito em 15/10 · ✅ aprovado pelo Jan | Concluída é definitiva (ninguém reabre): checklist sem toque com aviso, menu de status vira cadeado, controller e trigger no banco recusam mudar status/etapas/progresso. Concluir sempre pede confirmação e, se houver etapas pendentes, marca todas como concluídas (100%). Migração corrige obras já concluídas abaixo de 100% (`db/etapa_5_obra_concluida_travada.sql`). Corrigidos no formulário de edição: etapas voltavam todas para pendente e a data de conclusão era apagada |
| **Etapa 4 — Filtros e ordenação (Obras e Orçamentos)** | ✅ Feito em 15/10 · ✅ aprovado pelo Jan | Botão de filtro ao lado da busca abre painel com: ordenar Mais recentes/Mais antigos (feito na consulta ao banco e lembrado pelo controller), período de criação (hoje, ontem, 7 dias, 30 dias, intervalo) e prazo (obras atrasadas / terminando em 7 dias; orçamentos pendentes vencidos / vencendo em 7 dias). Obras ganhou chips de status. Componentes compartilhados: `FiltroLista` (`lib/src/core/filtros/`, 12 testes unitários), `BotaoFiltroLista`, `ChipsFiltroStatus`. Paginação ainda não feita (listas carregam tudo) |
| **Etapa 3 — Calendário em português** | ✅ Feito em 15/10 · ✅ aprovado pelo Jan | App inteiro em pt_BR (`flutter_localizations`); calendários com as cores Sahara pelo tema (`datePickerTheme`); campo de data padrão `CampoData` na Nova Obra (período "De → Até" com contagem de dias), validade do orçamento e data da transação; previsão de término nunca antes do início. Corrigido travamento ao editar orçamento com validade vencida |
| **Etapa 2 — Busca com filtro** | ✅ Feito em 15/10 · ✅ aprovado pelo Jan | Componente único `CampoBuscaSelecao` (`lib/src/apresentacao/widgets/`) no cliente da Nova Obra, na obra do Novo Orçamento e no "Adicionar funcionário" da equipe. Busca no banco (até 20 resultados, sem diferenciar acentos e maiúsculas; clientes também por CPF/CNPJ e telefone) via `db/etapa_2_busca_com_filtro.sql`. Lista fecha ao selecionar, limpar, tocar fora, apertar voltar ou esconder o teclado |
| **Etapa 1 — Status do orçamento (3 opções)** | ✅ Feito em 15/10 · ✅ aprovado pelo Jan | Só Pendente / Aprovado / Recusado, como no DERS. "Concluído" migrado para Aprovado, "Rejeitado" para Recusado (corrigido o filtro de recusados que nunca mostrava nada); Recusado editado volta sozinho para Pendente; trava `CHECK` no banco (`db/orcamento_status_3_opcoes.sql`) |

### 4.2 Segurança
- **✅ Segurança 1 — RF002 Fase B (16/10, testado pelo Jan):** o login descobre o e-mail pelo CPF só pela função `buscar_email_por_login`; a leitura anônima da tabela `usuario` foi removida (`db/seguranca_1_login_sem_leitura_anonima.sql`). Os scripts em `db/` com CPF, e-mail e senha reais do administrador foram trocados por marcadores (`<CPF_DO_ADMIN>` etc.). **Atenção:** o repositório é público e o histórico do git ainda guarda esses dados antigos — a senha do administrador foi trocada; tornar o repositório privado é recomendado.
- **✅ Segurança 2 — Permissões por função no banco (16/10, testado pelo Jan com as 3 funções):** a matriz do app agora também vale no banco, por RLS (`db/seguranca_2_permissoes_por_funcao.sql`):

  | Tabela | Administrador | Gerente | Funcionário |
  |---|---|---|---|
  | `cliente` | tudo | tudo, menos excluir | nada |
  | `orcamento` | tudo | tudo | nada |
  | `transacao` | tudo | tudo, menos excluir | nada |
  | `obra` | tudo | tudo, menos excluir | lê as alocadas; altera só o checklist |
  | `equipe_obra` | tudo | tudo | vê a equipe das suas obras |
  | `usuario` | tudo | lê todos | lê o próprio e os colegas das suas obras |

  Fechou a brecha em que qualquer usuário podia mudar a própria função para Administrador (trigger: fora o Administrador, no próprio cadastro só muda o "primeiro acesso"). Usuário inativado perde o acesso mesmo com a sessão aberta. Funções auxiliares `minha_funcao()`, `eh_admin()`, `eh_gestor()`, `minhas_obras()` (SECURITY DEFINER). Continuam valendo as regras de negócio por trigger (CPF, status do orçamento, início e conclusão da obra, obra do lançamento) e as do chat.
- **Edge Function `criar-usuario`:** confirmar que está implantada no Supabase (o cadastro de usuário depende dela).

### 4.3 Testes (V&V)
- **114 testes unitários passando**: modelos de Usuário e Cliente, `ValidadorCpf`, `FiltroLista`, `ItemMaterial`, PDF da Lista de Materiais, regras/PDFs dos relatórios e os testes do tema (contraste WCAG ≥ 4,5:1 nos temas claro e escuro, `status_visual`, `StatusChip`, `TemaController`, cores dos gráficos).
- **Ainda sem testes** de repositórios (Supabase), controllers e telas, nem de `ValidadorSenha` e `GeocodificacaoService`.
- Os testes manuais de cada etapa foram feitos por você no Samsung A55 e estão registrados nas tabelas acima.

### 4.4 Documentação e repositório
- ✅ `README.md` e `ARCHITECTURE.md` atualizados em 18/10: identidade visual, cada módulo como está hoje (equipe, chat, mapa, PDFs, Edge Function, permissões por função), banco com as 8 tabelas e a ordem dos scripts (com aviso para **não** rodar o antigo `rls_policy_usuario.sql`), rotas e fluxo de login.
- ✅ `.env.example` criado. **Corrigida falha de segurança (18/10):** o `.env` ia inteiro dentro do APK com chaves de administrador (`service_role`, access token, senha do banco). Elas foram para `.env.servidor` (fora do app e do git); o APK agora leva só `SUPABASE_URL` e `SUPABASE_ANON_KEY` (conferido no APK gerado). O APK antigo nunca saiu do celular do Jan, então não foi preciso trocar a chave.
- **Figura 19 (DER) do relatório do TFC:** precisa ser refeita com as tabelas reais (`usuario`, `cliente`, `obra`, `orcamento`, `transacao`, `equipe_obra`, `obra_mensagem`, `chat_leitura`).
- ✅ Tela de **Configurações** (16/10, testada pelo Jan): dados da conta do usuário logado, **Alterar senha** (confere a senha atual; mesma regra de senha do primeiro acesso) e versão do app. Substituiu o placeholder "Em construção".
- Redação da monografia: não tenho como ver isso pelo código; você precisa confirmar o andamento.

### 4.5 Nova identidade visual ✅ (branch `feat/identidade-visual`, pronta para juntar na `main`)
Troca da paleta "Sahara" pelo manual da marca aprovado em 15/10, seguindo `kit_identidade_visual/PLANO_IDENTIDADE_VISUAL.md` e o `PASSO_A_PASSO.md`. Só visual: nenhuma regra, permissão ou consulta ao banco muda. Placar da auditoria em `docs/identidade_visual/PROGRESSO.md`.

| Fase | Situação | Observação |
|---|---|---|
| 0 — Preparação | ✅ 16/10 | Branch, imagens da marca, dependências `flutter_svg`, `material_symbols_icons`, `shared_preferences` e `flutter_launcher_icons`. Linha de base: 1.359 valores fixos em 29 arquivos |
| 1 — Fundação do tema | ✅ 16/10 | `lib/src/core/tema/` (cores claro/escuro, tipografia, medidas, status, tema); `PaletaSahara` virou ponte temporária com as cores novas; 102 testes (60 novos de contraste WCAG e status) |
| 2 — Componentes | ✅ 16/10 | `StatusChip`, `CardApp`, `CardDestaque`, `IconeModulo`, `TelaVazia`, `LogoApp`/`AssinaturaApp` em `lib/src/apresentacao/widgets/` (ainda sem uso nas telas); 104 testes |
| 3 — Marca (ícone, login, menu, PDF) | ✅ 16/10 · testado pelo Jan | Ícone do app (pincel sobre grafite, adaptativo e temático), tela de abertura grafite `#3A302A` (Android 12+ e anteriores), assinatura da marca no login e no menu lateral, PDFs com as cores do manual e o símbolo no cabeçalho. Corrigido o estouro da linha de links do login com fonte grande |
| 4 — Telas (lotes A–H) | ✅ 18/10 | **A · Estrutura ✅ 16/10**: menu (Usuários em 7º, por decisão do Jan), busca, data, filtros, chips, acesso restrito, avisos, Configurações; alerta do sino passou a guardar `urgente` em vez de cor. **B · Acesso ✅ 16/10**: login, recuperar senha, primeiro acesso, alterar senha e Usuários (sem `GoogleFonts` fora do tema). **C · Resumo Geral ✅ 16/10**: cabeçalho claro, indicadores com `IconeModulo`, saldo no `CardDestaque`, `StatusChip` nas obras, alertas e telas vazias com ilustração. **D · Clientes ✅ 16/10**: lista (chips compartilhados, `CardApp`, `TelaVazia` com atalho para todos os ativos) e formulário. **E · Obras ✅ 16/10**: lista, detalhes, chat, formulário e PDF da lista de materiais; cores de status unificadas pelo `status_visual` (Em Andamento azul, Concluída verde). **F · Orçamentos ✅ 16/10**: lista e formulário com `StatusChip`, seletor de status pelo `status_visual`, WhatsApp no verde do tema. **G · Financeiro ✅ 18/10**: saldo no `CardDestaque` (pendente na legenda), receitas/despesas em `success`/`error`, formulário com valor no estilo do manual. **H · Relatórios ✅ 18/10**: lucro no `CardDestaque`, gráficos nas cores do tema e paleta fixa por categoria (`core/tema/cores_graficos.dart`, aprovada pelo Jan), nome/%/valor por categoria. **Fase 4 concluída: zero valores fixos fora de `core/tema` e dos PDFs** |
| 5 — Modo escuro + Configurações | ✅ 18/10 · testado pelo Jan | `TemaController` (segue o celular por padrão, escolha salva com `shared_preferences`), seção Aparência em Configurações (Automático/Claro/Escuro), `PaletaSahara` apagada; 114 testes |
| 6 — Testes e documentação | ✅ 18/10 | README, ARCHITECTURE e histórico atualizados; plano e passo a passo em `docs/identidade_visual/`; auditoria permanente em `tool/identidade_visual/verificar.dart`; pasta do kit removida. Falta o Jan juntar a branch na `main` e tirar os prints para o TFC |

---

## 5. Ações suas pendentes

| # | Ação | Por quê |
|---|---|---|
| 1 | Tornar o repositório do GitHub privado (opcional, recomendado) | O histórico antigo ainda contém CPF e e-mail do administrador |
| 2 | Refazer a Figura 19 (DER) no relatório do TFC II | Hoje ela descreve o modelo antigo |

**Limpeza do banco concluída em 16/10:** removidas as sobras do modelo do TFC I (tabelas `etapas`, `financeiro`, `material`, `observacao` e `funcionario`, todas vazias, e a coluna `orcamento.id_etapas`), via `db/limpeza_tabelas_antigas.sql` e `db/limpeza_funcionario_e_id_etapas.sql`. O banco tem exatamente as 8 tabelas do app: `chat_leitura`, `cliente`, `equipe_obra`, `obra`, `obra_mensagem`, `orcamento`, `transacao`, `usuario`.

---

## 6. Próximos passos sugeridos (por prioridade)

1. **Ampliar os testes:** `ValidadorSenha`, repositórios com `mocktail`, controllers de Obra e de alertas.
2. **APK de release** assinado (chave fora do git).
3. ~~Documentação: README por módulo e `.env.example`~~ ✅ feito em 18/10.
4. **Melhorias opcionais:** aceitar e validar CNPJ no cliente; paginação das listas.

---

## 7. Observações de ambiente
- **Smart App Control do Windows foi desativado** para o Flutter voltar a compilar (ele bloqueava o `dartaotruntime.exe` e o `impellerc.exe`). O Defender continua ativo.
- Se o `adb` não encontrar o celular no USB, desligar a **Ancoragem USB** do Samsung e escolher "Transferência de arquivos".
- O repositório estava sem identidade do git configurada; defini **localmente** (só neste repositório) o mesmo autor dos commits anteriores.
- O código está no GitHub (`git push` feito em 16/10), junto com `HISTORICO_DO_PROJETO.md` e este relatório.