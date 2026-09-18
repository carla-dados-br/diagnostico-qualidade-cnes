# Diagnóstico de Qualidade e Governança de Dados em Estabelecimentos de Saúde (CNES/DATASUS)

> Projeto de portfólio em Dados para Saúde. Autora em formação em Biomedicina e Ciência de Dados e IA, aplicando na prática análise de dados, qualidade de dados, governança e interoperabilidade em uma base pública do SUS.

## Sobre o projeto

Este projeto utiliza dados públicos do CNES (Cadastro Nacional de Estabelecimentos de Saúde), disponibilizados pelo DATASUS/Ministério da Saúde e acessados inicialmente pelo dataset público `br_ms_cnes` da Base dos Dados, para avaliar a qualidade cadastral de estabelecimentos de saúde.

O trabalho percorre diferentes etapas do ciclo de vida do dado:

- exploração e compreensão da estrutura;
- definição de recorte;
- avaliação de completude;
- avaliação de consistência;
- avaliação de atualidade;
- avaliação de unicidade;
- tratamento e reprodução dos indicadores em Python;
- visualização dos resultados;
- definição de regras mínimas de governança;
- investigação de proveniência;
- preparação para interoperabilidade por meio de FHIR.

Ao final, o projeto prevê o mapeamento dos dados tratados para os recursos FHIR `Organization` e `Location`, com validação formal dos recursos produzidos.

O CNES é uma base estrutural para diferentes processos de informação em saúde. Problemas cadastrais podem se propagar para análises, integrações, indicadores e processos que dependem desses registros.

A pergunta central do projeto é:

> Quanto do cadastro está incompleto, inconsistente ou desatualizado, onde esses problemas aparecem e quais controles de qualidade e governança podem reduzir o risco de propagação dessas inconsistências?

---

## Perguntas de negócio

- Quais campos críticos do cadastro apresentam problemas de completude?
- Existem inconsistências entre informações relacionadas armazenadas em tabelas diferentes?
- Qual o percentual de estabelecimentos sem atualização cadastral recente?
- Existem identificadores duplicados dentro do recorte?
- Como a qualidade do cadastro varia entre municípios?
- Quais achados exigem regras explícitas de governança?
- Quais limitações semânticas precisam ser resolvidas antes de transformar esses dados em recursos interoperáveis?

Cada indicador calculado deve responder a uma necessidade analítica ou de governança identificável.

---

## Recorte

- **Geográfico:** Estado de São Paulo
- **Temporal:** competência de novembro de 2025
- **Fonte analítica principal:** Base dos Dados
- **Dataset:** `br_ms_cnes`
- **Consulta:** Google BigQuery

O recorte principal contém **110.362 estabelecimentos**.

A justificativa completa do recorte está documentada em [`docs/decisao-recorte.md`](docs/decisao-recorte.md).

---

## Dimensões de qualidade

O diagnóstico utiliza quatro dimensões fixas de qualidade.

| Dimensão | O que mede | Status |
|---|---|---|
| Completude | Presença dos valores esperados considerando regras reais de preenchimento | 5 campos avaliados |
| Consistência | Contradições, incompatibilidades ou problemas de domínio entre campos e tabelas | 3 regras principais + investigação semântica |
| Atualidade | Tempo desde a última alteração cadastral | Concluída |
| Unicidade | Existência de duplicidade de identificadores dentro do recorte | Concluída |

As quatro dimensões possuem ao menos um indicador calculado e documentado.

---

## Regras de consistência aplicadas

Foram implementadas três regras principais, escolhidas para representar diferentes níveis de complexidade analítica.

| Regra | Tabelas | O que exige | Status |
|---|---|---|---|
| Habilitação com competência final vencida ainda registrada | `habilitacao` | comparação temporal dentro da própria tabela | Concluída |
| Divergência de quantidade de leitos | `leito` + `habilitacao` | agregação e junção entre tabelas | Concluída |
| Leito de UTI sem habilitação correspondente | `leito` + `habilitacao` | correspondência semântica entre domínios diferentes | Concluída |

A correspondência entre tipos de leito e tipos de habilitação foi investigada separadamente, pois os dois campos utilizam domínios de códigos diferentes.

---

## Principais achados

