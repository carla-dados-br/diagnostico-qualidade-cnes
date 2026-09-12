-- =====================================================================
-- FASE 3 (continuacao) -- Indicador de unicidade: id_estabelecimento_cnes
-- Recorte: SP, competencia 2025-11
-- =====================================================================

-- -----------------------------------------------------------------------
-- 1. Duplicidade de id_estabelecimento_cnes dentro do recorte
-- Nota sobre a chave: a chave de relacionamento do projeto e
--            id_estabelecimento_cnes + ano + mes (Fase 1), necessaria
--            porque a mesma tabela contem varias competencias. Como o
--            recorte ja fixa ano = 2025 e mes = 11 no WHERE, essas duas
--            partes da chave ja sao constantes dentro desta consulta --
--            a duplicidade testada e so sobre id_estabelecimento_cnes
--            isolado.
-- Resultado: 0 linhas. Nenhum id_estabelecimento_cnes se repete no
--            recorte.
-- Decisao: unicidade confirmada -- id_estabelecimento_cnes funciona
--            como chave unica de fato dentro de SP/nov-2025, sem
--            excecao, em 110.362 registros. Ultima das quatro dimensoes
--            de qualidade fixas do projeto (completude, consistencia,
--            atualidade, unicidade) fechada.
-- -----------------------------------------------------------------------
SELECT
    id_estabelecimento_cnes,
    COUNT(*) AS quantidade
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE
    sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
GROUP BY
    id_estabelecimento_cnes
HAVING
    COUNT(*) > 1
ORDER BY
    quantidade DESC;
