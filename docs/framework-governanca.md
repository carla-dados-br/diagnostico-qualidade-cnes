# Framework de Governança — Diagnóstico de Qualidade CNES/DATASUS

Este documento traduz os achados de qualidade identificados nas Fases 1 a 3
em regras de governança: quem verifica o quê, com que frequência, e o que
fazer quando um problema é encontrado. Cada regra está ligada ao achado real
que a originou, com rastreabilidade até a query de referência.

Neste projeto solo, os papéis descritos (Engenharia de Dados, Governança,
Análise de Negócio, etc.) representam a separação de responsabilidades que
existiria em um cenário real, com pessoas diferentes ocupando cada papel —
ver seção 9 do documento de planejamento original.

## Fundamentação do framework

A governança de dados não se resume a um checklist unificado de checagem. Separar os achados em regras distintas é fundamental porque a natureza dos problemas e os destinatários das ações mudam drasticamente dependendo da camada afetada: enquanto um erro em um dado cadastral exige a atuação da gestão pontual, uma falha em um controle positivo demanda o acionamento direto da engenharia de dados para inspecionar a integridade da esteira de monitoramento. Tratar realidades operacionais tão diversas sob uma mesma ótica geraria apenas ruído, fadiga de alertas e desresponsabilização.

Para evitar que decisões técnicas sejam tomadas sobre premissas falsas, o framework adota como premissa estrutural que o que é fato verificado na fonte vira regra automatizada, enquanto o que permanece como suposição ou incerteza vira tarefa formal de investigação. Essa separação garante que o catálogo de dados e os alertas de produção permaneçam livres de hipóteses não confirmadas, blindando a confiabilidade analítica do projeto.

Por fim, devido à limitação metodológica de operar sobre o recorte de uma única competência, regras que dependem de análise temporal ou de distribuição comparativa — como o monitoramento de domínio ou a priorização territorial — atuam inicialmente por meio de fotografias analíticas estáticas e baselines. A ativação completa e automatizada dessas frentes fica condicionada à evolução da infraestrutura do projeto e à posterior implementação de um módulo histórico de comparação entre cargas mensais.

---

## Regra 1 — Valor sentinela mascarando ausência real

- **Gatilho:** a cada nova carga ou atualização do cadastro.
- **Responsável pela execução:** área de gestão do dado cadastral.
- **Responsável pela validação:** responsável pela qualidade dos dados.
- **Ação em caso de violação:** gerar alerta para a área de gestão cadastral, informando o campo afetado, a quantidade de registros com valores sentinela, a competência da carga e os valores encontrados.
- **Achados que originaram esta regra:** `id_regiao_saude` (54,70% dos registros com `"nan"` no lugar de valor ausente); `ano_competencia_final` (89,76% usando o sentinela 9999/99 para "sem prazo definido").
- **Indicador de monitoramento:** percentual de ocorrência de sentinelas, estratificado por tabela e por campo monitorado (não um percentual global — denominadores muito diferentes entre tabelas distorceriam a leitura).

---

## Regra 2 — Inconsistência referencial e potencial quebra de regra de negócio (Leitos vs. Habilitações)

A divergência entre leitos físicos e habilitações formais é, no mínimo, uma
quebra crítica de integridade referencial entre módulos que deveriam ser
consistentes. Se for confirmado junto à área de negócio que a habilitação
reflete, de fato, a autorização para financiamento SUS (hipótese ainda não
verificada na documentação oficial do CNES), essa inconsistência
representaria também risco de glosa de faturamento e impacto na regulação
de vagas.

- **Gatilho:** a cada ingestão conjunta ou cruzamento periódico (ETL) entre os módulos de infraestrutura (`leito`) e de documentação/credenciamento (`habilitacao`).
- **Responsável pela execução:** área de Integração de Dados / Engenharia de Dados.
- **Responsável pela validação:** área de Faturamento SUS ou Regulação Assistencial, acionada especificamente para validar a hipótese de impacto regulatório.
- **Ação em caso de violação:** gerar notificação automática para a área de qualidade e faturamento, informando o código CNES do estabelecimento, o tipo de leito conflitante, a natureza da divergência (quantidade incompatível ou ausência total) e a competência.
- **Achados que originaram esta regra:** divergência sistemática de quantidade (768 de 768 casos, sempre no mesmo sentido); 50,1% dos leitos de UTI sem habilitação correspondente.
- **Indicador de monitoramento:** percentual de ativos de infraestrutura crítica (leitos de UTI, suporte avançado) com quebra de integridade referencial frente ao cadastro de habilitações, estratificado por tipo de divergência.

---

## Regra 3 — Controle positivo (verificação de completude sob suspeita)

