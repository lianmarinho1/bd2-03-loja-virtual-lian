-- Projeto 3: Loja Virtual | Banco de Dados 2 - MBI-08
-- Prova 1 - estrutura do banco

DROP SCHEMA IF EXISTS loja CASCADE;
CREATE SCHEMA loja;
SET search_path TO loja, public;

CREATE SEQUENCE pedido_numero_seq START 1;

CREATE TABLE categoria (
    id_categoria BIGSERIAL PRIMARY KEY,
    nome VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE produto (
    id_produto BIGSERIAL PRIMARY KEY,
    sku VARCHAR(40) NOT NULL UNIQUE,
    id_categoria BIGINT NOT NULL REFERENCES categoria(id_categoria),
    nome VARCHAR(160) NOT NULL,
    descricao TEXT,
    especificacoes JSONB NOT NULL DEFAULT '{}'::jsonb,
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE preco_produto (
    id_preco BIGSERIAL PRIMARY KEY,
    id_produto BIGINT NOT NULL REFERENCES produto(id_produto),
    valor NUMERIC(10,2) NOT NULL CHECK (valor >= 0),
    inicio_vigencia TIMESTAMPTZ NOT NULL,
    fim_vigencia TIMESTAMPTZ,
    CHECK (fim_vigencia IS NULL OR fim_vigencia > inicio_vigencia)
);

CREATE TABLE movimento_estoque (
    id_movimento BIGSERIAL PRIMARY KEY,
    id_produto BIGINT NOT NULL REFERENCES produto(id_produto),
    tipo VARCHAR(10) NOT NULL CHECK (tipo IN ('entrada', 'saida')),
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    ocorrido_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    observacao TEXT
);

CREATE TABLE cliente (
    id_cliente BIGSERIAL PRIMARY KEY,
    nome VARCHAR(160) NOT NULL,
    email VARCHAR(180) NOT NULL UNIQUE,
    documento VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE endereco (
    id_endereco BIGSERIAL PRIMARY KEY,
    id_cliente BIGINT NOT NULL REFERENCES cliente(id_cliente),
    tipo VARCHAR(12) NOT NULL CHECK (tipo IN ('entrega', 'cobranca')),
    logradouro VARCHAR(160) NOT NULL,
    numero VARCHAR(20) NOT NULL,
    complemento VARCHAR(100),
    cidade VARCHAR(100) NOT NULL,
    uf CHAR(2) NOT NULL CHECK (uf ~ '^[A-Z]{2}$'),
    cep VARCHAR(9) NOT NULL
);

CREATE TABLE cupom (
    id_cupom BIGSERIAL PRIMARY KEY,
    codigo VARCHAR(40) NOT NULL UNIQUE,
    tipo_desconto VARCHAR(12) NOT NULL CHECK (tipo_desconto IN ('percentual', 'valor_fixo')),
    valor_desconto NUMERIC(10,2) NOT NULL CHECK (valor_desconto > 0),
    valor_minimo NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (valor_minimo >= 0),
    limite_usos INTEGER NOT NULL CHECK (limite_usos > 0),
    usos_realizados INTEGER NOT NULL DEFAULT 0 CHECK (usos_realizados >= 0 AND usos_realizados <= limite_usos),
    validade_inicio TIMESTAMPTZ NOT NULL,
    validade_fim TIMESTAMPTZ NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    CHECK (validade_fim > validade_inicio),
    CHECK (tipo_desconto <> 'percentual' OR valor_desconto <= 100)
);

CREATE TABLE frete_uf (
    uf CHAR(2) PRIMARY KEY CHECK (uf ~ '^[A-Z]{2}$'),
    valor NUMERIC(10,2) NOT NULL CHECK (valor >= 0)
);

CREATE TABLE pedido (
    id_pedido BIGSERIAL PRIMARY KEY,
    numero VARCHAR(20) NOT NULL UNIQUE DEFAULT ('PD-' || to_char(current_date, 'YYYY') || '-' || lpad(nextval('pedido_numero_seq')::text, 6, '0')),
    id_cliente BIGINT NOT NULL REFERENCES cliente(id_cliente),
    id_endereco_entrega BIGINT NOT NULL REFERENCES endereco(id_endereco),
    uf_entrega CHAR(2) NOT NULL REFERENCES frete_uf(uf),
    id_cupom BIGINT REFERENCES cupom(id_cupom),
    status VARCHAR(24) NOT NULL CHECK (status IN ('carrinho', 'aguardando_pagamento', 'pago', 'enviado', 'entregue', 'cancelado')),
    criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    subtotal NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    desconto NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (desconto >= 0),
    frete NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (frete >= 0),
    total NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    entrega_logradouro VARCHAR(160) NOT NULL,
    entrega_numero VARCHAR(20) NOT NULL,
    entrega_complemento VARCHAR(100),
    entrega_cidade VARCHAR(100) NOT NULL,
    entrega_uf CHAR(2) NOT NULL,
    entrega_cep VARCHAR(9) NOT NULL,
    CHECK (total = subtotal - desconto + frete),
    CHECK (desconto <= subtotal),
    CHECK (entrega_uf = uf_entrega)
);

CREATE TABLE item_pedido (
    id_pedido BIGINT NOT NULL REFERENCES pedido(id_pedido) ON DELETE CASCADE,
    id_item INTEGER NOT NULL CHECK (id_item > 0),
    id_produto BIGINT NOT NULL REFERENCES produto(id_produto),
    nome_produto VARCHAR(160) NOT NULL,
    preco_unitario NUMERIC(10,2) NOT NULL CHECK (preco_unitario >= 0),
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    total_item NUMERIC(10,2) GENERATED ALWAYS AS (preco_unitario * quantidade) STORED,
    PRIMARY KEY (id_pedido, id_item)
);

CREATE TABLE pagamento (
    id_pagamento BIGSERIAL PRIMARY KEY,
    id_pedido BIGINT NOT NULL REFERENCES pedido(id_pedido) ON DELETE CASCADE,
    forma VARCHAR(10) NOT NULL CHECK (forma IN ('pix', 'cartao', 'boleto')),
    status VARCHAR(12) NOT NULL CHECK (status IN ('pendente', 'aprovado', 'recusado', 'estornado')),
    valor NUMERIC(10,2) NOT NULL CHECK (valor >= 0),
    pago_em TIMESTAMPTZ
);

CREATE TABLE avaliacao (
    id_avaliacao BIGSERIAL PRIMARY KEY,
    id_cliente BIGINT NOT NULL REFERENCES cliente(id_cliente),
    id_produto BIGINT NOT NULL REFERENCES produto(id_produto),
    nota INTEGER NOT NULL CHECK (nota BETWEEN 1 AND 5),
    comentario TEXT,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (id_cliente, id_produto)
);

-- Um cliente não usa o mesmo cupom duas vezes em pedidos não cancelados.
CREATE UNIQUE INDEX uq_pedido_cupom_cliente_ativo
    ON pedido (id_cupom, id_cliente)
    WHERE id_cupom IS NOT NULL AND status <> 'cancelado';

CREATE INDEX ix_pedido_status_criado ON pedido(status, criado_em);
CREATE INDEX ix_movimento_estoque_produto ON movimento_estoque(id_produto, ocorrido_em);
CREATE INDEX ix_item_pedido_produto ON item_pedido(id_produto);
CREATE INDEX ix_produto_especificacoes ON produto USING GIN(especificacoes);

-- O banco impede notas inválidas, duplicidade de avaliação e saldo negativo por meio
-- da procedure de fechamento/cancelamento em 03_transacoes.sql, que usa bloqueio de linha.
