# Countly

Countly e um MVP de contagens regressivas feito com Next.js, TypeScript e SCSS. O app permite criar contagens com nome, data alvo, descricao opcional e imagem local, salvando tudo no `localStorage` do navegador.

## Funcionalidades

- Criacao de contagens regressivas sem backend.
- Persistencia local via `localStorage`.
- Upload de imagem por clique, arrastar e soltar, ou colar da area de transferencia.
- Date picker customizado no visual do app.
- Ordenacao por data mais proxima ou mais distante.
- Visualizacao em lista e calendario.
- Layout responsivo para desktop, tablet e mobile.

## Tecnologias

- Next.js App Router
- React
- TypeScript
- SCSS
- Inter
- Lucide React

## Como rodar

```bash
npm install
npm run dev
```

Acesse `http://localhost:3000`.

## Scripts

```bash
npm run dev
npm run build
npm run start
npm run lint
```

## Observacoes

Este MVP nao usa dados mockados nem chamadas externas. As contagens criadas ficam salvas apenas no navegador atual.
