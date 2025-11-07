# ANEXO 03 - Autenticação e Segurança com Dinamize
## CRM DWU - Integração com API Dinamize (Token Proprietário)

**Data:** 2025-11-05  
**Versão:** 1.1  
**Status:** ✅ Método Identificado - ⏳ Implementação Pendente

---

## ⚠️ Escopo deste Documento

**Este documento trata EXCLUSIVAMENTE da autenticação Backend CRM ↔ API Dinamize**

```
┌─────────────┐           ┌──────────────┐          ┌──────────────┐
│  Frontend   │───JWT────→│ Backend CRM  │──Token──→│  Dinamize    │
│             │ (ANEXO_08)│              │  Prop.   │    API       │
└─────────────┘           └──────────────┘ (ANEXO_03)└──────────────┘
```

### **Divisão de Responsabilidades:**

| Documento | Escopo | Método |
|-----------|--------|--------|
| **ANEXO_08** | Frontend ↔ Backend CRM | JWT DIY |
| **ANEXO_03** | Backend CRM ↔ Dinamize | Token Proprietário |

**Ver ANEXO_08** para decisão técnica sobre autenticação de usuários do CRM.

---

## 📋 Sumário Executivo

Este anexo apresenta a estratégia de autenticação e segurança **especificamente para integração com a API Dinamize**, incluindo fluxo de autenticação com Token Proprietário, gerenciamento via TokenManager e implementação de segurança.

**Importante:** A Dinamize **impõe** o uso de Token Proprietário. Não há escolha de método de autenticação nesta camada.

---

## 1. Método de Autenticação Identificado

### 1.1 Tipo de Autenticação
- **Token customizado** (não é JWT ou OAuth2 padrão)
- Token obtido via endpoint `/auth`
- Token incluído no header `auth-token` em todas as requisições subsequentes
- Não utiliza padrões OAuth2 ou JWT

### 1.2 Características do Token

| Característica | Valor | Observações |
|----------------|-------|-------------|
| **Expiração por inatividade** | 1 hora | Token expira se não houver requisições por 1 hora |
| **Tempo máximo ativo** | 24 horas | Token não pode permanecer ativo por mais de 24 horas |
| **Formato** | String customizada | `#.######.##.##########################` |
| **Header** | `auth-token` | Não é `Authorization: Bearer` |
| **Refresh token** | Não identificado | Não encontrado endpoint de refresh na documentação |

### 1.3 Diferenças em relação a JWT/OAuth2

**Não é JWT:**
- Token não está no formato JWT (header.payload.signature)
- Não contém informações decodificáveis

**Não é OAuth2:**
- Não há fluxo de autorização completo
- Não há endpoint de refresh token identificado
- Não há escopos OAuth2 padrão

**É Token Customizado:**
- Token simples retornado pela API
- Gerenciado diretamente pela Dinamize
- Requer nova autenticação quando expira

---

## 2. Fluxo de Autenticação

### 2.1 Fluxo Completo

```
┌─────────────┐                    ┌──────────────┐                    ┌─────────────┐
│   Cliente   │                    │   API DWU    │                    │ Dinamize API│
└──────┬──────┘                    └──────┬──────┘                    └──────┬──────┘
       │                                    │                                    │
       │ 1. Requisição de autenticação      │                                    │
       │───────────────────────────────────>│                                    │
       │                                    │                                    │
       │                                    │ 2. POST /auth                      │
       │                                    │ {user, password, client_code}      │
       │                                    │───────────────────────────────────>│
       │                                    │                                    │
       │                                    │ 3. Resposta com auth-token         │
       │                                    │<───────────────────────────────────│
       │                                    │                                    │
       │                                    │ 4. Armazenar token criptografado   │
       │                                    │    em crm_auth_tokens              │
       │                                    │                                    │
       │ 5. Resposta (sucesso/erro)         │                                    │
       │<───────────────────────────────────│                                    │
       │                                    │                                    │
       │ 6. Requisições subsequentes        │                                    │
       │    com auth-token no header        │                                    │
       │───────────────────────────────────>│ 7. Validar token e fazer requisição│
       │                                    │───────────────────────────────────>│
       │                                    │                                    │
       │                                    │ 8. Resposta da Dinamize            │
       │                                    │<───────────────────────────────────│
       │                                    │                                    │
       │ 9. Resposta processada             │                                    │
       │<───────────────────────────────────│                                    │
```

