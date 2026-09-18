-- =====================================================================
-- FASE 1 — Indicador de completude: id_regiao_saude
-- Recorte: SP, competencia 2025-11
-- =====================================================================

-- -----------------------------------------------------------------------
-- 1. Primeira checagem (INSUFICIENTE) - so verifica NULL
-- Resultado: 0 incompletos, 0.0% -> falso negativo
-- -----------------------------------------------------------------------
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF(id_regiao_saude IS NULL) AS total_sem_regiao_saude,
  ROUND(COUNTIF(id_regiao_saude IS NULL) / COUNT(*) * 100, 2) AS percentual_incompleto
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;


-- -----------------------------------------------------------------------
-- 2. Investigacao - o campo e STRING; suspeita de nulo mascarado como texto
-- Resultado: total_com_texto_nan = 60.361 / total_null_verdadeiro = 0
-- -----------------------------------------------------------------------
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF(id_regiao_saude = 'nan') AS total_com_texto_nan,
  COUNTIF(id_regiao_saude IS NULL) AS total_null_verdadeiro,
  ROUND(COUNTIF(id_regiao_saude = 'nan') / COUNT(*) * 100, 2) AS percentual_incompleto
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;


-- -----------------------------------------------------------------------
-- 3. Fase 1 - versao com duas formas de ausencia: NULL + texto 'nan'
-- Resultado historico: 60.361 incompletos, 54.69%
-- Esta versao foi posteriormente corrigida apos a reproducao em Python,
-- que identificou 5 registros adicionais com string vazia.
-- -----------------------------------------------------------------------
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF(id_regiao_saude IS NULL OR id_regiao_saude = 'nan') AS total_incompletos,
  ROUND(
    COUNTIF(id_regiao_saude IS NULL OR id_regiao_saude = 'nan') / COUNT(*) * 100
  , 2) AS percentual_incompleto_real
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;


-- -----------------------------------------------------------------------
-- 4. Metrica corrigida e atual - tres formas de ausencia observadas
-- NULL + texto 'nan' + string vazia ''
--
-- Verificacao adicional com TRIM:
--   string vazia exata = 5
--   vazio apos TRIM    = 5
--   somente espacos    = 0
-- Portanto, nao foi identificada uma quarta forma de ausencia composta
-- apenas por espacos no recorte.
--
-- Resultado final: 60.366 incompletos, 54.70%
-- -----------------------------------------------------------------------
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF(
    id_regiao_saude IS NULL
    OR id_regiao_saude = 'nan'
    OR id_regiao_saude = ''
  ) AS total_incompletos,
  ROUND(
    COUNTIF(
      id_regiao_saude IS NULL
      OR id_regiao_saude = 'nan'
      OR id_regiao_saude = ''
    ) / COUNT(*) * 100
  , 2) AS percentual_incompleto_real
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;
