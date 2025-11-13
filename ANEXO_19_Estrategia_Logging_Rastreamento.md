# ANEXO 19 - Estratégia de Logging e Rastreamento
## CRM DWU - Documentação Técnica

**Data:** 2025-11-12  
**Versão:** 1.0  
**Status:** ✅ Implementado

---

## 📋 Sumário Executivo

Este documento descreve a estratégia de logging implementada no módulo Dinamize para rastreamento, debugging e monitoramento. A estratégia utiliza o NestJS Logger com diferentes níveis de log para facilitar a identificação de problemas e o acompanhamento do fluxo de sincronização.

---

## 1. Princípios da Estratégia

### 1.1 Níveis de Log

Utilizamos 4 níveis principais de log do NestJS:

| Nível | Uso | Quando Usar |
|-------|-----|-------------|
| **`log`** | Operações importantes e sucessos | Início/fim de requisições, operações críticas concluídas |
| **`debug`** | Detalhes para troubleshooting | Dados intermediários, estados internos, payloads preparados |
| **`warn`** | Situações recuperáveis | Retries, dados ausentes mas não críticos, fallbacks |
| **`error`** | Falhas e erros críticos | Exceções, erros de validação, falhas permanentes |

### 1.2 Informações Contextuais

Todos os logs devem incluir informações contextuais relevantes:

- **IDs de rastreamento**: `leadId`, `leadSyncId`, `queueId`, `jobId`, `companyId`
- **Operações**: `operation` (create/update/delete)
- **Status**: Status atual de processos
- **Tempos**: Quando relevante para performance

### 1.3 Segurança

- **Dados sensíveis**: Sempre redigir emails e informações pessoais em logs
- **Payloads**: Usar `[REDACTED]` para campos sensíveis
- **Stack traces**: Incluir apenas em logs de erro quando necessário

---

## 2. Pontos Estratégicos de Logging

### 2.1 Controller (`DinamizeSyncController`)

O controller é o ponto de entrada das requisições HTTP. Logs estratégicos:

#### Log 1: Início da Requisição
```typescript
this.logger.log(`Iniciando sincronização: leadId=${syncDto.leadId}, operation=${syncDto.operation}, listCode=${syncDto.listCode}, companyId=${companyId}`);
```
**Nível:** `log`  
**Quando:** Início de cada requisição  
**Propósito:** Rastreamento de requisições recebidas

#### Log 2: Criação de LeadSync
```typescript
this.logger.log(`Criando novo LeadSync: leadId=${syncDto.leadId}, listId=${syncDto.listCode}`);
```
**Nível:** `log`  
**Quando:** Novo registro de sincronização criado  
**Propósito:** Identificar novos relacionamentos Lead-Lista

#### Log 3: LeadSync Existente
```typescript
this.logger.debug(`LeadSync existente encontrado: id=${leadSync.id}, status=${leadSync.status}`);
```
**Nível:** `debug`  
**Quando:** LeadSync já existe no banco  
**Propósito:** Troubleshooting de sincronizações duplicadas

#### Log 4: Payload Preparado
```typescript
this.logger.debug(`Payload preparado para sincronização: ${JSON.stringify({ ...payload, email: '[REDACTED]' })}`);
```
**Nível:** `debug`  
**Quando:** Payload montado antes de enfileirar  
**Propósito:** Validar dados enviados para Dinamize

#### Log 5: Sucesso no Enfileiramento
```typescript
this.logger.log(`Sincronização enfileirada com sucesso: leadSyncId=${leadSync.id}, operation=${syncDto.operation}`);
```
**Nível:** `log`  
**Quando:** Job enfileirado com sucesso  
**Propósito:** Confirmação de sucesso da requisição

#### Logs de Erro
```typescript
// Lead não encontrado
this.logger.warn(`Lead ${syncDto.leadId} não encontrado para company ${companyId}`);

// Email ausente
this.logger.error(`Lead ${syncDto.leadId} não possui email para sincronização. Company: ${companyId}, ListCode: ${syncDto.listCode}`);
```

---

### 2.2 Service (`DinamizeSyncService`)

O service gerencia o enfileiramento de jobs. Logs estratégicos:

#### Log: Job Enfileirado
```typescript
this.logger.log(`Sync job enfileirado: ${operation} para leadSync ${leadSyncId}`);
```
**Nível:** `log`  
**Quando:** Job adicionado ao BullMQ com sucesso  
**Propósito:** Rastreamento de jobs na fila

**Nota:** Logs de debug foram removidos para reduzir verbosidade, mantendo apenas o essencial.

---

### 2.3 Processor (`DinamizeSyncProcessor`)

