# Documento de Resultados — Diagnóstico de Qualidade e Governança de Dados no CNES

## 0. Identificação

_Em construção._

## 1. Resumo executivo

_Em construção._

## 2. Contexto e objetivo

_Em construção._

## 3. Processo estudado

Esta seção descreve o fluxo previsto nas normas e documentos oficiais do CNES, e não o funcionamento prático observado em cada estabelecimento ou esfera de gestão. As etapas anteriores à publicação da base não foram acompanhadas diretamente pelo projeto e são descritas a partir das regras documentadas nas fontes consultadas.

### Origem e responsáveis

O registro de um estabelecimento no CNES nasce no próprio estabelecimento, no momento em que seus dados são cadastrados. Segundo a Portaria GM/MS nº 1.646/2015, incorporada à Portaria de Consolidação GM/MS nº 1/2017, o cadastramento e a manutenção dos dados são de responsabilidade de cada estabelecimento de saúde, por meio de seus responsáveis técnicos ou administrativos. Os profissionais de saúde são corresponsáveis pela exatidão dos próprios dados cadastrais e devem comunicar aos responsáveis pelo cadastramento qualquer alteração em sua situação.

### Caminho até a base nacional

O caminho até a base nacional depende do vínculo do estabelecimento com o SUS. Estabelecimentos que não integram o SUS, entre outros casos previstos no art. 14, inserem seus dados diretamente na base nacional. Já os estabelecimentos integrantes do SUS que não se enquadram nesses casos enviam seus dados à esfera de direção do SUS responsável pelo território, que valida as informações e as encaminha à base nacional, tornando-se corresponsável por elas. Essa validação, porém, pode ser dispensada pelo município ou estado, transferindo ao estabelecimento a responsabilidade pelo envio, ou descentralizada para regionais e distritos sanitários. Em todos os casos, a atualização deve ocorrer com periodicidade mínima mensal ou sempre que houver alguma modificação.

### Da base nacional ao BigQuery

Após a consolidação na base nacional, o DATASUS publica os dados mensalmente em seu FTP público, em arquivos `.dbc` separados por grupo de informação e por unidade da federação. A Base dos Dados baixa esses arquivos e os trata antes de disponibilizá-los no Google BigQuery. Segundo o código público do pipeline, esse tratamento inclui, na tabela de estabelecimentos, a remoção de registros sem código CNES, a eliminação de linhas totalmente repetidas, a padronização dos nomes das colunas e a separação da data original de atualização em ano e mês. Como foi consultada a versão atual do código do pipeline, não é possível afirmar que os dados da competência de novembro de 2025 tenham passado exatamente pelas mesmas transformações e regras hoje presentes no código.

### Ponto de coleta deste diagnóstico

Este diagnóstico utilizou dados públicos do CNES/DATASUS, acessados por meio do conjunto `br_ms_cnes`, disponibilizado pela Base dos Dados e consultado no Google BigQuery. O recorte analisado foi o estado de São Paulo, competência novembro de 2025.

Como os dados foram coletados já após sua disponibilização e tratamento por um intermediário, o diagnóstico consegue medir a qualidade do dado no estado em que ele chegou ao projeto, avaliando completude, consistência, atualidade e unicidade. Porém, o diagnóstico não permite afirmar em qual etapa anterior surgiu uma determinada inconsistência — se no preenchimento realizado pelo estabelecimento, na validação pelas esferas de gestão do SUS, quando aplicável, na consolidação e publicação pelo DATASUS ou no tratamento realizado pela Base dos Dados antes da disponibilização no BigQuery. Por isso, os achados descrevem o dado observado no recorte e não atribuem a origem do problema.

## 4. Dados e método

Os dados e o recorte utilizados estão descritos na seção 3. Esta seção explica o que foi medido, como as medições foram realizadas e de que forma os resultados foram conferidos.

### 4.1 O que foi medido

**Completude:** verifica se as informações estão preenchidas nos casos em que deveriam estar disponíveis. Neste projeto, foi aplicada a cinco campos — região de saúde, município, tipo de unidade, tipo de gestão e CNPJ da mantenedora —, escolhidos durante a exploração inicial da base por parecerem úteis para o diagnóstico e para outras análises do projeto, sem um critério formal definido previamente. Por isso, os resultados de completude descrevem a situação desses cinco campos no recorte analisado, e não a completude de todo o cadastro do CNES.

