# Diagnóstico de Qualidade e Governança de Dados em Estabelecimentos de Saúde (CNES/DATASUS)

> Projeto de portfólio em Dados para Saúde. Autora em formação (Biomedicina + Ciência de Dados e IA), aplicando na prática as competências de Análise de Dados, Governança de Dados e comunicação de achados técnicos em saúde.

## Sobre o projeto

Este projeto usa a base pública do CNES (Cadastro Nacional de Estabelecimentos de Saúde), mantida pelo DATASUS/Ministério da Saúde, para diagnosticar problemas reais de qualidade e fragmentação de dados no setor de saúde brasileiro, e propor uma estrutura de governança para corrigi-los.

O CNES é o cadastro base que sustenta outros sistemas do SUS (SIA, SIH, e-SUS AB) — problemas de qualidade nele se propagam para toda a rede, o que torna esse diagnóstico relevante para qualquer organização de saúde, pública ou privada.

## Perguntas de negócio

- Quais campos críticos do cadastro têm mais problemas de completude (dados ausentes)?
- Qual o percentual de estabelecimentos sem atualização cadastral recente?
- Como a qualidade dos dados varia entre regiões/municípios?

## Recorte do projeto

- **Geográfico:** Estado de São Paulo (SP)
- **Temporal:** competência de novembro/2025
- Justificativa completa em [`docs/decisao-recorte.md`](docs/decisao-recorte.md)

## Status atual

🚧 Em desenvolvimento — Fase 1 (Exploração e extração) em andamento.

- [x] Ambiente configurado (BigQuery Sandbox)
- [x] Estrutura da tabela `estabelecimento` explorada (204 colunas)
- [x] Recorte do projeto definido e validado com dados reais
- [x] Primeira extração de amostra realizada
- [ ] Indicadores de completude calculados
- [ ] Limpeza e tratamento (Python)
- [ ] Dashboard (Power BI)
- [ ] Framework de governança

## Tecnologias

SQL (Google BigQuery), Python (pandas), Power BI, Git.

## Estrutura do repositório

```
├── sql/          queries de extração e exploração
├── python/       scripts de tratamento e limpeza (Fase 2)
├── docs/         decisões documentadas, dicionário de dados, governança
├── dashboard/    arquivos e prints do Power BI (Fase 4)
└── README.md
```

## Fonte de dados

[Base dos Dados](https://basedosdados.org) — dataset público `br_ms_cnes`, acessado via Google BigQuery.

## Autoria

Projeto conduzido em formação, como parte da construção de carreira em Dados para Saúde. Documentação e código produzidos com apoio de mentoria técnica para fins de aprendizado.
