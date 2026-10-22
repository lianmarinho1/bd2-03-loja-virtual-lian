-- Transações e concorrência — PostgreSQL
SET search_path TO loja, public;

-- Saldo atual calculado pelos movimentos.
CREATE OR REPLACE VIEW vw_saldo_estoque AS
SELECT p.id_produto, p.sku, p.nome,
       COALESCE(sum(CASE WHEN m.tipo = 'entrada' THEN m.quantidade ELSE -m.quantidade END), 0)::integer AS saldo
FROM produto p LEFT JOIN movimento_estoque m USING (id_produto)
GROUP BY p.id_produto, p.sku, p.nome;

-- Fechamento atômico: trava os produtos, confere o estoque, grava os preços do momento
-- e insere as saídas. Se algum produto faltar, toda a transação deve sofrer ROLLBACK.
CREATE OR REPLACE PROCEDURE fechar_pedido(p_id_pedido BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
    item RECORD;
    saldo_atual INTEGER;
BEGIN
    PERFORM 1 FROM pedido WHERE id_pedido = p_id_pedido FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Pedido % não encontrado', p_id_pedido; END IF;

    IF EXISTS (SELECT 1 FROM pedido WHERE id_pedido = p_id_pedido AND status NOT IN ('carrinho', 'aguardando_pagamento')) THEN
        RAISE EXCEPTION 'Pedido % não está disponível para fechamento', p_id_pedido;
    END IF;

    FOR item IN SELECT * FROM item_pedido WHERE id_pedido = p_id_pedido ORDER BY id_produto FOR UPDATE LOOP
        -- O bloqueio é feito na linha do produto; o saldo é calculado depois do bloqueio.
        PERFORM 1 FROM produto WHERE id_produto = item.id_produto FOR UPDATE;
        SELECT COALESCE(sum(CASE WHEN tipo = 'entrada' THEN quantidade ELSE -quantidade END), 0)::integer
          INTO saldo_atual
          FROM movimento_estoque
         WHERE id_produto = item.id_produto;
        IF saldo_atual < item.quantidade THEN
            RAISE EXCEPTION 'Estoque insuficiente para o produto %: saldo %, solicitado %', item.id_produto, saldo_atual, item.quantidade;
        END IF;
        INSERT INTO movimento_estoque (id_produto, tipo, quantidade, observacao)
        VALUES (item.id_produto, 'saida', item.quantidade, 'Baixa do pedido ' || p_id_pedido);
    END LOOP;

    UPDATE pedido SET status = 'aguardando_pagamento' WHERE id_pedido = p_id_pedido AND status = 'carrinho';
END;
$$;

CREATE OR REPLACE PROCEDURE cancelar_pedido(p_id_pedido BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE item RECORD;
    situacao VARCHAR(24);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pedido WHERE id_pedido = p_id_pedido) THEN
        RAISE EXCEPTION 'Pedido % não encontrado', p_id_pedido;
    END IF;
    SELECT status INTO situacao FROM pedido WHERE id_pedido = p_id_pedido FOR UPDATE;
    IF situacao IN ('enviado', 'entregue', 'cancelado') THEN
        RAISE EXCEPTION 'Pedido % já foi enviado e não pode ser cancelado', p_id_pedido;
    END IF;
    IF situacao <> 'carrinho' THEN
        FOR item IN SELECT id_produto, quantidade FROM item_pedido WHERE id_pedido = p_id_pedido LOOP
            INSERT INTO movimento_estoque (id_produto, tipo, quantidade, observacao)
            VALUES (item.id_produto, 'entrada', item.quantidade, 'Devolução do pedido cancelado ' || p_id_pedido);
        END LOOP;
    END IF;
    UPDATE pedido SET status = 'cancelado' WHERE id_pedido = p_id_pedido;
END;
$$;

-- Teste com sucesso: executar como uma transação completa.
-- BEGIN;
-- CALL fechar_pedido(1);
-- COMMIT;

-- Teste de rollback: escolha um pedido com item do produto 30 e quantidade maior que 1.
-- BEGIN;
-- UPDATE item_pedido SET quantidade = 2 WHERE id_pedido = 2 AND id_item = 1;
-- CALL fechar_pedido(2);
-- ROLLBACK;

-- Teste de cancelamento antes do envio:
-- BEGIN;
-- CALL cancelar_pedido(2);
-- COMMIT;

-- Concorrência: abrir duas sessões e executar, em cada uma, o bloco abaixo para o
-- mesmo produto. A primeira sessão obtém o bloqueio; a segunda aguarda. Depois que a
-- primeira confirma, a segunda reavalia o saldo e falha, evitando estoque negativo.
-- BEGIN;
-- SELECT id_produto, saldo FROM vw_saldo_estoque WHERE id_produto = 30 FOR UPDATE;
-- -- inserir a saída somente depois da conferência do saldo
-- COMMIT;
