# Dicionário de Dados — Projeto CNES

Registro dos campos analisados na tabela `basedosdados.br_ms_cnes.estabelecimento`, recorte SP + competência 2025-11.

Para cada campo: tipo de dado, o que representa, e como valores ausentes se manifestam na prática (nem sempre como `NULL`).

---

## `id_regiao_saude`

- **Tipo:** STRING
- **O que representa:** código da região de saúde à qual o estabelecimento está vinculado, usado para planejamento e alocação de recursos regionais.
- **Padrão de ausência identificado:** o campo não usa `NULL` para representar ausência de valor. Em vez disso, parte dos registros traz o texto literal `"nan"` armazenado como string, e uma pequena parcela traz string vazia (`""`).
- **Impacto:** uma verificação de completude baseada apenas em `IS NULL` retorna 0% de incompletude neste campo — resultado enganoso. A verificação correta precisa somar `IS NULL`, `= 'nan'` **e** `= ''` (string vazia).
- **Hipótese de causa:** provável resíduo de um processo de tratamento de dados (ex.: exportação via pandas/Python, onde `NaN` é a representação padrão de ausência) que converteu o valor ausente em texto antes de gravar na base, em vez de preservá-lo como nulo.
- **Métrica de completude (SP, nov/2025):**

  | Total de estabelecimentos | Incompletos (NULL + "nan") | % Incompleto |
  |---|---|---|
  | 110.362 | 60.366 | 54,70% |

- **Correção de métrica (12/09/2026):** a investigação original (Fase 1/3) testou apenas `NULL` e o texto `"nan"`, sem testar string vazia. Reproduzir a normalização em Python (Fase 2), testando as três formas de uma vez, revelou 5 registros adicionais — confirmados na fonte original com `COUNT(*) WHERE id_regiao_saude = ''`. Métrica corrigida de 60.361 (54,69%) para 60.366 (54,70%). Achado direto do valor de reproduzir a mesma análise em ferramenta diferente (etapa "comparação SQL × Python" da Fase 2).
- **Query de referência:** ver `sql/03-completude-id_regiao_saude.sql`
- **Recomendação de tratamento (Fase 2):** ao limpar os dados em Python, converter explicitamente o texto `"nan"` para `NULL`/`NaN` reconhecido pelo pandas, antes de qualquer cálculo de completude ou agregação.

---

## `ano_competencia_final` / `mes_competencia_final` (tabela `habilitacao`)

- **Tipo:** INT64
- **O que representa:** competência (ano/mês) em que a habilitação do estabelecimento deixa de valer. Usado na regra de consistência "habilitação vencida ainda registrada" (Fase 3).
- **Padrão de ausência/indeterminação identificado:** o campo não usa `NULL` para representar "sem prazo de validade definido". Em vez disso, usa um valor sentinela: `ano_competencia_final = 9999` combinado com `mes_competencia_final = 99`.
- **Prevalência do sentinela (SP, nov/2025):** 6.072 de 6.764 habilitações (89,76%) usam esse sentinela — a grande maioria das habilitações não tem prazo definido.
- **Categorias observadas no campo, entre os registros com data definida (692 registros):**
  1. **Sentinela `9999/99`** — indeterminado, convenção sistemática e consistente.
  2. **Prazos longos plausíveis** — datas futuras distantes mas plausíveis (majoritariamente entre 2029 e 2099), refletindo habilitações de longa duração. Contagens relevantes em cada competência (ex.: 2029-10 com 20 registros), o que indica padrão real, não ruído.
  3. **Outlier isolado** — um único registro com `2999/12`. Aparece uma única vez; não é um segundo sentinela sistemático. **Os dados não permitem determinar a causa** (não documentar como erro de digitação ou qualquer outra causa específica sem confirmação da fonte).
- **Impacto para a regra de consistência:** a regra "habilitação vencida" precisa excluir explicitamente o sentinela (`ano_competencia_final != 9999`) antes de comparar datas — caso contrário, a comparação `sentinela < competência_de_referência` nunca é verdadeira (9999 é sempre maior), mascarando o resultado real da regra como "zero vencidas" mesmo antes de qualquer habilitação real ser avaliada.
- **Resultado da regra aplicada corretamente (SP, nov/2025):**

  | Total habilitações | Indeterminadas (sentinela) | Com data definida | Vencidas |
  |---|---|---|---|
  | 6.764 | 6.072 (89,76%) | 692 | 0 |

  A competência final mínima entre os registros com data definida é 2025-11 — ou seja, a habilitação mais próxima de vencer está vencendo na própria competência de referência, não antes dela. O resultado de zero vencidas é genuíno para este recorte, não um artefato de cálculo.
