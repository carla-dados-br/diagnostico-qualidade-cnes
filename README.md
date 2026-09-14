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

O diagnóstico usa quatro dimensões como categorias fixas de análise. As quatro já têm pelo menos um indicador calculado.

| Dimensão | O que mede | Status |
|---|---|---|
| Completude | Campos obrigatórios efetivamente preenchidos | 2 campos medidos |
| Consistência | Valores que se contradizem entre campos ou entre tabelas | 3 regras concluídas |
| Atualidade | Tempo desde a última alteração cadastral | Concluída |
| Unicidade | Se cada estabelecimento aparece uma única vez no recorte | Concluída |

## Regras de consistência aplicadas

Três regras, escolhidas para cobrir níveis técnicos distintos — todas concluídas:

| Regra | Tabelas | O que exige | Status |
|---|---|---|---|
| Habilitação com competência final vencida ainda registrada | `habilitacao` | comparação de datas dentro da tabela | Concluída |
| Divergência de quantidade de leitos entre `leito` e `habilitacao` | `leito` + `habilitacao` | junção com agregação prévia | Concluída |
| Leito de UTI cadastrado sem habilitação correspondente | `leito` + `habilitacao` | junção e critério clínico de correspondência (de-para semântico validado empiricamente) | Concluída |

A definição de quais habilitações correspondem a cada tipo de UTI é decisão clínica, não técnica, e fica justificada na documentação.

## Achados até aqui

A verificação da estrutura do conjunto, feita antes de a análise começar, já produziu problemas de qualidade documentados:

- Dado pessoal de profissional de saúde presente em base pública
- Quantidade de leitos registrada em duas tabelas diferentes, sem garantia de que coincidam
- Campos indicadores com tipos de dado diferentes entre tabelas do mesmo conjunto
- Códigos ambíguos no dicionário oficial: valores distintos com o mesmo significado declarado

Detalhamento em [`docs/achados-verificacao-estrutura.md`](docs/achados-verificacao-estrutura.md).

A aplicação dos indicadores e das regras de consistência revelou achados adicionais, com investigação completa em [`docs/dicionario-de-dados.md`](docs/dicionario-de-dados.md):

- **Nulo mascarado como texto.** O campo `id_regiao_saude` não usa `NULL` para representar ausência de valor — usa o texto literal `"nan"`. Uma checagem baseada só em `IS NULL` indicava 0% de incompletude; a checagem correta revelou 54,69%.
- **Sentinela de prazo indeterminado.** Em `habilitacao`, 89,76% dos registros usam `ano_competencia_final = 9999` para representar "sem prazo definido", em vez de um campo nulo. A regra de habilitação vencida precisou excluir esse sentinela antes de comparar datas.
- **Divergência sistemática entre fontes.** Nenhum dos 768 estabelecimentos avaliáveis tem `leito.quantidade_total` igual a `habilitacao.quantidade_leitos`. A divergência é sempre na mesma direção (leito ≥ habilitação), o que sugere que os dois campos medem conceitos diferentes, não erro aleatório de digitação.
- **Metade dos leitos de UTI sem habilitação correspondente.** 553 de 1.103 combinações estabelecimento+categoria de UTI (50,1%) não têm habilitação formal correspondente, totalizando 7.312 leitos. O de-para entre os códigos de leito e de habilitação foi validado empiricamente, não apenas por nome parecido.
- **Um campo genuinamente completo.** `tipo_unidade` apresentou 0% de incompletude, testado contra três formas de ausência (nulo, texto "nan", string vazia) e confirmado por inspeção prévia dos 38 valores distintos em uso — diferente dos zeros enganosos encontrados em outros campos.
- **Um em cada cinco estabelecimentos desatualizado.** Usando uma janela de 24 meses anteriores à própria competência do arquivo (não à data de execução da análise, para manter o indicador reproduzível), 20,72% dos estabelecimentos não tiveram atualização cadastral recente.
- **Disparidade municipal real, mas não bimodal.** A incompletude de `id_regiao_saude` varia de 0% (ex.: Osvaldo Cruz) a mais de 99% (ex.: Caieiras) entre municípios de porte comparável. A hipótese inicial de dois grupos opostos foi testada contra a distribuição completa e rejeitada: os 347 municípios avaliados se espalham pelas quatro faixas de incompletude, sem concentração em extremos.

## Status

