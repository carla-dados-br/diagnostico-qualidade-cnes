-- =====================================================================
-- FASE 3 — Regra de consistencia: divergencia de quantidade de leitos
-- Recorte: SP, competencia 2025-11
-- Tabelas: leito + habilitacao (primeiro JOIN do projeto)
-- =====================================================================

-- -----------------------------------------------------------------------
-- 1. Agregacao previa de `leito` - uma linha por estabelecimento
-- Motivo: leito tem multiplas linhas por estabelecimento (uma por
-- especialidade/tipo). JOIN direto sem agregar multiplicaria linhas
-- (erro silencioso ja documentado em achados-verificacao-estrutura.md).
-- -----------------------------------------------------------------------
SELECT
  id_estabelecimento_cnes,
  SUM(quantidade_total) AS total_leitos_estabelecimento
FROM `basedosdados.br_ms_cnes.leito`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11
GROUP BY id_estabelecimento_cnes
LIMIT 10;


-- -----------------------------------------------------------------------
-- 2. Agregacao previa de `habilitacao` - mesma logica
-- Nota: ano_competencia_final/mes_competencia_final (sentinela pelo ano 9999,
-- ver achado anterior) nao interfere aqui - quantidade_leitos e campo
-- independente da data de validade da habilitacao.
-- -----------------------------------------------------------------------
SELECT
  id_estabelecimento_cnes,
  SUM(quantidade_leitos) AS total_leitos_habilitados
FROM `basedosdados.br_ms_cnes.habilitacao`
WHERE sigla_uf = 'SP'
  AND ano = 2025
  AND mes = 11
GROUP BY id_estabelecimento_cnes
LIMIT 10;


-- -----------------------------------------------------------------------
-- 3. JOIN das duas agregacoes - casos de divergencia
-- INNER JOIN (nao LEFT JOIN): a pergunta desta regra e "entre os
-- estabelecimentos que existem nas duas fontes, onde os numeros
-- divergem" - nao "quais estabelecimentos faltam em uma das fontes"
-- (essa e uma regra diferente, ja prevista em achados-verificacao-estrutura.md).
-- -----------------------------------------------------------------------
WITH leitos_agregados AS (
  SELECT
    id_estabelecimento_cnes,
    SUM(quantidade_total) AS total_leitos
  FROM `basedosdados.br_ms_cnes.leito`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
  GROUP BY id_estabelecimento_cnes
),

habilitacoes_agregadas AS (
  SELECT
    id_estabelecimento_cnes,
    SUM(quantidade_leitos) AS total_leitos_habilitados
  FROM `basedosdados.br_ms_cnes.habilitacao`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
  GROUP BY id_estabelecimento_cnes
)

SELECT
  l.id_estabelecimento_cnes,
  l.total_leitos,
  h.total_leitos_habilitados,
  l.total_leitos - h.total_leitos_habilitados AS diferenca
FROM leitos_agregados AS l
JOIN habilitacoes_agregadas AS h
  ON l.id_estabelecimento_cnes = h.id_estabelecimento_cnes
WHERE l.total_leitos != h.total_leitos_habilitados
LIMIT 15;


-- -----------------------------------------------------------------------
-- 4. Metrica agregada da regra
-- Resultado: 768 de 768 estabelecimentos avaliaveis divergem (100%). [NOTA 2026-11-02: 464 dos 768 tem total habilitado = 0; ver etapas 6 a 8]
-- Resultado extremo, investigar antes de aceitar (mesmo principio ja
-- aplicado ao 0% da regra de habilitacao vencida).
-- -----------------------------------------------------------------------
WITH leitos_agregados AS (
  SELECT
    id_estabelecimento_cnes,
    SUM(quantidade_total) AS total_leitos
  FROM `basedosdados.br_ms_cnes.leito`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
  GROUP BY id_estabelecimento_cnes
),

habilitacoes_agregadas AS (
  SELECT
    id_estabelecimento_cnes,
    SUM(quantidade_leitos) AS total_leitos_habilitados
  FROM `basedosdados.br_ms_cnes.habilitacao`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
  GROUP BY id_estabelecimento_cnes
)

