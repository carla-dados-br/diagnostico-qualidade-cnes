# Log Completo de Queries — Projeto CNES

Registro de toda query executada no projeto desde o início: a pergunta que ela responde, o SQL exato, o resultado obtido, e a decisão tomada a partir dele — incluindo tentativas que não deram certo na primeira vez. Este arquivo consolida o histórico completo (Fase 1 e Fase 3) num único documento cronológico.

Recorte padrão: `sigla_uf = 'SP'`, `ano = 2025`, `mes = 11`, tabela `basedosdados.br_ms_cnes.estabelecimento`, salvo indicação contrária.

---

# FASE 1 — Exploração, Extração e Verificação de Estrutura

## Exploração inicial da tabela `estabelecimento`

**Pergunta:** como são os dados reais da tabela, sem filtro nenhum?

```sql
SELECT *
FROM `basedosdados.br_ms_cnes.estabelecimento`
LIMIT 10;
```

**Resultado:** 10 linhas reais. Achado imediato: `id_regiao_saude` aparecia como `"nan"` em parte das linhas — pista que levaria à investigação de completude na Fase 3.

**Custo:** 0 bytes processados (SELECT * sem WHERE/agregação é leitura direta, sem cobrança).

---

## Estrutura da tabela (colunas)

**Pergunta:** quais colunas existem em `estabelecimento`?

```sql
SELECT column_name, data_type
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'estabelecimento';
```

**Resultado:** 204 colunas. Custo: 0 bytes (consulta ao catálogo de metadados, não aos dados).

---

## Competências disponíveis

**Pergunta:** quais competências (ano/mês) existem na base, da mais recente à mais antiga?

```sql
SELECT DISTINCT ano, mes
FROM `basedosdados.br_ms_cnes.estabelecimento`
ORDER BY ano DESC, mes DESC
LIMIT 5;
```

**Resultado:** 245 competências distintas, desde 2005-08. Mais recente: 2025-12.

---

## Validação de volume por competência (escolha do recorte temporal)

**Pergunta:** a competência mais recente disponível (dez/2025) é a mais confiável, ou sofre defasagem de consolidação?

```sql
SELECT ano, mes, COUNT(*) AS total_estabelecimentos
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE ano = 2025 AND mes >= 8
GROUP BY ano, mes
ORDER BY ano DESC, mes DESC;
```

**Resultado (Brasil, todas as UFs):**

| Competência | Total |
|---|---|
| 2025-12 | 470.360 |
| 2025-11 | 471.254 |
| 2025-10 | 470.397 |
| 2025-09 | 469.214 |
| 2025-08 | 465.866 |

**Decisão:** novembro/2025 escolhida como referência — maior volume da série recente, indicando ser a competência mais consolidada.

---

## Total do recorte final (SP + novembro/2025)

**Pergunta:** quantos estabelecimentos existem no recorte definitivo do projeto?

```sql
SELECT COUNT(*) AS total_estabelecimentos_sp_nov25
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11;
```

**Resultado: 110.362 estabelecimentos.** Base de trabalho de todo o restante do projeto.

---

## Verificação de estrutura do conjunto completo — onde estão os dados de capacidade instalada

**Pergunta:** a tabela `estabelecimento` tem os campos de leito e equipamento, ou eles estão em outro lugar?

```sql
SELECT table_name, column_name, data_type
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN ('estabelecimento','leito','equipamento','habilitacao','servico_especializado')
ORDER BY table_name, ordinal_position;
```

**Resultado:** 257 linhas — mas `estabelecimento` (204) + `equipamento` (12) somam só 216. Diferença de 41 levou à query seguinte.

---

## Inventário completo de tabelas do conjunto

**Pergunta:** quantas tabelas existem no conjunto `br_ms_cnes`, e quantas colunas cada uma tem?

```sql
SELECT table_name, COUNT(*) AS total_colunas
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
GROUP BY table_name
ORDER BY table_name;
```

**Resultado:** 14 tabelas ao todo. As três pendentes (`leito`=10, `habilitacao`=16, `servico_especializado`=15) somavam exatamente os 41 que faltavam. Achado não previsto: existência da tabela `dicionario`.

