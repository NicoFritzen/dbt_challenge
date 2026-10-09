# Research: Pipeline Analítico de Investimentos

## Decisão: dbt Core com DuckDB local

**Racional**: Os dados são pequenos, locais e tabulares; DuckDB permite execução sem servidor, credenciais ou infraestrutura externa e mantém os comandos dbt reproduzíveis.

**Alternativas consideradas**: PostgreSQL exigiria serviço e configuração adicionais; SQLite não é o alvo primário do adaptador dbt escolhido; um warehouse gerenciado adicionaria custo e dependências sem valor para o desafio.

## Decisão: manter data_raw como seed path

**Racional**: Os CSVs já existem em data_raw e devem ser preservados integralmente. Configurar esse diretório como caminho de seeds evita cópias ou edição manual.

**Alternativas consideradas**: copiar para seeds/ aumentaria o risco de divergência; transformar CSV fora do dbt quebraria a rastreabilidade.

## Decisão: staging tipado com rastreabilidade e auditoria de rejeições

**Racional**: A origem contém anomalias conhecidas: duplicidades cadastrais, uma transação sem client_id e uma quantidade negativa. O staging deve expor a validade e a origem; a camada curada deve filtrar o que não pode alimentar os marts; uma relação auxiliar deve permitir auditoria dos rejeitados.

**Alternativas consideradas**: remover silenciosamente os registros perderia evidência; permitir todos nos marts contaminaria chaves e métricas.

## Decisão: deduplicação cadastral por completude, data e desempate estável

**Racional**: Para o mesmo client_id, primeiro selecionar o registro com mais campos cadastrais preenchidos; em empate, usar created_at mais recente; em empate persistente, usar uma chave determinística derivada dos valores estáveis do registro. A ordem física do CSV não é critério válido.

**Alternativas consideradas**: first-row/last-row depende da ordem de ingestão; seleção aleatória não é reproduzível.

## Decisão: transações órfãs fora dos marts, mas auditáveis

**Racional**: Uma transação sem cliente não pode satisfazer a integridade referencial de fact_transactions ou da carteira. Ela será identificada por motivo de rejeição e excluída dos modelos analíticos curados, sem alterar o seed.

**Alternativas consideradas**: atribuir um cliente fictício fabricaria dados; manter no fato quebraria a relação com dim_clients.

## Decisão: separação entre gate de integridade e detector de anomalias

**Racional**: assert_no_negative_position.sql deve retornar posições negativas intencionais. Como um teste singular dbt que retorna linhas falha, os testes de integridade que devem passar serão selecionados e executados separadamente; o detector permanecerá ativo e seu resultado será documentado.

**Alternativas consideradas**: desabilitar o teste, filtrar a posição negativa ou alterar a origem violaria a constituição.

## Decisão: incrementalidade e macro ficam opcionais

**Racional**: Os seis modelos obrigatórios devem ser concluídos antes dos bônus. Se incrementalidade for escolhida, fact_transactions usará transaction_date, chave de atualização transaction_id e uma estratégia que considere registros atrasados. Macro só será criada quando uma regra estiver realmente repetida.

**Alternativas consideradas**: implementar bônus antes da base aumentaria complexidade e dificultaria validar a equivalência com full-refresh.
