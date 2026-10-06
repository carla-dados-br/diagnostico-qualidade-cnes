-- =====================================================================
-- FASE 6 — Reproducao independente das transicoes de natureza juridica
-- Comparacao: SP, novembro/2022 x dezembro/2022
-- =====================================================================
--
-- CONTEXTO
-- As transicoes historicas foram documentadas anteriormente em
-- docs/mapeamento-cnes-fhir.md, mas a consulta original nao havia sido
-- versionada.
--
-- Este arquivo constitui uma reproducao independente realizada durante
-- a revisao corretiva da Fase 6. Ele nao deve ser apresentado como a
-- consulta SQL original da investigacao historica.
--
-- OBJETIVOS
-- 1. verificar unicidade de id_estabelecimento_cnes nas duas competencias;
-- 2. reproduzir as transicoes das coortes 2305 e 2313;
-- 3. reconciliar o total de estabelecimentos com natureza 2240;
-- 4. reproduzir os casos 4000 -> 2240.
--
-- OBSERVACAO
-- "Nao localizado em SP" significa apenas que o mesmo CNES nao foi
-- encontrado no recorte SP/dezembro-2022 utilizado nesta comparacao.
-- =====================================================================


CREATE TEMP TABLE nov AS
SELECT
  CAST(id_estabelecimento_cnes AS STRING) AS id_estabelecimento_cnes,
  TRIM(CAST(id_natureza_juridica AS STRING)) AS id_natureza_juridica
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2022
  AND mes = 11;


CREATE TEMP TABLE dez AS
SELECT
  CAST(id_estabelecimento_cnes AS STRING) AS id_estabelecimento_cnes,
  TRIM(CAST(id_natureza_juridica AS STRING)) AS id_natureza_juridica
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2022
  AND mes = 12;


-- ---------------------------------------------------------------------
-- RESULTADO 1
-- Controle de unicidade dos identificadores em cada competencia.
-- Esperado para a comparacao: nenhum CNES duplicado em cada recorte.
-- ---------------------------------------------------------------------
SELECT
  '2022-11' AS competencia,
  COUNT(*) AS registros,
  COUNT(DISTINCT id_estabelecimento_cnes) AS cnes_distintos,
  COUNT(*) - COUNT(DISTINCT id_estabelecimento_cnes) AS duplicidades
FROM nov

UNION ALL

SELECT
  '2022-12' AS competencia,
  COUNT(*) AS registros,
  COUNT(DISTINCT id_estabelecimento_cnes) AS cnes_distintos,
  COUNT(*) - COUNT(DISTINCT id_estabelecimento_cnes) AS duplicidades
FROM dez
ORDER BY competencia;


-- ---------------------------------------------------------------------
-- RESULTADO 2
-- Transicoes das coortes que estavam em 2305 ou 2313 em novembro/2022.
-- ---------------------------------------------------------------------
SELECT
  n.id_natureza_juridica AS codigo_novembro,
  COALESCE(d.id_natureza_juridica, 'NAO_LOCALIZADO_SP') AS situacao_dezembro,
  COUNT(*) AS estabelecimentos
FROM nov n
LEFT JOIN dez d
  USING (id_estabelecimento_cnes)
WHERE n.id_natureza_juridica IN ('2305', '2313')
GROUP BY
  codigo_novembro,
  situacao_dezembro
ORDER BY
  codigo_novembro,
  estabelecimentos DESC,
  situacao_dezembro;


-- ---------------------------------------------------------------------
-- RESULTADO 3
-- Tamanho original das duas coortes de novembro/2022.
-- ---------------------------------------------------------------------
SELECT
  id_natureza_juridica AS codigo_novembro,
  COUNT(*) AS estabelecimentos
FROM nov
WHERE id_natureza_juridica IN ('2305', '2313')
GROUP BY id_natureza_juridica
ORDER BY id_natureza_juridica;