### Ausência mascarada em `id_regiao_saude`

O campo `id_regiao_saude` não representa ausência apenas com `NULL`.

Foram identificadas três formas:

- `NULL`;
- texto literal `"nan"`;
- string vazia `""`.

Uma verificação baseada apenas em `IS NULL` produziria falsamente 0% de incompletude.

Após a comparação entre SQL e Python e a inclusão das três formas de ausência, a métrica corrigida do recorte é **54,70% de incompletude**.

Esse achado mostra que a forma física de representação do dado precisa ser investigada antes da definição de métricas.

### Valor sentinela em habilitações

Na tabela `habilitacao`, a combinação:

```text
ano_competencia_final = 9999
mes_competencia_final = 99
```

é utilizada para representar prazo final indeterminado.

No recorte, **6.072 de 6.764 habilitações (89,76%)** utilizam esse padrão.

A regra de habilitação vencida precisou excluir explicitamente o sentinela antes da comparação temporal. Após o tratamento correto, **0 habilitações vencidas** foram encontradas no recorte.

### Divergência sistemática entre quantidades de leitos

Foram encontrados **768 estabelecimentos avaliáveis** presentes simultaneamente nas tabelas necessárias para a comparação.

Em todos eles:

```text
leito.quantidade_total > habilitacao.quantidade_leitos
```

Nenhum dos 768 apresentou igualdade entre as duas medidas.

O padrão é sistemático e compatível com a hipótese de que os campos possam representar conceitos diferentes. Essa interpretação permanece documentada como hipótese enquanto não houver confirmação semântica suficiente da fonte.

### UTI sem habilitação correspondente

Foram avaliadas **1.103 combinações estabelecimento + categoria de UTI**. Dessas, **553 (50,1%)** não apresentaram habilitação correspondente segundo o de-para utilizado no projeto.

Essas combinações representam **7.312 leitos** em **547 estabelecimentos**.

A correspondência entre os domínios de leito e habilitação foi construída semanticamente e investigada empiricamente, não apenas pela semelhança textual dos nomes.

### Completude não garante consistência semântica

O campo `tipo_unidade` apresentou:

- 0 `NULL`;
- 0 textos `"nan"`;
- 0 strings vazias.

Portanto, apresentou **0% de incompletude** no recorte.

Entretanto, a investigação do domínio mostrou que completude física não significa necessariamente consistência semântica.

Foram observados **38 códigos distintos**, dos quais:

- 37 possuem correspondência na tabela `dicionario`;
- o código `16` não possui correspondência nessa fonte;
- 5 estabelecimentos apresentam `tipo_unidade = 16`.

Isso transformou o código `16` em uma exceção semântica que precisou ser investigada antes do mapeamento FHIR.

---

## Investigação de proveniência do código `tipo_unidade = 16`

A investigação temporal mostrou que o código `16` começou a aparecer recentemente nos cinco estabelecimentos afetados do recorte, substituindo diferentes códigos anteriores.

Também foi identificada ocorrência nacional do código em múltiplas UFs a partir de setembro de 2025 dentro do período pesquisado.

Para verificar se o valor poderia ter sido criado durante a transformação da Base dos Dados, foi realizado um teste independente de proveniência.

### Ferramentas utilizadas

- Docker;
- PySUS 2.11.1;
- fonte CNES consultada com `source="origin"`.

### Consulta realizada

```text
Estado: SP
Ano: 2025
Mês: 11
Grupo CNES: ST
```

O conjunto retornado apresentou:

- 110.362 registros;
- 208 colunas;
- campos originais `CNES` e `TP_UNID`.

Os cinco estabelecimentos investigados apresentaram:

| CNES | `TP_UNID` |
|---|---:|
| `4932609` | `16` |
| `5767032` | `16` |
| `5828953` | `16` |
| `9340459` | `16` |
| `9570365` | `16` |

Resultado: **5 de 5 registros apresentaram `TP_UNID = 16` na origem consultada.**

Portanto, não foi encontrada evidência de que a transformação observada entre a origem consultada e a Base dos Dados tenha introduzido o valor `16`.

Isso confirma sua proveniência dentro da cadeia investigada, mas não confirma seu significado semântico. O código continua sem significado oficial confirmado dentro das fontes utilizadas no projeto.

