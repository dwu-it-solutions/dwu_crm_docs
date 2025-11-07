# ANEXO 06 - Frontend do Módulo de Leads
## CRM DWU - Documentação Técnica do Frontend

**Data:** 2025-01-05  
**Versão:** 1.0  
**Status:** ✅ Documentação Completa

**Objetivo**: Entregar telas básicas de Leads alinhadas ao backend (ANEXO 05), com foco em uso rápido e direto.

### Rotas
- `/leads` — Lista
- `/leads/new` — Criar
- `/leads/:id` — Detalhe
- `/leads/:id/edit` — Editar
- `/leads/import` — Importar CSV
- `/leads/:id/convert` — Converter (modal)
 - `/pipeline` — Quadro Kanban de Oportunidades
 - `/companies` — Lista de Empresas
 - `/companies/new` — Criar Empresa
 - `/companies/:id` — Detalhe da Empresa (contatos)
 - `/companies/:id/edit` — Editar Empresa
 - `/contacts/:id` — Detalhe do Contato (interações)

### Telas (o que precisa aparecer)
- Lista: busca, filtros simples (status, origem), tabela (nome, email, status, origem, sync), paginação, ações (ver/editar/converter).
- Criar/Editar: nome, email (único), telefone, empresa; opcional: tags/notas; opção “Sincronizar com Dinamize”.
- Detalhe: dados do lead, status/origem, cartão de sync (synced/pending/failed e `contact_id`), timeline simples.
- Importar: upload CSV, mapeamento leve, enviar e acompanhar status.
- Converter: modal com estágio, valor e notas.
 - Pipeline (Kanban): colunas = estágios; cartões = oportunidades com nome, valor, dono, data; drag-and-drop entre estágios; ações rápidas (ganhar/perder).
 - Tarefas (no detalhe de Lead e de Oportunidade): lista (tipo, descrição, prazo, status), criar tarefa, marcar concluída, excluir.
 - Configurações de Pipeline/Stages: gestão de pipelines (listar/criar/editar/excluir) e stages (listar/criar/editar/excluir/reordenar por drag-and-drop).
 - Empresas: lista com busca/paginação; criar/editar; detalhe com dados e listagem de contatos.
 - Contatos: dentro da empresa (lista + criar/editar/excluir) e detalhe do contato (interações).
 - Interações: no detalhe do contato (lista, criar, excluir) com tipo (email/call/meeting/task), descrição e data.

### Fluxos do usuário
- Criar lead (com sync opcional) → ver badge `pending` → após worker, vira `synced`.
- Listar e filtrar → paginação server-side.
- Editar lead → sucesso com toast → timeline registra.
- Sync automática (Dinamize→CRM) → itens novos aparecem na lista com origem Dinamize.
- Converter lead → cria oportunidade e marca `converted`.
- Importar CSV → recebe `import_id` e acompanha até concluir.

### Fluxos detalhados (alinhados ao ANEXO_05)

#### A) Criar Lead manual com sincronização Dinamize

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │
│  (React)    │    │  (API REST)   │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. Usuário       │                    │
       │    preenche form │                    │
       │    marca "Sync   │                    │
       │    Dinamize"     │                    │
       │                  │                    │
       │ 2. Validação     │                    │
       │    local (email) │                    │
       │                  │                    │
       │ 3. POST /leads   │                    │
       │    {name, email,│                    │
       │     sync: true}  │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 4. Processar       │
       │                  │    (ver ANEXO_05)  │
       │                  │───────────────────>│
       │                  │                    │
       │ 5. HTTP 201      │                    │
       │    {lead}        │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 6. Toast sucesso │                    │
       │    "Lead criado" │                    │
       │                  │                    │
       │ 7. Redirecionar  │                    │
       │    /leads/:id    │                    │
       │                  │                    │
       │ 8. Exibir badge  │                    │
       │    sync: pending │                    │
       │                  │                    │
       │ 9. Polling ou    │                    │
       │    WebSocket     │                    │
       │    atualiza badge│                    │
       │    para synced   │                    │