**Consistência:** verifica se informações relacionadas são compatíveis entre si e se os códigos registrados pertencem às listas de códigos consultadas. Neste projeto, foi aplicada a três regras e a uma verificação dos códigos registrados no campo tipo de unidade; por exemplo, à comparação entre a quantidade total de leitos informada para o estabelecimento e a quantidade de leitos registrada nas habilitações correspondentes, para identificar diferenças que precisassem de investigação.

**Atualidade:** verifica há quanto tempo o cadastro recebeu uma atualização registrada. Neste projeto, foi aplicada à data de atualização dos estabelecimentos, utilizando uma janela metodológica de 24 meses para classificar os registros.

**Unicidade:** verifica se cada estabelecimento aparece de forma única na identificação usada pelo projeto. Neste projeto, foi aplicada ao código CNES do estabelecimento, buscando identificar repetições desse identificador no recorte analisado.

### 4.2 Como foi medido

As medições foram feitas com consultas em SQL sobre a base disponibilizada no Google BigQuery. Para a completude, foram consideradas três formas diferentes de registrar a ausência de informação — campo sem valor, o texto `"nan"` e texto em branco —, porque considerar apenas o campo sem valor, que é a forma detectada pelas verificações usuais, faria registros sem informação parecerem preenchidos e poderia subestimar a incompletude. Para a atualidade, a referência de tempo foi a competência de novembro de 2025, e não a data em que a consulta foi executada, para que o resultado permanecesse vinculado ao período analisado e não mudasse artificialmente com o passar do tempo. Nas regras de consistência, o ano `9999` foi tratado separadamente por representar ausência de data final da habilitação, e as informações de leitos e habilitações foram resumidas a uma linha por estabelecimento antes da comparação, para evitar que estabelecimentos com vários registros fossem contados repetidamente e produzissem resultados inflados.

### 4.3 Como os números foram conferidos

Os resultados de completude e unicidade foram calculados em SQL e refeitos de forma independente em Python. A conferência identificou cinco registros com texto em branco no campo região de saúde que não estavam sendo contabilizados pela consulta SQL. Isso levou à correção da métrica de 54,69% para 54,70%; após a correção, os dois caminhos passaram a apresentar o mesmo resultado. A alteração foi registrada na documentação do projeto.

Os resultados de consistência e atualidade não passaram por essa reprodução independente em Python. Além disso, resultados extremos, como os 100% de divergência encontrados na comparação entre leitos e habilitações, foram investigados antes de serem aceitos como achados, para verificar se representavam um erro confirmado ou uma situação que exigia análise adicional. O resultado dessa investigação é apresentado na seção 5, junto aos demais resultados do diagnóstico.

As consultas, os critérios técnicos de cada medição e o registro das decisões estão listados na seção 9 (Anexos).

## 5. Resultados

### 5.1 Visão geral dos achados

Nota sobre prioridade: A prioridade indica a necessidade de atenção no documento e de controle sobre o dado. Ela não representa gravidade clínica, financeira ou regulatória, porque esses impactos não foram medidos neste projeto.