SELECT
  COUNT(*) AS total_estabelecimentos_avaliaveis,
  COUNTIF(l.total_leitos != h.total_leitos_habilitados) AS total_com_divergencia,
  ROUND(
    COUNTIF(l.total_leitos != h.total_leitos_habilitados) / COUNT(*) * 100
  , 2) AS percentual_com_divergencia
FROM leitos_agregados AS l
JOIN habilitacoes_agregadas AS h
  ON l.id_estabelecimento_cnes = h.id_estabelecimento_cnes;


-- -----------------------------------------------------------------------
-- 5. Investigacao - distribuicao e direcao das diferencas
-- Resultado: diferenca sempre positiva (leito > habilitacao em 768 de
-- 768 casos, nunca o contrario). Min=1, max=1309, media=97.88.
-- Padrao sistematico e direcional, nao ruido aleatorio.
-- -----------------------------------------------------------------------
WITH leitos_agregados AS (
  SELECT
    id_estabelecimento_cnes,
    SUM(quantidade_total) AS total_leitos
  FROM `basedosdados.br_ms_cnes.leito`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
  GROUP BY id_estabelecimento_cnes
),

habilitacoes_agregadas AS (
  SELECT
    id_estabelecimento_cnes,
    SUM(quantidade_leitos) AS total_leitos_habilitados
  FROM `basedosdados.br_ms_cnes.habilitacao`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
  GROUP BY id_estabelecimento_cnes
)

SELECT
  MIN(l.total_leitos - h.total_leitos_habilitados) AS diferenca_minima,
  MAX(l.total_leitos - h.total_leitos_habilitados) AS diferenca_maxima,
  ROUND(AVG(l.total_leitos - h.total_leitos_habilitados), 2) AS diferenca_media,
  COUNTIF(l.total_leitos > h.total_leitos_habilitados) AS leito_maior_que_habilitacao,
  COUNTIF(l.total_leitos < h.total_leitos_habilitados) AS habilitacao_maior_que_leito
FROM leitos_agregados AS l
JOIN habilitacoes_agregadas AS h
  ON l.id_estabelecimento_cnes = h.id_estabelecimento_cnes;

-- -----------------------------------------------------------------------
-- 6. Verificacao pos-auditoria - habilitacoes sem leitos no universo da
-- etapa 4 (executada em 2026-11-02; job job_GoT7543x-3yYMZXlKKhZDAsgrFnz)
-- Motivo: a etapa 4 soma quantidade_leitos de TODOS os tipos de
-- habilitacao. Tipos que nao envolvem leitos (ex.: CAPS, hemodialise,
-- vasectomia) entram com zero e tornam a divergencia inevitavel.
-- Resultado: 768 avaliaveis; 464 (60,4%) com total habilitado = 0;
-- 0 com quantidade_leitos nula.
-- -----------------------------------------------------------------------
WITH l AS (
  SELECT id_estabelecimento_cnes, SUM(quantidade_total) AS t
  FROM `basedosdados.br_ms_cnes.leito`
  WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11
  GROUP BY 1
),
h AS (
  SELECT id_estabelecimento_cnes, SUM(quantidade_leitos) AS t,
         COUNTIF(quantidade_leitos IS NULL) AS nulos
  FROM `basedosdados.br_ms_cnes.habilitacao`
  WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11
  GROUP BY 1
)
SELECT COUNT(*) AS avaliaveis,
       COUNTIF(h.t = 0) AS hab_total_zero,
       COUNTIF(h.nulos > 0) AS com_nulo
FROM l JOIN h USING (id_estabelecimento_cnes);


