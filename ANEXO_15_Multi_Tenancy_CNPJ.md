# Multi-Tenancy por CNPJ - Documentação

## Visão Geral

O sistema foi implementado com suporte completo a **multi-tenancy por CNPJ**, permitindo que múltiplas empresas (matriz e filiais) utilizem o mesmo sistema de forma isolada. Cada empresa possui seus próprios dados e usuários podem pertencer a múltiplas empresas.

## Arquitetura

### 1. Estrutura do Banco de Dados

#### Enums
- `CompanyType`: `MATRIZ` | `FILIAL`
- `UserCompanyRole`: `OWNER` | `ADMIN` | `MANAGER` | `USER`

#### Tabelas Principais

**`crm_companies`**
- `id`: ID único
- `cnpj`: CNPJ único (NOT NULL)
- `name`: Nome da empresa
- `type`: Tipo (MATRIZ ou FILIAL)
- `parentCompanyId`: ID da empresa matriz (NULL se for matriz)
- `segment`, `website`: Informações adicionais

**`crm_user_companies`** (N:N)
- `userId`: ID do usuário
- `companyId`: ID da empresa
- `role`: Role do usuário na empresa específica
- Unique constraint em `(userId, companyId)`

**Todas as tabelas de recursos** possuem `companyId`:
- `crm_leads`
- `crm_contacts`
- `crm_opportunities` (também possui `clientCompanyId` para empresa cliente)
- `crm_pipelines`
- `crm_stages`
- `crm_tasks`
- `crm_settings`
- `crm_auth_tokens`
- `crm_webhook_events`
- `crm_audit_log`
- `erp_integrations`

### 2. Autenticação e Autorização

#### JWT Payload
```typescript
{
  sub: number;           // User ID
  email: string;
  role: string;          // Role global
  companyId: number | null;  // Empresa atual (contexto)
  companyIds: number[];      // Lista de empresas que o usuário tem acesso
}
```

#### Fluxo de Autenticação

1. **Login** (`POST /auth/login`)
   - Valida credenciais
   - Busca empresas do usuário (`UserCompany`)
   - Gera token com `companyId` padrão (primeira empresa) e lista `companyIds`
   - Opcional: aceita `companyId` no body para definir empresa inicial

2. **Trocar Empresa** (`POST /auth/switch-company/:companyId`)
   - Valida se usuário tem acesso à empresa solicitada
   - Gera novo token com novo `companyId`

3. **Validação de Acesso** (`CompanyGuard`)
   - Extrai `companyId` do header `X-Company-Id` ou usa do JWT
   - Valida se `companyId` está na lista `companyIds` do usuário
   - Adiciona `companyId` ao `request` para uso nos controllers

### 3. Isolamento de Dados

Todos os repositories filtram automaticamente por `companyId`:

```typescript
// Exemplo: LeadsRepository
async findById(id: number, companyId: number) {
  return this.prisma.lead.findFirst({
    where: { id, companyId } // Filtro automático
  });
}
```

### 4. Controllers

Todos os controllers de recursos utilizam `CompanyGuard` e o decorator `@CompanyId()`:

```typescript
@UseGuards(JwtAuthGuard, CompanyGuard)
@Controller('leads')
export class LeadsController {
  @Get()
  findAll(@Query() query: ListLeadsDto, @CompanyId() companyId: number) {
    return this.leadsService.findAll(query, companyId);
  }
}
```

## Migração de Dados

A migration `20251111120000_add_multitenancy` realiza:

1. Criação de enums `CompanyType` e `UserCompanyRole`
2. Atualização de `crm_companies`:
   - Adiciona `type`, `parentCompanyId`, `updatedAt`
   - Torna `cnpj` NOT NULL e UNIQUE
   - Cria empresa padrão se necessário (`CNPJ: 00000000000000`)
3. Criação de `crm_user_companies`
4. Associação de usuários existentes à empresa padrão
5. Adição de `companyId` em todas as tabelas de recursos
6. Migração de dados existentes para empresa padrão
7. Criação de índices compostos para performance

## Uso da API

### Login com empresa específica

```bash
POST /auth/login
{
  "email": "user@example.com",
  "password": "password123",
  "companyId": 1  // Opcional
}
```

Resposta:
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": "3600s",
  "companyId": 1,
  "companyIds": [1, 2, 3]
}
```

### Trocar de empresa

```bash
POST /auth/switch-company/2
Authorization: Bearer <token>
```

### Usar header para definir empresa

```bash
GET /api/leads
Authorization: Bearer <token>
X-Company-Id: 2  // Opcional, usa do JWT se não informado
```

## Próximos Passos

### Pendente
1. **Endpoints CRUD para Company**
   - `GET /companies` - Listar empresas do usuário
   - `GET /companies/:id` - Detalhes da empresa
   - `POST /companies` - Criar empresa (apenas matriz)
   - `POST /companies/:id/subsidiaries` - Criar filial
   - `PATCH /companies/:id` - Atualizar empresa
   - `DELETE /companies/:id` - Deletar empresa

2. **Endpoints para UserCompany**
   - `GET /users/:id/companies` - Listar empresas do usuário
   - `POST /users/:id/companies` - Vincular usuário a empresa
   - `DELETE /users/:id/companies/:companyId` - Remover vínculo

3. **Atualizar seed.ts**
   - Criar estrutura de exemplo: matriz + filiais
   - Criar usuários com múltiplas empresas
   - Criar dados de exemplo por empresa

4. **Testes**
   - Testes unitários para CompanyGuard
   - Testes de integração para isolamento de dados
   - Testes de troca de empresa

## Segurança

- ✅ Validação obrigatória de `companyId` em todas as operações
- ✅ Isolamento total: usuário só vê recursos da empresa atual
- ✅ Auditoria: `AuditLog` registra `companyId` de todas as ações
- ✅ Performance: índices compostos `(companyId, ...)` em queries frequentes
- ✅ Validação de acesso: usuário não pode acessar empresa sem permissão

## Notas Importantes

1. **CNPJ único**: Cada empresa deve ter um CNPJ único no sistema
2. **Hierarquia**: Filiais sempre referenciam uma matriz através de `parentCompanyId`
3. **Dados isolados**: Todos os recursos são isolados por `companyId`, garantindo privacidade entre empresas
4. **Usuários multi-empresa**: Um usuário pode pertencer a múltiplas empresas com roles diferentes em cada uma