---

## Estrutura das tabelas de capacidade instalada — confirmação da chave de junção

**Pergunta:** quais campos existem em `leito`, `habilitacao` e `servico_especializado`, e elas têm as chaves para JOIN?

```sql
SELECT table_name, column_name, data_type
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN ('leito','habilitacao','servico_especializado')
ORDER BY table_name, ordinal_position;
```

**Resultado:** as cinco primeiras colunas das três tabelas são `ano`, `mes`, `sigla_uf`, `id_municipio`, `id_estabelecimento_cnes` — as mesmas de `estabelecimento`. Chave de junção composta confirmada: `id_estabelecimento_cnes + ano + mes`.

---

## Estrutura da tabela `dicionario`

**Pergunta:** o dicionário serve para traduzir os códigos das outras tabelas? Em que formato?

```sql
SELECT column_name, data_type
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'dicionario'
ORDER BY ordinal_position;
```

**Resultado:** 5 colunas — `id_tabela`, `nome_coluna`, `chave`, `valor`, `cobertura_temporal`. Formato de-para: informa a qual tabela e coluna o código pertence, o código em si e seu significado.

---

## Estrutura da tabela `profissional` — achado de dado pessoal

**Pergunta:** existe campo de responsabilidade técnica, para uma regra de alta complexidade sem responsável habilitado?

```sql
SELECT column_name, data_type
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'profissional'
ORDER BY ordinal_position;
```

**Resultado:** 23 colunas. **Não existe** campo de responsabilidade técnica. **Achado crítico:** a tabela contém `nome`, `cartao_nacional_saude` e `id_municipio_6_residencia` — dado pessoal de profissional de saúde em base pública.

**Decisão:** tabela excluída do escopo do projeto. Nenhum dado pessoal extraído, tratado ou versionado. Premissa da versão 1 do documento de arquitetura (que assumia ausência de dado pessoal) corrigida na versão 2.

---

## Códigos de especialidade e tipo de leito (UTI)

**Pergunta:** qual código representa UTI? A especialidade sozinha identifica o leito?

```sql
SELECT id_tabela, nome_coluna, chave, valor
FROM `basedosdados.br_ms_cnes.dicionario`
WHERE nome_coluna IN ('tipo_especialidade_leito', 'tipo_leito')
ORDER BY nome_coluna, chave;
```

**Resultado:** 73 linhas. UTI aparece nos códigos 74 a 83, 85 e 86 de `tipo_especialidade_leito`. **Decisão técnica:** a especialidade não identifica o leito sozinha (cardiologia = código 2 ou 32); toda agregação precisa usar `tipo_especialidade_leito` **e** `tipo_leito` juntos.

---

# FASE 3 — Indicadores de Qualidade e Regras de Consistência

## `id_regiao_saude` — completude

**Pergunta:** qual o percentual de estabelecimentos sem `id_regiao_saude` preenchido?

**Query 1 — checagem inicial (insuficiente):**
```sql
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF(id_regiao_saude IS NULL) AS total_sem_regiao_saude,
  ROUND(COUNTIF(id_regiao_saude IS NULL) / COUNT(*) * 100, 2) AS percentual_incompleto
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11;
```
**Resultado:** 0 incompletos, 0,0%. Falso negativo — o campo não usa `NULL` para ausência.

**Query 2 — investigação de ausência disfarçada:**
```sql
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF(id_regiao_saude = 'nan') AS total_com_texto_nan,
  COUNTIF(id_regiao_saude IS NULL) AS total_null_verdadeiro,
  ROUND(COUNTIF(id_regiao_saude = 'nan') / COUNT(*) * 100, 2) AS percentual_incompleto
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11;
```
**Resultado:** 60.361 registros com texto literal `"nan"`, 0 nulos verdadeiros.

**Query 3 — métrica final:**
```sql
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF(id_regiao_saude IS NULL OR id_regiao_saude = 'nan') AS total_incompletos,
  ROUND(COUNTIF(id_regiao_saude IS NULL OR id_regiao_saude = 'nan') / COUNT(*) * 100, 2) AS percentual_incompleto_real
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11;
```
**Resultado: 60.361 incompletos, 54,69%.**