Por essa razão, nenhum `coding.display` será inferido artificialmente durante o mapeamento FHIR.

Investigação completa: [`docs/investigacao-proveniencia-tipo-unidade-16.md`](docs/investigacao-proveniencia-tipo-unidade-16.md).

---

## Atualidade cadastral

Foi adotada uma janela metodológica de **24 meses** anteriores à própria competência do snapshot.

A referência utilizada é novembro de 2025, e não a data em que a análise foi executada.

| Situação | Estabelecimentos |
|---|---:|
| Atualizados | 87.494 |
| Desatualizados | 22.868 |
| Não informado | 0 |

Percentual desatualizado: **20,72%**.

A janela de 24 meses é uma convenção metodológica deste projeto e não uma regra normativa atribuída ao DATASUS.

---

## Distribuição regional

A incompletude de `id_regiao_saude` apresenta forte variação municipal.

Foram avaliados **347 municípios** com pelo menos 20 estabelecimentos.

| Faixa de incompletude | Municípios |
|---|---:|
| 0–25% | 100 |
| 25–50% | 67 |
| 50–75% | 111 |
| 75–100% | 69 |

A hipótese inicial de uma distribuição bimodal foi testada e rejeitada. O problema apresenta distribuição contínua entre municípios.

---

## Unicidade

O campo `id_estabelecimento_cnes` foi avaliado dentro do recorte fixo SP + novembro/2025.

Resultado:

```text
110.362 registros
0 identificadores duplicados
```

Dentro deste recorte, `id_estabelecimento_cnes` funciona como chave única de fato.

---

## Tratamento em Python

A Fase 2 reproduziu formalmente parte dos indicadores originalmente desenvolvidos em SQL utilizando Python e pandas.

Notebook principal: [`python/fase2-limpeza-tratamento.ipynb`](python/fase2-limpeza-tratamento.ipynb).

A comparação SQL × Python permitiu identificar e corrigir divergências reais de interpretação, incluindo:

- tipo correto de `id_municipio`;
- existência de strings vazias em `id_regiao_saude`;
- correção da métrica de incompletude de 54,69% para 54,70%.

A reprodução das três regras de consistência e do indicador de atualidade em Python permanece como extensão futura e não bloqueia as próximas fases do projeto.

---

## Dashboard

A Fase 4 produziu três visualizações principais:

- completude por campo;
- atualidade cadastral;
- distribuição regional.

Os relatórios foram produzidos no Power BI e os resultados exportados e versionados na pasta `dashboard/`.

A versão Web do Power BI utilizada no projeto exigiu relatórios separados para algumas visualizações devido às limitações de combinação de múltiplas fontes sem o Power BI Desktop.

---

## Governança de dados

A Fase 5 transformou os principais achados técnicos em regras mínimas de governança.

O framework contém **9 regras de governança**, cada uma associada a um problema efetivamente encontrado durante o projeto.

Documento: [`docs/framework-governanca.md`](docs/framework-governanca.md).

O framework diferencia explicitamente:

```text
fato confirmado
≠
hipótese
≠
regra metodológica do projeto
```

Essa separação evita transformar interpretações ainda não verificadas em regras de negócio ou afirmações sobre a fonte.

---

## Interoperabilidade FHIR

A **Fase 6 está em andamento**.

O objetivo é transformar informações selecionadas do CNES em recursos compatíveis com **FHIR R4**, principalmente:

- `Organization`;
- `Location`.

O processo não consiste apenas em renomear colunas. Cada campo precisa ser avaliado considerando:

- conceito de origem;
- significado semântico;
- recurso FHIR apropriado;
- elemento FHIR;
- cardinalidade;
- tipo de dado;
- sistema de identificação ou terminologia;
- necessidade de transformação;
- referências entre recursos;
- possível perda semântica.

Os mapeamentos serão classificados como:

- direto;
- aproximado;
- dependente de transformação;
- sem correspondência clara.

A investigação de `tipo_unidade = 16` foi realizada justamente porque um código cuja semântica não está confirmada não pode ser transformado automaticamente em um conceito FHIR validado.

A Fase 6 somente será considerada concluída após:

- definição do mapeamento;
- geração dos recursos;
- produção de exemplos JSON;
- validação formal FHIR;
- documentação das perdas e exceções semânticas.

