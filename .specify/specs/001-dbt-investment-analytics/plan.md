# Implementation Plan: Pipeline Analítico de Investimentos com dbt

**Branch**: "001-dbt-investment-analytics" | **Date**: 2026-10-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from ".specify/specs/001-dbt-investment-analytics/spec.md"

## Summary

Construir um projeto dbt local, reproduzível e auditável para transformar os seeds "transactions.csv" e "clients.csv" em seis modelos analíticos obrigatórios: "stg_transactions", "stg_clients", "int_transactions", "fact_transactions", "dim_clients" e "mart_client_portfolio".

A abordagem usa DuckDB como armazenamento local, dbt Core para materialização e testes, dependências ref() em fluxo unidirecional e SQL organizado por camadas. Os dados de origem permanecerão em "data_raw/" e serão consumidos como seeds sem edição. A camada de staging preservará indicadores de validade e rastreabilidade; a camada intermediate filtrará registros não curados, relacionará clientes e aplicará as regras financeiras; os marts publicarão fatos, dimensão e posições agregadas.

O teste singular de posições negativas permanecerá ativo como detector de anomalias. A validação será dividida entre um conjunto de testes de integridade que deve passar e a execução separada do detector de posições negativas, cuja falha esperada será documentada.

## Technical Context

**Language/Version**: SQL/dbt; versão compatível de Python para o dbt será pinada no arquivo de dependências.

**Primary Dependencies**: dbt Core e adaptador DuckDB, com versões compatíveis e pinadas; nenhuma dependência externa é necessária para os requisitos obrigatórios.

**Storage**: DuckDB local, com seeds CSV preservados em "data_raw/".

**Testing**: Testes genéricos dbt em "schema.yml", testes singulares SQL e consultas de validação de granularidade, cardinalidade, integridade referencial e cálculos financeiros.

**Target Platform**: Execução local em Windows, macOS ou Linux com Python e dbt instalados conforme README.

**Project Type**: Projeto analítico dbt local, orientado a modelos SQL e documentação.

**Performance Goals**: Executar o conjunto fornecido de aproximadamente 25 clientes e 100 transações em poucos segundos em ambiente local, sem sacrificar rastreabilidade ou qualidade.

**Constraints**: Não modificar os CSVs; não usar APIs, dados de mercado ou infraestrutura de produção; manter execução determinística, idempotente e independente de credenciais; não declarar dbt test integralmente aprovado enquanto o detector de anomalias retornar linhas.

**Scale/Scope**: Dois seeds, seis modelos obrigatórios, uma camada de auditoria para rejeições/anomalias, testes dbt, documentação completa e bônus opcionais de incrementalidade e macro.

## Constitution Check

*GATE: PASS antes da pesquisa e reavaliado após o desenho.*

- **Integridade e rastreabilidade**: PASS — "data_raw/" será somente leitura lógica; modelos de staging conservarão chaves e indicadores de origem/validade; rejeições serão auditáveis.
- **Arquitetura em camadas**: PASS — staging, intermediate e marts terão responsabilidades e dependências unidirecionais explícitas.
- **Regras financeiras**: PASS — BUY/SELL, valores com sinal e agregações serão definidos no modelo intermediate e testados nos marts.
- **Qualidade**: PASS com decisão explícita — testes genéricos e testes de integridade comporão o gate de aprovação; "assert_no_negative_position.sql" permanecerá ativo e será analisado separadamente quando retornar anomalias esperadas.
- **Reprodutibilidade**: PASS — DuckDB local, dependências pinadas, comandos documentados e materializações idempotentes.
- **Documentação**: PASS — "schema.yml", README, modelo de dados e guia de validação serão entregues junto ao projeto.
- **Simplicidade**: PASS — nenhuma infraestrutura externa; macro e incrementalidade só serão implementadas se o bônus for escolhido e houver benefício demonstrável.

## Project Structure

### Documentation (this feature)

    specs/001-dbt-investment-analytics/
    ├── plan.md
    ├── research.md
    ├── data-model.md
    ├── quickstart.md
    ├── contracts/           # Não gerado: não há API externa
    └── tasks.md             # Gerado somente por /speckit.tasks

