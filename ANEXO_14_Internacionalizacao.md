# ANEXO 14 – Internacionalização (i18n)

## 1. Visão Geral

- Mantemos um único pacote de traduções no monorepo: `@dwu/shared`.
- O backend NestJS consome essas traduções via `nestjs-i18n`, com `StaticI18nLoader` apontando para o pacote compartilhado.
- Futuramente, frontend (React) e mobile (React Native) também devem consumir `@dwu/shared` para garantir consistência das mensagens.

## 2. Estrutura de Arquivos

```
dwu_crm_shared/
└── src/i18n/
    ├── index.ts
    └── locales/
        ├── en/messages.json
        ├── es/messages.json
        └── pt/messages.json
```

- Cada arquivo `messages.json` agrupa namespaces (`common`, `navbar`, `dashboard`, `errors`, etc.).
- `index.ts` exporta:
  - `translations`
  - `defaultLanguage` (`pt`)
  - Helper `getTranslation(namespace, key, locale)`.

## 3. Backend (NestJS)

### 3.1 Configuração (`app.module.ts`)

- Carrega `I18nModule.forRoot` com:
  - `fallbackLanguage`: `pt`.
  - `loader`: `StaticI18nLoader` (carrega `translations` do pacote shared).
  - `resolvers`: `QueryResolver` (`lang`, `locale`) e `AcceptLanguageResolver`.

### 3.2 Consumo nas Rotas

```
@Get(':id')
findOne(@Param('id') id: string, @I18n() i18n: I18nContext) {
  return this.leadsService.findOne(Number(id), i18n.lang);
}
```

- `@I18n()` injeta `I18nContext`, habilitando acesso ao idioma resolvido no request.

### 3.3 Mensagens no Service

```
const message = this.i18n.translate('errors.leadNotFound', {
  lang,
  args: { id }
});
```

- `lang` vem do contexto ou utiliza o default (`pt`).
- `args` substituem placeholders (`Lead {{id}} não encontrado`).

### 3.4 Testes

- Injetar `I18nService` mockado:
  ```
  {
    provide: I18nService,
    useValue: { translate: jest.fn((key) => key) }
  }
  ```
- Testes de integração podem chamar endpoints com `Accept-Language` para validar respostas.

## 4. Consumindo nas Demais Aplicações

### 4.1 Frontend / Mobile

- Instalar `@dwu/shared`.
- Usar o helper `getTranslation(namespace, key, locale)` ou carregar `translations[locale][namespace]`.
- Integrar com libs de i18n (ex.: `react-i18next`) lendo o JSON gerado no build.

### 4.2 Documentação e Mensagens

- Evitar strings hardcoded; centralizar no shared.
- Sempre manter namespace coerente (`errors`, `navbar`, etc.).

## 5. Adicionando Novas Traduções

1. Atualizar `messages.json` em cada idioma.
2. Rodar `npm install && npm run build` em `dwu_crm_shared` para gerar `dist`.
3. Ajustar consumidores (backend: rebuild; frontend/mobile: reimportar).
4. Validar via testes (req com `Accept-Language`, fallback, etc.).

## 6. Checklist de Boas Práticas

- [ ] Definir `Accept-Language` ou query `?lang=` nas chamadas HTTP quando desejar idioma específico.
- [ ] Garantir que traduções novas existem em todos os idiomas suportados.
- [ ] Evitar interpolar com `concat`; use placeholders `{{}}`.
- [ ] Manter `defaultLanguage` como fallback para casos de ausência de tradução.
- [ ] Atualizar anexos/README ao adicionar idiomas ou namespaces relevantes.

## 7. Referências

- `dwu_crm_backend/src/i18n/static-i18n.loader.ts`
- `dwu_crm_backend/src/leads/leads.service.ts`
- `dwu_crm_shared/src/i18n/index.ts`
- `ANEXO_13_Testes_JWT.md` – seção de testes com múltiplos idiomas.

