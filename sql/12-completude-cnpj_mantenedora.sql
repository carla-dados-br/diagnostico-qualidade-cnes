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
-- Decisao: tipo_grau_dependencia codifica a distincao Individual/Mantido
--            do manual tecnico do CNES, mesmo sem nome literal no campo.
--            Metrica final em duas camadas:
--              - Completude bruta (todos os estabelecimentos):
--                11,11% preenchido, 88,89% vazio
--              - Completude condicional (so entre tipo_grau_dependencia
--                = 3, os que deveriam ter CNPJ):
--                100% preenchido, 0% de ausencia real
--            O significado exato dos codigos 1/3 nao foi confirmado em
--            fonte oficial que os nomeie diretamente -- a confirmacao
--            vem da correspondencia empirica perfeita, nao de leitura
--            de documentacao.
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