**Decisão:** métrica oficial soma `NULL` real + texto `"nan"`. Recomendação para a Fase 2: converter `"nan"` para nulo reconhecido pelo pandas antes de qualquer agregação.

---

## Habilitação vencida ainda registrada — consistência

**Pergunta:** existe habilitação com competência final vencida, mas ainda presente na base?

**Query 1 — tentativa inicial:**
```sql
SELECT
  COUNT(*) AS total_habilitacoes,
  COUNTIF((ano_competencia_final * 100 + mes_competencia_final) < 202511) AS total_vencidas
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11;
```
**Resultado:** 0 vencidas, 0,0% — suspeito.

**Query 2 — checagem de nulo:**
```sql
SELECT
  COUNT(*) AS total_habilitacoes,
  COUNTIF(ano_competencia_final IS NULL) AS sem_data_final
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11;
```
**Resultado:** 0 nulos. Hipótese de ausência por nulo descartada.

**Query 3 — intervalo de valores:**
```sql
SELECT MIN(ano_competencia_final), MAX(ano_competencia_final),
       MIN(mes_competencia_final), MAX(mes_competencia_final)
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11;
```
**Resultado:** ano de 2025 a 9999, mês de 1 a 99 — **sentinela 9999/99 identificado**.

**Query 4 — regra corrigida:**
```sql
SELECT
  COUNT(*) AS total_habilitacoes,
  COUNTIF(ano_competencia_final = 9999) AS total_indeterminadas,
  COUNTIF(ano_competencia_final != 9999 AND (ano_competencia_final*100+mes_competencia_final) < 202511) AS total_vencidas
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11;
```
**Resultado:** 6.764 total, 6.072 indeterminadas (89,76%), 692 com data definida, 0 vencidas.

**Query 5 — confirmação:**
```sql
SELECT MIN(ano_competencia_final*100+mes_competencia_final) AS competencia_final_minima,
       MAX(ano_competencia_final*100+mes_competencia_final) AS competencia_final_maxima
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf='SP' AND ano=2025 AND mes=11 AND ano_competencia_final != 9999;
```
**Resultado:** mínima 202511 — a habilitação mais próxima de vencer expira na própria competência de referência. Zero vencidas é resultado genuíno, não artefato de cálculo. Máxima: 299912 — outlier a investigar.

**Query 6 — investigação do outlier:**
```sql
SELECT ano_competencia_final, mes_competencia_final, COUNT(*) AS total
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf='SP' AND ano=2025 AND mes=11 AND ano_competencia_final != 9999
GROUP BY ano_competencia_final, mes_competencia_final
ORDER BY ano_competencia_final DESC, mes_competencia_final DESC LIMIT 15;
```
**Resultado:** `2999/12` aparece 1 única vez — outlier isolado, não um segundo sentinela. Causa não determinável pelos dados (não documentada como erro de digitação sem confirmação da fonte).

**Decisão:** regra final exclui sentinela 9999 antes de comparar datas.

---

## Divergência de quantidade de leitos — consistência

**Pergunta:** `leito.quantidade_total` coincide com `habilitacao.quantidade_leitos` para o mesmo estabelecimento?

```sql
WITH leitos_agregados AS (
  SELECT id_estabelecimento_cnes, SUM(quantidade_total) AS total_leitos
  FROM `basedosdados.br_ms_cnes.leito`
  WHERE sigla_uf='SP' AND ano=2025 AND mes=11
  GROUP BY id_estabelecimento_cnes
),
habilitacoes_agregadas AS (
  SELECT id_estabelecimento_cnes, SUM(quantidade_leitos) AS total_leitos_habilitados
  FROM `basedosdados.br_ms_cnes.habilitacao`
  WHERE sigla_uf='SP' AND ano=2025 AND mes=11
  GROUP BY id_estabelecimento_cnes
)
SELECT COUNT(*) AS total_avaliaveis,
       COUNTIF(l.total_leitos != h.total_leitos_habilitados) AS total_divergencia
FROM leitos_agregados l JOIN habilitacoes_agregadas h
  ON l.id_estabelecimento_cnes = h.id_estabelecimento_cnes;
```
**Resultado:** 768 avaliáveis, 768 com divergência (100%).

