# Investigação de Proveniência — `tipo_unidade = 16`

## Contexto

Durante a preparação do mapeamento CNES → FHIR, foi identificado o valor
`tipo_unidade = 16` em registros da tabela
`basedosdados.br_ms_cnes.estabelecimento`.

O recorte principal do projeto permanece:

- Estado: São Paulo
- Competência: novembro de 2025
- Total de estabelecimentos: 110.362

O objetivo desta investigação foi responder a duas perguntas distintas:

1. O valor `16` foi introduzido pela transformação da Base dos Dados ou já
   está presente na origem consultada?
2. O significado semântico do código `16` está documentado e pode ser
   utilizado com segurança em um mapeamento FHIR?

Essas perguntas correspondem, respectivamente, a proveniência do dado e
validação semântica.

---

## 1. Detecção da anomalia

No recorte SP + novembro/2025 foram encontrados 38 códigos distintos de
`tipo_unidade`.

Ao comparar os valores observados com a tabela
`basedosdados.br_ms_cnes.dicionario`:

- 37 códigos possuíam correspondência;
- o código `16` não possuía correspondência;
- 5 estabelecimentos apresentavam `tipo_unidade = 16`.

CNES afetados no recorte:

- `4932609`
- `5767032`
- `5828953`
- `9340459`
- `9570365`

A ausência de correspondência no dicionário não foi interpretada
automaticamente como código inválido. O valor foi tratado como anomalia
semântica pendente de investigação.

---

## 2. Investigação temporal dos cinco estabelecimentos

Foi analisado o histórico de `tipo_unidade` dos cinco CNES.

Transições observadas:

| CNES | Tipo anterior | Entrada do código `16` |
|---|---|---|
| `4932609` | `22` | 2025-11 |
| `5767032` | `36` | 2025-11 |
| `5828953` | `4` | 2025-10 |
| `9340459` | `22` | 2025-09 |
| `9570365` | `2` | 2025-09 |

O CNES `5767032` apresentou posteriormente a sequência:

`36 → 16 → 36`

Esse comportamento demonstra que, nesse estabelecimento, o código `16`
não funcionou como substituição permanente do código anterior.

O dado não permite determinar a causa dessa transição. Reclassificação
temporária, correção cadastral, mudança de regra ou outra causa permanecem
como hipóteses não confirmadas.

---

## 3. Abrangência nacional

Foi investigada a ocorrência de `tipo_unidade = 16` no conjunto nacional
a partir de janeiro de 2024.

Dentro do período pesquisado, as primeiras ocorrências foram observadas em
setembro de 2025.

| Competência | Estabelecimentos | UFs |
|---|---:|---:|
| 2025-09 | 10 | 7 |
| 2025-10 | 21 | 9 |
| 2025-11 | 43 | 15 |
| 2025-12 | 54 | 15 |
| 2026-01 | 59 | 16 |
| 2026-02 | 86 | 18 |

O padrão observado é recente, crescente e distribuído entre múltiplas UFs.

Isso sustenta a conclusão de que o fenômeno não é exclusivamente paulista
nem restrito a um único estabelecimento ou município.

Os dados, entretanto, não permitem determinar em qual processo anterior da
cadeia o código foi originalmente criado nem qual é o seu significado.

---

## 4. Teste de proveniência

Para verificar se o valor poderia ter sido introduzido pela transformação da
Base dos Dados, foi realizada uma comparação com a origem consultada por meio
do PySUS.

### Ambiente

A máquina do projeto utiliza:

- Debian GNU/Linux 11
- Python 3.9.2 no host

Como o PySUS atual exige uma versão de Python mais recente, a ferramenta foi
executada em ambiente Docker isolado, preservando o Python do sistema.

Ferramenta utilizada:

- Docker
- imagem `alertadengue/pysus`
- PySUS 2.11.1

### Consulta

Foi utilizada a função CNES do namespace `pysus.ftp` com:

- `state="SP"`
- `year=2025`
- `month=11`
- `group="ST"`
- `source="origin"`
- `as_dataframe=True`

O retorno utilizado na comparação apresentou:

- arquivo materializado pelo PySUS: `STSP2511.parquet`
- 110.362 registros
- 208 colunas

Os campos relevantes da origem consultada foram:

- `CNES`
- `TP_UNID`

Correspondência utilizada na investigação:

| Origem consultada | Base dos Dados |
|---|---|
| `CNES` | `id_estabelecimento_cnes` |
| `TP_UNID` | `tipo_unidade` |

---

## 5. Resultado da comparação

Os cinco estabelecimentos foram encontrados na origem consultada.

| CNES | `TP_UNID` | Competência |
|---|---:|---:|
| `4932609` | `16` | `202511` |
| `5767032` | `16` | `202511` |
| `5828953` | `16` | `202511` |
| `9340459` | `16` | `202511` |
| `9570365` | `16` | `202511` |

Total encontrado: 5 de 5.

Para esses cinco estabelecimentos e para a competência novembro de 2025,
o valor `16` já está presente no conjunto obtido do servidor de origem
consultado pelo PySUS.

Não foi encontrada evidência de que a transformação observada entre essa
origem e a Base dos Dados tenha introduzido ou alterado o valor `16`.

Essa conclusão se refere à proveniência observada nesta comparação. Ela não
determina em qual sistema ou processo anterior ao arquivo disponibilizado
o código foi originalmente criado.

---

## 6. Conclusão semântica

O teste de proveniência não resolveu o significado do código `16`.

Até o encerramento desta investigação:

- o código ocorre nos dados;
- está presente na origem consultada;
- não possui correspondência no dicionário utilizado no projeto;
- seu significado oficial não foi confirmado;
- sua equivalência com outro código não foi confirmada;
- não foi confirmado um sistema terminológico que permita representá-lo
  como conceito validado no FHIR.

Portanto, proveniência confirmada não significa semântica validada.

---

## 7. Impacto no mapeamento FHIR

Enquanto a semântica e o sistema terminológico do código `16` permanecerem
não confirmados, ele não deve receber `coding.display` inferido nem ser
tratado como um mapeamento terminológico validado em `Organization.type`.

A ausência de significado confirmado deve permanecer explícita no processo
de transformação.

Nenhum rótulo será fabricado para tornar o recurso FHIR aparentemente mais
completo.

---

## Classificação do achado

- **Dimensão:** Consistência / Governança semântica
- **Campo:** `tipo_unidade`
- **Código:** `16`
- **Registros afetados no recorte principal:** 5 de 110.362
- **Cobertura do domínio observado:** 37 de 38 códigos com correspondência no dicionário
- **Proveniência:** confirmada na origem consultada
- **Semântica:** não resolvida
- **Impacto FHIR:** exceção terminológica
- **Status:** documentado; não bloqueia a continuidade do projeto, desde que tratado explicitamente
