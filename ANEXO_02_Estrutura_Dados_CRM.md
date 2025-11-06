# ANEXO 02 - Definição da Estrutura de Dados
## CRM DWU - Estrutura de Dados (Lead, Contato, Empresa, Oportunidade)

**Data:** 2025-11-05  
**Versão:** 1.1  
**Status:** ✅ Estrutura Definida e Otimizada

---

## 📋 Sumário Executivo

Este anexo apresenta a estrutura completa de dados do CRM DWU, incluindo:
- **Convenções de nomenclatura** (Seção 0) - Justificativa técnica para padrão `crm_*` (tabelas) e `dwu_*` (colunas)
- **Entidades principais** (Lead, Contato, Empresa, Oportunidade)
- **Tabelas de integração** (sincronização, filas, logs, auditoria)
- **Relacionamentos** e mapeamento com API Dinamize
- **Decisões técnicas** (SERIAL vs BIGSERIAL, padronização de FKs)

---

## 0. Convenções de Nomenclatura

### 0.1 Decisão: Prefixo de Tabelas (crm_) vs Prefixo de Colunas (dwu_)

**Padrão Adotado:**
- **Tabelas:** Prefixo `crm_` (indica domínio funcional)
- **Colunas:** Prefixo `dwu_` (indica proprietário/sistema)
- **Foreign Keys:** Prefixo `dwu_[entidade]_id` (entidade + proprietário)

**Exemplo:**
```sql
CREATE TABLE crm_leads (           -- crm_ = domínio CRM
  dwu_id SERIAL PRIMARY KEY,       -- dwu_ = proprietário DWU
  dwu_name VARCHAR(150),            -- dwu_ = proprietário DWU
  dwu_company_id INTEGER            -- dwu_ + entidade = FK clara
);
```

---

### 0.2 Justificativa Técnica

#### **Por que `crm_*` para tabelas (não `dwu_*`):**

**1. Separação por Domínio Funcional**

DWU terá **múltiplos domínios** além do CRM:

```sql
-- ✅ Padrão adotado: Domínios claros
crm_leads              -- Domínio: Customer Relationship Management
crm_opportunities      -- Domínio: CRM
crm_companies          -- Domínio: CRM

finance_invoices       -- Domínio: Financeiro (futuro)
finance_payments       -- Domínio: Financeiro (futuro)

hr_employees           -- Domínio: Recursos Humanos (futuro)
hr_departments         -- Domínio: RH (futuro)

erp_products           -- Domínio: ERP (futuro - Mês 3+)
erp_inventory          -- Domínio: ERP (futuro)

-- ❌ Alternativa descartada: Tudo genérico
dwu_leads              -- DWU de qual domínio? CRM? ERP? Não fica claro
dwu_opportunities      -- Idem
dwu_invoices           -- Invoice é Finance ou CRM? Confuso
dwu_employees          -- Confuso com outros módulos
dwu_products           -- De qual sistema?
```

**2. Clareza Semântica**

```sql
-- Query cross-domain
SELECT 
  l.dwu_name,                    -- Lead do CRM
  i.dwu_value,                   -- Invoice do Finance
  e.dwu_department               -- Employee do HR
FROM crm_leads l                 -- ← Óbvio: domínio CRM
JOIN finance_invoices i          -- ← Óbvio: domínio Finance
  ON i.dwu_customer_email = l.dwu_email
JOIN hr_employees e              -- ← Óbvio: domínio HR
  ON e.dwu_id = l.dwu_assigned_to;

-- ✅ Desenvolvedor novo identifica domínios imediatamente
-- ✅ Prefixo documenta a função da tabela
```

**3. Padrão da Indústria**

Grandes sistemas enterprise usam **prefixo = domínio/módulo**:

