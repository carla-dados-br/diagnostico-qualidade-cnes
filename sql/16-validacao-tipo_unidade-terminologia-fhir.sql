-- =====================================================================
-- FASE 6 — Validacao terminologica de tipo_unidade
-- Recorte CNES: SP, competencia 2025-11
-- Referencia: BRTipoEstabelecimentoSaude
-- =====================================================================
--
-- OBJETIVO
-- Comparar os codigos de tipo_unidade efetivamente observados no recorte
-- do projeto com os conceitos publicados no ValueSet oficial
-- BRTipoEstabelecimentoSaude.
--
-- FONTE TERMINOLOGICA CONSULTADA
-- Ministerio da Saude — Guia de Implementacao de Terminologias do Brasil
-- ValueSet:
-- https://terminologia.saude.gov.br/fhir/ValueSet/BRTipoEstabelecimentoSaude
-- Versao publicada do ValueSet/IG consultada: 1.1.0
-- Artefato informado como ativo desde: 2026-08-22
-- CodeSystem referenciado pelo ValueSet:
-- https://terminologia.saude.gov.br/fhir/CodeSystem/BRTipoEstabelecimentoSaude
-- Total publicado nessa versao: 39 conceitos
-- Data de acesso desta verificacao: 2026-10-04
--
-- LIMITE TEMPORAL
-- O artefato terminologico consultado esta informado como ativo desde
-- 2026-08-22, enquanto o recorte analisado representa 2025-11. Ausencia de um codigo nessa versao
-- publicada nao prova que ele nunca tenha possuido significado oficial
-- no periodo historico do snapshot.
--
-- Esta consulta testa COBERTURA DE CODIGO. Nao deve ser confundida com
-- a metrica de completude de sql/07-completude-tipo_unidade.sql.
-- =====================================================================

CREATE TEMP TABLE terminologia_fhir AS
SELECT codigo
FROM UNNEST([
  '67','64','85','84','62','61','83','60','82','50',
  '81','5','80','43','79','42','78','40','77','76',
  '4','75','39','74','36','73','32','72','22','71',
  '21','70','20','7','2','69','15','68','1'
]) AS codigo;


CREATE TEMP TABLE observado AS
SELECT
  TRIM(CAST(tipo_unidade AS STRING)) AS codigo,
  COUNT(*) AS total_estabelecimentos
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11
GROUP BY codigo;


-- ---------------------------------------------------------------------
-- RESULTADO 1
-- Resumo de cobertura terminologica.
-- ---------------------------------------------------------------------
SELECT
  (SELECT COUNT(*) FROM observado) AS codigos_observados,
  (SELECT COUNT(*) FROM terminologia_fhir) AS conceitos_valueset_1_1_0,
  COUNTIF(t.codigo IS NOT NULL) AS observados_presentes_no_valueset,
  COUNTIF(t.codigo IS NULL) AS observados_ausentes_no_valueset
FROM observado o
LEFT JOIN terminologia_fhir t
  ON o.codigo = t.codigo;


-- ---------------------------------------------------------------------
-- RESULTADO 2
-- Codigos observados no CNES que nao aparecem no ValueSet consultado.
-- Nenhum significado deve ser inferido automaticamente para eles.
-- ---------------------------------------------------------------------
SELECT
  o.codigo,
  o.total_estabelecimentos
FROM observado o
LEFT JOIN terminologia_fhir t
  ON o.codigo = t.codigo
WHERE t.codigo IS NULL
ORDER BY SAFE_CAST(o.codigo AS INT64), o.codigo;


-- ---------------------------------------------------------------------
-- RESULTADO 3
-- Conceitos do ValueSet que nao aparecem no recorte SP/2025-11.
-- Ausencia no recorte nao significa invalidade do conceito.
-- ---------------------------------------------------------------------
SELECT
  t.codigo
FROM terminologia_fhir t
LEFT JOIN observado o
  ON t.codigo = o.codigo
WHERE o.codigo IS NULL
ORDER BY SAFE_CAST(t.codigo AS INT64), t.codigo;


-- =====================================================================
-- RESULTADO DA EXECUCAO — 2026-10-04
-- =====================================================================
--
-- RESULTADO 1 — resumo de cobertura
--
-- codigos_observados:                 38
-- conceitos_valueset_1_1_0:          39
-- observados_presentes_no_valueset:   37
-- observados_ausentes_no_valueset:     1
--
-- RESULTADO 2 — codigo observado ausente do ValueSet consultado
--
-- codigo | total_estabelecimentos
-- 16     | 5
--
-- RESULTADO 3 — conceitos do ValueSet nao observados no recorte
--
-- 32
-- 64
--
-- CONCLUSAO
-- Dos 38 codigos distintos de tipo_unidade observados no recorte
-- SP/2025-11, 37 aparecem no ValueSet BRTipoEstabelecimentoSaude
-- consultado e apenas o codigo 16 nao aparece.
--
-- O codigo 16 ocorre em 5 estabelecimentos no recorte.
--
-- Os codigos 32 e 64 pertencem ao ValueSet consultado, mas nao foram
-- observados no recorte SP/2025-11. Essa ausencia no recorte nao implica
-- invalidade desses conceitos.
--
-- LIMITE
-- A ausencia do codigo 16 na versao terminologica consultada nao prova
-- que ele nunca tenha possuido significado oficial no periodo historico
-- de 2025-11. O resultado sustenta apenas que seu significado e sua
-- codificacao terminologica nao foram comprovados para uso FHIR nesta
-- versao do projeto.
-- =====================================================================
