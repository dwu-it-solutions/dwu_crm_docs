# ANEXO 13 - Guia de Testes JWT

## 1. Contexto

- Valida o fluxo de autenticação do backend NestJS executando em Docker.
- Banco local PostgreSQL exposto em `host.docker.internal:5432` com usuário `postgres` / senha `postgres`.
- Usuário administrador criado via seed: `admin@dwu.com.br` / `admin123`.

## 2. Preparação

1. **Aplicar migrations dentro do container**
   ```bash
   docker exec dwu-crm-backend npx prisma migrate deploy
   ```

2. **Rodar seed apontando para o mesmo banco**
   ```bash
   cd ../dwu_crm_backend
   DATABASE_URL="postgresql://postgres:postgres@localhost:5432/dwu_suite_dev?schema=dwu_crm_dev" npm run prisma:seed
   ```
   > Executa localmente, mas preenche o mesmo banco usado pelo container (`host.docker.internal`).

## 3. Fluxo de autenticação

1. **Obter token**
   ```bash
   curl -s http://localhost:3001/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"admin@dwu.com.br","password":"admin123"}'
   ```
   Resposta `201` contém `accessToken`, `tokenType` e `expiresIn`.

2. **Acessar rota protegida**
   ```bash
   TOKEN=<copiar accessToken>
   curl -s http://localhost:3001/api/leads \
     -H "Authorization: Bearer $TOKEN"
   ```
   Retorna `200` com lista de leads seed.

3. **Sem token / token inválido**
   ```bash
   curl -i http://localhost:3001/api/leads
   ```
   Deve responder `401 Unauthorized`.

4. **Mensagens traduzidas (i18n)**
   ```bash
   TOKEN=<copiar accessToken>
   curl -s "http://localhost:3001/api/leads/999?lang=pt" \
     -H "Authorization: Bearer $TOKEN"

   curl -s http://localhost:3001/api/leads/999 \
     -H "Authorization: Bearer $TOKEN" \
     -H "Accept-Language: en"
   ```
   O primeiro comando responde `Lead 999 não encontrado`; o segundo responde `Lead 999 not found` utilizando o cabeçalho `Accept-Language`.

## 4. Notas
- Para testar expiração, ajuste `JWT_EXPIRES_IN` no `backend.docker.env` e reinicie o container.
- Healthcheck (`GET /api`) continua público por meio do decorator `@Public()`.
- Logs do container mostram `API disponível em http://[::1]:3001/api`; o endereço funcional é `http://localhost:3001/api`.
- O banco padrão de desenvolvimento é `dwu_suite_dev`, com schema ativo `dwu_crm_dev`.

## 5. Referências
- README do backend (`dwu_crm_backend/README.md`) – seção “Testes JWT”, com link para este anexo.
- `ANEXO_05_Backend_Modulo_Leads.md` – arquitetura Controller → Service → Repository.