### Source Code (repository root)

    data_raw/
    ├── clients.csv                 # Origem preservada
    └── transactions.csv            # Origem preservada
    models/
    ├── staging/
    │   ├── stg_clients.sql
    │   └── stg_transactions.sql
    ├── intermediate/
    │   └── int_transactions.sql
    ├── marts/
    │   ├── fact_transactions.sql
    │   ├── dim_clients.sql
    │   └── mart_client_portfolio.sql
    └── audits/
        └── audit_rejected_transactions.sql
    tests/
    ├── assert_no_negative_position.sql
    ├── assert_fact_transaction_grain.sql
    ├── assert_portfolio_grain.sql
    └── assert_financial_calculations.sql
    macros/
    └── [opcional: macro de regra genuinamente compartilhada]
    dbt_project.yml
    profiles.yml.example
    requirements.txt
    schema.yml
    README.md
    .gitignore

**Structure Decision**: Projeto dbt único, sem aplicação ou serviço de API. A configuração apontará o caminho "data_raw/" como seed path para não mover nem duplicar os CSVs. O modelo de auditoria pertence a uma camada auxiliar controlada e não substitui os seis marts obrigatórios. Não será criado diretório "contracts/" porque o projeto não expõe API ou contrato externo.

## Implementation Phases

### Phase 0 — Pesquisa e decisões

1. Fixar dbt Core e DuckDB em versões compatíveis e documentar a instalação.
2. Confirmar que o seed path pode apontar diretamente para "data_raw/", preservando os arquivos.
3. Definir convenção de rastreabilidade: chaves de origem, flags de validade e relação entre registros rejeitados e seeds.
4. Definir a regra de completude cadastral e o desempate determinístico sem depender da ordem física do CSV.
5. Definir a estratégia opcional de incrementalidade e a separação dos comandos de testes de integridade versus detecção de anomalias.

### Phase 1 — Desenho

1. Documentar entidades, campos, granularidade e regras no "data-model.md".
2. Definir dependências ref(): seeds → staging → intermediate → marts/auditoria.
3. Definir "schema.yml" como contrato interno de modelos, colunas, descrições e testes.
4. Definir o "quickstart.md" com setup, execução, validação e interpretação da falha esperada.
5. Não criar contratos externos: os únicos pontos de interação são comandos dbt e relações locais documentadas.

### Phase 2 — Implementação futura

1. Configurar projeto e dependências.
2. Implementar staging tipado com flags de validade e deduplicação cadastral.
3. Implementar intermediate com relacionamento válido e regras financeiras.
4. Implementar marts com as granularidades definidas.
5. Implementar auditoria de rejeições e testes.
6. Documentar modelos e atualizar README.
7. Avaliar separadamente os bônus de incrementalidade e macro.

### Phase 3 — Validação e entrega futura

1. Executar dbt seed e confirmar que os CSVs não foram alterados.
2. Executar dbt run e validar as seis relações obrigatórias e a trilha de auditoria.
3. Executar o conjunto de testes de integridade que deve passar.
4. Executar "assert_no_negative_position.sql" separadamente e registrar posições/falhas esperadas.
5. Reexecutar o pipeline para verificar idempotência.
6. Se incrementalidade for implementada, comparar com --full-refresh.
7. Preparar repositório GitHub, vídeo de até cinco minutos e envio definido na especificação.

## Constitution Check — pós-desenho

- **Integridade e rastreabilidade**: PASS — o data-model.md define origem, flags, rejeições auditáveis e ausência de alteração dos seeds.
- **Arquitetura em camadas**: PASS — as relações e dependências foram definidas sem ciclos e sem contrato externo desnecessário.
- **Regras financeiras**: PASS — as fórmulas e granularidades estão definidas no data-model.md e serão verificadas no quickstart.
- **Qualidade**: PASS com ressalva documentada — o detector de posições negativas continua ativo e separado do conjunto de integridade que deve passar.
- **Reprodutibilidade e idempotência**: PASS — o quickstart inclui reexecução e, opcionalmente, comparação incremental/full-refresh.
- **Documentação**: PASS — research.md, data-model.md e quickstart.md complementam o plano; README e schema.yml ficam para implementação.
- **Simplicidade**: PASS — DuckDB local é suficiente; auditoria é o único modelo auxiliar necessário para rastreabilidade.

## Complexity Tracking

Nenhuma violação da constituição foi identificada. O modelo auxiliar de auditoria é necessário para cumprir rastreabilidade de transações rejeitadas e não constitui uma quarta camada analítica.
