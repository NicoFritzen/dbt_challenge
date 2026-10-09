# Constituição do Pipeline Analítico Clube Valor

## Princípios Fundamentais

### I. Integridade e rastreabilidade dos dados

Os arquivos `transactions.csv` e `clients.csv` MUST ser preservados integralmente como dados de origem. Alterações manuais nos arquivos CSV MUST NOT ocorrer. Seeds e modelos derivados MUST manter rastreabilidade explícita até a origem por meio de dependências dbt e documentação.

Dados inválidos MUST ser tratados por regras explícitas, determinísticas e reproduzíveis. Critérios de exclusão, deduplicação e transformação MUST ser documentados. Inconsistências não podem ser ocultadas para forçar a aprovação dos testes; anomalias originadas nos CSV MUST permanecer identificáveis e ser diferenciadas de defeitos introduzidos pelo pipeline.

### II. Arquitetura em camadas

O projeto MUST adotar fluxo unidirecional de dependências e três camadas analíticas:

- **Staging:** `stg_transactions` e `stg_clients`, responsáveis por padronização, tipagem, validação e tratamento inicial.
- **Intermediate:** `int_transactions`, responsável por relacionamentos, enriquecimentos e aplicação de regras de negócio.
- **Marts:** `fact_transactions`, `dim_clients` e `mart_client_portfolio`, responsáveis pela disponibilização dos modelos analíticos finais.

Modelos MUST usar `ref()` para dependências entre modelos e MUST respeitar a separação de responsabilidades e a granularidade declarada de cada camada. Dependências circulares ou acesso direto indevido à origem MUST NOT ser introduzidos.

### III. Correção das regras financeiras

As regras financeiras MUST ser implementadas sem ambiguidade:

- `BUY` MUST representar entrada positiva de quantidade.
- `SELL` MUST representar saída negativa de quantidade.
- O valor bruto MUST ser calculado como `quantity * unit_price`.
- A quantidade líquida MUST representar compras menos vendas.
- O valor financeiro líquido MUST representar o valor bruto das compras menos o valor bruto das vendas.

Modelos MUST usar tipos numéricos adequados à precisão financeira. Fluxo financeiro líquido MUST NOT ser confundido com valor de mercado, patrimônio ou lucro. O pipeline MUST NOT fabricar posições iniciais inexistentes e MUST preservar a capacidade de identificar posições negativas.

### IV. Qualidade de dados como requisito central

O projeto MUST implementar testes genéricos dbt `not_null`, `unique` e `accepted_values` sempre que aplicáveis. O teste singular `assert_no_negative_position.sql` MUST existir e validar a regra definida para posições negativas.

Os testes MUST validar granularidade, unicidade, integridade referencial e consistência das transformações. Falhas existentes na origem MUST ser distinguidas de falhas introduzidas pelo pipeline, e falhas esperadas e inesperadas MUST ser documentadas. Testes MUST NOT ser desabilitados, enfraquecidos ou contornados apenas para obter resultado positivo.

### V. Reprodutibilidade e idempotência

As execuções MUST ser determinísticas e repetíveis. Execuções consecutivas de `dbt seed`, `dbt run` e `dbt test` MUST NOT produzir duplicações indevidas. O projeto MUST permitir execução independente conforme instruções do README, com dependências e configurações documentadas e sem depender de configuração local não documentada.

Credenciais e informações sensíveis MUST ser protegidas e MUST NOT ser versionadas em arquivos do projeto.

### VI. Documentação como parte da implementação

Todos os modelos MUST ser documentados em `schema.yml`, incluindo todas as colunas publicadas, a granularidade, as regras de negócio relevantes e as garantias de qualidade aplicáveis.

O README MUST documentar instalação, configuração, arquitetura, comandos de execução e validação. A documentação MUST refletir o comportamento efetivamente implementado; divergências entre documentação, SQL, testes e resultados MUST ser corrigidas como defeitos.

### VII. Simplicidade e manutenibilidade

O SQL MUST ser legível, modular e organizado. Modelos MUST ter responsabilidade única e seguir nomenclatura `snake_case`. Lógica repetida SHOULD ser centralizada em macros somente quando isso melhorar clareza e manutenção. O projeto SHOULD priorizar os requisitos obrigatórios antes de bônus e MUST NOT introduzir dependências ou infraestrutura sem valor claro para o desafio.

## Requisitos Técnicos e Restrições

### Processamento incremental opcional

Se o requisito bônus de processamento incremental for implementado, o modelo MUST usar `transaction_date` como referência de controle incremental, MUST ser idempotente e MUST evitar duplicação de `transaction_id`. O tratamento de registros atrasados ou atualizados MUST ser documentado. A equivalência lógica entre execução incremental e `full-refresh` MUST ser validada.

### Entrega mínima verificável

O projeto MUST permitir a execução dos comandos abaixo a partir das instruções documentadas:

```text
dbt seed
dbt run
dbt test
```

A integridade dos dados e a honestidade da validação MUST ter precedência sobre a ocultação de falhas esperadas.

## Padrões de Engenharia e Fluxo de Trabalho

Especificações, planos, tarefas, modelos, testes e documentação MUST ser avaliados contra esta constituição. Toda mudança MUST preservar o fluxo em camadas, a granularidade declarada e a rastreabilidade dos dados.

Antes da entrega, a implementação SHOULD ser verificada com `dbt seed`, `dbt run` e `dbt test`, e os resultados MUST ser analisados quanto a falhas de origem versus falhas do pipeline. Cada modelo novo ou alterado MUST atualizar sua documentação e seus testes aplicáveis.

Exceções aos princípios MUST ser justificadas no artefato técnico correspondente, incluindo motivo, impacto, escopo e plano de reversão ou regularização quando aplicável.

## Governança

Esta constituição é a autoridade normativa para especificações, planos, tarefas e implementação do projeto. Em caso de conflito, seus princípios prevalecem sobre convenções locais não documentadas.

Alterações nesta constituição MUST ser versionadas, MUST registrar a justificativa e MUST atualizar a data de última alteração. Mudanças que alterem princípios, requisitos obrigatórios ou critérios de validação exigem incremento de versão MAJOR; adições compatíveis exigem incremento MINOR; correções editoriais sem alteração normativa exigem incremento PATCH.

Revisões de implementação MUST verificar conformidade com esta constituição, especialmente preservação da origem, dependências entre camadas, regras financeiras, testes obrigatórios, documentação e reprodutibilidade. Qualquer complexidade adicional MUST ser justificada por benefício verificável.

**Versão**: 1.0.0 | **Ratificada**: 2026-10-08 | **Última alteração**: 2026-10-08