| ID | Achado | Evidência | Dimensão | Confiança | Prioridade |
|---|---|---|---|---|---|
| A1 | Ausência mascarada em região de saúde | 60.366 de 110.362 (54,70%) | Completude | Fato | **Alta** |
| A5 | Cadastros classificados como desatualizados | 22.868 de 110.362 (20,72%) | Atualidade | Fato segundo critério do projeto | **Alta** |
| A6 | Variação municipal da ausência de região de saúde | 0% a 99,18% em 347 municípios avaliados | Completude | Fato | **Alta** |
| A10 | Valores de `cpf_cnpj` com compatibilidade matemática com CPF | até 34.318 (33.368 + 950) de 98.559 preenchidos | Fora das quatro dimensões — privacidade e governança | Fato; interpretação é hipótese | **Alta** |
| A2 | Valor sentinela nas habilitações | 6.072 de 6.764 (89,77%); 0 vencidas após tratamento | Completude | Fato | **Média** |
| A3 | Divergência entre quantidades de leitos e habilitações | 768 de 768; leitos maiores que habilitações em todos os casos | Consistência | Fato; interpretação é hipótese | **Média** |
| A4 | Leito de UTI sem habilitação correspondente segundo o de-para | 553 de 1.103 combinações (50,1%); 7.312 leitos; universo de 547 estabelecimentos com UTI | Consistência | Fato; interpretação é hipótese | **Média** |
| A8 | Código 16 sem significado semântico confirmado | 5 estabelecimentos; 37 de 38 códigos reconciliados | Consistência | Fato; interpretação é hipótese | **Média** |
| A7 | Ausência de duplicidade do identificador CNES | 0 duplicados em 110.362 registros | Unicidade | Fato | **Baixa** |
| A9 | Completude do CNPJ da mantenedora depende da aplicabilidade | 88,89% vazio bruto; 100% preenchido entre 12.264 mantidos | Completude | Fato | **Baixa** |

### 5.2 Achados detalhados

#### A1 e A6 — Ausência de região de saúde e variação entre municípios

- **Achado:** O campo região de saúde apresenta ausência de informação em mais da metade dos estabelecimentos analisados. A ausência é composta principalmente pelo texto `"nan"`: dos 60.366 registros classificados como ausentes, 60.361 estão representados como `"nan"`, 5 aparecem como texto em branco e nenhum foi identificado como campo sem valor. Isso mostra que a ausência está sendo representada principalmente como um valor textual, e não como um campo nulo convencional.
- **Evidência:** A consulta `sql/03` identificou ausência de região de saúde em 60.366 dos 110.362 estabelecimentos (54,70%). A consulta `sql/09` mostrou que as taxas municipais de ausência variam de 0% a 99,18%. A análise municipal considerou 347 municípios do estado de São Paulo que possuíam pelo menos 20 estabelecimentos na base analisada; esse critério foi utilizado para evitar que municípios com poucos estabelecimentos produzissem proporções extremas que dificultassem a interpretação da variação observada.
- **Dimensão:** Completude.
- **Onde ocorre no processo:** O problema foi observado na base `br_ms_cnes`, disponibilizada pela Base dos Dados e consultada no Google BigQuery, após a publicação e o tratamento intermediário dos dados. Como o projeto não acompanhou diretamente o cadastramento nos estabelecimentos nem todas as etapas anteriores à disponibilização da base, não é possível afirmar em qual etapa a informação deixou de estar disponível ou passou a ser representada como texto.
- **Causa provável (hipótese):** Uma hipótese é que os valores ausentes tenham sido convertidos para o texto `"nan"` em alguma etapa de tratamento ou transformação dos dados. Essa hipótese ainda não foi confirmada. Um caminho possível para investigar a proveniência, já utilizado no projeto para o código 16, é aplicar ao campo região de saúde o mesmo método da Fase 6, com o PySUS e `source="origin"`, verificando se o `"nan"` já está presente na origem ou se aparece posteriormente no processamento.
- **Alcance:** O achado abrange o recorte estadual de São Paulo, com 60.366 estabelecimentos sem região de saúde identificada, e apresenta variação entre os 347 municípios avaliados, cujas taxas de ausência vão de 0% a 99,18%. O projeto mediu a distribuição da ausência, mas não quantificou seus efeitos sobre decisões ou serviços de saúde.
- **Prioridade:** Alta, devido à magnitude da ausência identificada, à grande variação entre municípios e ao fato de que a representação como texto `"nan"` pode não ser reconhecida por verificações convencionais de valores nulos.

#### A5 — Cadastros classificados como desatualizados

- **Achado:** Foram identificados 22.868 estabelecimentos classificados como desatualizados, o que representa 20,72% dos 110.362 estabelecimentos do recorte. Como o projeto não identificou um critério oficial de validade cadastral, a classificação baseou-se em um critério metodológico próprio: foi considerado desatualizado o registro cuja última atualização informada é anterior a 24 meses em relação à competência do arquivo.

