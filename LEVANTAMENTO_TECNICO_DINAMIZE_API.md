# Levantamento Técnico - Integração Dinamize API
## CRM DWU - Mês 1: Estrutura Base + Integração com Dinamize

**Data:** 2025-01-04  
**Versão:** 1.0  
**Status:** Em desenvolvimento

---

## 📋 Sumário

Este documento apresenta o levantamento técnico realizado para integração do CRM DWU com a API Dinamize, organizado pelos três tópicos principais do Mês 1.

---

## 1️⃣ Levantamento Técnico de Integração com Dinamize (Documentação e Escopos)

### 📝 Comentário: O que fizemos
- ✅ Acessamos e analisamos a documentação completa da API Dinamize disponível em https://panel.dinamize.com/apidoc/
- ✅ Mapeamos todos os endpoints principais necessários (autenticação, contatos, listas)
- ✅ Identificamos o método de autenticação utilizado (Token customizado via `/auth`)
- ✅ Documentamos limites de rate limiting (60 requisições por minuto)
- ✅ Extraímos informações sobre formato de dados, códigos de erro e estrutura de respostas
- ✅ Criamos mapeamento inicial de campos Dinamize → CRM
- ✅ Identificamos que a API usa apenas método POST e sempre retorna HTTP 200 (validar campo `code`)

### 📝 Comentário: O que precisa ser feito
- [ ] Validar endpoints com requisições de teste usando credenciais reais
- [ ] Completar mapeamento de campos customizados (cmp4, cmp5, etc.)
- [ ] Verificar com suporte Dinamize sobre disponibilidade de webhooks
- [ ] Testar fluxo completo de autenticação (login, uso, expiração)
- [ ] Validar rate limiting com testes de carga controlada
- [ ] Documentar endpoints de listas de marketing que ainda não foram detalhados
- [ ] Criar casos de teste para cada endpoint identificado
- [ ] Definir estratégia de tratamento de erros e retry

**Anexo:** Ver `ANEXO_01_Levantamento_Tecnico_Dinamize_API.md`

### 📝 Complemento: Documentação de Ajuda Dinamize
- [ ] Analisar documentação em https://help.dinamize.com/
- [ ] Extrair casos de uso e melhores práticas
- [ ] Documentar conceitos de negócio (date_rest, optout, spam)
- [ ] Verificar disponibilidade de webhooks
- [ ] Mapear campos customizados (cmp4, cmp5, etc.)
- [ ] Entender regras de duplicatas e merge

**Anexo:** Ver `ANEXO_05_Help_Dinamize_Insights.md` (em desenvolvimento)

---

## 2️⃣ Definição da Estrutura de Dados (Lead, Contato, Empresa, Oportunidade)

### 📝 Comentário: O que fizemos
- ✅ Revisamos e consolidamos a estrutura do banco de dados em um único arquivo SQL (`dwu_crm_mvp_import_pgadmin.sql`)
- ✅ Validamos que todas as tabelas principais estão criadas (crm_leads, crm_contacts, crm_companies, crm_opportunities)
- ✅ Adicionamos campos necessários para integração Dinamize (dwu_country, dwu_city, dwu_state, dwu_address, dwu_company_name, dwu_website, dwu_campaign, etc.)
- ✅ Criamos tabelas de integração (crm_lead_sync, crm_sync_queue, crm_auth_tokens, crm_settings, crm_webhook_events, crm_audit_log)
- ✅ Implementamos campo JSONB (dwu_source_data) para armazenar dados extras da Dinamize
- ✅ Criamos mapeamento inicial de campos Dinamize → campos do banco de dados
- ✅ Adicionamos campos de rastreamento de erros e sincronização (last_successful_sync, sync_error_count, last_error_message)

### 📝 Comentário: O que precisa ser feito
- [ ] Validar estrutura do banco de dados executando o script completo no ambiente de desenvolvimento
- [ ] Criar diagrama ER atualizado incluindo todas as tabelas de integração
- [ ] Documentar relacionamentos entre entidades (leads, contatos, empresas, oportunidades)
- [ ] Definir estratégia completa de sincronização (quais campos, quando, como)
- [ ] Documentar tratamento de campos customizados da Dinamize (cmp4, cmp5, etc.)
- [ ] Criar scripts de validação de integridade referencial
- [ ] Definir regras de negócio para conversão de lead em oportunidade
- [ ] Mapear campos customizados da Dinamize para estrutura do CRM
- [ ] Criar índices adicionais para otimização de consultas

