-- =====================================================================
-- PROJETO: Diagnóstico de Qualidade e Governança de Dados em
--          Estabelecimentos de Saúde (CNES/DATASUS)
-- FASE 1 — Exploração e extração
-- Fonte: Base dos Dados (basedosdados.br_ms_cnes.estabelecimento)
-- Ambiente: Google BigQuery Sandbox
-- =====================================================================


-- -----------------------------------------------------------------------
-- 1. EXPLORAÇÃO INICIAL
-- Objetivo: ver como são os dados "crus" da tabela, sem filtro nenhum,
-- para entender o formato antes de qualquer análise.
-- Custo: 0 bytes processados (SELECT * sem WHERE/agregação é leitura direta).
-- -----------------------------------------------------------------------
SELECT *
FROM `basedosdados.br_ms_cnes.estabelecimento`
LIMIT 10;


-- -----------------------------------------------------------------------
-- 2. LISTAGEM DE COLUNAS (METADADOS)
-- Objetivo: descobrir todas as colunas disponíveis na tabela, sem depender
-- de rolar a interface visual. Retornou 204 colunas.
-- Custo: 0 bytes (consulta ao catálogo de metadados, não aos dados em si).
-- -----------------------------------------------------------------------
SELECT column_name, data_type
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'estabelecimento';


-- -----------------------------------------------------------------------
-- 3. COMPETÊNCIAS DISPONÍVEIS
-- Objetivo: identificar quais competências (ano/mês) existem na base,
-- da mais recente para a mais antiga, para escolher a competência
-- de referência do projeto.
-- Resultado: 245 competências distintas, desde 2005-08. Mais recente: 2025-12.
-- -----------------------------------------------------------------------
SELECT DISTINCT ano, mes
FROM `basedosdados.br_ms_cnes.estabelecimento`
ORDER BY ano DESC, mes DESC
LIMIT 5;


-- -----------------------------------------------------------------------
-- 4. VOLUME DE ESTABELECIMENTOS POR COMPETÊNCIA (VALIDAÇÃO DA ESCOLHA)
-- Objetivo: comparar o volume de estabelecimentos entre os últimos meses
-- de 2025, para verificar se a competência mais recente (dez/2025) sofre
-- de defasagem de divulgação antes de escolher a competência de referência.
-- Resultado: novembro/2025 tem o maior volume (471.254) -> escolhido como
-- competência de referência do projeto.
-- -----------------------------------------------------------------------
SELECT ano, mes, COUNT(*) AS total_estabelecimentos
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE ano = 2025 AND mes >= 8
GROUP BY ano, mes
ORDER BY ano DESC, mes DESC;


-- -----------------------------------------------------------------------
-- 5. TOTAL DE ESTABELECIMENTOS NO RECORTE DO PROJETO
-- Objetivo: confirmar o tamanho da base de trabalho final, já aplicando
-- o recorte geográfico (SP) e temporal (nov/2025) definidos para o projeto.
-- Resultado: 110.362 estabelecimentos.
-- -----------------------------------------------------------------------
SELECT COUNT(*) AS total_estabelecimentos_sp_nov25
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11;


-- -----------------------------------------------------------------------
-- 6. AMOSTRA REAL DO RECORTE FINAL
-- Objetivo: ver linhas reais de estabelecimentos já dentro do recorte
-- definitivo do projeto (SP + nov/2025), para inspecionar visualmente
-- padrões de preenchimento e primeiros indícios de qualidade dos dados.
-- Achado: campo id_regiao_saude aparece vazio (nan) em parte das linhas
-- -> primeiro indício real de incompletude de dados no recorte do projeto.
-- -----------------------------------------------------------------------
SELECT *
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11
LIMIT 10;