```

- UI: Form `Criar Lead` (opção "Sincronizar com Dinamize").
- API: POST `/leads` { name, email, ..., sync: true|false } → 201 { lead }.
- UI após salvar: toast sucesso; na lista/detalhe, badge de sync = `pending` quando `sync: true`.
- Atualização: após processamento do worker, detalhe mostra `sync_status=synced` e `contact_id`.

#### B) Buscar/Listar Leads

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │
│  (React)    │    │  (API REST)   │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. Usuário       │                    │
       │    acessa /leads │                    │
       │                  │                    │
       │ 2. Estado loading│                    │
       │    (skeleton)    │                    │
       │                  │                    │
       │ 3. GET /leads    │                    │
       │    ?page=1       │                    │
       │    &limit=20     │                    │
       │    &status=new   │                    │
       │    &q=...        │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 4. Buscar leads    │
       │                  │    com filtros     │
       │                  │───────────────────>│
       │                  │                    │
       │                  │ 5. Retornar dados │
       │                  │    {items,         │
       │                  │     pagination}    │
       │                  │<───────────────────│
       │                  │                    │
       │ 6. HTTP 200      │                    │
       │    {items,       │                    │
       │     pagination}  │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 7. Renderizar    │                    │
       │    tabela        │                    │
       │    com dados     │                    │
       │                  │                    │
       │ 8. Persistir     │                    │
       │    filtros na URL│                    │
       │    (?status=new) │                    │
```

- UI: Lista com busca e filtros (status, origem) e paginação.
- API: GET `/leads?page=1&limit=20&status=new&q=...` → { items, pagination }.
- UI: atualiza tabela; persiste filtros na URL; empty/error states com retry.

#### C) Atualizar Lead existente

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │
│  (React)    │    │  (API REST)   │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. Usuário       │                    │
       │    clica Editar  │                    │
       │    no detalhe    │                    │
       │                  │                    │
       │ 2. Abrir form    │                    │
       │    pré-preenchido│                    │
       │                  │                    │
       │ 3. Usuário       │                    │
       │    altera campos │                    │
       │                  │                    │
       │ 4. Validação     │                    │
       │    local         │                    │
       │                  │                    │
       │ 5. PATCH /leads/ │                    │
       │    :id           │                    │
       │    {campos       │                    │
       │     alterados}   │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 6. Atualizar lead  │
       │                  │───────────────────>│
       │                  │                    │
       │                  │ 7. Registrar       │
       │                  │    auditoria       │
       │                  │───────────────────>│
       │                  │                    │
       │ 8. HTTP 200      │                    │
       │    {lead}        │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 9. Toast sucesso │                    │
       │                  │                    │
       │ 10. Atualizar    │                    │
       │     timeline     │                    │
       │     (antes/depois)│                    │
```

- UI: Form `Editar Lead` no detalhe.
- API: PATCH `/leads/:id` { campos alterados } → { lead }.
- UI: toast sucesso; timeline registra antes/depois; se sincronizado anteriormente, exibir ação "Reprocessar sync" quando aplicável.

#### D) Sincronização automática (Dinamize → CRM)

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │
│  (React)    │    │  (Worker)     │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. Backend       │                    │
       │    processa sync │                    │
       │    (cron 15min)  │                    │
       │                  │───────────────────>│
       │                  │                    │
       │ 2. Novos leads   │                    │
       │    criados com   │                    │
       │    origin=Dinamize│                    │
       │                  │                    │
       │ 3. Frontend      │                    │
       │    polling ou    │                    │
       │    WebSocket     │                    │
       │    detecta novos │                    │
       │                  │                    │
       │ 4. GET /leads    │                    │
       │    ?origin=      │                    │
       │    Dinamize      │                    │
       │    &since=...    │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 5. Retornar novos  │
       │                  │───────────────────>│
       │                  │                    │
       │ 6. Atualizar     │                    │
       │    lista com     │                    │
       │    novos itens   │                    │
       │    (badge origin)│                    │
```

- UI: Lista/Detalhe podem usar refresh manual ou polling curto opcional.
- API (backend executa via worker): novos/alterados chegam como origem Dinamize.
- UI: itens aparecem com `origin=Dinamize`; badges refletem último `sync_status`.

