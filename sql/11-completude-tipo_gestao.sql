-- =====================================================================
-- FASE 3 (continuacao) -- Indicador de completude: tipo_gestao
-- Recorte: SP, competencia 2025-11
-- =====================================================================

-- -----------------------------------------------------------------------
-- 1. Distribuicao de valores distintos
-- Resultado: M (municipal) com 109.733, E (estadual) com 629.
--            Soma = 110.362, o total exato do recorte -> 0% de ausencia.
-- Decisao: campo 100% preenchido no recorte, com somente M e E
--            observados. A verificacao posterior na tabela dicionario
--            do conjunto registrou um dominio maior: D, E, M, S e Z.
--            Dominio observado no recorte nao deve ser confundido com
--            dominio registrado no dicionario. Ver secao 2.
-- -----------------------------------------------------------------------
SELECT
    tipo_gestao,
    COUNT(*) AS quantidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE
    sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
GROUP BY
    tipo_gestao
ORDER BY
    quantidade DESC;


-- -----------------------------------------------------------------------
-- 2. Reconciliacao do dominio com a tabela dicionario do conjunto.
--
-- Esta consulta foi incorporada posteriormente, durante a revisao
-- corretiva da Fase 6, para tornar reproduzivel a verificacao do dominio
-- categórico de tipo_gestao.
--
-- A tabela basedosdados.br_ms_cnes.dicionario e tratada aqui como
-- dicionario auxiliar do conjunto utilizado pelo projeto. Sua utilizacao
-- nao transforma, por si so, os valores em terminologia FHIR oficial.
-- -----------------------------------------------------------------------
SELECT
    chave,
    valor
FROM `basedosdados.br_ms_cnes.dicionario`
WHERE nome_coluna = 'tipo_gestao'
ORDER BY chave;


-- RESULTADO DA RECONCILIACAO DO DOMINIO — 2026-10-04
-- chave | valor
-- D     | dupla
-- E     | estadual
-- M     | municipal
-- S     | sem gestao
-- Z     | nao informado
--
-- Interpretacao:
-- - no recorte SP/2025-11 foram observados somente M e E;
-- - D, E, M, S e Z sao os valores registrados na tabela dicionario
--   consultada para tipo_gestao;
-- - Z representa "nao informado" no dicionario, mas nao foi observado
--   no recorte SP/2025-11;
-- - a tabela dicionario e tratada como fonte auxiliar do conjunto e nao,
--   por si so, como terminologia FHIR oficial.