| Sistema | Padrão | Exemplos |
|---------|--------|----------|
| **Oracle E-Business Suite** | Módulo | `AR_*` (Accounts Receivable), `AP_*` (Payables), `GL_*` (General Ledger) |
| **SAP** | Área funcional | `VBAK` (Sales), `KNA1` (Customers), `MARA` (Material) |
| **Microsoft Dynamics** | Entidade | `Account`, `Contact` (sem prefixo, usa schema) |
| **Salesforce** | Sem prefixo | `Account`, `Contact`, `Lead` |
| **PostgreSQL Community** | Schema ou prefixo funcional | `crm.leads` ou `crm_leads` |

**Consenso:** Prefixo indica **área funcional**, não nome da empresa.

**4. Escalabilidade e Manutenibilidade**

```sql
-- Cenário futuro: Integração entre domínios
-- ✅ Com crm_*: Claro quais domínios estão envolvidos
SELECT 
  COUNT(DISTINCT c.dwu_id) as total_clientes,
  SUM(i.dwu_value) as receita_total
FROM crm_companies c           -- CRM: Cadastro de clientes
JOIN finance_invoices i        -- Finance: Faturamento
  ON i.dwu_company_id = c.dwu_id
WHERE c.dwu_segment = 'Varejo';

-- Desenvolvedor olha query e entende:
-- "Buscando empresas do CRM e cruzando com invoices do Finance"

-- ⚠️ Com dwu_*: Menos claro
SELECT 
  COUNT(DISTINCT c.dwu_id),
  SUM(i.dwu_value)
FROM dwu_companies c           -- Qual domínio? Precisa verificar
JOIN dwu_invoices i            -- Qual domínio? Precisa verificar
  ON i.dwu_company_id = c.dwu_id;

-- Desenvolvedor precisa consultar documentação ou código
```

**5. Namespace Lógico**

```sql
-- Alternativa seria PostgreSQL Schemas
crm.leads                      -- Schema CRM
finance.invoices               -- Schema Finance

-- Mas prefixo é mais simples:
crm_leads                      -- Mais direto
finance_invoices               -- Funciona em qualquer DB
```

---

#### **Por que `dwu_*` para colunas:**

**1. Identifica Propriedade/Sistema**

```sql
-- dwu_ indica que a coluna pertence ao sistema DWU
dwu_id           -- ID no sistema DWU
dwu_name         -- Nome no sistema DWU
dwu_custom_field -- Campo customizado do DWU
```

**2. Diferencia de Campos Padrão**

```sql
-- Colunas DWU vs colunas padrão do framework
dwu_id           -- ID proprietário
dwu_name         -- Campo de negócio
created_at       -- ← Sem prefixo (padrão ActiveRecord/Laravel)
updated_at       -- ← Sem prefixo (padrão)
deleted_at       -- ← Sem prefixo (padrão soft delete)
```

**3. Evita Conflitos em JOINs**

```sql
-- Em integrações, fica claro qual sistema é qual
SELECT 
  l.dwu_name as nome_dwu,           -- Sistema DWU
  d.name as nome_dinamize,          -- API Dinamize
  e.customer_name as nome_erp       -- Sistema ERP
FROM crm_leads l
JOIN dinamize_contacts d ON d.email = l.dwu_email
JOIN erp_customers e ON e.email = l.dwu_email;
```

**4. Campos Customizados Explícitos**

```sql
-- Fica óbvio que é customização DWU
dwu_score              -- Score customizado DWU
dwu_classification     -- Classificação interna DWU
dwu_internal_notes     -- Notas internas DWU
```

---

### 0.3 Exemplos Comparativos

#### **Boa Prática: Domínios Separados**