Submissão de dados à RNDS não faz parte do escopo deste projeto.

---

## Status do projeto

### Fases concluídas

- [x] Fase 1 — Exploração, extração e definição do recorte
- [x] Fase 2 — Limpeza e tratamento formal em Python
- [x] Fase 3 — Indicadores de qualidade e consistência
- [x] Fase 4 — Dashboard
- [x] Fase 5 — Governança de dados

### Fase atual

- [ ] **Fase 6 — Mapeamento e validação FHIR**

Atividades já realizadas dentro da Fase 6:

- [x] investigação inicial dos campos disponíveis para interoperabilidade;
- [x] avaliação de `id_estabelecimento_cnes` como identificador;
- [x] investigação do domínio de `tipo_unidade`;
- [x] identificação da exceção semântica `tipo_unidade = 16`;
- [x] análise temporal dos cinco estabelecimentos afetados;
- [x] análise nacional da ocorrência do código `16`;
- [x] teste de proveniência utilizando PySUS e `source="origin"`;
- [x] documentação formal da exceção semântica;
- [ ] concluir tabela de mapeamento CNES → FHIR;
- [ ] implementar transformação;
- [ ] gerar recursos `Organization`;
- [ ] gerar recursos `Location`;
- [ ] validar formalmente os recursos FHIR;
- [ ] documentar perdas semânticas e exceções.

### Etapa final

- [ ] Fase 7 — Consolidação e apresentação final do portfólio

---

## Checklist técnico concluído

- [x] Ambiente configurado e BigQuery Sandbox utilizado
- [x] Estrutura da tabela `estabelecimento` explorada
- [x] 204 colunas identificadas na tabela analítica principal
- [x] Recorte definido e validado contra dados reais
- [x] Estrutura do conjunto investigada
- [x] 14 tabelas avaliadas quanto a chaves e granularidade
- [x] Escopo revisado após exploração da estrutura
- [x] Completude de `id_regiao_saude` calculada e corrigida para 54,70%
- [x] Completude de `tipo_unidade` calculada: 0% de ausência
- [x] Domínio observado de `tipo_unidade` investigado: 37 de 38 códigos reconciliados
- [x] Exceção semântica do código `16` documentada
- [x] Regra de habilitação vencida
- [x] Regra de divergência de leitos
- [x] Regra de UTI sem habilitação correspondente
- [x] Indicador de atualidade cadastral
- [x] Indicador de distribuição regional
- [x] Completude de `id_municipio`
- [x] Completude de `tipo_gestao`
- [x] Completude condicional de `cnpj_mantenedora`
- [x] Indicador de unicidade
- [x] Pipeline formal em Python
- [x] Comparação SQL × Python
- [x] Dashboard produzido
- [x] Framework de governança produzido
- [x] Investigação de proveniência do código `16`
- [ ] Mapeamento CNES → FHIR concluído
- [ ] Recursos FHIR gerados
- [ ] Recursos FHIR formalmente validados

---

## Tecnologias

- SQL
- Google BigQuery
- Python
- pandas
- Power BI
- Git
- GitHub
- Docker
- PySUS
- FHIR R4

---

## Estrutura do repositório

```text
.
├── sql/
│   ├── 01-exploracao-fase1.sql
│   ├── 02-verificacao-estrutura.sql
│   ├── 03-completude-id_regiao_saude.sql
│   ├── 04-consistencia-habilitacao-vencida.sql
│   ├── 05-consistencia-divergencia-leitos.sql
│   ├── 06-consistencia-uti-sem-habilitacao.sql
│   ├── 07-completude-tipo_unidade.sql
│   ├── 08-atualidade-cadastral.sql
│   ├── 09-distribuicao-regional.sql
│   ├── 10-completude-id_municipio.sql
│   ├── 11-completude-tipo_gestao.sql
│   ├── 12-completude-cnpj_mantenedora.sql
│   └── 13-unicidade-id_estabelecimento_cnes.sql
│
├── docs/
│   ├── decisao-recorte.md
│   ├── achados-verificacao-estrutura.md
│   ├── dicionario-de-dados.md
│   ├── framework-governanca.md
│   ├── investigacao-proveniencia-tipo-unidade-16.md
│   └── demais decisões e documentos metodológicos
│
├── python/
│   └── fase2-limpeza-tratamento.ipynb
│
├── dashboard/
│   └── relatórios e evidências da Fase 4
│
└── README.md
```

