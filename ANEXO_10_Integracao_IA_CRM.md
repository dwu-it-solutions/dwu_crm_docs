# ANEXO 10 - Integração de IA no CRM DWU
## CRM DWU - Especificação Técnica de Funcionalidades Inteligentes

**Data:** 2025-11-06  
**Versão:** 1.0  
**Status:** 📋 Especificação Inicial  
**Equipe Responsável:** Arquitetura e Desenvolvimento

---

## 1. Visão Geral

### 1.1 Objetivo

Integrar funcionalidades de Inteligência Artificial no CRM DWU para:
- Automatizar análises e insights de leads e oportunidades
- Melhorar a experiência do usuário com sugestões inteligentes
- Aumentar a produtividade através de automações inteligentes
- Fornecer previsões e análises preditivas para tomada de decisão

### 1.2 Escopo

Este documento especifica as funcionalidades de IA a serem implementadas no módulo de Leads e Oportunidades, incluindo:
- Scoring e análise de leads
- Sugestões de ações
- Enriquecimento automático de dados
- Geração de conteúdo personalizado
- Análise preditiva de oportunidades
- Chatbot assistente
- Análise de sentimento
- Segmentação automática
- Detecção de padrões
- Automação inteligente de follow-up

### 1.3 Arquitetura Geral

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │  Módulo IA  │    │  Serviços   │
│  (React)    │    │  (Node.js)    │    │             │    │  Externos   │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                    │                  │
       │ 1. Requisição   │                    │                  │
       │    de análise   │                    │                  │
       │─────────────────>│                    │                  │
       │                  │                    │                  │
       │                  │ 2. Buscar dados    │                  │
       │                  │    históricos     │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 3. Processar com   │                  │
       │                  │    IA/ML           │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 4. Chamar serviço  │                  │
       │                  │    externo (LLM)   │                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │                  │ 5. Resposta        │                  │
       │                  │    processada      │                  │
       │                  │<──────────────────────────────────────│
       │                  │                    │                  │
       │                  │ 6. Salvar cache/   │                  │
       │                  │    resultados     │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │ 7. Retornar      │                    │                  │
       │    insights     │                    │                  │
       │<─────────────────│                    │                  │
```

---

## 2. Funcionalidades Detalhadas

### 2.1 Scoring e Análise de Leads

#### 2.1.1 Objetivo
Fornecer um score automático (0-100) que indica a probabilidade de conversão de um lead, baseado em múltiplos fatores históricos e comportamentais.

#### 2.1.2 Fatores de Análise
- **Dados do Lead**: Email (domínio corporativo), empresa, cargo, origem
- **Comportamento**: Tempo desde criação, número de interações, última interação
- **Histórico Similar**: Taxa de conversão de leads similares
- **Dinamize**: Dados de engajamento (abertura de emails, cliques)
- **Pipeline**: Estágio atual, tempo no estágio, progressão

#### 2.1.3 Algoritmo de Scoring
```
Score = (
  Fator_Origem * 0.20 +
  Fator_Qualidade_Dados * 0.15 +
  Fator_Engajamento * 0.25 +
  Fator_Histórico_Similar * 0.20 +
  Fator_Tempo_Resposta * 0.20
)

Classificação:
- 80-100: 🔥 Alto Potencial (Hot Lead)
- 50-79:  ⚠️ Médio Potencial (Warm Lead)
- 0-49:   ❄️ Baixo Potencial (Cold Lead)
```

#### 2.1.4 Endpoints

**GET `/leads/:id/analyze`**
```json
Request: GET /leads/123/analyze

Response: 200 OK
{
  "lead_id": 123,
  "score": 75,
  "classification": "warm",
  "badge": "⚠️ Médio Potencial",
  "factors": {
    "origin": { "value": 85, "weight": 0.20, "reason": "Lead de origem Dinamize" },
    "data_quality": { "value": 70, "weight": 0.15, "reason": "Dados completos" },
    "engagement": { "value": 80, "weight": 0.25, "reason": "3 interações nos últimos 7 dias" },
    "similar_history": { "value": 65, "weight": 0.20, "reason": "Leads similares convertem 65%" },
    "response_time": { "value": 60, "weight": 0.20, "reason": "Resposta média de 2 dias" }
  },
  "insights": [
    "Lead demonstra interesse ativo",
    "Empresa do setor de tecnologia (alta conversão)",
    "Recomendado: follow-up em 24h"
  ],
  "updated_at": "2025-11-06T14:30:00Z"
}
```

**POST `/leads/batch-analyze`**
```json
Request: POST /leads/batch-analyze
{
  "lead_ids": [123, 456, 789],
  "force_refresh": false
}

