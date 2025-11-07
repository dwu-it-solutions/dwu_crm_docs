# ANEXO 05 - Backend do Módulo de Leads
## CRM DWU - Documentação Técnica do Backend

**Data:** 2025-01-05  
**Versão:** 1.0  
**Status:** ✅ Documentação Completa

## 1. Visão Geral do Módulo

### 1.1 Objetivo

O módulo de leads é responsável por:
- Gerenciar o ciclo de vida completo de leads (CRUD)
- Sincronizar leads com a API Dinamize
- Capturar leads de múltiplas origens (Dinamize, Manual, CSV)
- Converter leads em oportunidades
- Rastrear status e interações dos leads

### 1.2 Entidades Principais

**Tabela: `crm_leads`**
- Armazena informações principais dos leads
- Suporta múltiplas origens (Dinamize, Manual, CSV)
- Campos JSONB para dados extras da Dinamize

**Tabela: `crm_lead_sync`**
- Rastreia sincronização entre leads locais e Dinamize
- Mantém relacionamento com contatos Dinamize
- Controla status de sincronização

**Tabela: `crm_sync_queue`**
- Fila de operações assíncronas de sincronização
- Suporta retry automático
- Processamento em background

### 1.3 Fluxo de Dados - Cenários Completos

#### 1.3.1 Cenário A: Criar Lead Manual com Sincronização Dinamize

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend    │    │ PostgreSQL  │    │    Redis    │    │  Dinamize   │
│             │    │  (API REST)  │    │             │    │  (BullMQ)   │    │     API     │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                    │                  │                  │
       │ 1. POST /leads   │                    │                  │                  │
       │ {email, name,    │                    │                  │                  │
       │  sync: true}     │                    │                  │                  │
       │─────────────────>│                    │                  │                  │
       │                  │                    │                  │                  │
       │                  │ 2. Validar dados   │                  │                  │
       │                  │    (email único?)  │                  │                  │
       │                  │                    │                  │                  │
       │                  │ 3. INSERT INTO     │                  │                  │
       │                  │    crm_leads       │                  │                  │
       │                  │───────────────────>│                  │                  │
       │                  │                    │                  │                  │
       │                  │ 4. INSERT INTO     │                  │                  │
       │                  │    crm_lead_sync   │                  │                  │
       │                  │    (status:        │                  │                  │
       │                  │     pending)       │                  │                  │
       │                  │───────────────────>│                  │                  │
       │                  │                    │                  │                  │
       │                  │ 5. INSERT INTO     │                  │                  │
       │                  │    crm_sync_queue  │                  │                  │
       │                  │    (status: queued)│                  │                  │
       │                  │───────────────────>│                  │                  │
       │                  │                    │                  │                  │
       │                  │ 6. Adicionar job   │                  │                  │
       │                  │    ao BullMQ       │                  │                  │
       │                  │──────────────────────────────────────>│                  │
       │                  │                    │                  │                  │
       │                  │ 7. Registrar em    │                  │                  │
       │                  │    crm_audit_log   │                  │                  │
       │                  │───────────────────>│                  │                  │
       │                  │                    │                  │                  │
       │ 8. HTTP 201      │                    │                  │                  │
       │    {lead data}   │                    │                  │                  │
       │<─────────────────│                    │                  │                  │
       │                  │                    │                  │                  │
       │                  │                    │                  │ 9. Worker pega   │
       │                  │                    │                  │    job da fila   │
       │                  │                    │                  │<─────────────────│
       │                  │                    │                  │                  │
       │                  │                    │ 10. UPDATE       │                  │
       │                  │                    │     crm_sync_    │                  │
       │                  │                    │     queue        │                  │
       │                  │                    │     (processing) │                  │
       │                  │                    │<─────────────────│                  │
       │                  │                    │                  │                  │
       │                  │ 11. Obter token    │                  │                  │
       │                  │     válido         │                  │                  │
       │                  │────────────────────────────────────────────────────────> │
       │                  │                    │                  │                  │
       │                  │ 12. POST /emkt/    │                  │                  │
       │                  │     contact/add    │                  │                  │
       │                  │────────────────────────────────────────────────────────> │
       │                  │                    │                  │                  │
       │                  │ 13. Resposta OK    │                  │                  │
       │                  │     {contact_id}   │                  │                  │
       │                  │<──────────────────────────────────────────────────────── │
       │                  │                    │                  │                  │
       │                  │                    │ 14. UPDATE       │                  │
       │                  │                    │     crm_lead_    │                  │
       │                  │                    │     sync         │                  │
       │                  │                    │     (synced)     │                  │
       │                  │                    │<─────────────────│                  │
       │                  │                    │                  │                  │
       │                  │                    │ 15. UPDATE       │                  │
       │                  │                    │     crm_sync_    │                  │
       │                  │                    │     queue        │                  │
       │                  │                    │     (completed)  │                  │
       │                  │                    │<─────────────────│                  │
       │                  │                    │                  │                  │
       │                  │                    │ 16. INSERT INTO  │                  │
       │                  │                    │     crm_sync_    │                  │
       │                  │                    │     logs         │                  │
       │                  │                    │     (sucesso)    │                  │
       │                  │                    │<─────────────────│                  │
