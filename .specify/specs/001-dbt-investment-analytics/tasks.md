---

description: "Task list for the dbt investment analytics pipeline"
---

# Tasks: Pipeline Analítico de Investimentos com dbt

**Input**: Design documents from .specify/specs/001-dbt-investment-analytics/

**Prerequisites**: plan.md, spec.md, research.md, data-model.md and quickstart.md

**Organization**: Tasks are grouped by user story. Mandatory stories come before optional bonuses.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Inicializar o projeto dbt local sem alterar os CSVs existentes.

- [X] T001 [P] Criar requirements.txt com versões compatíveis e pinadas de dbt-core e dbt-duckdb.
- [X] T002 [P] Criar dbt_project.yml com DuckDB, caminho de seeds data_raw/ e diretórios de models, tests e macros.
- [X] T003 [P] Criar profiles.yml.example com target local DuckDB e instruções para configuração sem credenciais versionadas.
- [X] T004 [P] Atualizar .gitignore para ignorar banco DuckDB local, ambiente virtual, artefatos target/ e credenciais locais, preservando data_raw/clients.csv e data_raw/transactions.csv.
- [X] T005 Criar as pastas models/staging/, models/intermediate/, models/marts/, models/audits/, tests/ e macros/ conforme plan.md.

**Checkpoint**: O projeto pode instalar dependências e resolver sua configuração local sem editar os arquivos de origem.

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Estabelecer contratos de nomes, rastreabilidade, seleção de testes e proteção da origem antes dos modelos.