```sql
-- ✅ Sistema DWU com múltiplos módulos
crm_leads (dwu_id, dwu_name, dwu_email)
crm_opportunities (dwu_id, dwu_value, dwu_lead_id)

finance_invoices (dwu_id, dwu_number, dwu_value)
finance_payments (dwu_id, dwu_amount, dwu_invoice_id)

hr_employees (dwu_id, dwu_name, dwu_department)
hr_departments (dwu_id, dwu_name, dwu_manager_id)

-- Vantagens:
-- ✅ Tabela indica domínio (crm_, finance_, hr_)
-- ✅ Coluna indica proprietário (dwu_)
-- ✅ FK indica entidade (dwu_lead_id, dwu_invoice_id)
-- ✅ Desenvolvedor identifica contexto rapidamente
```

#### **Alternativa Descartada: Tudo com dwu_**

```sql
-- ⚠️ Menos claro: Tudo genérico
dwu_leads (dwu_id, dwu_name, dwu_email)
dwu_opportunities (dwu_id, dwu_value, dwu_lead_id)
dwu_invoices (dwu_id, dwu_number, dwu_value)        -- Qual domínio?
dwu_payments (dwu_id, dwu_amount, dwu_invoice_id)   -- Qual domínio?
dwu_employees (dwu_id, dwu_name, dwu_department)    -- Qual domínio?

-- Problemas:
-- ⚠️ Precisa verificar cada tabela para entender domínio
-- ⚠️ dwu_invoices poderia ser Finance, CRM ou até ERP
-- ⚠️ Namespace poluído (tudo parece igual)
-- ⚠️ Dificulta onboarding de novos desenvolvedores
```

---

### 0.4 Padrão Completo Adotado

| Elemento | Padrão | Indica | Exemplos |
|----------|--------|--------|----------|
| **Tabela** | `[dominio]_[entidade]` | Domínio funcional | `crm_leads`, `finance_invoices`, `hr_employees` |
| **Coluna** | `dwu_[nome]` | Proprietário DWU | `dwu_id`, `dwu_name`, `dwu_email` |
| **FK** | `dwu_[entidade]_id` | Entidade + Proprietário | `dwu_lead_id`, `dwu_company_id`, `dwu_invoice_id` |
| **Timestamps** | Sem prefixo | Padrão framework | `created_at`, `updated_at`, `deleted_at` |

**Benefícios:**
- ✅ **Clareza:** Tabela indica domínio, coluna indica sistema
- ✅ **Escalabilidade:** Fácil adicionar novos domínios
- ✅ **Consistência:** Padrão único em todo sistema DWU
- ✅ **Manutenibilidade:** Desenvolvedor identifica contexto rapidamente
- ✅ **Padrão de Mercado:** Alinhado com práticas enterprise

---

### 0.5 Roadmap de Domínios DWU

**Planejado/Possível:**

```sql
-- Módulo CRM (Atual - Mês 1-3)
crm_leads
crm_contacts
crm_opportunities
crm_companies
crm_lead_sync
crm_sync_queue

-- Módulo Integrações (Mês 3+)
integration_erp_configs
integration_api_keys
integration_webhooks

-- Módulo Financeiro (Futuro)
finance_invoices
finance_payments
finance_transactions
finance_accounts

-- Módulo RH (Futuro)
hr_employees
hr_departments
hr_payroll

-- Módulo ERP (Futuro)
erp_products
erp_inventory
erp_orders
erp_suppliers
```

**Com prefixo `crm_*`, fica óbvio qual módulo cada tabela pertence.** ✅

---

## 1. Entidades Principais

### 1.1 Leads (crm_leads)

**Objetivo:** Armazenar informações de leads/prospectos que podem vir de múltiplas fontes (Dinamize, Manual, CSV)

**Campos Principais:**

