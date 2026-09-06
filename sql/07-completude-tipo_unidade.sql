-- =====================================================================
-- FASE 3 — Indicador de completude: tipo_unidade
-- Recorte: SP, competencia 2025-11
-- =====================================================================

-- -----------------------------------------------------------------------
-- 1. Valores distintos do campo no recorte, ANTES de calcular qualquer
-- metrica - habito de investigacao adotado apos o achado de nulo
-- mascarado em id_regiao_saude (ver sql/03).
-- Resultado: 38 valores distintos, todos codigos numericos validos,
-- nenhum "nan", vazio ou fora do padrao observado.
-- -----------------------------------------------------------------------
SELECT DISTINCT tipo_unidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11
ORDER BY tipo_unidade;


-- -----------------------------------------------------------------------
-- 2. Traducao dos codigos via dicionario oficial
-- Resultado: 44 codigos catalogados nacionalmente (posto de saude,
-- hospital geral, farmacia, central de regulacao, etc.), dos quais 38
-- tem uso no recorte SP/nov-2025.
-- -----------------------------------------------------------------------
SELECT
  chave,
  valor
FROM `basedosdados.br_ms_cnes.dicionario`
WHERE nome_coluna = 'tipo_unidade'
ORDER BY chave;


-- -----------------------------------------------------------------------
-- 3. Metrica de completude - testa tres formas de ausencia ao mesmo
-- tempo (nulo real, texto "nan", string vazia), mesmo padrao de
-- verificacao usado em id_regiao_saude.
-- Resultado: 0 em todas as tres formas de ausencia, 110.362 de 110.362
-- estabelecimentos com valor valido. Campo genuinamente 100% completo
-- neste recorte - resultado confirmado por investigacao previa (secao 1),
-- nao aceito por ausencia de checagem.
-- -----------------------------------------------------------------------
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF(tipo_unidade IS NULL) AS total_nulo,
  COUNTIF(tipo_unidade = 'nan') AS total_texto_nan,
  COUNTIF(tipo_unidade = '') AS total_string_vazia,
  ROUND(
    COUNTIF(tipo_unidade IS NULL OR tipo_unidade = 'nan' OR tipo_unidade = '') / COUNT(*) * 100
  , 2) AS percentual_incompleto
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;