Response: 200 OK
{
  "results": [
    { "lead_id": 123, "score": 75, "classification": "warm" },
    { "lead_id": 456, "score": 90, "classification": "hot" },
    { "lead_id": 789, "score": 30, "classification": "cold" }
  ],
  "processed_at": "2025-11-06T14:30:00Z"
}
```

#### 2.1.5 Fluxo de Dados

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │  PostgreSQL │    │  Redis      │
│             │    │  (API REST)   │    │             │    │  (Cache)     │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                    │                  │
       │ 1. GET /leads/  │                    │                  │
       │    :id/analyze   │                    │                  │
       │─────────────────>│                    │                  │
       │                  │                    │                  │
       │                  │ 2. Verificar cache│                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │                  │ 3. Cache hit?     │                  │
       │                  │<──────────────────────────────────────│
       │                  │                    │                  │
       │                  │ 4. Se não: Buscar │                  │
       │                  │    dados do lead   │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 5. Buscar histórico│                  │
       │                  │    de leads similares│                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 6. Calcular score │                  │
       │                  │    (algoritmo)     │                  │
       │                  │                    │                  │
       │                  │ 7. Salvar cache    │                  │
       │                  │    (TTL: 1h)       │                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │ 8. Retornar      │                    │                  │
       │    score +       │                    │                  │
       │    insights      │                    │                  │
       │<─────────────────│                    │                  │
```

#### 2.1.6 Implementação Técnica

**Tabela: `crm_lead_scores`**
```sql
CREATE TABLE crm_lead_scores (
  id SERIAL PRIMARY KEY,
  lead_id INTEGER NOT NULL REFERENCES crm_leads(id),
  score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
  classification VARCHAR(20) NOT NULL, -- 'hot', 'warm', 'cold'
  factors JSONB NOT NULL,
  insights TEXT[],
  calculated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL,
  UNIQUE(lead_id)
);

CREATE INDEX idx_lead_scores_lead_id ON crm_lead_scores(lead_id);
CREATE INDEX idx_lead_scores_classification ON crm_lead_scores(classification);
CREATE INDEX idx_lead_scores_expires_at ON crm_lead_scores(expires_at);
```

**Serviço: `LeadScoringService`**
```typescript
class LeadScoringService {
  async calculateScore(leadId: number): Promise<LeadScore> {
    // 1. Buscar dados do lead
    const lead = await this.leadRepository.findById(leadId);
    
    // 2. Calcular fatores
    const factors = {
      origin: await this.calculateOriginFactor(lead),
      dataQuality: await this.calculateDataQualityFactor(lead),
      engagement: await this.calculateEngagementFactor(lead),
      similarHistory: await this.calculateSimilarHistoryFactor(lead),
      responseTime: await this.calculateResponseTimeFactor(lead)
    };
    
    // 3. Calcular score final
    const score = this.computeFinalScore(factors);
    
    // 4. Gerar insights
    const insights = await this.generateInsights(lead, factors, score);
    
    // 5. Salvar e cachear
    return await this.saveScore(leadId, score, factors, insights);
  }
}
```

---

### 2.2 Sugestões de Próximas Ações

#### 2.2.1 Objetivo
Recomendar ações contextuais e oportunas para cada lead/oportunidade, baseado em análise de histórico, estágio atual e padrões de sucesso.

#### 2.2.2 Tipos de Sugestões
- **Follow-up**: "Fazer follow-up em 2 dias" (baseado em tempo médio de resposta)
- **Enviar Proposta**: "Lead está pronto para proposta" (baseado em estágio e score)
- **Agendar Reunião**: "Agendar reunião de descoberta" (baseado em interações)
- **Enviar Material**: "Enviar case de sucesso do setor" (baseado em empresa/segmento)
- **Transferir**: "Transferir para vendedor sênior" (baseado em valor estimado)