- **Query de referência:** ver `sql/04-consistencia-habilitacao-vencida.sql`

---

## `leito.quantidade_total` × `habilitacao.quantidade_leitos`

- **Tipo:** INT64 (ambos os campos)
- **O que representam:** o mesmo fato — quantidade de leitos de um estabelecimento — registrado em duas tabelas diferentes do CNES. Redundância já identificada na verificação de estrutura (`docs/achados-verificacao-estrutura.md`).
- **Granularidade original:** ambas as tabelas têm múltiplas linhas por estabelecimento (uma por especialidade/tipo de leito, ou por habilitação). Regra de agregação prévia aplicada antes do JOIN: `SUM()` agrupado por `id_estabelecimento_cnes`.
- **Tipo de junção usado:** `INNER JOIN` (não `LEFT JOIN`) — a regra avalia divergência **entre estabelecimentos presentes nas duas fontes**. Estabelecimentos com leito cadastrado mas sem nenhuma habilitação correspondente (ou vice-versa) não entram nesta regra; essa é a regra seguinte, de UTI sem habilitação.
- **Resultado da regra (SP, nov/2025):**

  | Estabelecimentos avaliáveis (nas 2 tabelas) | Com divergência | % |
  |---|---|---|
  | 768 | 768 | 100% |

- **Investigação do padrão:** a divergência não é aleatória. Em 768 de 768 casos, `leito.quantidade_total` é maior que `habilitacao.quantidade_leitos` — nunca o contrário. Diferença mínima de 1, máxima de 1.309, média de 97,88.
- **Hipótese explicativa (não confirmada pelos dados; requer verificação na documentação oficial do CNES):** as duas colunas podem medir conceitos diferentes — `leito.quantidade_total` possivelmente reflete leitos físicos existentes no estabelecimento, enquanto `habilitacao.quantidade_leitos` possivelmente reflete apenas os leitos que passaram por processo formal de habilitação/autorização para financiamento do SUS, um subconjunto do total físico. O padrão observado (leito sempre ≥ habilitação) é compatível com essa hipótese, mas os dados por si só não a confirmam — nenhuma causa é declarada como fato sem verificação na fonte oficial.
- **Query de referência:** ver `sql/05-consistencia-divergencia-leitos.sql`

---

## `tipo_especialidade_leito` (leito) × `tipo_habilitacao` (habilitacao) — UTI

- **Tipo:** STRING (ambos os campos)
- **O que representam:** o código de leito identifica o tipo de UTI cadastrado fisicamente (`leito`); o código de habilitação identifica se o estabelecimento tem autorização formal para operar aquele tipo de UTI (`habilitacao`). Os dois campos pertencem a domínios de código numéricos completamente diferentes — não é possível cruzá-los por igualdade numérica, apenas por correspondência semântica (de-para).

### De-para semântico construído

**12 pares diretos**, confirmados por igualdade semântica e mesma granularidade (a distinção tipo I/II/III existe nos dois lados):

| Código leito | Descrição | Código habilitação |
|---|---|---|
| 74 | UTI adulto tipo I | 2696 |
| 75 | UTI adulto tipo II | 2601 |
| 76 | UTI adulto tipo III | 2604 |
| 77 | UTI pediátrica tipo I | 2698 |
| 78 | UTI pediátrica tipo II | 2603 |
| 79 | UTI pediátrica tipo III | 2606 |
| 80 | UTI neonatal tipo I | 2697 |
| 83 | UTI de queimados | 2607 |
| 85 | UTI coronariana tipo II | 2608 |
| 86 | UTI coronariana tipo III | 2609 |

**2 pares com sinônimo**, confirmados empiricamente (não só por nome parecido):

| Código leito | Código(s) habilitação | Evidência |
|---|---|---|
| 81 (UTI neonatal tipo II) | 2602 **e** 2610 | 96 de 98 estabelecimentos (~98%) com habilitação 2610 também têm leito 81 cadastrado |
| 82 (UTI neonatal tipo III) | 2605 **e** 2611 | 28 de 28 estabelecimentos (100%) com habilitação 2611 também têm leito 82 cadastrado |