- **Evidência:** A consulta `sql/08-atualidade-cadastral.sql` avaliou os campos `ano_atualizacao` e `mes_atualizacao` da tabela `estabelecimento`, tendo como referência a competência do próprio arquivo (2025-11), e não a data de execução da consulta. A janela de 24 meses fixou o corte em 2023-11, mês incluído como atualizado. O cálculo retornou 87.494 registros atualizados (79,28%), 22.868 desatualizados (20,72%) e nenhum registro sem data de atualização informada. O resultado está registrado também em `docs/log-de-queries.md`. A janela de 24 meses é uma convenção analítica adotada para o diagnóstico e não foi confirmada como norma oficial de validade cadastral do DATASUS.

- **Dimensão:** Atualidade.

- **Onde ocorre no processo:** O indicador foi medido sobre a tabela `estabelecimento` da base `br_ms_cnes`. Não é possível afirmar em qual etapa da origem a defasagem se acumula. A consulta também identificou uma anomalia de cronologia: 2.971 estabelecimentos (2,7%) apresentam data de atualização (2025-12) posterior à própria competência do arquivo (2025-11). Pela regra do corte (igual ou posterior a 2023-11), esses registros foram incluídos no grupo de atualizados e não afetam os 20,72% calculados para a desatualização. A anomalia levantou a hipótese de uma defasagem no fluxo de consolidação ou publicação pela fonte, mas essa causa não pôde ser confirmada pelos dados.

- **Causa provável (hipótese):** A ausência de atualização por mais de 24 meses não comprova, isoladamente, que o dado esteja incorreto. As hipóteses principais são: (1) ausência real de alterações físicas, assistenciais ou administrativas que motivassem atualização no período; (2) falha na rotina de manutenção cadastral pelos responsáveis locais; ou (3) encerramento de atividades sem a devida baixa no sistema. O diagnóstico comprova a ausência de atualização registrada, mas não a sua causa operacional.

- **Alcance:** O achado abrange 22.868 estabelecimentos do recorte de São Paulo, competência novembro de 2025, segundo o critério de 24 meses. O número depende diretamente da janela metodológica escolhida e não deve ser extrapolado para outras competências ou Unidades da Federação.

- **Prioridade:** Alta. A classificação justifica-se pela magnitude do achado: mais de um quinto do recorte não registra atualização nos 24 meses anteriores à competência analisada. Esse volume gera incerteza sobre a atualidade das informações de uma parcela expressiva do cadastro, o que justifica a atenção no documento e o acompanhamento do indicador, independentemente dos efeitos que essa defasagem possa ou não causar no planejamento ou nos serviços de saúde.

#### A10 — Valores de `cpf_cnpj` compatíveis com CPF

- **Achado:** O campo `cpf_cnpj` apresenta valores matematicamente compatíveis com o algoritmo de dígitos verificadores do CPF. Dos 98.559 valores preenchidos, 33.368 passaram somente no algoritmo de CPF e 950 passaram nos algoritmos de CPF e de CNPJ. Por isso, o número de valores compatíveis com CPF varia de no mínimo 33.368 (33,86%) a no máximo 34.318 (34,82%), conforme os 950 valores ambíguos sejam ou não considerados. A compatibilidade matemática configura risco potencial de presença de dado pessoal, mas não comprova que os valores sejam CPFs de pessoas físicas.

- **Evidência:** A consulta `sql/15-validacao-cpf_cnpj.sql`, executada em 04/10/2026, reproduz o perfilamento e a validação matemática registrados na Decisão 07 de `docs/mapeamento-cnes-fhir.md`. Dos 110.362 registros do recorte, 11.803 têm o campo vazio e 98.559 estão preenchidos, todos com 14 dígitos; 34.400 começam com o prefixo `000`. O algoritmo de CPF foi aplicado aos últimos 11 dígitos dos valores com esse prefixo, e o algoritmo de CNPJ aos 14 dígitos completos. O resultado foi 33.368 valores compatíveis somente com CPF, 64.241 somente com CNPJ e 950 com ambos. As consultas retornam apenas contagens agregadas, e nenhum valor individual de `cpf_cnpj` foi registrado nos arquivos do projeto.

