# Dicionário de Dados — Projeto CNES

Registro dos campos analisados na tabela `basedosdados.br_ms_cnes.estabelecimento`, recorte SP + competência 2025-11.

Para cada campo: tipo de dado, o que representa, e como valores ausentes se manifestam na prática (nem sempre como `NULL`).

---

## `id_regiao_saude`

- **Tipo:** STRING
- **O que representa:** código da região de saúde à qual o estabelecimento está vinculado, usado para planejamento e alocação de recursos regionais.
- **Padrão de ausência identificado:** o campo não usa `NULL` para representar ausência de valor. Em vez disso, parte dos registros traz o texto literal `"nan"` armazenado como string.
- **Impacto:** uma verificação de completude baseada apenas em `IS NULL` retorna 0% de incompletude neste campo — resultado enganoso. A verificação correta precisa somar `IS NULL` **e** `= 'nan'`.
- **Hipótese de causa:** provável resíduo de um processo de tratamento de dados (ex.: exportação via pandas/Python, onde `NaN` é a representação padrão de ausência) que converteu o valor ausente em texto antes de gravar na base, em vez de preservá-lo como nulo.
- **Métrica de completude (SP, nov/2025):**

  | Total de estabelecimentos | Incompletos (NULL + "nan") | % Incompleto |
  |---|---|---|
  | 110.362 | 60.361 | 54,69% |

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

- **Distinção importante em relação a outros achados deste dicionário:** diferente de `id_regiao_saude` (54,69% mascarado) e dos sentinelas de `habilitacao`, este resultado de 0% de incompletude foi **confirmado por investigação prévia** — os 38 valores distintos usados no recorte foram inspecionados individualmente antes do cálculo da métrica, e todos correspondem a códigos válidos do dicionário oficial. O zero aqui reflete ausência real de problema, não ausência de verificação.
- **Query de referência:** ver `sql/07-completude-tipo_unidade.sql`

---

*Próximo campo a investigar: a definir entre `id_municipio`, `tipo_gestao` ou `cnpj_mantenedora`.*
