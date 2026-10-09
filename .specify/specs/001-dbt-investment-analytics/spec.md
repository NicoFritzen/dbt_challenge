# Feature Specification: Pipeline Analítico de Investimentos com dbt

**Feature Branch**: `001-dbt-investment-analytics`

**Created**: 2026-10-08

**Status**: Draft

**Input**: User description: "Desenvolver um projeto dbt funcional que transforme dados brutos de uma corretora fictícia em modelos analíticos confiáveis, utilizando arquitetura em camadas, testes automatizados e documentação completa."

## User Scenarios & Testing

### User Story 1 - Ingestão e padronização confiável dos dados (Priority: P1)

Como pessoa responsável por dados, quero carregar os CSVs originais e obter dados de staging tipados, rastreáveis e tratados segundo regras explícitas, para que as camadas posteriores tenham uma base confiável sem alterar a origem.

**Why this priority**: É a base independente de todas as análises e preserva a auditabilidade dos dados intencionalmente imperfeitos.

**Independent Test**: Executar `dbt seed` e validar os modelos `stg_transactions` e `stg_clients`, seus testes e a rastreabilidade até os dois arquivos CSV.

**Acceptance Scenarios**:

1. **Given** os arquivos `transactions.csv` e `clients.csv` estão disponíveis, **When** a ingestão é executada, **Then** ambos são carregados como seeds sem alteração manual dos arquivos.
2. **Given** existem campos inválidos ou obrigatórios ausentes, **When** o staging é construído, **Then** os registros curados seguem regras documentadas e as anomalias de origem continuam identificáveis.
3. **Given** existem duplicações cadastrais, **When** `stg_clients` é construído, **Then** a seleção do registro válido é determinística e documentada.

### User Story 2 - Construção dos modelos transacionais analíticos (Priority: P1)

Como analista, quero consultar transações normalizadas e métricas financeiras por operação, para analisar o fluxo de compra e venda preservando a granularidade transacional.

**Why this priority**: Entrega a base factual necessária para auditoria das operações e para a construção da carteira.

**Independent Test**: Executar os modelos transacionais e conferir uma linha por `transaction_id`, os relacionamentos válidos e os cálculos de valor bruto, quantidade com sinal e valor com sinal.

**Acceptance Scenarios**:

1. **Given** uma transação BUY ou SELL válida, **When** o modelo transacional é construído, **Then** o valor bruto é `quantity * unit_price` e os sinais correspondem à operação.
2. **Given** há transações associadas a clientes válidos, **When** o mart factual é consultado, **Then** as informações relevantes da operação são preservadas sem duplicidade indevida.
3. **Given** uma chave transacional inválida ou duplicada, **When** a validação é executada, **Then** a inconsistência é detectada e não é mascarada por duplicação artificial.

### User Story 3 - Cálculo da posição financeira dos clientes (Priority: P1)

Como analista de investimentos, quero consultar a posição por cliente e ativo, para saber quantidades compradas, vendidas, líquidas e o fluxo financeiro líquido sem confundi-lo com valor de mercado ou rentabilidade.

**Why this priority**: É o principal resultado analítico do desafio e depende diretamente das regras financeiras corretas.

**Independent Test**: Comparar `mart_client_portfolio` com a soma independente das transações por `client_id` e `asset_ticker`.

**Acceptance Scenarios**:

1. **Given** várias operações de um cliente para um ativo, **When** a carteira é construída, **Then** existe uma linha por cliente e ativo com totais comprados, vendidos, posição líquida, compras brutas, vendas brutas e valor líquido.
2. **Given** as vendas superam as compras, **When** a carteira é construída, **Then** a posição líquida negativa é preservada para auditoria.
3. **Given** um cliente não possui transações, **When** `dim_clients` é consultada, **Then** o cliente válido permanece disponível na dimensão.

### User Story 4 - Validação automatizada de qualidade (Priority: P1)

Como mantenedor do projeto, quero testes automatizados de integridade, granularidade e regras de negócio, para distinguir defeitos do pipeline de anomalias presentes nos dados.

