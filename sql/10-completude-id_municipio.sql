-- =====================================================================
-- FASE 3 (continuacao) -- Indicador de completude: id_municipio
-- Recorte: SP, competencia 2025-11
-- =====================================================================

-- -----------------------------------------------------------------------
-- 1. Valores distintos com verificacao estrutural (digitos + prefixo IBGE)
-- Resultado: 644 valores distintos, todos com 7 digitos, todos iniciando
--            em "35" (prefixo IBGE de SP). Nenhum nulo, vazio ou malformado.
-- -----------------------------------------------------------------------
SELECT
    id_municipio,
    LENGTH(CAST(id_municipio AS STRING)) AS qtd_digitos,
    COUNT(*) AS quantidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE
    sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
GROUP BY
    id_municipio
ORDER BY
    qtd_digitos ASC,
    quantidade DESC,
    id_municipio;


-- -----------------------------------------------------------------------
-- 2. Verificacao cruzada, mesmo recorte, metodo diferente (COUNT DISTINCT)
-- Resultado: 644 municipios distintos, 0 nulo, 0 "nan", 0 string vazia --
--            confirma exatamente a query 1.
-- Nota metodologica: uma primeira contagem via wc -l no CSV exportado da
--            query 1 indicou 643 em vez de 644 -- erro de contagem por
--            ausencia de quebra de linha final no arquivo, nao um
--            problema no dado. Corrigido comparando com esta query antes
--            de aceitar qualquer conclusao.
-- Decisao: campo 100% completo. SP tem 645 municipios oficiais (IBGE);
--            o recorte cobre 644 -- 1 municipio sem estabelecimento
--            cadastrado nesta competencia, registrado como pendencia de
--            investigacao (Fase 5), nao como problema de completude.
-- -----------------------------------------------------------------------
SELECT
  COUNT(*) AS total_estabelecimentos,
  COUNTIF(id_municipio IS NULL) AS nulo,
  COUNTIF(id_municipio = 'nan') AS texto_nan,
  COUNTIF(id_municipio = '') AS string_vazia,
  COUNT(DISTINCT id_municipio) AS total_municipios_distintos
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11;
