# ANEXO 01 - Levantamento Técnico de Integração com Dinamize API
## CRM DWU - Documentação Detalhada da API

**Data:** 2025-01-04  
**Versão:** 1.0  
**Status:** ✅ Análise Completa

---

## 📋 Sumário Executivo

Este anexo apresenta o levantamento técnico completo realizado sobre a API Dinamize, incluindo endpoints mapeados, formatos de dados, limites técnicos, códigos de erro e estratégias de integração identificadas durante a análise da documentação oficial.

---

## 1. Informações Gerais da API

### 1.1 URL Base e Documentação
- **URL Base Produção:** `https://api.dinamize.com`
- **Documentação Interativa:** `https://panel.dinamize.com/apidoc/`
- **Versão da API:** 1.0.0
- **Ambiente Sandbox/Teste:** Não identificado ambiente separado (mesma URL)

### 1.2 Características Técnicas
- ✅ **Protocolo:** HTTPS apenas (SSL v3 e TLS a partir do 1.2)
- ✅ **Método HTTP:** POST (todos os endpoints, inclusive para buscar/listar)
- ✅ **Formato de Dados:** JSON com charset UTF-8
- ✅ **Content-Type:** `application/json; charset=utf-8`
- ✅ **Timeout:** 20 segundos por requisição
- ✅ **Resposta HTTP:** Sempre retorna 200 (validar campo `code` na resposta)

### 1.3 Formato de Data/Hora
- **Formato:** `YYYY-MM-DD HH:MM:SS`
- **Exemplo:** `2025-01-15 10:30:00`

### 1.4 Estrutura Padrão de Resposta
Todas as respostas seguem o formato:
```json
{
  "code": "480001",
  "code_detail": "Success",
  "body": { ... },
  "request_unique": "######",
  "warning": []
}
```

---

## 2. Endpoints Mapeados

### 2.1 Autenticação

#### POST /auth
**Objetivo:** Obter token de autenticação para requisições subsequentes

**URL Completa:** `https://api.dinamize.com/auth`

**Headers:**
```
Content-Type: application/json; charset=utf-8
```

**Requisição:**
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
- `240029`: Client code is invalid / The relationship between user and client wasn't found

**Características do Token:**
- Token expira em **1 hora de inatividade**
- Token pode permanecer ativo por no máximo **24 horas**
- Token deve ser incluído no header `auth-token` em todas as requisições
- ⚠️ Não identificado endpoint de refresh token na documentação

### 2.2 Contatos/Leads

#### POST /emkt/contact/search
**Objetivo:** Buscar/listar contatos com filtros e paginação

**URL Completa:** `https://api.dinamize.com/emkt/contact/search`

**Headers:**
```
auth-token: {token}
Content-Type: application/json; charset=utf-8
```

**Requisição:**
```json
{
  "contact-list_code": "1",
  "page_number": "1",
  "page_size": "10",
  "status_contact": "NO_REST",
  "search": [
    {
      "field": "email",
      "operator": "=",
      "value": "contato@exemplo.com"
    },
    {
      "field": "name",
      "operator": "*v*",
      "value": "João"
    }
  ],
  "order": [
    {
      "field": "name",
      "type": "DESC"
    }
  ]
}
```

**Parâmetros:**
- `contact-list_code` (obrigatório): Código da lista de contatos
- `page_number` (opcional): Número da página
- `page_size` (opcional): Quantidade por página (Máx: 10.000)
- `status_contact` (opcional): `REST_ONLY` (em descanso) | `NO_REST` (não em descanso)
- `search` (opcional): Array de filtros
- `order` (opcional): Array de ordenação

**Operadores de Busca:**
- `=`, `!=` (igual, diferente)
- `*v*`, `!*v*` (contém, não contém)
- `v*`, `!v*` (começa com, não começa com)
- `*v`, `!*v` (termina com, não termina com)
- `<`, `>`, `<=`, `>=` (para datas)

**Campos Pesquisáveis:**
- `name`: Nome do contato
- `email`: Email do contato
- `external_code`: Código externo
- `insert_date`: Data de inclusão (formato: `YYYY-MM-DD HH:MM:SS`)
- `status_email`: Status do email (`V` = válido, `I` = inválido)

**Resposta:**
```json
{
  "code": "480001",
  "code_detail": "Success",
  "body": {
    "next": true,
    "items": [
      {
        "code": "123456",
        "email": "contato@exemplo.com",
        "name": "Nome do Contato",
        "external_code": "EXT001",
        "insert_date": "2025-01-15 10:30:00",
        "status": "V",
        "optout": false,
        "spam": false,
        "total_clicks": "10",
        "total_sents": "5",
        "total_views": "20",
        "custom_fields": {
          "cmp4": "valor1",
          "cmp5": "valor2"
        }
      }
    ]
  },
  "request_unique": "######",
  "warning": []
}
```

**Paginação:** Campo `next: true` indica que existem mais registros

#### POST /emkt/contact/get
**Objetivo:** Obter contato específico por ID

**Requisição:**
```json
{
  "contact_code": "123456",
  "contact-list_code": "1"
}
```