Os códigos 2610 e 2611 aparecem no dicionário oficial como entradas textualmente diferentes de 2602/2605, mas o cruzamento empírico mostra que coexistem nos mesmos estabelecimentos com a mesma função — tratados como sinônimos para fins desta regra, não como categorias distintas.

**Códigos de habilitação sem uso no recorte (SP, nov/2025):** `2612`, `2613` (variantes rotuladas para SRAG/COVID-19), `2699` (UTI tipo I sem especificar público), `8217` (rede cegonha), `8218` (rede de urgência/emergência). Não é uma decisão editorial de exclusão — esses códigos simplesmente não ocorrem nos dados filtrados; podem ter uso relevante em outros recortes geográficos ou temporais.

### Resultado da regra (SP, nov/2025)

| Combinações estabelecimento+categoria de UTI avaliadas | Sem habilitação correspondente | % | Leitos afetados | Estabelecimentos com algum tipo de UTI |
|---|---|---|---|---|
| 1.103 | 553 | 50,1% | 7.312 | 547 |

Metade das combinações de leito de UTI por estabelecimento não tem nenhuma habilitação formal correspondente registrada — resultado coerente com o achado da regra de divergência de quantidade de leitos (`leito.quantidade_total` sistematicamente maior que `habilitacao.quantidade_leitos`), agora visto em nível mais granular e clinicamente relevante.

- **Query de referência:** ver `sql/06-consistencia-uti-sem-habilitacao.sql`

---
---

## `tipo_unidade`

- **Tipo:** STRING (código numérico armazenado como texto)
- **O que representa:** classifica o tipo de estabelecimento de saúde (posto de saúde, hospital geral, farmácia, unidade móvel, central de regulação, entre 44 categorias catalogadas nacionalmente). Campo-base para qualquer segmentação do cadastro por tipo de unidade.
- **Padrão de ausência investigado:** três formas testadas (`NULL`, texto `"nan"`, string vazia `""`) — nenhuma encontrada.
- **Resultado (SP, nov/2025):**

  | Total de estabelecimentos | Nulo | Texto "nan" | String vazia | % Incompleto |
  |---|---|---|---|---|
  | 110.362 | 0 | 0 | 0 | 0% |

- **Distinção importante em relação a outros achados deste dicionário:** diferente de `id_regiao_saude` (54,70% mascarado) e dos sentinelas de `habilitacao`, este resultado de 0% de incompletude foi **confirmado por investigação prévia** — os 38 valores distintos usados no recorte foram inspecionados individualmente antes do cálculo da métrica, e todos correspondem a códigos válidos do dicionário oficial. O zero aqui reflete ausência real de problema, não ausência de verificação.
- **Query de referência:** ver `sql/07-completude-tipo_unidade.sql`

---

---

## `ano_atualizacao` / `mes_atualizacao` — Indicador de Atualidade Cadastral

- **Tipo:** INT64 (ambos)
- **O que representa:** competência (ano/mês) da última alteração cadastral do estabelecimento. Base para a dimensão de qualidade "Atualidade" (distinta de Completude e Consistência, já medidas em outros campos).
- **Padrão de ausência investigado:** nenhum nulo encontrado (0 de 110.362). Intervalo de valores: 2015 a 2025, sem sentinela aparente (diferente do padrão `9999`/`99` encontrado em `habilitacao`).

### Achado observacional (não uma regra de qualidade, mas relevante para interpretação)

2.971 estabelecimentos (2,7%) têm `ano_atualizacao`/`mes_atualizacao` **posterior** à própria competência do arquivo (2025-11) — ou seja, aparecem como atualizados em dezembro/2025 dentro de um arquivo referente a novembro/2025. Hipótese plausível, não confirmada pelos dados: defasagem no processo de publicação/consolidação da fonte, semelhante à defasagem já registrada em `docs/decisao-recorte.md`. Documentado como observação, não como causa estabelecida.

### Decisão metodológica: regra de atualidade