### 2.2 Endpoint de Autenticação

**URL:** `https://api.dinamize.com/auth`  
**Método:** `POST`

**Headers:**
```
Content-Type: application/json; charset=utf-8
```

**Body:**
```json
{
  "user": "user@test.com",
  "password": "password",
  "client_code": "300001"
}
```

**Resposta de Sucesso:**
```json
{
  "code": "480001",
  "code_detail": "Success",
  "body": {
    "auth-token": "#.######.##.##########################",
    "manager": true
  },
  "request_unique": "######",
  "warning": []
}
```

**Códigos de Erro:**
- `240002`: Password is required
- `240003`: Username is required
- `240004`: Username or password are invalid
- `240029`: Client code is invalid

### 2.3 Uso do Token

**Em todas as requisições subsequentes:**
```
Headers:
  auth-token: #.######.##.##########################
  Content-Type: application/json; charset=utf-8
```

**Validação:**
- Token deve ser validado antes de cada requisição
- Se expirado, realizar nova autenticação automaticamente
- Verificar se token está ativo em `crm_auth_tokens.dwu_active`

---

## 3. Estrutura de Armazenamento

### 3.1 Tabela crm_auth_tokens

**Objetivo:** Armazenar tokens de autenticação de forma segura

**Campos:**

| Campo | Tipo | Descrição | Observações |
|-------|------|-----------|-------------|
| `dwu_id` | SERIAL | ID interno (PK) | - |
| `dwu_auth_token` | TEXT | Token de acesso | **Criptografado antes de armazenar** |
| `dwu_refresh_token` | TEXT | Refresh token | Se disponível, também criptografado |
| `dwu_token_type` | VARCHAR(20) | Tipo de token | 'TOKEN_CUSTOM', 'JWT', 'OAuth2', 'API_KEY' |
| `dwu_scope` | TEXT | Escopo/permissões | Permissões do token |
| `dwu_api_endpoint` | VARCHAR(200) | URL base da API | 'https://api.dinamize.com' |
| `obtained_at` | TIMESTAMP | Data de obtenção | Para controle de expiração |
| `expires_at` | TIMESTAMP | Data de expiração | Calculada: obtained_at + 1h ou 24h |
| `dwu_active` | BOOLEAN | Se está ativo | Para revogação manual |

**Exemplo de Registro:**
```sql
INSERT INTO crm_auth_tokens (
  dwu_auth_token,
  dwu_token_type,
  dwu_api_endpoint,
  obtained_at,
  expires_at,
  dwu_active
) VALUES (
  'encrypted_token_here',  -- Token criptografado
  'TOKEN_CUSTOM',
  'https://api.dinamize.com',
  NOW(),
  NOW() + INTERVAL '1 hour',
  TRUE
);
```

### 3.2 Segurança de Tokens

#### Criptografia
- ✅ Tokens devem ser **criptografados** antes de armazenar no banco
- ✅ Usar biblioteca de criptografia (ex: AES-256)
- ✅ Campo `dwu_encrypted` em `crm_settings` para controlar criptografia
- ⏳ Implementar rotação de chaves de criptografia

#### Boas Práticas
- Nunca logar tokens em texto plano
- Não expor tokens em URLs ou logs
- Validar token antes de cada requisição
- Implementar revogação manual de tokens (via `dwu_active`)

#### Armazenamento
- Tokens criptografados no banco de dados
- Chave de criptografia em variável de ambiente (não no código)
- Backup de chaves de criptografia em local seguro

---

## 4. Gerenciamento de Tokens

### 4.1 Ciclo de Vida do Token