```

#### 1.3.2 Cenário B: Buscar/Listar Leads

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend    │    │ PostgreSQL  │
│             │    │  (API REST)  │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. GET /leads    │                    │
       │ ?page=1&limit=20 │                    │
       │ &status=new      │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 2. Validar filtros │
       │                  │    e paginação     │
       │                  │                    │
       │                  │ 3. SELECT FROM     │
       │                  │    crm_leads       │
       │                  │    WHERE ...       │
       │                  │    JOIN crm_lead_  │
       │                  │    sync            │
       │                  │    ORDER BY ...    │
       │                  │    LIMIT 20        │
       │                  │───────────────────>│
       │                  │                    │
       │                  │ 4. COUNT(*) para   │
       │                  │    paginação       │
       │                  │───────────────────>│
       │                  │                    │
       │                  │ 5. Dados retornados│
       │                  │<───────────────────│
       │                  │                    │
       │ 6. HTTP 200      │                    │
       │    {items,       │                    │
       │     pagination}  │                    │
       │<─────────────────│                    │
```

#### 1.3.3 Cenário C: Atualizar Lead Existente

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend    │    │ PostgreSQL  │    │    Redis    │
│             │    │  (API REST)  │    │             │    │  (BullMQ)   │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                    │                  │
       │ 1. PATCH /leads/1│                    │                  │
       │    {name: "Novo" │                    │                  │
       │     status: "con-│                    │                  │
       │     tacted"}     │                    │                  │
       │─────────────────>│                    │                  │
       │                  │                    │                  │
       │                  │ 2. Validar dados   │                  │
       │                  │    e permissões    │                  │
       │                  │                    │                  │
       │                  │ 3. SELECT lead     │                  │
       │                  │    atual           │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 4. UPDATE          │                  │
       │                  │    crm_leads       │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 5. Verificar se    │                  │
       │                  │    tem sync        │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 6. Se tem sync:    │                  │
       │                  │    Adicionar job   │                  │
       │                  │    de UPDATE       │                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │                  │ 7. Registrar em    │                  │
       │                  │    crm_audit_log   │                  │
       │                  │    (antes/depois)  │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │ 8. HTTP 200      │                    │                  │
       │    {lead atualiz-│                    │                  │
       │     ado}         │                    │                  │
       │<─────────────────│                    │                  │
       │                  │                    │                  │
       │                  │                    │                  │ Worker processa │
       │                  │                    │                  │ job de UPDATE  │
       │                  │                    │                  │ (similar ao     │
       │                  │                    │                  │ cenário A)      │
```

#### 1.3.4 Cenário D: Sincronização da Dinamize para CRM (Automática)

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│   Cron Job  │    │   Backend    │    │ PostgreSQL  │    │  Dinamize   │
│  (Scheduler)│    │ (Sync Worker)│    │             │    │     API     │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                    │                  │
       │ 1. Trigger a cada│                    │                  │
       │    15 minutos    │                    │                  │
       │─────────────────>│                    │                  │
       │                  │                    │                  │
       │                  │ 2. Buscar última   │                  │
       │                  │    sincronização   │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 3. Obter token     │                  │
       │                  │    válido          │                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │                  │ 4. POST /emkt/     │                  │
       │                  │    contact/search  │                  │
       │                  │    {insert_date >= │                  │
       │                  │     last_sync}     │                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │                  │ 5. Lista de        │                  │
       │                  │    contatos novos  │                  │
       │                  │<──────────────────────────────────────│
       │                  │                    │                  │
       │                  │ 6. Para cada       │                  │
       │                  │    contato:        │                  │
       │                  │                    │                  │
       │                  │ 6.1 Verificar se   │                  │
       │                  │      já existe     │                  │
       │                  │      (por email)   │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 6.2 Se não existe: │                  │
       │                  │      INSERT INTO   │                  │
       │                  │      crm_leads     │                  │
       │                  │      (origin:      │                  │
       │                  │       Dinamize)    │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 6.3 Se existe:     │                  │
       │                  │      UPDATE        │                  │
       │                  │      crm_leads     │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 6.4 Criar/atualizar│                 │
       │                  │      crm_lead_sync │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 7. Atualizar       │                  │
       │                  │    last_successful │                  │
       │                  │    _sync           │                  │
       │                  │───────────────────>│                  │
```

#### 1.3.5 Cenário E: Converter Lead em Oportunidade

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend    │    │ PostgreSQL  │
│             │    │  (API REST)  │    │             │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘
       │                  │                    │
       │ 1. POST /leads/1 │                    │
       │    /convert      │                    │
       │    {stage_id,    │                    │
       │     value, ...}  │                    │
       │─────────────────>│                    │
       │                  │                    │
       │                  │ 2. Validar lead    │                  │
       │                  │    existe e não    │                  │
       │                  │    convertido      │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 3. Validar stage   │                  │
       │                  │    existe e ativo  │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 4. BEGIN TRANSACTION                  │
       │                  │                    │                  │
       │                  │ 5. INSERT INTO     │                  │
       │                  │    crm_opportunities                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 6. UPDATE          │                  │
       │                  │    crm_leads       │                  │
       │                  │    (status:        │                  │
       │                  │     converted,     │                  │
       │                  │     converted_at,  │                  │
       │                  │     converted_to_  │                  │
       │                  │     opportunity_id)│                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 7. COMMIT          │                  │
       │                  │                    │                  │
       │                  │ 8. Registrar em    │                  │
       │                  │    crm_audit_log   │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │ 9. HTTP 200      │                    │                  │
       │    {lead,        │                    │                  │
       │     opportunity} │                    │                  │
       │<─────────────────│                    │                  │
```

#### 1.3.6 Cenário F: Importação de Leads via CSV

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend    │    │ PostgreSQL  │    │    Redis    │
│             │    │  (API REST)  │    │             │    │  (BullMQ)   │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                    │                  │
       │ 1. POST /leads/  │                    │                  │
       │    import        │                    │                  │
       │    (multipart)   │                    │                  │
       │─────────────────>│                    │                  │
       │                  │                    │                  │
       │                  │ 2. Validar arquivo │                  │
       │                  │    CSV             │                  │
       │                  │                    │                  │
       │                  │ 3. Criar registro  │                  │
       │                  │    de importação   │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 4. Adicionar job   │                  │
       │                  │    de processamento│                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │ 5. HTTP 202      │                    │                  │
       │    {import_id,   │                    │                  │
       │     status:      │                    │                  │
       │     processing}  │                    │                  │
       │<─────────────────│                    │                  │
       │                  │                    │                  │
       │                  │                    │                  │ Worker processa │
       │                  │                    │                  │ CSV linha por   │
       │                  │                    │                  │ linha:          │
       │                  │                    │                  │                  │
       │                  │ 6. Para cada linha:│                  │                  │
       │                  │    6.1 Validar     │                  │                  │
       │                  │        dados       │                  │                  │
       │                  │                    │                  │                  │
       │                  │    6.2 Verificar   │                  │                  │
       │                  │        email único │                  │                  │
       │                  │───────────────────>│                  │                  │
       │                  │                    │                  │                  │
       │                  │    6.3 Criar ou    │                  │                  │
       │                  │        atualizar   │                  │                  │
       │                  │        lead        │                  │                  │
       │                  │───────────────────>│                  │                  │
       │                  │                    │                  │                  │
       │                  │    6.4 Se sync:    │                  │                  │
       │                  │        adicionar   │                  │                  │
       │                  │        à fila      │                  │                  │
       │                  │──────────────────────────────────────>│                  │
       │                  │                    │                  │                  │
       │                  │ 7. Atualizar status│                  │                  │
       │                  │    de importação   │                  │                  │
       │                  │    (completed)     │                  │                  │
       │                  │───────────────────>│                  │                  │
```

#### 1.3.7 Tratamento de Erros e Retry

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│    Redis    │    │   Backend    │    │ PostgreSQL  │    │  Dinamize   │
│  (BullMQ)   │    │  (Worker)    │    │             │    │     API     │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                    │                  │
       │ 1. Job na fila   │                    │                  │
       │─────────────────>│                    │                  │
       │                  │                    │                  │
       │                  │ 2. Tentar sync     │                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │                  │ 3. Erro: Rate Limit│                  │
       │                  │    (code: 240024)  │                  │
       │                  │    {retry-after: 17│                  │
       │                  │     segundos}      │                  │
       │                  │<──────────────────────────────────────│
       │                  │                    │                  │
       │                  │ 4. Registrar erro  │                  │
       │                  │    em crm_sync_logs│                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 5. Atualizar       │                  │
       │                  │    crm_sync_queue  │                  │
       │                  │    (failed,        │                  │
       │                  │     attempt_count) │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 6. Aguardar        │                  │
       │                  │    retry-after     │                  │
       │                  │    (17 segundos)   │                  │
       │                  │                    │                  │
       │ 7. Retry automático│                  │                  │
       │    (backoff)     │                    │                  │
       │──────────────────>│                   │                  │
       │                  │                    │                  │
       │                  │ 8. Nova tentativa  │                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │                  │ 9. Sucesso!        │                  │
       │                  │<──────────────────────────────────────│
       │                  │                    │                  │
       │                  │ 10. Atualizar      │                  │
       │                  │     status (completed)                │
       │                  │───────────────────>│                  │
```