**Query de investigação da direção:**
```sql
SELECT MIN(l.total_leitos - h.total_leitos_habilitados) AS diferenca_minima,
       MAX(l.total_leitos - h.total_leitos_habilitados) AS diferenca_maxima,
       COUNTIF(l.total_leitos > h.total_leitos_habilitados) AS leito_maior
FROM leitos_agregados l JOIN habilitacoes_agregadas h
  ON l.id_estabelecimento_cnes = h.id_estabelecimento_cnes;
```
**Resultado:** diferença de 1 a 1.309, média 97,88. Em 768 de 768 casos, `leito` ≥ `habilitacao`, nunca o contrário.

**Decisão:** divergência sistemática e direcional, não erro aleatório. Hipótese (não confirmada): os campos medem conceitos diferentes.

---

## Leito de UTI sem habilitação correspondente — consistência

**Pergunta:** existe leito de UTI cadastrado sem nenhuma habilitação formal correspondente?

**Query de busca dos códigos de habilitação de UTI:**
```sql
SELECT chave, valor FROM `basedosdados.br_ms_cnes.dicionario`
WHERE nome_coluna='tipo_habilitacao'
  AND (LOWER(valor) LIKE '%terapia intensiva%' OR LOWER(valor) LIKE '%uti%');
```
**Resultado:** 19 códigos candidatos (com falsos positivos de "terapêutica" descartados manualmente) — 14 realmente relacionados a UTI.

**De-para construído:** 12 pares diretos por igualdade semântica (ex.: leito 74 = "UTI adulto tipo I" ↔ habilitação 2696) + 2 pares com sinônimo, validados empiricamente:

```sql
-- validação do código 2610 como sinônimo de 2602 (leito 81)
WITH estabelecimentos_2610 AS (
  SELECT DISTINCT id_estabelecimento_cnes FROM `basedosdados.br_ms_cnes.habilitacao`
  WHERE sigla_uf='SP' AND ano=2025 AND mes=11 AND tipo_habilitacao='2610'
)
SELECT l.id_estabelecimento_cnes, l.tipo_especialidade_leito, l.quantidade_total
FROM `basedosdados.br_ms_cnes.leito` l JOIN estabelecimentos_2610 e
  ON l.id_estabelecimento_cnes = e.id_estabelecimento_cnes
WHERE l.sigla_uf='SP' AND l.ano=2025 AND l.mes=11 AND l.tipo_especialidade_leito='81';
```
**Resultado:** 96 de 98 estabelecimentos confirmados (~98%). Mesma lógica para 2611/2605 (leito 82): 28 de 28 (100%).

**Query final (LEFT JOIN):**
```sql
WITH leitos_uti AS (
  SELECT id_estabelecimento_cnes,
    CASE tipo_especialidade_leito WHEN '74' THEN 'uti_adulto_1' /* ... */ END AS categoria_uti,
    SUM(quantidade_total) AS total_leitos
  FROM `basedosdados.br_ms_cnes.leito`
  WHERE sigla_uf='SP' AND ano=2025 AND mes=11
    AND tipo_especialidade_leito IN ('74','75','76','77','78','79','80','81','82','83','85','86')
  GROUP BY id_estabelecimento_cnes, categoria_uti
),
habilitacoes_uti AS (
  SELECT DISTINCT id_estabelecimento_cnes,
    CASE tipo_habilitacao WHEN '2696' THEN 'uti_adulto_1' /* ... */ END AS categoria_uti
  FROM `basedosdados.br_ms_cnes.habilitacao`
  WHERE sigla_uf='SP' AND ano=2025 AND mes=11
    AND tipo_habilitacao IN ('2696','2601','2604','2698','2603','2606','2697','2602','2610','2605','2611','2607','2608','2609')
)
SELECT COUNT(DISTINCT l.id_estabelecimento_cnes || l.categoria_uti) AS total_combinacoes,
       COUNT(DISTINCT CASE WHEN h.id_estabelecimento_cnes IS NULL THEN l.id_estabelecimento_cnes || l.categoria_uti END) AS total_sem_habilitacao,
       SUM(CASE WHEN h.id_estabelecimento_cnes IS NULL THEN l.total_leitos ELSE 0 END) AS leitos_sem_habilitacao
FROM leitos_uti l LEFT JOIN habilitacoes_uti h
  ON l.id_estabelecimento_cnes = h.id_estabelecimento_cnes AND l.categoria_uti = h.categoria_uti;
```
**Resultado:** 1.103 combinações avaliadas, 553 sem habilitação (50,1%), 7.312 leitos afetados.