```
1. Obtenção
   └─> Autenticação via /auth
   └─> Armazenar token criptografado
   └─> Registrar obtained_at e expires_at

2. Uso
   └─> Validar token antes de cada requisição
   └─> Verificar se não expirou
   └─> Verificar se está ativo (dwu_active = TRUE)

3. Renovação
   └─> Verificar se próximo da expiração (ex: 5 minutos antes)
   └─> Fazer nova autenticação automaticamente
   └─> Atualizar token no banco

4. Expiração
   └─> Token expira por inatividade (1h) ou tempo máximo (24h)
   └─> Requer nova autenticação
   └─> Marcar token como inativo
```

### 4.2 Validação de Token

**Antes de cada requisição:**
1. Buscar token ativo mais recente
2. Verificar se `dwu_active = TRUE`
3. Verificar se `expires_at > NOW()`
4. Verificar se `obtained_at > NOW() - INTERVAL '24 hours'`
5. Se válido, usar token
6. Se inválido/expirado, fazer nova autenticação

**Pseudocódigo:**
```javascript
function getValidToken() {
  const token = getLatestActiveToken();
  
  if (!token || !token.dwu_active) {
    return authenticate();
  }
  
  const now = new Date();
  const expiresAt = new Date(token.expires_at);
  const obtainedAt = new Date(token.obtained_at);
  const maxAge = new Date(obtainedAt.getTime() + 24 * 60 * 60 * 1000);
  
  // Verificar expiração por inatividade (1h)
  if (expiresAt <= now) {
    return authenticate();
  }
  
  // Verificar expiração por tempo máximo (24h)
  if (maxAge <= now) {
    return authenticate();
  }
  
  // Verificar se próximo da expiração (renovar proativamente)
  const timeUntilExpiry = expiresAt - now;
  if (timeUntilExpiry < 5 * 60 * 1000) { // 5 minutos
    return authenticate(); // Renovar proativamente
  }
  
  return decryptToken(token.dwu_auth_token);
}
```

### 4.3 Renovação Automática

**Estratégia:**
- Verificar token antes de cada requisição
- Se próximo da expiração (ex: 5 minutos), renovar proativamente
- Fazer nova autenticação automaticamente
- Atualizar token no banco de dados

**Benefícios:**
- Evita falhas por token expirado
- Transparente para o usuário
- Mantém sincronização ativa

---

## 5. Códigos de Erro

### 5.1 Tabela de Códigos

| Código | Descrição | Ação Recomendada |
|--------|-----------|------------------|
| `240002` | Password is required | Validar envio de senha no body |
| `240003` | Username is required | Validar envio de usuário no body |
| `240004` | Username or password are invalid | Retentar com credenciais corretas ou verificar credenciais |
| `240029` | Client code is invalid | Validar código do cliente ou verificar relacionamento usuário-cliente |

### 5.2 Tratamento de Erros

**Estratégia:**
1. Capturar erro na resposta
2. Verificar código de erro
3. Logar erro para análise
4. Retentar com backoff exponencial (se aplicável)
5. Notificar administrador em caso de erros críticos

**Exemplo:**
```javascript
if (response.code !== '480001') {
  logError(response.code, response.code_detail);
  
  if (response.code === '240004') {
    // Credenciais inválidas - não retentar automaticamente
    throw new AuthenticationError('Credenciais inválidas');
  }
  
  if (response.code === '240029') {
    // Código de cliente inválido - verificar configuração
    throw new ConfigurationError('Código de cliente inválido');
  }
}
```

---

## 6. Implementação Proposta

### 6.1 Serviços Necessários

#### DinamizeAuthService
**Responsabilidades:**
- Autenticação inicial
- Obtenção de token
- Armazenamento seguro de token
- Validação de credenciais

#### TokenManager
**Responsabilidades:**
- Gerenciar ciclo de vida dos tokens
- Validação de tokens
- Renovação automática
- Cache de tokens

#### EncryptionService
**Responsabilidades:**
- Criptografar tokens antes de armazenar
- Descriptografar tokens para uso
- Rotação de chaves de criptografia

#### AuthMiddleware
**Responsabilidades:**
- Validar token antes de requisições
- Interceptar requisições e adicionar token
- Tratar expiração de token

### 6.2 Funcionalidades a Implementar