### 📝 Comentário: Atualizações Recentes
- ✅ **2025-11-05:** BIGSERIAL aplicado em tabelas de alto volume (logs, auditoria)
- ✅ Seção 2.8 adicionada com decisão SERIAL vs BIGSERIAL

**Anexo:** Ver `ANEXO_02_Estrutura_Dados_CRM.md` (v1.1)

---

## 3️⃣ Autenticação e Segurança (JWT ou OAuth)

### 📝 Comentário: O que fizemos
- ✅ Identificamos o método de autenticação utilizado pela Dinamize (Token customizado, não JWT/OAuth)
- ✅ Documentamos o fluxo completo de autenticação (endpoint `/auth`, formato de requisição/resposta)
- ✅ Estrutura do banco preparada com campos necessários (crm_auth_tokens com dwu_refresh_token, dwu_token_type, dwu_scope, dwu_api_endpoint)
- ✅ Identificamos regras de expiração de token (1h inatividade, 24h máximo)
- ✅ Documentamos códigos de erro de autenticação e estratégias de tratamento
- ✅ Identificamos que não há endpoint de refresh token na documentação (necessário verificar ou fazer nova autenticação)

### 📝 Comentário: O que precisa ser feito
- [ ] Implementar serviço de autenticação Dinamize no backend (DinamizeAuthService)
- [ ] Criar TokenManager para gerenciar ciclo de vida dos tokens (obtenção, validação, renovação)
- [ ] Implementar criptografia de tokens antes de armazenar no banco (usar biblioteca de criptografia)
- [ ] Criar middleware de autenticação para validar tokens antes das requisições
- [ ] Implementar renovação automática de tokens (verificar se Dinamize suporta refresh ou se precisa nova autenticação)
- [ ] Testar cenários de expiração e tratamento de erros (1h inatividade, 24h máximo)
- [ ] Criar logs de auditoria para operações de autenticação (usar crm_audit_log)
- [ ] Implementar rotação de chaves de criptografia
- [ ] Criar sistema de monitoramento de tokens próximos da expiração
- [ ] Implementar cache de tokens para evitar requisições desnecessárias

**Anexo:** Ver `ANEXO_03_Autenticacao_Seguranca_Dinamize.md`

---

## 📊 Status Geral do Projeto

### Concluído ✅
- Levantamento técnico da API Dinamize
- Mapeamento de endpoints principais
- Estrutura de banco de dados consolidada
- Identificação de método de autenticação
- Documentação de rate limiting
- Mapeamento inicial de campos Dinamize → CRM

### Em Andamento 🔄
- Validação de endpoints com testes reais
- Documentação completa de mapeamento de campos
- Definição de estratégia de sincronização
- Planejamento de implementação de serviços

### Pendente ⏳
- Implementação de serviços no backend
- Testes de integração
- Validação com credenciais reais
- Implementação de criptografia de tokens
- Criação de diagramas ER atualizados

---

## 📝 Observações Gerais

### Dependências Identificadas
- API Dinamize utiliza apenas método POST
- Formato de dados: JSON com charset UTF-8
- Rate limiting: 60 requisições por minuto
- Timeout: 20 segundos por requisição
- Token customizado (não JWT/OAuth padrão)

### Riscos e Mitigações
- **Risco:** Token pode expirar durante operação
  - **Mitigação:** Implementar renovação proativa antes da expiração
  
- **Risco:** Rate limiting pode bloquear sincronizações
  - **Mitigação:** Implementar fila de requisições com tratamento de retry-after

- **Risco:** Dados podem estar desatualizados
  - **Mitigação:** Implementar sincronização incremental baseada em `insert_date`

- **Risco:** Não há endpoint de refresh token identificado
  - **Mitigação:** Implementar nova autenticação automática quando token expirar

---

**Próxima Revisão:** Após validação de endpoints com testes reais  
**Responsável:** Equipe DWU CRM  
**Última atualização:** 2025-01-XX