| Campo | Tipo | Descrição | Origem |
|-------|------|-----------|--------|
| `dwu_id` | SERIAL | ID interno (PK) | Sistema |
| `dwu_name` | VARCHAR(150) | Nome do lead | Dinamize/Manual |
| `dwu_email` | VARCHAR(150) | Email (único) | Dinamize/Manual |
| `dwu_phone` | VARCHAR(30) | Telefone | Dinamize/Manual |
| `dwu_origin` | VARCHAR(50) | Origem (Dinamize, Manual, CSV) | Sistema |
| `dwu_status` | VARCHAR(30) | Status (new, contacted, converted, lost) | Sistema |
| `dwu_tags` | TEXT[] | Tags para categorização | Sistema |
| `dwu_source_data` | JSONB | Dados completos da Dinamize | Dinamize |
| `dwu_country` | VARCHAR(2) | Código do país (ISO 3166-1 alpha-2) | Dinamize/Manual |
| `dwu_city` | VARCHAR(100) | Cidade | Dinamize/Manual |
| `dwu_state` | VARCHAR(100) | Estado/Província | Dinamize/Manual |
| `dwu_address` | TEXT | Endereço completo | Dinamize/Manual |
| `dwu_company_name` | VARCHAR(150) | Nome da empresa | Dinamize/Manual |
| `dwu_website` | VARCHAR(200) | Website | Dinamize/Manual |
| `dwu_source_url` | TEXT | URL de origem (rastreamento) | Sistema |
| `dwu_campaign` | VARCHAR(100) | Campanha que gerou o lead | Sistema |
| `dwu_converted_at` | TIMESTAMP | Data de conversão | Sistema |
| `dwu_converted_to_opportunity_id` | INTEGER | ID da oportunidade gerada | Sistema |
| `created_at` | TIMESTAMP | Data de criação | Sistema |
| `updated_at` | TIMESTAMP | Data de atualização | Sistema |

**Índices:**
- `idx_crm_leads_dwu_email` - Email (único)
- `idx_crm_leads_dwu_status` - Status
- `idx_crm_leads_dwu_campaign` - Campanha
- `idx_crm_leads_dwu_country` - País
- `idx_crm_leads_dwu_converted_to_opportunity_id` - Oportunidade convertida

### 1.2 Contatos (crm_contacts)

**Objetivo:** Armazenar contatos vinculados a empresas

**Campos Principais:**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `dwu_id` | SERIAL | ID interno (PK) |
| `dwu_company_id` | INTEGER | Referência para crm_companies (FK) |
| `dwu_name` | VARCHAR(150) | Nome do contato |
| `dwu_email` | VARCHAR(150) | Email |
| `dwu_phone` | VARCHAR(30) | Telefone |
| `dwu_position` | VARCHAR(100) | Cargo |
| `dwu_notes` | TEXT | Observações |
| `created_at` | TIMESTAMP | Data de criação |

**Índices:**
- `idx_crm_contacts_company_id` - Empresa

### 1.3 Empresas (crm_companies)

**Objetivo:** Armazenar informações de empresas/clientes

**Campos Principais:**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `dwu_id` | SERIAL | ID interno (PK) |
| `dwu_name` | VARCHAR(150) | Nome da empresa (obrigatório) |
| `dwu_cnpj` | VARCHAR(20) | CNPJ |
| `dwu_segment` | VARCHAR(100) | Segmento |
| `dwu_website` | VARCHAR(150) | Website |
| `created_at` | TIMESTAMP | Data de criação |

### 1.4 Oportunidades (crm_opportunities)

**Objetivo:** Armazenar oportunidades de venda no pipeline

**Campos Principais:**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `dwu_id` | SERIAL | ID interno (PK) |
| `dwu_lead_id` | INTEGER | Referência para crm_leads (FK) |
| `dwu_company_id` | INTEGER | Referência para crm_companies (FK) |
| `dwu_stage_id` | INTEGER | Referência para crm_stages (FK) |
| `dwu_assigned_to` | INTEGER | Usuário responsável |
| `dwu_value` | NUMERIC(12,2) | Valor da oportunidade |
| `dwu_forecast_date` | TIMESTAMP | Data prevista de fechamento |
| `dwu_probability` | INTEGER | Probabilidade (0-100%) |
| `dwu_status` | VARCHAR(30) | Status (open, closed, lost) |
| `created_at` | TIMESTAMP | Data de criação |
| `updated_at` | TIMESTAMP | Data de atualização |

