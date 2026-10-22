-- Carga de dados fictícios para exercitar a prova 1.
SET search_path TO loja, public;

INSERT INTO categoria (nome)
SELECT nome FROM (VALUES ('Periféricos'), ('Cabos'), ('Componentes'), ('Gadgets'), ('Armazenamento')) AS x(nome);

INSERT INTO produto (sku, id_categoria, nome, descricao, especificacoes)
SELECT 'SKU-' || lpad(n::text, 3, '0'), ((n - 1) % 5) + 1,
       CASE WHEN n % 5 = 1 THEN 'Teclado mecânico ' || n
            WHEN n % 5 = 2 THEN 'Cabo USB-C ' || n
            WHEN n % 5 = 3 THEN 'Memória RAM ' || n
            WHEN n % 5 = 4 THEN 'Gadget inteligente ' || n
            ELSE 'SSD NVMe ' || n END,
       'Produto fictício para carga de teste',
       jsonb_build_object('marca', CASE WHEN n % 2 = 0 THEN 'TechSul' ELSE 'ByteMais' END,
                          'garantia_meses', CASE WHEN n % 3 = 0 THEN 24 ELSE 12 END,
                          'cor', CASE WHEN n % 2 = 0 THEN 'preto' ELSE 'branco' END,
                          'voltagem', CASE WHEN n % 2 = 0 THEN '110V' ELSE 'bivolt' END)
FROM generate_series(1, 30) AS g(n);

-- Alguns produtos têm histórico de preço; todos têm preço atual.
INSERT INTO preco_produto (id_produto, valor, inicio_vigencia, fim_vigencia)
SELECT id_produto, 40 + id_produto, now() - interval '180 days', now() - interval '30 days'
FROM produto WHERE id_produto <= 10;
INSERT INTO preco_produto (id_produto, valor, inicio_vigencia)
SELECT id_produto, 50 + id_produto * 2, now() - interval '29 days'
FROM produto;

INSERT INTO cliente (nome, email, documento)
SELECT 'Cliente ' || lpad(n::text, 2, '0'), 'cliente' || n || '@exemplo.test', 'CPF-FICTICIO-' || lpad(n::text, 3, '0')
FROM generate_series(1, 40) AS g(n);

INSERT INTO endereco (id_cliente, tipo, logradouro, numero, complemento, cidade, uf, cep)
SELECT ((n - 1) % 40) + 1, CASE WHEN n % 3 = 0 THEN 'cobranca' ELSE 'entrega' END,
       'Rua dos Dados ' || n, (100 + n)::text, CASE WHEN n % 4 = 0 THEN 'Apto ' || n ELSE NULL END,
       CASE WHEN n % 2 = 0 THEN 'Manaus' ELSE 'Recife' END,
       CASE WHEN n % 2 = 0 THEN 'AM' ELSE 'PE' END, '69000-' || lpad(n::text, 3, '0')
FROM generate_series(1, 60) AS g(n);

INSERT INTO frete_uf (uf, valor) VALUES
('AC', 35.00), ('AL', 28.00), ('AM', 25.00), ('AP', 38.00), ('BA', 24.00), ('CE', 26.00),
('DF', 20.00), ('ES', 22.00), ('GO', 22.00), ('MA', 30.00), ('MG', 20.00), ('MS', 24.00),
('MT', 28.00), ('PA', 30.00), ('PB', 29.00), ('PE', 25.00), ('PI', 30.00), ('PR', 18.00),
('RJ', 18.00), ('RN', 29.00), ('RO', 34.00), ('RR', 40.00), ('RS', 22.00), ('SC', 20.00),
('SE', 28.00), ('SP', 16.00), ('TO', 32.00);

INSERT INTO cupom (codigo, tipo_desconto, valor_desconto, valor_minimo, limite_usos, usos_realizados, validade_inicio, validade_fim, ativo) VALUES
('BEMVINDO10', 'percentual', 10, 50, 100, 0, now() - interval '10 days', now() + interval '30 days', TRUE),
('FIXO20', 'valor_fixo', 20, 100, 50, 0, now() - interval '10 days', now() + interval '30 days', TRUE),
('RAM15', 'percentual', 15, 200, 20, 0, now() - interval '2 days', now() + interval '15 days', TRUE),
('VENCIDO', 'percentual', 5, 0, 10, 0, now() - interval '60 days', now() - interval '30 days', TRUE),
('ESGOTADO', 'valor_fixo', 30, 50, 1, 1, now() - interval '5 days', now() + interval '20 days', TRUE),
('FRETEGRATIS', 'valor_fixo', 40, 250, 15, 0, now() - interval '1 day', now() + interval '20 days', TRUE),
('INATIVO', 'percentual', 10, 0, 50, 0, now() - interval '1 day', now() + interval '20 days', FALSE),
('ULTIMOUSO', 'percentual', 25, 300, 2, 0, now() - interval '1 day', now() + interval '20 days', TRUE);