**Why this priority**: Sem validação explícita, os modelos não são confiáveis nem auditáveis.

**Independent Test**: Executar os testes genéricos e o teste singular obrigatório, registrar seus resultados e confirmar que falhas esperadas não são ocultadas.

**Acceptance Scenarios**:

1. **Given** modelos e colunas publicados, **When** `dbt test` é executado, **Then** são avaliados testes `not_null`, `unique`, `accepted_values` e integridade referencial quando aplicáveis.
2. **Given** existe posição com `net_quantity < 0`, **When** `tests/assert_no_negative_position.sql` é executado, **Then** o teste retorna essa posição como violação identificável.
3. **Given** o teste singular retorna linhas por causa de uma anomalia conhecida, **When** os resultados são analisados, **Then** a ocorrência é reportada como falha esperada de qualidade, sem alterar origem ou modelo para obter aprovação artificial.
4. **Given** o teste de posições negativas permanece ativo, **When** os testes de integridade são executados separadamente, **Then** o gate de integridade considera apenas os testes que devem passar e documenta o resultado do teste de anomalias à parte.

### User Story 5 - Documentação e reprodução do projeto (Priority: P1)

Como terceiro executor ou revisor, quero entender a arquitetura, as decisões e os comandos do projeto, para reproduzir a execução e auditar os resultados sem conhecimento implícito do autor.

**Why this priority**: A entrega só é verificável se outra pessoa conseguir executar e interpretar o projeto de forma independente.

**Independent Test**: Seguir o README em ambiente configurado e verificar que modelos, colunas, granularidades, regras, testes, limitações e falhas esperadas estão documentados.

**Acceptance Scenarios**:

1. **Given** um ambiente com as dependências documentadas, **When** o executor segue o README, **Then** consegue executar `dbt seed`, `dbt run` e `dbt test`.
2. **Given** os seis modelos obrigatórios, **When** o schema é consultado, **Then** cada modelo e cada coluna publicada possuem descrição, granularidade e testes aplicáveis.
3. **Given** uma falha esperada ou limitação conhecida, **When** o README é consultado, **Then** seu significado e tratamento estão explícitos.

### User Story 6 - Processamento incremental de transações (Priority: P2, bônus)

Como mantenedor, quero processar novas transações incrementalmente com reexecução idempotente, para reduzir processamento sem duplicar identificadores nem perder registros atrasados.

**Why this priority**: É uma otimização útil, mas não é necessária para o valor mínimo do pipeline analítico.

**Independent Test**: Comparar uma execução incremental com uma execução `full-refresh` sobre o mesmo conjunto lógico e verificar equivalência dos resultados.

**Acceptance Scenarios**:

1. **Given** o mart factual já foi materializado, **When** novas transações são processadas usando `transaction_date`, **Then** apenas o conjunto necessário é atualizado sem duplicar `transaction_id`.
2. **Given** uma transação atrasada ou atualizada, **When** o processamento incremental ocorre, **Then** o tratamento é determinístico, idempotente e documentado.
3. **Given** o mesmo conjunto de dados, **When** se compara incremental e `full-refresh`, **Then** os resultados analíticos são logicamente equivalentes.

### User Story 7 - Reutilização de transformações por macros (Priority: P3, bônus)

Como mantenedor, quero centralizar uma transformação genuinamente repetida em uma macro dbt documentada, para reduzir duplicação e manter consistência entre modelos.

**Why this priority**: Melhora manutenção, mas só deve ser adotada quando houver repetição real e sem antecipar abstrações desnecessárias.

**Independent Test**: Identificar a regra compartilhada, executar os modelos que a utilizam e comparar seus resultados com a regra definida.

**Acceptance Scenarios**:

1. **Given** uma transformação usada por múltiplos modelos, **When** a macro é aplicada, **Then** os modelos produzem a mesma regra de forma consistente.
2. **Given** não há repetição genuína, **When** o projeto é avaliado, **Then** nenhuma macro artificial é exigida.

