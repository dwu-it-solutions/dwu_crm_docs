# ANEXO 18 - Implementação Dinamize com Redis
## CRM DWU - Documentação Técnica da Integração

**Data:** 2025-01-XX  
**Versão:** 1.0  
**Status:** ✅ Implementado

---

## 📋 Sumário Executivo

Este documento descreve a implementação completa da integração com API Dinamize utilizando Redis para rate limiting, cache de tokens e filas de processamento assíncrono com BullMQ. A solução foi projetada para suportar picos de tráfego como Black Friday.

---

## 1. Arquitetura da Solução

### 1.1 Componentes Principais

```
┌─────────────┐
│  Frontend   │
└──────┬──────┘
       │
       │ HTTP/REST
       │
┌──────▼──────────────────────────────────────┐
│         Backend NestJS                       │
│  ┌──────────────────────────────────────┐   │
│  │   DinamizeModule                     │   │
│  │  ┌────────────────────────────────┐  │   │
│  │  │ DinamizeContactsService       │  │   │
│  │  │ DinamizeAuthService            │  │   │
│  │  │ DinamizeSyncService            │  │   │
│  │  └────────────────────────────────┘  │   │
│  │  ┌────────────────────────────────┐  │   │
│  │  │ RateLimiterService (Redis)     │  │   │
│  │  │ TokenCacheService (Redis)       │  │   │
│  │  └────────────────────────────────┘  │   │
│  │  ┌────────────────────────────────┐  │   │
│  │  │ DinamizeApiClient              │  │   │
│  │  └────────────────────────────────┘  │   │
│  └──────────────────────────────────────┘   │
│  ┌──────────────────────────────────────┐   │
│  │ BullMQ Queue (Redis)                 │   │
│  │  └─ DinamizeSyncProcessor            │   │
│  └──────────────────────────────────────┘   │
└──────┬───────────────────────────────────────┘
       │
       ├──────────────┬──────────────┬──────────────┐
       │              │              │              │
┌──────▼──────┐ ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐
│ PostgreSQL  │ │   Redis   │ │  Dinamize │ │   Redis   │
│             │ │  (Cache)  │ │    API    │ │  (Queue)  │
└─────────────┘ └───────────┘ └───────────┘ └───────────┘
```

### 1.2 Fluxo de Autenticação

```
1. Requisição → DinamizeAuthService
2. Verificar cache Redis (TokenCacheService)
3. Se não encontrado, verificar PostgreSQL (crm_auth_tokens)
4. Se expirado, fazer nova autenticação
5. Armazenar token criptografado em PostgreSQL
6. Armazenar token descriptografado em Redis (cache)
7. Retornar token para uso
```

### 1.3 Fluxo de Sincronização

```
1. Criar/Atualizar Lead no CRM
2. Criar LeadSync (status: pending)
3. Criar SyncQueue (status: queued)
4. Adicionar job ao BullMQ
5. Worker processa job assincronamente
6. Atualizar status (processing → synced/failed)
7. Atualizar LeadSync com resultado
```

---

## 2. Estrutura de Arquivos

```
src/
├── dinamize/
│   ├── dinamize.module.ts
│   ├── config/
│   │   └── dinamize.config.ts
│   ├── interfaces/
│   │   └── dinamize-response.interface.ts
│   ├── dto/
│   │   ├── search-contacts-dinamize.dto.ts
│   │   ├── create-contact-dinamize.dto.ts
│   │   ├── update-contact-dinamize.dto.ts
│   │   └── sync-lead.dto.ts
│   ├── auth/
│   │   ├── dinamize-auth.service.ts
│   │   ├── token-manager.service.ts
│   │   ├── token-cache.service.ts
│   │   └── encryption.service.ts
│   ├── client/
│   │   ├── dinamize-api.client.ts
│   │   └── rate-limiter.service.ts
│   ├── contacts/
│   │   ├── dinamize-contacts.service.ts
│   │   └── dinamize-contacts.controller.ts
│   ├── sync/
│   │   ├── dinamize-sync.service.ts
│   │   ├── dinamize-sync.controller.ts
│   │   └── dinamize-sync.processor.ts
│   └── exceptions/
│       └── dinamize.exceptions.ts
├── redis/
│   └── redis.module.ts
└── config/
    └── redis.config.ts
```