**Índices:**
- `idx_crm_opportunities_lead_id` - Lead
- `idx_crm_opportunities_company_id` - Empresa
- `idx_crm_opportunities_stage_id` - Estágio

### 1.5 Pipeline e Estágios

**Tabela:** `crm_pipelines` - Pipeline de vendas
**Tabela:** `crm_stages` - Estágios dentro de um pipeline

**Relacionamento:**
- Pipeline (1) ──< (N) Estágios
- Oportunidade (N) >── (1) Estágio

---

## 2. Tabelas de Integração

### 2.1 crm_lead_sync

**Objetivo:** Rastrear sincronização entre leads locais e contatos na Dinamize

**Campos:**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `dwu_id` | SERIAL | ID interno (PK) |
| `dwu_lead_id` | INTEGER | Referência para crm_leads (FK) |
| `dwu_dinamize_contact_id` | VARCHAR(50) | ID do contato na Dinamize |
| `dwu_list_id` | VARCHAR(50) | ID da lista na Dinamize |
| `dwu_status` | VARCHAR(20) | Status da sincronização (pending, synced, error) |
| `last_sync` | TIMESTAMP | Última tentativa de sincronização |
| `last_successful_sync` | TIMESTAMP | Última sincronização bem-sucedida |
| `sync_error_count` | INTEGER | Contador de erros consecutivos |
| `last_error_message` | TEXT | Última mensagem de erro |

**Constraint:** `UNIQUE (dwu_lead_id, dwu_list_id)` - Evita duplicatas

**Índices:**
- `idx_crm_lead_sync_lead_id` - Lead

### 2.2 crm_sync_queue

**Objetivo:** Fila de operações de sincronização assíncronas

**Campos:**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `dwu_id` | SERIAL | ID interno (PK) |
| `dwu_lead_sync_id` | INTEGER | Referência para crm_lead_sync (FK) |
| `dwu_operation` | VARCHAR(20) | Operação (create, update, delete) |
| `dwu_payload` | JSONB | Payload completo da operação |
| `dwu_attempt_count` | INTEGER | Contador de tentativas |
| `dwu_status` | VARCHAR(20) | Status (queued, processing, completed, failed) |
| `last_attempt` | TIMESTAMP | Última tentativa |
| `created_at` | TIMESTAMP | Data de criação |

### 2.3 crm_sync_logs

**Objetivo:** Logs detalhados de sincronização

**Campos:**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `dwu_id` | BIGSERIAL | ID interno (PK) - BIGSERIAL devido ao alto volume |
| `dwu_queue_id` | INTEGER | Referência para crm_sync_queue (FK) |
| `dwu_response_code` | VARCHAR(20) | Código de resposta |
| `dwu_response_detail` | TEXT | Detalhes da resposta |
| `dwu_response_body` | JSONB | Corpo da resposta |
| `dwu_error_category` | VARCHAR(50) | Categoria (NETWORK, AUTH, VALIDATION, API_ERROR) |
| `dwu_error_code` | VARCHAR(50) | Código de erro específico |
| `dwu_retry_after` | INTEGER | Segundos até próxima tentativa (rate limiting) |
| `created_at` | TIMESTAMP | Data de criação |

**Nota:** BIGSERIAL usado pois esta tabela pode crescer rapidamente (milhões de registros).

### 2.4 crm_auth_tokens

**Objetivo:** Armazenar tokens de autenticação Dinamize

