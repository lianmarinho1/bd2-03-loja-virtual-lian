# Dicionário de dados simples

Banco de Dados 2 · Turma MBI-08 · Aula 5  
Projeto 3 — Loja Virtual  
Aluno: Lian Marinho

Este dicionário segue o modelo indicado pelo professor. Ele descreve a reconstrução proposta do MER. A v1 original não foi encontrada, portanto não é possível comprovar alterações entre versões.

### Tabela: `categoria`
**Para que serve:** organiza os produtos por categoria.
| Campo | Explicação |
|---|---|
| `id_categoria` | Identifica cada categoria |
| `nome` | Nome da categoria |

### Tabela: `produto`
**Para que serve:** guarda os produtos vendidos pela loja.
| Campo | Explicação |
|---|---|
| `id_produto` | Identifica cada produto |
| `sku` | Código único usado para identificar o produto |
| `id_categoria` | Liga o produto a `categoria` |
| `nome` | Nome do produto |
| `descricao` | Detalhes do produto |
| `especificacoes` | Atributos variáveis em JSONB, como marca, cor e voltagem |
| `ativo` | Indica se o produto pode ser vendido |

### Tabela: `preco_produto`
**Para que serve:** guarda os preços e o período em que cada preço vale.
| Campo | Explicação |
|---|---|
| `id_preco` | Identifica cada preço |
| `id_produto` | Liga o preço a `produto` |
| `valor` | Valor do produto naquele período |
| `inicio_vigencia` | Início da validade do preço |
| `fim_vigencia` | Fim da validade; pode ficar vazio |

### Tabela: `movimento_estoque`
**Para que serve:** registra entradas e saídas de produtos.
| Campo | Explicação |
|---|---|
| `id_movimento` | Identifica cada movimento |
| `id_produto` | Liga o movimento a `produto` |
| `tipo` | Informa se é entrada ou saída |
| `quantidade` | Quantidade movimentada |
| `ocorrido_em` | Data e hora do movimento |
| `observacao` | Motivo do movimento |

### Tabela: `cliente`
**Para que serve:** guarda as pessoas que compram na loja.
| Campo | Explicação |
|---|---|
| `id_cliente` | Identifica cada cliente |
| `nome` | Nome completo |
| `email` | E-mail; não deve se repetir |
| `documento` | CPF fictício ou outro documento |

### Tabela: `endereco`
**Para que serve:** guarda os endereços cadastrados pelos clientes.
| Campo | Explicação |
|---|---|
| `id_endereco` | Identifica cada endereço |
| `id_cliente` | Liga o endereço a `cliente` |
| `tipo` | Indica entrega ou cobrança |
| `logradouro` | Rua ou avenida |
| `numero` | Número do imóvel |
| `complemento` | Apartamento, bloco ou complemento |
| `cidade` | Cidade |
| `uf` | Estado |
| `cep` | Código postal |

### Tabela: `cupom`
**Para que serve:** guarda os cupons de desconto.
| Campo | Explicação |
|---|---|
| `id_cupom` | Identifica cada cupom |
| `codigo` | Código informado pelo cliente; não se repete |
| `tipo_desconto` | Percentual ou valor fixo |
| `valor_desconto` | Percentual ou valor descontado |
| `valor_minimo` | Valor mínimo do pedido |
| `limite_usos` | Número máximo de usos |
| `usos_realizados` | Quantidade de usos já feita |
| `validade_inicio` | Início da validade |
| `validade_fim` | Fim da validade |
| `ativo` | Indica se está liberado |

### Tabela: `pedido`
**Para que serve:** representa o carrinho e a compra de um cliente.
| Campo | Explicação |
|---|---|
| `id_pedido` | Identifica cada pedido |
| `numero` | Número no formato `PD-2026-000123` |
| `id_cliente` | Liga o pedido a `cliente` |
| `id_endereco_entrega` | Indica o endereço escolhido |
| `uf_entrega` | Liga o pedido a `frete_uf` |
| `id_cupom` | Liga o pedido ao cupom usado |
| `status` | Carrinho, aguardando pagamento, pago, enviado, entregue ou cancelado |
| `criado_em` | Data e hora da criação |
| `subtotal` | Soma dos itens antes do desconto e frete |
| `desconto` | Desconto registrado |
| `frete` | Frete registrado |
| `total` | Subtotal menos desconto mais frete |
| `entrega_logradouro` | Cópia do logradouro usado no pedido |
| `entrega_numero` | Cópia do número usado no pedido |
| `entrega_complemento` | Cópia do complemento usado no pedido |
| `entrega_cidade` | Cópia da cidade usada no pedido |
| `entrega_uf` | Cópia da UF usada no pedido |
| `entrega_cep` | Cópia do CEP usado no pedido |

### Tabela: `item_pedido`
**Para que serve:** lista produtos e quantidades de cada pedido.
| Campo | Explicação |
|---|---|
| `id_pedido` | Liga o item a `pedido` |
| `id_item` | Identifica o item dentro do pedido |
| `id_produto` | Liga o item a `produto` |
| `nome_produto` | Nome copiado no momento da compra |
| `preco_unitario` | Preço copiado no momento da compra |
| `quantidade` | Quantidade comprada |
| `total_item` | Preço unitário vezes a quantidade |

### Tabela: `pagamento`
**Para que serve:** registra pagamentos e tentativas de pagamento.
| Campo | Explicação |
|---|---|
| `id_pagamento` | Identifica cada pagamento |
| `id_pedido` | Liga o pagamento a `pedido` |
| `forma` | Pix, cartão ou boleto |
| `status` | Situação do pagamento |
| `valor` | Valor pago ou tentado |
| `pago_em` | Data da confirmação |

### Tabela: `frete_uf`
**Para que serve:** guarda o valor padrão do frete por estado.
| Campo | Explicação |
|---|---|
| `uf` | Identifica o estado |
| `valor` | Valor padrão do frete |

### Tabela: `avaliacao`
**Para que serve:** guarda a opinião dos clientes sobre produtos comprados.
| Campo | Explicação |
|---|---|
| `id_avaliacao` | Identifica cada avaliação |
| `id_cliente` | Liga a avaliação a `cliente` |
| `id_produto` | Liga a avaliação a `produto` |
| `nota` | Nota de 1 a 5 |
| `comentario` | Comentário do cliente |
| `criado_em` | Data e hora da avaliação |

## Regras registradas

- `sku` e `cupom.codigo` são únicos.
- O preço fica preservado em `item_pedido.preco_unitario`.
- O endereço é copiado para os campos `entrega_*` no fechamento.
- `(id_cliente, id_produto)` deve ser único em `avaliacao`.
- A avaliação só deve ser criada depois de conferir que o cliente comprou o produto.
- `(id_cupom, id_cliente)` deve ser único entre pedidos não cancelados, garantindo um uso por cliente.
- Pedido com valor após desconto maior ou igual a R$ 300,00 recebe frete grátis.
- O saldo é calculado pelos movimentos e não pode ficar negativo; baixa e devolução ocorrem em transação.
