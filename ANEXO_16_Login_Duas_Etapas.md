# ANEXO 16 - Login em Duas Etapas com Seleção de Empresa

**Data:** 2025-11-11  
**Versão:** 1.0  
**Status:** ✅ Implementado

---

## Visão Geral

O sistema implementa um fluxo de login em duas etapas para permitir que usuários que pertencem a múltiplas empresas selecionem qual empresa desejam acessar após a autenticação inicial.

## Fluxo de Autenticação

### Etapa 1: Login (`POST /auth/login`)

O usuário envia suas credenciais (email e senha). O sistema:

1. Valida as credenciais
2. Busca todas as empresas associadas ao usuário (`UserCompany`)
3. Retorna uma resposta baseada no número de empresas:

#### Caso 1: Usuário com apenas uma empresa

```json
{
  "requiresCompanySelection": false,
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": "1h",
  "companies": [
    {
      "id": 1,
      "name": "Empresa Matriz Ltda",
      "cnpj": "12345678000190",
      "type": "MATRIZ",
      "role": "ADMIN"
    }
  ],
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "João Silva"
  }
}
```

**Token JWT gerado contém:**
- `sub`: ID do usuário
- `email`: Email do usuário
- `role`: Role global
- `companyId`: ID da empresa (única disponível)
- `companyIds`: Array com ID da empresa

#### Caso 2: Usuário com múltiplas empresas

```json
{
  "requiresCompanySelection": true,
  "temporaryToken": "temp_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "companies": [
    {
      "id": 1,
      "name": "Empresa Matriz Ltda",
      "cnpj": "12345678000190",
      "type": "MATRIZ",
      "role": "ADMIN"
    },
    {
      "id": 2,
      "name": "Filial São Paulo",
      "cnpj": "12345678000191",
      "type": "FILIAL",
      "role": "MANAGER"
    }
  ],
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "João Silva"
  }
}
```

**Token temporário gerado contém:**
- `sub`: ID do usuário
- `email`: Email do usuário
- `role`: Role global
- `temp`: `true` (flag indicando token temporário)
- `companyIds`: Array com IDs de todas as empresas disponíveis
- **Expiração:** 5 minutos

### Etapa 2: Seleção de Empresa (`POST /auth/select-company`)

Se o usuário tem múltiplas empresas, ele deve enviar o `temporaryToken` no header `Authorization` e o `companyId` no body:

```bash
POST /auth/select-company
Authorization: Bearer temp_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "companyId": 2
}
```

O sistema:

1. Valida o token temporário (verifica `temp: true` e expiração)
2. Verifica se o `companyId` solicitado está na lista `companyIds` do token
3. Gera um token JWT final com a empresa selecionada

**Resposta:**

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": "1h",
  "companyId": 2,
  "companyIds": [1, 2]
}
```

**Token JWT final contém:**
- `sub`: ID do usuário
- `email`: Email do usuário
- `role`: Role global
- `companyId`: ID da empresa selecionada
- `companyIds`: Array com IDs de todas as empresas disponíveis

## Endpoints Adicionais

### Listar Empresas do Usuário (`GET /auth/companies`)

Retorna todas as empresas que o usuário autenticado tem acesso:

```bash
GET /auth/companies
Authorization: Bearer <token>
```

**Resposta:**

```json
[
  {
    "id": 1,
    "name": "Empresa Matriz Ltda",
    "cnpj": "12345678000190",
    "type": "MATRIZ",
    "role": "ADMIN"
  },
  {
    "id": 2,
    "name": "Filial São Paulo",
    "cnpj": "12345678000191",
    "type": "FILIAL",
    "role": "MANAGER"
  }
]
```

### Trocar de Empresa (`POST /auth/switch-company/:companyId`)

Permite que um usuário já autenticado troque de empresa sem fazer login novamente:

```bash
POST /auth/switch-company/2
Authorization: Bearer <token>
```

**Resposta:**

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": "1h",
  "companyId": 2,
  "companyIds": [1, 2]
}
```

## Tratamento de Erros

### Erros de Autenticação

Todos os erros retornam mensagens internacionalizadas (i18n) baseadas no header `Accept-Language`:

- **Credenciais inválidas:** `errors.invalidCredentials`
- **Usuário sem acesso a empresas:** `errors.noCompanyAccess`
- **Token temporário inválido:** `errors.temporaryTokenInvalid`
- **Token temporário não fornecido:** `errors.temporaryTokenRequired`
- **Acesso negado à empresa:** `errors.companyAccessDenied`

### Exemplo de Resposta de Erro

```json
{
  "statusCode": 401,
  "message": "Token temporário inválido ou expirado",
  "error": "Unauthorized"
}
```

## Segurança

### Token Temporário

- **Expiração:** 5 minutos
- **Validação:** Verifica flag `temp: true` e lista `companyIds`
- **Uso único:** Apenas para endpoint `select-company`
- **Não pode ser usado:** Para acessar outros endpoints protegidos

### Validação de Acesso

- O sistema valida se o `companyId` solicitado está na lista `companyIds` do usuário
- Usuários não podem acessar empresas sem permissão
- O `CompanyGuard` valida o acesso em todas as requisições

## Implementação Técnica

### Arquivos Principais

- `src/auth/auth.service.ts`: Lógica de login e seleção de empresa
- `src/auth/auth.controller.ts`: Endpoints REST
- `src/auth/dto/login-response.dto.ts`: DTOs de resposta
- `src/auth/dto/select-company.dto.ts`: DTO de seleção de empresa
- `src/auth/guards/company.guard.ts`: Guard de validação de empresa

### Fluxo de Dados

```
1. POST /auth/login
   ↓
   AuthService.login()
   ↓
   UsersService.findByIdWithCompanies()
   ↓
   Se 1 empresa: retorna accessToken completo
   Se múltiplas: retorna temporaryToken

2. POST /auth/select-company
   ↓
   AuthService.selectCompany()
   ↓
   Valida temporaryToken
   ↓
   Verifica companyId em companyIds
   ↓
   Retorna accessToken final
```

## Exemplo de Uso no Frontend

```typescript
// Etapa 1: Login
const loginResponse = await fetch('/api/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password })
});

const data = await loginResponse.json();

if (data.requiresCompanySelection) {
  // Mostrar tela de seleção de empresa
  const selectedCompanyId = await showCompanySelector(data.companies);
  
  // Etapa 2: Selecionar empresa
  const tokenResponse = await fetch('/api/auth/select-company', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${data.temporaryToken}`
    },
    body: JSON.stringify({ companyId: selectedCompanyId })
  });
  
  const tokenData = await tokenResponse.json();
  localStorage.setItem('accessToken', tokenData.accessToken);
} else {
  // Token já disponível
  localStorage.setItem('accessToken', data.accessToken);
}
```

## Notas Importantes

1. **Token temporário:** Não pode ser usado para acessar endpoints protegidos, apenas para `select-company`
2. **Expiração:** Token temporário expira em 5 minutos
3. **i18n:** Todas as mensagens de erro são internacionalizadas
4. **Segurança:** Validação de acesso em múltiplas camadas (JWT, CompanyGuard, Service)