-- -----------------------------------------------------------------------
-- 7. Leitos por tipo de habilitacao (executada em 2026-11-02;
-- job job_CwYjVobq0cs4-6um1CE08vUqn6AI)
-- Resultado: 191 tipos e 6.764 registros (mesmo total da sql/04).
-- So 18 tipos tem leitos: 803 registros e 9.307 leitos habilitados
-- (UTI: 2601, 2602, 2603, 2604, 2606, 2607, 2608, 2609, 2610, 2611,
-- 2696, 2698; cuidados intermediarios neonatais: 2801, 2802, 2803;
-- outros: 908, 636, 1420). Os outros 173 tipos tem sempre zero.
-- Observacoes: a habilitacao 2602, extinta pela Portaria SAES/MS
-- n. 2.902/2025, aparece em 1 estabelecimento; 34 codigos nao tem
-- descricao na tabela dicionario. O dicionario e agregado por chave
-- (ANY_VALUE) para nao multiplicar linhas no JOIN.
-- -----------------------------------------------------------------------
WITH dic AS (
  SELECT chave, ANY_VALUE(valor) AS descricao
  FROM `basedosdados.br_ms_cnes.dicionario`
  WHERE id_tabela = 'habilitacao' AND nome_coluna = 'tipo_habilitacao'
  GROUP BY chave
)
SELECT
  h.tipo_habilitacao,
  d.descricao,
  COUNT(*) AS registros,
  COUNT(DISTINCT h.id_estabelecimento_cnes) AS estabelecimentos,
  COUNTIF(h.quantidade_leitos > 0) AS registros_com_leitos,
  SUM(h.quantidade_leitos) AS soma_leitos
FROM `basedosdados.br_ms_cnes.habilitacao` AS h
LEFT JOIN dic AS d ON h.tipo_habilitacao = d.chave
WHERE h.sigla_uf = 'SP' AND h.ano = 2025 AND h.mes = 11
GROUP BY 1, 2
ORDER BY soma_leitos DESC, registros DESC;


-- -----------------------------------------------------------------------
-- 8. Comparacao restrita as habilitacoes com leitos (executada em
-- 2026-11-02; job job_fqBUYJlokO6Pmw9aG9_Z5Cylw4Sj)
-- Criterio: quantidade_leitos > 0 (empirico; separa os 18 tipos da
-- etapa 7). Comparacao com o total de leitos e com os leitos SUS.
-- Resultado: 304 avaliaveis.
--   leitos_total > habilitados em 304 de 304 - esperado, porque o total
--   inclui tipos de leito que nao exigem habilitacao e leitos nao SUS.
--   leitos_sus: maior em 299, igual em 4, menor em 1; diferenca de -18
--   a 1.242, media 123,5; 0 nulos.
-- Leitura: a comparacao agregada descreve a diferenca, mas nao testa
-- consistencia. O unico caso a investigar e o estabelecimento com mais
-- leitos habilitados (18 a mais) do que leitos SUS cadastrados.
-- -----------------------------------------------------------------------
WITH hab AS (
  SELECT id_estabelecimento_cnes, SUM(quantidade_leitos) AS leitos_hab
  FROM `basedosdados.br_ms_cnes.habilitacao`
  WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11
    AND quantidade_leitos > 0
  GROUP BY 1
),
lei AS (
  SELECT id_estabelecimento_cnes,
         SUM(quantidade_total) AS leitos_total,
         SUM(quantidade_sus)   AS leitos_sus
  FROM `basedosdados.br_ms_cnes.leito`
  WHERE sigla_uf = 'SP' AND ano = 2025 AND mes = 11
  GROUP BY 1
)
SELECT
  COUNT(*) AS avaliaveis,
  COUNTIF(l.leitos_total > h.leitos_hab) AS total_maior,
  COUNTIF(l.leitos_total = h.leitos_hab) AS total_igual,
  COUNTIF(l.leitos_total < h.leitos_hab) AS total_menor,
  COUNTIF(l.leitos_sus > h.leitos_hab)   AS sus_maior,
  COUNTIF(l.leitos_sus = h.leitos_hab)   AS sus_igual,
  COUNTIF(l.leitos_sus < h.leitos_hab)   AS sus_menor,
  COUNTIF(l.leitos_sus IS NULL)          AS sus_nulo,
  MIN(l.leitos_sus - h.leitos_hab) AS dif_sus_min,
  MAX(l.leitos_sus - h.leitos_hab) AS dif_sus_max,
  ROUND(AVG(l.leitos_sus - h.leitos_hab), 2) AS dif_sus_media
FROM lei AS l
JOIN hab AS h USING (id_estabelecimento_cnes);