### User Story 8 - Entrega auditável e demonstrável (Priority: P1)

Como avaliador, quero receber o repositório completo e uma demonstração curta, para verificar execução, arquitetura, decisões, regras financeiras e testes.

**Why this priority**: É requisito de entrega para que o resultado seja avaliável por terceiros.

**Independent Test**: Acessar o repositório, executar os comandos documentados, assistir ao vídeo de até cinco minutos e verificar o envio ao destinatário indicado.

**Acceptance Scenarios**:

1. **Given** o projeto concluído, **When** o repositório é acessado, **Then** contém todos os arquivos necessários para execução independente.
2. **Given** o vídeo de demonstração, **When** ele é assistido, **Then** explica arquitetura, decisões técnicas, regras financeiras, testes e execução em até cinco minutos.
3. **Given** a entrega final, **When** os canais definidos são verificados, **Then** o link do vídeo acompanha o repositório e o repositório é enviado para `fernando@clubedovalor.com.br`.

### Edge Cases

- Campos obrigatórios ausentes, tipos inválidos, quantidades ou preços inválidos MUST seguir regras de tratamento documentadas, sem alteração dos CSVs.
- Operações diferentes de BUY e SELL MUST ser rejeitadas ou classificadas como inválidas segundo regra explícita; não podem ser interpretadas silenciosamente.
- Duplicidades de `transaction_id` e `client_id` MUST ser detectadas, e a deduplicação cadastral MUST ser determinística.
- Clientes válidos sem transações MUST permanecer em `dim_clients`.
- Clientes ou transações sem relacionamento válido MUST ser identificáveis e tratados conforme regra documentada.
- Vendas superiores às compras MUST produzir posições negativas preservadas em `mart_client_portfolio`.
- Reexecuções MUST manter resultados equivalentes e não criar duplicidades indevidas.
- A estratégia incremental MUST considerar registros atrasados e atualizados, caso o bônus seja implementado.

## Requirements

### Functional Requirements

