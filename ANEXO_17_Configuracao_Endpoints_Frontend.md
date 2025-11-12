# ANEXO 17 - Configuração de Endpoints e Variáveis de Ambiente - Frontend

**Data:** 2025-11-12  
**Versão:** 1.0  
**Status:** ✅ Completo

## Objetivo

Documentar a estrutura de configuração centralizada de endpoints e variáveis de ambiente no frontend, garantindo separação por ambiente e facilidade de manutenção.

---

## 1. Estrutura de Arquivos

### 1.1 Arquivos de Configuração

```
dwu_crm_frontend/
├── .env                    # Variáveis locais (não versionado)
├── .env.example            # Template para outros desenvolvedores
└── src/
    └── config/
        └── env.ts          # Configuração centralizada type-safe
```

### 1.2 Variáveis de Ambiente

**`.env` (desenvolvimento local):**
```env
# API Configuration
VITE_API_BASE_URL=http://localhost:3001
VITE_API_TIMEOUT=20000
```

**`.env.example` (template):**
```env
# API Configuration
VITE_API_BASE_URL=http://localhost:3001
VITE_API_TIMEOUT=20000
```

> **Nota:** O arquivo `.env` está no `.gitignore` e não deve ser commitado. Use `.env.example` como referência.

---

## 2. Configuração Centralizada (`src/config/env.ts`)

### 2.1 Estrutura

```typescript
// Configuração centralizada das variáveis de ambiente
const getEnvVar = (key: string, defaultValue?: string): string => {
  const value = import.meta.env[key];
  if (!value && !defaultValue) {
    console.warn(`Variável de ambiente ${key} não encontrada. Usando valor padrão.`);
  }
  return value || defaultValue || '';
};

export const env = {
  apiBaseUrl: getEnvVar('VITE_API_BASE_URL', 'http://localhost:3001'),
  apiTimeout: Number(getEnvVar('VITE_API_TIMEOUT', '20000')),
} as const;

// Validação em desenvolvimento
if (import.meta.env.DEV) {
  if (!env.apiBaseUrl) {
    console.error('VITE_API_BASE_URL não está definida!');
  }
}

// Endpoints da API
export const endpoints = {
  auth: {
    login: `${env.apiBaseUrl}/api/auth/login`,
    register: `${env.apiBaseUrl}/api/auth/register`,
    selectCompany: `${env.apiBaseUrl}/api/auth/select-company`,
    switchCompany: `${env.apiBaseUrl}/api/auth/switch-company`,
    getCompanies: `${env.apiBaseUrl}/api/auth/companies`,
  },
  leads: {
    list: `${env.apiBaseUrl}/api/leads`,
    create: `${env.apiBaseUrl}/api/leads`,
    update: (id: number) => `${env.apiBaseUrl}/api/leads/${id}`,
    delete: (id: number) => `${env.apiBaseUrl}/api/leads/${id}`,
    getById: (id: number) => `${env.apiBaseUrl}/api/leads/${id}`,
    updateStatus: (id: number) => `${env.apiBaseUrl}/api/leads/${id}/status`,
  },
} as const;
```

### 2.2 Características

- ✅ **Type-safe**: TypeScript garante tipos corretos
- ✅ **Validação**: Avisos em desenvolvimento se variáveis não estiverem definidas
- ✅ **Valores padrão**: Fallback para valores padrão se variável não existir
- ✅ **Centralizado**: Todos os endpoints em um único lugar
- ✅ **Reutilizável**: Funções para endpoints dinâmicos (com ID)

---

## 3. Uso nos Componentes

### 3.1 Importação

```typescript
import { endpoints } from '../../config/env';
```

### 3.2 Exemplos de Uso

**Login:**
```typescript
const response = await axios.post(endpoints.auth.login, {
  email: result.data.email,
  password: result.data.password,
});
```

**Listar Leads:**
```typescript
const response = await axios.get(
  `${endpoints.leads.list}?${params.toString()}`,
  { headers: { Authorization: `Bearer ${token}` } }
);
```

**Buscar Lead por ID:**
```typescript
const response = await axios.get(
  endpoints.leads.getById(leadId),
  { headers: { Authorization: `Bearer ${token}` } }
);
```

**Criar Lead:**
```typescript
const response = await axios.post(
  endpoints.leads.create,
  payload,
  { headers: { Authorization: `Bearer ${token}` } }
);
```

**Atualizar Lead:**
```typescript
const response = await axios.patch(
  endpoints.leads.update(leadId),
  payload,
  { headers: { Authorization: `Bearer ${token}` } }
);
```

**Deletar Lead:**
```typescript
await axios.delete(
  endpoints.leads.delete(leadId),
  { headers: { Authorization: `Bearer ${token}` } }
);
```