**Campos:**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `dwu_id` | SERIAL | ID interno (PK) |
| `dwu_auth_token` | TEXT | Token de acesso (criptografado) |
| `dwu_refresh_token` | TEXT | Refresh token (se disponível, criptografado) |
| `dwu_token_type` | VARCHAR(20) | Tipo (TOKEN_CUSTOM, JWT, OAuth2, API_KEY) |
| `dwu_scope` | TEXT | Escopo/permissões |
| `dwu_api_endpoint` | VARCHAR(200) | URL base da API |
| `obtained_at` | TIMESTAMP | Data de obtenção |
| `expires_at` | TIMESTAMP | Data de expiração |
| `dwu_active` | BOOLEAN | Se está ativo |

### 2.5 crm_settings

**Objetivo:** Configurações gerais do sistema e integrações

**Campos:**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `dwu_id` | SERIAL | ID interno (PK) |
| `dwu_key` | VARCHAR(100) | Chave única |
| `dwu_value` | TEXT | Valor (pode ser criptografado) |
| `dwu_category` | VARCHAR(50) | Categoria (dinamize, system, integration) |
| `dwu_encrypted` | BOOLEAN | Se o valor está criptografado |
| `dwu_description` | TEXT | Descrição |
| `updated_at` | TIMESTAMP | Data de atualização |

### 2.6 crm_webhook_events

**Objetivo:** Eventos recebidos via webhook (se disponível)

**Campos:**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `dwu_id` | BIGSERIAL | ID interno (PK) - BIGSERIAL devido ao alto volume de eventos |
| `dwu_event_type` | VARCHAR(50) | Tipo (lead.created, lead.updated, etc.) |
| `dwu_source` | VARCHAR(50) | Fonte (dinamize, manual) |
| `dwu_payload` | JSONB | Payload completo |
| `dwu_processed` | BOOLEAN | Se foi processado |
| `dwu_processed_at` | TIMESTAMP | Quando foi processado |
| `dwu_error` | TEXT | Erro no processamento |
| `created_at` | TIMESTAMP | Data de criação |

**Nota:** BIGSERIAL usado pois webhooks podem gerar alto volume de eventos.

### 2.7 crm_audit_log

**Objetivo:** Log de auditoria de todas as ações

**Campos:**

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `dwu_id` | BIGSERIAL | ID interno (PK) - BIGSERIAL devido ao volume de auditoria |
| `dwu_user_id` | INTEGER | Usuário que executou a ação |
| `dwu_action` | VARCHAR(50) | Ação (CREATE, UPDATE, DELETE, SYNC) |
| `dwu_entity_type` | VARCHAR(50) | Tipo de entidade (lead, contact, opportunity) |
| `dwu_entity_id` | INTEGER | ID da entidade |
| `dwu_changes` | JSONB | Dados antes/depois |
| `dwu_ip_address` | VARCHAR(45) | IP de origem |
| `dwu_user_agent` | TEXT | User agent |
| `created_at` | TIMESTAMP | Data de criação |

**Nota:** BIGSERIAL usado pois auditoria gera muitos registros ao longo do tempo.

---

## 2.8 Decisão: SERIAL vs BIGSERIAL

### **Estratégia de IDs:**

| Tipo de Tabela | Tipo ID | Capacidade | Justificativa |
|----------------|---------|-----------|---------------|
| **Entidades Principais** | SERIAL | 2.1 bilhões | Suficiente para leads, contacts, companies, opportunities |
| **Tabelas de Log** | BIGSERIAL | 9.2 quintilhões | Alto volume: sync_logs, audit_log, webhook_events |

### **Análise de Crescimento:**

```
Exemplo de volumetria:

crm_leads (SERIAL):
├─ 100k leads/ano × 50 anos = 5M registros
└─ Conclusão: SERIAL suficiente ✅

crm_sync_logs (BIGSERIAL):
├─ 100k leads × 10 syncs cada = 1M logs/ano
├─ 10 anos = 10M registros
└─ Conclusão: BIGSERIAL recomendado ⚠️

crm_audit_log (BIGSERIAL):
├─ 1000 ações/dia × 365 dias × 10 anos = 3.65M
└─ Conclusão: BIGSERIAL preventivo ✅
```