- **Data de referência:** 2025-11 — a competência do próprio snapshot analisado, não a data de execução da análise. Essa escolha torna o indicador uma característica do snapshot, reproduzível por qualquer pessoa que rode a mesma query sobre o mesmo arquivo, independentemente de quando a análise for executada.
- **Janela de atualidade:** 24 meses anteriores à competência de referência (limite: 2023-11, incluído como "ainda atualizado").
- **Justificativa:** 24 meses é uma convenção metodológica deste projeto, adotada por representar um intervalo operacional razoável para avaliar atualidade de um cadastro nacional de estabelecimentos de saúde, evitando classificar como desatualizados registros ainda dentro de um ciclo bienal de manutenção. **Não é uma definição normativa do DATASUS sobre prazo de validade cadastral** — nenhuma fonte oficial desse tipo foi verificada; o corte é uma decisão do projeto, documentada como tal.
- **Categorias:** "atualizado" (competência ≥ 2023-11), "desatualizado" (< 2023-11), "não informado" (ausência de ano/mês) — tratada separadamente, sem ser somada aos desatualizados.

### Resultado (SP, nov/2025)

| Total de estabelecimentos | Atualizados | Desatualizados | Não informado | % Desatualizado |
|---|---|---|---|---|
| 110.362 | 87.494 | 22.868 | 0 | 20,72% |

Cerca de 1 em cada 5 estabelecimentos do recorte não teve nenhuma atualização cadastral nos 24 meses anteriores à competência de referência.

- **Query de referência:** ver `sql/08-atualidade-cadastral.sql`

---

---

## Distribuição Regional — Incompletude de `id_regiao_saude` por Município

- **Unidade de análise:** `id_municipio` (código do município, IBGE).
- **Completude do agrupador:** verificada antes da análise — 0 nulo, 0 texto `"nan"`, 0 string vazia; 644 municípios distintos no recorte (SP tem 645 municípios oficiais).
- **Critério de inclusão:** municípios com volume ≥ 20 estabelecimentos, para evitar que amostras pequenas distorçam o ranking (um município com 1 estabelecimento incompleto apareceria como "100% incompleto").
- **Métrica escolhida:** em vez de contar estabelecimentos por território, mede-se como a incompletude de `id_regiao_saude` (54,70% no agregado do estado, ver seção `id_regiao_saude` acima) se distribui entre os municípios — respondendo diretamente à pergunta de negócio sobre variação territorial da qualidade do cadastro.

### Achado principal: disparidade municipal real

Extremos observados (municípios com volume relevante):

| Município | Estabelecimentos | % Incompleto |
|---|---|---|
| Caieiras | 122 | 99,18% |
| São Caetano do Sul | 960 | 98,44% |
| Santo André | 1.136 | 98,24% |
| São Paulo (capital) | 28.059 | 96,11% |
| ... | ... | ... |
| Ribeirão Preto | 2.877 | 2,16% |
| São José do Rio Preto | 1.539 | 1,43% |
| Presidente Prudente | 1.225 | 0,24% |
| Osvaldo Cruz | 119 | 0% |
| Adamantina | 200 | 0% |

**Hipótese testada e rejeitada:** a hipótese inicial de que municípios maiores/capital concentrariam o problema não se sustentou — São Paulo (capital) está entre os piores, mas municípios pequenos e médios não-capitais (Caieiras, Cajamar, Bertioga) têm incompletude ainda maior.

### Distribuição completa por faixas (correção metodológica)

Os extremos acima sugeriam, à primeira vista, uma distribuição bimodal (dois grupos opostos). A distribuição completa, testada antes de aceitar essa hipótese, mostra outro padrão:

| Faixa de incompletude | Municípios |
|---|---|
| 0–25% | 100 |
| 25–50% | 67 |
| 50–75% | 111 |
| 75–100% | 69 |

Total: 347 municípios com volume ≥ 20 estabelecimentos.

