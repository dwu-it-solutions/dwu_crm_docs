# CRM-DINAMIZE - Análise e Plano de Integração
## DWU - Sistema de CRM com Integração Dinamize

---

## 📋 Sumário Executivo

Este documento apresenta a análise da estrutura atual do banco de dados `dwu_crm_mvp`, recomendações de melhoria e plano de ação para integração com a API Dinamize.

**Fase Atual:** Mês 1 - Estrutura Base + Integração com Dinamize  
**Status:** Estrutura base criada, análise em andamento

---

## 1️⃣ Levantamento Técnico - Integração Dinamize

### 1.1 Documentação API Dinamize
- **URL da Documentação:** https://panel.dinamize.com/apidoc/
- **Status:** Requer acesso e análise detalhada dos endpoints disponíveis

### 1.2 Endpoints Esperados (Baseado na Estrutura Atual)
Com base nas tabelas criadas, esperamos utilizar:

1. **Autenticação**
   - Endpoint de login/token
   - Renovação de tokens
   - Revogação de tokens

2. **Leads/Contatos**
   - Listar contatos/leads
   - Criar contato/lead
   - Atualizar contato/lead
   - Buscar por ID ou email
   - Sincronização de listas

3. **Listas de Marketing**
   - Listar listas disponíveis
   - Adicionar contato em lista
   - Remover contato de lista
   - Criar lista

---

## 2️⃣ Análise da Estrutura Atual

### 2.1 Pontos Fortes ✅

1. **Tabela `crm_leads`**
   - ✅ Campo `dwu_source_data JSONB` para armazenar payload completo da Dinamize
   - ✅ Campo `dwu_origin` para identificar origem (Dinamize, Manual, CSV)
   - ✅ Campo `dwu_tags` para categorização
   - ✅ Índice em email para performance

2. **Tabela `crm_lead_sync`**
   - ✅ Armazena relacionamento entre lead local e contato Dinamize
   - ✅ Campo `dwu_dinamize_contact_id` para ID externo
   - ✅ Campo `dwu_list_id` para rastrear listas
   - ✅ Constraint UNIQUE para evitar duplicatas

3. **Tabela `crm_sync_queue`**
   - ✅ Sistema de fila para operações assíncronas
   - ✅ Suporte a retry com `dwu_attempt_count`
   - ✅ Payload JSONB para flexibilidade

4. **Tabela `crm_auth_tokens`**
   - ✅ Armazena tokens de autenticação
   - ✅ Campo `expires_at` para controle de expiração
   - ✅ Campo `dwu_active` para revogação

### 2.2 Melhorias Necessárias ⚠️

#### 🔴 Crítico - Autenticação

**Problema Identificado:**
- Tabela `crm_auth_tokens` não possui campos suficientes para autenticação Dinamize
- Falta armazenar refresh token (se Dinamize usar OAuth2)
- Falta armazenar tipo de autenticação (JWT, OAuth2, API Key)

**Recomendações:**
```sql
-- Adicionar campos necessários:
ALTER TABLE crm_auth_tokens ADD COLUMN dwu_refresh_token TEXT;
ALTER TABLE crm_auth_tokens ADD COLUMN dwu_token_type VARCHAR(20); -- 'JWT', 'OAuth2', 'API_KEY'
ALTER TABLE crm_auth_tokens ADD COLUMN dwu_scope TEXT; -- Permissões do token
ALTER TABLE crm_auth_tokens ADD COLUMN dwu_api_endpoint VARCHAR(200); -- URL base da API
```

#### 🟡 Importante - Sincronização

**Problemas Identificados:**

1. **Falta rastreamento de erro detalhado**
   - Tabela `crm_sync_logs` existe mas pode ser melhorada
   - Falta campo para categorizar tipos de erro

2. **Falta controle de taxa de requisições (Rate Limiting)**
   - Dinamize pode ter limites de requisições por minuto/hora
   - Necessário adicionar controle de throttling

3. **Falta last_successful_sync**
   - Campo `last_sync` em `crm_lead_sync` não diferencia sucesso de falha

**Recomendações:**
```sql
-- Adicionar campos para melhor rastreamento:
ALTER TABLE crm_lead_sync ADD COLUMN last_successful_sync TIMESTAMP;
ALTER TABLE crm_lead_sync ADD COLUMN sync_error_count INTEGER DEFAULT 0;
ALTER TABLE crm_lead_sync ADD COLUMN last_error_message TEXT;

-- Melhorar crm_sync_logs:
ALTER TABLE crm_sync_logs ADD COLUMN dwu_error_category VARCHAR(50); -- 'NETWORK', 'AUTH', 'VALIDATION', 'API_ERROR'
ALTER TABLE crm_sync_logs ADD COLUMN dwu_error_code VARCHAR(50);
ALTER TABLE crm_sync_logs ADD COLUMN dwu_retry_after INTEGER; -- Para rate limiting
```

#### 🟡 Importante - Webhooks e Eventos

**Problema Identificado:**
- Falta estrutura para receber webhooks da Dinamize
- Se Dinamize enviar eventos (novo lead, atualização, etc.), precisamos processar

