# 📚 Índice da Documentação - CRM DWU (Integração Dinamize)

**Última atualização:** 2025-11-06  
**Versão:** 1.3

---

## 🎯 Navegação Rápida

| Documento | Finalidade | Status |
|-----------|-----------|--------|
| [📄 Documento Principal](#documento-principal) | Visão geral e status | ✅ Completo |
| [📋 Anexos Técnicos](#anexos-tecnicos) | Especificações detalhadas | ✅ 4/6 completos |
| [📝 Guias Práticos](#guias-praticos) | Como fazer análises | ✅ Completo |
| [💡 Anotações](#anotacoes) | Decisões e insights | 🔄 Em andamento |
| [🗄️ Banco de Dados](#banco-de-dados) | Scripts SQL | ✅ Completo |
| [⚙️ Configuração](#configuracao) | Regras do projeto | ✅ Completo |

---

## 📄 Documento Principal

### 📘 LEVANTAMENTO_TECNICO_DINAMIZE_API.md
**Status:** ✅ Completo  
**Última atualização:** 2025-11-05  
**O que contém:**
- Status geral do projeto (Mês 1)
- Resumo dos 3 tópicos principais:
  1. Levantamento técnico de integração
  2. Estrutura de dados (Lead, Contato, Empresa, Oportunidade)
  3. Autenticação e segurança
- Checklists de tarefas concluídas e pendentes
- Referências para anexos específicos

**Quando usar:** Visão geral do projeto e status atual

---

## 📋 Anexos Técnicos

### ✅ ANEXO_01_Levantamento_Tecnico_Dinamize_API.md
**Status:** ✅ Completo  
**O que contém:**
- URL base e documentação da API
- Características técnicas (HTTPS, POST, JSON, UTF-8)
- Endpoints mapeados:
  - POST /auth (autenticação)
  - POST /emkt/contact/* (contatos/leads)
- Estrutura de requisições e respostas
- Códigos de erro detalhados
- Rate limiting (60 req/min)
- Formato de data/hora
- Escopo de integração (Mês 1 vs Futuro)

**Quando usar:** Referência técnica para implementação da API

---

### ✅ ANEXO_02_Estrutura_Dados_CRM.md
**Status:** ✅ Completo  
**Versão:** 1.1 (atualizado 2025-11-05)  
**O que contém:**
- **Seção 0: Convenções de Nomenclatura** (NOVA!)
  - Justificativa técnica: `crm_*` (tabelas) vs `dwu_*` (colunas)
  - Análise de padrões da indústria (Oracle, SAP, Dynamics, Salesforce)
  - Roadmap de domínios futuros (finance_, hr_, erp_)
  - Exemplos comparativos e cenários de escalabilidade
- Estrutura completa do banco de dados
- Tabelas principais:
  - crm_leads
  - crm_contacts
  - crm_companies
  - crm_opportunities
- Tabelas de integração:
  - crm_lead_sync
  - crm_sync_queue
  - crm_sync_logs (BIGSERIAL)
  - crm_auth_tokens
  - crm_settings
  - crm_webhook_events (BIGSERIAL)
  - crm_audit_log (BIGSERIAL)
- **Decisão SERIAL vs BIGSERIAL** (Seção 2.8)
- **Padronização de FKs** (dwu_[entidade]_id)
- Relacionamentos entre tabelas
- Campos JSONB para dados flexíveis
- Índices e otimizações
- Mapeamento Dinamize → CRM

**Quando usar:** Referência para estrutura do banco de dados  
**Destaques v1.1:** 
- Nomenclatura justificada tecnicamente
- BIGSERIAL em tabelas de alto volume
- FKs padronizadas com entidade explícita

---

### ✅ ANEXO_03_Autenticacao_Seguranca_Dinamize.md
**Status:** ✅ Completo  
**O que contém:**
- Método de autenticação (Token customizado)
- Fluxo de autenticação
- Expiração de tokens (1h inatividade, 24h máximo)
- Estratégias de renovação
- Segurança:
  - Criptografia de tokens
  - LGPD e proteção de dados
  - Auditoria
- Códigos de erro de autenticação

**Quando usar:** Implementar módulo de autenticação

---

### ✅ ANEXO_04_Analise_Tecnologia_Backend.md
**Status:** ✅ Completo  
**O que contém:**
- Análise de tecnologias backend
- Recomendações de stack
- Estrutura modular
- Padrões de código

**Quando usar:** Decisões de arquitetura backend

---

### ✅ ANEXO_05_Backend_Modulo_Leads.md
**Status:** ✅ Completo  
**Data:** 2025-11-06  
**O que contém:**
- Visão geral do módulo de leads
- Entidades principais (crm_leads, crm_lead_sync, crm_sync_queue)
- Fluxos de dados completos:
  - Criar lead com sincronização Dinamize
  - Buscar/listar leads
  - Atualizar lead existente
  - Sincronização automática Dinamize → CRM
  - Converter lead em oportunidade
  - Importação CSV
  - Pipeline Kanban
  - Gestão de empresas e contatos
  - Tarefas e interações
- Tratamento de erros e retry
- Estrutura de dados detalhada

**Quando usar:** Implementação do backend do módulo de leads

---

### ✅ ANEXO_06_Frontend_Modulo_Leads.md
**Status:** ✅ Completo  
**Data:** 2025-11-06  
**O que contém:**
- Rotas e telas do módulo de leads
- Fluxos do usuário detalhados
- Componentes principais
- Critérios de aceite
- Integração com backend (alinhado ao ANEXO_05)

**Quando usar:** Implementação do frontend do módulo de leads

---

### 📝 ANEXO_05_Help_Dinamize_Insights.md
**Status:** 📝 Template criado (aguardando preenchimento)  
**O que vai conter:**
- Conceitos de negócio (date_rest, optout, spam)
- Tipos de listas (estáticas, dinâmicas, segmentadas)
- Campos customizados (tipos, limitações)
- Melhores práticas de importação
- Estratégias de sincronização bidirecional
- Tratamento de duplicatas
- Webhooks (se disponível)
- Automações disponíveis
- Métricas via API
- Requisitos de LGPD
- Troubleshooting comum

**Quando usar:** Entender conceitos de negócio e uso prático  
**Fonte:** https://help.dinamize.com/

---

---

### ✅ ANEXO_07_Guia_Pratico_Integracao_API.md
**Status:** 📝 Em desenvolvimento  
**Data:** 2025-11-05  
**O que contém:**
- **Guia prático** de integração com API Dinamize
- **Tutoriais e exemplos** extraídos do help.dinamize.com
- **Melhores práticas** de implementação
- **Casos de uso comuns** e troubleshooting
- **Campos customizados** (cmp4, cmp5, etc.)
- **Webhooks** (se disponíveis)
- **Performance e otimização**

**Quando usar:**
- Implementação prática de integração
- Resolução de problemas de integração
- Referência de exemplos de código

---

### ✅ ANEXO_08_Decisao_Tecnica_Autenticacao_JWT.md
**Status:** ✅ Completo  
**Data:** 2025-11-05  
**O que contém:**
- **Decisão:** JWT DIY (implementação própria)
- **Análise comparativa completa:**
  - JWT DIY vs Auth0 vs OAuth2 Lite vs Keycloak
- **Justificativas técnicas:**
  - ✅ Independência total (zero dependência externa)
  - ✅ Performance superior (2-4x mais rápido)
  - ✅ Custo previsível (R$ 20k fixo em 5 anos)
  - ✅ Controle total (dados on-premise, LGPD)
  - ✅ Permissões granulares completas (RBAC)
- **Comparações detalhadas:**
  - Dependência externa
  - Performance (latência, throughput)
  - Integração (Dinamize, ERPs)
  - Custo (5 anos, por cenário)
  - Permissões granulares (implementação)
- **Plano de implementação:** 4 fases (120h total)
- **Riscos e mitigações**
- **Métricas de sucesso**

**Quando usar:** 
- Referência para decisão de autenticação
- Onboarding de novos desenvolvedores
- Revisões de arquitetura
- Comunicação com stakeholders

**Arquitetura escolhida:**
```
Frontend ─JWT─> Backend CRM ─Token Prop─> Dinamize
                     ↓ JWT + Scopes
                 ERPs/Sistemas
```

---

### ✅ ANEXO_09_Decisao_Tecnica_Git_Flow_GitHub.md
**Status:** ✅ Completo (Objetivo e Sucinto)
**Data:** 2025-11-05  
**O que contém:**
- **Decisões finais:**
  - ✅ Multirepo (6 repositórios GitHub separados)
  - ✅ GitLab Flow (metodologia branch = ambiente)
  - ✅ Semantic Versioning independente por repo
  - ✅ 3 Ambientes: development → staging → main
  - ✅ Deploy independente e isolado
- **Estrutura multirepo:**
  - dwu_crm_backend, frontend, mobile
  - dwu_crm_shared (npm privado)
  - dwu_crm_database, docs
- **Justificativa:** Controle, isolamento, segurança
- **Código compartilhado:** @dwu/crm-shared (GitHub Packages)
- **Versionamento:** Independente (backend v1.2.0, frontend v1.1.5)
- **Ambientes:** 3 portas (3001, 3002, 3000)

**Quando usar:**
- Setup inicial dos repositórios
- Decisões de versionamento
- Estratégia de deploy

---

### ✅ ANEXO_10_Integracao_IA_CRM.md
**Status:** ✅ Especificação Inicial
**Data:** 2025-11-06  
**O que contém:**
- **10 Funcionalidades de IA especificadas:**
  1. Scoring e Análise de Leads (score 0-100, classificação hot/warm/cold)
  2. Sugestões de Próximas Ações (follow-up, proposta, reunião)
  3. Enriquecimento Automático de Dados (LinkedIn, Clearbit, validação)
  4. Geração de Conteúdo Personalizado (emails, propostas, notas)
  5. Análise Preditiva de Oportunidades (probabilidade de fechamento)
  6. Chatbot Assistente (busca e comandos conversacionais)
  7. Análise de Sentimento (em interações)
  8. Segmentação Automática (agrupamento de leads)
  9. Detecção de Padrões e Anomalias (insights automáticos)
  10. Automação Inteligente de Follow-up
- **Arquitetura técnica:** Integração com LLM, APIs externas, cache Redis
- **Estrutura de dados:** Tabelas para scores, sugestões, enriquecimentos, previsões
- **Endpoints REST:** Especificação completa de APIs
- **Fluxos de dados:** Diagramas detalhados
- **Roadmap:** 3 fases de implementação (MVP → Avançado)
- **Segurança e privacidade:** LGPD, rate limiting, anonimização

**Quando usar:**
- Planejamento de funcionalidades de IA
- Implementação de features inteligentes
- Decisões de arquitetura de IA/ML
- Integração com serviços externos (OpenAI, Clearbit, etc.)

---

### ✅ ANEXO_11_Decisao_Tecnica_Design_System.md
**Status:** ✅ Decisão Aprovada
**Data:** 2025-11-06  
**O que contém:**
- **Decisão:** Material UI (MUI) como design system principal
- **Análise comparativa detalhada:**
  - Integração com React (nativo vs wrapper)
  - Componentes para CRM (DataGrid, DatePicker, etc.)
  - Design System e consistência (Material Design)
  - Produtividade com Cursor AI (autocomplete e sugestões)
  - Customização e branding (sistema de temas)
  - Performance (bundle size, otimizações)
  - Curva de aprendizado
  - Manutenibilidade e escalabilidade
- **Tabela comparativa:** 8 critérios avaliados (MUI vence em 6)
- **Justificativa técnica:** Por que MUI é ideal para CRM
- **Plano de implementação:** 3 fases (Setup → Componentes → Telas)
- **Recursos e documentação:** Links e guias
- **Considerações e mitigações:** Desafios e soluções

**Quando usar:**
- Decisão de design system para frontend
- Justificativa técnica para stakeholders
- Setup inicial do projeto React
- Referência para customização de temas
- Onboarding de novos desenvolvedores

---

### ✅ MANUAL_GIT_FLOW.md
**Status:** ✅ Completo  
**Data:** 2025-11-05  
**O que contém:**
- **Guia prático diário** para desenvolvedores
- **Setup inicial:** Clone, configuração, branches
- **Workflows por módulo:**
  - Backend (features, migrations, testes)
  - Frontend (componentes, páginas, build)
  - Mobile (screens, navegação, build)
- **Processo de release completo:**
  - Pré-release checklist
  - Deploy em staging (RC)
  - Deploy em produção (tag)
  - Pós-release
- **Hotfix urgente:** Fluxo passo-a-passo
- **Convenções:**
  - Nomenclatura de branches
  - Formato de commits
  - Template de PR
- **Comandos úteis:** Git diário
- **Troubleshooting:** Conflitos, erros comuns
- **Checklist diário:** Antes de começar, antes de PR

**Quando usar:**
- Dia a dia de desenvolvimento
- Dúvida sobre fluxo Git
- Como fazer release
- Como fazer hotfix
- Referência rápida de comandos

---

## 📝 Guias Práticos

### 📋 GUIA_ANALISE_API_INTEGRACOES.md
**Status:** ✅ Completo  
**Localização:** `CRM - Dinamize/Anotações/`  
**O que contém:**
- Checklist estruturado para análise
- Perguntas-chave para responder
- Template de anotação
- Priorização de artigos
- Checklist pós-análise
- Dicas de análise
- Tempo estimado: 2-3h

**Quando usar:** Durante análise da seção API e Integrações do help.dinamize.com  
**Como usar:** Abrir lado a lado com o navegador, usar como checklist

---

### 📊 COMPARACAO_DOCUMENTACAO_ATUAL_VS_API_INTEGRACOES.md
**Status:** ✅ Completo  
**O que contém:**
- Comparação visual: O que temos vs O que podemos ganhar
- Análise detalhada por tema:
  - Autenticação
  - Campos customizados
  - Sincronização
  - Webhooks
  - Rate limiting
  - Validações
  - Casos de uso
  - Troubleshooting
  - Segurança
- Gaps priorizados
- Checklist de decisões bloqueadas
- Estimativa de valor (ROI) da análise
- Recomendação final

**Quando usar:** Para entender POR QUE fazer a análise antes de implementar  
**Insight principal:** 3-4h de análise economizam DIAS de implementação

---

## 💡 Anotações

### 📝 20250411.md
**Status:** Histórico  
**Conteúdo:** Anotações de 11/04/2025

---

### 📝 20251105_analise_help_dinamize.md
**Status:** 🔄 Em andamento  
**O que contém:**
- Decisão: Vale a pena analisar help.dinamize.com?
- Resposta: SIM, alto valor agregado
- Checklist de análise por prioridade:
  - 🔴 Alta: Campos customizados, webhooks, duplicatas, limitações
  - 🟡 Média: Conceitos, importação, métricas, LGPD
  - 🟢 Baixa: Automações, segmentação, outras integrações
- Impacto esperado no projeto
- Próximos passos (3 fases)
- Status: ✅ Documentos criados, aguardando análise

**Quando usar:** Acompanhar progresso da análise

---

### 📝 anotacoes.txt
**Status:** Histórico  
**Conteúdo:** Anotações gerais anteriores

---

## 🗄️ Banco de Dados

### 💾 dwu_crm_mvp_import_pgadmin.sql
**Status:** ✅ Completo  
**Localização:** Raiz do projeto  
**O que contém:**
- Script completo de criação do banco
- Todas as tabelas com constraints
- Índices
- Comentários explicativos
- Pronto para importar no PostgreSQL

**Como usar:**
```sql
-- No pgAdmin ou psql:
\i dwu_crm_mvp_import_pgadmin.sql
```

**Principais tabelas:**
- ✅ crm_leads (leads/prospects)
- ✅ crm_contacts (contatos convertidos)
- ✅ crm_companies (empresas)
- ✅ crm_opportunities (oportunidades)
- ✅ crm_lead_sync (mapeamento CRM ↔ Dinamize)
- ✅ crm_sync_queue (fila de sincronização)
- ✅ crm_sync_logs (logs de erros)
- ✅ crm_auth_tokens (tokens de autenticação)
- ✅ crm_settings (configurações)
- ✅ crm_webhook_events (eventos de webhooks)
- ✅ crm_audit_log (auditoria)

---

## ⚙️ Configuração

### ⚙️ .cursorrules
**Status:** ✅ Completo  
**Localização:** Raiz do projeto  
**O que contém:**
- Contexto do projeto
- Idioma: SEMPRE Português (pt-BR)
- Padrões de banco de dados:
  - Nomenclatura (crm_*, dwu_*)
  - Campos obrigatórios
  - JSONB para dados flexíveis
  - Índices
- Segurança e autenticação Dinamize
- Integração (endpoints, rate limiting, sincronização)
- Padrões de código
- Estrutura de arquivos recomendada
- Boas práticas (Git, SQL, Performance, Testes)
- Fluxos principais
- Validações importantes
- Prioridades (Mês 1)
- Observações especiais da API Dinamize
- Convenções adicionais (variáveis de ambiente, status, códigos de erro)

**Quando usar:** O Cursor AI usa automaticamente em todas as interações

---

## 🎯 Fluxo de Uso da Documentação

### Para ANÁLISE (agora):
1. Ler **COMPARACAO_DOCUMENTACAO_ATUAL_VS_API_INTEGRACOES.md** (entender o valor)
2. Abrir **GUIA_ANALISE_API_INTEGRACOES.md** como checklist
3. Navegar https://help.dinamize.com/tag?s=API%2520Integra%25C3%25A7%25C3%25B5es
4. Preencher **ANEXO_07** durante navegação
5. Navegar https://help.dinamize.com/ (geral)
6. Preencher **ANEXO_05** com conceitos de negócio
7. Atualizar outros anexos conforme necessário

### Para IMPLEMENTAÇÃO (depois):
1. **ANEXO_01** → Especificação técnica da API
2. **ANEXO_07** → Exemplos de código práticos
3. **ANEXO_03** → Implementar autenticação
4. **ANEXO_02** + **dwu_crm_mvp_import_pgadmin.sql** → Estrutura do banco
5. **ANEXO_05** → Entender regras de negócio
6. **.cursorrules** → Seguir padrões do projeto

### Para TROUBLESHOOTING:
1. **ANEXO_07** → Seção de troubleshooting
2. **ANEXO_01** → Códigos de erro
3. **ANEXO_05** → Conceitos e comportamentos esperados

---

## 📊 Status Geral da Documentação

### ✅ Pronto para uso (14 documentos)
- LEVANTAMENTO_TECNICO_DINAMIZE_API.md
- ANEXO_01 (Levantamento Técnico API Dinamize)
- ANEXO_02 (Estrutura de Dados v1.1) - Atualizado 2025-11-05
- ANEXO_03 (Autenticação Dinamize v1.1) - Atualizado 2025-11-05
- ANEXO_04 (Análise Tecnologia Backend)
- ANEXO_05 (Backend Módulo Leads) ✨ NOVO 2025-11-06
- ANEXO_06 (Frontend Módulo Leads) ✨ NOVO 2025-11-06
- ANEXO_07 (Guia Prático Integração API) 📝 Em desenvolvimento
- ANEXO_08 (Decisão JWT DIY) ✨ NOVO 2025-11-05
- ANEXO_09 (Git Flow + GitHub) ✨ NOVO 2025-11-05
- ANEXO_10 (Integração IA CRM) ✨ NOVO 2025-11-06
- ANEXO_11 (Decisão Design System) ✨ NOVO 2025-11-06
- MANUAL_GIT_FLOW.md ✨ NOVO 2025-11-05
- GUIA_ANALISE_API_INTEGRACOES.md
- COMPARACAO_DOCUMENTACAO_ATUAL_VS_API_INTEGRACOES.md
- .cursorrules (atualizado)
- dwu_crm_mvp_import_pgadmin.sql

### 📝 Templates criados, aguardando preenchimento (1 documento)
- ANEXO_07 (Guia Prático Integração API) - Preencher após análise help.dinamize.com

### 🔄 Em andamento (1 documento)
- 20251105_analise_help_dinamize.md (acompanhamento)

---

## 🚀 Próximas Ações

### Fase 1: Análise (ATUAL)
- [ ] Analisar https://help.dinamize.com/tag?s=API%2520Integra%25C3%25A7%25C3%25B5es
- [ ] Preencher ANEXO_07
- [ ] Analisar https://help.dinamize.com/ (geral)
- [ ] Preencher ANEXO_05
- [ ] Atualizar ANEXO_01, 02, 03 se necessário

### Fase 2: Ajustes (DEPOIS DA ANÁLISE)
- [ ] Revisar e ajustar .cursorrules com novos insights
- [ ] Ajustar estrutura do banco se necessário (campos customizados!)
- [ ] Atualizar LEVANTAMENTO_TECNICO_DINAMIZE_API.md
- [ ] Criar lista priorizada de tarefas de implementação

### Fase 3: Implementação (FUTURO)
- [ ] Módulo de autenticação
- [ ] Módulo de sincronização
- [ ] Sistema de filas
- [ ] Rate limiter
- [ ] Webhooks (se disponível)
- [ ] Testes

---

## 📞 Suporte e Recursos

### Links Úteis
- **API Técnica:** https://panel.dinamize.com/apidoc/
- **Help Geral:** https://help.dinamize.com/
- **API e Integrações:** https://help.dinamize.com/tag?s=API%2520Integra%25C3%25A7%25C3%25B5es

### Dúvidas Frequentes

**Q: Por onde começar a ler?**  
A: Comece por este índice, depois COMPARACAO_DOCUMENTACAO_ATUAL_VS_API_INTEGRACOES.md

**Q: Qual documento tem o código SQL?**  
A: dwu_crm_mvp_import_pgadmin.sql (na raiz do projeto)

**Q: Onde está a especificação da API?**  
A: ANEXO_01_Levantamento_Tecnico_Dinamize_API.md

**Q: Onde vou encontrar exemplos de código?**  
A: ANEXO_07 (após preencher com análise do help)

**Q: Preciso ler tudo antes de implementar?**  
A: Não! Mas PRECISA preencher ANEXO_05 e ANEXO_06 antes de começar a codificar.

---

## 📝 Histórico de Versões

### v1.3 - 2025-11-06
- ✅ Renumerados anexos: ANEXO_06→07 (Guia), ANEXO_07→08 (JWT), ANEXO_08→09 (Git Flow), ANEXO_09→10 (IA), ANEXO_10→11 (Design System)
- ✅ Atualizado índice com numeração correta
- ✅ Removido arquivo duplicado ANEXO_05_Backend_Modulo_Leads 1.md
- ✅ Atualizadas referências internas nos arquivos renumerados

### v1.2 - 2025-11-06
- ✅ Adicionado ANEXO_11 (Decisão Técnica Design System - Material UI vs Bootstrap)
- ✅ Atualizado índice com novo documento

### v1.1 - 2025-11-06
- ✅ Adicionado ANEXO_05 (Backend Módulo Leads)
- ✅ Adicionado ANEXO_06 (Frontend Módulo Leads)
- ✅ Adicionado ANEXO_10 (Integração IA CRM)
- ✅ Atualizado índice com novos documentos

### v1.0 - 2025-11-05
- ✅ Criação do índice
- ✅ Todos os anexos principais criados
- ✅ Templates de análise prontos
- ✅ Banco de dados estruturado
- ✅ .cursorrules configurado
- 📝 Aguardando: Análise do help.dinamize.com

---

**Mantido por:** Equipe DWU CRM  
**Última revisão:** 2025-11-06  
**Próxima revisão:** Após análise completa do help.dinamize.com

