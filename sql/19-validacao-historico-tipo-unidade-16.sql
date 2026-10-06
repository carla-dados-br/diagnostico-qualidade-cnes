-- =====================================================================
-- FASE 6 — Reproducao independente do historico de tipo_unidade = 16
-- Janela investigada: 2024-01 a 2026-02
-- =====================================================================
--
-- CONTEXTO
-- A investigacao temporal e nacional do codigo 16 foi documentada
-- anteriormente em docs/investigacao-proveniencia-tipo-unidade-16.md,
-- mas a consulta SQL original nao havia sido versionada.
--
-- Este arquivo constitui uma reproducao independente criada durante
-- a revisao corretiva da Fase 6. Nao deve ser apresentado como a
-- consulta original da investigacao historica.
--
-- OBJETIVOS
-- 1. reproduzir os cinco CNES de SP/2025-11 com tipo_unidade = 16;
-- 2. identificar a primeira ocorrencia de 16 em cada um desses CNES
--    e o ultimo tipo observado anteriormente na janela pesquisada;
-- 3. verificar a sequencia temporal do CNES 5767032;
-- 4. localizar a primeira ocorrencia nacional de tipo_unidade = 16
--    dentro da janela iniciada em janeiro de 2024;
-- 5. reproduzir a evolucao mensal nacional de estabelecimentos e UFs.
--
-- LIMITES
-- - "primeira ocorrencia" significa primeira ocorrencia dentro da
--   janela 2024-01 a 2026-02;
-- - os resultados temporais nao determinam o significado do codigo 16;
-- - crescimento ou distribuicao geografica nao constituem validacao
--   terminologica FHIR.
-- =====================================================================


CREATE TEMP TABLE historico AS
SELECT
  CAST(id_estabelecimento_cnes AS STRING) AS id_estabelecimento_cnes,
  DATE(ano, mes, 1) AS competencia,
  sigla_uf,
  NULLIF(TRIM(CAST(tipo_unidade AS STRING)), '') AS tipo_unidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE ano BETWEEN 2024 AND 2026
  AND NOT (ano = 2026 AND mes > 2);


-- ---------------------------------------------------------------------
-- RESULTADO 1
-- Cinco estabelecimentos de SP em novembro/2025 com tipo_unidade = 16.
-- ---------------------------------------------------------------------
SELECT
  id_estabelecimento_cnes,
  tipo_unidade
FROM historico
WHERE competencia = DATE '2025-11-01'
  AND sigla_uf = 'SP'
  AND tipo_unidade = '16'
ORDER BY id_estabelecimento_cnes;


-- ---------------------------------------------------------------------
-- RESULTADO 2
-- Primeira entrada em tipo_unidade = 16 para os cinco CNES e ultimo
-- tipo observado anteriormente dentro da janela pesquisada.
-- ---------------------------------------------------------------------
WITH cinco AS (
  SELECT id_estabelecimento_cnes
  FROM UNNEST([
    '4932609',
    '5767032',
    '5828953',
    '9340459',
    '9570365'
  ]) AS id_estabelecimento_cnes
),

primeiro_16 AS (
  SELECT
    h.id_estabelecimento_cnes,
    MIN(h.competencia) AS primeira_competencia_16
  FROM historico h
  JOIN cinco c
    USING (id_estabelecimento_cnes)
  WHERE h.tipo_unidade = '16'
  GROUP BY h.id_estabelecimento_cnes
),

anterior AS (
  SELECT
    h.id_estabelecimento_cnes,
    h.competencia AS competencia_anterior,
    h.tipo_unidade AS tipo_anterior
  FROM historico h
  JOIN primeiro_16 p
    USING (id_estabelecimento_cnes)
  WHERE h.competencia < p.primeira_competencia_16
    AND h.tipo_unidade IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY h.id_estabelecimento_cnes
    ORDER BY h.competencia DESC
  ) = 1
)

SELECT
  p.id_estabelecimento_cnes,
  a.tipo_anterior,
  a.competencia_anterior,
  p.primeira_competencia_16