#### E) Converter Lead em Oportunidade

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │
│  (React)    │    │  (API REST)   │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. Usuário       │                    │
       │    clica         │                    │
       │    "Converter"   │                    │
       │                  │                    │
       │ 2. Abrir modal   │                    │
       │    de conversão  │                    │
       │                  │                    │
       │ 3. Usuário       │                    │
       │    seleciona     │                    │
       │    stage, valor  │                    │
       │                  │                    │
       │ 4. Validação     │                    │
       │    local         │                    │
       │                  │                    │
       │ 5. POST /leads/  │                    │
       │    :id/convert   │                    │
       │    {stage_id,    │                    │
       │     value, ...}  │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 6. Criar           │
       │                  │    oportunidade    │
       │                  │───────────────────>│
       │                  │                    │
       │                  │ 7. Atualizar lead  │
       │                  │    (converted)     │
       │                  │───────────────────>│
       │                  │                    │
       │ 8. HTTP 200      │                    │
       │    {lead,        │                    │
       │     opportunity} │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 9. Toast sucesso │                    │
       │                  │                    │
       │ 10. Fechar modal │                    │
       │                  │                    │
       │ 11. Atualizar    │                    │
       │     detalhe com  │                    │
       │     status=       │                    │
       │     converted    │                    │
       │     e link opp   │                    │
```

- UI: Modal `Converter` no detalhe do lead.
- API: POST `/leads/:id/convert` { stage_id, value, ... } → { lead, opportunity }.
- UI: toast sucesso; detalhe marca `status=converted` e mostra link da oportunidade.

#### F) Importação de Leads via CSV

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │    │    Redis    │
│  (React)    │    │  (API REST)   │    │             │    │  (BullMQ)   │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                    │                  │
       │ 1. Usuário       │                    │                  │
       │    faz upload    │                    │                  │
       │    arquivo CSV   │                    │                  │
       │                  │                    │                  │
       │ 2. Preview       │                    │                  │
       │    primeiras     │                    │                  │
       │    linhas        │                    │                  │
       │                  │                    │                  │
       │ 3. Mapeamento    │                    │                  │
       │    de colunas    │                    │                  │
       │                  │                    │                  │
       │ 4. POST /leads/  │                    │                  │
       │    import        │                    │                  │
       │    (multipart)   │                    │                  │
       │─────────────────>│                    │                  │
       │                  │                    │                  │
       │                  │ 5. Validar CSV     │                  │
       │                  │    e criar job     │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 6. Adicionar job   │                  │
       │                  │    à fila          │                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │ 7. HTTP 202      │                    │                  │
       │    {import_id}   │                    │                  │
       │<─────────────────│                    │                  │
       │                  │                    │                  │
       │ 8. Exibir        │                    │                  │
       │    progresso     │                    │                  │
       │    (polling)     │                    │                  │
       │                  │                    │                  │
       │ 9. GET /leads/   │                    │                  │
       │    import/:id    │                    │                  │
       │─────────────────>│                    │                  │
       │                  │                    │                  │
       │                  │ 10. Retornar       │                  │
       │                  │     status         │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │ 11. HTTP 200     │                    │                  │
       │     {status,     │                    │                  │
       │      progress}   │                    │                  │
       │<─────────────────│                    │                  │
       │                  │                    │                  │
       │ 12. Quando       │                    │                  │
       │     completed:   │                    │                  │
       │     exibir       │                    │                  │
       │     resumo       │                    │                  │
       │     (criados/    │                    │                  │
       │     atualizados/ │                    │                  │
       │     erros)       │                    │                  │
```

- UI: Tela `Importar CSV` (upload → mapeamento → enviar → acompanhamento).
- API: POST `/leads/import` (multipart) → 202 { import_id }.
- UI: acompanha via GET `/leads/import/:import_id` até `completed`; exibe resumo (criados/atualizados/erros) e link de erros quando houver.

#### G) Pipeline (Kanban) — listar e mover oportunidades

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │
│  (React)    │    │  (API REST)   │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. Usuário       │                    │
       │    acessa        │                    │
       │    /pipeline     │                    │
       │                  │                    │
       │ 2. GET /pipeline │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 3. Buscar stages   │
       │                  │    e opportunities │
       │                  │───────────────────>│
       │                  │                    │
       │                  │ 4. Retornar board  │
       │                  │    {stages,        │
       │                  │     opportunities} │
       │                  │<───────────────────│
       │                  │                    │
       │ 5. HTTP 200      │                    │
       │    {stages,      │                    │
       │     opportunities}│                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 6. Renderizar    │                    │
       │    Kanban board  │                    │
       │                  │                    │
       │ 7. Usuário       │                    │
       │    arrasta card  │                    │
       │    para outro    │                    │
       │    stage         │                    │
       │                  │                    │
       │ 8. Update        │                    │
       │    otimista      │                    │
       │    (UI primeiro) │                    │
       │                  │                    │
       │ 9. PATCH /oppor- │                    │
       │    tunities/:id/ │                    │
       │    move          │                    │
       │    {to_stage_id, │                    │
       │     position}    │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 10. Validar e      │
       │                  │     atualizar      │
       │                  │───────────────────>│
       │                  │                    │
       │ 11. HTTP 200     │                    │
       │     {opportunity}│                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 12. Se erro:     │                    │
       │     rollback UI  │                    │
       │     e exibir msg │                    │