-- ---------------------------------------------------------------------
-- RESULTADO 4
-- Reconciliacao completa da natureza juridica 2240.
--
-- entrada:
--   nao era 2240 em novembro (ou nao estava no recorte)
--   e e 2240 em dezembro.
--
-- saida:
--   era 2240 em novembro
--   e deixou de ser 2240 em dezembro (ou nao esta no recorte).
-- ---------------------------------------------------------------------
WITH comparacao AS (
  SELECT
    COALESCE(n.id_estabelecimento_cnes, d.id_estabelecimento_cnes)
      AS id_estabelecimento_cnes,
    n.id_natureza_juridica AS natureza_novembro,
    d.id_natureza_juridica AS natureza_dezembro
  FROM nov n
  FULL OUTER JOIN dez d
    USING (id_estabelecimento_cnes)
)
SELECT
  COUNTIF(natureza_novembro = '2240') AS total_2240_novembro,
  COUNTIF(natureza_dezembro = '2240') AS total_2240_dezembro,

  COUNTIF(
    natureza_dezembro = '2240'
    AND COALESCE(natureza_novembro, '') != '2240'
  ) AS entradas_2240,

  COUNTIF(
    natureza_novembro = '2240'
    AND COALESCE(natureza_dezembro, '') != '2240'
  ) AS saidas_2240,

  COUNTIF(natureza_dezembro = '2240')
    - COUNTIF(natureza_novembro = '2240')
    AS variacao_liquida
FROM comparacao;


-- ---------------------------------------------------------------------
-- RESULTADO 5
-- Casos 4000 -> 2240 entre novembro e dezembro de 2022.
-- O identificador CNES e exibido apenas para reproduzir os dois casos
-- ja documentados; nenhum documento fiscal e retornado nesta consulta.
-- ---------------------------------------------------------------------
SELECT
  n.id_estabelecimento_cnes,
  n.id_natureza_juridica AS natureza_novembro,
  d.id_natureza_juridica AS natureza_dezembro
FROM nov n
JOIN dez d
  USING (id_estabelecimento_cnes)
WHERE n.id_natureza_juridica = '4000'
  AND d.id_natureza_juridica = '2240'
ORDER BY n.id_estabelecimento_cnes;


-- =====================================================================
-- RESULTADOS REPRODUZIDOS — 2026-10-04
-- =====================================================================
--
-- RESULTADO 1 — unicidade
-- competencia | registros | cnes_distintos | duplicidades
-- 2022-11     | 85237     | 85237          | 0
-- 2022-12     | 85396     | 85396          | 0
--
-- RESULTADO 2 — transicoes das coortes
--
-- 2305 -> 2062               = 1470
-- 2305 -> 2305               = 499
-- 2305 -> NAO_LOCALIZADO_SP  = 18
-- 2305 -> 2054               = 1
--
-- 2313 -> 2240               = 606
-- 2313 -> 2313               = 140
-- 2313 -> NAO_LOCALIZADO_SP  = 3
-- 2313 -> 2062               = 2
--
-- RESULTADO 3 — tamanho das coortes
-- 2305 = 1988
-- 2313 = 751
--
-- Reconciliacao das coortes:
-- 1470 + 499 + 18 + 1 = 1988
-- 606 + 140 + 3 + 2 = 751
--
-- RESULTADO 4 — reconciliacao do codigo 2240
-- total_2240_novembro = 8577
-- total_2240_dezembro = 9194
-- entradas_2240       = 661
-- saidas_2240         = 44
-- variacao_liquida    = 617
--
-- Reconciliacao:
-- 661 - 44 = 617
-- 8577 + 617 = 9194
--
-- RESULTADO 5 — casos 4000 -> 2240
-- 5030714 | 4000 -> 2240
-- 9744983 | 4000 -> 2240
--
-- LIMITES
-- - esta e uma reproducao independente criada durante a revisao
--   corretiva da Fase 6; nao e apresentada como a consulta original;
-- - NAO_LOCALIZADO_SP indica apenas ausencia do mesmo CNES no recorte
--   SP/dezembro-2022 usado nesta comparacao;
-- - as transicoes observadas nao demonstram, isoladamente, sua causa
--   administrativa ou normativa;
-- - nenhuma conversao retroativa universal e inferida destes resultados.