- **Dimensão:** Fora das quatro dimensões — privacidade e governança. As dimensões do projeto avaliam falta (completude), contradição (consistência), atraso (atualidade) e repetição (unicidade). O achado não descreve nenhuma dessas situações, e sim o risco de privacidade associado ao conteúdo armazenado no campo.

- **Onde ocorre no processo:** O achado foi identificado na base `br_ms_cnes` durante a Fase 6 (mapeamento FHIR) e registrado na Decisão 07. Essa decisão estabeleceu que, nesta versão, não são gerados identificadores FHIR de CPF ou CNPJ: os recursos `Organization` continuam identificados pelo número CNES, conforme a Decisão 01, e o valor original permanece preservado na camada de dados, sujeito a controles de privacidade. O projeto não acompanhou o cadastramento na origem e, portanto, não atribui o padrão observado a uma etapa específica.

- **Causa provável (hipótese):** O nome do campo (`cpf_cnpj`) sugere que ele foi concebido para receber tanto CPF quanto CNPJ, de modo que a presença de valores compatíveis com CPF pode refletir o uso previsto do campo, e não um erro de preenchimento. O padrão observado é coerente com o armazenamento do CPF, de 11 dígitos, completado com zeros à esquerda até 14 dígitos. A hipótese é reforçada pela natureza jurídica: 33.179 (99,43%) dos 33.368 valores compatíveis somente com CPF estão em estabelecimentos com `id_natureza_juridica = 4000`, código que o guia de implementação da SES-GO, publicado como rascunho, associa ao grupo "Pessoas Físicas". Essa associação não deve ser confundida com a finalidade específica do código `400-0` na regulamentação do CNES. A hipótese não explica os 189 valores compatíveis somente com CPF fora da natureza 4000 nem resolve os 950 valores ambíguos.

- **Alcance:** O achado abrange de 33.368 a 34.318 dos 98.559 valores preenchidos de `cpf_cnpj` no recorte de São Paulo, competência novembro de 2025. A validação matemática não comprova existência cadastral, titularidade, situação cadastral nem tipo fiscal efetivo dos documentos. O resultado está restrito ao recorte analisado e não deve ser extrapolado para outras competências ou Unidades da Federação.

- **Prioridade:** Alta. A classificação justifica-se pelo volume de valores compatíveis com CPF, cerca de um terço dos valores preenchidos, em uma base de acesso público, o que representa um risco potencial de presença de dados pessoais. Esse risco justifica a atenção no documento e o cuidado com o campo em todas as etapas que o utilizem, independentemente da confirmação de que os valores correspondam, de fato, a documentos de pessoas físicas.

#### A2 — Valor sentinela nas habilitações

- **Achado:** O campo de competência final (`ano_competencia_final` / `mes_competencia_final`, tabela `habilitacao`) não utiliza um valor ausente (`NULL`) para representar habilitações sem prazo definido, mas sim um valor sentinela que não corresponde a um prazo real. O marcador consistente para esse sentinela é o ano `9999`, presente em 6.072 das 6.764 habilitações (89,77%). O limite do padrão é que o mês associado não é fixo: o ano `9999` aparece combinado com o mês `99` em 6.068 registros e com o mês `9` em 4 ocorrências. Após o tratamento desse marcador, o resultado foi de zero habilitações vencidas.

- **Evidência:** O perfilamento está registrado em `sql/04-consistencia-habilitacao-vencida.sql` e na seção "Habilitação vencida ainda registrada — consistência" do `docs/log-de-queries.md`. As etapas 1 a 6 não possuem data de execução registrada. A etapa 4 aplicou a regra com exclusão do sentinela e forneceu as contagens principais: 6.072 registros com ano `9999` e 692 com data definida. A etapa 5 confirmou que a competência final mínima é 202511, comprovando que o resultado de zero vencidas (obtido na etapa 4) é genuíno. A etapa 7 (executada em 31/10/2026) verificou que o mês `99` só ocorre associado ao ano `9999`, mas que o mês associado ao ano `9999` varia entre `99` e `9`.

