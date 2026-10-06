-- =====================================================================
-- FASE 6 — Relacao entre CNPJ da mantenedora, documento proprio
--          e natureza juridica
-- Recorte: SP, competencia 2025-11
-- =====================================================================
--
-- OBJETIVO
-- Reproduzir de forma agregada os resultados usados na decisao FHIR
-- sobre cnpj_mantenedora, sem expor valores individuais de documentos.
--
-- CAMPOS
-- cnpj_mantenedora      -> documento da entidade mantenedora
-- cpf_cnpj              -> documento proprio associado ao estabelecimento
-- id_natureza_juridica  -> natureza juridica registrada
--
-- PRIVACIDADE
-- Nenhuma consulta abaixo retorna cpf_cnpj ou cnpj_mantenedora em nivel
-- individual. Somente contagens agregadas sao produzidas.
-- =====================================================================

CREATE TEMP TABLE base AS
SELECT
  TRIM(CAST(cnpj_mantenedora AS STRING)) AS cnpj_mantenedora,
  NULLIF(TRIM(CAST(cpf_cnpj AS STRING)), '') AS documento_proprio,
  TRIM(CAST(id_natureza_juridica AS STRING)) AS id_natureza_juridica
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;


-- ---------------------------------------------------------------------
-- RESULTADO 1
-- Relacao entre cnpj_mantenedora e documento proprio.
-- ---------------------------------------------------------------------
SELECT
  COUNTIF(cnpj_mantenedora IS NOT NULL AND cnpj_mantenedora != '')
    AS mantenedora_preenchida,

  COUNTIF(
    cnpj_mantenedora IS NOT NULL
    AND cnpj_mantenedora != ''
    AND documento_proprio IS NULL
  ) AS documento_proprio_ausente,

  COUNTIF(
    cnpj_mantenedora IS NOT NULL
    AND cnpj_mantenedora != ''
    AND documento_proprio IS NOT NULL
    AND documento_proprio != cnpj_mantenedora
  ) AS documento_proprio_preenchido_diferente,

  COUNTIF(
    cnpj_mantenedora IS NOT NULL
    AND cnpj_mantenedora != ''
    AND documento_proprio IS NOT NULL
    AND documento_proprio = cnpj_mantenedora
  ) AS documento_proprio_identico
FROM base;


-- ---------------------------------------------------------------------
-- RESULTADO 2
-- Natureza juridica 1244 entre registros com mantenedora preenchida
-- e documento proprio ausente.
-- ---------------------------------------------------------------------
SELECT
  COUNT(*) AS natureza_1244_documento_ausente_mantenedora_preenchida
FROM base
WHERE cnpj_mantenedora IS NOT NULL
  AND cnpj_mantenedora != ''
  AND documento_proprio IS NULL
  AND id_natureza_juridica = '1244';


-- =====================================================================
-- RESULTADOS REPRODUZIDOS — 2026-10-04
-- =====================================================================
--
-- RESULTADO 1
-- mantenedora_preenchida                         = 12264
-- documento_proprio_ausente                     = 11803
-- documento_proprio_preenchido_diferente        = 461
-- documento_proprio_identico                     = 0
--
-- Reconciliacao:
-- 11803 + 461 + 0 = 12264
--
-- RESULTADO 2
-- natureza_1244_documento_ausente_mantenedora_preenchida = 10161
--
-- Limites da evidencia:
-- - os resultados se referem a SP, competencia 2025-11;
-- - nenhuma consulta deste arquivo publica documentos individuais;
-- - a existencia de cnpj_mantenedora nao autoriza utiliza-lo como
--   documento proprio do estabelecimento;
-- - os resultados quantitativos nao determinam, isoladamente, a
--   modelagem de uma entidade mantenedora em FHIR.
