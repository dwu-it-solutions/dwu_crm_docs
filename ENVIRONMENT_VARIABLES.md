## Guia de Variáveis de Ambiente – DWU CRM

> Contrato oficial de variáveis por repositório, categoria e ambiente.  
> Última atualização: 2025-11-09.

### 1. Categorias

| Categoria | Onde definir | Exemplos | Observações |
| --- | --- | --- | --- |
| **Secrets** | GitHub → Settings → Secrets and variables → Actions | `DATABASE_URL`, `PROD_API_KEY`, `AWS_SECRET_ACCESS_KEY` | Sempre mascarados em logs. Não versionar. |
| **Variables** | GitHub → Settings → Variables → Actions | `APP_ENV`, `REGION`, `TIMEZONE` | Valores não sensíveis. Podem ser sobrescritos por ambiente. |
| **Contexto** | Workflows (`env:`) com GitHub Context (`${{ github.* }}`) | `GIT_BRANCH`, `GIT_COMMIT`, `DEPLOY_TAG` | Dinâmicos; usados apenas em runtime. |
| **Arquivos .env** | `.env.local`, `.env.development`, `.env.example` | `APP_PORT`, `VITE_API_URL`, `TZ` | Nunca guardar segredos reais fora de Secrets. |

### 2. Convenções Gerais

1. **Formato**: `UPPER_CASE_SNAKE_CASE`.
2. **Prefixos**:
   - `APP_` – Configurações gerais da aplicação.
   - `DB_` – Banco de dados.
   - `AWS_` – Integrações AWS.
   - `DINAMIZE_` – Integrações Dinamize.
   - `CI_` / `GIT_` – Contexto CI/CD.
3. **Arquivos versionados**: apenas `.env.example`.
4. **Arquivos ignorados**: `.env`, `.env.local`, `.env.development`, `.env.staging`, `.env.production`.
5. **Máscara em logs**: quando necessário usar `echo`, aplicar `echo "::add-mask::$VARIAVEL"`.
6. **Documentação**: atualizações obrigatórias neste guia ao adicionar/alterar variáveis.

### 3. Estrutura Recomendada de Arquivos `.env`

| Arquivo | Uso | Versionado | Local | Observações |
| --- | --- | --- | --- | --- |
| `.env.example` | Modelo de referência | ✅ | Repositório | Valores dummy, instruções de origem. |
| `.env.local` | Desenvolvimento local | ❌ | Máquina dev | Personalizado por dev. |
| `.env.development` | Configuração de dev compartilhada | ✅* | Repositório (sem segredos) | Opcional se necessário. |
| `.env.staging` | Pré-produção | ❌ | GitHub Secrets/Variables | Injetado via Actions. |
| `.env.production` | Produção | ❌ | GitHub Secrets/Variables | Injetado via Actions. |

> `*` versionar `.env.development` apenas se não contiver segredos; caso contrário, deixar apenas `.env.example`.

### 4. Variáveis por Repositório

#### 4.1 `dwu_crm_backend`