- **Dimensão:** Completude. O achado surgiu na construção de uma regra de consistência, mas descreve uma ausência mascarada, e não uma contradição entre campos. O uso do ano `9999` oculta o fato de que a habilitação não possui um prazo de validade definido, da mesma forma que o `"nan"` atua na ausência de região de saúde (achado A1). Se aceito de forma bruta, o sentinela inflaria falsamente a completude do campo com informações que não representam datas reais.

- **Onde ocorre no processo:** O padrão foi identificado na Fase 3 (Indicadores e regras de consistência). O tratamento exigiu a exclusão explícita do ano `9999` antes de calcular a regra de habilitação vencida. O projeto não acompanhou o cadastramento na origem e, portanto, não atribui o padrão observado a uma etapa específica.

- **Causa provável (hipótese):** O registro de um ano futuro extremado (`9999`) sugere o uso de uma convenção sistêmica pela origem para designar habilitações de prazo indeterminado. Essa interpretação foi deduzida pelo comportamento dos dados, sem confirmação na documentação oficial da fonte. A hipótese de convenção sistemática não explica, porém, por que 4 dos registros apresentam o mês `9`.

- **Alcance:** O sentinela afeta 6.072 (89,77%) das 6.764 habilitações no recorte de São Paulo (competência novembro/2025). O resultado de zero vencidas foi medido sobre o universo de 692 registros com data definida. O diagnóstico é estrito a este recorte e não deve ser extrapolado.

- **Prioridade:** Média. Diferente do A1, em que o `"nan"` mascarava a ausência de uma informação estrutural para o planejamento (a região de saúde), a ausência de prazo de validade em uma habilitação pode refletir uma situação cadastral legítima, como habilitações sem prazo de vencimento, apenas registrada de forma inadequada, e não necessariamente uma falha na coleta do dado. Além disso, diferente do A10, não há risco de privacidade. O tratamento (isolar o sentinela) não bloqueia o projeto; ele exige manter a exclusão nos cálculos e o monitoramento previsto na Regra 1 de `docs/framework-governanca.md`, para evitar que o sentinela distorça cálculos temporais e dilua o percentual de vencidas.

#### A3 — Divergência entre quantidade de leitos e habilitações

- **Achado:** A quantidade total de leitos informada é sistematicamente maior do que a quantidade de leitos habilitados para o mesmo estabelecimento. A divergência afeta 100% dos 768 estabelecimentos avaliados e, em todos os casos, `leito` > `habilitacao`. As diferenças variam de 1 a 1.309 leitos por unidade, com uma média de 97,88.

- **Evidência:** O diagnóstico está documentado na seção "Divergência de quantidade de leitos — consistência" do `docs/log-de-queries.md` (linha 314) e operacionalizado em `sql/05-consistencia-divergencia-leitos.sql`. A etapa 4 da query (linhas 82–118) consolidou o volume (768 de 768 estabelecimentos divergentes). A etapa 5 (linhas 121–157) provou a direção positiva constante e calculou os valores de mínimo (1), máximo (1.309) e a média (97,88) — sendo que a média foi calculada exclusivamente na `sql/05` (linha 152), não estando presente na query resumida do log. Nenhum dos dois arquivos possui data de execução registrada para essas etapas.

- **Dimensão:** Consistência. O achado mantém essa classificação porque nasceu da aplicação de uma regra de consistência cruzada entre fontes. No entanto, se a hipótese de que os campos medem conceitos diferentes se confirmar, não existirá uma inconsistência real nos dados, mas sim uma falta de definição documentada sobre as regras de negócio de cada tabela.

- **Onde ocorre no processo:** A divergência materializa-se na relação entre o volume de leitos declarados e a quantidade de leitos registrada nas habilitações. O projeto não acompanhou o cadastramento na origem e, portanto, não atribui o padrão observado a uma etapa de preenchimento específica.

- **Causa provável (hipótese):** O fato de a divergência ser sistemática, direcional e atingir todos os casos observados é compatível com a hipótese de que os campos medem conceitos diferentes (por exemplo, capacidade física instalada vs. cota de financiamento). Contudo, o mesmo padrão também poderia refletir um preenchimento sistematicamente incompleto do campo de habilitações. A interpretação de conceitos diferentes é uma dedução do comportamento analítico e não foi verificada junto à fonte.

