-- -----------------------------------------------------------------------
-- FASE 6 (REVISAO) -- Validacao estrutural e matematica de cpf_cnpj
-- Recorte: SP, competencia 2025-11
--
-- Objetivo:
-- reproduzir de forma versionada o perfilamento e a validacao matematica
-- registrados na Decisao 07 do mapeamento CNES -> FHIR.
--
-- Privacidade:
-- os valores brutos de cpf_cnpj sao usados apenas internamente durante
-- o calculo. As consultas finais retornam somente resultados agregados.
--
-- Limite:
-- passar matematicamente no algoritmo de CPF ou CNPJ nao comprova
-- existencia, titularidade, situacao cadastral nem tipo fiscal efetivo.
-- -----------------------------------------------------------------------

CREATE TEMP FUNCTION fn_cpf_valido(cpf STRING)
RETURNS BOOL
LANGUAGE js AS r"""
  if (cpf === null || !/^[0-9]{11}$/.test(cpf)) {
    return false;
  }

  if (/^([0-9])\1{10}$/.test(cpf)) {
    return false;
  }

  const digitos = cpf.split('').map(Number);

  let soma = 0;
  for (let i = 0; i < 9; i++) {
    soma += digitos[i] * (10 - i);
  }

  let primeiro = (soma * 10) % 11;
  if (primeiro === 10) {
    primeiro = 0;
  }

  if (primeiro !== digitos[9]) {
    return false;
  }

  soma = 0;
  for (let i = 0; i < 10; i++) {
    soma += digitos[i] * (11 - i);
  }

  let segundo = (soma * 10) % 11;
  if (segundo === 10) {
    segundo = 0;
  }

  return segundo === digitos[10];
""";

CREATE TEMP FUNCTION fn_cnpj_valido(cnpj STRING)
RETURNS BOOL
LANGUAGE js AS r"""
  if (cnpj === null || !/^[0-9]{14}$/.test(cnpj)) {
    return false;
  }

  if (/^([0-9])\1{13}$/.test(cnpj)) {
    return false;
  }

  const digitos = cnpj.split('').map(Number);
  const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  let soma = 0;
  for (let i = 0; i < 12; i++) {
    soma += digitos[i] * pesos1[i];
  }

  let resto = soma % 11;
  const primeiro = resto < 2 ? 0 : 11 - resto;

  if (primeiro !== digitos[12]) {
    return false;
  }

  soma = 0;
  for (let i = 0; i < 13; i++) {
    soma += digitos[i] * pesos2[i];
  }

  resto = soma % 11;
  const segundo = resto < 2 ? 0 : 11 - resto;

  return segundo === digitos[13];
""";

CREATE TEMP TABLE classificado AS
WITH base AS (
  SELECT
    CAST(id_natureza_juridica AS STRING) AS id_natureza_juridica,
    NULLIF(TRIM(CAST(cpf_cnpj AS STRING)), '') AS documento
  FROM `basedosdados.br_ms_cnes.estabelecimento`
  WHERE sigla_uf = 'SP'
    AND ano = 2025
    AND mes = 11
),
validado AS (
  SELECT
    id_natureza_juridica,
    documento,
    documento IS NULL AS documento_ausente,
    IFNULL(REGEXP_CONTAINS(documento, r'^[0-9]{14}$'), FALSE)
      AS formato_14_numerico,
    IFNULL(STARTS_WITH(documento, '000'), FALSE) AS prefixo_000,
    CASE
      WHEN IFNULL(REGEXP_CONTAINS(documento, r'^[0-9]{14}$'), FALSE)
           AND IFNULL(STARTS_WITH(documento, '000'), FALSE)
      THEN fn_cpf_valido(RIGHT(documento, 11))
      ELSE FALSE
    END AS cpf_ok,
    CASE
      WHEN IFNULL(REGEXP_CONTAINS(documento, r'^[0-9]{14}$'), FALSE)
      THEN fn_cnpj_valido(documento)
      ELSE FALSE
    END AS cnpj_ok
  FROM base
)
SELECT
  *,
  CASE
    WHEN documento_ausente
      THEN 'Documento ausente'
    WHEN NOT formato_14_numerico
      THEN 'Formato inesperado'
    WHEN cpf_ok AND cnpj_ok
      THEN 'Valido nos dois algoritmos'
    WHEN cpf_ok
      THEN 'Somente CPF valido'
    WHEN cnpj_ok
      THEN 'Somente CNPJ valido'
    ELSE 'Nenhum algoritmo valido'
  END AS resultado_matematico
FROM validado;