#### 2.2.3 Endpoints

**GET `/leads/:id/suggestions`**
```json
Request: GET /leads/123/suggestions

Response: 200 OK
{
  "lead_id": 123,
  "suggestions": [
    {
      "type": "follow_up",
      "priority": "high",
      "title": "Fazer follow-up",
      "description": "Lead demonstrou interesse há 3 dias. Momento ideal para contato.",
      "suggested_date": "2025-11-08T10:00:00Z",
      "action": {
        "type": "create_task",
        "params": {
          "related_type": "lead",
          "related_id": 123,
          "type": "call",
          "description": "Follow-up após demonstração de interesse",
          "due_date": "2025-11-08T10:00:00Z"
        }
      },
      "confidence": 0.85
    },
    {
      "type": "send_proposal",
      "priority": "medium",
      "title": "Enviar proposta comercial",
      "description": "Lead está no estágio de negociação. Score alto (75) indica alta probabilidade de fechamento.",
      "action": {
        "type": "generate_proposal",
        "params": {
          "lead_id": 123,
          "template": "standard"
        }
      },
      "confidence": 0.70
    }
  ],
  "generated_at": "2025-11-06T14:30:00Z"
}
```

**POST `/leads/:id/suggestions/:suggestion_id/execute`**
```json
Request: POST /leads/123/suggestions/1/execute

Response: 200 OK
{
  "suggestion_id": 1,
  "executed": true,
  "result": {
    "type": "task_created",
    "task_id": 456,
    "message": "Tarefa criada com sucesso"
  }
}
```

#### 2.2.4 Fluxo de Dados

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │  PostgreSQL │    │  Serviço IA │
│             │    │  (API REST)   │    │             │    │  (LLM)      │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                    │                  │
       │ 1. GET /leads/  │                    │                  │
       │    :id/suggestions│                    │                  │
       │─────────────────>│                    │                  │
       │                  │                    │                  │
       │                  │ 2. Buscar contexto│                  │
       │                  │    do lead         │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 3. Analisar       │                  │
       │                  │    histórico      │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 4. Gerar sugestões│                  │
       │                  │    com LLM        │                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │                  │ 5. Sugestões     │                  │
       │                  │    contextuais    │                  │
       │                  │<──────────────────────────────────────│
       │                  │                    │                  │
       │ 6. Exibir cards  │                    │                  │
       │    de sugestões  │                    │                  │
       │<─────────────────│                    │                  │
       │                  │                    │                  │
       │ 7. Usuário clica │                    │                  │
       │    "Executar"    │                    │                  │
       │─────────────────>│                    │                  │
       │                  │                    │                  │
       │                  │ 8. Executar ação  │                  │
       │                  │    (criar tarefa, │                  │
       │                  │     gerar email)  │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │ 9. Feedback      │                    │                  │
       │    de sucesso    │                    │                  │
       │<─────────────────│                    │                  │
```

---

### 2.3 Enriquecimento Automático de Dados

#### 2.3.1 Objetivo
Completar automaticamente dados de leads e empresas usando fontes públicas e APIs externas, reduzindo trabalho manual e melhorando qualidade dos dados.

#### 2.3.2 Fontes de Dados
- **Email**: Validação e detecção de domínio corporativo
- **LinkedIn**: Dados profissionais (cargo, empresa, foto)
- **Clearbit/RocketReach**: Enriquecimento de empresas e contatos
- **Google Places**: Dados de localização e empresa
- **WHOIS**: Informações de domínio

#### 2.3.3 Endpoints

**POST `/leads/:id/enrich`**
```json
Request: POST /leads/123/enrich
{
  "sources": ["linkedin", "clearbit", "email_validation"],
  "auto_save": false
}