| Chave | Categoria | Descrição | Observação |
| --- | --- | --- | --- |
| `APP_NAME` | Variable | Nome da aplicação | Default: `dwu-crm-backend`. |
| `APP_ENV` | Variable | Ambiente atual (`local`, `development`, `staging`, `production`) | Usado pelo NestJS. |
| `APP_PORT` | Variable | Porta HTTP (ex.: `3001`) | Mantido em `.env.local`. |
| `TZ` | Variable | Timezone (`America/Sao_Paulo`) | Padroniza logs e cron. |
| `DB_HOST` | Variable | Host do banco | Para ambientes locais/sandbox. |
| `DB_PORT` | Variable | Porta do banco | Default `5432`. |
| `DB_NAME` | Variable | Nome do banco | |
| `DB_SCHEMA` | Variable | Schema Prisma (opcional) | |
| `DATABASE_URL` | Secret | URL completa | Formato padrão Prisma. |
| `DB_USER` / `DB_PASS` | Secret | Credenciais | Definidos por ambiente. |
| `DINAMIZE_API_BASE_URL` | Variable | Endpoint Dinamize | Default: `https://api.dinamize.com`. Configure para ambiente de teste se disponível. |
| `DINAMIZE_API_USER` | Secret | Usuário/email da API Dinamize | Credencial de autenticação. |
| `DINAMIZE_API_PASSWORD` | Secret | Senha da API Dinamize | Credencial de autenticação. |
| `DINAMIZE_CLIENT_CODE` | Secret | Código do cliente Dinamize | Código único do cliente. |
| `DINAMIZE_TOKEN_EXPIRY_INACTIVITY_MINUTES` | Variable | Tempo de expiração por inatividade | Default: `60` minutos. |
| `DINAMIZE_TOKEN_MAX_AGE_HOURS` | Variable | Tempo máximo de vida do token | Default: `24` horas. |
| `DINAMIZE_RATE_LIMIT_PER_MINUTE` | Variable | Limite de requisições por minuto | Default: `60`. |
| `ENCRYPT_TOKEN_KEY` | Secret | Chave para criptografia de tokens | Usado para criptografar tokens armazenados. |
| `JWT_SECRET` | Secret | Segredo JWT | |
| `JWT_EXPIRES_IN` | Variable | Expiração token | Ex.: `3600s`. |
| `REDIS_URL` | Secret | Cache/queue | Opcional. |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Secret | Integração AWS | Se aplicável. |
| `GIT_BRANCH` | Contexto | `${{ github.ref_name }}` | Definido no workflow. |
| `GIT_COMMIT` | Contexto | `${{ github.sha }}` | |

#### 4.2 `dwu_crm_frontend` (Vite)

| Chave | Categoria | Descrição | Observação |
| --- | --- | --- | --- |
| `APP_NAME` | Variable | Nome da aplicação | Opcional. |
| `APP_ENV` | Variable | Ambiente Vite | (`development`, `staging`, `production`). |
| `VITE_API_URL` | Variable | Base URL do backend | Sempre prefixar `VITE_`. |
| `VITE_INSIGHTS_KEY` | Secret | Chaves analytics | Definir como Secret e referenciar no build. |
| `VITE_FEATURE_FLAGS` | Variable | Flags JSON/string | |
| `CI_BUILD_VERSION` | Contexto | `${{ github.run_number }}` | Para mostrar versão na UI. |

#### 4.3 `dwu_crm_mobile`

| Chave | Categoria | Descrição | Observação |
| --- | --- | --- | --- |
| `APP_ENV` | Variable | Ambiente RN (`development`, etc.) | |
| `API_BASE_URL` | Variable | Backend endpoint | |
| `MOBILE_SENTRY_DSN` | Secret | Observabilidade | |
| `MOBILE_FEATURE_FLAGS` | Variable | Flags mobile | |
| `MOBILE_BUILD_NUMBER` | Contexto | Derivado do Actions (`${{ github.run_number }}`) | Setado no build job. |

#### 4.4 `dwu_crm_shared`

| Chave | Categoria | Descrição | Observação |
| --- | --- | --- | --- |
| `APP_ENV` | Variable | Ambiente para build | |
| `NPM_TOKEN` | Secret | Publicação GitHub Packages | Usado no workflow de publish. |

#### 4.5 Observação sobre infraestrutura

O repositório `dwu_crm_infra` foi descontinuado em 2025-11-11. As variáveis de suporte a Docker Compose passam a ser mantidas diretamente em cada aplicação (`dwu_crm_backend`, `dwu_crm_frontend`, `dwu_crm_mobile`). Utilize as seções correspondentes acima para definir URLs de banco, segredos e endpoints.

### 5. Estrutura `.env.example` (modelo)