---

## 3. Configuração

### 3.1 Variáveis de Ambiente

```env
# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0
REDIS_KEY_PREFIX=dwu_crm:
REDIS_TTL=3600

# Dinamize
DINAMIZE_API_BASE_URL=https://api.dinamize.com
DINAMIZE_API_USER=seu-email@exemplo.com
DINAMIZE_API_PASSWORD=sua-senha
DINAMIZE_CLIENT_CODE=300001
DINAMIZE_TOKEN_EXPIRY_INACTIVITY_MINUTES=60
DINAMIZE_TOKEN_MAX_AGE_HOURS=24
DINAMIZE_TOKEN_RENEW_BEFORE_MINUTES=5
DINAMIZE_RATE_LIMIT_PER_MINUTE=60
DINAMIZE_REQUEST_TIMEOUT=20000

# Segurança
ENCRYPT_TOKEN_KEY=sua-chave-secreta-32-caracteres
ENCRYPT_TOKEN_ALGORITHM=AES-256-GCM
```

### 3.2 Docker Compose (Redis)

```yaml
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  redis_data:
```

---

## 4. Serviços Principais

### 4.1 DinamizeAuthService

**Responsabilidades:**
- Autenticação com API Dinamize
- Gerenciamento de tokens
- Integração com cache Redis e PostgreSQL

**Métodos principais:**
- `authenticate(companyId)`: Obtém token válido (cache ou nova autenticação)

### 4.2 RateLimiterService

**Responsabilidades:**
- Rate limiting distribuído usando Redis
- Sliding window log algorithm
- Tratamento de rate limit excedido

**Características:**
- Limite: 60 requisições por minuto
- Distribuído: funciona com múltiplas instâncias
- Fail-open: permite requisição se Redis falhar

### 4.3 TokenCacheService

**Responsabilidades:**
- Cache de tokens em Redis
- TTL automático (1 hora)
- Invalidação de tokens

### 4.4 DinamizeSyncService

**Responsabilidades:**
- Enfileirar sincronizações
- Criar registros em `crm_sync_queue`
- Adicionar jobs ao BullMQ

### 4.5 DinamizeSyncProcessor

**Responsabilidades:**
- Processar jobs da fila
- Sincronizar leads com Dinamize
- Atualizar status de sincronização
- Retry automático (3 tentativas)

---

## 5. Endpoints da API

### 5.1 Contatos Dinamize

#### POST `/api/dinamize/contacts/search`
Buscar contatos na Dinamize

**Body:**
```json
{
  "contact-list_code": "1",
  "page_number": 1,
  "page_size": 10,
  "status_contact": "NO_REST",
  "search": [
    {
      "field": "email",
      "operator": "=",
      "value": "contato@exemplo.com"
    }
  ]
}
```

#### POST `/api/dinamize/contacts`
Criar contato na Dinamize

**Body:**
```json
{
  "email": "novo@exemplo.com",
  "name": "Novo Contato",
  "contact-list_code": "1",
  "custom_fields": {
    "cmp4": "valor1"
  }
}
```

#### GET `/api/dinamize/contacts/:contactCode?listCode=1`
Obter contato específico

#### POST `/api/dinamize/contacts/:contactCode/update`
Atualizar contato

#### POST `/api/dinamize/contacts/:contactCode/delete?listCode=1`
Deletar contato

---

## 6. Rate Limiting

### 6.1 Estratégia

- **Algoritmo:** Sliding Window Log
- **Limite:** 60 requisições por minuto
- **Armazenamento:** Redis (distribuído)
- **Comportamento:** Fail-open (permite se Redis falhar)

### 6.2 Implementação

```typescript
// Usa Redis Sorted Set (ZSET)
// Chave: rate_limit:dinamize:{companyId}
// Score: timestamp
// Value: timestamp-random

1. Remover timestamps antigos (último minuto)
2. Contar requisições no window
3. Se >= limite, calcular tempo de espera
4. Adicionar timestamp atual
5. Definir TTL de 60 segundos
```

### 6.3 Tratamento de Rate Limit Excedido