---

## `tipo_unidade` — completude

**Pergunta:** `tipo_unidade` tem alguma forma de ausência (nulo, "nan", string vazia)?

**Query 1 — valores distintos:**
```sql
SELECT DISTINCT tipo_unidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11
ORDER BY tipo_unidade;
```
**Resultado observado na investigação original:** 38 valores distintos, todos numéricos e sem ausência aparente pelo formato.

> **Atualização posterior — Fase 6:** a investigação semântica mostrou que 37 dos 38 códigos observados possuem correspondência na tabela `dicionario`. O código `16`, presente em 5 estabelecimentos no recorte SP + novembro/2025, não possui correspondência nessa fonte auxiliar. O teste de proveniência encontrou `TP_UNID = 16` para os mesmos 5 CNES na origem consultada via PySUS, mas seu significado semântico permanece não confirmado. Ver [`investigacao-proveniencia-tipo-unidade-16.md`](investigacao-proveniencia-tipo-unidade-16.md).

**Query 2 — tradução via dicionário:**
```sql
SELECT chave, valor FROM `basedosdados.br_ms_cnes.dicionario`
WHERE nome_coluna = 'tipo_unidade' ORDER BY chave;
```
**Resultado:** 44 códigos estão registrados na tabela `dicionario`. No recorte foram observados 38 códigos distintos de `tipo_unidade`: 37 possuem correspondência nessa tabela e o código `16` não possui correspondência.

**Query 3 — métrica de completude:**
```sql
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF(tipo_unidade IS NULL) AS total_nulo,
  COUNTIF(tipo_unidade = 'nan') AS total_texto_nan,
  COUNTIF(tipo_unidade = '') AS total_string_vazia,
  ROUND(COUNTIF(tipo_unidade IS NULL OR tipo_unidade = 'nan' OR tipo_unidade = '') / COUNT(*) * 100, 2) AS percentual_incompleto
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11;
```
**Resultado:** 0 em todas as três formas de ausência — **0% de incompletude, confirmado por investigação prévia** (diferente dos zeros suspeitos de outros campos).

---

## Atualidade cadastral

**Pergunta:** qual o percentual de estabelecimentos sem atualização recente?

**Query 1 — distribuição por competência de atualização:**
```sql
SELECT ano_atualizacao, mes_atualizacao, COUNT(*) AS total_estabelecimentos
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf='SP' AND ano=2025 AND mes=11
GROUP BY ano_atualizacao, mes_atualizacao
ORDER BY ano_atualizacao DESC, mes_atualizacao DESC LIMIT 20;
```
**Resultado:** achado inesperado — 2025-12 aparece com 2.971 estabelecimentos, competência **posterior** à do arquivo (2025-11).

**Query 2 — checagem de nulo e intervalo:**
```sql
SELECT COUNT(*) AS total, COUNTIF(ano_atualizacao IS NULL) AS sem_ano,
       MIN(ano_atualizacao) AS ano_minimo, MAX(ano_atualizacao) AS ano_maximo
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf='SP' AND ano=2025 AND mes=11;
```
**Resultado:** 0 nulos, intervalo de 2015 a 2025 — sem sentinela aparente.

