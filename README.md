# Entrega — Banco de Dados 2 MBI-08, Aula 5

**Projeto 3: Loja Virtual**  
**Aluno:** Lian Marinho

## Situação da entrega

Esta pasta contém a versão da **Prova 1** em construção. O modelo é uma reconstrução proposta a partir do enunciado e das orientações do professor. A v1 original não foi encontrada; por isso não há afirmação de revisão comprovada nem feedback inventado da turma.

## Arquivos

- `modelo-v2.pdf` — MER legível para entrega.
- `modelo-v2.png` — imagem do MER.
- `mer-loja-virtual.mmd` — fonte Mermaid editável.
- `mer-loja-virtual.svg` — fonte vetorial editável.
- `dicionario-de-dados-simples.md` — dicionário no formato simples.
- `decisoes.md` — três decisões, uma dúvida, limites da comparação com v1 e registro de IA.

## Estrutura da prova 1

- `diagrama/` — MER em Mermaid, SVG, PNG e PDF.
- `docs/` — dicionário e decisões.
- `sql/01_ddl.sql` — schema, tabelas, PK, FK, UNIQUE, CHECK, DEFAULT e índices.
- `sql/02_carga.sql` — carga fictícia com 30 produtos, 5 categorias, 40 clientes, 60 endereços, 8 cupons e 120 pedidos.
- `sql/03_transacoes.sql` — saldo, fechamento do pedido, rollback, cancelamento e roteiro de concorrência.
- `sql/instalar.sql` — recria o banco e executa os scripts da prova 1.
- `evidencias/` — consultas e roteiro para salvar os resultados reais dos testes.

O dicionário segue o modelo simples indicado pelo professor: uma seção por tabela, finalidade da tabela e explicação curta de cada campo.

As regras que dependem de transação, procedure ou trigger — estoque não negativo, cancelamento após 48 horas, avaliação de quem comprou e um uso de cupom por cliente — serão aprofundadas nas próximas etapas. Nesta prova, a baixa e a devolução de estoque são demonstradas em `03_transacoes.sql`.

## Nota de escopo

Esta é uma reconstrução proposta a partir dos arquivos e requisitos disponíveis. A v1 não foi localizada; por isso não há afirmação de revisão comprovada nem feedback inventado da turma.
