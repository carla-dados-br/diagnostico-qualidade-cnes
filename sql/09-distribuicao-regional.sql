-- =====================================================================
-- FASE 3 — Indicador de distribuicao regional
-- Recorte: SP, competencia 2025-11
-- Metrica: como a incompletude de id_regiao_saude (ja quantificada em
-- sql/03) varia entre municipios - nao apenas contagem de
-- estabelecimentos por territorio.
-- =====================================================================

-- -----------------------------------------------------------------------
-- 1. Verificacao da completude do agrupador (id_municipio) ANTES de
-- usa-lo como base de agrupamento - mesmo principio ja aplicado a
-- outros campos: nao herdar um problema de completude nao verificado.
-- Resultado: 0 nulo, 0 texto "nan", 0 string vazia. 644 municipios
-- distintos no recorte (SP tem 645 municipios oficiais - diferenca
-- provavelmente e um municipio sem nenhum estabelecimento no recorte).
-- -----------------------------------------------------------------------
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF(id_municipio IS NULL) AS nulo,
  COUNTIF(id_municipio = 'nan') AS texto_nan,
  COUNTIF(id_municipio = '') AS string_vazia,
  COUNT(DISTINCT id_municipio) AS total_municipios_distintos
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;


-- -----------------------------------------------------------------------
-- 2. Municipios com MAIOR incompletude (volume >= 20 estabelecimentos,
-- para nao distorcer o ranking com amostras pequenas). Traduzido via
-- JOIN com a tabela de referencia geografica br_bd_diretorios_brasil.municipio
-- (primeiro JOIN do projeto entre datasets diferentes da Base dos Dados).
-- Resultado: piores casos entre 90% e 99% de incompletude, incluindo
-- Sao Paulo (capital) mas tambem municipios pequenos e medios - a
-- hipotese inicial de "capital concentra o problema" NAO se confirmou.
-- -----------------------------------------------------------------------
WITH incompletude_por_municipio AS (
  SELECT
    id_municipio,
    COUNT(*) AS total_estabelecimentos,
    COUNTIF(id_regiao_saude IS NULL OR id_regiao_saude = 'nan' OR id_regiao_saude = '') AS total_incompletos,
    ROUND(
      COUNTIF(id_regiao_saude IS NULL OR id_regiao_saude = 'nan' OR id_regiao_saude = '') / COUNT(*) * 100
    , 2) AS percentual_incompleto
  FROM `basedosdados.br_ms_cnes.estabelecimento`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
  GROUP BY id_municipio
  HAVING total_estabelecimentos >= 20
)

SELECT
  m.nome,
  m.capital_uf,
  i.total_estabelecimentos,
  i.total_incompletos,
  i.percentual_incompleto
FROM incompletude_por_municipio AS i
JOIN `basedosdados.br_bd_diretorios_brasil.municipio` AS m
  ON i.id_municipio = m.id_municipio
ORDER BY i.percentual_incompleto DESC, i.id_municipio ASC
LIMIT 20;


-- -----------------------------------------------------------------------
-- 3. Municipios com MENOR incompletude - necessario para nao concluir
-- padrao a partir de uma unica ponta da distribuicao.
-- Resultado: extremo oposto verdadeiro - varios municipios com 0% de
-- incompletude (Osvaldo Cruz, Adamantina, Novo Horizonte, entre outros).
-- Ribeiro Preto aparece como caso de referencia favoravel (2,16%).
-- A media estadual era 54,69% na Fase 1 e foi corrigida para 54,70%
-- apos a reproducao em Python identificar 5 strings vazias adicionais.
-- A composicao dos grupos de 20 municipios com maior e menor incompletude
-- permanece a mesma, assim como a distribuicao por faixas dos 347 municipios.
-- Entretanto, houve reordenacao de posicoes no ranking municipal geral.
-- -----------------------------------------------------------------------
WITH incompletude_por_municipio AS (
  SELECT
    id_municipio,
    COUNT(*) AS total_estabelecimentos,
    COUNTIF(id_regiao_saude IS NULL OR id_regiao_saude = 'nan' OR id_regiao_saude = '') AS total_incompletos,
    ROUND(
      COUNTIF(id_regiao_saude IS NULL OR id_regiao_saude = 'nan' OR id_regiao_saude = '') / COUNT(*) * 100
    , 2) AS percentual_incompleto
  FROM `basedosdados.br_ms_cnes.estabelecimento`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
  GROUP BY id_municipio
  HAVING total_estabelecimentos >= 20
)

SELECT
  m.nome,
  i.total_estabelecimentos,
  i.total_incompletos,
  i.percentual_incompleto
FROM incompletude_por_municipio AS i
JOIN `basedosdados.br_bd_diretorios_brasil.municipio` AS m
  ON i.id_municipio = m.id_municipio
ORDER BY i.percentual_incompleto ASC, i.id_municipio ASC
LIMIT 20;


-- -----------------------------------------------------------------------
-- 4. Distribuicao completa por faixas de incompletude - construida
-- para testar a hipotese de bimodalidade sugerida pelos extremos
-- (secoes 2 e 3), em vez de aceitar essa hipotese sem verificacao.
-- Resultado: 347 municipios com volume >= 20 estabelecimentos,
-- distribuidos em TODAS as quatro faixas (100 / 67 / 111 / 69) - NAO
-- concentrados em dois grupos opostos. Hipotese de bimodalidade
-- REJEITADA pela evidencia completa; distribuicao e espalhada e
-- continua, com maior concentracao na faixa 50-75%.
-- -----------------------------------------------------------------------
WITH incompletude_por_municipio AS (
  SELECT
    id_municipio,
    COUNT(*) AS total_estabelecimentos,
    ROUND(
      COUNTIF(id_regiao_saude IS NULL OR id_regiao_saude = 'nan' OR id_regiao_saude = '') / COUNT(*) * 100
    , 2) AS percentual_incompleto
  FROM `basedosdados.br_ms_cnes.estabelecimento`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
  GROUP BY id_municipio
  HAVING total_estabelecimentos >= 20
)

SELECT
  CASE
    WHEN percentual_incompleto < 25 THEN '0-25%'
    WHEN percentual_incompleto < 50 THEN '25-50%'
    WHEN percentual_incompleto < 75 THEN '50-75%'
    ELSE '75-100%'
  END AS faixa_incompletude,
  COUNT(*) AS total_municipios
FROM incompletude_por_municipio
GROUP BY faixa_incompletude
ORDER BY faixa_incompletude;