**Query 3 — investigação da atualização posterior à competência:**
```sql
SELECT COUNT(*) AS total,
  COUNTIF((ano_atualizacao*100+mes_atualizacao) > 202511) AS apos_competencia,
  COUNTIF((ano_atualizacao*100+mes_atualizacao) = 202511) AS na_competencia,
  COUNTIF((ano_atualizacao*100+mes_atualizacao) < 202511) AS antes_competencia
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf='SP' AND ano=2025 AND mes=11;
```
**Resultado:** 2.971 (2,7%) após, 6.082 (5,5%) na própria, 101.309 (91,8%) antes — padrão real, hipótese de defasagem de publicação registrada sem confirmação.

**Query 4 — distribuição por ano (base para o corte):**
```sql
SELECT ano_atualizacao, COUNT(*) AS total, ROUND(COUNT(*)/110362*100,2) AS percentual
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf='SP' AND ano=2025 AND mes=11
GROUP BY ano_atualizacao ORDER BY ano_atualizacao DESC;
```
**Resultado:** 2025+2024 somam 78,54%. Sem "penhasco" abrupto ano a ano.

**Decisão metodológica:** data de referência = competência do snapshot (2025-11, não a data de execução), janela de 24 meses (convenção do projeto, não norma DATASUS). Limite: 2023-11 (202311).

**Query 5 — indicador final:**
```sql
SELECT COUNT(*) AS total,
  COUNTIF(ano_atualizacao IS NOT NULL AND mes_atualizacao IS NOT NULL AND (ano_atualizacao*100+mes_atualizacao) >= 202311) AS atualizados,
  COUNTIF(ano_atualizacao IS NOT NULL AND mes_atualizacao IS NOT NULL AND (ano_atualizacao*100+mes_atualizacao) < 202311) AS desatualizados,
  COUNTIF(ano_atualizacao IS NULL OR mes_atualizacao IS NULL) AS nao_informado
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf='SP' AND ano=2025 AND mes=11;
```
**Resultado:** 87.494 atualizados, 22.868 desatualizados (**20,72%**), 0 não informado.

---

## Distribuição regional — incompletude de `id_regiao_saude` por município

**Pergunta:** a incompletude de `id_regiao_saude` (54,69%) está uniformemente distribuída entre municípios, ou concentrada?

**Query 1 — verificação de completude do agrupador:**
```sql
SELECT COUNT(*) AS total, COUNTIF(id_municipio IS NULL) AS nulo,
       COUNTIF(id_municipio = 'nan') AS texto_nan, COUNTIF(id_municipio = '') AS string_vazia,
       COUNT(DISTINCT id_municipio) AS total_municipios
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf='SP' AND ano=2025 AND mes=11;
```
**Resultado:** 0 nulo, 0 "nan", 0 vazio, 644 municípios distintos (SP tem 645 oficiais). Agrupador confiável.

**Query 2 — municípios com maior incompletude (JOIN com diretório de municípios):**
```sql
WITH incompletude_por_municipio AS (
  SELECT id_municipio, COUNT(*) AS total_estabelecimentos,
    ROUND(COUNTIF(id_regiao_saude IS NULL OR id_regiao_saude = 'nan') / COUNT(*) * 100, 2) AS percentual_incompleto
  FROM `basedosdados.br_ms_cnes.estabelecimento`
  WHERE sigla_uf='SP' AND ano=2025 AND mes=11
  GROUP BY id_municipio
  HAVING total_estabelecimentos >= 20
)
SELECT m.nome, m.capital_uf, i.total_estabelecimentos, i.percentual_incompleto
FROM incompletude_por_municipio i JOIN `basedosdados.br_bd_diretorios_brasil.municipio` m
  ON i.id_municipio = m.id_municipio
ORDER BY i.percentual_incompleto DESC LIMIT 20;
```
**Resultado:** piores casos entre 90% e 99% (Caieiras 99,18%, São Caetano do Sul 98,44%...), incluindo São Paulo capital (96,11%) mas também municípios pequenos — hipótese de "capital concentra o problema" **rejeitada**.

**Query 3 — municípios com menor incompletude:**
```sql
-- mesma CTE, ORDER BY percentual_incompleto ASC LIMIT 20
```
**Resultado:** vários municípios com 0% (Osvaldo Cruz, Adamantina...), Ribeirão Preto com 2,16%.

