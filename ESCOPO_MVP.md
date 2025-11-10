# Escopo do Produto – DWU CRM

## 1. O que é um CRM

Um CRM (Customer Relationship Management) é uma plataforma que centraliza a gestão do relacionamento com clientes e leads, permitindo organizar e automatizar processos de vendas, marketing e atendimento. Os principais objetivos são:

- Aumentar a conversão de leads em clientes.
- Melhorar a fidelização.
- Ter uma visão unificada do ciclo de vida do cliente.
- Automatizar comunicações e tarefas recorrentes.

## 2. Visão Geral do Produto

O DWU CRM será uma solução moderna integrada com a Dinamize (automação de marketing e e-mail) e preparada para conectar qualquer ERP via API, mantendo-se agnóstico e flexível.

### Pilares do Produto

1. Integração completa com Dinamize (captação de leads, nutrição, automações, campanhas).
2. Agnóstico para ERP, com arquitetura modular de conectores/API.
3. Foco em usabilidade e velocidade, com interface responsiva e UX moderna.
4. Ênfase em vendas e relacionamento (pipeline, oportunidades, histórico de interações).

## 3. Objetivos do MVP

- Lançar em 3 meses uma versão funcional para:
  - Pequenas e médias empresas.
  - Times comerciais com ciclo de vendas consultivo.
  - Marketing com foco em e-mail e inbound.
- Validar a integração real com a Dinamize.
- Possibilitar conexão inicial com ERP via API REST pública.

## 4. Integrações Previstas no MVP

| Sistema  | Tipo de Integração                                   | Status no MVP   |
|----------|-------------------------------------------------------|-----------------|
| Dinamize | Autenticação, listas, leads, campanhas, automações    | Obrigatória     |
| ERP (genérico) | Conector REST (webhook e API Push/Pull)         | Conector base   |

## 5. Módulos do MVP

### 5.1 Leads

- Captura automática via Dinamize.
- Cadastro manual e importação CSV.
- Enriquecimento básico de dados.
- Tags e status personalizados.

### 5.2 Contatos e Empresas

- Cadastro de empresas e contatos vinculados.
- Histórico de interações (e-mail, chamadas, tarefas).
- Visão 360 graus do cliente.

### 5.3 Vendas (Pipeline)

- Funis personalizados e drag & drop de oportunidades.
- Atribuição de responsáveis.
- Forecast de vendas.
- Gatilhos para automações na Dinamize.

### 5.4 Tarefas e Atividades

- Tarefas vinculadas a leads e oportunidades.
- Agendamentos com notificações.
- Tipos de atividades (reunião, ligação, follow-up).

### 5.5 Integração com Dinamize

- Consulta e sincronização de listas.
- Sincronização de leads captados por landing pages.
- Disparo de campanhas via API.
- Automatizações baseadas em comportamento.

### 5.6 Integração com ERP

- Conector REST genérico com:
  - Envio de novos clientes.
  - Recebimento de status de pedidos/vendas.
  - Recebimento de alertas de inadimplência.
- Mapeamento de campos padrão.

## 6. Roadmap do MVP (3 Meses)

### Mês 1 – Estrutura Base e Integração Dinamize

- [ ] Levantamento técnico da API Dinamize.
- [ ] Definição da estrutura de dados (lead, contato, empresa, oportunidade).
- [ ] Autenticação e segurança (JWT ou OAuth).
- [ ] Padronização de versionamento, repositórios, ambientes e deploy.
- [ ] Escolha do framework backend.
- [ ] Backend do módulo de leads.
- [ ] Frontend de captura e visualização de leads.
- [ ] Integração com listas e leads Dinamize.
- [ ] Integração de IA ao CRM DWU.

### Mês 2 – Pipeline e Operação Comercial

- [ ] Pipeline visual (Kanban).
- [ ] Módulo de tarefas e atividades.
- [ ] Visualização de contatos e empresas com histórico.
- [ ] Dashboard inicial (oportunidades, leads, tarefas pendentes).
- [ ] Gatilhos para envio à automação Dinamize.

### Mês 3 – Integração ERP e Conector Base

- [ ] Estrutura para conectores ERP (REST genérico).
- [ ] Tela de configuração (token, URL, mapeamento).
- [ ] API para envio de novos clientes.
- [ ] Recebimento via webhook (ERP fictício).
- [ ] Testes finais e ajustes de performance.

## 7. Critérios de Aceitação do MVP

- Sistema web responsivo disponível.
- Login seguro e multiusuário.
- Leads sincronizados automaticamente com Dinamize.
- Pipeline funcional com movimentação de oportunidades.
- Atividades vinculadas aos registros.
- Integração REST funcional com ERP de exemplo.
- Documentação pública da API de integração.

## 8. Segurança e LGPD

- Consentimento para uso de dados de leads.
- Controle de acesso por perfil.
- Registro de atividades (logs).
- Armazenamento seguro e criptografado em repouso.

## 9. Tecnologias Sugeridas

- Frontend: React, Tailwind, Vite.
- Backend: Node.js com Express ou NestJS.
- Banco de dados: PostgreSQL.
- Integrações: Webhooks e REST APIs (ERP e Dinamize).
- Infraestrutura: Docker e provedores como AWS ou DigitalOcean.
- Autenticação: JWT ou OAuth 2.0.