- **Alcance:** O achado incide sobre 768 estabelecimentos. Este número não representa a totalidade das unidades de saúde de São Paulo em nov/2025, mas exclusivamente o subconjunto de estabelecimentos que registraram presença simultânea nas duas tabelas (`INNER JOIN`).

- **Prioridade:** Média. Assim como o A2, esse achado expõe um padrão estrutural que, se interpretado diretamente como erro, poluiria os indicadores de qualidade do projeto com possíveis falsos positivos de inconsistência. A diferença fundamental é que, no A2, os dados permitiram um tratamento técnico imediato (a exclusão do sentinela 9999) para isolar o problema. No A3, não há filtro ou tratamento matemático aplicável que corrija a divergência antes que o significado real dos campos seja esclarecido junto à fonte.

#### A4 — Leito de UTI sem habilitação correspondente segundo o de-para

- **Achado:** Das 1.103 combinações estabelecimento + categoria de UTI do recorte, 553 (50,1%) não apresentam habilitação de UTI correspondente segundo o de-para construído pelo projeto. Essas combinações somam 7.312 dos 16.301 leitos de UTI do recorte (44,86%). As 1.103 combinações pertencem a 547 estabelecimentos com algum tipo de UTI cadastrado; o número de estabelecimentos com pelo menos uma combinação sem habilitação não foi calculado.

- **Evidência:** A regra está em `sql/06-consistencia-uti-sem-habilitacao.sql`, etapa 8 (linhas 168–239), que produziu 1.103, 553 e 7.312. O valor 547 vem da linha 235 (`total_estabelecimentos_com_uti`), que conta todos os estabelecimentos com UTI, sem condição de ausência de habilitação. O de-para está documentado nas linhas 81–107, e a validação empírica dos sinônimos está nas etapas 6 e 7 (linhas 110–165): 2610 confirmado em 96 de 98 estabelecimentos e 2611 em 28 de 28. O registro está na seção "Leito de UTI sem habilitação correspondente — consistência" do `docs/log-de-queries.md` (linha 352). As etapas 1 a 8 não possuem data de execução registrada. A etapa 9 (linhas 242–265, executada em 01/11/2026) verificou que cada um dos 12 códigos de UTI aparece com um único `tipo_leito`; com isso, o agrupamento apenas por especialidade não altera o resultado, apesar da decisão técnica registrada no log (linha 184). O total de 16.301 leitos vem dessa etapa.

- **Dimensão:** Consistência. O achado resulta de uma regra de correspondência entre duas tabelas (`leito` e `habilitacao`) do mesmo estabelecimento. A classificação depende de duas condições não verificadas: que o de-para represente corretamente a relação entre os dois domínios de código e que todo leito de UTI cadastrado deva ter uma habilitação correspondente. Se alguma delas não se confirmar, parte das 553 combinações deixa de ser inconsistência no dado e passa a ser efeito do método.

- **Onde ocorre no processo:** Na relação entre o cadastramento dos leitos de UTI e o registro das habilitações do mesmo estabelecimento, que são campos de domínios de código diferentes e sem chave de correspondência oficial entre si. O projeto não acompanhou o cadastramento na origem e, portanto, não atribui o padrão observado a uma etapa de preenchimento específica.

- **Causa provável (hipótese):** O resultado é compatível com pelo menos três explicações, que os dados analisados não permitem distinguir: (1) leitos de UTI cadastrados sem a habilitação formal correspondente registrada; (2) limitações do de-para, construído por semelhança textual e validação empírica, e não por uma tabela oficial de correspondência — como o de-para exige o mesmo tipo (I, II ou III) nos dois lados (linha 86), um estabelecimento com habilitação de outro tipo para a mesma UTI é contado como "sem habilitação"; (3) a premissa de que todo leito de UTI exige habilitação, que não foi verificada. Nenhuma dessas explicações foi verificada junto à fonte.