**Query 4 — distribuição completa por faixas (teste da hipótese de bimodalidade):**
```sql
WITH incompletude_por_municipio AS ( /* mesma CTE */ )
SELECT
  CASE WHEN percentual_incompleto<25 THEN '0-25%' WHEN percentual_incompleto<50 THEN '25-50%'
       WHEN percentual_incompleto<75 THEN '50-75%' ELSE '75-100%' END AS faixa,
  COUNT(*) AS total_municipios
FROM incompletude_por_municipio GROUP BY faixa ORDER BY faixa;
```
**Resultado:** 100 / 67 / 111 / 69 municípios nas quatro faixas (347 total) — **hipótese de bimodalidade rejeitada**; distribuição espalhada e contínua, concentração relativa em 50-75%.

---

# FASE 3 (continuação) — Campos Críticos de Completude Restantes e Unicidade

## `id_municipio` — fechado

**Pergunta:** existe valor ausente ou malformado em `id_municipio`, e quantos municípios distintos aparecem no recorte?

**Query 1 — valores distintos com verificação estrutural:**
```sql
SELECT id_municipio, LENGTH(CAST(id_municipio AS STRING)) AS qtd_digitos, COUNT(*) AS quantidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11
GROUP BY id_municipio
ORDER BY qtd_digitos ASC, quantidade DESC, id_municipio;
```
**Resultado:** 644 valores distintos, todos com exatamente 7 dígitos, todos iniciando em "35" (prefixo IBGE de SP). Nenhum nulo, vazio ou malformado.

**Query 2 — verificação cruzada, método diferente:**
```sql
SELECT COUNT(*) AS total_estabelecimentos, COUNTIF(id_municipio IS NULL) AS nulo,
       COUNTIF(id_municipio = 'nan') AS texto_nan, COUNTIF(id_municipio = '') AS string_vazia,
       COUNT(DISTINCT id_municipio) AS total_municipios_distintos
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11;
```
**Resultado:** confirma exatamente a Query 1 — 644 municípios, 0 em todas as formas de ausência.

**Decisão:** campo 100% completo. São Paulo tem 645 municípios oficiais (IBGE); o recorte cobre 644 — 1 município sem estabelecimento cadastrado nesta competência, registrado como pendência de escalabilidade (Fase 5), não como problema de completude.

**Nota metodológica:** uma contagem inicial via `wc -l` no arquivo exportado indicou 643 em vez de 644 — erro de contagem por ausência de quebra de linha final no CSV, não um problema no dado. Corrigido comparando com a Query 2 antes de aceitar qualquer conclusão.

---

## `tipo_gestao` — fechado

**Pergunta:** quais valores existem em `tipo_gestao`, e há alguma forma de ausência?

```sql
SELECT tipo_gestao, COUNT(*) AS quantidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11
GROUP BY tipo_gestao
ORDER BY quantidade DESC;
```
**Resultado:** `M` (municipal) com 109.733, `E` (estadual) com 629. Soma = 110.362, o total exato do recorte.

**Decisão:** campo 100% completo. Domínio esperado (não verificado em fonte oficial nesta sessão) inclui também `D` e `S`, que não ocorrem neste recorte — domínio teórico maior que o observado, sem indicar ausência.

---

## `cnpj_mantenedora` — fechado

**Pergunta:** existe valor ausente em `cnpj_mantenedora`, e o que esse vazio significa?

**Query 1 — valores distintos com verificação estrutural:**
```sql
SELECT cnpj_mantenedora, LENGTH(CAST(cnpj_mantenedora AS STRING)) AS qtd_digitos, COUNT(*) AS quantidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11
GROUP BY cnpj_mantenedora
ORDER BY qtd_digitos ASC, quantidade DESC, cnpj_mantenedora;
```
**Resultado:** 98.098 vazios (88,89%), 12.264 com CNPJ válido de 14 dígitos (743 mantenedoras distintas). Nenhum valor malformado.

**Achado:** segundo o Manual Técnico do CNES, `cnpj_mantenedora` só é obrigatório quando o estabelecimento tem situação "Mantido" — estabelecimentos "Individuais" legitimamente não preenchem. 88,89% de vazio não é necessariamente 88,89% de incompletude real.