- **Gatilho:** a cada alteração no código das rotinas de verificação, ou como "passo zero" da esteira automatizada de qualidade — roda sempre que a ferramenta de medição é acionada ou modificada, funcionando como um teste de unidade do pipeline.
- **Responsável pela execução:** Engenharia de Dados.
- **Responsável pela validação:** área de Qualidade de Dados, que atesta que o "sensor" voltou a medir a realidade com precisão.
- **Ação em caso de violação:** disparar alerta técnico bloqueante para a Engenharia de Dados, informando a quebra do teste de controle, e suspender a publicação do painel de qualidade daquela competência até a correção.
- **Achados que originaram esta regra:** `tipo_unidade` (0% de incompletude, confirmado por inspeção manual dos 38 valores distintos em uso).
- **Indicador de monitoramento:** status de integridade da rotina de validação — percentual de execuções mensais em que a query de controle rodou com sucesso e retornou o status esperado.

---

## Regra 4 — Documentação de tipo desatualizada (schema drift)

- **Gatilho:** misto — reativo a cada publicação de nota técnica de mudança de layout pela fonte (DATASUS/CNES); programado, trimestralmente, cruzando o dicionário oficial do projeto com o `INFORMATION_SCHEMA.COLUMNS` atualizado.
- **Responsável pela execução:** Engenharia de Dados.
- **Responsável pela validação:** Analista de Dados ou Especialista de Governança, que avalia o impacto técnico e decide entre atualizar o dicionário ou reescrever queries.
- **Ação em caso de violação:** disparar alerta de quebra de contrato de dados (schema drift) para Engenharia e Análise. Se a mudança quebrar rotinas ativas, suspender o processo analítico até a refatoração; se o impacto for nulo, atualizar o dicionário.
- **Achados que originaram esta regra:** `id_municipio` (documentado como `INT64`, tipo real confirmado como `STRING` via `INFORMATION_SCHEMA.COLUMNS` na Fase 2).
- **Indicador de monitoramento:** taxa de conformidade de metadados — percentual de campos documentados que correspondem à tipagem física real no banco.

---

## Regra 5 — Monitoramento de anomalia na distribuição de domínio (data drift categórico)

- **Gatilho:** atual (preparatório) — execução única no fechamento desta análise, registrando a distribuição observada na competência de nov/2025; futuro (ativo) — a cada nova carga mensal, condicionado à implementação do módulo de comparação entre competências previsto na escalabilidade do projeto.
- **Responsável pela execução:** Analista de Dados (registro da baseline atual); Engenharia de Dados (automação futura).
- **Responsável pela validação:** Especialista em Governança ou Qualidade de Dados.
- **Ação em caso de violação:** hoje, registro formal no catálogo de dados de que `M` e `E` são o domínio válido observado nesta competência; a possível existência de `D` e `S`, citada como conhecimento prévio não verificado, entra como lacuna de investigação a ser confirmada na fonte oficial do DATASUS antes de integrar qualquer baseline esperada. No futuro, disparar alerta não-bloqueante sempre que uma categoria com presença histórica regular cair abruptamente ou desaparecer.
- **Achados que originaram esta regra:** `tipo_gestao` — o recorte apresentou exclusivamente as categorias `M` (109.733) e `E` (629), somando 100% do total. A possível existência de `D` e `S` no domínio oficial é hipótese não confirmada nesta sessão.
- **Indicador de monitoramento:** hoje, a própria distribuição percentual de `tipo_gestao`, como referência histórica; no futuro, taxa de estabilidade do domínio categórico (variação mês a mês das categorias ativas).

---

## Regra 6 — Métrica de completude dependente de regra de negócio (`cnpj_mantenedora`)

- **Gatilho:** a cada cálculo de completude sobre `cnpj_mantenedora` — a métrica não pode ser calculada sobre o total geral do recorte.
- **Responsável pela execução:** Engenharia de Dados (view certificada / camada semântica).
- **Responsável pela validação:** Analista de Dados / Especialista de Governança.
- **Ação em caso de violação:** alertar quando um estabelecimento com `tipo_grau_dependencia = 3` (Mantido) tiver `cnpj_mantenedora` vazio, nulo ou sentinela — vazios associados a `tipo_grau_dependencia = 1` (Individual) são comportamento legítimo e devem ser ignorados pelo monitoramento. Como proteção estrutural contra cálculo ingênuo futuro, disponibilizar uma view/conjunto certificado com coluna calculada (`status_cnpj_mantenedora`: "Preenchido" / "Faltante" / "Não se aplica").
- **Achados que originaram esta regra:** `cnpj_mantenedora` — o vazio bruto contra o total geral mistura ausência esperada (Individual) com ausência real (Mantido sem CNPJ); `tipo_grau_dependencia` confirmado via tabela `dicionario` do BigQuery (`1` = individual, `3` = mantida).
- **Indicador de monitoramento:** percentual de estabelecimentos com `tipo_grau_dependencia = 3` que possuem `cnpj_mantenedora` preenchido, sobre o total de estabelecimentos com `tipo_grau_dependencia = 3` (não sobre o total geral do recorte).

