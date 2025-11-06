-- ============================================
-- CRM Database Schema - PostgreSQL (dwu_crm_mvp)
-- Script para importar no pgAdmin 4
-- Versão consolidada com todas as melhorias
-- ============================================
-- 
-- INSTRUÇÕES PARA USAR NO PGADMIN 4:
-- 1. Conecte ao servidor PostgreSQL
-- 2. Clique com botão direito em "Databases" > "Create" > "Database"
-- 3. Nome: dwu_crm_mvp
-- 4. Execute este script (Query Tool)
-- 5. Após criar as tabelas, use Tools > Generate ERD para visualizar o diagrama
--

-- ============================================
-- 1. MÓDULO DE LEADS
-- ============================================

CREATE TABLE IF NOT EXISTS crm_leads (
  dwu_id SERIAL PRIMARY KEY,
  dwu_name VARCHAR(150),
  dwu_email VARCHAR(150) UNIQUE,
  dwu_phone VARCHAR(30),
  dwu_origin VARCHAR(50),
  dwu_source_data JSONB,
  dwu_status VARCHAR(30) DEFAULT 'new',
  dwu_tags TEXT[],
  -- Campos adicionais para integração Dinamize
  dwu_country VARCHAR(2), -- ISO 3166-1 alpha-2
  dwu_city VARCHAR(100),
  dwu_state VARCHAR(100),
  dwu_address TEXT,
  dwu_company_name VARCHAR(150),
  dwu_website VARCHAR(200),
  dwu_source_url TEXT, -- URL de origem (para rastreamento)
  dwu_campaign VARCHAR(100), -- Campanha que gerou o lead
  dwu_converted_at TIMESTAMP, -- Quando foi convertido
  dwu_converted_to_opportunity_id INTEGER, -- Referência será adicionada após criar crm_opportunities
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE crm_leads IS 'Módulo de Leads - origem: Dinamize, Manual, CSV';
COMMENT ON COLUMN crm_leads.dwu_origin IS 'origem: Dinamize, Manual, CSV';
COMMENT ON COLUMN crm_leads.dwu_status IS 'new | contacted | converted | lost';
COMMENT ON COLUMN crm_leads.dwu_country IS 'Código do país (ISO 3166-1 alpha-2, ex: BR, US)';
COMMENT ON COLUMN crm_leads.dwu_city IS 'Cidade do lead';
COMMENT ON COLUMN crm_leads.dwu_state IS 'Estado/Província';
COMMENT ON COLUMN crm_leads.dwu_address IS 'Endereço completo';
COMMENT ON COLUMN crm_leads.dwu_company_name IS 'Nome da empresa (se aplicável)';
COMMENT ON COLUMN crm_leads.dwu_website IS 'Website do lead/empresa';
COMMENT ON COLUMN crm_leads.dwu_source_url IS 'URL de origem (para rastreamento de campanhas)';
COMMENT ON COLUMN crm_leads.dwu_campaign IS 'Campanha que gerou o lead';
COMMENT ON COLUMN crm_leads.dwu_converted_at IS 'Data/hora em que o lead foi convertido';
COMMENT ON COLUMN crm_leads.dwu_converted_to_opportunity_id IS 'ID da oportunidade gerada a partir deste lead';

-- ============================================
-- 2. INTEGRAÇÃO COM DINAMIZE - Sincronização de Leads
-- ============================================

CREATE TABLE IF NOT EXISTS crm_lead_sync (
  dwu_id SERIAL PRIMARY KEY,
  lead_id INTEGER REFERENCES crm_leads(dwu_id) ON DELETE CASCADE,
  dwu_dinamize_contact_id VARCHAR(50),
  dwu_list_id VARCHAR(50),
  dwu_status VARCHAR(20) DEFAULT 'pending',
  last_sync TIMESTAMP,
  -- Campos adicionais para rastreamento de erros
  last_successful_sync TIMESTAMP,
  sync_error_count INTEGER DEFAULT 0,
  last_error_message TEXT,
  UNIQUE (lead_id, dwu_list_id)
);

COMMENT ON TABLE crm_lead_sync IS 'Sincronização de leads com Dinamize';
COMMENT ON COLUMN crm_lead_sync.last_successful_sync IS 'Última sincronização bem-sucedida';
COMMENT ON COLUMN crm_lead_sync.sync_error_count IS 'Contador de erros consecutivos';
COMMENT ON COLUMN crm_lead_sync.last_error_message IS 'Última mensagem de erro';

-- ============================================
-- 3. MÓDULO DE CONTATOS & EMPRESAS
-- ============================================

CREATE TABLE IF NOT EXISTS crm_companies (
  dwu_id SERIAL PRIMARY KEY,
  dwu_name VARCHAR(150) NOT NULL,
  dwu_cnpj VARCHAR(20),
  dwu_segment VARCHAR(100),
  dwu_website VARCHAR(150),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS crm_contacts (
  dwu_id SERIAL PRIMARY KEY,
  company_id INTEGER REFERENCES crm_companies(dwu_id) ON DELETE CASCADE,
  dwu_name VARCHAR(150),
  dwu_email VARCHAR(150),
  dwu_phone VARCHAR(30),
  dwu_position VARCHAR(100),
  dwu_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS crm_interactions (
  dwu_id SERIAL PRIMARY KEY,
  contact_id INTEGER REFERENCES crm_contacts(dwu_id) ON DELETE CASCADE,
  dwu_type VARCHAR(30),
  dwu_description TEXT,
  occurred_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON COLUMN crm_interactions.dwu_type IS 'email | call | meeting | task';

-- ============================================
-- 4. MÓDULO DE VENDAS (PIPELINE)
-- ============================================

CREATE TABLE IF NOT EXISTS crm_pipelines (
  dwu_id SERIAL PRIMARY KEY,
  dwu_name VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS crm_stages (
  dwu_id SERIAL PRIMARY KEY,
  pipeline_id INTEGER REFERENCES crm_pipelines(dwu_id) ON DELETE CASCADE,
  dwu_name VARCHAR(100),
  dwu_position INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS crm_opportunities (
  dwu_id SERIAL PRIMARY KEY,
  lead_id INTEGER REFERENCES crm_leads(dwu_id),
  company_id INTEGER REFERENCES crm_companies(dwu_id),
  stage_id INTEGER REFERENCES crm_stages(dwu_id),
  dwu_assigned_to INTEGER,
  dwu_value NUMERIC(12,2),
  dwu_forecast_date TIMESTAMP,
  dwu_probability INTEGER,
  dwu_status VARCHAR(30) DEFAULT 'open',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON COLUMN crm_opportunities.dwu_assigned_to IS 'usuário responsável';
COMMENT ON COLUMN crm_opportunities.dwu_probability IS '0-100%';

-- ============================================
-- 5. MÓDULO DE TAREFAS E ATIVIDADES
-- ============================================

CREATE TABLE IF NOT EXISTS crm_tasks (
  dwu_id SERIAL PRIMARY KEY,
  dwu_related_type VARCHAR(20),
  dwu_related_id INTEGER,
  dwu_type VARCHAR(30),
  dwu_description TEXT,
  dwu_due_date TIMESTAMP,
  dwu_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON COLUMN crm_tasks.dwu_related_type IS 'lead | opportunity';
COMMENT ON COLUMN crm_tasks.dwu_type IS 'reunião | ligação | follow-up';

-- ============================================
-- 6. INTEGRAÇÃO COM DINAMIZE - Sistema de Filas
-- ============================================

CREATE TABLE IF NOT EXISTS crm_sync_queue (
  dwu_id SERIAL PRIMARY KEY,
  lead_sync_id INTEGER REFERENCES crm_lead_sync(dwu_id) ON DELETE CASCADE,
  dwu_operation VARCHAR(20) NOT NULL,
  dwu_payload JSONB NOT NULL,
  dwu_attempt_count INTEGER DEFAULT 0,
  dwu_status VARCHAR(20) DEFAULT 'queued',
  last_attempt TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON COLUMN crm_sync_queue.dwu_operation IS 'create | update | delete';

CREATE TABLE IF NOT EXISTS crm_sync_logs (
  dwu_id SERIAL PRIMARY KEY,
  queue_id INTEGER REFERENCES crm_sync_queue(dwu_id) ON DELETE CASCADE,
  dwu_response_code VARCHAR(20),
  dwu_response_detail TEXT,
  dwu_response_body JSONB,
  -- Campos adicionais para categorização de erros
  dwu_error_category VARCHAR(50), -- 'NETWORK', 'AUTH', 'VALIDATION', 'API_ERROR'
  dwu_error_code VARCHAR(50),
  dwu_retry_after INTEGER, -- Para rate limiting (segundos)
  created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON COLUMN crm_sync_logs.dwu_error_category IS 'Categoria do erro: NETWORK, AUTH, VALIDATION, API_ERROR';
COMMENT ON COLUMN crm_sync_logs.dwu_error_code IS 'Código de erro específico';
COMMENT ON COLUMN crm_sync_logs.dwu_retry_after IS 'Tempo em segundos até poder tentar novamente (rate limiting)';

-- ============================================
-- 7. INTEGRAÇÃO COM DINAMIZE - Autenticação
-- ============================================

CREATE TABLE IF NOT EXISTS crm_auth_tokens (
  dwu_id SERIAL PRIMARY KEY,
  dwu_auth_token TEXT NOT NULL,
  obtained_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP,
  dwu_active BOOLEAN DEFAULT TRUE,
  -- Campos adicionais para suporte a diferentes tipos de autenticação
  dwu_refresh_token TEXT,
  dwu_token_type VARCHAR(20), -- 'JWT', 'OAuth2', 'API_KEY'
  dwu_scope TEXT, -- Permissões do token
  dwu_api_endpoint VARCHAR(200) -- URL base da API
);

COMMENT ON COLUMN crm_auth_tokens.dwu_refresh_token IS 'Refresh token para renovação automática (OAuth2)';
COMMENT ON COLUMN crm_auth_tokens.dwu_token_type IS 'Tipo de autenticação: JWT, OAuth2, API_KEY';
COMMENT ON COLUMN crm_auth_tokens.dwu_scope IS 'Escopo/permissões do token';
COMMENT ON COLUMN crm_auth_tokens.dwu_api_endpoint IS 'URL base da API (ex: https://api.dinamize.com/v1)';

-- ============================================
-- 8. CONFIGURAÇÕES DO SISTEMA
-- ============================================

CREATE TABLE IF NOT EXISTS crm_settings (
  dwu_id SERIAL PRIMARY KEY,
  dwu_key VARCHAR(100) UNIQUE NOT NULL,
  dwu_value TEXT,
  dwu_category VARCHAR(50), -- 'dinamize', 'system', 'integration'
  dwu_encrypted BOOLEAN DEFAULT FALSE,
  dwu_description TEXT,
  updated_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE crm_settings IS 'Configurações gerais do sistema e integrações';
COMMENT ON COLUMN crm_settings.dwu_key IS 'Chave única da configuração';
COMMENT ON COLUMN crm_settings.dwu_value IS 'Valor da configuração (pode ser criptografado)';
COMMENT ON COLUMN crm_settings.dwu_category IS 'Categoria: dinamize, system, integration';
COMMENT ON COLUMN crm_settings.dwu_encrypted IS 'Se o valor está criptografado';

-- ============================================
-- 9. WEBHOOKS E EVENTOS
-- ============================================

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

COMMENT ON TABLE crm_webhook_events IS 'Eventos recebidos via webhook (ex: da Dinamize)';
COMMENT ON COLUMN crm_webhook_events.dwu_event_type IS 'Tipo do evento: lead.created, lead.updated, etc.';
COMMENT ON COLUMN crm_webhook_events.dwu_source IS 'Fonte do webhook: dinamize, manual, etc.';
COMMENT ON COLUMN crm_webhook_events.dwu_payload IS 'Payload completo do webhook';
COMMENT ON COLUMN crm_webhook_events.dwu_processed IS 'Se o evento foi processado';
COMMENT ON COLUMN crm_webhook_events.dwu_processed_at IS 'Quando foi processado';
COMMENT ON COLUMN crm_webhook_events.dwu_error IS 'Erro no processamento (se houver)';

-- ============================================
-- 10. AUDITORIA
-- ============================================

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

COMMENT ON TABLE crm_audit_log IS 'Log de auditoria de todas as ações no sistema';
COMMENT ON COLUMN crm_audit_log.dwu_user_id IS 'ID do usuário que executou a ação';
COMMENT ON COLUMN crm_audit_log.dwu_action IS 'Tipo de ação: CREATE, UPDATE, DELETE, SYNC';
COMMENT ON COLUMN crm_audit_log.dwu_entity_type IS 'Tipo de entidade: lead, contact, opportunity, etc.';
COMMENT ON COLUMN crm_audit_log.dwu_entity_id IS 'ID da entidade afetada';
COMMENT ON COLUMN crm_audit_log.dwu_changes IS 'Dados antes/depois (JSON)';
COMMENT ON COLUMN crm_audit_log.dwu_ip_address IS 'IP de origem da ação';
COMMENT ON COLUMN crm_audit_log.dwu_user_agent IS 'User agent do cliente';

-- ============================================
-- 11. MÓDULO DE INTEGRAÇÃO COM ERP
-- ============================================

CREATE TABLE IF NOT EXISTS erp_integrations (
  dwu_id SERIAL PRIMARY KEY,
  dwu_endpoint VARCHAR(200),
  dwu_entity VARCHAR(50),
  dwu_operation VARCHAR(20),
  dwu_payload JSONB,
  dwu_status VARCHAR(20) DEFAULT 'queued',
  last_sync TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON COLUMN erp_integrations.dwu_entity IS 'cliente | pedido | fatura';
COMMENT ON COLUMN erp_integrations.dwu_operation IS 'send | receive';

-- ============================================
-- 12. CONSTRAINTS ADICIONAIS (Após criar todas as tabelas)
-- ============================================

-- Adicionar constraint de referência para dwu_converted_to_opportunity_id
-- (foi removida da criação da tabela para evitar referência circular)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'fk_crm_leads_converted_to_opportunity'
  ) THEN
    ALTER TABLE crm_leads 
      ADD CONSTRAINT fk_crm_leads_converted_to_opportunity 
      FOREIGN KEY (dwu_converted_to_opportunity_id) 
      REFERENCES crm_opportunities(dwu_id);
  END IF;
END $$;

-- ============================================
-- 13. ÍNDICES PARA MELHORAR PERFORMANCE
-- ============================================

-- Índices para crm_leads
CREATE INDEX IF NOT EXISTS idx_crm_leads_dwu_email ON crm_leads(dwu_email);
CREATE INDEX IF NOT EXISTS idx_crm_leads_dwu_status ON crm_leads(dwu_status);
CREATE INDEX IF NOT EXISTS idx_crm_leads_dwu_converted_to_opportunity_id ON crm_leads(dwu_converted_to_opportunity_id);
CREATE INDEX IF NOT EXISTS idx_crm_leads_dwu_campaign ON crm_leads(dwu_campaign);
CREATE INDEX IF NOT EXISTS idx_crm_leads_dwu_country ON crm_leads(dwu_country);

-- Índices para crm_lead_sync
CREATE INDEX IF NOT EXISTS idx_crm_lead_sync_lead_id ON crm_lead_sync(lead_id);

-- Índices para crm_contacts
CREATE INDEX IF NOT EXISTS idx_crm_contacts_company_id ON crm_contacts(company_id);

-- Índices para crm_interactions
CREATE INDEX IF NOT EXISTS idx_crm_interactions_contact_id ON crm_interactions(contact_id);

-- Índices para crm_stages
CREATE INDEX IF NOT EXISTS idx_crm_stages_pipeline_id ON crm_stages(pipeline_id);

-- Índices para crm_opportunities
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_lead_id ON crm_opportunities(lead_id);
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_company_id ON crm_opportunities(company_id);
CREATE INDEX IF NOT EXISTS idx_crm_opportunities_stage_id ON crm_opportunities(stage_id);

-- Índices para crm_tasks
CREATE INDEX IF NOT EXISTS idx_crm_tasks_related ON crm_tasks(dwu_related_type, dwu_related_id);

-- Índices para crm_sync_queue
CREATE INDEX IF NOT EXISTS idx_crm_sync_queue_dwu_status ON crm_sync_queue(dwu_status);
CREATE INDEX IF NOT EXISTS idx_crm_sync_queue_lead_sync_id ON crm_sync_queue(lead_sync_id);

-- Índices para crm_sync_logs
CREATE INDEX IF NOT EXISTS idx_crm_sync_logs_queue_id ON crm_sync_logs(queue_id);
CREATE INDEX IF NOT EXISTS idx_crm_sync_logs_error_category ON crm_sync_logs(dwu_error_category);
CREATE INDEX IF NOT EXISTS idx_crm_sync_logs_created_at ON crm_sync_logs(created_at DESC);

-- Índices para crm_settings
CREATE INDEX IF NOT EXISTS idx_crm_settings_category ON crm_settings(dwu_category);
CREATE INDEX IF NOT EXISTS idx_crm_settings_key ON crm_settings(dwu_key);

-- Índices para crm_webhook_events
CREATE INDEX IF NOT EXISTS idx_crm_webhook_events_processed ON crm_webhook_events(dwu_processed);
CREATE INDEX IF NOT EXISTS idx_crm_webhook_events_type ON crm_webhook_events(dwu_event_type);
CREATE INDEX IF NOT EXISTS idx_crm_webhook_events_source ON crm_webhook_events(dwu_source);
CREATE INDEX IF NOT EXISTS idx_crm_webhook_events_created_at ON crm_webhook_events(created_at DESC);

-- Índices para crm_audit_log
CREATE INDEX IF NOT EXISTS idx_crm_audit_log_user_id ON crm_audit_log(dwu_user_id);
CREATE INDEX IF NOT EXISTS idx_crm_audit_log_entity ON crm_audit_log(dwu_entity_type, dwu_entity_id);
CREATE INDEX IF NOT EXISTS idx_crm_audit_log_action ON crm_audit_log(dwu_action);
CREATE INDEX IF NOT EXISTS idx_crm_audit_log_created_at ON crm_audit_log(created_at DESC);

-- ============================================
-- 14. CONFIGURAÇÕES INICIAIS
-- ============================================

-- Configurações padrão (valores devem ser ajustados conforme necessário)
INSERT INTO crm_settings (dwu_key, dwu_value, dwu_category, dwu_description) VALUES
  ('dinamize_api_base_url', 'https://api.dinamize.com/v1', 'dinamize', 'URL base da API Dinamize'),
  ('dinamize_rate_limit_per_minute', '60', 'dinamize', 'Limite de requisições por minuto'),
  ('dinamize_rate_limit_per_hour', '1000', 'dinamize', 'Limite de requisições por hora'),
  ('sync_interval_minutes', '15', 'system', 'Intervalo de sincronização automática em minutos'),
  ('sync_batch_size', '100', 'system', 'Tamanho do lote de sincronização'),
  ('sync_max_retries', '3', 'system', 'Número máximo de tentativas de sincronização'),
  ('timezone', 'America/Sao_Paulo', 'system', 'Timezone padrão do sistema'),
  ('encrypt_tokens', 'true', 'system', 'Se tokens devem ser criptografados no banco')
ON CONFLICT (dwu_key) DO NOTHING;

-- ============================================
-- FIM DO SCRIPT
-- ============================================
-- Após executar este script, no pgAdmin 4:
-- 1. Clique com botão direito no banco "dwu_crm_mvp"
-- 2. Selecione "Generate ERD" (ou Tools > Generate ERD)
-- 3. O pgAdmin irá gerar o diagrama visual automaticamente
-- ============================================
