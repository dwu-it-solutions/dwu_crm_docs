# Manual de Git Flow - CRM DWU
## Guia Prático para Desenvolvedores

**Versão:** 1.0  
**Data:** 2025-11-05  
**Baseado em:** GitLab Flow (metodologia) + GitHub (plataforma) + Semantic Versioning  
**Referência:** ANEXO_09_Decisao_Tecnica_Git_Flow_GitHub.md

---

**Plataforma:** GitHub  
**Metodologia:** GitLab Flow (branch = ambiente)  
**Estrutura:** Multirepo (6 repositórios separados)

---

## Índice Rápido

- [Setup Inicial](#setup-inicial)
- [Desenvolvimento Diário](#desenvolvimento-diário)
- [Backend](#backend)
- [Frontend](#frontend)
- [Mobile](#mobile)
- [Releases](#releases)
- [Hotfix](#hotfix)
- [Comandos Úteis](#comandos-úteis)

---

## Setup Inicial

### Clonar Repositórios

```bash
# 1. Criar workspace
mkdir dwu-crm-workspace
cd dwu-crm-workspace

# 2. Clonar todos os repos
git clone git@github.com:dwu/dwu_crm_backend.git
git clone git@github.com:dwu/dwu_crm_frontend.git
git clone git@github.com:dwu/dwu_crm_mobile.git
git clone git@github.com:dwu/dwu_crm_shared.git
git clone git@github.com:dwu/dwu_crm_database.git
git clone git@github.com:dwu/dwu_crm_docs.git

# 2. Configurar Git (uma vez)
git config user.name "Seu Nome"
git config user.email "seu@email.com"

# 3. Verificar branches
git branch -a
# * main
#   remotes/origin/development
#   remotes/origin/staging
#   remotes/origin/main

# 4. Criar tracking de branches remotas
git checkout -b development origin/development
git checkout -b staging origin/staging
git checkout main
```

---

### Instalar Dependências

```bash
# Cada repositório separadamente

# Backend
cd dwu_crm_backend
npm install

# Frontend
cd ../dwu_crm_frontend
npm install

# Mobile
cd ../dwu_crm_mobile
npm install

# Shared (se desenvolver)
cd ../dwu_crm_shared
npm install
```

---

## Desenvolvimento Diário

### Fluxo Básico de Feature

```bash
# 1. SEMPRE começar de development atualizado
git checkout development
git pull origin development

# 2. Criar branch de feature
git checkout -b feature/nome-descritivo

# Exemplos de nomes:
# feature/login-jwt
# feature/sincronizacao-leads
# feature/dashboard-vendas
# feature/integracao-erp-totvs

# 3. Desenvolver
# ... fazer alterações ...

# 4. Commit frequente
git add .
git commit -m "Implementa autenticação JWT"

# Mensagens em português, imperativo:
# ✅ "Adiciona validação de email"
# ✅ "Corrige bug de sincronização"
# ✅ "Implementa RBAC para vendedores"
# ❌ "Adicionado validação"
# ❌ "Fix bug"

# 5. Push para remote
git push origin feature/nome-descritivo

# 6. Abrir Pull Request no GitHub/GitLab
# feature/nome-descritivo → development

# 7. Aguardar:
# - CI passar (testes, linter)
# - Code review (1-2 pessoas)
# - Aprovação

# 8. Merge (automático ou manual)
# CI/CD faz deploy automático em DEV
```

---

### Atualizar Feature com Development

```bash
# Se development avançou enquanto você trabalhava
git checkout development
git pull origin development

git checkout feature/sua-feature
git merge development

# Ou rebase (mais limpo)
git rebase development

# Resolver conflitos se houver
git add .
git rebase --continue

git push origin feature/sua-feature --force-with-lease
```

---

## Backend

### Estrutura

```
packages/backend/
├── src/
│   ├── modules/
│   │   ├── auth/
│   │   ├── dinamize/
│   │   └── leads/
│   ├── common/
│   └── config/
├── tests/
└── package.json
```

### Workflow Backend

```bash
# 1. Criar feature
git checkout development
git pull origin development
git checkout -b feature/api-leads

# 2. Desenvolver no backend
cd packages/backend

# 3. Rodar testes localmente
npm test

# 4. Rodar linter
npm run lint

# 5. Testar integração com Dinamize
npm run test:integration

# 6. Commit
cd ../..  # Voltar para root
git add packages/backend
git commit -m "Adiciona endpoint de listagem de leads"

# 7. Push e PR
git push origin feature/api-leads
```

---

### Testes Backend

```bash
# Testes unitários
cd packages/backend
npm test

# Testes de integração (com BD)
npm run test:integration

# Testes com Dinamize (staging)
NODE_ENV=staging npm run test:dinamize

# Coverage
npm run test:coverage
```

---

## Frontend

### Estrutura

```
packages/frontend/
├── src/
│   ├── components/
│   ├── pages/
│   ├── services/
│   ├── hooks/
│   └── store/
├── public/
└── package.json
```

### Workflow Frontend

```bash
# 1. Criar feature
git checkout development
git pull origin development
git checkout -b feature/tela-leads

# 2. Desenvolver no frontend
cd packages/frontend

# 3. Rodar dev server
npm run dev
# http://localhost:3000

# 4. Testar
npm test

# 5. Build
npm run build

# 6. Lint
npm run lint

# 7. Commit
cd ../..
git add packages/frontend
git commit -m "Adiciona tela de listagem de leads"

# 8. Push e PR
git push origin feature/tela-leads
```

---

### Usar Tipos Compartilhados

```typescript
// packages/frontend/src/services/api.ts
import { Lead, CreateLeadDTO } from '@crm-dwu/shared/types';

async function createLead(data: CreateLeadDTO): Promise<Lead> {
  // Tipos sincronizados entre backend e frontend
}
```

---

## Mobile

### Estrutura

```
packages/mobile/
├── src/
│   ├── screens/
│   ├── components/
│   ├── navigation/
│   └── services/
├── android/
├── ios/
└── package.json
```

### Workflow Mobile

```bash
# 1. Criar feature
git checkout development
git pull origin development
git checkout -b feature/app-leads

# 2. Desenvolver
cd packages/mobile

# 3. Rodar Android
npm run android

# 4. Rodar iOS
npm run ios

# 5. Testes
npm test

# 6. Build
npm run build:android
npm run build:ios

# 7. Commit e PR
cd ../..
git add packages/mobile
git commit -m "Adiciona tela de leads no app mobile"
git push origin feature/app-leads
```

---

## Releases

### Processo de Release

#### Fase 1: Preparação em Development

```bash
# 1. Todas features mergeadas em development
# 2. CI passa em development
# 3. Testado localmente

# 4. Atualizar CHANGELOG.md
# Em packages/backend, frontend, mobile
```

**CHANGELOG.md:**
```markdown
# Changelog

## [Unreleased]

## [1.1.0] - 2025-11-15

### Added
- Integração com ERP Totvs via OAuth2
- Dashboard de vendas
- Relatório de conversão de leads

### Fixed
- Correção de bug na sincronização com Dinamize
- Validação de email aprimorada

### Changed
- Performance de listagem de leads otimizada
```

---

#### Fase 2: Deploy em Staging

```bash
# 1. Merge development → staging
git checkout staging
git pull origin staging
git merge development

# Resolver conflitos se houver
git add .
git commit -m "Merge development para staging - preparação v1.1.0"

# 2. Push (trigger deploy staging)
git push origin staging

# 3. CI/CD faz deploy automático em STAGING

# 4. Testar em staging
# - Validar com Dinamize real
# - Testes de integração com ERPs
# - Testes de usuários (UAT)
# - Validar performance
```

---

#### Fase 3: Release para Produção

```bash
# Staging OK? Avançar para produção

# 1. Merge staging → main
git checkout main
git pull origin main
git merge staging --no-ff

# 2. Criar tag de release
git tag -a v1.1.0 -m "Release v1.1.0: Integração ERPs

Features:
- Conectores ERP Totvs e SAP
- Dashboard de vendas
- Relatórios de conversão

Fixes:
- Sincronização Dinamize
- Validação de email
"

# 3. Push com tags
git push origin main
git push origin --tags

# 4. CI/CD automático:
# - Build production
# - Deploy
# - Criar release no GitHub
# - Atualizar CHANGELOG
# - Notificar equipe
```

---

#### Fase 4: Pós-Release

```bash
# 1. Atualizar CHANGELOG.md
# Mover [Unreleased] para [1.1.0]

# 2. Propagar para staging e development
git checkout staging
git merge main
git push origin staging

git checkout development
git merge staging
git push origin development

# 3. Monitorar produção
# - Logs de erro
# - Métricas de performance
# - Feedback de usuários
```

---

## Hotfix

### Correção Urgente em Produção

```bash
# 1. Criar hotfix direto de main
git checkout main
git pull origin main
git checkout -b hotfix/token-dinamize-expirado

# 2. Corrigir o problema
# ... fazer alterações mínimas ...

# 3. Testar localmente
npm test

# 4. Commit
git add .
git commit -m "Corrige renovação de token Dinamize"

# 5. Push
git push origin hotfix/token-dinamize-expirado

# 6. PR para main (URGENTE)
# Aprovação rápida (1 pessoa)

# 7. Merge em main
git checkout main
git merge hotfix/token-dinamize-expirado

# 8. Criar tag PATCH
git tag -a v1.0.1 -m "Hotfix: Correção token Dinamize"
git push origin main --tags

# 9. CI/CD faz deploy IMEDIATO

# 10. Propagar para staging e development
git checkout staging
git merge main
git push origin staging

git checkout development
git merge staging
git push origin development

# 11. Deletar branch de hotfix
git branch -d hotfix/token-dinamize-expirado
git push origin --delete hotfix/token-dinamize-expirado
```

---

## Comandos Úteis

### Verificar Status

```bash
# Status atual
git status

# Ver branches
git branch -a

# Ver último commit
git log -1

# Ver diferenças
git diff
git diff development...feature/sua-feature
```

---

### Limpar Branches

```bash
# Listar branches mergeadas
git branch --merged

# Deletar branch local
git branch -d feature/antiga

# Deletar branch remota
git push origin --delete feature/antiga

# Limpar referências de branches remotas deletadas
git fetch --prune
```

---

### Desfazer Mudanças

```bash
# Desfazer mudanças não commitadas
git restore arquivo.ts
git restore .

# Desfazer último commit (manter mudanças)
git reset --soft HEAD~1

# Desfazer último commit (descartar mudanças)
git reset --hard HEAD~1

# Reverter commit em produção (cria novo commit)
git revert [commit-hash]
```

---

### Resolver Conflitos

```bash
# 1. Tentar merge
git merge development
# CONFLICT em arquivo.ts

# 2. Abrir arquivo e resolver
# <<<<<<< HEAD
# seu código
# =======
# código development
# >>>>>>> development

# 3. Escolher versão correta ou mesclar

# 4. Marcar como resolvido
git add arquivo.ts

# 5. Finalizar merge
git commit -m "Merge development resolvendo conflitos"
```

---

### Stash (Guardar Mudanças Temporárias)

```bash
# Guardar mudanças sem commit
git stash save "WIP: implementando login"

# Trocar de branch
git checkout outra-branch

# Voltar e recuperar
git checkout feature/sua-feature
git stash pop

# Listar stashes
git stash list

# Aplicar stash específico
git stash apply stash@{0}
```

---

## Boas Práticas

### Commits

**Formato:**
```
<tipo>: <descrição curta>

<descrição detalhada opcional>

<referências opcionais>
```

**Exemplos:**
```bash
git commit -m "feat: Adiciona autenticação JWT"

git commit -m "fix: Corrige validação de email em leads"

git commit -m "refactor: Melhora performance de sincronização"

git commit -m "docs: Atualiza ANEXO_02 com nomenclatura

- Adicionada seção 0
- Justificativa técnica crm_* vs dwu_*
- Roadmap de domínios futuros
"

git commit -m "test: Adiciona testes de integração Dinamize

Refs: #123
"
```

**Tipos:**
- `feat`: Nova feature
- `fix`: Correção de bug
- `refactor`: Refatoração (sem mudança de comportamento)
- `docs`: Documentação
- `test`: Testes
- `chore`: Manutenção (build, config)
- `perf`: Performance
- `style`: Formatação (não afeta código)

---

### Pull Requests

**Template:**
```markdown
## Descrição
Implementa autenticação JWT para usuários do CRM.

## Tipo de Mudança
- [x] Nova feature
- [ ] Correção de bug
- [ ] Breaking change
- [ ] Documentação

## Módulos Afetados
- [x] Backend (packages/backend/src/modules/auth)
- [x] Frontend (packages/frontend/src/services/auth)
- [ ] Mobile

## Checklist
- [x] Testes adicionados/atualizados
- [x] Documentação atualizada
- [x] CI passa
- [x] Testado localmente
- [x] Sem credenciais no código

## Como Testar
1. Instalar dependências: `pnpm install`
2. Rodar backend: `cd packages/backend && npm run dev`
3. Rodar testes: `npm test`
4. Login com: email@teste.com / senha123

## Screenshots (se UI)
[Adicionar prints]

## Referências
- ANEXO_08 (Decisão JWT)
- Issue #123
```

---

### Code Review

**Checklist do Revisor:**
- [ ] Código segue padrões (.cursorrules)
- [ ] Nomenclatura correta (crm_*, dwu_*)
- [ ] Sem credenciais hardcoded
- [ ] Testes cobrem funcionalidade
- [ ] Mensagens de commit claras
- [ ] Sem console.log esquecido
- [ ] Documentação atualizada se necessário
- [ ] Performance OK (sem queries N+1)

---

## Backend

### Criar Nova Feature Backend

```bash
# 1. Branch
git checkout development
git pull origin development
git checkout -b feature/api-relatorios

# 2. Estrutura
cd packages/backend

# 3. Criar módulo
mkdir -p src/modules/reports
touch src/modules/reports/reports.service.ts
touch src/modules/reports/reports.controller.ts
touch src/modules/reports/reports.dto.ts

# 4. Implementar
# ... código ...

# 5. Criar testes
mkdir -p tests/modules/reports
touch tests/modules/reports/reports.service.spec.ts

# 6. Rodar testes
npm test

# 7. Commit
cd ../..
git add packages/backend
git commit -m "feat: Adiciona módulo de relatórios

- ReportsService com agregação de dados
- Endpoint GET /api/reports/conversao
- Testes unitários completos
"

# 8. Push e PR
git push origin feature/api-relatorios
```

---

### Migração de Banco de Dados

```bash
# 1. Branch
git checkout development
git checkout -b feature/adiciona-campo-score

# 2. Criar migration
cd database/migrations
touch 20251105_add_score_to_leads.sql

# 3. Escrever SQL
# ALTER TABLE crm_leads ADD COLUMN dwu_score INTEGER;

# 4. Testar localmente
psql dwu_crm_dev < 20251105_add_score_to_leads.sql

# 5. Atualizar ANEXO_02 (documentação)
# Adicionar campo dwu_score na tabela crm_leads

# 6. Commit
cd ../..
git add database/migrations
git add "CRM - Dinamize/docs/ANEXO_02_Estrutura_Dados_CRM.md"
git commit -m "feat: Adiciona campo de score em leads

Migration: 20251105_add_score_to_leads.sql
Documentação: ANEXO_02 atualizado
"

# 7. Push e PR
git push origin feature/adiciona-campo-score
```

---

## Frontend

### Criar Nova Tela

```bash
# 1. Branch
git checkout development
git pull origin development
git checkout -b feature/tela-dashboard

# 2. Estrutura
cd packages/frontend

# 3. Criar componentes
mkdir -p src/pages/Dashboard
touch src/pages/Dashboard/index.tsx
touch src/pages/Dashboard/Dashboard.module.css

mkdir -p src/components/MetricCard
touch src/components/MetricCard/index.tsx

# 4. Implementar
# ... código React ...

# 5. Usar tipos compartilhados
# import { Lead } from '@crm-dwu/shared/types';

# 6. Testar
npm run dev
npm test

# 7. Build
npm run build

# 8. Commit
cd ../..
git add packages/frontend
git commit -m "feat: Adiciona dashboard de vendas

- Componente MetricCard reutilizável
- Página Dashboard com métricas principais
- Integração com API de relatórios
"

# 9. Push e PR
git push origin feature/tela-dashboard
```

---

## Mobile

### Criar Nova Tela Mobile

```bash
# 1. Branch
git checkout development
git pull origin development
git checkout -b feature/app-listagem-leads

# 2. Estrutura
cd packages/mobile

# 3. Criar screen
mkdir -p src/screens/Leads
touch src/screens/Leads/LeadsListScreen.tsx
touch src/screens/Leads/LeadDetailScreen.tsx

# 4. Implementar
# ... código React Native ...

# 5. Usar tipos compartilhados
# import { Lead } from '@crm-dwu/shared/types';

# 6. Testar
npm run android
# ou
npm run ios

# 7. Commit
cd ../..
git add packages/mobile
git commit -m "feat: Adiciona listagem de leads no app

- LeadsListScreen com pull-to-refresh
- LeadDetailScreen com detalhes
- Navegação configurada
"

# 8. Push e PR
git push origin feature/app-listagem-leads
```

---

## Releases

### Release Checklist

#### Pré-Release

```bash
# Em development:
- [ ] Todas features mergeadas
- [ ] CI verde
- [ ] Testes passando (unit + integration)
- [ ] CHANGELOG.md atualizado
- [ ] Versão decidida (v1.x.x)
```

#### Release em Staging

```bash
# 1. Merge em staging
git checkout staging
git pull origin staging
git merge development --no-ff
git push origin staging

# 2. CI/CD faz deploy STAGING

# 3. Criar tag release candidate
git tag -a v1.1.0-rc.1 -m "Release Candidate 1.1.0"
git push origin --tags

# 4. Testes em staging (1-3 dias)
- [ ] Testes funcionais completos
- [ ] Testes de integração Dinamize REAL
- [ ] Testes de performance
- [ ] Validação de usuários (UAT)
- [ ] Validação de segurança

# 5. Encontrou bugs? Fix em staging
git checkout -b bugfix/correcao-staging
# ... corrigir ...
git checkout staging
git merge bugfix/correcao-staging
git push origin staging

# 6. Nova RC se necessário
git tag -a v1.1.0-rc.2 -m "Release Candidate 1.1.0 - Correções"
git push origin --tags
```

#### Release em Production

```bash
# Staging aprovado? Produção!

# 1. Merge staging → main
git checkout main
git pull origin main
git merge staging --no-ff -m "Release v1.1.0"

# 2. Criar tag FINAL
git tag -a v1.1.0 -m "Release v1.1.0: Integração ERPs

## Features
- Conectores ERP Totvs e SAP via OAuth2
- Dashboard de vendas com métricas em tempo real
- Relatório de conversão de leads

## Fixes  
- Correção na renovação de token Dinamize
- Validação aprimorada de email

## Breaking Changes
Nenhum
"

# 3. Push
git push origin main
git push origin v1.1.0

# 4. CI/CD automático:
# - Build production
# - Security scan
# - Deploy
# - Create GitHub Release
# - Generate release notes
# - Notify team (Slack/Email)

# 5. Verificar deploy
curl https://crm-dwu.com/health
# Status: healthy

# 6. Monitorar próximas 24h
# - Logs de erro
# - Performance
# - Integrações (Dinamize, ERPs)
```

#### Pós-Release

```bash
# 1. Atualizar development e staging
git checkout staging
git merge main
git push origin staging

git checkout development
git merge staging
git push origin development

# 2. Comunicar release
# - Email para stakeholders
# - Documentação atualizada
# - Release notes publicadas

# 3. Iniciar próximo ciclo
git checkout development
# Desenvolvimento v1.2.0 inicia
```

---

## Múltiplos Módulos (Monorepo)

### Commit Afetando Múltiplos Pacotes

```bash
# Mudança compartilhada (ex: tipo Lead)

# 1. Alterar shared
cd packages/shared
# Adicionar campo em Lead interface

# 2. Atualizar backend
cd ../backend
# Usar novo campo

# 3. Atualizar frontend  
cd ../frontend
# Usar novo campo

# 4. Atualizar mobile
cd ../mobile
# Usar novo campo

# 5. Commit TUDO junto
cd ../..
git add packages/shared packages/backend packages/frontend packages/mobile
git commit -m "feat: Adiciona campo score em Lead

Afeta:
- shared: Tipo Lead atualizado
- backend: API retorna score
- frontend: Exibe score na listagem
- mobile: Exibe score no app
"
```

---

### Deploy Seletivo

```bash
# CI/CD detecta mudanças e deploys apenas afetados

# Apenas backend mudou
git add packages/backend
git commit -m "fix: Corrige validação backend"
# CI/CD: Deploy apenas backend

# Apenas frontend mudou
git add packages/frontend
git commit -m "feat: Nova tela frontend"
# CI/CD: Deploy apenas frontend

# Shared mudou (afeta tudo)
git add packages/shared packages/backend packages/frontend
git commit -m "refactor: Atualiza tipos compartilhados"
# CI/CD: Deploy backend + frontend + mobile
```

---

## Convenções de Nomenclatura

### Branches

```bash
# Features
feature/login-jwt
feature/integracao-dinamize
feature/dashboard-vendas
feature/erp-totvs

# Bugfix
bugfix/validacao-email
bugfix/sincronizacao-dinamize
bugfix/memoria-leak

# Hotfix (urgente em produção)
hotfix/token-expirado
hotfix/erro-critico-login
hotfix/seguranca-xss
```

**Regras:**
- Minúsculas
- Hífen separador (kebab-case)
- Descritivo (não usar só número de issue)
- Português OK

---

### Tags

```bash
# Releases
v1.0.0          # Release produção
v1.1.0-rc.1     # Release candidate
v1.0.0-beta.1   # Beta
v1.0.0-alpha.1  # Alpha

# Formato
v[MAJOR].[MINOR].[PATCH][-PRERELEASE]
```

---

### Commits

```bash
# Bom
git commit -m "feat: Adiciona autenticação JWT"
git commit -m "fix: Corrige renovação token Dinamize"
git commit -m "docs: Atualiza ANEXO_08 com decisão JWT"

# Ruim
git commit -m "update"
git commit -m "fix"
git commit -m "WIP"
git commit -m "asdfjkl"
```

---

## Troubleshooting

### Problema: Merge Conflict

```bash
# Durante merge
git merge development
# CONFLICT!

# Resolver:
1. Abrir arquivos com conflito
2. Procurar por <<<<<<< e >>>>>>>
3. Escolher versão correta
4. Remover marcadores
5. git add arquivo.ts
6. git commit (sem mensagem, usa padrão de merge)
```

---

### Problema: Commitou em Branch Errada

```bash
# Commitou em main em vez de feature

# 1. Criar branch com commit
git branch feature/nome-correto

# 2. Voltar main sem o commit
git reset --hard HEAD~1

# 3. Ir para branch correta
git checkout feature/nome-correto
```

---

### Problema: Precisa Desfazer Push

```bash
# NÃO use force push em main/staging!

# Solução: Revert
git revert [commit-hash]
git push origin [branch]

# Cria novo commit desfazendo mudanças
```

---

## Ferramentas Recomendadas

### Git Clients

- **CLI:** Git Bash (Windows), Terminal (Mac/Linux)
- **GUI:** GitKraken, SourceTree, GitHub Desktop
- **IDE:** VSCode Git integrado

### Aliases Úteis

```bash
# Adicionar ao ~/.gitconfig

[alias]
  st = status
  co = checkout
  br = branch
  ci = commit
  ca = commit --amend
  l = log --oneline --graph --all
  p = pull origin
  po = push origin
  undo = reset --soft HEAD~1
```

**Uso:**
```bash
git st        # status
git co main   # checkout main
git l         # log bonito
```

---

## Resumo dos Fluxos

### Feature Normal

```
development → feature/nome → development → staging → main
```

### Hotfix Urgente

```
main → hotfix/nome → main → staging → development
```

### Release

```
development (features) → staging (testes) → main (tag v1.x.x) → production
```

---

## Checklist Diário

### Antes de Começar o Dia

```bash
- [ ] git checkout development
- [ ] git pull origin development
- [ ] Verificar se CI está verde
- [ ] Ler mensagens do time (PRs, issues)
```

### Antes de Ir Embora

```bash
- [ ] Commit mudanças (ou stash)
- [ ] Push branch (backup)
- [ ] Atualizar status (se pair programming)
- [ ] Deixar testes passando
```

### Antes de PR

```bash
- [ ] Rebase com development (atualizar)
- [ ] Rodar testes localmente
- [ ] Rodar linter
- [ ] Atualizar documentação se necessário
- [ ] Revisar diff completo
- [ ] Remover console.log, debugger
```

---

## Referências

- **GitLab Flow:** https://docs.gitlab.com/ee/topics/gitlab_flow.html
- **Semantic Versioning:** https://semver.org/
- **Conventional Commits:** https://www.conventionalcommits.org/
- **Git Best Practices:** https://git-scm.com/book/

---

**Última atualização:** 2025-11-05  
**Versão:** 1.0  
**Mantido por:** Equipe DWU CRM