- **FR-001**: O projeto MUST carregar `transactions.csv` e `clients.csv` como seeds sem alterações manuais na origem.
- **FR-002**: O projeto MUST normalizar nomes de colunas para `snake_case` e aplicar tipagem adequada nos modelos de staging.
- **FR-003**: O projeto MUST validar campos obrigatórios e aplicar regras explícitas para excluir ou classificar registros inválidos dos modelos curados.
- **FR-004**: O projeto MUST tratar duplicações cadastrais priorizando o registro com maior completude de informações; em caso de empate, MUST priorizar o `created_at` mais recente e, persistindo o empate, MUST aplicar um critério determinístico documentado.
- **FR-005**: O projeto MUST preservar a rastreabilidade dos registros derivados até os dados de origem e manter anomalias identificáveis.
- **FR-006**: O projeto MUST construir `stg_transactions` e `stg_clients` na camada Staging.
- **FR-007**: O projeto MUST construir `int_transactions` na camada Intermediate, preservando a granularidade transacional.
- **FR-008**: O projeto MUST construir `fact_transactions`, `dim_clients` e `mart_client_portfolio` na camada Marts.
- **FR-009**: `fact_transactions` MUST representar uma transação por `transaction_id`, preservando informações relevantes e métricas financeiras consistentes.
- **FR-010**: `dim_clients` MUST representar um cliente por `client_id`, garantir unicidade e incluir clientes válidos sem transações.
- **FR-011**: `mart_client_portfolio` MUST representar uma posição por `client_id` e `asset_ticker`.
- **FR-012**: O projeto MUST calcular `gross_amount = quantity * unit_price` para cada transação.
- **FR-013**: O projeto MUST calcular `signed_quantity` como `+quantity` para BUY e `-quantity` para SELL.
- **FR-014**: O projeto MUST calcular `signed_amount` como `+gross_amount` para BUY e `-gross_amount` para SELL.
- **FR-015**: O projeto MUST calcular na carteira totais comprados, totais vendidos, `net_quantity = SUM(signed_quantity)`, valor bruto das compras, valor bruto das vendas e `net_amount = SUM(signed_amount)`.
- **FR-016**: O projeto MUST preservar posições negativas e MUST NOT interpretar `net_amount` como valor de mercado, patrimônio, lucro ou rentabilidade.
- **FR-017**: O projeto MUST aplicar testes genéricos `not_null`, `unique` e `accepted_values` quando aplicáveis, incluindo BUY e SELL como valores aceitos para `operation`.
- **FR-018**: O projeto MUST validar integridade referencial, granularidade, duplicidade e consistência de quantidades e valores financeiros.
- **FR-019**: O arquivo `tests/assert_no_negative_position.sql` MUST retornar registros de `mart_client_portfolio` em que `net_quantity < 0`.
- **FR-020**: O projeto MUST manter ativo o teste de posições negativas e MUST executar separadamente os testes de integridade que devem passar, documentando as falhas esperadas do teste de anomalias.
- **FR-021**: O projeto MUST documentar todos os modelos e todas as colunas publicadas em `schema.yml`, incluindo descrição funcional, granularidade e testes.
- **FR-022**: O README MUST documentar objetivo, arquitetura, diretórios, dependências, configuração, execução, interpretação de falhas esperadas, decisões, tratamento e limitações.
- **FR-023**: O projeto MUST permitir execução documentada de `dbt seed`, `dbt run` e `dbt test`.
- **FR-024**: A especificação MUST distinguir execução dos modelos, aprovação dos testes de integridade e detecção esperada de anomalias de negócio.
- **FR-025**: Transações sem cliente correspondente MUST ser excluídas dos modelos analíticos curados e MUST permanecer identificáveis por mecanismo documentado de auditoria e rastreabilidade, sem alteração dos registros originais.
- **FR-026**: O projeto MUST registrar que o teste de posições negativas permanece ativo, que suas falhas esperadas são analisadas separadamente e que os testes de integridade com aprovação esperada formam um conjunto distinto.
- **FR-027**: Caso o bônus incremental seja implementado, `fact_transactions` MUST usar `transaction_date` como controle, evitar duplicação de `transaction_id`, ser idempotente, tratar registros atrasados e demonstrar equivalência com `full-refresh`.
- **FR-028**: Caso o bônus de macros seja implementado, MUST existir uma macro reutilizável para transformação genuinamente compartilhada, com finalidade documentada.
- **FR-029**: A entrega MUST publicar o projeto em repositório GitHub com os arquivos necessários para execução independente.
- **FR-030**: A entrega MUST incluir link para vídeo de demonstração de até cinco minutos cobrindo arquitetura, decisões técnicas, regras financeiras, testes e execução.
- **FR-031**: A entrega MUST enviar o repositório para `fernando@clubedovalor.com.br`.
- **FR-032**: O projeto MUST permanecer fora do escopo de APIs de corretoras, dados em tempo real, precificação atual, rentabilidade, FIFO, custo médio, tributação, dividendos, dashboards, orquestração de produção e streaming.

### Key Entities