---

## Regra 7 — Monitoramento de atualidade cadastral e metadados de atualização

- **Gatilho:** a cada nova carga ou atualização mensal do cadastro, avaliando o intervalo entre a competência de referência e o ano/mês de atualização registrado.
- **Responsável pela execução:** Engenharia de Dados.
- **Responsável pela validação:** Governança de Dados em conjunto com áreas de negócio/gestão em saúde, responsáveis por ratificar se o limiar de 24 meses reflete o SLA real de operação do SUS.
- **Ação em caso de violação:** (A) desatualizado com data conhecida — alerta para a gestão cadastral, informando o código CNES, ressaltando que o limiar de 24 meses é premissa analítica do projeto, pendente de ratificação oficial; (B) metadado ausente ("não informado") — alerta técnico separado para a equipe de qualidade, tratado como falha de completude de metadados, nunca somado à categoria de atraso temporal.
- **Achados que originaram esta regra:** 20,72% dos estabelecimentos sem atualização cadastral nos últimos 24 meses (corte metodológico do projeto, sem fonte normativa oficial verificada), mais os registros com ausência total do metadado de atualização.
- **Indicador de monitoramento:** duas métricas independentes — (1) percentual de estabelecimentos dentro do limite de 24 meses, sobre o total **com data informada**; (2) percentual de estabelecimentos com metadado de atualização ausente, sobre o total geral do recorte.

---

## Regra 8 — Monitoramento e priorização da distribuição territorial da incompletude

- **Gatilho:** execução analítica estática a cada fechamento de competência, com filtro de amostragem (`total_estabelecimentos >= 20`). Monitoramento dinâmico de desvio ao longo do tempo fica condicionado à implementação futura do módulo de comparação entre competências (mesma limitação da Regra 5).
- **Responsável pela execução:** Engenharia de Dados / equipe de suporte analítico.
- **Responsável pela validação:** Governança de Dados em conjunto com a gestão de saúde regional.
- **Ação em caso de violação:** não há alerta pontual por município; a ação é estabelecer estratificação de priorização estratégica (foco na faixa acima de 75% de incompletude) para direcionar auditorias e suporte técnico. A causa presumida (diferenças nos processos de cadastro/exportação municipais) não gera bloqueio — converte-se em frente formal de investigação institucional.
- **Achados que originaram esta regra:** incompletude de `id_regiao_saude` varia de 0% a mais de 99% entre 347 municípios avaliados (volume ≥ 20); hipótese de bimodalidade rejeitada, concentração maior na faixa 50–75%. A causa territorial permanece como hipótese não confirmada.
- **Indicador de monitoramento:** proporção de municípios em cada faixa de criticidade de preenchimento, funcionando como mapa de calor para direcionamento de esforços.

---

## Regra 9 — Proteção e governança de dados pessoais em base pública (`profissional`)

- **Gatilho:** misto — preventivo, a cada nova proposta de alteração de escopo, query exploratória ou expansão de fase do projeto; periódico, em auditorias mensais de compliance no BigQuery, verificando reintrodução da tabela em views ativas.
- **Responsável pela execução:** Engenharia de Dados (bloqueio por padrão e aplicação de mascaramento nos fluxos autorizados).
- **Responsável pela validação:** Governança de Dados e Oficial de Proteção de Dados (DPO/Compliance), que avaliam trilhas de exceção formais.
- **Ação em caso de violação:** postura fail-closed — qualquer query ou pipeline que tente cruzar ou expor `nome` ou `cartao_nacional_saude` sem autorização prévia documentada deve ser barrada sumariamente, com alerta crítico para a Governança. Fluxos futuros autorizados (ex.: validação de registro de conselho) exigem mascaramento irreversível do `cartao_nacional_saude` e supressão de identificadores diretos antes de tocar qualquer camada de consumo analítico.
- **Achados que originaram esta regra:** a tabela `profissional` contém `nome`, `cartao_nacional_saude` e `id_municipio_6_residencia`, identificando indivíduos. A premissa inicial do projeto (v1), que assumia dado agregado sem informação pessoal, foi corrigida — há dado pessoal de profissional de saúde em base pública.
- **Indicador de monitoramento:** taxa de conformidade de acesso e anonimização — auditoria mensal confirmando zero acessos não autorizados à tabela bruta, e 100% de conformidade com uso de dados mascarados nos casos aprovados por exceção formal.