Quando Dinamize retorna código `240024`:
1. Extrair `retry-after` da resposta
2. Bloquear requisições por X segundos
3. Aguardar antes de retry
4. Logar evento para monitoramento

---

## 7. Cache de Tokens

### 7.1 Estratégia de Cache

**Camadas:**
1. **Redis (cache rápido):** Token descriptografado, TTL 1h
2. **PostgreSQL (persistência):** Token criptografado, permanente

**Fluxo:**
1. Buscar no Redis primeiro
2. Se não encontrado, buscar no PostgreSQL
3. Se encontrado no PostgreSQL, armazenar no Redis
4. Se expirado, fazer nova autenticação

### 7.2 Criptografia

- **Algoritmo:** AES-256-GCM
- **Armazenamento:** PostgreSQL (criptografado)
- **Cache:** Redis (descriptografado, TTL curto)
- **Chave:** Variável de ambiente `ENCRYPT_TOKEN_KEY`

---

## 8. Fila de Sincronização (BullMQ)

### 8.1 Configuração

```typescript
@Processor('dinamize-sync', {
  concurrency: 5, // 5 jobs simultâneos
  limiter: {
    max: 60, // Máximo 60 jobs/minuto
    duration: 60000
  }
})
```

### 8.2 Retry Strategy

- **Tentativas:** 3
- **Backoff:** Exponencial (5s, 10s, 20s)
- **Remoção:** Jobs completos após 1h, falhas após 24h

### 8.3 Status da Fila

- `queued`: Aguardando processamento
- `processing`: Em processamento
- `completed`: Concluído com sucesso
- `failed`: Falha permanente (após 3 tentativas)

---

## 9. Tratamento de Erros

### 9.1 Códigos de Erro Dinamize

| Código | Descrição | Ação |
|--------|-----------|------|
| `480001` | Success | Continuar |
| `240002` | Password is required | Erro de configuração |
| `240003` | Username is required | Erro de configuração |
| `240004` | Username or password invalid | Credenciais inválidas |
| `240024` | Rate limit exceeded | Aguardar retry-after |
| `240029` | Client code invalid | Erro de configuração |

### 9.2 Exceções Customizadas

- `DinamizeAuthenticationError`: Erro de autenticação
- `DinamizeRateLimitError`: Rate limit excedido
- `DinamizeApiError`: Erro genérico da API

---

## 10. Monitoramento

### 10.1 Métricas Importantes

- Taxa de sucesso de autenticação
- Taxa de rate limit excedido
- Tempo médio de processamento de jobs
- Taxa de falha de sincronização
- Uso de cache Redis

### 10.2 Logs

Todos os serviços utilizam `Logger` do NestJS:
- Autenticação: Log de obtenção/renovação de tokens
- Rate Limiter: Log de bloqueios e esperas
- Sync Processor: Log de processamento e erros

---

## 11. Testes

### 11.1 Testes Unitários

- `rate-limiter.service.spec.ts`: Testes de rate limiting
- `encryption.service.spec.ts`: Testes de criptografia

### 11.2 Como Executar

```bash
npm test
npm test -- --watch
npm test -- --coverage
```

---

## 12. Próximos Passos

### 12.1 Melhorias Futuras

- [ ] Dashboard BullMQ para monitoramento de filas
- [ ] Métricas Prometheus
- [ ] Alertas para rate limit excedido
- [ ] Testes de integração com API Dinamize real
- [ ] Documentação de webhooks (quando disponível)

### 12.2 Integração com Módulo de Leads

- [ ] Integrar criação de lead com sincronização automática
- [ ] Implementar sincronização incremental (cron job)
- [ ] Criar endpoint para sincronização manual

---

## 13. Referências

- **Documentação Dinamize:** https://panel.dinamize.com/apidoc/
- **BullMQ:** https://docs.bullmq.io/
- **ioredis:** https://github.com/redis/ioredis
- **ANEXO_01:** Levantamento Técnico Dinamize API
- **ANEXO_03:** Autenticação e Segurança Dinamize

---

**Última atualização:** 2025-01-XX  
**Responsável:** Equipe DWU CRM  
**Versão:** 1.0

