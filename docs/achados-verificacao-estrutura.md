# Verificação da estrutura do CNES

**Data:** 19/08/2026
**Recorte:** São Paulo (SP), competência novembro/2025
**Conjunto:** `basedosdados.br_ms_cnes`
**Consultas:** `sql/02-verificacao-estrutura.sql`

---

## Por que essa verificação existe

O escopo inicial do projeto previa regras de consistência clínica — por exemplo, estabelecimento com leito de UTI cadastrado mas sem serviço compatível habilitado. Escrever essas regras exigia saber onde estão os dados de leitos, equipamentos e habilitações, e se a tabela `estabelecimento` sozinha bastaria.

A documentação pública do CNES indica que esses dados vêm de arquivos separados na origem. Documentação e realidade da tabela no BigQuery não são a mesma coisa: na Fase 1, a coluna `description` do `INFORMATION_SCHEMA`, que consta em documentações genéricas do BigQuery, não existia neste conjunto.

Verifiquei antes de escrever.

---

## O que existe no conjunto

O `br_ms_cnes` tem 14 tabelas:

| Tabela | Colunas |
|---|---|
| dados_complementares | 94 |
| dicionario | 5 |
| equipamento | 12 |
| equipe | 24 |
| estabelecimento | 204 |
| estabelecimento_ensino | 14 |
| estabelecimento_filantropico | 14 |
| gestao_metas | 15 |
| habilitacao | 16 |
| incentivos | 15 |
| leito | 10 |
| profissional | 23 |
| regra_contratual | 15 |
| servico_especializado | 15 |

Três diferenças em relação à lista planejada no repositório da Base dos Dados: `regra_contratual` está no singular, `incentivos` não constava, `integra_sus` não existe. A tabela `dicionario` também não aparecia na documentação.

---

## Chaves de relacionamento

As cinco tabelas que interessam ao projeto — `estabelecimento`, `leito`, `equipamento`, `habilitacao`, `servico_especializado` — começam com as mesmas cinco colunas:

```
ano                      INT64
mes                      INT64
sigla_uf                 STRING
id_municipio             STRING
id_estabelecimento_cnes  STRING
```

A chave de junção é composta: `id_estabelecimento_cnes` + `ano` + `mes`. O código sozinho não basta, porque cada tabela é uma fotografia mensal e o mesmo estabelecimento aparece em várias competências.

Como `sigla_uf` existe em todas, o filtro de SP pode ser aplicado em cada tabela antes do JOIN. Isso reduz o volume lido dos dois lados da junção.

---

## Granularidade: a decisão técnica central

Nenhuma das tabelas relacionadas tem uma linha por estabelecimento.

- `leito` — uma linha por estabelecimento **por especialidade por tipo** por competência
- `habilitacao` — uma linha por habilitação
- `servico_especializado` — uma linha por serviço, com subtipo
- `equipamento` — uma linha por tipo de equipamento

Um hospital com 5 tipos de leito, 3 habilitações e 8 serviços gera 120 linhas se as três tabelas forem juntadas cruas. É multiplicação, não soma.

**Decisão:** agregar cada tabela para uma linha por estabelecimento antes de juntar com `estabelecimento`. A granularidade da tabela principal precisa ser preservada.

---

## Códigos de leito

O campo `tipo_leito` tem 7 categorias: cirúrgico, clínico, complementar, obstétricos, pediátricos, outras especialidades, hospital dia.

O campo `tipo_especialidade_leito` tem 66 códigos. **A especialidade não identifica o leito sozinha** — cardiologia aparece como 2 e como 32, oncologia como 12 e 44, aids como 31 e 69, geriatria como 36 e 72. O que diferencia é o `tipo_leito`: cardiologia 2 é leito cirúrgico, cardiologia 32 é clínico.

Agrupar apenas por especialidade somaria leito cirúrgico com clínico. A query rodaria sem erro e devolveria número errado.

**Códigos de UTI:**

| Código | Descrição |
|---|---|
| 74, 75, 76 | UTI adulto tipos I, II, III |
| 77, 78, 79 | UTI pediátrica tipos I, II, III |
| 80, 81, 82 | UTI neonatal tipos I, II, III |
| 83 | UTI de queimados |
| 85, 86 | UTI coronariana tipos II e III |

A faixa não é contínua: 84 é acolhimento noturno, que não é UTI. Filtrar por intervalo numérico (`BETWEEN 74 AND 86`) incluiria o código errado. O filtro precisa listar os códigos explicitamente.

---

## Achados de qualidade de dados