Response: 200 OK
{
  "lead_id": 123,
  "enrichment": {
    "email_validation": {
      "valid": true,
      "domain": "dwu.com.br",
      "domain_type": "corporate"
    },
    "linkedin": {
      "found": true,
      "profile_url": "https://linkedin.com/in/joao-silva",
      "position": "CEO",
      "company": "DWU Solutions",
      "photo_url": "https://..."
    },
    "clearbit": {
      "company": {
        "name": "DWU Solutions",
        "domain": "dwu.com.br",
        "industry": "Technology",
        "employees": 50,
        "location": "São Paulo, SP"
      }
    }
  },
  "suggested_updates": {
    "name": "João Silva",
    "position": "CEO",
    "company": "DWU Solutions",
    "phone": "+55 11 99999-9999",
    "website": "https://dwu.com.br",
    "industry": "Technology"
  },
  "confidence": 0.92,
  "enriched_at": "2025-11-06T14:30:00Z"
}
```

**POST `/leads/:id/enrich/apply`**
```json
Request: POST /leads/123/enrich/apply
{
  "fields": ["name", "position", "company", "phone"]
}

Response: 200 OK
{
  "lead_id": 123,
  "updated_fields": ["name", "position", "company", "phone"],
  "updated_at": "2025-11-06T14:30:00Z"
}
```

#### 2.3.4 Fluxo de Dados

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌─────────────┐
│  Frontend   │    │   Backend     │    │  PostgreSQL │    │  APIs       │
│             │    │  (API REST)   │    │             │    │  Externas   │
└──────┬──────┘    └──────┬───────┘    └──────┬──────┘    └──────┬──────┘
       │                  │                    │                  │
       │ 1. POST /leads/  │                    │                  │
       │    :id/enrich    │                    │                  │
       │─────────────────>│                    │                  │
       │                  │                    │                  │
       │                  │ 2. Buscar lead    │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │                  │ 3. Validar email  │                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │                  │ 4. Buscar LinkedIn│                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │                  │ 5. Buscar Clearbit│                  │
       │                  │──────────────────────────────────────>│
       │                  │                    │                  │
       │                  │ 6. Consolidar     │                  │
       │                  │    dados          │                  │
       │                  │                    │                  │
       │ 7. Exibir preview│                    │                  │
       │    de dados      │                    │                  │
       │<─────────────────│                    │                  │
       │                  │                    │                  │
       │ 8. Usuário       │                    │                  │
       │    confirma      │                    │                  │
       │─────────────────>│                    │                  │
       │                  │                    │                  │
       │                  │ 9. Aplicar        │                  │
       │                  │    atualizações   │                  │
       │                  │───────────────────>│                  │
       │                  │                    │                  │
       │ 10. Dados        │                    │                  │
       │     atualizados  │                    │                  │
       │<─────────────────│                    │                  │
```

---

### 2.4 Geração de Conteúdo Personalizado

#### 2.4.1 Objetivo
Gerar emails, propostas e notas personalizadas baseadas no contexto do lead/oportunidade, histórico de interações e dados da empresa.

#### 2.4.2 Tipos de Conteúdo
- **Emails**: Follow-up, proposta inicial, agradecimento
- **Propostas**: Comerciais personalizadas
- **Notas**: Resumo de reunião, próximos passos
- **Mensagens**: WhatsApp, SMS

#### 2.4.3 Endpoints

**POST `/ai/generate-email`**
```json
Request: POST /ai/generate-email
{
  "lead_id": 123,
  "type": "follow_up",
  "tone": "professional",
  "context": "Lead demonstrou interesse em produto X após reunião",
  "include_call_to_action": true
}

Response: 200 OK
{
  "email": {
    "subject": "Seguindo sobre nossa conversa - Próximos passos",
    "body": "Olá João,\n\nFoi um prazer conversar com você sobre como nossa solução pode ajudar a DWU Solutions...",
    "suggested_send_date": "2025-11-08T10:00:00Z"
  },
  "alternatives": [
    {
      "tone": "friendly",
      "subject": "Oi João, vamos continuar nossa conversa?",
      "body": "..."
    }
  ],
  "generated_at": "2025-11-06T14:30:00Z"
}
```

