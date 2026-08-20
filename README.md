# Diagnóstico de Qualidade e Governança de Dados em Estabelecimentos de Saúde (CNES/DATASUS)

> Projeto de portfólio em Dados para Saúde. Autora em formação (Biomedicina + Ciência de Dados e IA), aplicando na prática análise de dados, medição de qualidade, governança e interoperabilidade em uma base pública do SUS.

## Sobre o projeto

Este projeto usa a base pública do CNES (Cadastro Nacional de Estabelecimentos de Saúde), mantida pelo DATASUS/Ministério da Saúde, para medir a qualidade do cadastro de estabelecimentos e propor um conjunto mínimo de regras de governança. Ao final, os dados tratados são mapeados para os recursos FHIR `Organization` e `Location`.

O CNES é o cadastro base que sustenta outros sistemas do SUS, entre eles SIA, SIH e e-SUS AB. Inconsistência no CNES não fica nele: se propaga para a rede inteira, e chega em forma de indicador aos gestores que decidem alocação de leitos, distribuição de profissionais e planejamento regional.

A pergunta do projeto é objetiva: quanto do cadastro está incompleto, inconsistente ou desatualizado, e onde.

## Perguntas de negócio

- Quais campos críticos do cadastro têm mais problemas de completude?
- Qual o percentual de estabelecimentos sem atualização cadastral recente?
- Como a qualidade do cadastro varia entre municípios?

Cada indicador calculado precisa responder a uma dessas perguntas. Indicador que não muda nenhuma decisão de gestão não entra no diagnóstico.

## Recorte

- **Geográfico:** Estado de São Paulo
- **Temporal:** competência de novembro de 2025
- **Fonte:** Base dos Dados, dataset público `br_ms_cnes`, acessado via Google BigQuery

Justificativa completa em [`docs/decisao-recorte.md`](docs/decisao-recorte.md).

## Dimensões de qualidade

O diagnóstico usa quatro dimensões como categorias fixas de análise:

| Dimensão | O que mede |
|---|---|
| Completude | Campos obrigatórios efetivamente preenchidos |
| Consistência | Valores que se contradizem entre campos ou entre tabelas |
| Atualidade | Tempo desde a última alteração cadastral |
| Unicidade | Duplicidade de registro para o mesmo estabelecimento |

## Regras de consistência aplicadas

Três regras, escolhidas para cobrir níveis técnicos distintos:

| Regra | Tabelas | O que exige |
|---|---|---|
| Habilitação com competência final vencida ainda registrada | `habilitacao` | comparação de datas dentro da tabela |
| Divergência de quantidade de leitos entre `leito` e `habilitacao` | `leito` + `habilitacao` | junção com agregação prévia |
| Leito de UTI cadastrado sem habilitação correspondente | `leito` + `habilitacao` | junção e critério clínico de correspondência |

A definição de quais habilitações correspondem a cada tipo de UTI é decisão clínica, não técnica, e fica justificada na documentação.

## Achados até aqui

A verificação da estrutura do conjunto, feita antes de a análise começar, já produziu problemas de qualidade documentados:

- Dado pessoal de profissional de saúde presente em base pública
- Quantidade de leitos registrada em duas tabelas diferentes, sem garantia de que coincidam
- Campos indicadores com tipos de dado diferentes entre tabelas do mesmo conjunto
- Códigos ambíguos no dicionário oficial: valores distintos com o mesmo significado declarado

Detalhamento em [`docs/achados-verificacao-estrutura.md`](docs/achados-verificacao-estrutura.md).

## Status

Fase 1 concluída. Fase 2 em preparação.

- [x] Ambiente configurado, BigQuery Sandbox
- [x] Estrutura da tabela `estabelecimento` explorada, 204 colunas
- [x] Recorte definido e validado contra dado real
- [x] Primeira extração de amostra
- [x] Estrutura do conjunto verificada: 14 tabelas, chaves de junção e granularidade
- [x] Escopo revisado a partir da estrutura real ([versão 2](docs/projeto-portfolio-cnes-qualidade-dados-v2.md))
- [ ] Dicionário de dados derivado da tabela oficial
- [ ] Limpeza e tratamento em Python, com log de decisões
- [ ] Indicadores de completude, atualidade e unicidade
- [ ] Três regras de consistência aplicadas
- [ ] Painel publicado
- [ ] Proposta de regras mínimas de governança
- [ ] Mapeamento validado para recursos FHIR

## Tecnologias

SQL (Google BigQuery), Python (pandas), Power BI, Git, FHIR.

## Estrutura do repositório

```
├── sql/          consultas de exploração, verificação e extração
├── docs/         decisões documentadas, achados, dicionário de dados e escopo
├── python/       tratamento e cálculo de indicadores (a partir da Fase 2)
├── dashboard/    arquivos e capturas do painel (a partir da Fase 4)
└── README.md
```

## Decisões

As escolhas de escopo, tratamento e interpretação ficam registradas em `docs/`, uma por arquivo, sempre com o motivo e as alternativas descartadas.

Decisão sem justificativa escrita é decisão que ninguém consegue auditar depois, inclusive quem a tomou.

O documento de escopo tem histórico de versões. A versão 2 registra o que mudou depois que a estrutura real do conjunto foi verificada, incluindo uma premissa do planejamento inicial que se mostrou errada.

## Limitações declaradas

**O que este projeto mede.** A qualidade do cadastro, não a operação da instituição por trás dele. Um estabelecimento com cadastro completo não é necessariamente bem gerido, e um cadastro incompleto não indica má gestão.

**Alcance do recorte.** São Paulo, uma competência. Diferenças observadas entre municípios valem para este recorte e não devem ser lidas como padrão nacional.

**Defasagem.** A competência mais recente publicada na fonte tem alguns meses de atraso em relação à data da extração. Os achados descrevem o cadastro naquele momento.

**Natureza do dado.** O projeto usa dados de estabelecimento, sem qualquer informação de paciente.

O conjunto `br_ms_cnes` contém uma tabela `profissional` com nome, cartão nacional de saúde e município de residência — dado pessoal de profissional de saúde em base pública. Essa tabela ficou fora do escopo desta versão. Nenhum dado pessoal é extraído, tratado ou versionado neste repositório. A decisão está registrada em `docs/`.

**Alcance do mapeamento FHIR.** O projeto mapeia dados para recursos FHIR e valida o resultado. Não envolve submissão à RNDS, que exige certificação digital e credenciais indisponíveis em projeto de portfólio.

Nenhuma conformidade legal ou recomendação clínica é alegada.

## Autoria

**Carla Rodrigues de Moraes**
Profissional em formação em Dados para Saúde · Biomedicina + Ciência de Dados e IA

As decisões de escopo, tratamento e interpretação estão documentadas em `docs/`,
cada uma com a justificativa.

[LinkedIn](https://linkedin.com/in/carla-rodrigues-br) · [GitHub](https://github.com/carla-dados-br)