FROM primeiro_16 p
LEFT JOIN anterior a
  USING (id_estabelecimento_cnes)
ORDER BY p.id_estabelecimento_cnes;


-- ---------------------------------------------------------------------
-- RESULTADO 3
-- Mudancas de tipo_unidade observadas para o CNES 5767032.
-- Permite verificar, entre outras transicoes, a sequencia 36 -> 16 -> 36.
-- ---------------------------------------------------------------------
WITH serie AS (
  SELECT
    id_estabelecimento_cnes,
    competencia,
    tipo_unidade,
    LAG(tipo_unidade) OVER (
      PARTITION BY id_estabelecimento_cnes
      ORDER BY competencia
    ) AS tipo_anterior
  FROM historico
  WHERE id_estabelecimento_cnes = '5767032'
),

mudancas AS (
  SELECT *
  FROM serie
  WHERE tipo_unidade IS NOT NULL
    AND (
      tipo_anterior IS NULL
      OR tipo_unidade != tipo_anterior
    )
)

SELECT
  id_estabelecimento_cnes,
  competencia,
  tipo_anterior,
  tipo_unidade AS novo_tipo
FROM mudancas
ORDER BY competencia;


-- ---------------------------------------------------------------------
-- RESULTADO 4
-- Primeira competencia nacional com tipo_unidade = 16 dentro da janela.
-- ---------------------------------------------------------------------
SELECT
  MIN(competencia) AS primeira_competencia_com_codigo_16
FROM historico
WHERE tipo_unidade = '16';


-- ---------------------------------------------------------------------
-- RESULTADO 5
-- Evolucao nacional das ocorrencias de tipo_unidade = 16.
-- A contagem de estabelecimentos utiliza CNES distintos.
-- ---------------------------------------------------------------------
SELECT
  competencia,
  COUNT(DISTINCT id_estabelecimento_cnes) AS estabelecimentos,
  COUNT(DISTINCT sigla_uf) AS ufs
FROM historico
WHERE tipo_unidade = '16'
GROUP BY competencia
ORDER BY competencia;


-- =====================================================================
-- RESULTADOS REPRODUZIDOS — 2026-10-04
-- =====================================================================
--
-- RESULTADO 1 — SP/2025-11, tipo_unidade = 16
-- 4932609 | 16
-- 5767032 | 16
-- 5828953 | 16
-- 9340459 | 16
-- 9570365 | 16
--
-- RESULTADO 2 — primeira ocorrencia de 16 nos cinco CNES
-- CNES    | tipo anterior | competencia anterior | primeira competencia 16
-- 4932609 | 22            | 2025-10              | 2025-11
-- 5767032 | 36            | 2025-10              | 2025-11
-- 5828953 | 4             | 2025-09              | 2025-10
-- 9340459 | 22            | 2025-08              | 2025-09
-- 9570365 | 2             | 2025-08              | 2025-09
--
-- RESULTADO 3 — mudancas do CNES 5767032
-- 2025-07 | NULL -> 36
-- 2025-11 | 36   -> 16
-- 2026-02 | 16   -> 36
--
-- A sequencia observada dentro da janela pesquisada e:
-- 36 -> 16 -> 36
--
-- RESULTADO 4 — primeira competencia nacional com codigo 16
-- dentro da janela iniciada em 2024-01:
-- 2025-09
--
-- RESULTADO 5 — evolucao nacional
-- competencia | estabelecimentos | UFs
-- 2025-09     | 10               | 7
-- 2025-10     | 21               | 9
-- 2025-11     | 43               | 15
-- 2025-12     | 54               | 15
-- 2026-01     | 59               | 16
-- 2026-02     | 86               | 18
--
-- LIMITES
-- - os resultados se referem a primeira ocorrencia dentro da janela
--   2024-01 a 2026-02, e nao a toda a historia do CNES;
-- - a presenca e a expansao do codigo 16 nao determinam seu significado;
-- - a sequencia temporal nao demonstra a causa administrativa da mudanca;
-- - esta evidencia historica nao substitui validacao terminologica FHIR.