**POST `/ai/generate-proposal`**
```json
Request: POST /ai/generate-proposal
{
  "opportunity_id": 456,
  "template": "standard",
  "include_pricing": true,
  "custom_sections": ["implementation", "support"]
}

Response: 200 OK
{
  "proposal": {
    "title": "Proposta Comercial - DWU Solutions",
    "sections": [
      {
        "title": "Resumo Executivo",
        "content": "..."
      },
      {
        "title": "Solução Proposta",
        "content": "..."
      },
      {
        "title": "Investimento",
        "content": "..."
      }
    ],
    "total_value": 50000.00,
    "validity_days": 30
  },
  "generated_at": "2025-11-06T14:30:00Z"
}
```

---

### 2.5 Análise Preditiva de Oportunidades

#### 2.5.1 Objetivo
Prever probabilidade de fechamento, valor estimado e prazo de oportunidades baseado em histórico e padrões similares.

#### 2.5.2 Endpoints

**GET `/opportunities/:id/predict`**
```json
Request: GET /opportunities/456/predict

Response: 200 OK
{
  "opportunity_id": 456,
  "predictions": {
    "win_probability": 0.75,
    "estimated_value": 50000.00,
    "estimated_close_date": "2025-12-15",
    "confidence": 0.82
  },
  "factors": {
    "stage": { "weight": 0.30, "impact": "positive" },
    "time_in_stage": { "weight": 0.20, "impact": "neutral" },
    "similar_history": { "weight": 0.25, "impact": "positive" },
    "engagement": { "weight": 0.25, "impact": "positive" }
  },
  "risk_indicators": [
    "Sem interação há 15 dias",
    "Valor acima da média do pipeline"
  ],
  "recommendations": [
    "Agendar reunião de alinhamento",
    "Enviar material de apoio"
  ],
  "calculated_at": "2025-11-06T14:30:00Z"
}
```

---

### 2.6 Chatbot Assistente

#### 2.6.1 Objetivo
Fornecer assistente conversacional para busca rápida, criação de tarefas e consultas sobre leads/oportunidades.

#### 2.6.2 Comandos Suportados
- "Mostre leads de alto potencial"
- "Crie uma tarefa para o lead X amanhã"
- "Quais oportunidades estão em risco?"
- "Resumo do pipeline de novembro"
- "Lead mais antigo sem contato"

#### 2.6.3 Endpoints

**POST `/ai/chat`**
```json
Request: POST /ai/chat
{
  "message": "Mostre leads de alto potencial",
  "context": {
    "user_id": 1,
    "current_page": "/leads"
  }
}

Response: 200 OK
{
  "response": "Encontrei 5 leads de alto potencial:\n\n1. João Silva (DWU Solutions) - Score: 90\n2. Maria Santos (Tech Corp) - Score: 85\n...",
  "actions": [
    {
      "type": "navigate",
      "url": "/leads?filter=high_potential"
    },
    {
      "type": "show_list",
      "data": [...]
    }
  ],
  "suggestions": [
    "Ver detalhes do lead João Silva",
    "Criar tarefa de follow-up"
  ]
}
```

---

### 2.7 Análise de Sentimento

#### 2.7.1 Objetivo
Detectar tom e sentimento em interações (emails, chamadas, notas) para identificar leads em risco ou oportunidades de upsell.

#### 2.7.2 Endpoints

**POST `/interactions/:id/analyze-sentiment`**
```json
Request: POST /interactions/789/analyze-sentiment

Response: 200 OK
{
  "interaction_id": 789,
  "sentiment": {
    "overall": "positive",
    "score": 0.75,
    "emotions": {
      "joy": 0.60,
      "trust": 0.70,
      "fear": 0.10,
      "anger": 0.05
    }
  },
  "key_phrases": [
    "muito interessado",
    "gostaria de agendar",
    "solução perfeita"
  ],
  "risk_level": "low",
  "recommendations": [
    "Lead demonstra alto interesse",
    "Recomendado: enviar proposta"
  ],
  "analyzed_at": "2025-11-06T14:30:00Z"
}
```

---

### 2.8 Segmentação Automática

#### 2.8.1 Objetivo
Agrupar leads automaticamente por perfil, comportamento ou características similares para campanhas direcionadas.

