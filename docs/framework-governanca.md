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

## Regra 2 — Investigação de coerência entre leitos e habilitações

- **Base da regra:** hipótese / tarefa formal de investigação.

A comparação agregada entre `leito.quantidade_total` e `habilitacao.quantidade_leitos` encontrou divergência nos 768 estabelecimentos presentes nas duas fontes, sempre com o total de leitos superior ao total informado nas habilitações. Esse padrão é um achado reproduzível, mas não demonstra, por si só, que as duas medidas devam ser iguais ou que exista erro cadastral.

Em análise distinta, específica para UTI, o de-para semântico utilizado pelo projeto encontrou 553 de 1.103 combinações estabelecimento + categoria de UTI sem habilitação correspondente segundo os códigos considerados. Essas combinações concentram 7.312 leitos. O resultado também não é tratado isoladamente como irregularidade regulatória, porque sua interpretação depende da validação da relação de negócio entre os cadastros.

Até que essa relação seja confirmada por documentação oficial ou por regra de negócio validada, os resultados permanecem como evidência para investigação e não como violação automatizada.

- **Gatilho:** revisão periódica das comparações entre os módulos `leito` e `habilitacao`, especialmente após novas competências ou alterações no de-para semântico.
- **Responsável pela execução:** área de Qualidade de Dados / Análise de Dados, com apoio da Engenharia de Dados para reprodução das consultas.
- **Responsável pela validação:** área de negócio responsável pelo CNES, regulação ou gestão assistencial, capaz de confirmar a relação esperada entre os conceitos comparados.
- **Ação diante do achado:** abrir registro de investigação contendo competência, código CNES, consulta de origem e medidas observadas. Não gerar alerta de violação, conclusão de irregularidade ou inferência de risco de glosa enquanto a relação semântica entre os campos não estiver confirmada.
- **Achados que originaram esta investigação:** no `sql/05`, 768 de 768 estabelecimentos avaliáveis apresentaram diferença entre os totais agregados, sempre com `total_leitos > total_leitos_habilitados`; no `sql/06`, 553 de 1.103 combinações estabelecimento + categoria de UTI não encontraram habilitação correspondente segundo o de-para aplicado pelo projeto, concentrando 7.312 leitos.
- **Indicadores de acompanhamento:** percentual de estabelecimentos com divergência entre os totais agregados e percentual de combinações estabelecimento + categoria de UTI sem correspondência segundo o de-para aplicado. Esses indicadores descrevem os achados e não representam, nesta etapa, percentuais de violação.
- **Condição para futura automação:** somente transformar o achado em regra de alerta após confirmar, em documentação oficial ou regra de negócio validada, qual relação deve existir entre os campos, em qual granularidade e quais códigos podem ser considerados semanticamente correspondentes.

---

## Regra 3 — Controle positivo (verificação de completude sob suspeita)

- **Gatilho:** a cada alteração no código das rotinas de verificação, ou como "passo zero" da esteira automatizada de qualidade — roda sempre que a ferramenta de medição é acionada ou modificada, funcionando como um teste de unidade do pipeline.
- **Responsável pela execução:** Engenharia de Dados.
- **Responsável pela validação:** área de Qualidade de Dados, que atesta que o "sensor" voltou a medir a realidade com precisão.
- **Ação em caso de violação:** disparar alerta técnico bloqueante para a Engenharia de Dados, informando a quebra do teste de controle, e suspender a publicação do painel de qualidade daquela competência até a correção.
- **Achados que originaram esta regra:** `tipo_unidade` apresentou 0% de incompletude no recorte SP/2025-11 segundo as formas de ausência testadas, com 38 códigos distintos observados. Esse resultado mede completude, não validade semântica. Na validação terminológica separada da Fase 6, registrada em `sql/16-validacao-tipo_unidade-terminologia-fhir.sql`, 37 dos 38 códigos observados aparecem no `BRTipoEstabelecimentoSaude` consultado; o código `16`, presente em 5 estabelecimentos, não aparece nessa versão terminológica e permanece semanticamente não resolvido para geração de `Coding` FHIR.
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
- **Ação em caso de violação:** hoje, registrar no catálogo que `M` e `E` foram as categorias observadas em SP/nov-2025, sem tratá-las como domínio completo do campo. A consulta reproduzida à tabela `basedosdados.br_ms_cnes.dicionario` registrou `D`, `E`, `M`, `S` e `Z` para `tipo_gestao`; essa tabela é usada como fonte auxiliar do conjunto, não como terminologia FHIR oficial. No futuro, disparar alerta não-bloqueante quando houver alteração abrupta na distribuição histórica das categorias, surgimento inesperado de valor fora do domínio registrado no dicionário ou aumento relevante de `Z` ("nao informado").
- **Achados que originaram esta regra:** `tipo_gestao` — o recorte SP/nov-2025 apresentou exclusivamente `M` (109.733) e `E` (629), somando 110.362 registros e 100% de preenchimento físico. Em verificação posterior reproduzida no `sql/11-completude-tipo_gestao.sql`, a tabela `basedosdados.br_ms_cnes.dicionario` retornou `D = dupla`, `E = estadual`, `M = municipal`, `S = sem gestao` e `Z = nao informado`. Portanto, domínio observado no recorte e domínio registrado no dicionário são referências distintas.
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

---

## Regra 10 — Tratamento conservador de identificadores fiscais potencialmente pessoais (`estabelecimento.cpf_cnpj`)

- **Gatilho:** qualquer consulta, transformação, exportação, documentação, exemplo, artefato de portfólio ou proposta de interoperabilidade que utilize `estabelecimento.cpf_cnpj`.
- **Responsável pela execução:** Engenharia de Dados, aplicando minimização por padrão — valores individuais não devem ser publicados ou versionados e os resultados analíticos devem ser agregados sempre que a finalidade permitir.
- **Responsável pela validação:** Governança de Dados e, em eventual uso individual futuro, revisão formal de Privacidade/Compliance antes da liberação do fluxo.
- **Ação em caso de violação:** postura fail-closed para exposição — bloquear a publicação ou o versionamento de valores brutos de `cpf_cnpj`, remover o identificador de exemplos, relatórios e artefatos públicos e reexecutar a saída em forma agregada. Nesta versão, o campo também não deve gerar `Identifier` de CPF ou CNPJ nos recursos FHIR. Qualquer evolução futura exige classificação documental e finalidade de uso explicitamente validadas antes da exposição individual.
- **Achados que originaram esta regra:** no recorte de São Paulo, competência 2025-11, `sql/15-validacao-cpf_cnpj.sql` reproduziu 98.559 valores preenchidos, todos com 14 dígitos; 33.368 passaram somente pelo algoritmo de CPF, 64.241 somente pelo algoritmo de CNPJ e 950 passaram nos dois algoritmos. A validação matemática não comprova existência cadastral, titularidade, situação cadastral ou tipo fiscal efetivo. A Decisão 07 do mapeamento CNES → FHIR, portanto, mantém o identificador fiscal não implementado nesta versão.
- **Indicador de monitoramento:** zero valores individuais de `cpf_cnpj` em arquivos versionados ou artefatos públicos do projeto; 100% das evidências publicadas sobre esse campo devem permanecer agregadas, salvo exceção futura formalmente aprovada e documentada.
