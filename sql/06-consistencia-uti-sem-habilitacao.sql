-- =====================================================================
-- FASE 3 — Regra de consistencia: leito de UTI sem habilitacao
-- correspondente
-- Recorte: SP, competencia 2025-11
-- Tabelas: leito + habilitacao (LEFT JOIN + de-para semantico)
-- =====================================================================

-- -----------------------------------------------------------------------
-- 1. Estrutura da tabela habilitacao
-- Objetivo: encontrar o campo que identifica o TIPO de habilitacao
-- (ate aqui so haviamos usado quantidade_leitos e as datas).
-- Resultado: campo tipo_habilitacao (STRING), 16 colunas ao todo.
-- -----------------------------------------------------------------------
SELECT
  column_name,
  data_type
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'habilitacao'
ORDER BY ordinal_position;


-- -----------------------------------------------------------------------
-- 2. Valores distintos de tipo_habilitacao no recorte do projeto
-- Objetivo: confirmar o formato do campo (codigo numerico, como
-- tipo_especialidade_leito ja era).
-- -----------------------------------------------------------------------
SELECT DISTINCT tipo_habilitacao
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11
ORDER BY tipo_habilitacao
LIMIT 30;


-- -----------------------------------------------------------------------
-- 3. Traducao completa de tipo_habilitacao via dicionario
-- Resultado: 402 codigos distintos no total (exportado via CSV para
-- conferencia completa, sem perda por paginacao da interface).
-- -----------------------------------------------------------------------
SELECT
  chave,
  valor
FROM `basedosdados.br_ms_cnes.dicionario`
WHERE nome_coluna = 'tipo_habilitacao'
ORDER BY chave;


-- -----------------------------------------------------------------------
-- 4. Filtro dos codigos de habilitacao relacionados a UTI
-- Cuidado: o filtro por texto pegou falsos positivos ("terapeutica" em
-- comunidade terapeutica, residencia terapeutica) - revisados e
-- descartados manualmente.
-- Resultado: 19 codigos de habilitacao relacionados a UTI.
-- -----------------------------------------------------------------------
SELECT
  chave,
  valor
FROM `basedosdados.br_ms_cnes.dicionario`
WHERE nome_coluna = 'tipo_habilitacao'
  AND (
    LOWER(valor) LIKE '%terapia intensiva%'
    OR LOWER(valor) LIKE '%uti%'
  )
ORDER BY chave;


-- -----------------------------------------------------------------------
-- 5. Codigos de leito UTI (tipo_especialidade_leito), ja documentados
-- na verificacao de estrutura - reconfirmados aqui para montar o de-para.
-- -----------------------------------------------------------------------
SELECT
  chave,
  valor
FROM `basedosdados.br_ms_cnes.dicionario`
WHERE nome_coluna = 'tipo_especialidade_leito'
  AND chave IN ('74','75','76','77','78','79','80','81','82','83','85','86')
ORDER BY chave;


-- =====================================================================
-- DE-PARA SEMANTICO (leito x habilitacao) - nao numerico, os dois
-- campos pertencem a dominios de codigo diferentes.
--
-- 12 pares diretos confirmados por igualdade semantica e mesma
-- granularidade (tipo I/II/III preservado nos dois lados):
--   leito 74 -> habilitacao 2696  (uti adulto tipo I)
--   leito 75 -> habilitacao 2601  (uti adulto tipo II)
--   leito 76 -> habilitacao 2604  (uti adulto tipo III)
--   leito 77 -> habilitacao 2698  (uti pediatrica tipo I)
--   leito 78 -> habilitacao 2603  (uti pediatrica tipo II)
--   leito 79 -> habilitacao 2606  (uti pediatrica tipo III)
--   leito 80 -> habilitacao 2697  (uti neonatal tipo I)
--   leito 83 -> habilitacao 2607  (uti de queimados)
--   leito 85 -> habilitacao 2608  (uti coronariana tipo II)
--   leito 86 -> habilitacao 2609  (uti coronariana tipo III)
--
-- 2 pares com sinonimo confirmado empiricamente (ver secoes 6 e 7):
--   leito 81 -> habilitacao 2602 OU 2610 (uti neonatal tipo II)
--   leito 82 -> habilitacao 2605 OU 2611 (uti neonatal tipo III)
--
-- Codigos de habilitacao sem uso no recorte SP/nov-2025 (nao decisao
-- editorial de exclusao - simplesmente nao ocorrem nos dados):
--   2612, 2613 (variantes SRAG/COVID-19), 2699 (uti I generico sem
--   especificar publico), 8217 (rede cegonha), 8218 (rede urgencia/
--   emergencia)
-- =====================================================================


-- -----------------------------------------------------------------------
-- 6. Investigacao empirica do codigo 2610 (suspeita de sinonimo de 2602)
-- Pergunta: os estabelecimentos com habilitacao 2610 tambem tem leito
-- codigo 81 (uti neonatal tipo II) cadastrado?
-- Resultado: 98 estabelecimentos com habilitacao 2610; 96 deles (~98%)
-- tem leito codigo 81 correspondente -> evidencia forte de sinonimo,
-- nao duplicidade nem erro.
-- -----------------------------------------------------------------------
WITH estabelecimentos_2610 AS (
  SELECT DISTINCT id_estabelecimento_cnes
  FROM `basedosdados.br_ms_cnes.habilitacao`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
    AND tipo_habilitacao = '2610'
)