**Query 2 — busca de campo de classificação Individual/Mantido:**
```sql
SELECT column_name, data_type
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'estabelecimento'
ORDER BY column_name;
```
**Resultado:** nenhuma coluna literalmente chamada "situação"; candidato identificado por nome: `tipo_grau_dependencia`.

**Query 3 — distribuição de `tipo_grau_dependencia`:**
```sql
SELECT tipo_grau_dependencia, COUNT(*) AS quantidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11
GROUP BY tipo_grau_dependencia
ORDER BY quantidade DESC;
```
**Resultado:** valor `1` com 98.098, valor `3` com 12.264 — totais idênticos aos de vazio/preenchido em `cnpj_mantenedora`.

**Query 4 — tabela cruzada, confirmação linha a linha:**
```sql
SELECT
    tipo_grau_dependencia,
    CASE
        WHEN cnpj_mantenedora IS NULL OR cnpj_mantenedora = '' THEN 'vazio'
        ELSE 'preenchido'
    END AS status_cnpj,
    COUNT(*) AS quantidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11
GROUP BY tipo_grau_dependencia, status_cnpj
ORDER BY tipo_grau_dependencia, status_cnpj;
```
**Resultado:** exatamente 2 combinações, sem exceção — `1` + `vazio` (98.098) e `3` + `preenchido` (12.264). Confirmação linha a linha, não só coincidência de totais.

**Decisão:** `tipo_grau_dependencia` codifica a distinção Individual/Mantido do manual técnico do CNES, mesmo sem nome literal no campo. Métrica final tem duas camadas:

| Camada | Resultado |
|---|---|
| Completude bruta (todos os estabelecimentos) | 11,11% preenchido, 88,89% vazio |
| Completude condicional (só entre os que deveriam ter CNPJ, `tipo_grau_dependencia = 3`) | **100% preenchido, 0% de ausência real** |

Reportar só a completude bruta seria enganoso, na mesma direção (embora oposta em efeito) do erro que `id_regiao_saude` teria causado se medido só por `IS NULL`. O significado dos códigos `1`/`3` não foi confirmado em fonte oficial nomeando-os — a confirmação vem da correspondência perfeita e sem exceção com `cnpj_mantenedora`, que é evidência empírica direta, não leitura de documentação.

---

## Unicidade — `id_estabelecimento_cnes` — fechado

**Pergunta:** existe estabelecimento duplicado dentro do recorte (mesmo `id_estabelecimento_cnes` aparecendo mais de uma vez em SP/nov-2025)?

**Nota sobre a chave:** a chave de relacionamento do projeto é `id_estabelecimento_cnes + ano + mes` (Fase 1), necessária porque a mesma tabela contém várias competências. Como o recorte já fixa `ano = 2025` e `mes = 11` no `WHERE`, essas duas partes da chave já são constantes dentro da consulta — a duplicidade a testar, neste recorte específico, é só sobre `id_estabelecimento_cnes` isolado.

```sql
SELECT
    id_estabelecimento_cnes,
    COUNT(*) AS quantidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11
GROUP BY id_estabelecimento_cnes
HAVING COUNT(*) > 1
ORDER BY quantidade DESC;
```
**Resultado:** 0 linhas. Nenhum `id_estabelecimento_cnes` se repete no recorte.

**Decisão:** unicidade confirmada — `id_estabelecimento_cnes` funciona como chave única de fato dentro de SP/nov-2025, sem exceção, em 110.362 registros. Última das quatro dimensões de qualidade fixas do projeto (completude, consistência, atualidade, unicidade) fechada — nota: o README anterior contava "distribuição regional" como a quarta dimensão, mas essa análise é uma extensão de completude, não a dimensão unicidade definida no documento de arquitetura. Esta seção fecha a dimensão que de fato faltava.

---

## Como manter este log

Ao fechar um campo novo: adicionar uma seção seguindo o padrão acima (pergunta, query, resultado, decisão). Ao reabrir um campo "fechado" por causa de um achado novo, mover para "em andamento" e registrar o motivo da reabertura, sem apagar o histórico anterior.