O processor executa os jobs assíncronos. Logs estratégicos:

#### Log 1: Início do Processamento
```typescript
this.logger.log(`Processando sync job ${job.id}: ${operation} para leadSync ${leadSyncId}`);
```
**Nível:** `log`  
**Quando:** Job começa a ser processado  
**Propósito:** Rastreamento de processamento assíncrono

#### Log 2: Erro no Processamento
```typescript
this.logger.error(`Erro ao processar sync job ${job.id}: ${error.message}`);
```
**Nível:** `error`  
**Quando:** Exceção capturada durante processamento  
**Propósito:** Identificar falhas e causas

#### Event Handlers (BullMQ)
```typescript
@OnWorkerEvent('completed')
onCompleted(job: Job) {
  this.logger.log(`Job ${job.id} concluído com sucesso`);
}

@OnWorkerEvent('failed')
onFailed(job: Job, error: Error) {
  this.logger.error(`Job ${job.id} falhou: ${error.message}`);
}
```
**Nível:** `log` (completed) / `error` (failed)  
**Quando:** Eventos do BullMQ  
**Propósito:** Rastreamento de ciclo de vida dos jobs

---

## 3. Fluxo de Rastreamento Completo

### 3.1 Fluxo de Sincronização Bem-Sucedida

```
1. [Controller] log: "Iniciando sincronização: leadId=X, operation=create..."
2. [Controller] log: "Criando novo LeadSync: leadId=X, listId=Y" (ou debug se existente)
3. [Controller] debug: "Payload preparado para sincronização: {...}"
4. [Controller] log: "Sincronização enfileirada com sucesso: leadSyncId=Z, operation=create"
5. [Service] log: "Sync job enfileirado: create para leadSync Z"
6. [Processor] log: "Processando sync job 123: create para leadSync Z"
7. [Processor] log: "Job 123 concluído com sucesso" (via @OnWorkerEvent)
```

### 3.2 Fluxo com Erro

```
1. [Controller] log: "Iniciando sincronização: leadId=X..."
2. [Controller] warn: "Lead X não encontrado para company Y"
   → throw NotFoundException

OU

1. [Controller] log: "Iniciando sincronização..."
2. [Controller] error: "Lead X não possui email para sincronização..."
   → throw BadRequestException

OU (durante processamento)

1. [Processor] log: "Processando sync job 123..."
2. [Processor] error: "Erro ao processar sync job 123: [mensagem]"
3. [Processor] error: "Job 123 falhou: [mensagem]" (via @OnWorkerEvent)
```

---

## 4. Boas Práticas

### 4.1 Formato de Mensagens

✅ **Bom:**
```typescript
this.logger.log(`Sincronização enfileirada: leadSyncId=${leadSync.id}, operation=${operation}`);
```

❌ **Ruim:**
```typescript
this.logger.log('Sincronização enfileirada'); // Sem contexto
```

### 4.2 Redação de Dados Sensíveis

✅ **Bom:**
```typescript
this.logger.debug(`Payload: ${JSON.stringify({ ...payload, email: '[REDACTED]' })}`);
```

❌ **Ruim:**
```typescript
this.logger.debug(`Payload: ${JSON.stringify(payload)}`); // Expõe email
```

### 4.3 Níveis Apropriados

✅ **Bom:**
```typescript
this.logger.log(`Operação concluída: ${operation}`); // Sucesso importante
this.logger.debug(`Status atualizado: ${status}`); // Detalhe interno
```

❌ **Ruim:**
```typescript
this.logger.error(`Operação concluída: ${operation}`); // Não é erro!
this.logger.log(`Status atualizado: ${status}`); // Muito verboso
```

### 4.4 Contexto Suficiente

✅ **Bom:**
```typescript
this.logger.error(`Lead ${leadId} não possui email. Company: ${companyId}, ListCode: ${listCode}`);
```

❌ **Ruim:**
```typescript
this.logger.error('Email não encontrado'); // Sem contexto
```

---

## 5. Exemplo Completo: Controller