SELECT
  l.id_estabelecimento_cnes,
  l.tipo_especialidade_leito,
  l.quantidade_total
FROM `basedosdados.br_ms_cnes.leito` AS l
JOIN estabelecimentos_2610 AS e
  ON l.id_estabelecimento_cnes = e.id_estabelecimento_cnes
WHERE l.sigla_uf = 'SP'
  AND l.ano = 2025
  AND l.mes = 11
  AND l.tipo_especialidade_leito = '81';


-- -----------------------------------------------------------------------
-- 7. Investigacao empirica do codigo 2611 (suspeita de sinonimo de 2605)
-- Resultado: 28 de 28 estabelecimentos (100%) tem leito codigo 82
-- correspondente -> sinonimo confirmado com evidencia ainda mais forte
-- que o caso anterior.
-- -----------------------------------------------------------------------
WITH estabelecimentos_2611 AS (
  SELECT DISTINCT id_estabelecimento_cnes
  FROM `basedosdados.br_ms_cnes.habilitacao`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
    AND tipo_habilitacao = '2611'
)

SELECT
  l.id_estabelecimento_cnes,
  l.tipo_especialidade_leito,
  l.quantidade_total
FROM `basedosdados.br_ms_cnes.leito` AS l
JOIN estabelecimentos_2611 AS e
  ON l.id_estabelecimento_cnes = e.id_estabelecimento_cnes
WHERE l.sigla_uf = 'SP'
  AND l.ano = 2025
  AND l.mes = 11
  AND l.tipo_especialidade_leito = '82';


-- -----------------------------------------------------------------------
-- 8. Regra final - leitos de UTI agregados por categoria semantica
-- (CASE WHEN unifica os codigos de leito em categorias), habilitacoes
-- de UTI agregadas pela mesma categoria (unificando os sinonimos), e
-- LEFT JOIN para achar combinacoes estabelecimento+categoria sem
-- nenhuma habilitacao correspondente.
-- Resultado: 553 de 1.103 combinacoes (50,1%) sem habilitacao,
-- totalizando 7.312 leitos de UTI sem respaldo formal, em 547
-- estabelecimentos com algum tipo de UTI cadastrado.
-- -----------------------------------------------------------------------
WITH leitos_uti AS (
  SELECT
    id_estabelecimento_cnes,
    CASE tipo_especialidade_leito
      WHEN '74' THEN 'uti_adulto_1'
      WHEN '75' THEN 'uti_adulto_2'
      WHEN '76' THEN 'uti_adulto_3'
      WHEN '77' THEN 'uti_pediatrica_1'
      WHEN '78' THEN 'uti_pediatrica_2'
      WHEN '79' THEN 'uti_pediatrica_3'
      WHEN '80' THEN 'uti_neonatal_1'
      WHEN '81' THEN 'uti_neonatal_2'
      WHEN '82' THEN 'uti_neonatal_3'
      WHEN '83' THEN 'uti_queimados'
      WHEN '85' THEN 'uti_coronariana_2'
      WHEN '86' THEN 'uti_coronariana_3'
    END AS categoria_uti,
    SUM(quantidade_total) AS total_leitos
  FROM `basedosdados.br_ms_cnes.leito`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
    AND tipo_especialidade_leito IN ('74','75','76','77','78','79','80','81','82','83','85','86')
  GROUP BY id_estabelecimento_cnes, categoria_uti
),

habilitacoes_uti AS (
  SELECT DISTINCT
    id_estabelecimento_cnes,
    CASE tipo_habilitacao
      WHEN '2696' THEN 'uti_adulto_1'
      WHEN '2601' THEN 'uti_adulto_2'
      WHEN '2604' THEN 'uti_adulto_3'
      WHEN '2698' THEN 'uti_pediatrica_1'
      WHEN '2603' THEN 'uti_pediatrica_2'
      WHEN '2606' THEN 'uti_pediatrica_3'
      WHEN '2697' THEN 'uti_neonatal_1'
      WHEN '2602' THEN 'uti_neonatal_2'
      WHEN '2610' THEN 'uti_neonatal_2'
      WHEN '2605' THEN 'uti_neonatal_3'
      WHEN '2611' THEN 'uti_neonatal_3'
      WHEN '2607' THEN 'uti_queimados'
      WHEN '2608' THEN 'uti_coronariana_2'
      WHEN '2609' THEN 'uti_coronariana_3'
    END AS categoria_uti
  FROM `basedosdados.br_ms_cnes.habilitacao`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
    AND tipo_habilitacao IN ('2696','2601','2604','2698','2603','2606','2697','2602','2610','2605','2611','2607','2608','2609')
)

SELECT
  COUNT(DISTINCT l.id_estabelecimento_cnes || l.categoria_uti) AS total_combinacoes_leito_uti,
  COUNT(DISTINCT CASE WHEN h.id_estabelecimento_cnes IS NULL THEN l.id_estabelecimento_cnes || l.categoria_uti END) AS total_sem_habilitacao,
  SUM(CASE WHEN h.id_estabelecimento_cnes IS NULL THEN l.total_leitos ELSE 0 END) AS total_leitos_sem_habilitacao,
  COUNT(DISTINCT l.id_estabelecimento_cnes) AS total_estabelecimentos_com_uti
FROM leitos_uti AS l
LEFT JOIN habilitacoes_uti AS h
  ON l.id_estabelecimento_cnes = h.id_estabelecimento_cnes
  AND l.categoria_uti = h.categoria_uti;
