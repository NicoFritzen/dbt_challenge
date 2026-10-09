# Modelo de Dados

## Fontes

### transactions.csv

Representa operações financeiras. Campos: transaction_id, client_id, asset_ticker, operation, quantity, unit_price e transaction_date.

### clients.csv

Representa cadastros. Campos: client_id, name, city, state e created_at.

## Entidades e granularidades

### stg_transactions

Uma linha por registro de origem tipado, preservando transaction_id e uma referência de origem. Deve expor flags ou motivos de validade para campos obrigatórios, operação, quantidade, preço, data e relacionamento posterior. Registros inválidos não devem alimentar os modelos curados, mas devem permanecer identificáveis para auditoria.

### stg_clients

Uma linha por registro cadastral selecionado para o cliente após deduplicação determinística. A seleção prioriza completude de informações, depois created_at mais recente e, persistindo empate, critério estável derivado dos valores do registro. O registro original e o motivo da seleção devem ser rastreáveis.

### int_transactions

Uma linha por transação válida e relacionada a cliente válido. Deve conservar os atributos da operação e derivar:

- gross_amount = quantity * unit_price
- signed_quantity = quantity para BUY e -quantity para SELL
- signed_amount = gross_amount para BUY e -gross_amount para SELL

Quantidade e preço inválidos, operações não aceitas, transaction_id duplicado não resolvido e client_id sem correspondência ficam fora desta relação e são auditáveis.

### fact_transactions

Uma linha por transaction_id curado. Publica atributos da operação, cliente, ativo, data, quantidade, preço, gross_amount, signed_quantity e signed_amount. A chave transaction_id deve ser única e não nula.

### dim_clients

Uma linha por client_id válido. Publica name, city, state, created_at e informações de rastreabilidade aplicáveis. Deve incluir clientes sem transações.

### mart_client_portfolio

Uma linha por combinação client_id e asset_ticker com ao menos uma transação curada. Publica:

- total_buy_quantity
- total_sell_quantity
- net_quantity
- gross_buy_amount
- gross_sell_amount
- net_amount

net_quantity é a soma de signed_quantity e net_amount é a soma de signed_amount. A posição pode ser negativa; isso é uma anomalia de negócio detectada, não um motivo para apagar a linha.

### audit_rejected_transactions

Uma linha por registro transacional que não alimenta os modelos curados, com identificador de origem, transaction_id quando disponível, client_id quando disponível, motivo ou motivos de rejeição e referência ao seed. Essa relação não substitui fact_transactions e existe para auditoria.

## Relacionamentos

    clients seed -> stg_clients -> dim_clients
    transactions seed -> stg_transactions -> int_transactions -> fact_transactions
                                      -> audit_rejected_transactions
    int_transactions -> mart_client_portfolio
    dim_clients <- fact_transactions por client_id

Dependências entre modelos devem ser expressas por ref() e seguir somente a direção seed, staging, intermediate, marts/auditoria.

## Regras de validação

- transaction_id é obrigatório e único em fact_transactions.
- client_id é obrigatório e único em dim_clients.
- client_id e asset_ticker formam uma chave única em mart_client_portfolio.
- operation aceita somente BUY e SELL nos registros curados.
- quantity e unit_price devem ser numéricos e válidos para cálculo.
- transaction_date e created_at devem ser tipados como datas.
- Relações curadas devem manter integridade referencial com dim_clients.
- Cálculos financeiros devem usar tipo numérico com precisão suficiente.
- Posições negativas devem permanecer visíveis e ser retornadas pelo teste singular obrigatório.