### **Trade-offs:**

| Aspecto | SERIAL (4 bytes) | BIGSERIAL (8 bytes) |
|---------|------------------|---------------------|
| **Espaço em disco** | ✅ Menor | ⚠️ +100% |
| **Performance índices** | ✅ Mais rápido | ⚠️ Ligeiramente mais lento |
| **Performance JOINs** | ✅ Mais rápido | ⚠️ Ligeiramente mais lento |
| **Capacidade** | ⚠️ 2.1B | ✅ 9.2Q |

**Decisão:** Usar BIGSERIAL apenas onde o volume justifica (logs e auditoria).

---

## 3. Mapeamento Dinamize → CRM

### 3.1 Tabela de Mapeamento

| Campo Dinamize | Tipo | Campo CRM | Tabela | Observações |
|----------------|------|-----------|--------|-------------|
| `code` | string | `dwu_dinamize_contact_id` | crm_lead_sync | ID externo do contato |
| `email` | string | `dwu_email` | crm_leads | Email único |
| `name` | string | `dwu_name` | crm_leads | Nome do contato |
| `external_code` | string | JSONB | crm_leads.dwu_source_data | Código externo customizado |
| `insert_date` | datetime | `created_at` | crm_leads | Data de registro |
| `status` | string | `dwu_status` | crm_leads | `V` = válido, `I` = inválido |
| `optout` | boolean | `dwu_status = 'unsubscribed'` | crm_leads | Se fez descadastro |
| `spam` | boolean | JSONB | crm_leads.dwu_source_data | Se denunciou SPAM |
| `total_clicks` | string | JSONB | crm_leads.dwu_source_data | Total de cliques |
| `total_sents` | string | JSONB | crm_leads.dwu_source_data | Total de envios |
| `total_views` | string | JSONB | crm_leads.dwu_source_data | Total de visualizações |
| `custom_fields` | object | JSONB | crm_leads.dwu_source_data | Campos personalizados (cmp4, cmp5, etc.) |
| `contact-list_code` | string | `dwu_list_id` | crm_lead_sync | ID da lista |
| `date_rest` | string | JSONB | crm_leads.dwu_source_data | Data de descanso |

### 3.2 Armazenamento de Dados Extras

Todos os campos não mapeados diretamente são armazenados em `dwu_source_data` (JSONB) na tabela `crm_leads`, permitindo:
- Flexibilidade para campos customizados
- Preservação de dados completos da Dinamize
- Consultas JSONB para campos específicos

**Exemplo:**
```sql
-- Buscar campo customizado
SELECT dwu_source_data->>'cmp4' as campo_customizado
FROM crm_leads
WHERE dwu_source_data->>'external_code' = 'EXT001';
```

---

## 4. Relacionamentos

### 4.1 Diagrama de Relacionamentos

```
crm_leads (1) ──< (N) crm_lead_sync (via dwu_lead_id)
crm_leads (1) ──< (N) crm_opportunities (via dwu_lead_id)
crm_leads (1) >── (1) crm_opportunities (via dwu_converted_to_opportunity_id)

crm_companies (1) ──< (N) crm_contacts (via dwu_company_id)
crm_companies (1) ──< (N) crm_opportunities (via dwu_company_id)

crm_pipelines (1) ──< (N) crm_stages (via dwu_pipeline_id)
crm_stages (1) ──< (N) crm_opportunities (via dwu_stage_id)

crm_lead_sync (1) ──< (N) crm_sync_queue (via dwu_lead_sync_id)
crm_sync_queue (1) ──< (N) crm_sync_logs (via dwu_queue_id)
```

### 4.2 Observações

- **crm_lead_sync** é a ponte entre leads locais e contatos na Dinamize
- Cada lead pode ter múltiplas sincronizações (uma por lista)
- Oportunidade pode ser gerada a partir de um lead (via `dwu_converted_to_opportunity_id`)
- Sistema de filas permite processamento assíncrono de sincronizações
- **Todas FKs seguem padrão `dwu_[entidade]_id`** para clareza e consistência

