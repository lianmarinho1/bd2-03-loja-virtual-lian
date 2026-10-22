# Evidências da prova 1

As evidências devem ser capturadas no PostgreSQL durante a execução dos scripts.

## Conferências previstas

```sql
SET search_path TO loja, public;

SELECT count(*) AS categorias FROM categoria; -- 5
SELECT count(*) AS produtos FROM produto; -- 30
SELECT count(*) AS clientes FROM cliente; -- 40
SELECT count(*) AS enderecos FROM endereco; -- 60
SELECT count(*) AS cupons FROM cupom; -- 8
SELECT count(*) AS pedidos FROM pedido; -- 120
SELECT status, count(*) FROM pedido GROUP BY status ORDER BY status;
SELECT * FROM vw_saldo_estoque WHERE saldo <= 1;
SELECT numero, status, criado_em FROM pedido WHERE status = 'aguardando_pagamento' AND criado_em < now() - interval '48 hours';
```

## Concorrência

Usar duas sessões do PostgreSQL com o produto 30, que começa com uma unidade. A sessão 1 bloqueia a linha e registra a saída. A sessão 2 aguarda o bloqueio e, depois do commit da sessão 1, encontra saldo zero e deve sofrer rollback/erro. O resultado esperado é nunca existir saldo negativo.

## Observação

Esta pasta é o local para salvar os prints ou saídas reais depois que o banco for executado. Não foram inventados resultados de execução.