**Recomendação:**
```sql
-- Nova tabela para webhooks/eventos:
CREATE TABLE IF NOT EXISTS crm_webhook_events (
  dwu_id SERIAL PRIMARY KEY,
  dwu_event_type VARCHAR(50), -- 'lead.created', 'lead.updated', 'lead.deleted'
  dwu_source VARCHAR(50) DEFAULT 'dinamize',
  dwu_payload JSONB NOT NULL,
  dwu_processed BOOLEAN DEFAULT FALSE,
  dwu_processed_at TIMESTAMP,
  dwu_error TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_crm_webhook_events_processed ON crm_webhook_events(dwu_processed);
CREATE INDEX idx_crm_webhook_events_type ON crm_webhook_events(dwu_event_type);
```

#### 🟢 Melhoria - Campos Adicionais para Leads

**Recomendações:**
```sql
-- Campos que podem ser úteis baseado em APIs de CRM:
ALTER TABLE crm_leads ADD COLUMN dwu_country VARCHAR(2); -- ISO 3166-1 alpha-2
ALTER TABLE crm_leads ADD COLUMN dwu_city VARCHAR(100);
ALTER TABLE crm_leads ADD COLUMN dwu_state VARCHAR(100);
ALTER TABLE crm_leads ADD COLUMN dwu_address TEXT;
ALTER TABLE crm_leads ADD COLUMN dwu_company_name VARCHAR(150);
ALTER TABLE crm_leads ADD COLUMN dwu_website VARCHAR(200);
ALTER TABLE crm_leads ADD COLUMN dwu_source_url TEXT; -- URL de origem (para rastreamento)
ALTER TABLE crm_leads ADD COLUMN dwu_campaign VARCHAR(100); -- Campanha que gerou o lead
ALTER TABLE crm_leads ADD COLUMN dwu_converted_at TIMESTAMP; -- Quando foi convertido
ALTER TABLE crm_leads ADD COLUMN dwu_converted_to_opportunity_id INTEGER REFERENCES crm_opportunities(dwu_id);
```

---

## 3️⃣ Autenticação e Segurança

### 3.1 Estratégia de Autenticação

**Opções:**

#### Opção A: API Key (Mais Simples)
- Token único fornecido pela Dinamize
- Armazenar em `crm_auth_tokens`
- Incluir no header de cada requisição

#### Opção B: JWT (Recomendado se disponível)
- Token com expiração
- Refresh token para renovação automática
- Mais seguro que API Key

#### Opção C: OAuth2 (Mais Complexo, Mais Seguro)
- Fluxo de autorização completo
- Refresh tokens automáticos
- Melhor para aplicações de produção

### 3.2 Tabela de Configurações

**Recomendação:** Criar tabela para configurações gerais:

```sql
CREATE TABLE IF NOT EXISTS crm_settings (
  dwu_id SERIAL PRIMARY KEY,
  dwu_key VARCHAR(100) UNIQUE NOT NULL,
  dwu_value TEXT,
  dwu_category VARCHAR(50), -- 'dinamize', 'system', 'integration'
  dwu_encrypted BOOLEAN DEFAULT FALSE,
  dwu_description TEXT,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Exemplos de configurações:
-- 'dinamize_api_base_url' -> 'https://api.dinamize.com/v1'
-- 'dinamize_rate_limit_per_minute' -> '60'
-- 'sync_interval_minutes' -> '15'
-- 'timezone' -> 'America/Sao_Paulo'
```

### 3.3 Segurança de Dados

**Recomendações:**

1. **Criptografar tokens sensíveis**
   - Usar criptografia no backend antes de armazenar
   - Campo `dwu_encrypted` para identificar campos criptografados

2. **Logs de auditoria**
   ```sql
   CREATE TABLE IF NOT EXISTS crm_audit_log (
     dwu_id SERIAL PRIMARY KEY,
     dwu_user_id INTEGER, -- Usuário que fez a ação
     dwu_action VARCHAR(50), -- 'CREATE', 'UPDATE', 'DELETE', 'SYNC'
     dwu_entity_type VARCHAR(50), -- 'lead', 'contact', 'opportunity'
     dwu_entity_id INTEGER,
     dwu_changes JSONB, -- Dados alterados (before/after)
     dwu_ip_address VARCHAR(45),
     dwu_user_agent TEXT,
     created_at TIMESTAMP DEFAULT NOW()
   );
   ```

---

## 4️⃣ Plano de Ação - Próximos Passos

### Fase 1: Análise e Documentação (Semana 1)
- [ ] Acessar e analisar documentação completa da API Dinamize
- [ ] Identificar todos os endpoints necessários
- [ ] Mapear campos da API Dinamize para nossa estrutura
- [ ] Documentar fluxo de autenticação (JWT/OAuth2/API Key)
- [ ] Identificar limites de rate limiting
- [ ] Verificar se Dinamize suporta webhooks

### Fase 2: Ajustes no Banco de Dados (Semana 1-2)
- [ ] Adicionar campos faltantes em `crm_auth_tokens`
- [ ] Criar tabela `crm_settings` para configurações
- [ ] Melhorar `crm_sync_logs` com categorias de erro
- [ ] Adicionar campos adicionais em `crm_leads`
- [ ] Criar tabela `crm_webhook_events` (se necessário)
- [ ] Criar tabela `crm_audit_log` para auditoria
- [ ] Atualizar índices conforme necessário