---

## Decisões metodológicas

As decisões de escopo, tratamento e interpretação são registradas em `docs/`.

Sempre que possível, cada decisão contém:

- problema encontrado;
- evidência;
- interpretação;
- hipótese, quando existente;
- decisão adotada;
- justificativa;
- impacto sobre as etapas posteriores.

Uma decisão sem justificativa escrita reduz a auditabilidade e dificulta a reprodução da análise.

O projeto também preserva a separação entre:

```text
observação
hipótese
conclusão
decisão metodológica
```

Uma hipótese plausível não é documentada como fato enquanto não houver evidência suficiente para sustentá-la.

---

## Limitações declaradas

### Escopo da análise

O projeto mede a qualidade do cadastro, não a qualidade operacional ou assistencial das instituições.

Um estabelecimento com cadastro completo não é necessariamente bem administrado, assim como um cadastro incompleto não demonstra má gestão da instituição.

### Recorte geográfico e temporal

O diagnóstico principal utiliza São Paulo, competência novembro de 2025.

Os resultados desse snapshot não devem ser automaticamente generalizados para todo o Brasil ou para outras competências.

Investigações nacionais ou temporais realizadas durante o projeto são utilizadas como análises auxiliares e ficam explicitamente identificadas.

### Defasagem da fonte

O snapshot analisado representa uma competência específica da base.

Resultados relacionados à atualidade são calculados em relação à própria competência de novembro de 2025 para garantir reprodutibilidade.

### Dados pessoais

O projeto utiliza dados de estabelecimentos. Nenhum dado de paciente é utilizado.

O conjunto `br_ms_cnes` contém uma tabela `profissional` com informações pessoais de profissionais de saúde. Essa tabela permanece fora do escopo.

Nenhum dado pessoal dessa tabela é extraído, tratado ou versionado neste repositório.

### Proveniência

O uso de `source="origin"` no PySUS permite reduzir camadas intermediárias durante a investigação da proveniência.

Entretanto, confirmar que determinado valor existe no conjunto disponibilizado pela origem consultada não significa determinar em qual sistema ou processo anterior ele foi originalmente criado.

### Semântica

A presença de um código nos dados não é suficiente para atribuir significado a ele.

O código `tipo_unidade = 16` exemplifica essa diferença:

```text
proveniência confirmada
≠
semântica validada
```

Nenhum significado terminológico será inventado para preencher lacunas durante a transformação FHIR.

### FHIR

O projeto realiza mapeamento e validação de recursos FHIR.

Não envolve submissão à RNDS.

Integração produtiva com a RNDS exigiria requisitos operacionais, de segurança, autenticação e credenciamento que estão fora do escopo deste projeto de portfólio.

### Convenções metodológicas

Alguns critérios utilizados no projeto, como a janela de 24 meses para avaliação de atualidade, são decisões metodológicas próprias.

Eles não são apresentados como normas do DATASUS quando não existe confirmação documental para isso.

---

## Próximos passos

O projeto encontra-se atualmente na **Fase 6 — Interoperabilidade FHIR**.

Próximas atividades:

1. concluir o mapeamento semântico dos campos CNES;
2. definir os campos utilizados em `Organization`;
3. definir os campos utilizados em `Location`;
4. classificar cada correspondência quanto à qualidade do mapeamento;
5. implementar a transformação;
6. gerar exemplos em JSON;
7. executar validação formal FHIR R4;
8. registrar exceções e perdas semânticas;
9. concluir a Fase 6;
10. consolidar a apresentação final do projeto na Fase 7.

---

## Autoria

**Carla Rodrigues de Moraes**

Profissional em formação em Dados para Saúde · Biomedicina + Ciência de Dados e IA
As decisões de escopo, tratamento, qualidade, governança e interoperabilidade deste projeto são documentadas para tornar o processo reproduzível e auditável.

[LinkedIn](https://linkedin.com/in/carla-rodrigues-br) · [GitHub](https://github.com/carla-dados-br)
