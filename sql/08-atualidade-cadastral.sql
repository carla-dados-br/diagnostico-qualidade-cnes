-- =====================================================================
-- FASE 3 — Indicador de atualidade cadastral
-- Recorte: SP, competencia 2025-11
-- Campos: ano_atualizacao, mes_atualizacao (tabela estabelecimento)
-- =====================================================================

-- -----------------------------------------------------------------------
-- 1. Distribuicao de atualizacao por ano/mes (mais recentes primeiro)
-- Objetivo: identificar o periodo mais recente disponivel e observar o
-- comportamento real da base antes de definir qualquer corte de
-- "atualizado" (nao decidir arbitrariamente antes de olhar os dados).
-- Achado inesperado: existem estabelecimentos com ano_atualizacao/
-- mes_atualizacao = 2025-12, POSTERIOR a propria competencia do arquivo
-- (2025-11). Investigado na secao 3.
-- -----------------------------------------------------------------------
SELECT
  ano_atualizacao,
  mes_atualizacao,
  COUNT(*) AS total_estabelecimentos
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11
GROUP BY ano_atualizacao, mes_atualizacao
ORDER BY ano_atualizacao DESC, mes_atualizacao DESC;


-- -----------------------------------------------------------------------
-- 2. Checagem de ausencia e intervalo do campo
-- Resultado: 0 nulos em ano_atualizacao e mes_atualizacao. Intervalo de
-- 2015 a 2025 - sem sentinela aparente (nao ha 9999 nem 0 como valor
-- extremo, diferente do que foi encontrado em habilitacao).
-- -----------------------------------------------------------------------
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF(ano_atualizacao IS NULL) AS sem_ano_atualizacao,
  COUNTIF(mes_atualizacao IS NULL) AS sem_mes_atualizacao,
  MIN(ano_atualizacao) AS ano_minimo,
  MAX(ano_atualizacao) AS ano_maximo
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;


-- -----------------------------------------------------------------------
-- 3. Investigacao do achado da secao 1: quantos estabelecimentos tem
-- atualizacao posterior a propria competencia do arquivo (2025-11)?
-- Resultado: 2.971 estabelecimentos (2,7%) com atualizacao posterior;
-- 6.082 (5,5%) na propria competencia; 101.309 (91,8%) antes dela.
-- Padrao real e nao desprezivel, mas nao a maioria. Hipotese plausivel
-- (nao confirmada pelos dados): defasagem no processo de publicacao/
-- consolidacao do arquivo pela fonte, similar a defasagem ja registrada
-- em docs/decisao-recorte.md. Documentado como observacao, nao como
-- causa confirmada.
-- -----------------------------------------------------------------------
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF((ano_atualizacao * 100 + mes_atualizacao) > 202511) AS atualizados_apos_competencia,
  COUNTIF((ano_atualizacao * 100 + mes_atualizacao) = 202511) AS atualizados_na_competencia,
  COUNTIF((ano_atualizacao * 100 + mes_atualizacao) < 202511) AS atualizados_antes_competencia
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;


-- -----------------------------------------------------------------------
-- 4. Distribuicao agregada por ano - visao panoramica para decidir o
-- corte de atualidade com base em evidencia, nao em numero arbitrario.
-- Resultado: 2025+2024 somam 78,54% do cadastro. Sem "penhasco" abrupto
-- ano a ano (2023 e 2022 tem percentuais proximos), mas a partir de
-- 2019 para tras o volume ja e residual (< 0,15% somado).
-- -----------------------------------------------------------------------
SELECT
  ano_atualizacao,
  COUNT(*) AS total_estabelecimentos,
  ROUND(COUNT(*) / 110362 * 100, 2) AS percentual
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11
GROUP BY ano_atualizacao
ORDER BY ano_atualizacao DESC;


-- =====================================================================
-- DECISAO METODOLOGICA - REGRA DE ATUALIDADE
--
-- Data de referencia: 2025-11 (competencia do proprio snapshot
-- analisado, NAO a data de execucao da query). Essa escolha torna o
-- indicador uma caracteristica do snapshot, reproduzivel por qualquer
-- pessoa que rode a mesma query sobre o mesmo arquivo, independente de
-- quando a analise for executada.
--
-- Janela de atualidade: 24 meses anteriores a competencia de
-- referencia. Limite calculado: 2025-11 menos 24 meses = 2023-11
-- (codigo comparavel: 202311, incluido como ainda "atualizado").
--
-- Justificativa: 24 meses e uma convencao metodologica deste projeto,
-- adotada por representar um intervalo operacional razoavel para
-- avaliar atualidade de um cadastro nacional de estabelecimentos de
-- saude, evitando classificar como desatualizados registros ainda
-- dentro de um ciclo bienal de manutencao. NAO e uma definicao
-- normativa do DATASUS sobre prazo de validade cadastral - nenhuma
-- fonte oficial desse tipo foi verificada.
--
-- Categorias: "atualizado" (>= 2023-11), "desatualizado" (< 2023-11),
-- "nao informado" (ano/mes de atualizacao ausente) - tratada em
-- separado, nao somada aos desatualizados.
-- =====================================================================


-- -----------------------------------------------------------------------
-- 5. Indicador final de atualidade cadastral
-- Resultado: 87.494 atualizados (79,28%), 22.868 desatualizados
-- (20,72%), 0 nao informado.
-- -----------------------------------------------------------------------
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF(
    ano_atualizacao IS NOT NULL AND mes_atualizacao IS NOT NULL
    AND (ano_atualizacao * 100 + mes_atualizacao) >= 202311
  ) AS atualizados,
  COUNTIF(
    ano_atualizacao IS NOT NULL AND mes_atualizacao IS NOT NULL
    AND (ano_atualizacao * 100 + mes_atualizacao) < 202311
  ) AS desatualizados,
  COUNTIF(
    ano_atualizacao IS NULL OR mes_atualizacao IS NULL
  ) AS nao_informado,
  ROUND(
    COUNTIF(
      ano_atualizacao IS NOT NULL AND mes_atualizacao IS NOT NULL
      AND (ano_atualizacao * 100 + mes_atualizacao) < 202311
    ) / COUNT(*) * 100
  , 2) AS percentual_desatualizado
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;