---

## 5. Estratégia de Sincronização

### 5.1 Sincronização Incremental

**Objetivo:** Sincronizar apenas registros novos ou atualizados

**Método:**
- Usar campo `insert_date` da Dinamize para filtrar
- Buscar contatos com `insert_date >= última_sincronização`
- Atualizar `last_successful_sync` após cada sincronização bem-sucedida

**Exemplo de busca:**
```json
{
  "contact-list_code": "1",
  "search": [
    {
      "field": "insert_date",
      "operator": ">=",
      "value": "2025-01-15 10:30:00"
    }
  ]
}
```

### 5.2 Tratamento de Dados Extras

- Campos não mapeados diretamente → `dwu_source_data` (JSONB)
- Permite flexibilidade para campos customizados da Dinamize
- Consultas JSONB para acesso a campos específicos

### 5.3 Identificação de Duplicatas

- Usar `email` como chave única em `crm_leads`
- Usar `external_code` para mapear contatos do CRM para Dinamize
- Constraint `UNIQUE (lead_id, dwu_list_id)` em `crm_lead_sync`

---

## 6. Próximos Passos

### 6.1 Validações Necessárias
1. Validar estrutura executando script SQL completo
2. Testar integridade referencial
3. Validar índices e performance
4. Testar consultas JSONB

### 6.2 Documentação Adicional
1. Criar diagrama ER visual atualizado
2. Documentar regras de negócio para conversão lead → oportunidade
3. Documentar tratamento de campos customizados (cmp4, cmp5, etc.)
4. Criar scripts de validação de dados

### 6.3 Implementação
1. Criar serviços de acesso aos dados
2. Implementar sincronização incremental
3. Criar sistema de validação de integridade
4. Implementar tratamento de duplicatas

---

## 7. Referências

- **Script SQL:** `dwu_crm_mvp_import_pgadmin.sql`
- **Banco de Dados:** PostgreSQL
- **Versão:** 1.0 (consolidada)

---

## 8. Histórico de Alterações

### **Versão 1.1** - 2025-11-05
- ✅ **Adicionada Seção 0: Convenções de Nomenclatura**
  - Justificativa técnica para uso de `crm_*` (tabelas) vs `dwu_*` (colunas)
  - Análise baseada em padrões da indústria (Oracle, SAP, Dynamics, Salesforce)
  - Exemplos comparativos e cenários de escalabilidade
  - Roadmap de domínios futuros (finance_, hr_, erp_)
- ✅ **Alterado de SERIAL para BIGSERIAL nas tabelas de alto volume:**
  - `crm_sync_logs` (milhões de registros esperados)
  - `crm_audit_log` (auditoria contínua)
  - `crm_webhook_events` (alto volume de eventos)
- ✅ **Adicionada seção 2.8** explicando decisão SERIAL vs BIGSERIAL
- ✅ **Mantido SERIAL** nas entidades principais (capacidade suficiente)
- ✅ **Padronizado FKs** com prefixo `dwu_[entidade]_id`:
  - `company_id` → `dwu_company_id`
  - `lead_id` → `dwu_lead_id`
  - `stage_id` → `dwu_stage_id`
  - `queue_id` → `dwu_queue_id`
  - `lead_sync_id` → `dwu_lead_sync_id`
- ✅ **Atualizado diagrama de relacionamentos** com novos nomes
- ✅ **Observação adicionada** sobre padrão de nomenclatura de FKs

### **Versão 1.0** - 2025-01-05
- ✅ Estrutura inicial definida
- ✅ Todas as entidades principais criadas
- ✅ Tabelas de integração definidas

---

**Última atualização:** 2025-11-05  
**Responsável:** Equipe DWU CRM  
**Versão:** 1.1


