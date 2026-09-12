-- =====================================================================
-- FASE 3 (continuacao) -- Indicador de completude: tipo_gestao
-- Recorte: SP, competencia 2025-11
-- =====================================================================

-- -----------------------------------------------------------------------
-- 1. Distribuicao de valores distintos
-- Resultado: M (municipal) com 109.733, E (estadual) com 629.
--            Soma = 110.362, o total exato do recorte -> 0% de ausencia.
-- Decisao: campo 100% completo. Dominio esperado por conhecimento previo
--            (nao verificado em fonte oficial nesta sessao) inclui
--            tambem D (dupla gestao) e S (sem gestao), que nao ocorrem
--            neste recorte -- dominio teorico maior que o dominio
--            observado, sem indicar ausencia de dado.
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