```

- UI: Rota `/pipeline` carrega colunas e cartões.
- API: GET `/pipeline` → { stages, opportunities por stage }.
- UI: ao arrastar cartão para outra coluna, envia PATCH `/opportunities/:id/move` { to_stage_id, position }.
- UI: trata validações (mensagem se transição não permitida/WIP cheio); em sucesso, atualiza board localmente.

#### H) Ganhar/Perder oportunidade

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │
│  (React)    │    │  (API REST)   │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. Usuário       │                    │
       │    clica "Ganhar"│                    │
       │    ou "Perder"   │                    │
       │                  │                    │
       │ 2. Modal de      │                    │
       │    confirmação   │                    │
       │    (se perder)   │                    │
       │                  │                    │
       │ 3. POST /opportu-│                    │
       │    nities/:id/   │                    │
       │    win ou /loss  │                    │
       │    {value/reason}│                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 4. Atualizar       │
       │                  │    oportunidade    │
       │                  │    (status)        │
       │                  │───────────────────>│
       │                  │                    │
       │                  │ 5. Registrar       │
       │                  │    auditoria       │
       │                  │───────────────────>│
       │                  │                    │
       │ 6. HTTP 200      │                    │
       │    {opportunity} │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 7. Toast sucesso │                    │
       │                  │                    │
       │ 8. Remover card  │                    │
       │    do board ou   │                    │
       │    mover para    │                    │
       │    "Fechadas"    │                    │
```

- UI: Ação no cartão ou no detalhe da oportunidade.
- API: POST `/opportunities/:id/win` { value, ... } → { opportunity }.
- API: POST `/opportunities/:id/loss` { reason } → { opportunity }.
- UI: mostra toast e remove o cartão do fluxo aberto (ou move para coluna "Fechadas").

#### I) Tarefas (Tasks) no detalhe de Lead/Oportunidade

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │
│  (React)    │    │  (API REST)   │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. Usuário       │                    │
       │    abre aba      │                    │
       │    "Tarefas"     │                    │
       │                  │                    │
       │ 2. GET /tasks    │                    │
       │    ?related_type=│                    │
       │    lead&related_ │                    │
       │    id=:id        │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 3. Buscar tarefas  │
       │                  │───────────────────>│
       │                  │                    │
       │                  │ 4. Retornar lista  │
       │                  │<───────────────────│
       │                  │                    │
       │ 5. HTTP 200      │                    │
       │    {items}       │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 6. Renderizar    │                    │
       │    lista         │                    │
       │    ordenada por  │                    │
       │    due_date      │                    │
       │                  │                    │
       │ 7. Usuário cria  │                    │
       │    nova tarefa   │                    │
       │                  │                    │
       │ 8. POST /tasks   │                    │
       │    {related_type,│                    │
       │     related_id,  │                    │
       │     type, desc,  │                    │
       │     due_date}    │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 9. Criar tarefa    │
       │                  │───────────────────>│
       │                  │                    │
       │ 10. HTTP 201     │                    │
       │     {task}        │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 11. Adicionar à  │                    │
       │     lista        │                    │
```

- UI: Seção/aba "Tarefas" dentro do detalhe.
- API:
  - GET `/tasks?related_type=lead|opportunity&related_id=:id` → `{ items }`
  - POST `/tasks` { related_type, related_id, type, description, due_date } → `201 { task }`
  - PATCH `/tasks/:id` { completed } → `{ task }`
  - DELETE `/tasks/:id` → `204`
- UX: lista com loading/empty/error; toasts; confirmação ao excluir; ordenar por `due_date`.

#### J) Gestão de Pipelines

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │
│  (React)    │    │  (API REST)   │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. Usuário       │                    │
       │    acessa        │                    │
       │    configurações │                    │
       │                  │                    │
       │ 2. GET /pipelines│                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 3. Buscar pipelines│
       │                  │───────────────────>│
       │                  │                    │
       │                  │ 4. Retornar lista  │
       │                  │<───────────────────│
       │                  │                    │
       │ 5. HTTP 200      │                    │
       │    {items}       │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 6. Renderizar    │                    │
       │    tabela        │                    │
       │                  │                    │
       │ 7. Usuário cria  │                    │
       │    novo pipeline │                    │
       │                  │                    │
       │ 8. POST /pipelines│                    │
       │    {name}        │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 9. Criar pipeline  │
       │                  │───────────────────>│
       │                  │                    │
       │ 10. HTTP 201     │                    │
       │     {pipeline}    │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 11. Adicionar à  │                    │
       │     tabela        │                    │
```