- **Ressalva de atualização (12/09/2026):** após a comparação entre SQL e Python (Fase 2), foram identificados 5 registros adicionais com string vazia (`""`) em `id_regiao_saude`, não contemplados na investigação SQL original. A métrica estadual de incompletude foi atualizada de 60.361 (54,69%) para 60.366 (54,70%). A correção não altera o ranking dos municípios nem a distribuição por faixas dos 347 municípios analisados — 5 registros são insuficientes para mudar esses resultados —, mas 54,70% deve ser usado como referência atualizada no projeto.
- **Interpretação:** existe heterogeneidade municipal relevante e contínua — os municípios se distribuem por todas as faixas, com concentração um pouco maior em 50–75%, não em dois blocos isolados.
- **O que não podemos concluir:** que existem dois grupos distintos de municípios, ou que a diferença decorre de um processo operacional específico. Os extremos permanecem como evidência da amplitude da disparidade, não como evidência de bimodalidade.
- **Hipótese operacional (não confirmada, a investigar):** o padrão de extremos observado nos primeiros rankings é compatível com a hipótese de que alguns municípios usam processos de cadastro/exportação diferentes de outros, mas essa causa não foi verificada nos dados disponíveis.
- **Caso de referência:** Ribeirão Preto (2,16% de incompletude, 2.877 estabelecimentos) está entre os municípios de melhor completude, sem que se possa extrapolar causalidade a partir apenas dessa observação.
- **Próxima investigação sugerida:** identificar quais características dos municípios ou dos estabelecimentos estão associadas aos diferentes níveis de completude observados.

- **Query de referência:** ver `sql/09-distribuicao-regional.sql`

---
---

## `id_municipio`

- **Tipo:** STRING (código de 7 dígitos, numérico em aparência mas armazenado como texto)
- **O que representa:** código do município (IBGE, 7 dígitos: 2 primeiros identificam a UF, 5 seguintes o município) onde está localizado o estabelecimento. Chave de agrupamento territorial, usada também na análise de Distribuição Regional acima.
- **Padrão de ausência investigado:** verificação estrutural (dígitos + prefixo) e verificação por `COUNT(DISTINCT)`, feitas de forma independente e comparadas entre si.
- **Resultado (SP, nov/2025):**

  | Total de estabelecimentos | Municípios distintos | Nulo | Texto "nan" | String vazia | Dígitos fora do padrão (7) |
  |---|---|---|---|---|---|
  | 110.362 | 644 | 0 | 0 | 0 | 0 |

  Todos os 644 valores distintos começam com o prefixo `35` (código IBGE de São Paulo).

- **Interpretação do total de municípios:** São Paulo tem 645 municípios oficiais (IBGE); o recorte cobre 644. O município ausente não teve nenhum estabelecimento de saúde cadastrado nesta competência — não é um problema de completude do campo (nenhum estabelecimento existente ficou sem código), e fica registrado como pendência de investigação (qual município é esse, e se o padrão se repete em outras competências) para a Fase 5.
- **Correção de tipo (12/09/2026):** esta seção documentava o campo como `INT64`. Verificação direta em `INFORMATION_SCHEMA.COLUMNS`, feita na Fase 2 (Python), confirmou que o tipo real é `STRING`. As queries de completude já tratavam o campo corretamente como texto (via `CAST(... AS STRING)`), então a métrica de completude não muda — só a documentação do tipo estava errada.
- **Nota metodológica:** uma primeira contagem de linhas de um arquivo exportado, feita com `wc -l`, indicou 643 em vez de 644 — erro de contagem por ausência de quebra de linha final no CSV, não um problema no dado. Corrigido comparando com uma segunda verificação (`COUNT(DISTINCT id_municipio)`) antes de aceitar a conclusão.
- **Query de referência:** ver `sql/10-completude-id_municipio.sql`

---

## `tipo_gestao`

- **Tipo:** STRING (1 caractere)
- **O que representa:** esfera administrativa responsável pela gestão do estabelecimento.
- **Domínio observado no recorte (SP, nov/2025):**

  | Valor | Significado | Estabelecimentos |
  |---|---|---|
  | `M` | Gestão municipal | 109.733 |
  | `E` | Gestão estadual | 629 |

  Soma = 110.362, o total exato do recorte — 0% de ausência.

- **Domínio teórico vs. domínio observado:** conhecimento prévio (não verificado em fonte oficial nesta sessão) indica que o domínio completo do campo inclui também `D` (dupla gestão) e `S` (sem gestão), nenhum dos dois presente neste recorte. Ausência de uma categoria do domínio teórico não é a mesma coisa que ausência de dado — é o domínio teórico sendo maior que o domínio observado neste recorte específico.
- **Query de referência:** ver `sql/11-completude-tipo_gestao.sql`

---

## `cnpj_mantenedora`