```
# Application
APP_NAME=dwu-crm-backend
APP_ENV=local
APP_PORT=3001
TZ=America/Sao_Paulo

# Database (preencher via Secrets)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dwu_suite_dev
DATABASE_URL=postgresql://user:pass@localhost:5432/dwu_suite_dev?schema=dwu_crm_dev
# DB_USER e DB_PASS devem ser configurados como Secrets no GitHub

# Dinamize (opcional - necessário quando tiver credenciais)
# Por padrão, usa ambiente de produção. Configure DINAMIZE_API_BASE_URL para ambiente de teste se disponível.
DINAMIZE_API_BASE_URL=https://api.dinamize.com
DINAMIZE_API_USER=preencher_via_secret
DINAMIZE_API_PASSWORD=preencher_via_secret
DINAMIZE_CLIENT_CODE=preencher_via_secret
DINAMIZE_TOKEN_EXPIRY_INACTIVITY_MINUTES=60
DINAMIZE_TOKEN_MAX_AGE_HOURS=24
DINAMIZE_RATE_LIMIT_PER_MINUTE=60
ENCRYPT_TOKEN_KEY=preencher_via_secret

# Autenticação
JWT_SECRET=alterar_em_producao
JWT_EXPIRES_IN=3600s
```

> **Legenda**  
> `preencher_via_secret`: valor deve ser configurado como Secret e substituído via GitHub Actions (`env:` ou `dotenv` no deploy).

### 6. GitHub Actions – Convenções

#### 6.1 Bloco `env` Global
```yaml
env:
  APP_NAME: dwu-crm-backend
  APP_ENV: ${{ vars.APP_ENV }}
  GIT_BRANCH: ${{ github.ref_name }}
  GIT_COMMIT: ${{ github.sha }}
  DEPLOY_TAG: v${{ github.run_number }}
```

#### 6.2 Secrets por Job
```yaml
jobs:
  deploy:
    environment: production
    env:
      DATABASE_URL: ${{ secrets.DATABASE_URL }}
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

#### 6.3 Máscara
```yaml
- name: Mascarar secrets
  run: |
    echo "::add-mask::${{ secrets.DATABASE_URL }}"
    echo "::add-mask::${{ secrets.PROD_API_KEY }}"
```

### 7. GitHub Environments

| Environment | Branch | Secrets | Variables | Aprovação |
| --- | --- | --- | --- | --- |
| `development` | `development` | `DATABASE_URL_DEV`, `DINAMIZE_API_KEY_SANDBOX` | `APP_ENV=development`, `REGION=us-east-1` | Opcional |
| `staging` | `staging` | `DATABASE_URL_STAGING`, `AWS_*_STAGING` | `APP_ENV=staging`, `REGION=us-east-1` | 1 aprovador |
| `production` | `main` | `DATABASE_URL`, `PROD_API_KEY`, `AWS_*` | `APP_ENV=production`, `REGION=us-east-1` | 2 aprovadores |

### 8. Passos para Adicionar Nova Variável
1. Definir categoria (Secret, Variable, Contexto).
2. Atualizar `.env.example` correspondente.
3. Atualizar este documento.
4. Criar/atualizar no GitHub (Secrets/Variables).
5. Ajustar workflows (`env:` e jobs) se necessário.
6. Comunicar equipe (PR + destaque no changelog).

### 9. Checklist de Conformidade
- [ ] `.gitignore` cobre `.env`, `.env.*`, com exceção de `.env.example`.
- [ ] `.env.example` atualizado em cada repositório.
- [ ] Secrets definidos em `Settings → Secrets`.
- [ ] Variáveis configuradas em `Settings → Variables`.
- [ ] Environments com approvals e URLs configuradas.
- [ ] Workflows consomem variáveis via `vars`/`secrets`.
- [ ] Logs mascaram qualquer valor sensível.
- [ ] Documentação alinhada.

### 10. Referências
- [ANEXO_09_Decisao_Tecnica_Git_Flow_GitHub.md](./ANEXO_09_Decisao_Tecnica_Git_Flow_GitHub.md)
- [MANUAL_GIT_FLOW.md](./MANUAL_GIT_FLOW.md)
- GitHub Docs – [Secrets](https://docs.github.com/actions/security-guides/encrypted-secrets) / [Variables](https://docs.github.com/actions/learn-github-actions/variables)
- Semantic Versioning – [semver.org](https://semver.org)