```typescript
@Post('queue')
@ApiOperation({ summary: 'Enfileirar sincronização de lead com Dinamize' })
async queueSync(@Body() syncDto: SyncLeadDto, @CompanyId() companyId: number) {
  // Log 1: Início da requisição (trace)
  this.logger.log(`Iniciando sincronização: leadId=${syncDto.leadId}, operation=${syncDto.operation}, listCode=${syncDto.listCode}, companyId=${companyId}`);

  // Buscar lead
  const lead = await this.leadsRepository.findById(syncDto.leadId, companyId);
  if (!lead) {
    this.logger.warn(`Lead ${syncDto.leadId} não encontrado para company ${companyId}`);
    throw new NotFoundException(`Lead ${syncDto.leadId} não encontrado`);
  }

  // Buscar ou criar LeadSync
  let leadSync = await this.prisma.leadSync.findFirst({
    where: {
      leadId: syncDto.leadId,
      listId: syncDto.listCode
    }
  });

  if (!leadSync) {
    // Log 2: Criação de novo LeadSync (info)
    this.logger.log(`Criando novo LeadSync: leadId=${syncDto.leadId}, listId=${syncDto.listCode}`);
    leadSync = await this.prisma.leadSync.create({
      data: {
        leadId: syncDto.leadId,
        listId: syncDto.listCode,
        status: 'pending'
      }
    });
  } else {
    // Log 3: LeadSync existente encontrado (debug)
    this.logger.debug(`LeadSync existente encontrado: id=${leadSync.id}, status=${leadSync.status}`);
  }

  // Preparar payload para Dinamize
  const email = lead.email ?? lead.contacts?.[0]?.email ?? '';
  const name = [lead.firstName, lead.lastName].filter(Boolean).join(' ') 
    ?? lead.contacts?.[0]?.name 
    ?? '';

  if (!email) {
    this.logger.error(`Lead ${syncDto.leadId} não possui email para sincronização. Company: ${companyId}, ListCode: ${syncDto.listCode}`);
    throw new BadRequestException('Lead não possui email para sincronização');
  }

  const payload: any = {
    email,
    'contact-list_code': syncDto.listCode
  };

  if (name) {
    payload.name = name;
  }

  if (syncDto.contactCode) {
    payload.contact_code = syncDto.contactCode;
  }

  // Log 4: Payload preparado (debug - útil para troubleshooting)
  this.logger.debug(`Payload preparado para sincronização: ${JSON.stringify({ ...payload, email: '[REDACTED]' })}`);

  // Enfileirar sincronização
  await this.syncService.queueSync(leadSync.id, syncDto.operation, payload, companyId);

  // Log 5: Sucesso no enfileiramento (info)
  this.logger.log(`Sincronização enfileirada com sucesso: leadSyncId=${leadSync.id}, operation=${syncDto.operation}`);

  return {
    message: 'Sincronização enfileirada com sucesso',
    leadSyncId: leadSync.id,
    operation: syncDto.operation
  };
}
```

---

## 6. Benefícios da Estratégia

### 6.1 Rastreamento End-to-End

Com os logs estratégicos, é possível rastrear uma requisição desde o controller até o processamento assíncrono:

1. **Requisição HTTP** → Log no controller
2. **Enfileiramento** → Log no service
3. **Processamento** → Logs no processor
4. **Conclusão** → Event handler do BullMQ

### 6.2 Debugging Eficiente

- **Logs de debug**: Ativados apenas quando necessário (variável de ambiente)
- **Contexto completo**: IDs e informações relevantes em cada log
- **Redação de dados sensíveis**: Segurança mantida

### 6.3 Monitoramento

- **Logs de erro**: Identificam problemas rapidamente
- **Logs de sucesso**: Confirmam operações concluídas
- **Logs de warning**: Alertam sobre situações recuperáveis

### 6.4 Performance

- **Logs mínimos em produção**: Apenas `log`, `warn` e `error`
- **Debug desabilitado**: Reduz overhead em produção
- **Informações essenciais**: Sem verbosidade desnecessária

---

## 7. Configuração de Ambiente

### 7.1 Níveis de Log por Ambiente

```typescript
// .env
LOG_LEVEL=error,warn,log  # Produção (sem debug)
LOG_LEVEL=error,warn,log,debug  # Desenvolvimento
```

### 7.2 NestJS Logger Configuration

O NestJS Logger já está configurado para respeitar os níveis definidos. Em produção, logs de `debug` são automaticamente filtrados.

---

## 8. Checklist de Implementação

Ao adicionar novos logs, verificar:

- [ ] Nível apropriado (`log`, `debug`, `warn`, `error`)
- [ ] Contexto suficiente (IDs, operações, status)
- [ ] Dados sensíveis redigidos (emails, tokens)
- [ ] Mensagem clara e descritiva
- [ ] Informações úteis para troubleshooting
- [ ] Não expõe informações internas desnecessárias

---

## 9. Referências

- **NestJS Logger**: https://docs.nestjs.com/techniques/logger
- **BullMQ Events**: https://docs.bullmq.io/guide/events
- **ANEXO_18**: Implementação Dinamize com Redis (contexto completo)

---

**Status:** ✅ Implementado e documentado  
**Última atualização:** 2025-11-12  
**Mantido por:** Equipe DWU CRM