- UI: Página de configurações com tabela de pipelines (nome, criado em, ações editar/excluir) e botão "Novo Pipeline".
- API:
  - GET `/pipelines` → `{ items }`
  - POST `/pipelines` { name } → `201 { pipeline }`
  - PUT `/pipelines/:id` { name } → `{ pipeline }`
  - DELETE `/pipelines/:id` → `204` (bloquear se possuir stages/opps, ou exigir confirmação forte)

#### K) Gestão de Stages por Pipeline

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │
│  (React)    │    │  (API REST)   │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. Usuário       │                    │
       │    seleciona    │                    │
       │    pipeline      │                    │
       │                  │                    │
       │ 2. GET /pipelines│                    │
       │    /:id/stages   │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 3. Buscar stages   │
       │                  │───────────────────>│
       │                  │                    │
       │                  │ 4. Retornar lista  │
       │                  │<───────────────────│
       │                  │                    │
       │ 5. HTTP 200      │                    │
       │    {items}       │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 6. Renderizar    │                    │
       │    lista         │                    │
       │    ordenável     │                    │
       │                  │                    │
       │ 7. Usuário       │                    │
       │    arrasta para  │                    │
       │    reordenar     │                    │
       │                  │                    │
       │ 8. Update        │                    │
       │    otimista      │                    │
       │                  │                    │
       │ 9. PATCH /stages │                    │
       │    /reorder      │                    │
       │    {pipeline_id, │                    │
       │     order: [...]}│                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 10. Atualizar      │
       │                  │     posições       │
       │                  │───────────────────>│
       │                  │                    │
       │ 11. HTTP 200     │                    │
       │     {items}      │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 12. Se erro:     │                    │
       │     rollback UI  │                    │
```

- UI: Dentro do pipeline selecionado: lista de stages ordenáveis (drag), ações criar/editar/excluir.
- API:
  - GET `/pipelines/:id/stages` → `{ items }`
  - POST `/pipelines/:id/stages` { name } → `201 { stage }`
  - PUT `/stages/:id` { name } → `{ stage }`
  - PATCH `/stages/reorder` { pipeline_id, order: [stageIds] } → `{ items }`
  - DELETE `/stages/:id` → `204` (bloquear se houver oportunidades sem destino)
- UX: reorder otimista com rollback se falhar; confirmação ao excluir; validação de nome vazio.

#### L) Empresas — lista, criar/editar, excluir

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │
│  (React)    │    │  (API REST)   │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. Usuário       │                    │
       │    acessa        │                    │
       │    /companies    │                    │
       │                  │                    │
       │ 2. GET /companies│                    │
       │    ?q=&page=     │                    │
       │    &limit=       │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 3. Buscar empresas │
       │                  │    com filtros       │
       │                  │───────────────────>│
       │                  │                    │
       │                  │ 4. Retornar dados  │
       │                  │    {items,         │
       │                  │     pagination}    │
       │                  │<───────────────────│
       │                  │                    │
       │ 5. HTTP 200      │                    │
       │    {items,       │                    │
       │     pagination}  │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 6. Renderizar    │                    │
       │    tabela        │                    │
       │                  │                    │
       │ 7. Usuário cria  │                    │
       │    nova empresa  │                    │
       │                  │                    │
       │ 8. POST /companies│                    │
       │    {name, cnpj,  │                    │
       │     website, ...}│                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 9. Criar empresa   │
       │                  │───────────────────>│
       │                  │                    │
       │ 10. HTTP 201     │                    │
       │     {company}     │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 11. Toast sucesso │                    │
       │     e atualizar   │                    │
       │     lista        │                    │
```

