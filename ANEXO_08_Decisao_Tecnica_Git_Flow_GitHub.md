# ANEXO 08 - Decisão: Git Flow + Repositórios + Ambientes
## CRM DWU - Padronização de Versionamento e Deploy

**Data:** 2025-11-05  
**Versão:** 1.0  
**Status:** ✅ Decisão Aprovada

---

## Decisões Finais

1. **Repositórios:** Multirepo (6 repos GitHub separados)
2. **Metodologia:** GitLab Flow (branch = ambiente)
3. **Versionamento:** Semantic Versioning independente
4. **Ambientes:** development → staging → main
5. **Deploy:** Automático e isolado por repo

---

## 1. Estrutura Multirepo

### 6 Repositórios GitHub

```
GitHub Organization: dwu

dwu_crm_backend       → API Node.js (Servidor A)
dwu_crm_frontend      → Web React (Servidor B)
dwu_crm_mobile        → App React Native (Stores)
dwu_crm_shared        → Types/Utils (npm privado @dwu/crm-shared)
dwu_crm_database      → Migrations SQL
dwu_crm_docs          → Documentação
```

### Por que Multirepo

| Vantagem | Benefício |
|----------|-----------|
| **Isolamento** | Backend quebra ≠ frontend para |
| **Controle** | Permissões GitHub granulares |
| **Segurança** | .env separados, breach isolado |
| **Deploy independente** | Backend 5x/semana, mobile 1x/mês |
| **Sem conflitos** | Impossível commitar docs em código |
| **CI/CD simples** | 1 repo = 1 pipeline |

**Decisão:** Controle e isolamento > velocidade de compartilhamento

---

## 2. GitLab Flow (Metodologia)

### Branches (Todos os Repos)

```
main        → Produção (estável, sempre deployável)
  ↑
staging     → Pré-produção (testes integração Dinamize real)
  ↑
development → Desenvolvimento (integração de features)
  ↑
feature/*   → Features individuais
```

**Proteção GitHub:**
- `main`: PR obrigatório, 2 aprovações, CI passa, sem force push
- `staging`: PR obrigatório, 1 aprovação, CI passa
- `development`: PR obrigatório, CI passa

**Por que GitLab Flow:**
- ✅ Staging obrigatório (testa Dinamize antes de produção)
- ✅ Branch = Ambiente (claro e direto)
- ❌ Git Flow: Complexo (develop + release branches)
- ❌ GitHub Flow: Sem staging (arriscado)

---

## 3. Versionamento (SemVer)

### Formato: vMAJOR.MINOR.PATCH

```
v1.2.3
│ │ │
│ │ └─ PATCH: Bugfix (compatível)
│ └─── MINOR: Nova feature (compatível)
└───── MAJOR: Breaking change (incompatível)
```

### Estratégia: Independente por Repo

```
dwu_crm_backend:  v1.2.0  (evolui rápido)
dwu_crm_frontend: v1.1.5  (estável)
dwu_crm_mobile:   v1.0.3  (atualiza menos)
dwu_crm_shared:   v1.2.0  (sincronizado com backend)
```

**Vantagem:** Cada sistema no próprio ritmo

**Release coordenada quando necessário:**
```
Release Sistema CRM v1.1.0 =
├── backend v1.2.0
├── frontend v1.1.5
├── mobile v1.0.3
└── shared v1.2.0
```

### Roadmap Versões

```
v0.1.0-alpha  → Mês 1 (estrutura base)
v0.5.0-alpha  → Mês 2 (integração Dinamize)
v1.0.0        → Mês 3 (MVP produção)
v1.1.0        → Mês 3 (conectores ERP)
v1.2.0        → Mês 4 (dashboard)
```

---

## 4. Ambientes

### 3 Ambientes por Repo

| Ambiente | Branch | Localhost | Futuro | BD |
|----------|--------|-----------|--------|-----|
| **Development** | development | :3001/:5173 | dev.crm-dwu.com | dwu_crm_dev |
| **Staging** | staging | :3002/:5174 | staging.crm-dwu.com | dwu_crm_staging |
| **Production** | main | :3000/:5175 | crm-dwu.com | dwu_crm_prod |

### Variáveis de Ambiente

**Cada repo tem .env próprio:**

```bash
# dwu_crm_backend/.env.development
PORT=3001
DATABASE_URL=postgresql://localhost/dwu_crm_dev
DINAMIZE_API_URL=https://sandbox.dinamize.com
JWT_SECRET=dev_secret

# dwu_crm_frontend/.env.development
VITE_API_URL=http://localhost:3001

# .gitignore (todos repos)
.env
.env.*
!.env.example
```

**Início:** Localhost (3 portas diferentes)  
**Futuro:** Servidores separados ou Docker

---

## 5. Deploy

### Estratégia por Ambiente

```
Push → development  = Deploy DEV automático
Push → staging      = Deploy STAGING automático (+ testes integração)
Push → main + tag   = Deploy PROD automático (+ GitHub Release)
```

### CI/CD Simples

```yaml
# Cada repo: .github/workflows/deploy.yml

on:
  push:
    branches: [development, staging, main]
    tags: ['v*']

jobs:
  deploy:
    if: github.ref == 'refs/heads/development'
    # SSH + git pull + restart (ou Docker)
    
  deploy-staging:
    if: github.ref == 'refs/heads/staging'
    # SSH + git pull + restart + integration tests
    
  deploy-prod:
    if: github.ref == 'refs/heads/main'
    # SSH + git pull + restart + create release
```

**Deploy independente:** Backend atualiza sem afetar frontend

---

## 6. Código Compartilhado

### dwu_crm_shared (npm privado)

**Conteúdo:**
- Types (Lead, Company, Opportunity)
- Enums (LeadStatus, SyncStatus)
- Validações (email, phone, CNPJ)
- Constantes (DINAMIZE_RATE_LIMIT)

**Publicar:**
```bash
cd dwu_crm_shared
npm version minor  # v1.0.0 → v1.1.0
npm publish        # GitHub Packages
```

**Usar:**
```bash
# dwu_crm_backend
npm install @dwu/crm-shared@1.1.0

# dwu_crm_frontend  
npm install @dwu/crm-shared@1.1.0
```

**Atualização:** Shared muda → publica → backend/frontend atualizam package.json

---

## 7. Processo de Release

```bash
# 1. Features em development (ambos repos)
backend: feature/* → development
frontend: feature/* → development

# 2. Merge para staging (testar integração)
backend: development → staging
frontend: development → staging
# Testes 1-3 dias com Dinamize real

# 3. Staging OK? Release em main
backend: staging → main + tag v1.1.0
frontend: staging → main + tag v1.1.0

# 4. CI/CD cria GitHub Release automático
# 5. Deploy produção
```

**Tag em main = Release oficial**

---

## Referências

- **GitLab Flow:** https://docs.gitlab.com/ee/topics/gitlab_flow.html
- **Semantic Versioning:** https://semver.org/
- **GitHub Actions:** https://docs.github.com/actions
- **GitHub Packages:** https://docs.github.com/packages
- **Manual Prático:** MANUAL_GIT_FLOW.md

---

**Criado:** 2025-11-05  
**Decisão:** Multirepo (controle + isolamento + segurança)