- **Tipo:** STRING
- **O que representa:** CNPJ da entidade mantenedora do estabelecimento, quando o estabelecimento depende de outra instituição para sua manutenção.
- **Padrão de ausência inicial (SP, nov/2025):**

  | Total de estabelecimentos | Vazio | % Vazio | Com CNPJ válido (14 dígitos) | Mantenedoras distintas |
  |---|---|---|---|---|
  | 110.362 | 98.098 | 88,89% | 12.264 | 743 |

  Nenhum valor malformado — ou vazio, ou 14 dígitos completos.

- **Achado central — o vazio bruto não é a métrica de completude correta:** segundo o Manual Técnico do CNES, `cnpj_mantenedora` só é de preenchimento obrigatório quando o estabelecimento tem situação "Mantido" — estabelecimentos "Individuais" legitimamente não preenchem este campo. Medir completude contra o total geral do recorte mistura ausência esperada com ausência real.
- **Campo de classificação identificado:** não existe, entre as 204 colunas de `estabelecimento`, um campo chamado literalmente "situação" ou "individual/mantido". O candidato identificado por nome foi `tipo_grau_dependencia`, cuja distribuição (`1` com 98.098, `3` com 12.264) coincide exatamente com os totais de vazio/preenchido de `cnpj_mantenedora`.
- **Confirmação por tabela cruzada (não apenas coincidência de totais agregados):**

  | `tipo_grau_dependencia` | Status de `cnpj_mantenedora` | Estabelecimentos |
  |---|---|---|
  | `1` | vazio | 98.098 |
  | `3` | preenchido | 12.264 |

  Nenhuma combinação cruzada (`1` + preenchido, ou `3` + vazio) ocorre — correspondência perfeita, sem exceção, em 110.362 registros.

- **Métrica de completude, em duas camadas:**

  | Camada | Resultado |
  |---|---|
  | Completude bruta (todos os estabelecimentos) | 11,11% preenchido, 88,89% vazio |
  | Completude condicional (só entre os que deveriam ter CNPJ, `tipo_grau_dependencia = 3`) | **100% preenchido, 0% de ausência real** |

  Reportar só a completude bruta seria enganoso — na direção oposta, mas equivalente em gravidade, ao erro que `id_regiao_saude` teria causado se medido só por `IS NULL`.

- **Limite da confirmação:** o significado exato dos códigos `1` e `3` de `tipo_grau_dependencia` (isto é, qual rótulo oficial — "Individual", "Mantido" — corresponde a qual código) não foi confirmado em nenhuma fonte oficial que os nomeie diretamente. A confirmação usada aqui é evidência empírica (correspondência perfeita e sem exceção com `cnpj_mantenedora`), não leitura de documentação.
- **Query de referência:** ver `sql/12-completude-cnpj_mantenedora.sql`

---

## Unicidade — `id_estabelecimento_cnes`

- **Tipo:** STRING
- **O que representa:** identificador único do estabelecimento no CNES. Combinado com `ano` e `mes`, forma a chave de relacionamento do projeto entre todas as tabelas (Fase 1) — necessária porque a mesma tabela contém múltiplas competências (fotografias mensais) do mesmo estabelecimento.
- **Escopo do teste de unicidade:** como o recorte já fixa `ano = 2025` e `mes = 11` no filtro, essas duas partes da chave composta já são constantes dentro da consulta. A duplicidade testada, portanto, é sobre `id_estabelecimento_cnes` isolado, dentro deste recorte específico.
- **Resultado (SP, nov/2025):**

  | Total de estabelecimentos | `id_estabelecimento_cnes` duplicados |
  |---|---|
  | 110.362 | 0 |

  Nenhum identificador se repete — `id_estabelecimento_cnes` funciona como chave única de fato dentro deste recorte, sem exceção.

- **Query de referência:** ver `sql/13-unicidade-id_estabelecimento_cnes.sql`

---

*Fase 3 concluída: completude (5 campos: `id_regiao_saude`, `tipo_unidade`, `id_municipio`, `tipo_gestao`, `cnpj_mantenedora`), consistência (3 regras), atualidade (1 indicador), distribuição regional (1 indicador, extensão de completude) e unicidade (1 indicador). As quatro dimensões de qualidade fixas do projeto — completude, consistência, atualidade, unicidade — estão cobertas por pelo menos um indicador cada.*