- [ ] **Autenticação inicial**
  - Endpoint para autenticar usuário
  - Obter token da Dinamize
  - Armazenar token criptografado

- [ ] **Renovação automática de tokens**
  - Verificar expiração antes de cada requisição
  - Renovar proativamente (5 min antes)
  - Atualizar token no banco

- [ ] **Validação de token**
  - Middleware para validar antes de requisições
  - Verificar expiração e status
  - Tratar token inválido/expirado

- [ ] **Criptografia de tokens**
  - Criptografar antes de armazenar
  - Descriptografar para uso
  - Gerenciar chaves de criptografia

- [ ] **Logs de auditoria**
  - Registrar todas as operações de autenticação
  - Logar tentativas de autenticação
  - Logar renovações de token

- [ ] **Monitoramento**
  - Alertas para tokens próximos da expiração
  - Dashboard de status de autenticação
  - Métricas de uso de tokens

### 6.3 Estrutura de Arquivos Proposta

```
backend/
├── src/
│   ├── modules/
│   │   ├── dinamize/
│   │   │   ├── auth/
│   │   │   │   ├── dinamize-auth.service.ts
│   │   │   │   ├── dinamize-auth.controller.ts
│   │   │   │   ├── token-manager.ts
│   │   │   │   └── encryption.service.ts
│   │   │   └── dinamize-api.client.ts
│   └── common/
│       └── middleware/
│           └── auth.middleware.ts
```

---

## 7. Variáveis de Ambiente

### 7.1 Configurações Necessárias

```env
# Dinamize API
DINAMIZE_API_BASE_URL=https://api.dinamize.com
DINAMIZE_API_USER=user@test.com
DINAMIZE_API_PASSWORD=password
DINAMIZE_CLIENT_CODE=300001

# Autenticação
DINAMIZE_AUTH_TYPE=TOKEN_CUSTOM
DINAMIZE_TOKEN_EXPIRY_INACTIVITY_MINUTES=60
DINAMIZE_TOKEN_MAX_AGE_HOURS=24
DINAMIZE_TOKEN_RENEW_BEFORE_MINUTES=5

# Segurança
ENCRYPT_TOKEN_KEY=your_encryption_key_here
ENCRYPT_TOKEN_ALGORITHM=AES-256-GCM

# Timezone
APP_TIMEZONE=America/Sao_Paulo
```

---

## 8. Próximos Passos

### 8.1 Implementação
1. Criar DinamizeAuthService com autenticação inicial
2. Implementar TokenManager com renovação automática
3. Criar EncryptionService para criptografia de tokens
4. Implementar AuthMiddleware para validação
5. Criar endpoints para gerenciar autenticação

### 8.2 Testes
1. Testar autenticação com credenciais válidas
2. Testar autenticação com credenciais inválidas
3. Testar renovação automática de tokens
4. Testar tratamento de expiração
5. Testar criptografia/descriptografia

### 8.3 Validações
1. Validar fluxo completo de autenticação
2. Validar segurança de tokens
3. Validar tratamento de erros
4. Validar logs de auditoria

---

## 9. Riscos e Mitigações

### 9.1 Riscos Identificados

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Token expira durante operação | Alta | Médio | Renovação proativa antes da expiração |
| Não há endpoint de refresh | Alta | Médio | Implementar nova autenticação automática |
| Token comprometido | Baixa | Alto | Criptografia, logs de auditoria, revogação |
| Chave de criptografia perdida | Baixa | Crítico | Backup seguro de chaves, rotação |

### 9.2 Plano de Contingência

- **Token expirado:** Renovar automaticamente
- **Credenciais inválidas:** Notificar administrador
- **Falha de autenticação:** Retentar com backoff exponencial
- **Token comprometido:** Revogar imediatamente e gerar novo

---

## 10. Referências

- **Endpoint de Autenticação:** `POST /auth`
- **URL Base:** `https://api.dinamize.com`
- **Documentação:** `https://panel.dinamize.com/apidoc/`
- **Tabela de Tokens:** `crm_auth_tokens`

---

**Última atualização:** 2025-01-XX  
**Responsável:** Equipe DWU CRM  
**Versão:** 1.0