#### 2.8.2 Endpoints

**POST `/leads/segment`**
```json
Request: POST /leads/segment
{
  "criteria": ["industry", "score", "behavior"],
  "auto_create_tags": true
}

Response: 200 OK
{
  "segments": [
    {
      "id": "segment_1",
      "name": "Tech Companies - High Score",
      "lead_count": 25,
      "characteristics": {
        "industry": "Technology",
        "score_range": [70, 100],
        "avg_conversion_rate": 0.65
      },
      "tags": ["tech", "high-potential"],
      "created_at": "2025-11-06T14:30:00Z"
    }
  ],
  "total_segments": 5,
  "segmented_at": "2025-11-06T14:30:00Z"
}
```

---

### 2.9 Detecção de Padrões e Anomalias

#### 2.9.1 Objetivo
Identificar padrões de sucesso e alertar sobre anomalias que podem indicar problemas ou oportunidades.

#### 2.9.2 Endpoints

**GET `/ai/insights`**
```json
Request: GET /ai/insights?period=30d

Response: 200 OK
{
  "insights": [
    {
      "type": "pattern",
      "title": "Leads de origem Dinamize convertem 40% mais",
      "description": "Análise dos últimos 30 dias mostra que leads da Dinamize têm taxa de conversão de 65% vs 25% de outras origens",
      "confidence": 0.92,
      "recommendation": "Aumentar investimento em captação via Dinamize"
    },
    {
      "type": "anomaly",
      "title": "Oportunidade parada há 45 dias",
      "description": "Oportunidade #456 está no estágio 'Negociação' há 45 dias, acima da média de 15 dias",
      "severity": "high",
      "action_required": true
    }
  ],
  "generated_at": "2025-11-06T14:30:00Z"
}
```

---

### 2.10 Automação Inteligente de Follow-up

#### 2.10.1 Objetivo
Criar tarefas de follow-up automaticamente baseado em análise de momento ideal, aprendendo com histórico de sucesso.

#### 2.10.2 Endpoints

**POST `/leads/:id/auto-followup`**
```json
Request: POST /leads/123/auto-followup
{
  "enabled": true,
  "preferences": {
    "min_interval_days": 2,
    "max_interval_days": 7
  }
}

Response: 200 OK
{
  "lead_id": 123,
  "auto_followup_enabled": true,
  "next_suggested_date": "2025-11-08T10:00:00Z",
  "reason": "Baseado em histórico: leads similares respondem melhor após 2 dias",
  "created_at": "2025-11-06T14:30:00Z"
}
```

---

## 3. Estrutura de Dados

### 3.1 Tabelas Adicionais

**Tabela: `crm_lead_scores`**
```sql
CREATE TABLE crm_lead_scores (
  id SERIAL PRIMARY KEY,
  lead_id INTEGER NOT NULL REFERENCES crm_leads(id) ON DELETE CASCADE,
  score INTEGER NOT NULL CHECK (score >= 0 AND score <= 100),
  classification VARCHAR(20) NOT NULL CHECK (classification IN ('hot', 'warm', 'cold')),
  factors JSONB NOT NULL,
  insights TEXT[],
  calculated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(lead_id)
);
```

**Tabela: `crm_ai_suggestions`**
```sql
CREATE TABLE crm_ai_suggestions (
  id SERIAL PRIMARY KEY,
  related_type VARCHAR(20) NOT NULL CHECK (related_type IN ('lead', 'opportunity')),
  related_id INTEGER NOT NULL,
  type VARCHAR(50) NOT NULL,
  priority VARCHAR(20) NOT NULL CHECK (priority IN ('low', 'medium', 'high')),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  action JSONB NOT NULL,
  confidence DECIMAL(3,2) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  executed BOOLEAN NOT NULL DEFAULT FALSE,
  executed_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL
);
```

