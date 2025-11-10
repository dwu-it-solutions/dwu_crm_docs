## Plano de Padronização – Variáveis de Ambiente & GitLab Flow (GitHub)

> Documento base para implementação imediata do padrão de variáveis de ambiente, GitHub Actions e fluxo GitLab Flow adaptado no ecossistema DWU CRM.

### 1. Objetivos
- Garantir segurança e rastreabilidade no uso de variáveis (segredos x configuração x contexto).
- Padronizar a estrutura `.env` em todos os repositórios (`backend`, `frontend`, `mobile`, `shared`, `infra`).
- Formalizar uso de GitHub Environments (`development`, `staging`, `production`).
- Ajustar workflows GitHub Actions com uso consistente de `env`, `secrets` e variáveis de contexto.
- Documentar GitLab Flow adaptado (branches por ambiente) e integração com Semantic Versioning.
- Criar base compartilhada (`shared`) para i18n e utilitários.
- Introduzir repositório `crm_infra` com Docker Compose centralizado.

### 2. Escopo Geral
| Tópico | Itens |
| --- | --- |
| Estrutura `.env` | `.env.example`, `.env.local`, `.env.development`, `.env.staging`, `.env.production` |
| GitHub | Actions (`ci.yml`, `deploy.yml`), Environments, Secrets, Variables |
| Fluxo Git | Branches `feature/*`, `development`, `staging`, `main`, tags SemVer |
| Shared | Módulo `i18n` + enums/tipos compartilhados |
| Infra | Novo repo `dwu_crm_infra` com `docker-compose.yml`, scripts, envs de exemplo |
| Documentação | Atualizações em READMEs, `docs/ENVIRONMENT_VARIABLES.md`, referências cruzadas |

### 3. Diretrizes de Variáveis

#### 3.1 Categorias
- **Segredos (`Secrets`)**: tokens, credenciais, URLs com credenciais. Ex.: `DATABASE_URL`, `AWS_ACCESS_KEY_ID`, `PROD_API_KEY`.
- **Configuração (`Variables`)**: valores não sensíveis que controlam comportamento. Ex.: `APP_ENV`, `REGION`, `TIMEZONE`.
- **Contexto (Actions)**: valores dinâmicos do workflow. Ex.: `GIT_BRANCH=${{ github.ref_name }}`, `DEPLOY_TAG=v${{ github.run_number }}`.

#### 3.2 Convenção de Nome
- Prefixos por domínio: `APP_`, `DB_`, `AWS_`, `CI_`, `DINAMIZE_`, etc.
- Snake case, maiúsculas (`UPPER_CASE_SNAKE_CASE`).
- Documentar origem (`Secrets`, `Variables`, `env_file`, etc.) na `.env.example`.

#### 3.3 Estrutura `.env`
```
# Application
APP_NAME=myapp
APP_ENV=development
APP_REGION=us-east-1

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dwu_suite_dev
DB_USER=${{ secrets.DB_USER }}
DB_PASS=${{ secrets.DB_PASS }}

# Dinamize
DINAMIZE_API_URL=https://sandbox.dinamize.com
DINAMIZE_API_KEY=${{ secrets.DINAMIZE_API_KEY }}
```

### 4. Plano de Execução

1. **Diagnóstico** *(concluído)*  
   Levantamento de `.env`, `.gitignore`, Workflows, documentação atual.

2. **Documentação & Templates**  
   - Criar `docs/ENVIRONMENT_VARIABLES.md` com contrato das variáveis.
   - Atualizar READMEs dos repositórios com instruções para `.env` e GitLab Flow.

3. **Ajustes de Repositório**
   - Adicionar `.env.example` e atualizar `.gitignore` em `backend`, `frontend`, `mobile`, `shared`.
   - Inserir mensagens guia nos exemplos (ex.: “preencher via GitHub Secrets”).

4. **GitHub Actions**
   - `ci.yml`: lint/test/build nos pushes/PRs (`development`, `staging`, `main`).
   - `deploy.yml`: jobs condicionais por branch, com `environment` apontando para `development/staging/production`.
   - Uso de variáveis de contexto (`GIT_BRANCH`, `GIT_COMMIT`, `DEPLOY_TAG`).

5. **GitHub Environments**
   - Criar `development`, `staging`, `production`.
   - Cadastrar Secrets e Variables conforme categoria.
   - Configurar approvals/proteções (ex.: staging > 1 approval, production > 2 approvals).

6. **Fluxo GitLab Flow**
   - Revisar proteção de branch (PR obrigatório, CI verde, sem force push).
   - Adotar tags SemVer (com suporte a `semantic-release` futuramente).
   - Atualizar `MANUAL_GIT_FLOW.md` se necessário (ex.: novos comandos Actions).

7. **Shared i18n**
   - Estruturar `src/i18n/locales/{en,pt,es}` com `messages.json`.
   - Criar `index.ts` exportando `translations`, `SupportedLanguage`, `defaultLang`.
   - Documentar consumo em backend (NestJS) e frontend/mobile (React/React Native).

8. **Infraestrutura Docker**
   - Criar repo `dwu_crm_infra` com:
     - `docker-compose.yml` (backend, frontend, mobile, network).
     - `env/backend.env.example`, etc.
     - Scripts `start`, `stop`, `reset`.
   - README com instruções `docker compose up`.

9. **Checklist Final**
   - Workflows verdes em todos os repos.
   - Secrets/Variables auditados.
   - Documentação alinhada (docs + READMEs).
   - Onboarding validado (novo dev consegue subir ambiente com compose).

### 5. Recursos & Referências
- `ANEXO_09_Decisao_Tecnica_Git_Flow_GitHub.md`
- `MANUAL_GIT_FLOW.md`
- Estudo “Backend Environments Flow Docker i18n”
- GitHub Docs: Actions, Secrets, Environments
- Semantic Versioning (`semver.org`)

### 6. Próximos Passos Imediatos
1. Criar `docs/ENVIRONMENT_VARIABLES.md` (contrato geral).
2. Adicionar `.env.example` + ajustes `.gitignore` nos repos.
3. Estruturar workflows iniciais (`ci.yml` com lint/test).
4. Configurar Environments no GitHub (manual).
5. Estruturar `shared` i18n.
6. Criar esqueleto inicial do `dwu_crm_infra`.

> Após cada etapa, atualizar checklist nesta documentação e comunicar evolução ao time.