- UI: `/companies` com busca por nome/CNPJ; tabela paginada; ações criar, editar, excluir (com confirmação).
- API:
  - GET `/companies?q=&page=&limit=` → `{ items, pagination }`
  - POST `/companies` { name, cnpj, website, ... } → `201 { company }`
  - PUT `/companies/:id` { ... } → `{ company }`
  - DELETE `/companies/:id` → `204` (bloqueia se tiver contatos/oportunidades)
- UX: toasts; validação de campos obrigatórios; mensagens claras em bloqueios.

#### M) Contatos por Empresa — lista e CRUD

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │
│  (React)    │    │  (API REST)   │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. Usuário       │                    │
       │    abre aba      │                    │
       │    "Contatos"    │                    │
       │    na empresa    │                    │
       │                  │                    │
       │ 2. GET /companies│                    │
       │    /:id/contacts │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 3. Buscar contatos │
       │                  │───────────────────>│
       │                  │                    │
       │                  │ 4. Retornar lista  │
       │                  │<───────────────────│
       │                  │                    │
       │ 5. HTTP 200      │                    │
       │    {items}       │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 6. Renderizar    │                    │
       │    lista         │                    │
       │                  │                    │
       │ 7. Usuário cria  │                    │
       │    novo contato  │                    │
       │                  │                    │
       │ 8. POST /contacts│                    │
       │    {company_id,  │                    │
       │     name, email, │                    │
       │     phone, ...}  │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 9. Criar contato   │
       │                  │───────────────────>│
       │                  │                    │
       │ 10. HTTP 201     │                    │
       │     {contact}     │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 11. Adicionar à  │                    │
       │     lista        │                    │
```

- UI: dentro do detalhe da empresa, aba "Contatos": lista com nome/email/telefone/cargo; criar/editar/excluir contato.
- API:
  - GET `/companies/:id/contacts` → `{ items }`
  - POST `/contacts` { company_id, name, email, phone, position, notes } → `201 { contact }`
  - PUT `/contacts/:id` { ... } → `{ contact }`
  - DELETE `/contacts/:id` → `204`
- UX: toasts; confirmação ao excluir; validação de email.

#### N) Interações no Contato — registrar atividades

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │ PostgreSQL  │
│  (React)    │    │  (API REST)   │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. Usuário       │                    │
       │    acessa        │                    │
       │    detalhe do    │                    │
       │    contato       │                    │
       │                  │                    │
       │ 2. GET /contacts │                    │
       │    /:id/         │                    │
       │    interactions  │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 3. Buscar          │
       │                  │    interações      │
       │                  │───────────────────>│
       │                  │                    │
       │                  │ 4. Retornar lista  │
       │                  │    ordenada por    │
       │                  │    data            │
       │                  │<───────────────────│
       │                  │                    │
       │ 5. HTTP 200      │                    │
       │    {items}       │                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 6. Renderizar    │                    │
       │    timeline de   │                    │
       │    interações    │                    │
       │                  │                    │
       │ 7. Usuário cria  │                    │
       │    nova interação │                    │
       │                  │                    │
       │ 8. POST /contacts│                    │
       │    /:id/         │                    │
       │    interactions  │                    │
       │    {type, desc,  │                    │
       │     occurred_at} │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 9. Criar interação │
       │                  │───────────────────>│
       │                  │                    │
       │ 10. HTTP 201     │                    │
       │     {interaction}│                    │
       │<─────────────────│                    │
       │                  │                    │
       │ 11. Adicionar à  │                    │
       │     timeline     │                    │
```

- UI: no detalhe do contato, seção "Interações": lista com tipo, descricao e data; criar e excluir.
- API:
  - GET `/contacts/:id/interactions` → `{ items }`
  - POST `/contacts/:id/interactions` { type, description, occurred_at } → `201 { interaction }`
  - DELETE `/interactions/:id` → `204`
- UX: estados loading/empty/error; ordenação por data; toasts.

### Componentes principais
- Tabela de Leads, Filtros, Form de Lead, Badge de Sync, Timeline, Wizard de Importação, Modal de Conversão.

### Critérios de aceite (essenciais)
- Criar: aparece na lista com `pending`; após sync, `synced` visível no detalhe.
- Lista: filtros funcionam e persistem na URL; paginação server-side.
- Editar: atualiza e registra na timeline.
- Converter: cria oportunidade e mostra link no detalhe.
- Importar: mostra progresso por `import_id` e resumo final.
