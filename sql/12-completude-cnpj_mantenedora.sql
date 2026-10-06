-- =====================================================================
-- FASE 3 (continuacao) -- Indicador de completude: cnpj_mantenedora
-- Recorte: SP, competencia 2025-11
-- =====================================================================

-- -----------------------------------------------------------------------
-- 1. Valores distintos com verificacao estrutural (digitos de CNPJ)
-- Resultado: 98.098 vazios (88,89%), 12.264 com CNPJ valido de 14
--            digitos (743 mantenedoras distintas). Nenhum valor
--            malformado -- ou vazio, ou 14 digitos completos.
-- Achado: segundo o Manual Tecnico do CNES, cnpj_mantenedora so e de
--            preenchimento obrigatorio quando o estabelecimento tem
--            situacao "Mantido" -- estabelecimentos "Individuais"
--            legitimamente nao preenchem. 88,89% de vazio nao e
--            necessariamente 88,89% de incompletude real.
-- -----------------------------------------------------------------------
SELECT
    cnpj_mantenedora,
    LENGTH(CAST(cnpj_mantenedora AS STRING)) AS qtd_digitos,
    COUNT(*) AS quantidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE
    sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
GROUP BY
    cnpj_mantenedora
ORDER BY
    qtd_digitos ASC,
    quantidade DESC,
    cnpj_mantenedora;


-- -----------------------------------------------------------------------
-- 2. Busca de campo de classificacao Individual/Mantido (sem filtro de
--    nome, varredura das 204 colunas)
-- Resultado: nenhuma coluna chamada literalmente "situacao" ou
--            "individual/mantido". Candidato identificado por nome:
--            tipo_grau_dependencia.
-- -----------------------------------------------------------------------
SELECT
    column_name,
    data_type
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
WHERE
    table_name = 'estabelecimento'
ORDER BY column_name;


-- -----------------------------------------------------------------------
-- 3. Distribuicao de tipo_grau_dependencia
-- Resultado: valor 1 com 98.098, valor 3 com 12.264 -- totais identicos
--            aos de vazio/preenchido em cnpj_mantenedora.
-- -----------------------------------------------------------------------
SELECT
    tipo_grau_dependencia,
    COUNT(*) AS quantidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE
    sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
GROUP BY
    tipo_grau_dependencia
ORDER BY
    quantidade DESC;


-- -----------------------------------------------------------------------
-- 4. Tabela cruzada -- confirmacao linha a linha (nao so coincidencia
--    de totais agregados)
-- Resultado: exatamente 2 combinacoes, sem excecao -- 1+vazio (98.098)
--            e 3+preenchido (12.264).
-- Interpretacao operacional: tipo_grau_dependencia separa os dois grupos
--            observados na regra de preenchimento de cnpj_mantenedora.
--            Os rotulos dos codigos 1/3 foram verificados posteriormente
--            na tabela dicionario do conjunto (secao 5).
--            Metrica final em duas camadas:
--              - Completude bruta (todos os estabelecimentos):
--                11,11% preenchido, 88,89% vazio
--              - Completude condicional (so entre tipo_grau_dependencia
--                = 3, os que deveriam ter CNPJ):
--                100% preenchido, 0% de ausencia real
--            Esta foi a evidencia empirica original. A verificacao
--            posterior dos rotulos no dicionario do conjunto esta
--            registrada na secao 5. Essa fonte e tratada como dicionario
--            auxiliar do conjunto, nao como terminologia FHIR oficial.
-- -----------------------------------------------------------------------
SELECT
    tipo_grau_dependencia,
    CASE
        WHEN cnpj_mantenedora IS NULL OR cnpj_mantenedora = '' THEN 'vazio'
        ELSE 'preenchido'
    END AS status_cnpj,
    COUNT(*) AS quantidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE
    sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
GROUP BY
    tipo_grau_dependencia,
    status_cnpj
ORDER BY
    tipo_grau_dependencia,
    status_cnpj;


-- -----------------------------------------------------------------------
-- 5. Reconciliacao dos rotulos de tipo_grau_dependencia com a tabela
--    dicionario do conjunto.
-- Esta consulta foi incorporada posteriormente para tornar reproduzivel
-- a verificacao dos rotulos usados na interpretacao da completude
-- condicional. A tabela dicionario e tratada aqui como fonte auxiliar
-- do conjunto, nao como terminologia FHIR oficial.
-- -----------------------------------------------------------------------
SELECT
    chave,
    valor
FROM `basedosdados.br_ms_cnes.dicionario`
WHERE nome_coluna = 'tipo_grau_dependencia'
ORDER BY chave;


-- RESULTADO DA VERIFICACAO POSTERIOR — 2026-10-04
-- chave | valor
-- 1     | individual
-- 3     | mantida
--
-- Limite:
-- estes rotulos foram reproduzidos a partir da tabela
-- basedosdados.br_ms_cnes.dicionario. Esta evidencia documenta o
-- dicionario do conjunto utilizado pelo projeto e nao deve ser tratada,
-- por si so, como terminologia FHIR oficial.