-- RESULTADO 1
-- Perfil estrutural do campo.
SELECT
  COUNT(*) AS total_registros,
  COUNTIF(documento_ausente) AS documentos_ausentes,
  COUNTIF(NOT documento_ausente) AS documentos_preenchidos,
  COUNTIF(formato_14_numerico) AS documentos_14_digitos,
  COUNTIF(NOT documento_ausente AND prefixo_000) AS prefixo_000,
  COUNTIF(NOT documento_ausente AND NOT prefixo_000) AS outros_prefixos
FROM classificado;

-- RESULTADO 2
-- Matriz principal registrada conceitualmente na Decisao 07.
SELECT
  resultado_matematico,
  COUNTIF(id_natureza_juridica = '4000') AS natureza_4000,
  COUNTIF(id_natureza_juridica != '4000' OR id_natureza_juridica IS NULL)
    AS outras_naturezas,
  COUNT(*) AS total
FROM classificado
GROUP BY resultado_matematico
ORDER BY
  CASE resultado_matematico
    WHEN 'Somente CPF valido' THEN 1
    WHEN 'Somente CNPJ valido' THEN 2
    WHEN 'Valido nos dois algoritmos' THEN 3
    WHEN 'Documento ausente' THEN 4
    WHEN 'Formato inesperado' THEN 5
    ELSE 6
  END;

-- RESULTADO 3
-- Distribuicao dos documentos com prefixo 000 fora da natureza 4000.
-- Nenhum documento bruto e retornado.
SELECT
  id_natureza_juridica,
  COUNT(*) AS total_prefixo_000,
  COUNTIF(resultado_matematico = 'Somente CPF valido') AS somente_cpf,
  COUNTIF(resultado_matematico = 'Somente CNPJ valido') AS somente_cnpj,
  COUNTIF(resultado_matematico = 'Valido nos dois algoritmos') AS ambos,
  COUNTIF(resultado_matematico = 'Nenhum algoritmo valido') AS nenhum
FROM classificado
WHERE prefixo_000
  AND (id_natureza_juridica != '4000' OR id_natureza_juridica IS NULL)
GROUP BY id_natureza_juridica
ORDER BY total_prefixo_000 DESC, id_natureza_juridica;

-- -----------------------------------------------------------------------
-- RESULTADO DA EXECUCAO -- 2026-10-04
--
-- RESULTADO 1 -- Perfil estrutural
-- total_registros          = 110362
-- documentos_ausentes      = 11803
-- documentos_preenchidos   = 98559
-- documentos_14_digitos    = 98559
-- prefixo_000              = 34400
-- outros_prefixos          = 64159
--
-- RESULTADO 2 -- Validacao matematica
-- resultado_matematico             | natureza_4000 | outras_naturezas | total
-- Somente CPF valido                | 33179         | 189              | 33368
-- Somente CNPJ valido               | 1             | 64240            | 64241
-- Valido nos dois algoritmos        | 945           | 5                | 950
-- Documento ausente                 | 0             | 11803            | 11803
--
-- RESULTADO 3 -- Prefixo 000 fora da natureza 4000
-- id_natureza_juridica | total_prefixo_000 | somente_cpf | somente_cnpj | ambos | nenhum
-- 2062                  | 176               | 142         | 32           | 2     | 0
-- 2240                  | 53                | 20          | 31           | 2     | 0
-- 2135                  | 15                | 15          | 0            | 0     | 0
-- 2143                  | 13                | 0           | 13           | 0     | 0
-- 3999                  | 10                | 7           | 3            | 0     | 0
-- 2232                  | 7                 | 4           | 3            | 0     | 0
-- 1244                  | 1                 | 1           | 0            | 0     | 0
-- 2038                  | 1                 | 0           | 0            | 1     | 0
--
-- Conclusao:
-- a execucao reproduziu os resultados registrados na Decisao 07 do
-- mapeamento CNES -> FHIR para o recorte SP, competencia 2025-11.
-- Todos os 98559 valores preenchidos apresentaram 14 digitos.
-- Foram observados 34400 valores com prefixo 000.
-- A validacao matematica classificou 33368 valores somente como CPF,
-- 64241 somente como CNPJ e 950 como validos nos dois algoritmos.
--
-- Limite da evidencia:
-- a validacao matematica nao comprova existencia cadastral, titularidade,
-- situacao cadastral nem tipo fiscal efetivo dos documentos.
-- Os resultados agregados justificam tratamento conservador de privacidade,
-- mas nao autorizam classificar automaticamente os valores como documentos
-- pessoais de pessoa fisica.
-- Nenhum valor bruto de cpf_cnpj e registrado neste arquivo.
-- -----------------------------------------------------------------------