**Resposta:** Retorna dados completos do contato

#### POST /emkt/contact/add
**Objetivo:** Criar novo contato

**Requisição:**
```json
{
  "email": "novo@exemplo.com",
  "name": "Novo Contato",
  "external_code": "EXT002",
  "contact-list_code": "1",
  "date_rest": "2025-12-31",
  "custom_fields": {
    "cmp4": "valor1",
    "cmp5": "valor2"
  }
}
```

**Parâmetros:**
- `email` (obrigatório): Email do contato
- `name` (opcional): Nome do contato
- `external_code` (opcional): Código externo
- `contact-list_code` (obrigatório): Código da lista
- `date_rest` (opcional): Data de descanso (contato não recebe emails até o final do dia)
- `custom_fields` (opcional): Campos personalizados (cmp4, cmp5, etc.)

**Resposta:**
```json
{
  "code": "480001",
  "code_detail": "Success",
  "body": {
    "code": "123457"
  }
}
```

#### POST /emkt/contact/update
**Objetivo:** Atualizar contato existente

**Requisição:**
```json
{
  "contact_code": "123456",
  "contact-list_code": "1",
  "name": "Nome Atualizado",
  "custom_fields": {
    "cmp4": "novo_valor"
  }
}
```

#### POST /emkt/contact/delete
**Objetivo:** Deletar contato

**Requisição:**
```json
{
  "contact_code": "123456",
  "contact-list_code": "1"
}
```

#### POST /emkt/contact/history
**Objetivo:** Obter histórico de ações do contato

#### POST /emkt/contact/integration_search
**Objetivo:** Buscar contatos por código de integração

---

## 3. Rate Limiting

### 3.1 Limites Identificados
- **Por minuto:** 60 requisições

### 3.2 Comportamento ao Exceder Limite
Quando o limite é excedido, a API retorna:
```json
{
  "code": "240024",
  "code_detail": "Requests limit exceeded",
  "body": {
    "retry-after": "17"
  },
  "request_unique": "######",
  "warning": []
}
```

**Campo `retry-after`:** Indica quantos segundos aguardar antes de nova tentativa

### 3.3 Estratégia de Tratamento
- Implementar fila de requisições
- Respeitar o campo `retry-after` antes de novas tentativas
- Implementar backoff exponencial para múltiplas falhas
- Monitorar quantidade de requisições por minuto

---

## 4. Escopo de Integração

### 4.1 Funcionalidades Prioritárias (Mês 1)
1. **Autenticação e gerenciamento de tokens**
   - Obter token de autenticação
   - Gerenciar expiração e renovação
   - Armazenar tokens de forma segura

2. **Sincronização de contatos/leads**
   - Buscar/listar contatos da Dinamize
   - Criar contatos no CRM e sincronizar com Dinamize
   - Atualizar contatos existentes
   - Buscar contato por ID ou email

3. **Gerenciamento básico de listas**
   - Identificar listas disponíveis
   - Associar contatos a listas

### 4.2 Funcionalidades Futuras
- Webhooks (verificar disponibilidade com suporte Dinamize)
- Relatórios de campanhas
- Histórico detalhado de interações
- Campos customizados avançados
- Segmentação avançada

---

## 5. Tratamento de Erros

### 5.1 Códigos de Erro Comuns

| Código | Descrição | Ação Recomendada |
|--------|-----------|------------------|
| `480001` | Success | Operação bem-sucedida |
| `240002` | Password is required | Validar envio de senha |
| `240003` | Username is required | Validar envio de usuário |
| `240004` | Username or password are invalid | Retentar com credenciais corretas |
| `240024` | Requests limit exceeded | Aguardar retry-after e tentar novamente |
| `240029` | Client code is invalid | Validar código do cliente |

### 5.2 Estratégia de Tratamento
- Todos os erros retornam HTTP 200
- Sempre validar campo `code` na resposta
- Implementar retry com backoff exponencial
- Logar todos os erros para análise
- Notificar administradores em caso de erros críticos

---

## 6. Próximos Passos

### 6.1 Validações Necessárias
1. Validar endpoints com credenciais reais de desenvolvimento
2. Testar fluxo completo de autenticação
3. Validar rate limiting com testes controlados
4. Verificar comportamento em casos de erro

### 6.2 Documentação Adicional
1. Documentar campos customizados (cmp4, cmp5, etc.)
2. Mapear endpoints de listas de marketing
3. Verificar suporte a webhooks
4. Criar casos de teste para cada endpoint

### 6.3 Implementação
1. Criar cliente de API para comunicação com Dinamize
2. Implementar tratamento de rate limiting
3. Criar sistema de filas para requisições
4. Implementar sincronização incremental

---

## 7. Referências

- **Documentação Oficial:** https://panel.dinamize.com/apidoc/
- **URL Base da API:** https://api.dinamize.com
- **Formato de Dados:** JSON (UTF-8)
- **Versão da API:** 1.0.0

---

**Última atualização:** 2025-01-05  
**Responsável:** Equipe DWU CRM  
**Versão:** 1.0


