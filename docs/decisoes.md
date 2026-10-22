# Decisões de modelagem — Projeto 3: Loja Virtual

**Aluno:** Lian Marinho  
**Disciplina:** Banco de Dados 2 — MBI-08, Aula 5

## Decisão 1 — Preservar o preço do pedido

O preço atual do produto não deve ser usado para reconstituir uma compra antiga. Por isso, `item_pedido` guarda `preco_unitario`, `nome_produto` e `total_item`. Assim, o pedido continua correto mesmo quando o preço ou o nome do produto mudar.

## Decisão 2 — Preservar o endereço usado na entrega

O pedido aponta para `endereco`, mas também copia os campos `entrega_logradouro`, `entrega_numero`, `entrega_complemento`, `entrega_cidade`, `entrega_uf` e `entrega_cep` no fechamento. O `id_endereco_entrega` fica como referência de origem, mas o snapshot garante que a entrega histórica não dependa do cadastro atual.

## Decisão 3 — Registrar estoque como movimentos

Foi escolhida a tabela `movimento_estoque` em vez de guardar somente um saldo. Entradas e saídas ficam registradas com data, quantidade e observação. O saldo pode ser calculado e o histórico ajuda a conferir erros.

## Dúvida em aberto

O enunciado não deixa totalmente claro se um cliente pode avaliar um produto sem existir uma compra aprovada. A proposta permite a avaliação, mas recomenda validar, na aplicação, se o cliente comprou o produto. Essa regra pode ser ajustada quando o professor confirmar o requisito.

## Regras acrescentadas após a conferência do enunciado

- `produto.sku` é único e `produto.especificacoes` usa JSONB para atributos que variam por categoria.
- `cupom` possui limite de usos, usos realizados e valor mínimo. A regra de um uso por cliente será reforçada por uma restrição única em pedidos não cancelados.
- `pedido.uf_entrega` liga o pedido à tabela `frete_uf`, enquanto `entrega_uf` preserva a UF usada no momento da compra.
- Pedido com valor após desconto maior ou igual a R$ 300,00 recebe frete zero.
- Os status previstos são `carrinho`, `aguardando_pagamento`, `pago`, `enviado`, `entregue` e `cancelado`.

## Sobre a comparação com a v1

Este arquivo documenta uma **reconstrução proposta**. A v1 original não foi encontrada nos arquivos disponíveis. Portanto, **não é possível comprovar duas mudanças entre v1 e v2**, nem afirmar que houve feedback da turma. As decisões acima são justificativas deste modelo proposto, não um registro de revisão comprovada.

## IA utilizada

Foi utilizada inteligência artificial (ChatGPT/Codex) para organizar os requisitos fornecidos, propor a estrutura das tabelas, revisar PKs/FKs/cardinalidades e gerar os arquivos de entrega. A decisão final e a conferência do conteúdo devem ser feitas pelo aluno.
