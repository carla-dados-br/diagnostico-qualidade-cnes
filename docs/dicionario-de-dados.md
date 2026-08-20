# Dicionário de Dados — Projeto CNES

Registro dos campos analisados na tabela `basedosdados.br_ms_cnes.estabelecimento`, recorte SP + competência 2025-11.

Para cada campo: tipo de dado, o que representa, e como valores ausentes se manifestam na prática (nem sempre como `NULL`).

---

## `id_regiao_saude`

- **Tipo:** STRING
- **O que representa:** código da região de saúde à qual o estabelecimento está vinculado, usado para planejamento e alocação de recursos regionais.
- **Padrão de ausência identificado:** o campo não usa `NULL` para representar ausência de valor. Em vez disso, parte dos registros traz o texto literal `"nan"` armazenado como string.
- **Impacto:** uma verificação de completude baseada apenas em `IS NULL` retorna 0% de incompletude neste campo — resultado enganoso. A verificação correta precisa somar `IS NULL` **e** `= 'nan'`.
- **Hipótese de causa:** provável resíduo de um processo de tratamento de dados (ex.: exportação via pandas/Python, onde `NaN` é a representação padrão de ausência) que converteu o valor ausente em texto antes de gravar na base, em vez de preservá-lo como nulo.
- **Métrica de completude (SP, nov/2025):**

  | Total de estabelecimentos | Incompletos (NULL + "nan") | % Incompleto |
  |---|---|---|
  | 110.362 | 60.361 | 54,69% |

- **Query de referência:** ver `sql/03-completude-id_regiao_saude.sql`
- **Recomendação de tratamento (Fase 2):** ao limpar os dados em Python, converter explicitamente o texto `"nan"` para `NULL`/`NaN` reconhecido pelo pandas, antes de qualquer cálculo de completude ou agregação.

---

*Próximos campos a documentar: demais colunas de identificação e localização usadas nos indicadores (completude, atualidade, consistência).*
