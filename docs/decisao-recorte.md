# Decisão de Recorte — Projeto CNES/DATASUS

## Recorte definido

- **Geográfico:** Estado de São Paulo (SP)
- **Temporal (competência):** novembro/2025 (`ano = 2025`, `mes = 11`)

## Justificativa

**Geográfico (SP):** escolhido em vez de Brasil inteiro para reduzir o volume de dados na fase de tratamento local (Python/pandas) e permitir validação manual dos resultados ("conferir no olho"), já que é a região onde a autora do projeto reside e tem contexto prático.

**Temporal (novembro/2025):** o CNES é atualizado mensalmente, mas sofre defasagem de divulgação — a competência mais recente disponível na base nem sempre é a mais confiável, pois pode ainda estar em processo de consolidação.

Antes de escolher, foi feita uma verificação com dados reais, contando o total de estabelecimentos por competência nos últimos meses de 2025:

| Competência | Total de estabelecimentos |
|---|---|
| 2025-12 | 470.360 |
| 2025-11 | 471.254 |
| 2025-10 | 470.397 |
| 2025-09 | 469.214 |
| 2025-08 | 465.866 |

Novembro/2025 apresentou o maior volume de estabelecimentos da série recente, indicando ser o mês mais consolidado disponível (dezembro apresentou queda leve, compatível com dado ainda em consolidação, mas não descartada por completo). Por isso, novembro/2025 foi escolhido como competência de referência do projeto.

## Query usada na verificação

```sql
SELECT ano, mes, COUNT(*) AS total_estabelecimentos
FROM `basedosdados.br_ms_cnes.estabelecimento`
WHERE ano = 2025 AND mes >= 8
GROUP BY ano, mes
ORDER BY ano DESC, mes DESC
```

## Conceitos-chave já validados nesta fase

- **`ano`/`mes`**: competência de referência do CNES (o "retrato" mensal).
- **`ano_atualizacao`/`mes_atualizacao`**: data da última alteração cadastral do estabelecimento — campo-chave para o indicador de "desatualização", objetivo central do projeto.
- Tabela fonte: `basedosdados.br_ms_cnes.estabelecimento` (204 colunas).

## Origem

Fonte: [Base dos Dados](https://basedosdados.org) — dataset público `br_ms_cnes`, acessado via Google BigQuery (Sandbox, projeto `storied-shore-480202-t4`).