### Fase 3: Implementação Backend (Semana 2-3)
- [ ] Implementar serviço de autenticação Dinamize
- [ ] Implementar gerenciamento de tokens (refresh automático)
- [ ] Criar serviço de sincronização de leads
- [ ] Implementar sistema de filas (crm_sync_queue)
- [ ] Implementar tratamento de erros e retry
- [ ] Implementar rate limiting
- [ ] Criar endpoints de webhook (se necessário)

### Fase 4: Testes e Validação (Semana 3-4)
- [ ] Testes unitários dos serviços
- [ ] Testes de integração com API Dinamize (sandbox/teste)
- [ ] Testes de sincronização em massa
- [ ] Testes de tratamento de erros
- [ ] Testes de performance
- [ ] Validação de dados sincronizados

---

## 5️⃣ Estrutura de Arquivos Recomendada (Backend)

```
backend/
├── src/
│   ├── modules/
│   │   ├── dinamize/
│   │   │   ├── auth/
│   │   │   │   ├── dinamize-auth.service.ts
│   │   │   │   ├── dinamize-auth.controller.ts
│   │   │   │   └── token-manager.ts
│   │   │   ├── sync/
│   │   │   │   ├── lead-sync.service.ts
│   │   │   │   ├── sync-queue.service.ts
│   │   │   │   └── sync-scheduler.ts
│   │   │   ├── webhooks/
│   │   │   │   └── webhook-handler.service.ts
│   │   │   └── dinamize-api.client.ts
│   │   ├── leads/
│   │   ├── contacts/
│   │   └── opportunities/
│   ├── common/
│   │   ├── rate-limiter/
│   │   └── audit-log/
│   └── config/
│       └── dinamize.config.ts
```

---

## 6️⃣ Checklist de Implementação

### Autenticação Dinamize
- [ ] Identificar tipo de autenticação (API Key/JWT/OAuth2)
- [ ] Implementar serviço de autenticação
- [ ] Implementar refresh automático de tokens
- [ ] Armazenar tokens de forma segura (criptografado)
- [ ] Tratar expiração de tokens

### Sincronização de Leads
- [ ] Criar endpoint para sincronização manual
- [ ] Implementar sincronização automática (cron job)
- [ ] Sincronização bidirecional (Dinamize → CRM e CRM → Dinamize)
- [ ] Tratamento de conflitos (última modificação ganha ou merge)
- [ ] Sincronização incremental (apenas mudanças)

### Sistema de Filas
- [ ] Implementar processamento de fila
- [ ] Implementar retry com backoff exponencial
- [ ] Tratamento de falhas permanentes
- [ ] Dashboard de monitoramento da fila

### Tratamento de Erros
- [ ] Categorizar erros (network, auth, validation, API)
- [ ] Logs detalhados de erros
- [ ] Alertas para erros críticos
- [ ] Notificações para administradores

### Rate Limiting
- [ ] Implementar controle de taxa de requisições
- [ ] Respeitar limites da API Dinamize
- [ ] Filas para requisições excedentes
- [ ] Retry após período de rate limit

---

## 7️⃣ Variáveis de Ambiente Necessárias

```env
# Dinamize API
DINAMIZE_API_BASE_URL=https://api.dinamize.com/v1
DINAMIZE_API_KEY=your_api_key_here
DINAMIZE_CLIENT_ID=your_client_id  # Se OAuth2
DINAMIZE_CLIENT_SECRET=your_client_secret  # Se OAuth2

# Autenticação
DINAMIZE_AUTH_TYPE=API_KEY  # ou JWT ou OAUTH2
DINAMIZE_TOKEN_EXPIRY_MINUTES=60

# Sincronização
SYNC_INTERVAL_MINUTES=15
SYNC_BATCH_SIZE=100
SYNC_MAX_RETRIES=3

# Rate Limiting
DINAMIZE_RATE_LIMIT_PER_MINUTE=60
DINAMIZE_RATE_LIMIT_PER_HOUR=1000

# Timezone
APP_TIMEZONE=America/Sao_Paulo

# Segurança
ENCRYPT_TOKEN_KEY=your_encryption_key_here
```

---

## 8️⃣ Próximas Ações Imediatas

1. **Acessar documentação Dinamize** e mapear endpoints
2. **Aplicar melhorias no banco de dados** (seção 2.2)
3. **Criar estrutura inicial do backend** para integração
4. **Implementar autenticação** conforme tipo suportado pela Dinamize
5. **Criar testes** para validar integração

---

## 📝 Notas Finais

Esta análise foi baseada na estrutura atual do banco de dados e boas práticas de integração com APIs externas. Recomenda-se revisar e ajustar conforme a documentação específica da API Dinamize.

**Próxima revisão:** Após análise da documentação completa da API Dinamize

---

**Documento criado em:** 2025-01-XX  
**Última atualização:** 2025-01-XX  
**Versão:** 1.0