- [X] T006 [P] Documentar no README.md os comandos de instalação, o uso de DuckDB e a regra de que data_raw/*.csv é somente leitura.
- [X] T007 [P] Registrar em schema.yml o padrão de descrições, tags e convenções de testes, incluindo a separação da tag integrity do teste de anomalia.
- [X] T008 [P] Criar tests/assert_seed_immutability.sql ou procedimento equivalente documentado para comparar a presença e o conteúdo dos dois CSVs antes e depois da execução.
- [X] T009 Definir em schema.yml e data-model.md as chaves, granularidades, tipos numéricos e regras de rastreabilidade que serão usadas por todos os modelos.

**Checkpoint**: A base de configuração, documentação e validação de origem está pronta; nenhuma história deve alterar os CSVs.

## Phase 3: User Story 1 - Ingestão e padronização confiável (Priority: P1) 🎯 MVP

**Goal**: Tipar os dois seeds, deduplicar clientes deterministically, identificar registros inválidos e disponibilizar rejeições para auditoria.

**Independent Test**: Executar dbt seed e dbt run --select stg_clients stg_transactions audit_rejected_transactions; verificar tipagem, flags de validade, seleção de C6/C1 e identificação de T021, T036 e T037 sem alterar os CSVs.

### Implementation for User Story 1

- [X] T010 [P] [US1] Implementar models/staging/stg_clients.sql com tipagem, cálculo de completude, seleção por maior completude, created_at mais recente e desempate determinístico.
- [X] T011 [P] [US1] Implementar models/staging/stg_transactions.sql com snake_case, tipagem, flags de campos obrigatórios, operação, quantidade, preço e data, preservando transaction_id e referência de origem.
- [X] T012 [US1] Implementar models/audits/audit_rejected_transactions.sql para registrar transações inválidas ou órfãs, incluindo identificador, motivo de rejeição e referência ao seed, sem alterar os registros originais.
- [X] T013 [US1] Completar schema.yml para stg_clients, stg_transactions e audit_rejected_transactions com descrições funcionais, granularidades, colunas e testes aplicáveis.
- [X] T014 [US1] Criar tests/assert_client_deduplication.sql e tests/assert_rejected_transaction_traceability.sql para validar deduplicação determinística de C6/C1 e rastreabilidade de T021/T037.

**Checkpoint**: Os dados de origem permanecem intactos, os registros curáveis estão tipados e os registros não curáveis podem ser auditados independentemente.

## Phase 4: User Story 2 - Modelos transacionais analíticos (Priority: P1)

**Goal**: Relacionar transações a clientes válidos e publicar métricas financeiras por operação mantendo uma linha por transaction_id.

**Independent Test**: Executar os modelos transacionais e conferir gross_amount, signed_quantity, signed_amount, integridade referencial e unicidade de transaction_id.

### Implementation for User Story 2

- [X] T015 [US2] Implementar models/intermediate/int_transactions.sql usando ref() para staging, filtrando registros inválidos e client_id sem correspondência e aplicando as fórmulas financeiras definidas no data-model.md.
- [X] T016 [US2] Implementar models/marts/fact_transactions.sql com uma linha por transaction_id, preservando cliente, ativo, operação, data, quantidade, preço e métricas assinadas.
- [X] T017 [US2] Atualizar schema.yml para int_transactions e fact_transactions com granularidade, colunas, not_null, unique, accepted_values e relacionamentos aplicáveis.
- [X] T018 [US2] Criar tests/assert_fact_transaction_grain.sql para retornar duplicidades de transaction_id em fact_transactions.
- [X] T019 [US2] Criar tests/assert_financial_calculations.sql para comparar gross_amount, signed_quantity e signed_amount com as regras BUY/SELL.

**Checkpoint**: O fato transacional pode ser validado independentemente e não inclui transações órfãs ou inválidas.

## Phase 5: User Story 3 - Posição financeira dos clientes (Priority: P1)

**Goal**: Publicar dimensão completa de clientes e posição agregada por cliente e ativo, preservando posições negativas.

**Independent Test**: Comparar mart_client_portfolio com agregações independentes de int_transactions e confirmar que clientes sem transações permanecem em dim_clients.

### Implementation for User Story 3

- [X] T020 [P] [US3] Implementar models/marts/dim_clients.sql com uma linha por client_id válido, atributos cadastrais deduplicados e inclusão de clientes sem transações.
- [X] T021 [US3] Implementar models/marts/mart_client_portfolio.sql com granularidade client_id + asset_ticker e totais comprados, vendidos, líquidos e financeiros.
- [X] T022 [US3] Atualizar schema.yml para dim_clients e mart_client_portfolio com descrições de todas as colunas, chaves, granularidades e tipos numéricos.
- [X] T023 [US3] Criar tests/assert_portfolio_grain.sql para retornar duplicidades de client_id + asset_ticker e verificar a soma de signed_quantity e signed_amount.
- [X] T024 [US3] Validar em tests/assert_client_dimension_completeness.sql que clientes válidos sem transações aparecem em dim_clients e que cada client_id é único.

**Checkpoint**: A carteira publica uma posição por cliente e ativo, mantém net_quantity negativa quando existente e não a interpreta como rentabilidade ou valor de mercado.

## Phase 6: User Story 4 - Validação automatizada de qualidade (Priority: P1)

**Goal**: Consolidar o conjunto de testes que deve passar e manter o detector de posições negativas ativo e separado.

**Independent Test**: Executar dbt test --select tag:integrity para o gate de integridade e depois executar o teste singular de posições negativas; documentar claramente resultados esperados e inesperados.

### Implementation for User Story 4

- [X] T025 [P] [US4] Completar schema.yml com not_null, unique, accepted_values para BUY/SELL, relacionamentos e testes de granularidade nos seis modelos obrigatórios.
- [X] T026 [P] [US4] Criar tests/assert_referential_integrity.sql para detectar fact_transactions sem client_id correspondente em dim_clients.
- [X] T027 [P] [US4] Criar tests/assert_no_negative_position.sql para retornar todas as linhas de mart_client_portfolio com net_quantity menor que zero e permitir execução por nome com dbt test --select assert_no_negative_position.
- [X] T028 [US4] Configurar tags e seleção de testes em models/schema.yml e README.md para que tag:integrity --exclude assert_no_negative_position seja executado separadamente do detector de anomalias.
- [X] T029 [US4] Registrar no README.md que uma falha do assert_no_negative_position.sql pode ser esperada, enquanto falhas no conjunto de integridade indicam defeito ou anomalia não classificada.

**Checkpoint**: A validação não mascara anomalias; o gate de integridade e o detector de posições negativas têm resultados interpretáveis separadamente.

## Phase 7: User Story 5 - Documentação e reprodução (Priority: P1)

**Goal**: Permitir que terceiros instalem, executem, interpretem e auditem o projeto.

**Independent Test**: Seguir README.md em ambiente limpo, executar dbt seed, dbt run e as duas rotinas de teste, e confirmar que a documentação cobre todos os modelos e colunas.

### Implementation for User Story 5

- [X] T030 [P] [US5] Completar README.md com objetivo, arquitetura em camadas, estrutura de diretórios, dependências, configuração DuckDB e comandos dbt seed/dbt run/dbt test.
- [X] T031 [P] [US5] Documentar em README.md as regras de tratamento, deduplicação, exclusão de órfãos, auditoria, limitações e interpretação das falhas esperadas.
- [X] T032 [US5] Conferir schema.yml contra data-model.md para garantir descrição funcional, granularidade e descrição de todas as colunas publicadas.
- [X] T033 [US5] Executar os cenários de .specify/specs/001-dbt-investment-analytics/quickstart.md e registrar no README.md o resultado de uma execução reproduzível.

**Checkpoint**: Um terceiro consegue reproduzir o projeto e distinguir resultados válidos, falhas esperadas e falhas inesperadas.

## Phase 8: User Story 6 - Processamento incremental (Priority: P2, bônus)

**Goal**: Tornar fact_transactions incremental, idempotente e consistente com full-refresh.

**Independent Test**: Executar carga inicial, acrescentar ou simular registros novos/atrasados, executar o modo incremental e comparar chaves e métricas com full-refresh.

### Implementation for User Story 6

- [ ] T034 [US6] Definir em research.md/README.md a janela baseada em transaction_date, a estratégia de atualização por transaction_id e o tratamento de registros atrasados.
- [ ] T035 [US6] Converter models/marts/fact_transactions.sql para materialização incremental idempotente sem duplicar transaction_id.
- [ ] T036 [US6] Criar tests/assert_incremental_equivalence.sql ou procedimento documentado para comparar o resultado incremental com full-refresh por chave e métrica.
- [ ] T037 [US6] Atualizar quickstart.md e README.md com comandos, limitações e evidência de equivalência incremental/full-refresh.

**Checkpoint**: O bônus só é considerado concluído se a execução incremental e a full-refresh forem logicamente equivalentes.

## Phase 9: User Story 7 - Macro reutilizável (Priority: P3, bônus)

**Goal**: Centralizar uma transformação genuinamente repetida sem introduzir abstração artificial.

**Independent Test**: Executar os modelos que usam a macro e comparar os resultados com a regra financeira documentada.

### Implementation for User Story 7

- [ ] T038 [US7] Confirmar em research.md se existe transformação compartilhada por múltiplos modelos e registrar a justificativa para criar ou não a macro.
- [ ] T039 [US7] Se houver repetição genuína, implementar macros/signed_transaction_value.sql e aplicá-la nos modelos definidos, preservando os resultados financeiros.
- [ ] T040 [US7] Documentar finalidade, argumentos, modelos consumidores e validação da macro em README.md e schema.yml.

**Checkpoint**: Não criar macro artificial; se criada, ela reduz duplicação real e mantém consistência entre consumidores.

## Phase 10: User Story 8 - Entrega auditável e demonstrável (Priority: P1)

**Goal**: Preparar repositório, demonstração e materiais finais exigidos.

**Independent Test**: Abrir o repositório, seguir o README, assistir ao vídeo de até cinco minutos e confirmar a disponibilidade do link junto à entrega.

- [X] T041 [P] [US8] Revisar README.md, requirements.txt, dbt_project.yml, profiles.yml.example e os diretórios de modelos para incluir todos os arquivos necessários, sem credenciais, banco local ou artefatos gerados.
- [ ] T042 [US8] Gravar vídeo de até cinco minutos e registrar roteiro, duração e cobertura em README.md.
- [ ] T043 [US8] Adicionar o link do vídeo ao README.md e registrar limitações ou falhas esperadas demonstradas.
- [ ] T044 [US8] Publicar o conteúdo do repositório raiz, incluindo README.md e o link do vídeo, no GitHub e enviar o repositório para fernando@clubedovalor.com.br conforme autorização operacional.

**Checkpoint**: A entrega é reproduzível, auditável e contém repositório e demonstração vinculados.

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Validar conformidade final e evitar regressões.

- [X] T045 [P] Executar dbt seed, dbt run e a seleção tag:integrity --exclude assert_no_negative_position em ambiente limpo e registrar os resultados no README.md.
- [X] T046 [P] Comparar checksums ou conteúdo dos CSVs antes e depois da execução e registrar a confirmação em README.md.
- [X] T047 Revisar todos os modelos contra .specify/memory/constitution.md, spec.md, data-model.md e quickstart.md.
- [X] T048 Executar reexecução completa e registrar em README.md a confirmação de idempotência, ausência de duplicidades e consistência das seis relações obrigatórias.

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Não depende de outras fases; T001–T004 podem ser executadas em paralelo e T005 depende da definição da estrutura.
- **Foundational (Phase 2)**: Depende de Setup e bloqueia os modelos.
- **US1 (Phase 3)**: Depende da fundação; entrega o MVP de ingestão e auditoria.
- **US2 (Phase 4)**: Depende de US1, pois int_transactions consome staging e auditoria.
- **US3 (Phase 5)**: Depende de US2 para agregar transações e publicar carteira.
- **US4 (Phase 6)**: Depende de US2 e US3 para testar fatos e carteira.
- **US5 (Phase 7)**: Pode começar após os contratos de cada modelo, mas sua validação final depende de US4.
- **US6 (Phase 8)**: Opcional; depende de fact_transactions concluído e dos testes de US4.
- **US7 (Phase 9)**: Opcional; depende da identificação de repetição genuína nos modelos implementados.
- **US8 (Phase 10)**: Depende de todas as histórias obrigatórias e dos bônus escolhidos.
- **Polish (Phase 11)**: Depende da entrega desejada e deve ser concluída antes da publicação final.

### User Story Dependencies

- **US1 (P1)**: Pode iniciar após Phase 2; não depende de outra história.
- **US2 (P1)**: Depende de US1.
- **US3 (P1)**: Depende de US2.
- **US4 (P1)**: Depende de US2 e US3.
- **US5 (P1)**: Depende dos modelos e testes documentados; valida o conjunto completo.
- **US6 (P2)**: Opcional; depende de US2 e US4.
- **US7 (P3)**: Opcional; depende dos modelos onde houver repetição.
- **US8 (P1)**: Depende de todas as histórias obrigatórias.

### Parallel Opportunities

- T001–T004 podem ser executadas em paralelo.
- T010 e T011 podem ser executadas em paralelo; T012 depende da regra de validade de ambos.
- T020 e T021 podem ser executadas em paralelo depois de int_transactions.
- T025–T027 podem ser executadas em paralelo depois dos marts.
- T030–T032 podem ser executadas em paralelo, desde que a consolidação final do README aguarde os testes.
- T045 e T046 podem ser executadas em paralelo na validação final.

## Implementation Strategy

### MVP First

1. Completar Setup e Foundational.
2. Completar US1 e validar seeds, staging e auditoria.
3. Completar US2 e US3 para produzir os seis modelos obrigatórios.
4. Completar US4 para estabelecer o gate de integridade e o detector de anomalias.
5. Parar no checkpoint e validar o MVP antes de iniciar bônus ou entrega externa.

### Incremental Delivery

1. US1: ingestão, tipagem e auditoria.
2. US2: fato transacional.
3. US3: dimensão e carteira.
4. US4: qualidade automatizada.
5. US5: reprodução e documentação.
6. US6/US7: bônus somente após a base estável.
7. US8 e Polish: entrega final.

## Traceability

- FR-001–FR-005: T001–T014
- FR-006–FR-016: T010–T024
- FR-017–FR-020: T025–T029
- FR-021–FR-024: T030–T033
- FR-025–FR-026: T034–T040
- FR-027–FR-029: T041–T044
- SC-001–SC-011: T008, T010–T033, T045–T048
- SC-012: T034–T040
- SC-013: T041–T044