- **Alcance:** 553 combinações e 7.312 leitos (44,86% dos leitos de UTI do recorte), dentro de um universo de 547 estabelecimentos com UTI, em São Paulo (competência novembro/2025). Os códigos de habilitação 2612, 2613, 2699, 8217 e 8218 não ocorrem no recorte (`sql/06`, linhas 102–106); em outros recortes, o de-para precisaria ser revisto. O diagnóstico não deve ser extrapolado.

- **Prioridade:** Média. Comparado ao A3, que também é Consistência com interpretação em hipótese, o A4 tem maior relevância assistencial, porque trata de leitos de terapia intensiva em nível de categoria. No entanto, a força da sua evidência é menor: o A3 compara dois campos diretamente, enquanto o A4 depende de um de-para construído pelo próprio projeto. Assim como no A3, e diferente do A2, não há tratamento técnico que resolva o achado antes de esclarecer com a fonte o significado da correspondência. A prioridade não sobe para Alta porque a força da recomendação não pode exceder a força da evidência.

#### A9 — Completude do CNPJ da mantenedora depende da aplicabilidade

- **Achado:** O campo `cnpj_mantenedora` apresenta 98.098 registros vazios, correspondentes a 88,89% dos 110.362 estabelecimentos analisados. Entretanto, o vazio bruto não representa, por si só, uma falha de completude, pois o preenchimento do campo depende da situação cadastral do estabelecimento. A análise identificou que os registros vazios correspondem aos estabelecimentos classificados como `tipo_grau_dependencia = 1` (Individual), enquanto os registros classificados como `tipo_grau_dependencia = 3` (Mantida) apresentam o CNPJ da mantenedora preenchido.

- **Evidência:** A análise identificou 98.098 registros sem `cnpj_mantenedora` e 12.264 registros com CNPJ válido de 14 dígitos, correspondentes a 743 mantenedoras distintas. O cruzamento com `tipo_grau_dependencia` apresentou exatamente duas combinações: `1` (Individual) associado a CNPJ vazio em 98.098 registros e `3` (Mantida) associado a CNPJ preenchido em 12.264 registros. A correspondência foi confirmada linha a linha. Entre os 12.264 estabelecimentos classificados como Mantidos, portanto, a completude observada do campo foi de 100%.

- **Dimensão:** Completude.

- **Onde ocorre no processo:** O achado foi identificado na análise da base `br_ms_cnes`, durante a avaliação da completude do campo `cnpj_mantenedora`. A investigação mostrou que a interpretação da ausência depende da classificação `tipo_grau_dependencia`. O projeto não acompanhou diretamente o processo operacional de cadastramento de cada estabelecimento e, portanto, não atribui o comportamento observado a uma etapa específica de origem.

- **Causa provável:** Não foi identificada uma inconsistência de preenchimento entre os registros em que o campo é aplicável. A elevada proporção de vazios no total geral decorre da inclusão, na mesma métrica, de estabelecimentos classificados como Individuais, para os quais o CNPJ da mantenedora não se aplica. Assim, o principal risco identificado é metodológico: calcular a completude do campo sobre o total geral do recorte, sem considerar sua regra de aplicabilidade, produziria uma interpretação incorreta da qualidade dos dados.

- **Alcance:** O achado abrange os 110.362 estabelecimentos de São Paulo na competência de novembro de 2025. No total geral, foram observados 98.098 registros vazios (88,89%) e 12.264 preenchidos (11,11%). Considerando somente o universo em que o campo é aplicável, formado pelos 12.264 estabelecimentos classificados como Mantidos, a completude observada foi de 100%. O resultado está restrito ao recorte analisado e não deve ser extrapolado automaticamente para outras competências ou Unidades da Federação.

- **Prioridade:** Baixa. A classificação decorre do fato de que não foi identificada ausência de `cnpj_mantenedora` entre os estabelecimentos classificados como Mantidos no recorte analisado. O principal ponto de atenção é preservar a regra de negócio na definição e no monitoramento do indicador, evitando que estabelecimentos para os quais o campo não se aplica sejam tratados como registros incompletos.

## 6. Recomendações e controles

_Em construção._

## 7. Limitações e premissas

_Em construção._

## 8. Próximos passos

_Em construção._

## 9. Anexos técnicos

_Em construção._