-- Produto 30 fica com apenas uma unidade para o teste de concorrência.
INSERT INTO movimento_estoque (id_produto, tipo, quantidade, observacao)
SELECT id_produto, 'entrada', CASE WHEN id_produto = 30 THEN 1 ELSE 100 END,
       CASE WHEN id_produto = 30 THEN 'Cenário de última unidade' ELSE 'Estoque inicial' END
FROM produto;

-- 120 pedidos em todos os status. Os pedidos 1 a 8 usam cupons distintos.
INSERT INTO pedido (
    id_cliente, id_endereco_entrega, uf_entrega, id_cupom, status, criado_em,
    subtotal, desconto, frete, total,
    entrega_logradouro, entrega_numero, entrega_complemento, entrega_cidade, entrega_uf, entrega_cep
)
SELECT c.id_cliente, e.id_endereco, e.uf, CASE WHEN n <= 8 THEN n ELSE NULL END,
       CASE WHEN n % 6 = 0 THEN 'carrinho'
            WHEN n % 6 = 1 THEN 'aguardando_pagamento'
            WHEN n % 6 = 2 THEN 'pago'
            WHEN n % 6 = 3 THEN 'enviado'
            WHEN n % 6 = 4 THEN 'entregue'
            ELSE 'cancelado' END,
       CASE WHEN n % 6 = 1 THEN now() - interval '72 hours' ELSE now() - (n || ' hours')::interval END,
       0, 0, 0, 0, e.logradouro, e.numero, e.complemento, e.cidade, e.uf, e.cep
FROM generate_series(1, 120) AS g(n)
JOIN cliente c ON c.id_cliente = ((n - 1) % 40) + 1
JOIN endereco e ON e.id_endereco = ((n - 1) % 60) + 1;

INSERT INTO item_pedido (id_pedido, id_item, id_produto, nome_produto, preco_unitario, quantidade)
SELECT p.id_pedido, 1, pr.id_produto, pr.nome, pp.valor, 1 + (p.id_pedido % 2)
FROM pedido p
JOIN produto pr ON pr.id_produto = ((p.id_pedido - 1) % 29) + 1
JOIN preco_produto pp ON pp.id_produto = pr.id_produto AND pp.fim_vigencia IS NULL;

INSERT INTO item_pedido (id_pedido, id_item, id_produto, nome_produto, preco_unitario, quantidade)
SELECT p.id_pedido, 2, pr.id_produto, pr.nome, pp.valor, 1
FROM pedido p
JOIN produto pr ON pr.id_produto = (p.id_pedido % 29) + 1
JOIN preco_produto pp ON pp.id_produto = pr.id_produto AND pp.fim_vigencia IS NULL;

UPDATE pedido p
SET subtotal = x.subtotal,
    desconto = CASE WHEN p.id_cupom IS NULL THEN 0 ELSE LEAST(x.subtotal * 0.10, x.subtotal) END,
    frete = CASE WHEN x.subtotal - CASE WHEN p.id_cupom IS NULL THEN 0 ELSE LEAST(x.subtotal * 0.10, x.subtotal) END >= 300 THEN 0 ELSE f.valor END
FROM (SELECT id_pedido, sum(total_item) AS subtotal FROM item_pedido GROUP BY id_pedido) x
JOIN frete_uf f ON f.uf = p.uf_entrega
WHERE p.id_pedido = x.id_pedido;

UPDATE pedido SET total = subtotal - desconto + frete;

INSERT INTO pagamento (id_pedido, forma, status, valor, pago_em)
SELECT id_pedido, CASE WHEN id_pedido % 3 = 0 THEN 'pix' WHEN id_pedido % 3 = 1 THEN 'cartao' ELSE 'boleto' END,
       CASE WHEN status IN ('pago', 'enviado', 'entregue') THEN 'aprovado'
            WHEN status = 'cancelado' THEN 'estornado' ELSE 'pendente' END,
       total, CASE WHEN status IN ('pago', 'enviado', 'entregue') THEN criado_em + interval '2 hours' ELSE NULL END
FROM pedido;

UPDATE cupom c SET usos_realizados = x.usos
FROM (SELECT id_cupom, count(*)::integer AS usos FROM pedido WHERE id_cupom IS NOT NULL AND status <> 'cancelado' GROUP BY id_cupom) x
WHERE c.id_cupom = x.id_cupom;

-- Avaliações fictícias para clientes que possuem pedidos com itens; a regra de compra
-- será reforçada por procedure/trigger na prova 3.
INSERT INTO avaliacao (id_cliente, id_produto, nota, comentario)
SELECT DISTINCT p.id_cliente, i.id_produto, 4, 'Avaliação de teste'
FROM pedido p JOIN item_pedido i USING (id_pedido)
WHERE p.id_pedido <= 10;
