-- -----------------------------------------------------------------------
-- FASE 6 (REVISAO) -- Proveniencia dos exemplos FHIR
-- Recorte: SP, competencia 2025-11
--
-- Objetivo:
-- verificar diretamente na tabela estabelecimento se os cinco
-- id_estabelecimento_cnes utilizados nos exemplos FHIR possuem os CEPs
-- correspondentes dentro do mesmo registro do recorte analisado.
--
-- Esta consulta comprova a origem analitica dos pares CNES/CEP.
-- Ela nao define, por si so, o criterio de selecao dos cinco exemplos.
-- -----------------------------------------------------------------------

SELECT
  id_estabelecimento_cnes,
  cep,
  sigla_uf,
  ano,
  mes
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11
  AND id_estabelecimento_cnes IN (
    '0003735',
    '0004200',
    '0004642',
    '0006351',
    '0008028'
  )
ORDER BY id_estabelecimento_cnes;

-- -----------------------------------------------------------------------
-- RESULTADO DA EXECUCAO -- 2026-10-01
--
-- 5 linhas retornadas:
-- 0003735 | 07144000 | SP | 2025 | 11
-- 0004200 | 07011010 | SP | 2025 | 11
-- 0004642 | 07020081 | SP | 2025 | 11
-- 0006351 | 12400010 | SP | 2025 | 11
-- 0008028 | 06013070 | SP | 2025 | 11
--
-- Conclusao:
-- os cinco pares CNES/CEP utilizados nos exemplos FHIR foram confirmados
-- na mesma linha da tabela basedosdados.br_ms_cnes.estabelecimento para
-- o recorte SP, competencia 2025-11.
--
-- Limite da evidencia:
-- esta consulta confirma a correspondencia dos pares na fonte analitica
-- utilizada pelo projeto. Ela nao demonstra, por si so, o criterio
-- original de selecao dos cinco estabelecimentos nem substitui uma
-- verificacao de proveniencia ate os arquivos primarios do DATASUS.
-- -----------------------------------------------------------------------
