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
-- Nota: ano_competencia_final/mes_competencia_final (sentinela 9999/99,
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
-- Resultado: 768 de 768 estabelecimentos avaliaveis divergem (100%).
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
