# Quickstart de Validação

Este guia descreve a validação planejada; os arquivos dbt serão implementados na etapa de tarefas.

## Pré-requisitos

1. Python em versão compatível com as dependências pinadas.
2. Ambiente virtual ativado.
3. Dependências instaladas a partir de requirements.txt.
4. Acesso de leitura aos arquivos data_raw/clients.csv e data_raw/transactions.csv.

## Execução mínima

A partir da raiz do repositório:

    dbt seed
    dbt run

O resultado esperado é a criação dos seis modelos obrigatórios e da relação de auditoria, sem alteração dos CSVs de origem.

## Testes de integridade que devem passar

Executar a seleção de testes genéricos e singulares de granularidade, chaves, relacionamentos e cálculos financeiros, excluindo o detector de posições negativas quando ele for conhecido por retornar anomalias intencionais.

    dbt test --select tag:integrity --exclude assert_no_negative_position

O conjunto deve passar. Falhas nesse conjunto indicam defeito de qualidade ou de implementação e não devem ser ocultadas.

## Detecção de posições negativas

Executar o teste singular obrigatório separadamente:

    dbt test --select assert_no_negative_position

Se houver posições negativas nos dados curados, o resultado esperado é uma falha do teste com as linhas infratoras. Isso é uma detecção documentada de anomalia de negócio, não uma autorização para alterar seeds, filtrar a posição ou desabilitar o teste.

## Validações adicionais

- Reexecutar dbt seed e dbt run para verificar idempotência.
- Comparar contagens e chaves com a granularidade documentada.
- Conferir que clientes sem transações permanecem em dim_clients.
- Conferir que transações órfãs não aparecem nos marts e aparecem na auditoria.
- Conferir independentemente gross_amount, signed_quantity, signed_amount, net_quantity e net_amount.
- Registrar a diferença entre falha esperada do detector e falha inesperada dos testes de integridade.

## Validação opcional de incrementalidade

Se o bônus for implementado, executar uma carga incremental com transações novas, atualizadas e atrasadas; depois executar full-refresh e comparar as relações e métricas por chave. Não deve haver duplicação de transaction_id.

## Resultado de entrega

O README final deve repetir os comandos, as dependências, o significado da falha esperada e as limitações. O repositório e o vídeo de até cinco minutos devem ser publicados conforme a especificação.
