## Clube Valor — Pipeline Analítico dbt

Projeto dbt que transforma dois CSVs de uma corretora fictícia em modelos analíticos auditáveis:

- data_raw/transactions.csv: operações de compra e venda.
- data_raw/clients.csv: dados cadastrais.

Os arquivos de origem são seeds e não devem ser editados manualmente.

## Arquitetura

O fluxo é unidirecional:

1. Staging: stg_transactions e stg_clients tipam, normalizam, marcam validade e deduplicam cadastros.
2. Intermediate: int_transactions relaciona operações a clientes válidos e calcula métricas financeiras.
3. Marts: fact_transactions, dim_clients e mart_client_portfolio publicam fatos, dimensão e posições.
4. Auditoria: audit_rejected_transactions identifica registros transacionais que não alimentam os modelos curados.

mart_client_portfolio tem granularidade client_id + asset_ticker. Fluxo financeiro líquido não representa valor de mercado, patrimônio ou rentabilidade.

## Configuração

Requisitos: Python compatível com as versões de requirements.txt.

    python -m venv .venv
    .venv\Scripts\Activate.ps1
    python -m pip install -r requirements.txt
    Copy-Item profiles.yml.example profiles.yml

Em macOS/Linux, ative o ambiente com source .venv/bin/activate.

## Execução

    dbt seed
    dbt run
    dbt test --select tag:integrity --exclude assert_no_negative_position

O primeiro comando carrega os CSVs sem alterá-los. O segundo constrói os modelos. O terceiro executa os testes de integridade que devem passar.

## Teste de posições negativas

O teste singular tests/assert_no_negative_position.sql permanece ativo e retorna posições com net_quantity < 0. Como um teste dbt que retorna linhas falha por definição, ele deve ser analisado separadamente:

    dbt test --select assert_no_negative_position

Uma falha desse teste pode ser esperada quando vendas superam compras. Isso não autoriza ocultar posições, alterar os CSVs ou desabilitar o teste. Falhas no conjunto tag:integrity são tratadas como defeitos ou anomalias não classificadas e devem ser investigadas.

## Regras de negócio

- gross_amount = quantity * unit_price.
- BUY possui signed_quantity e signed_amount positivos.
- SELL possui signed_quantity e signed_amount negativos.
- net_quantity = SUM(signed_quantity).
- net_amount = SUM(signed_amount).
- Transações sem cliente válido, campos inválidos e duplicidades transacionais não alimentam os marts.
- Rejeições permanecem identificáveis em audit_rejected_transactions.
- Cadastros duplicados priorizam maior completude, depois created_at mais recente e, em empate, um critério determinístico.

## Testes e limitações conhecidas

Os testes validam chaves, granularidade, valores aceitos, relacionamentos, cálculos e rastreabilidade. A origem contém anomalias intencionais, incluindo duplicidades cadastrais, transação sem cliente (T021), quantidade inválida (T037) e posições negativas. Essas ocorrências são preservadas para auditoria e não devem ser corrigidas na origem.

O projeto não calcula valor de mercado, rentabilidade, FIFO, custo médio, tributação, dividendos ou dados de mercado em tempo real.

Incrementalidade e macro reutilizável são bônus ainda não implementados nesta versão.

## Estrutura

    data_raw/              seeds preservados
    models/staging/        padronização e tipagem
    models/intermediate/   regras financeiras e relacionamentos
    models/marts/          relações analíticas finais
    models/audits/         rejeições rastreáveis
    tests/                 testes genéricos e singulares
    schema.yml             documentação e testes de modelos

## Entrega

O repositório deve ser publicado no GitHub e acompanhado de vídeo de demonstração de até cinco minutos cobrindo arquitetura, decisões, regras, testes e execução. O link do vídeo deve ser adicionado aqui antes da entrega final.