Todos surgiram durante a verificação estrutural, sem que a análise da Fase 3 tivesse começado.

### 1. Dado pessoal de profissional em base pública

A tabela `profissional` contém `nome`, `cartao_nacional_saude` e `id_municipio_6_residencia`, junto com o estabelecimento de vínculo. Isso identifica indivíduos.

O documento de arquitetura assumia que o CNES é dado público agregado, sem dado pessoal, e propunha tratar LGPD como exercício hipotético. A premissa está errada. Não há dado de paciente, mas há dado pessoal de profissional de saúde, acessível a qualquer pessoa com conta no BigQuery.

**Consequências assumidas neste projeto:**
- Nenhum resultado com nome ou CNS vai para o repositório público
- Nenhum arquivo intermediário com essas colunas é versionado
- Só agregados por estabelecimento saem da Fase 3

### 2. Quantidade de leitos registrada em duas tabelas

`leito.quantidade_total` e `habilitacao.quantidade_leitos` descrevem o mesmo fato em lugares diferentes. Quando o mesmo dado é informado duas vezes, ele pode divergir — e não há como saber qual está certo sem ir à fonte.

Vira regra de consistência: comparar os dois valores por estabelecimento.

### 3. Habilitações com janela de validade

`habilitacao` tem `ano_competencia_inicial`, `mes_competencia_inicial`, `ano_competencia_final` e `mes_competencia_final`.

Habilitação com competência final anterior a novembro/2025 ainda presente na base de novembro/2025 é falha de atualidade. A regra não precisa de JOIN — compara datas dentro da própria tabela.

### 4. Campos indicadores com tipos diferentes entre tabelas

Em `servico_especializado`, os cinco campos `indicador_*` são INT64. Em `equipamento`, os dois campos `indicador_*` são STRING.

Mesma ideia semântica, dois tipos. Falha de padronização de metadados.

### 5. Problemas no próprio dicionário

- Grafias inconsistentes: `nefrologiaurologia` (código 8) e `nefrourologia` (código 40); `ortopediatraumatologia` sem separador
- Códigos ambíguos: 88 e 90 significam "queimado adulto"; 89 e 91 significam "queimado pediátrico"; 73 e 87 significam "saúde mental" — sem critério visível para escolher entre eles

O caso dos queimados é diferente do caso da cardiologia: ali havia um segundo campo (`tipo_leito`) que desfazia a ambiguidade. Aqui não há. Não é resolvível com os dados disponíveis; fica registrado como pergunta para a fonte oficial.

Esse achado atinge a camada de metadados, o que compromete qualquer análise construída sobre ela.

---

## Impacto nas regras da Fase 3

**Viáveis:**

| Regra | Tabelas |
|---|---|
| Leito de UTI sem habilitação correspondente | `leito` + `habilitacao` |
| Leito de UTI sem equipamento de suporte vital compatível | `leito` + `equipamento` |
| Divergência de quantidade de leitos entre fontes | `leito` + `habilitacao` |
| Habilitação vencida ainda registrada | `habilitacao` |
| Registro de conselho incompleto | `profissional` |

**Reformulada:**

A regra original — serviço de alta complexidade sem responsável técnico habilitado — não pode ser escrita. Não existe campo de responsabilidade técnica em `profissional`.

Versão possível: serviço de alta complexidade cadastrado sem nenhum profissional com CBO compatível vinculado. Mede adequação da força de trabalho ao serviço declarado, não responsabilidade técnica formal. A diferença precisa ficar explícita na documentação.

---

## Nota para a fase de interoperabilidade

O campo `cbo_2002` é vocabulário controlado de ocupações. No FHIR, o recurso `PractitionerRole` tem um elemento `code` que recebe esse tipo de codificação.

Registrado como observação, não como escopo.

---

## Viabilidade do recorte

O recorte SP + novembro/2025 continua válido e ganhou uma segunda justificativa. A primeira foi empírica: essa combinação tinha a maior contagem de estabelecimentos. A segunda é de custo — como `sigla_uf`, `ano` e `mes` existem em todas as tabelas, o filtro limita o volume de cada uma antes do JOIN.

**Riscos que permanecem:**

- Cobertura temporal pode variar entre tabelas; nem toda tabela necessariamente tem novembro/2025
- Multiplicação de linhas em JOIN sem agregação prévia é erro silencioso: a query roda e devolve número errado
- `SELECT *` em `estabelecimento` lê 204 colunas; em consulta com JOIN, o custo se multiplica pelas tabelas envolvidas