---

## 4. Configuração por Ambiente

### 4.1 Desenvolvimento Local

```env
# .env
VITE_API_BASE_URL=http://localhost:3001
VITE_API_TIMEOUT=20000
```

### 4.2 Staging

```env
# .env.staging (não versionado)
VITE_API_BASE_URL=https://api-staging.dwu.com.br
VITE_API_TIMEOUT=30000
```

### 4.3 Produção

```env
# .env.production (não versionado)
VITE_API_BASE_URL=https://api.dwu.com.br
VITE_API_TIMEOUT=30000
```

> **Importante:** No Vite, variáveis de ambiente devem ter o prefixo `VITE_` para serem expostas ao código do cliente.

---

## 5. Componentes Atualizados

Os seguintes componentes foram atualizados para usar a configuração centralizada:

- ✅ `src/pages/auth/LoginPage.tsx` - Usa `endpoints.auth.login`
- ✅ `src/pages/leads/LeadsPage.tsx` - Usa `endpoints.leads.list` e `endpoints.leads.delete`
- ✅ `src/pages/leads/lead_details/LeadDetailsPage.tsx` - Usa `endpoints.leads.getById` e `endpoints.leads.delete`
- ✅ `src/pages/leads/components/NewLeadModal.tsx` - Usa `endpoints.leads.create` e `endpoints.leads.update`

---

## 6. Benefícios

### 6.1 Manutenibilidade

- ✅ **Mudança única**: Alterar URL base em um único lugar
- ✅ **Sem URLs hardcoded**: Elimina necessidade de buscar/replace em múltiplos arquivos
- ✅ **Documentação implícita**: Estrutura de endpoints visível no código

### 6.2 Segurança

- ✅ **Separação por ambiente**: Diferentes URLs para dev/staging/prod
- ✅ **Sem segredos no código**: Variáveis sensíveis apenas em `.env` (não versionado)

### 6.3 Desenvolvimento

- ✅ **Type-safe**: TypeScript previne erros de digitação
- ✅ **Autocomplete**: IDEs sugerem endpoints disponíveis
- ✅ **Validação**: Avisos em desenvolvimento se configuração estiver incorreta

---

## 7. Adicionando Novos Endpoints

### 7.1 Passo a Passo

1. **Adicionar endpoint em `src/config/env.ts`:**

```typescript
export const endpoints = {
  // ... endpoints existentes
  contacts: {
    list: `${env.apiBaseUrl}/api/contacts`,
    create: `${env.apiBaseUrl}/api/contacts`,
    getById: (id: number) => `${env.apiBaseUrl}/api/contacts/${id}`,
    update: (id: number) => `${env.apiBaseUrl}/api/contacts/${id}`,
    delete: (id: number) => `${env.apiBaseUrl}/api/contacts/${id}`,
  },
} as const;
```

2. **Usar no componente:**

```typescript
import { endpoints } from '../../config/env';

// ...
const response = await axios.get(endpoints.contacts.list);
```

---

## 8. Docker e Hot Reload

### 8.1 Configuração Docker

O arquivo `.env` é carregado automaticamente pelo Docker Compose:

```yaml
services:
  frontend:
    env_file:
      - .env
```

### 8.2 Hot Reload

O Vite detecta mudanças no `.env` e reinicia o servidor automaticamente:

```
[vite] .env changed, restarting server...
```

---

## 9. Troubleshooting

### 9.1 Variável não encontrada

**Problema:** `Variável de ambiente VITE_API_BASE_URL não encontrada`

**Solução:**
1. Verificar se `.env` existe na raiz do projeto
2. Verificar se a variável tem o prefixo `VITE_`
3. Reiniciar o servidor de desenvolvimento

### 9.2 Endpoint não funciona

**Problema:** Requisições falham com erro de CORS ou 404

**Solução:**
1. Verificar `VITE_API_BASE_URL` no `.env`
2. Verificar se o backend está rodando na URL configurada
3. Verificar logs do container Docker

### 9.3 Mudanças não refletem

**Problema:** Alterações no `.env` não são aplicadas

**Solução:**
1. Reiniciar o servidor de desenvolvimento
2. Verificar se o arquivo está na raiz do projeto
3. Verificar se não há cache do navegador

---

## 10. Referências

- [Vite - Environment Variables](https://vitejs.dev/guide/env-and-mode.html)
- [ANEXO_06_Frontend_Modulo_Leads.md](./ANEXO_06_Frontend_Modulo_Leads.md) - Documentação do módulo de leads
- [ENVIRONMENT_VARIABLES.md](./ENVIRONMENT_VARIABLES.md) - Padrão geral de variáveis de ambiente

---

**Mantido por:** Equipe DWU CRM  
**Última atualização:** 2025-11-12