**Tabela: `crm_ai_enrichments`**
```sql
CREATE TABLE crm_ai_enrichments (
  id SERIAL PRIMARY KEY,
  lead_id INTEGER NOT NULL REFERENCES crm_leads(id) ON DELETE CASCADE,
  source VARCHAR(50) NOT NULL,
  data JSONB NOT NULL,
  confidence DECIMAL(3,2) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  applied BOOLEAN NOT NULL DEFAULT FALSE,
  applied_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**Tabela: `crm_ai_predictions`**
```sql
CREATE TABLE crm_ai_predictions (
  id SERIAL PRIMARY KEY,
  opportunity_id INTEGER NOT NULL REFERENCES crm_opportunities(id) ON DELETE CASCADE,
  win_probability DECIMAL(3,2) NOT NULL CHECK (win_probability >= 0 AND win_probability <= 1),
  estimated_value DECIMAL(10,2),
  estimated_close_date DATE,
  confidence DECIMAL(3,2) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  factors JSONB NOT NULL,
  risk_indicators TEXT[],
  recommendations TEXT[],
  calculated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMP NOT NULL,
  UNIQUE(opportunity_id)
);
```

**Tabela: `crm_ai_segments`**
```sql
CREATE TABLE crm_ai_segments (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  criteria JSONB NOT NULL,
  lead_count INTEGER NOT NULL DEFAULT 0,
  characteristics JSONB,
  tags TEXT[],
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**Tabela: `crm_ai_chat_history`**
```sql
CREATE TABLE crm_ai_chat_history (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES crm_users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  response TEXT NOT NULL,
  context JSONB,
  actions JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

---

## 4. Integração com Serviços Externos

### 4.1 OpenAI / LLM
- **Uso**: Geração de conteúdo, análise de texto, sugestões contextuais
- **Endpoints**: `/v1/chat/completions`, `/v1/embeddings`
- **Rate Limits**: Gerenciar via Redis com throttling

### 4.2 Clearbit / RocketReach
- **Uso**: Enriquecimento de dados de empresas e contatos
- **Rate Limits**: Cachear resultados por 30 dias

### 4.3 LinkedIn API
- **Uso**: Busca de perfis profissionais
- **Autenticação**: OAuth 2.0

---

## 5. Performance e Cache

### 5.1 Estratégia de Cache
- **Redis**: Cache de scores, sugestões, enriquecimentos
- **TTL**: 
  - Scores: 1 hora
  - Sugestões: 30 minutos
  - Enriquecimentos: 30 dias
  - Previsões: 6 horas

### 5.2 Processamento Assíncrono
- **BullMQ**: Jobs pesados (análise em lote, segmentação)
- **Workers**: Processamento em background

---

## 6. Segurança e Privacidade

### 6.1 Dados Sensíveis
- Não enviar dados pessoais sensíveis para APIs externas sem consentimento
- Anonimizar dados em análises agregadas
- Logs não devem conter informações pessoais

### 6.2 Rate Limiting
- Limitar requisições de IA por usuário
- Implementar throttling para APIs externas
- Monitorar custos de API

---

## 7. Roadmap de Implementação

### Fase 1 - MVP (4 semanas)
1. ✅ Scoring de Leads (básico)
2. ✅ Sugestões de Ações (regras simples)
3. ✅ Enriquecimento de Dados (email validation + Clearbit)

### Fase 2 - Intermediário (6 semanas)
4. ✅ Geração de Conteúdo (emails)
5. ✅ Análise Preditiva (modelo básico)
6. ✅ Chatbot (comandos simples)

### Fase 3 - Avançado (8 semanas)
7. ✅ Análise de Sentimento
8. ✅ Segmentação Automática
9. ✅ Detecção de Padrões
10. ✅ Automação Inteligente

---

## 8. Métricas de Sucesso

### 8.1 KPIs
- **Adoção**: % de usuários usando funcionalidades de IA
- **Precisão**: Acurácia de previsões e sugestões
- **Produtividade**: Redução de tempo em tarefas manuais
- **Conversão**: Aumento na taxa de conversão de leads

### 8.2 Monitoramento
- Tempo de resposta das APIs de IA
- Taxa de erro em gerações
- Custo por requisição
- Satisfação do usuário (feedback)

---

**Status:** 📋 Especificação Inicial - Aguardando Aprovação  
**Próximos Passos:** Revisão técnica, definição de stack, prototipagem MVP