Fase 1 concluída. Fase 3 concluída — as quatro dimensões de qualidade (completude, consistência, atualidade, unicidade) têm ao menos um indicador calculado e documentado. Fase 2 concluída para os indicadores de completude e unicidade — pipeline formal em Python (`python/fase2-limpeza-tratamento.ipynb`) reproduzindo, com paridade confirmada, os resultados já validados em SQL; duas divergências reais entre SQL e Python foram encontradas e corrigidas no processo (tipo de `id_municipio`, métrica de `id_regiao_saude`). Reprodução das 3 regras de consistência e do indicador de atualidade em Python (tabelas `leito` e `habilitacao`) fica como extensão futura, fora do escopo desta etapa. Fase 4 concluída — três gráficos publicados no Power BI Service (completude por campo, atualidade cadastral, distribuição regional), exportados como PDF e versionados em `dashboard/`. Cada gráfico ficou em um relatório separado, devido à limitação da versão Web do Power BI em mesclar múltiplas fontes de dados sem o Desktop. Fase 5 concluída — framework de governança com 9 regras (`docs/framework-governanca.md`), cada uma rastreável a um achado real do projeto, distinguindo explicitamente fato confirmado de hipótese pendente de validação.

- [x] Ambiente configurado, BigQuery Sandbox
- [x] Estrutura da tabela `estabelecimento` explorada, 204 colunas
- [x] Recorte definido e validado contra dado real
- [x] Estrutura do conjunto verificada: 14 tabelas, chaves de junção e granularidade
- [x] Escopo revisado a partir da estrutura real ([versão 2](docs/projeto-portfolio-cnes-qualidade-dados-v2.md))
- [x] Indicadores de completude: `id_regiao_saude` (54,69% incompleto), `tipo_unidade` (0%, verificado)
- [x] Regra de consistência: habilitação vencida ainda registrada
- [x] Regra de consistência: divergência de quantidade de leitos entre fontes
- [x] Regra de consistência: leito de UTI sem habilitação correspondente
- [x] Indicador de atualidade cadastral (20,72% desatualizado, corte de 24 meses documentado)
- [x] Indicador de distribuição regional (disparidade municipal documentada, extensão de completude)
- [x] Indicadores de completude: `id_municipio` (100%), `tipo_gestao` (100%, domínio observado menor que o esperado), `cnpj_mantenedora` (100% completo entre estabelecimentos "Mantidos"; 88,89% vazio bruto, ausência esperada por regra de negócio)
- [x] Indicador de unicidade (0 duplicados em `id_estabelecimento_cnes`, 110.362 registros)
- [x] Limpeza e tratamento formal em Python (`python/fase2-limpeza-tratamento.ipynb`), com paridade SQL×Python confirmada para completude e unicidade
- [x] Painel publicado (3 gráficos: completude por campo, atualidade cadastral, distribuição regional)
- [ ] Proposta de regras mínimas de governança
- [ ] Mapeamento validado para recursos FHIR

## Tecnologias

SQL (Google BigQuery), Python (pandas), Power BI, Git, FHIR.

## Estrutura do repositório

```
├── sql/
│   ├── 01-exploracao-fase1.sql
│   ├── 02-verificacao-estrutura.sql
│   ├── 03-completude-id_regiao_saude.sql
│   ├── 04-consistencia-habilitacao-vencida.sql
│   ├── 05-consistencia-divergencia-leitos.sql
│   ├── 06-consistencia-uti-sem-habilitacao.sql
│   ├── 07-completude-tipo_unidade.sql
│   ├── 08-atualidade-cadastral.sql
│   └── 09-distribuicao-regional.sql
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

**Convenções metodológicas próprias.** Alguns cortes (como a janela de 24 meses do indicador de atualidade) são decisões deste projeto, não definições normativas do DATASUS. Cada convenção está documentada com sua justificativa em `docs/dicionario-de-dados.md`.

Nenhuma conformidade legal ou recomendação clínica é alegada.

## Autoria

**Carla Rodrigues de Moraes**
Profissional em formação em Dados para Saúde · Biomedicina + Ciência de Dados e IA

As decisões de escopo, tratamento e interpretação estão documentadas em `docs/`,
cada uma com a justificativa.

[LinkedIn](https://linkedin.com/in/carla-rodrigues-br) · [GitHub](https://github.com/carla-dados-br)