- **Transação de ativo**: operação de compra ou venda identificada por `transaction_id`, relacionada a cliente e ativo, com quantidade, preço unitário e data.
- **Cliente**: registro cadastral identificado por `client_id`, com nome, cidade, estado e data de criação; pode existir sem transações.
- **Posição de carteira**: agregação por `client_id` e `asset_ticker`, contendo quantidades e fluxos financeiros derivados das transações.
- **Anomalia de qualidade**: registro inválido, duplicado, sem relacionamento ou posição negativa identificado por regra explícita, sem ser ocultado.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Os dois CSVs são carregados como seeds sem qualquer alteração manual na origem.
- **SC-002**: Os seis modelos obrigatórios — `stg_transactions`, `stg_clients`, `int_transactions`, `fact_transactions`, `dim_clients` e `mart_client_portfolio` — são construídos com sucesso.
- **SC-003**: Não existem duplicidades indevidas nas chaves e granularidades declaradas dos modelos curados.
- **SC-004**: 100% das transações válidas obedecem às fórmulas de valor bruto, quantidade com sinal e valor com sinal.
- **SC-005**: 100% dos modelos e colunas publicados possuem documentação funcional, granularidade e testes aplicáveis.
- **SC-006**: O teste singular permanece ativo e identifica todas as posições com `net_quantity < 0`, sem alteração artificial dos dados para evitar o resultado.
- **SC-007**: As anomalias conhecidas dos arquivos de origem são identificadas, classificadas ou excluídas por regras documentadas e reproduzíveis.
- **SC-008**: Um terceiro consegue executar `dbt seed`, `dbt run` e `dbt test` seguindo o README, sem configuração local não documentada.
- **SC-009**: Reexecuções equivalentes não introduzem duplicidades e produzem resultados equivalentes.
- **SC-010**: Falhas inesperadas de qualidade são diferenciadas das falhas esperadas associadas às anomalias intencionais.
- **SC-011**: O teste singular de posições negativas é analisado separadamente dos testes de integridade que devem passar; nenhuma aprovação integral de `dbt test` é declarada sem considerar essa distinção.
- **SC-012**: Se os bônus forem implementados, processamento incremental e `full-refresh` são logicamente equivalentes e a macro compartilhada reduz duplicação real.
- **SC-013**: O repositório GitHub contém o projeto executável, o link do vídeo de até cinco minutos e a entrega é enviada ao endereço solicitado.

## Assumptions

- Os dois arquivos CSV fornecidos são a fonte oficial do desafio e estão disponíveis no diretório de seeds ou em local configurado conforme documentação.
- BUY e SELL são os únicos valores de operação válidos para os dados curados.
- Duplicatas cadastrais são resolvidas pela maior completude de informações, depois por `created_at` mais recente e, em empate persistente, por critério determinístico documentado.
- Transações sem cliente correspondente são excluídas dos modelos analíticos curados, mas sua identificação é disponibilizada para auditoria e rastreabilidade.
- O ambiente de execução possui uma versão compatível de dbt e um adaptador de banco documentados pelo projeto.
- A publicação no GitHub, a gravação do vídeo e o envio do e-mail são etapas de entrega autorizadas pelo responsável pelo projeto, mas não constituem decisões de implementação SQL.
- O bônus incremental e o bônus de macros são opcionais e não podem comprometer os requisitos obrigatórios.
- Valor financeiro líquido representa fluxo financeiro derivado das operações, não avaliação de mercado nem rentabilidade.

## Open Questions / Clarifications

- **RESOLVIDO**: O teste singular `assert_no_negative_position.sql` permanece ativo para identificar posições negativas. Suas falhas esperadas serão documentadas e os testes de integridade que devem passar serão executados separadamente. Não é aceitável ocultar posições, ignorar o teste ou alterar os dados de origem.
- **RESOLVIDO**: Na deduplicação cadastral, deve prevalecer o registro com maior completude; em empate, o `created_at` mais recente; persistindo o empate, aplica-se um critério determinístico documentado.
- **RESOLVIDO**: Transações sem cliente correspondente serão excluídas dos modelos analíticos curados, mantendo os registros originais e disponibilizando sua identificação para auditoria e rastreabilidade.
- **PENDÊNCIA OPERACIONAL**: O repositório GitHub, o vídeo e o envio por e-mail serão fornecidos pelo executor ou por um responsável externo, e qual é o link final do vídeo? Esta definição é necessária para a entrega, mas não bloqueia o desenho técnico do pipeline.

## Out of Scope

- Integração com APIs de corretoras.
- Dados de mercado em tempo real.
- Precificação atual dos ativos.
- Cálculo de rentabilidade.
- FIFO e custo médio.
- Tributação e dividendos.
- Dashboards.
- Orquestração em produção.
- Infraestrutura de streaming.
- Alteração manual dos arquivos de entrada.
