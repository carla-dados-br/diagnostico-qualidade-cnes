-- =====================================================================
-- 02 - VERIFICACAO DA ESTRUTURA DO CNES
-- Projeto: Diagnostico de Qualidade e Governanca de Dados (CNES/DATASUS)
-- Data: 19/08/2026
--
-- Objetivo: descobrir em quais tabelas do conjunto br_ms_cnes estao os
-- dados de capacidade instalada (leitos, equipamentos, habilitacoes,
-- servicos) e quais campos permitem relacionar essas tabelas entre si.
--
-- Motivo: as regras de consistencia clinica previstas para a Fase 3
-- dependem de campos que podem nao estar na tabela `estabelecimento`.
-- Antes de escrever qualquer regra, era preciso confirmar o que existe.
--
-- Todas as consultas deste arquivo leem apenas o catalogo
-- (INFORMATION_SCHEMA) ou a tabela `dicionario`, que e pequena.
-- Nenhuma le dados de estabelecimentos.
-- =====================================================================


-- ---------------------------------------------------------------------
-- QUERY 1 - Onde estao os campos de capacidade instalada?
--
-- Pergunta: a tabela `estabelecimento` tem os campos de leito e
-- equipamento, ou eles estao em outro lugar?
--
-- Resultado: 257 linhas. A tabela `equipamento` existe e tem 12 colunas.
-- Confirmou tambem que `estabelecimento` tem `ano_atualizacao` e
-- `mes_atualizacao`, base para a regra de desatualizacao cadastral.
-- ---------------------------------------------------------------------

SELECT
  table_name,
  column_name,
  data_type
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN (
  'estabelecimento',
  'leito',
  'equipamento',
  'habilitacao',
  'servico_especializado'
)
ORDER BY table_name, ordinal_position;


-- ---------------------------------------------------------------------
-- QUERY 2 - Inventario: quais tabelas existem no conjunto?
--
-- Pergunta: a Query 1 devolveu 257 linhas, mas `estabelecimento` (204) e
-- `equipamento` (12) somam 216. De onde vieram as outras 41?
--
-- Resultado: 14 tabelas. As tres pendentes eram leito (10),
-- habilitacao (16) e servico_especializado (15) = 41. Conta fechou.
--
-- Achado nao previsto: existe uma tabela `dicionario`, que traduz os
-- codigos das demais tabelas.
-- ---------------------------------------------------------------------

SELECT
  table_name,
  COUNT(*) AS total_colunas
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
GROUP BY table_name
ORDER BY table_name;


-- ---------------------------------------------------------------------
-- QUERY 3 - Estrutura das tabelas de capacidade instalada
--
-- Pergunta: quais campos existem em leito, habilitacao e
-- servico_especializado, e elas tem as chaves para o JOIN?
--
-- Resultado: 41 linhas. As cinco primeiras colunas das tres tabelas sao
-- ano, mes, sigla_uf, id_municipio e id_estabelecimento_cnes - as mesmas
-- de `estabelecimento`. JOIN confirmado, e o filtro de SP pode ser
-- aplicado em cada tabela antes da juncao.
-- ---------------------------------------------------------------------

SELECT
  table_name,
  column_name,
  data_type
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN ('leito', 'habilitacao', 'servico_especializado')
ORDER BY table_name, ordinal_position;


-- ---------------------------------------------------------------------
-- QUERY 4 - Estrutura da tabela dicionario
--
-- Pergunta: o dicionario serve para traduzir os codigos das outras
-- tabelas? Em que formato?
--
-- Resultado: 5 colunas - id_tabela, nome_coluna, chave, valor e
-- cobertura_temporal. Formato de para: informa a qual tabela e coluna o
-- codigo pertence, o codigo em si e seu significado.
-- ---------------------------------------------------------------------

SELECT
  column_name,
  data_type
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'dicionario'
ORDER BY ordinal_position;


-- ---------------------------------------------------------------------
-- QUERY 5 - Estrutura da tabela profissional
--
-- Pergunta: existe campo de responsabilidade tecnica, para a regra de
-- alta complexidade sem responsavel habilitado?
--
-- Resultado: 23 colunas. NAO existe campo de responsabilidade tecnica.
-- Existem cbo_2002, tipo_conselho, id_registro_conselho e cargas
-- horarias - o que permite reformular a regra.
--
-- Achado critico: a tabela contem `nome`, `cartao_nacional_saude` e
-- `id_municipio_6_residencia`. Ha dado pessoal de profissional de saude
-- nesta base publica. Ver docs/achados-verificacao-estrutura.md.
-- ---------------------------------------------------------------------

SELECT
  column_name,
  data_type
FROM `basedosdados.br_ms_cnes.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'profissional'
ORDER BY ordinal_position;


-- ---------------------------------------------------------------------
-- QUERY 6 - Codigos de especialidade e tipo de leito
--
-- Pergunta: qual codigo representa UTI? A especialidade sozinha
-- identifica o leito?
--
-- Resultado: 73 linhas. UTI aparece nos codigos 74 a 83, 85 e 86 do
-- campo tipo_especialidade_leito. O campo tipo_leito tem 7 categorias:
-- cirurgico, clinico, complementar, obstetricos, pediatricos, outras
-- especialidades e hospital dia.
--
-- Decisao tecnica: a especialidade NAO identifica o leito sozinha.
-- Cardiologia aparece como 2 (cirurgico) e 32 (clinico). Toda agregacao
-- de leitos precisa usar tipo_especialidade_leito E tipo_leito juntos.
--
-- Esta consulta le a tabela `dicionario`, entao processa dados. E uma
-- tabela pequena, de traducao de codigos.
-- ---------------------------------------------------------------------

SELECT
  id_tabela,
  nome_coluna,
  chave,
  valor
FROM `basedosdados.br_ms_cnes.dicionario`
WHERE nome_coluna IN (
  'tipo_especialidade_leito',
  'tipo_leito'
)
ORDER BY nome_coluna, chave;
