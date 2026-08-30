-- =====================================================================
-- FASE 3 — Regra de consistencia: habilitacao vencida ainda registrada
-- Recorte: SP, competencia 2025-11
-- Tabela: habilitacao (sem JOIN — comparacao de datas dentro da propria tabela)
-- =====================================================================

-- -----------------------------------------------------------------------
-- 1. Primeira tentativa da regra
-- Logica: habilitacao com competencia final anterior a 2025-11 (202511)
-- ainda presente na extracao de 2025-11 = inconsistencia de atualidade.
-- Resultado: 0 vencidas, 0.0% -> suspeito, investigar antes de aceitar
-- -----------------------------------------------------------------------
SELECT
  COUNT(*) AS total_habilitacoes,
  COUNTIF(
    (ano_competencia_final * 100 + mes_competencia_final) < 202511
  ) AS total_vencidas,
  ROUND(
    COUNTIF(
      (ano_competencia_final * 100 + mes_competencia_final) < 202511
    ) / COUNT(*) * 100
  , 2) AS percentual_vencidas
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;


-- -----------------------------------------------------------------------
-- 2. Investigacao - o campo tem NULL, ou algo mascara o resultado?
-- Resultado: sem_data_final = 0 / com_data_final = 6764 -> nao ha nulos.
-- Hipotese de NULL descartada.
-- -----------------------------------------------------------------------
SELECT
  COUNT(*) AS total_habilitacoes,
  COUNTIF(ano_competencia_final IS NULL) AS sem_data_final,
  COUNTIF(ano_competencia_final IS NOT NULL) AS com_data_final
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;


-- -----------------------------------------------------------------------
-- 3. Investigacao - qual o intervalo real de valores do campo?
-- Resultado: ano_final entre 2025 e 9999, mes_final entre 1 e 99.
-- 9999/99 sao valores impossiveis de calendario -> sentinela para
-- "sem prazo de validade definido / tempo indeterminado".
-- -----------------------------------------------------------------------
SELECT
  MIN(ano_competencia_final) AS ano_final_minimo,
  MAX(ano_competencia_final) AS ano_final_maximo,
  MIN(mes_competencia_final) AS mes_final_minimo,
  MAX(mes_competencia_final) AS mes_final_maximo
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;


-- -----------------------------------------------------------------------
-- 4. Regra corrigida - exclui o sentinela 9999 antes de comparar
-- Resultado: total=6764, indeterminadas=6072 (89.76%), vencidas=0
-- entre as 692 com data definida. Ainda 0 vencidas -> checar se e
-- resultado real ou se ha outro sentinela nao mapeado.
-- -----------------------------------------------------------------------
SELECT
  COUNT(*) AS total_habilitacoes,
  COUNTIF(ano_competencia_final = 9999) AS total_indeterminadas,
  COUNTIF(
    ano_competencia_final != 9999
    AND (ano_competencia_final * 100 + mes_competencia_final) < 202511
  ) AS total_vencidas,
  ROUND(
    COUNTIF(
      ano_competencia_final != 9999
      AND (ano_competencia_final * 100 + mes_competencia_final) < 202511
    ) / COUNTIF(ano_competencia_final != 9999) * 100
  , 2) AS percentual_vencidas_entre_definidas
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;


-- -----------------------------------------------------------------------
-- 5. Investigacao - qual o intervalo real, ja sem o sentinela 9999?
-- Resultado: competencia_final_minima = 202511 (a propria competencia
-- de referencia). Confirma que 0 vencidas e um resultado genuino,
-- nao um erro de calculo: a habilitacao mais proxima de vencer esta
-- vencendo agora, nao antes.
-- Achado adicional: competencia_final_maxima = 299912 (ano 2999) ->
-- possivel segundo sentinela, investigar.
-- -----------------------------------------------------------------------
SELECT
  MIN(ano_competencia_final * 100 + mes_competencia_final) AS competencia_final_minima,
  MAX(ano_competencia_final * 100 + mes_competencia_final) AS competencia_final_maxima,
  COUNT(*) AS total_com_data_definida
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11
  AND ano_competencia_final != 9999;


-- -----------------------------------------------------------------------
-- 6. Investigacao - o valor 2999/12 e um segundo sentinela sistematico
-- ou um registro isolado?
-- Resultado: 2999/12 aparece com total=1 -> outlier isolado, nao um
-- padrao sistematico. Nao ha evidencia nos dados sobre a causa (nao
-- documentar como "erro de digitacao" sem confirmacao da fonte).
-- Achado complementar: datas futuras plausiveis mas distantes (2029 a
-- 2099) aparecem com contagens relevantes -> habilitacoes com prazos de
-- validade de longo prazo (decadas), categoria distinta do sentinela.
-- -----------------------------------------------------------------------
SELECT
  ano_competencia_final,
  mes_competencia_final,
  COUNT(*) AS total
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11
  AND ano_competencia_final != 9999
GROUP BY ano_competencia_final, mes_competencia_final
ORDER BY ano_competencia_final DESC, mes_competencia_final DESC
LIMIT 15;
