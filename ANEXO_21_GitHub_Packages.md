# Configuração GitHub Packages para @dwu/shared

Este documento explica como configurar e usar o pacote `@dwu/shared` via GitHub Packages.

## Publicação Automática

O pacote `@dwu/shared` é publicado automaticamente no GitHub Packages quando:
- Push para `main` ou `master` (publica versão estável, incrementa patch automaticamente)
- Criação de tag `v*` (ex: `v1.0.0`) - versão estável
- Criação de tag `v*-beta` ou `v*-alpha` (ex: `v1.0.0-beta`) - versão experimental
- Execução manual do workflow

**Estrutura Simplificada:**
O pacote `@dwu/shared` usa apenas `main` + `feature/*` (sem development/staging), pois é uma biblioteca e não precisa de múltiplos ambientes. O versionamento (v1.0.0, v1.0.0-beta) já resolve diferentes estágios de maturidade.

## Configuração Local

### 1. Criar Personal Access Token (PAT)

1. Acesse: https://github.com/settings/tokens
2. Clique em "Generate new token (classic)"
3. Selecione escopos:
   - `read:packages` (para instalar)
   - `write:packages` (para publicar, se necessário)
4. Copie o token gerado

### 2. Configurar autenticação local

**Opção A: Via .npmrc (recomendado)**

Crie/edite `.npmrc` na raiz do projeto:

```ini
@dwu:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=SEU_TOKEN_AQUI
```

**Opção B: Via comando npm**

```bash
npm config set @dwu:registry https://npm.pkg.github.com
npm config set //npm.pkg.github.com/:_authToken SEU_TOKEN_AQUI
```

### 3. Instalar dependências

```bash
npm install
```

## Uso com Docker (Desenvolvimento Local)

Para desenvolvimento local, o Docker Compose usa `file:../dwu_crm_shared` automaticamente.

O `docker-compose.yml` já está configurado para:
- Usar `file:../dwu_crm_shared` quando disponível
- Funcionar sem necessidade de autenticação GitHub

## CI/CD

No GitHub Actions, o CI usa automaticamente o GitHub Packages:
- Autenticação via `GITHUB_TOKEN` (automático)
- Build do Docker usa `USE_GITHUB_PACKAGES=true`
- Não requer configuração adicional

## Estrutura de Versões

O workflow de publicação segue semantic versioning:
- **Patch**: `0.1.0` → `0.1.1` (correções) - automático em push para main
- **Minor**: `0.1.0` → `0.2.0` (novas features) - via tag ou workflow manual
- **Major**: `0.1.0` → `1.0.0` (breaking changes) - via tag ou workflow manual
- **Beta/Alpha**: `v1.0.0-beta`, `v1.0.0-alpha` - versões experimentais via tags

## Estrutura de Branches

O pacote `@dwu/shared` usa apenas:
- `main` → Branch principal (publica automaticamente em push)
- `feature/*` → Features (não publica, apenas desenvolvimento)

**Não usa** `development` ou `staging` pois é uma biblioteca e não precisa de múltiplos ambientes. O versionamento (v1.0.0, v1.0.0-beta) já resolve diferentes estágios de maturidade.

## Verificar Publicação

Após publicação, verifique em:
https://github.com/dwu-it-solutions/dwu_crm_shared/packages

## Troubleshooting

### Erro: "401 Unauthorized"
- Verifique se o token está correto no `.npmrc`
- Confirme que o token tem escopo `read:packages`

### Erro: "404 Not Found"
- Verifique se o pacote foi publicado
- Confirme o nome do pacote: `@dwu/shared`
- Verifique se está usando o escopo correto: `@dwu`

### Erro no Docker Build
- Certifique-se que `GITHUB_TOKEN` está disponível no CI
- Verifique se `USE_GITHUB_PACKAGES=true` está sendo passado
