# Diagnóstico de Qualidade e Governança de Dados em Estabelecimentos de Saúde (CNES/DATASUS)

> Projeto de portfólio em Dados para Saúde. Autora em formação (Biomedicina + Ciência de Dados e IA), aplicando na prática análise de dados, medição de qualidade e governança em uma base pública do SUS.

## Sobre o projeto

Este projeto usa a base pública do CNES (Cadastro Nacional de Estabelecimentos de Saúde), mantida pelo DATASUS/Ministério da Saúde, para medir a qualidade do cadastro de estabelecimentos e propor um conjunto mínimo de regras de governança.

O CNES é o cadastro base que sustenta outros sistemas do SUS, entre eles SIA, SIH e e-SUS AB. Inconsistência no CNES não fica nele: se propaga para a rede inteira, e chega em forma de indicador aos gestores que decidem alocação de leitos, distribuição de profissionais e planejamento regional.

A pergunta do projeto é objetiva: quanto do cadastro está incompleto, inconsistente ou desatualizado, e onde.

## Perguntas de negócio

- Quais campos críticos do cadastro têm mais problemas de completude?
- Qual o percentual de estabelecimentos sem atualização cadastral recente?
- Como a qualidade do cadastro varia entre municípios?

Cada indicador calculado precisa responder a uma dessas perguntas. Indicador que não muda nenhuma decisão de gestão não entra no diagnóstico.

## Recorte

- **Geográfico:** Estado de São Paulo
- **Temporal:** competência de novembro de 2025, a mais recente disponível na fonte no momento da extração
- **Fonte:** Base dos Dados, dataset público `br_ms_cnes`, acessado via Google BigQuery

Justificativa completa em [`docs/decisao-recorte.md`](docs/decisao-recorte.md).

## Dimensões de qualidade

O diagnóstico usa quatro dimensões como categorias fixas de análise:

| Dimensão | O que mede |
|---|---|
| Completude | Campos obrigatórios efetivamente preenchidos |
| Consistência | Valores que se contradizem entre campos do mesmo registro |
| Atualidade | Tempo desde a última alteração cadastral |
| Unicidade | Duplicidade de registro para o mesmo estabelecimento |

## Status

Fase 1, exploração e extração, em andamento.

- [x] Ambiente configurado, BigQuery Sandbox
- [x] Estrutura da tabela `estabelecimento` explorada, 204 colunas
- [x] Recorte definido e validado contra dado real
- [x] Primeira extração de amostra
- [ ] Dicionário de dados dos campos selecionados
- [ ] Indicadores de completude calculados
- [ ] Limpeza e tratamento em Python, com log de decisões
- [ ] Indicadores de consistência, atualidade e unicidade
- [ ] Painel publicado
- [ ] Proposta de regras mínimas de governança

## Tecnologias

SQL (Google BigQuery), Python (pandas), Power BI, Git.

## Estrutura do repositório

```
├── sql/          consultas de exploração e extração
├── docs/         decisões documentadas, dicionário de dados e fontes
├── python/       tratamento e cálculo de indicadores (a partir da Fase 2)
├── dashboard/    arquivos e capturas do painel (a partir da Fase 4)
└── README.md
```

## Decisões

As escolhas de escopo, tratamento e interpretação ficam registradas em `docs/`, uma por arquivo, sempre com o motivo e as alternativas descartadas.

Decisão sem justificativa escrita é decisão que ninguém consegue auditar depois, inclusive quem a tomou.

## Limitações declaradas

**O que este projeto mede.** A qualidade do cadastro, não a operação da instituição por trás dele. Um estabelecimento com cadastro completo não é necessariamente bem gerido, e um cadastro incompleto não indica má gestão.

**Alcance do recorte.** São Paulo, uma competência. Diferenças observadas entre municípios valem para este recorte e não devem ser lidas como padrão nacional.

**Defasagem.** A competência mais recente publicada na fonte tem alguns meses de atraso em relação à data da extração. Os achados descrevem o cadastro naquele momento.

**Natureza do dado.** Dado público de estabelecimento, sem qualquer informação de paciente.

Nenhuma conformidade legal ou recomendação clínica é alegada.

## Autoria

**Carla Rodrigues de Moraes**
Profissional em formação em Dados para Saúde · Biomedicina + Ciência de Dados e IA

As decisões de escopo, tratamento e interpretação estão documentadas em `docs/`,
cada uma com a justificativa.

[LinkedIn](https://linkedin.com/in/carla-rodrigues-br) · [GitHub](https://github.com/carla-dados-br)
