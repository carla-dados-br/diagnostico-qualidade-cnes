# Documento de Resultados — Diagnóstico de Qualidade e Governança de Dados no CNES

## 0. Identificação

| Campo | Informação |
|---|---|
| Projeto | Diagnóstico de Qualidade e Governança de Dados em Estabelecimentos de Saúde (CNES/DATASUS) |
| Natureza | Projeto de portfólio, sem cliente. Os dados são públicos e reais, não sintéticos. |
| Fonte | CNES/DATASUS, conjunto `br_ms_cnes` da Base dos Dados, consultado no Google BigQuery |
| Recorte | São Paulo (SP), competência novembro de 2025, 110.362 estabelecimentos |
| Versão | 1.0, novembro de 2026 |
| Status | Finalizado |
| Responsável | Carla (`carla-dados-br`), que acumula os papéis de dona do dado, analista e revisora |
| Repositório | https://github.com/carla-dados-br/diagnostico-qualidade-cnes |

## 1. Resumo executivo

**Pergunta.** Em que medida o cadastro de estabelecimentos do CNES de São Paulo, em novembro de 2025, é completo, consistente, atual e único?

**Resposta.** O identificador dos estabelecimentos é único, mas mais da metade dos cadastros não informa a região de saúde, um em cada cinco não registra alteração no cadastro há mais de 24 meses e, nos leitos de UTI do SUS, toda categoria cadastrada tem a habilitação correspondente.

**Principais achados** (110.362 estabelecimentos):

1. **Região de saúde ausente** em 60.366 estabelecimentos (54,70%). A ausência aparece como o texto `"nan"`, que verificações comuns de campo vazio não detectam, e varia de 0% a 99,18% entre municípios (A1, A6).
2. **Cadastros sem alteração registrada:** 22.868 estabelecimentos (20,72%) sem alteração cadastral registrada há mais de 24 meses, segundo critério do projeto. O dado não indica, por si só, descumprimento da regra de desativação da Portaria SAS/MS nº 118/2014 (A5).
3. **Possível dado pessoal em base pública:** até 34.318 dos 98.559 valores preenchidos de `cpf_cnpj` são compatíveis com CPF (A10).
4. **Leitos de UTI do SUS com habilitação:** as 550 combinações estabelecimento + categoria de UTI com leitos SUS têm a habilitação correspondente; as 553 sem habilitação têm só leitos não SUS (A4). Na comparação agregada entre leitos e habilitações, restrita às habilitações que têm leitos, só 1 de 304 estabelecimentos tem mais leitos habilitados do que leitos SUS (A3).
5. **Prazo final não informado:** 6.072 de 6.764 habilitações (89,77%) usam o ano `9999` no lugar de uma data (A2).

**Impacto.** O impacto financeiro, clínico ou regulatório dos achados não foi medido neste projeto.

**Recomendações prioritárias.**

1. Tratar `"nan"` e texto em branco como ausência antes de qualquer indicador que use a região de saúde (R1).
2. Restringir `cpf_cnpj` a resultados agregados, sem publicar valores individuais (R5).
3. Cruzar leitos e habilitações só com leitos SUS e por categoria de leito, como no A4, e não pela comparação agregada (R7, R8).

**Decisão pedida ao leitor.** Validar com a área responsável pelo CNES as interpretações listadas na seção 7.2, incluindo o corte de 24 meses. Até essa validação, os achados A2, A3 e A8 devem ser lidos como evidência para investigação, e não como erro confirmado.

## 2. Contexto e objetivo

**Problema.** Gestores decidem sobre leitos, profissionais e planejamento regional com base em cadastros que podem estar incompletos, desatualizados ou inconsistentes. O CNES é a base cadastral que sustenta outros sistemas do SUS, como SIA, SIH e e-SUS AB; problemas de qualidade nele se propagam para esses sistemas.

**Pergunta do projeto.** Em que medida o cadastro de estabelecimentos do CNES de São Paulo, em novembro de 2025, é completo, consistente, atual e único, e quais controles reduziriam os problemas encontrados?

**Objetivos.**

- Medir completude, consistência, atualidade e unicidade do cadastro de estabelecimentos.
- Aplicar três regras de consistência baseadas na estrutura real do CNES, uma delas dependente de conhecimento clínico (leito de UTI e habilitação).
- Propor regras mínimas de governança, com responsáveis e indicadores.
- Mapear os dados para FHIR R4, com validação. O escopo inicial previa os recursos `Organization` e `Location`; a versão entregue gera apenas `Organization` (seção 5.3).

**Fora do escopo.** A tabela `profissional`, por conter dado pessoal (nome, cartão nacional de saúde e município de residência); o envio de dados à RNDS; modelos preditivos; a integração com sistemas hospitalares; e a correção dos dados na fonte.

**Leitores.** Gestores de saúde municipais e estaduais, equipes de dados de operadoras e hospitais e pesquisadores em saúde pública.

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

**Atualidade:** verifica há quanto tempo o cadastro não registra alteração. Neste projeto, foi aplicada à data de atualização dos estabelecimentos (`ano_atualizacao` e `mes_atualizacao`), utilizando uma janela metodológica de 24 meses para classificar os registros. Essa janela não corresponde à regra oficial de desativação, que trata da transmissão à base nacional (Portaria SAS/MS nº 118/2014; ver A5).

**Unicidade:** verifica se cada estabelecimento aparece de forma única na identificação usada pelo projeto. Neste projeto, foi aplicada ao código CNES do estabelecimento, buscando identificar repetições desse identificador no recorte analisado.

### 4.2 Como foi medido

As medições foram feitas com consultas em SQL sobre a base disponibilizada no Google BigQuery. Para a completude, foram consideradas três formas diferentes de registrar a ausência de informação — campo sem valor, o texto `"nan"` e texto em branco —, porque considerar apenas o campo sem valor, que é a forma detectada pelas verificações usuais, faria registros sem informação parecerem preenchidos e poderia subestimar a incompletude. Para a atualidade, a referência de tempo foi a competência de novembro de 2025, e não a data em que a consulta foi executada, para que o resultado permanecesse vinculado ao período analisado e não mudasse artificialmente com o passar do tempo. Nas regras de consistência, o ano `9999` foi tratado separadamente por representar ausência de data final da habilitação, e as informações de leitos e habilitações foram resumidas a uma linha por estabelecimento antes da comparação, para evitar que estabelecimentos com vários registros fossem contados repetidamente e produzissem resultados inflados.

### 4.3 Como os números foram conferidos

Os resultados de completude e unicidade foram calculados em SQL e refeitos de forma independente em Python. A conferência identificou cinco registros com texto em branco no campo região de saúde que não estavam sendo contabilizados pela consulta SQL. Isso levou à correção da métrica de 54,69% para 54,70%; após a correção, os dois caminhos passaram a apresentar o mesmo resultado. A alteração foi registrada na documentação do projeto.

Os resultados de consistência e atualidade não passaram por essa reprodução independente em Python. Além disso, resultados extremos foram investigados antes de serem aceitos como achados. No caso dos 100% de divergência entre leitos e habilitações, a primeira investigação não identificou que a regra somava habilitações sem leitos; isso foi detectado na auditoria de 02/11/2026, e o resultado corrigido está no A3. Os resultados dessas investigações são apresentados na seção 5, junto aos demais resultados do diagnóstico.

As consultas, os critérios técnicos de cada medição e o registro das decisões estão listados na seção 9 (Anexos).

## 5. Resultados

### 5.1 Visão geral dos achados

Nota sobre prioridade: A prioridade indica a necessidade de atenção no documento e de controle sobre o dado. Ela não representa gravidade clínica, financeira ou regulatória, porque esses impactos não foram medidos neste projeto.

| ID | Achado | Evidência | Dimensão | Confiança | Prioridade |
|---|---|---|---|---|---|
| A1 | Ausência mascarada em região de saúde | 60.366 de 110.362 (54,70%) | Completude | Fato | **Alta** |
| A6 | Variação municipal da ausência de região de saúde | 0% a 99,18% em 347 municípios avaliados | Completude | Fato | **Alta** |
| A10 | Valores de `cpf_cnpj` com compatibilidade matemática com CPF | até 34.318 (33.368 + 950) de 98.559 preenchidos | Fora das quatro dimensões — privacidade e governança | Fato; interpretação é hipótese | **Alta** |
| A5 | Cadastros sem alteração registrada há mais de 24 meses | 22.868 de 110.362 (20,72%); 50.785 (46,02%) sem alteração há mais de 6 meses | Atualidade | Fato segundo critério do projeto; significado do campo é hipótese | **Média** |
| A2 | Valor sentinela nas habilitações | 6.072 de 6.764 (89,77%); 0 vencidas após tratamento | Completude | Fato | **Média** |
| A8 | Código 16 de `tipo_unidade` sem significado semântico confirmado | 5 de 110.362 estabelecimentos; 37 de 38 códigos presentes no ValueSet FHIR e na tabela `dicionario` | Consistência | Fato; interpretação é hipótese | **Média** |
| A4 | Correspondência entre leitos de UTI do SUS e habilitações | 550 de 550 combinações com leitos SUS têm habilitação; as 553 sem habilitação têm só leitos não SUS | Consistência | Fato | **Baixa** |
| A3 | Comparação agregada entre leitos e habilitações | 304 estabelecimentos com habilitação de leitos; 1 com mais leitos habilitados do que leitos SUS | Consistência | Fato; interpretação é hipótese | **Baixa** |
| A7 | Ausência de duplicidade do identificador CNES | 0 duplicados em 110.362 registros | Unicidade | Fato | **Baixa** |
| A9 | Completude do CNPJ da mantenedora depende da aplicabilidade | 88,89% vazio bruto; 100% preenchido entre 12.264 mantidos | Completude | Fato | **Baixa** |

### 5.2 Achados detalhados

#### A1 e A6 — Ausência de região de saúde e variação entre municípios

- **Achado:** O campo região de saúde apresenta ausência de informação em mais da metade dos estabelecimentos analisados. A ausência é composta principalmente pelo texto `"nan"`: dos 60.366 registros classificados como ausentes, 60.361 estão representados como `"nan"`, 5 aparecem como texto em branco e nenhum foi identificado como campo sem valor. Isso mostra que a ausência está sendo representada principalmente como um valor textual, e não como um campo nulo convencional.

- **Evidência:** A consulta `sql/03` identificou ausência de região de saúde em 60.366 dos 110.362 estabelecimentos (54,70%). A consulta `sql/09` mostrou que as taxas municipais de ausência variam de 0% a 99,18%. A análise municipal considerou 347 municípios do estado de São Paulo que possuíam pelo menos 20 estabelecimentos na base analisada; esse critério foi utilizado para evitar que municípios com poucos estabelecimentos produzissem proporções extremas que dificultassem a interpretação da variação observada.

- **Dimensão:** Completude.

- **Onde ocorre no processo:** O problema foi observado na base `br_ms_cnes`, disponibilizada pela Base dos Dados e consultada no Google BigQuery, após a publicação e o tratamento intermediário dos dados. Como o projeto não acompanhou diretamente o cadastramento nos estabelecimentos nem todas as etapas anteriores à disponibilização da base, não é possível afirmar em qual etapa a informação deixou de estar disponível ou passou a ser representada como texto.

- **Causa provável (hipótese):** Uma hipótese é que os valores ausentes tenham sido convertidos para o texto `"nan"` em alguma etapa de tratamento ou transformação dos dados. Essa hipótese não foi verificada: o projeto não testou se o `"nan"` já está presente na origem dos dados.

- **Alcance:** O achado abrange o recorte estadual de São Paulo, com 60.366 estabelecimentos sem região de saúde identificada, e apresenta variação entre os 347 municípios avaliados, cujas taxas de ausência vão de 0% a 99,18%. O projeto mediu a distribuição da ausência, mas não quantificou seus efeitos sobre decisões ou serviços de saúde.

- **Prioridade:** Alta, devido à magnitude da ausência identificada, à grande variação entre municípios e ao fato de que a representação como texto `"nan"` pode não ser reconhecida por verificações convencionais de valores nulos.

#### A10 — Valores de `cpf_cnpj` compatíveis com CPF

- **Achado:** O campo `cpf_cnpj` apresenta valores matematicamente compatíveis com o algoritmo de dígitos verificadores do CPF. Dos 98.559 valores preenchidos, 33.368 passaram somente no algoritmo de CPF e 950 passaram nos algoritmos de CPF e de CNPJ. Por isso, o número de valores compatíveis com CPF varia de no mínimo 33.368 (33,86%) a no máximo 34.318 (34,82%), conforme os 950 valores ambíguos sejam ou não considerados. A compatibilidade matemática configura risco potencial de presença de dado pessoal, mas não comprova que os valores sejam CPFs de pessoas físicas.

- **Evidência:** A consulta `sql/15-validacao-cpf_cnpj.sql`, executada em 04/10/2026, reproduz o perfilamento e a validação matemática registrados na Decisão 07 de `docs/mapeamento-cnes-fhir.md`. Dos 110.362 registros do recorte, 11.803 têm o campo vazio e 98.559 estão preenchidos, todos com 14 dígitos; 34.400 começam com o prefixo `000`. O algoritmo de CPF foi aplicado aos últimos 11 dígitos dos valores com esse prefixo, e o algoritmo de CNPJ aos 14 dígitos completos. O resultado foi 33.368 valores compatíveis somente com CPF, 64.241 somente com CNPJ e 950 com ambos. As consultas retornam apenas contagens agregadas, e nenhum valor individual de `cpf_cnpj` foi registrado nos arquivos do projeto.

- **Dimensão:** Fora das quatro dimensões — privacidade e governança. As dimensões do projeto avaliam falta (completude), contradição (consistência), atraso (atualidade) e repetição (unicidade). O achado não descreve nenhuma dessas situações, e sim o risco de privacidade associado ao conteúdo armazenado no campo.

- **Onde ocorre no processo:** O achado foi identificado na base `br_ms_cnes` durante a Fase 6 (mapeamento FHIR) e registrado na Decisão 07. Essa decisão estabeleceu que, nesta versão, não são gerados identificadores FHIR de CPF ou CNPJ: os recursos `Organization` continuam identificados pelo número CNES, conforme a Decisão 01, e o valor original permanece preservado na camada de dados, sujeito a controles de privacidade. O projeto não acompanhou o cadastramento na origem e, portanto, não atribui o padrão observado a uma etapa específica.

- **Causa provável (hipótese):** O nome do campo (`cpf_cnpj`) sugere que ele foi concebido para receber tanto CPF quanto CNPJ, de modo que a presença de valores compatíveis com CPF pode refletir o uso previsto do campo, e não um erro de preenchimento. O padrão observado é coerente com o armazenamento do CPF, de 11 dígitos, completado com zeros à esquerda até 14 dígitos. A hipótese é reforçada pela natureza jurídica: 33.179 (99,43%) dos 33.368 valores compatíveis somente com CPF estão em estabelecimentos com `id_natureza_juridica = 4000`, código que o guia de implementação da SES-GO, publicado como rascunho, associa ao grupo "Pessoas Físicas". Essa associação não deve ser confundida com a finalidade específica do código `400-0` na regulamentação do CNES. A hipótese não explica os 189 valores compatíveis somente com CPF fora da natureza 4000 nem resolve os 950 valores ambíguos.

- **Alcance:** O achado abrange de 33.368 a 34.318 dos 98.559 valores preenchidos de `cpf_cnpj` no recorte de São Paulo, competência novembro de 2025. A validação matemática não comprova existência cadastral, titularidade, situação cadastral nem tipo fiscal efetivo dos documentos. O resultado está restrito ao recorte analisado e não deve ser extrapolado para outras competências ou Unidades da Federação.

- **Prioridade:** Alta. A classificação justifica-se pelo volume de valores compatíveis com CPF, cerca de um terço dos valores preenchidos, em uma base de acesso público, o que representa um risco potencial de presença de dados pessoais. Esse risco justifica a atenção no documento e o cuidado com o campo em todas as etapas que o utilizem, independentemente da confirmação de que os valores correspondam, de fato, a documentos de pessoas físicas.

#### A5 — Cadastros sem alteração registrada há mais de 24 meses

- **Achado:** 22.868 dos 110.362 estabelecimentos do recorte (20,72%) não registram alteração cadastral nos 24 meses anteriores à competência do arquivo; 50.785 (46,02%) não registram alteração nos 6 meses anteriores. A Portaria SAS/MS nº 118/2014 manda desativar automaticamente os estabelecimentos há mais de 6 meses sem atualização cadastral, mas define atualização como a exportação e transmissão sem rejeição da base local para a nacional, mesmo sem alteração de dados. Pelo resultado, o campo usado pelo projeto indica a data da última alteração do cadastro, e não a dessa transmissão. Por isso, o indicador mede tempo sem alteração registrada, e não o descumprimento da regra de desativação.

- **Evidência:** `sql/08-atualidade-cadastral.sql`, etapa 5 (sem data de execução registrada): 87.494 registros (79,28%) com última alteração em 2023-11 ou depois, 22.868 (20,72%) antes de 2023-11 e nenhum sem data. A referência é a competência do arquivo (2025-11), e não a data de execução da consulta. A etapa 6, executada em 02/11/2026, depois da auditoria do projeto, contou 50.785 registros (46,02%) com última alteração antes de 2025-05 e mostrou que a tabela não tem coluna de situação ou de desativação. O resultado está também no `docs/log-de-queries.md` (linha 510, com nota datada). Norma: Portaria SAS/MS nº 118/2014, art. 1º, §§ 1º e 3º.

- **Dimensão:** Atualidade, entendida como tempo desde a última alteração registrada no cadastro.

- **Onde ocorre no processo:** O indicador foi medido sobre a tabela `estabelecimento` da base `br_ms_cnes`. Não é possível afirmar em qual etapa da origem a defasagem se acumula. A consulta também identificou uma anomalia de cronologia: 2.971 estabelecimentos (2,7%) apresentam data de atualização (2025-12) posterior à própria competência do arquivo (2025-11). Pela regra do corte (igual ou posterior a 2023-11), esses registros foram incluídos no grupo de atualizados e não afetam os 20,72% calculados para a desatualização. A anomalia levantou a hipótese de uma defasagem no fluxo de consolidação ou publicação pela fonte, mas essa causa não pôde ser confirmada pelos dados.

- **Causa provável (hipótese):** A ausência de alteração por mais de 24 meses não comprova, isoladamente, que o dado esteja incorreto. As hipóteses principais são: (1) ausência real de mudanças físicas, assistenciais ou administrativas no período; (2) falha na rotina de manutenção cadastral pelos responsáveis locais; ou (3) encerramento de atividades sem a devida baixa no sistema. Que o campo registre a última alteração, e não a transmissão, é dedução a partir do resultado: a definição do campo não foi confirmada na fonte, e não foi verificado se o arquivo publicado inclui estabelecimentos desativados.

- **Alcance:** 22.868 estabelecimentos do recorte de São Paulo, competência novembro de 2025, segundo o critério de 24 meses; 50.785 segundo a janela de 6 meses. Os números dependem da janela escolhida e não devem ser extrapolados para outras competências ou Unidades da Federação.

- **Prioridade:** Média. Mais de um quinto do recorte não registra alteração há mais de 24 meses, o que justifica acompanhar o indicador. Como o campo não mede a transmissão exigida pela portaria, porém, cadastro sem alteração não equivale a cadastro desatualizado: o estabelecimento pode transmitir todo mês sem mudar nada. Como o A2, o A5 aponta um risco a acompanhar, sem erro comprovado.

#### A2 — Valor sentinela nas habilitações

- **Achado:** O campo de competência final (`ano_competencia_final` / `mes_competencia_final`, tabela `habilitacao`) não utiliza um valor ausente (`NULL`) para representar habilitações sem prazo definido, mas sim um valor sentinela que não corresponde a um prazo real. O marcador consistente para esse sentinela é o ano `9999`, presente em 6.072 das 6.764 habilitações (89,77%). O limite do padrão é que o mês associado não é fixo: o ano `9999` aparece combinado com o mês `99` em 6.068 registros e com o mês `9` em 4 ocorrências. Após o tratamento desse marcador, o resultado foi de zero habilitações vencidas.

- **Evidência:** O perfilamento está registrado em `sql/04-consistencia-habilitacao-vencida.sql` e na seção "Habilitação vencida ainda registrada — consistência" do `docs/log-de-queries.md`. As etapas 1 a 6 não possuem data de execução registrada. A etapa 4 aplicou a regra com exclusão do sentinela e forneceu as contagens principais: 6.072 registros com ano `9999` e 692 com data definida. A etapa 5 confirmou que a competência final mínima é 202511, comprovando que o resultado de zero vencidas (obtido na etapa 4) é genuíno. A etapa 7 (executada em 31/10/2026) verificou que o mês `99` só ocorre associado ao ano `9999`, mas que o mês associado ao ano `9999` varia entre `99` e `9`.

- **Dimensão:** Completude. O achado surgiu na construção de uma regra de consistência, mas descreve uma ausência mascarada, e não uma contradição entre campos. O uso do ano `9999` oculta o fato de que a habilitação não possui um prazo de validade definido, da mesma forma que o `"nan"` atua na ausência de região de saúde (achado A1). Se aceito de forma bruta, o sentinela inflaria falsamente a completude do campo com informações que não representam datas reais.

- **Onde ocorre no processo:** O sentinela já está presente na tabela `habilitacao` disponibilizada pela Base dos Dados, ou seja, foi registrado antes da coleta do projeto: no cadastramento, na consolidação pelo DATASUS ou no tratamento intermediário. O projeto não acompanhou o cadastramento na origem e, portanto, não atribui o padrão observado a uma etapa específica.

- **Causa provável (hipótese):** O registro de um ano futuro extremado (`9999`) sugere o uso de uma convenção sistêmica pela origem para designar habilitações de prazo indeterminado. Essa interpretação foi deduzida pelo comportamento dos dados e não foi verificada junto à fonte. A hipótese de convenção sistemática não explica, porém, por que 4 dos registros apresentam o mês `9`.

- **Alcance:** O sentinela afeta 6.072 (89,77%) das 6.764 habilitações no recorte de São Paulo (competência novembro/2025). O resultado de zero vencidas foi medido sobre o universo de 692 registros com data definida. O diagnóstico é estrito a este recorte e não deve ser extrapolado.

- **Prioridade:** Média. Diferente do A1, em que o `"nan"` mascarava a ausência de uma informação estrutural para o planejamento (a região de saúde), a ausência de prazo de validade em uma habilitação pode refletir uma situação cadastral legítima, como habilitações sem prazo de vencimento, apenas registrada de forma inadequada, e não necessariamente uma falha na coleta do dado. Além disso, diferente do A10, não há risco de privacidade. O tratamento (isolar o sentinela) não bloqueia o projeto; ele exige manter a exclusão nos cálculos e o monitoramento previsto na Regra 1 de `docs/framework-governanca.md`, para evitar que o sentinela distorça cálculos temporais e dilua o percentual de vencidas.

#### A8 — Código 16 de `tipo_unidade` sem significado semântico confirmado

- **Achado:** O código `16` aparece no campo `tipo_unidade` em 5 estabelecimentos do recorte, mas seu significado não está documentado em nenhuma das duas referências consultadas: a tabela `dicionario` da Base dos Dados e o ValueSet FHIR `BRTipoEstabelecimentoSaude` (versão 1.1.0). Dos 38 códigos observados no recorte, é o único sem correspondência nas duas.

- **Evidência:** Presença no ValueSet: `sql/16`, resultados 1 e 2 (linhas 58–80; resultados registrados nas linhas 101–111), executada em 2026-10-04: 37 de 38 códigos presentes; o `16` ocorre em 5 estabelecimentos. Correspondência com a tabela `dicionario`: `sql/07`, etapas 1 e 2 (linhas 22–44), por comparação manual entre as duas listas, sem data de execução registrada. Histórico e ocorrência nacional: a query original não foi versionada; a `sql/19` é uma reprodução independente, executada em 2026-10-04, que chegou aos mesmos números registrados em `docs/investigacao-proveniencia-tipo-unidade-16.md` (seções 2 e 3). Presença na origem: mesmo documento, seções 4 e 5 (PySUS 2.11.1, `source="origin"`), sem script versionado e sem data registrada. Log de queries, nota na linha 432.

- **Dimensão:** Consistência, entendida como consistência do valor com o domínio de referência do campo. O campo está 100% preenchido no recorte (`sql/07`, etapa 3), por isso o problema não é de completude. Se o `16` for um código válido ainda não documentado nas fontes consultadas, a inconsistência não está no dado, e sim na documentação de referência.

- **Onde ocorre no processo:** O valor já está presente nos mesmos 5 estabelecimentos no arquivo da origem consultada (CNES/ST/SP/2025-11, obtido pelo PySUS com `source="origin"`), e não foi encontrada evidência de que a transformação da Base dos Dados o tenha introduzido. O problema surge, portanto, antes da publicação desse arquivo, no cadastramento ou no processamento da origem. O teste não determina em qual dessas etapas, e o projeto não acompanhou o cadastramento na origem.

- **Causa provável (hipótese):** O padrão é compatível com uma alteração na origem, e não com uma ocorrência isolada: na janela de 2024-01 a 2026-02, o código aparece pela primeira vez em 2025-09 e passa de 10 estabelecimentos em 7 UFs para 86 em 18 UFs; os 5 estabelecimentos de SP vieram de tipos diferentes (22, 36, 4 e 2), e um deles voltou ao tipo anterior (36 → 16 → 36). Os dados não distinguem entre explicações alternativas: código novo ainda não incorporado às referências consultadas, uso indevido do código no cadastramento ou reclassificação temporária. A interpretação não foi verificada junto à fonte. A ausência no ValueSet versão 1.1.0, ativo desde 2026-08-22, não prova que o código não tivesse significado oficial em 2025-11.

- **Alcance:** No recorte, 5 de 110.362 estabelecimentos (cerca de 0,005%). A contagem equivale a estabelecimentos porque não há duplicidade de `id_estabelecimento_cnes` no recorte (A7). Fora do recorte, 43 estabelecimentos em 15 UFs na mesma competência (2025-11) e 86 em 18 UFs em 2026-02. O universo nacional de estabelecimentos não foi calculado, por isso não há percentual nacional.

- **Prioridade:** Média. A evidência do fato é forte (duas referências, presença na origem e histórico reproduzido), mas o alcance no recorte é pequeno. Fica em Média, e não em Baixa, porque o código não tem significado conhecido, afeta diretamente a classificação do estabelecimento e o mapeamento FHIR (`Organization.type`), e cresce em escala nacional. Já existe tratamento técnico: o projeto não atribui rótulo ao código no FHIR, o que limita o impacto dentro do projeto, mas não resolve o problema no dado.

#### A4 — Correspondência entre leitos de UTI do SUS e habilitações

- **Achado:** Todas as 550 combinações estabelecimento + categoria de UTI com leitos SUS têm a habilitação correspondente segundo o de-para do projeto. As 553 combinações sem habilitação (50,1% das 1.103 do recorte, com 7.312 leitos, em 298 estabelecimentos) são exatamente as que têm zero leitos SUS, ou seja, são formadas só por leitos não SUS. A habilitação 2602, extinta pela Portaria SAES/MS nº 2.902/2025, ainda aparece em 1 estabelecimento.

- **Evidência:** `sql/06`, etapa 10, executada em 02/11/2026, depois da auditoria do projeto. Ela reproduz o resultado original da etapa 8 (1.103 combinações, 553 sem habilitação, 7.312 leitos e 547 estabelecimentos com UTI) e acrescenta a contagem por leitos SUS: 550 combinações com leitos SUS, 0 sem habilitação; 7.346 leitos SUS de UTI, 0 sem habilitação; 281 estabelecimentos com UTI SUS. O de-para está nas linhas 81–107 da `sql/06`, e a validação empírica de 2610 e 2611, nas etapas 6 e 7 (linhas 110–165). A correspondência oficial entre tipo de leito e habilitação está nas Portarias SAES/MS nº 2.902/2025 e nº 3.511/2025 (coluna "habilitação relacionada aos leitos SUS"); o de-para do projeto coincide com ela nas categorias que ela cobre, inclusive 2610 e 2611 como habilitações dos leitos 81 e 82. A presença da 2602 vem da `sql/05`, etapa 7. O registro original está no `docs/log-de-queries.md` (linha 352), com nota datada na linha 403.

- **Dimensão:** Consistência. A regra testa a correspondência entre duas tabelas do mesmo estabelecimento. Nos leitos SUS, para os quais a correspondência é definida, não há inconsistência no recorte.

- **Onde ocorre no processo:** Na relação entre o cadastro dos leitos de UTI e o registro das habilitações do mesmo estabelecimento. O projeto não acompanhou o cadastramento na origem.

- **Causa provável (hipótese):** As combinações sem habilitação são compatíveis com UTIs que atendem só fora do SUS, para as quais as portarias consultadas não definem habilitação. A presença da 2602 depois da extinção é compatível com defasagem na atualização do cadastro. Nenhuma das duas interpretações foi verificada junto à fonte.

- **Alcance:** 1.103 combinações em 547 estabelecimentos com UTI, em São Paulo (competência novembro/2025): 550 combinações com leitos SUS, em 281 estabelecimentos, todas com habilitação; 553 só com leitos não SUS, em 298 estabelecimentos. A Portaria SAES/MS nº 3.511/2025, publicada em 24/11/2025, altera a tabela a partir da competência seguinte; em outros recortes, o de-para precisa ser revisto. Os códigos 2612, 2613, 2699, 8217 e 8218 não ocorrem no recorte (`sql/06`, linhas 102–106).

- **Prioridade:** Baixa. Como o A7 e o A9, o A4 confirma que o dado atende ao critério testado. Sua relevância está em mostrar que o de-para do projeto, construído antes da consulta às portarias, reproduz a correspondência oficial nos leitos SUS, e em afastar a leitura de que metade das UTIs estaria sem habilitação. O caso da 2602 é pontual e fica registrado para acompanhamento.

#### A3 — Comparação agregada entre leitos e habilitações

- **Achado:** A comparação original somava a quantidade de leitos de todas as habilitações do estabelecimento, inclusive as que não envolvem leitos, e apontava divergência em 768 de 768 estabelecimentos. Restrita às habilitações que têm leitos, a comparação abrange 304 estabelecimentos. O total de leitos cadastrados é maior que o de leitos habilitados em todos eles, o que é esperado, porque o total inclui leitos que não dependem de habilitação e leitos não SUS. Em relação aos leitos SUS, 299 estabelecimentos têm mais leitos SUS do que habilitados, 4 têm o mesmo número e 1 tem 18 leitos habilitados a mais do que leitos SUS cadastrados.

- **Evidência:** `sql/05`, etapas 6 a 8, executadas em 02/11/2026, depois da auditoria do projeto. A etapa 6 mostrou que 464 dos 768 estabelecimentos da comparação original (60,4%) tinham total habilitado igual a 0, porque só possuíam habilitações sem leitos. A etapa 7 mostrou que só 18 dos 191 tipos de habilitação do recorte têm leitos (803 registros e 9.307 leitos habilitados). A etapa 8 aplicou a comparação restrita a esses tipos (critério empírico `quantidade_leitos > 0`) e produziu os números do achado; a diferença entre leitos SUS e leitos habilitados vai de −18 a 1.242, com média de 123,5. O resultado original (etapas 4 e 5, sem data de execução registrada) está preservado, com nota datada, na `sql/05` (linha 84) e no `docs/log-de-queries.md` (linha 336).

- **Dimensão:** Consistência, restrita ao único caso em que há mais leitos habilitados do que leitos SUS cadastrados. A diferença no sentido oposto não é tratada como inconsistência, porque os dois campos não medem o mesmo conjunto de leitos.

- **Onde ocorre no processo:** Na relação entre o cadastro de leitos e o registro das habilitações do mesmo estabelecimento. O projeto não acompanhou o cadastramento na origem e, portanto, não atribui o caso observado a uma etapa específica.

- **Causa provável (hipótese):** O caso com mais leitos habilitados do que leitos SUS é compatível com defasagem entre a atualização do cadastro de leitos e a das habilitações, ou com habilitação registrada para leitos ainda não cadastrados como SUS. Os dados não distinguem essas explicações, e nenhuma foi verificada junto à fonte. O estabelecimento não foi identificado nesta verificação.

- **Alcance:** 304 estabelecimentos com pelo menos uma habilitação que tem leitos, em São Paulo (competência novembro/2025), com 1 caso a investigar. O universo da comparação original (768) incluía estabelecimentos sem nenhuma habilitação com leitos e não deve ser usado.

- **Prioridade:** Baixa. Como o A7 e o A9, o A3 descreve uma relação que, no recorte, não indica problema em escala: só 1 de 304 estabelecimentos fica fora do esperado. Diferente deles, há um caso a investigar. A comparação por categoria de leito, que testa de fato a correspondência entre leitos e habilitações, é feita no A4.

#### A7 — Ausência de duplicidade do identificador CNES

- **Achado:** Nenhum valor de `id_estabelecimento_cnes` se repete no recorte: cada um dos 110.362 registros de SP em novembro de 2025 tem um identificador diferente. O identificador funciona como chave única no recorte, o que permite tratar cada registro como um estabelecimento nas contagens dos demais achados.

- **Evidência:** `sql/13` (linhas 23–36), consulta que agrupa por `id_estabelecimento_cnes` e retorna os grupos com mais de um registro: 0 linhas. A mesma consulta e o resultado estão no log de queries (linhas 677–695). Não há data de execução registrada. O total de 110.362 registros vem da contagem do recorte na Fase 1 (log, linha 92). O mapeamento FHIR registra 110.362 registros e 110.362 identificadores distintos (`docs/mapeamento-cnes-fhir.md`, linhas 100–101), e a seção 4.3 deste documento informa que a unicidade foi refeita de forma independente em Python, com o mesmo resultado.

- **Dimensão:** Unicidade. O teste verifica a repetição do identificador do estabelecimento, que é a definição de unicidade adotada no projeto (seção 4.1).

- **Onde ocorre no processo:** Não há problema a localizar. O resultado descreve o dado no estado em que chegou ao projeto, depois da publicação pelo DATASUS e do tratamento pela Base dos Dados. O projeto não acompanhou o cadastramento na origem.

- **Causa provável (hipótese):** Não se aplica, porque não foi encontrado problema. O resultado é compatível com a atribuição de um código CNES por estabelecimento no cadastro nacional, mas essa regra de atribuição não foi verificada junto à fonte.

- **Alcance:** Os 110.362 registros do recorte (SP, novembro de 2025). O teste não verifica se um mesmo estabelecimento real foi cadastrado com dois códigos diferentes; essa forma de duplicidade não foi medida. O resultado não deve ser estendido a outras competências ou Unidades da Federação.

- **Prioridade:** Baixa, como o A9: os dois registram que o dado atende ao critério testado. Diferente dos achados de prioridade Média, não há problema a controlar. A relevância do A7 está em sustentar as contagens dos outros achados, como os 5 estabelecimentos do A8.

#### A9 — Completude do CNPJ da mantenedora depende da aplicabilidade

- **Achado:** O campo `cnpj_mantenedora` apresenta 98.098 registros vazios, correspondentes a 88,89% dos 110.362 estabelecimentos analisados. Entretanto, o vazio bruto não representa, por si só, uma falha de completude, pois o preenchimento do campo depende da situação cadastral do estabelecimento. A análise identificou que os registros vazios correspondem aos estabelecimentos classificados como `tipo_grau_dependencia = 1` (Individual), enquanto os registros classificados como `tipo_grau_dependencia = 3` (Mantida) apresentam o CNPJ da mantenedora preenchido.

- **Evidência:** A análise identificou 98.098 registros sem `cnpj_mantenedora` e 12.264 registros com CNPJ válido de 14 dígitos, correspondentes a 743 mantenedoras distintas. O cruzamento com `tipo_grau_dependencia` apresentou exatamente duas combinações: `1` (Individual) associado a CNPJ vazio em 98.098 registros e `3` (Mantida) associado a CNPJ preenchido em 12.264 registros. A correspondência foi confirmada linha a linha. Entre os 12.264 estabelecimentos classificados como Mantidos, portanto, a completude observada do campo foi de 100%.

- **Dimensão:** Completude.

- **Onde ocorre no processo:** O achado foi identificado na análise da base `br_ms_cnes`, durante a avaliação da completude do campo `cnpj_mantenedora`. A investigação mostrou que a interpretação da ausência depende da classificação `tipo_grau_dependencia`. O projeto não acompanhou diretamente o processo operacional de cadastramento de cada estabelecimento e, portanto, não atribui o comportamento observado a uma etapa específica de origem.

- **Causa provável:** Não foi identificada uma inconsistência de preenchimento entre os registros em que o campo é aplicável. A elevada proporção de vazios no total geral decorre da inclusão, na mesma métrica, de estabelecimentos classificados como Individuais, para os quais o CNPJ da mantenedora não se aplica. Assim, o principal risco identificado é metodológico: calcular a completude do campo sobre o total geral do recorte, sem considerar sua regra de aplicabilidade, produziria uma interpretação incorreta da qualidade dos dados.

- **Alcance:** O achado abrange os 110.362 estabelecimentos de São Paulo na competência de novembro de 2025. No total geral, foram observados 98.098 registros vazios (88,89%) e 12.264 preenchidos (11,11%). Considerando somente o universo em que o campo é aplicável, formado pelos 12.264 estabelecimentos classificados como Mantidos, a completude observada foi de 100%. O resultado está restrito ao recorte analisado e não deve ser extrapolado automaticamente para outras competências ou Unidades da Federação.

- **Prioridade:** Baixa. A classificação decorre do fato de que não foi identificada ausência de `cnpj_mantenedora` entre os estabelecimentos classificados como Mantidos no recorte analisado. O principal ponto de atenção é preservar a regra de negócio na definição e no monitoramento do indicador, evitando que estabelecimentos para os quais o campo não se aplica sejam tratados como registros incompletos.

### 5.3 Mapeamento FHIR

O mapeamento é um resultado de entrega, e não um achado de qualidade; por isso não entra na tabela 5.1.

- **O que foi gerado:** recursos `Organization` em FHIR R4 (4.0.1), identificados pelo número CNES (Decisão 01 de `docs/mapeamento-cnes-fhir.md`), com o CEP em `Organization.address.postalCode`. `Location` foi avaliado e não é gerado como recurso independente nesta versão. Não são gerados identificadores de CPF ou CNPJ (A10).

- **Validação:** os cinco bundles de exemplo em `fhir/exemplos/` passaram no FHIR Validator CLI 6.10.4: 5 de 5 aprovados, com 0 erros e 0 avisos (`fhir/validacao/validacao-cinco-bundles-cnes.log`). O conversor (`python/fase6-conversor-fhir.py`) tem 13 testes automatizados em `tests/test_fase6_conversor_fhir.py`.

- **Limites:** ver seção 7.3.

## 6. Recomendações e controles

As recomendações seguem a ordem de prioridade da tabela 5.1. Cada uma indica o achado que trata, o tipo de controle e o indicador de acompanhamento, com a linha de base medida no recorte. O detalhamento operacional (gatilho, responsáveis pela execução e pela validação, ação em caso de violação) está em `docs/framework-governanca.md`, na regra indicada.

Três tipos de controle são usados: **preventivo**, que impede o problema antes do uso do dado; **detectivo**, que identifica o problema a cada carga; e **investigação**, que verifica uma interpretação antes de qualquer alerta automático. Achados cuja interpretação é hipótese (A3, A8) começam por investigação junto à fonte. Responsáveis e prazos são sugestões. O projeto não mediu impacto financeiro, clínico ou regulatório, e nenhuma recomendação pressupõe esse impacto.

#### R1 — Tratar `"nan"` e texto em branco como ausência na região de saúde (A1)

- **Ação:** converter `"nan"` e texto em branco em ausência antes de qualquer cálculo com `id_regiao_saude`, e medir o campo pelas três formas de ausência (nulo, `"nan"` e texto em branco).

- **Controle:** detectivo, a cada carga (framework, Regra 1).

- **Indicador:** percentual de estabelecimentos sem região de saúde, somando as três formas de ausência. Linha de base: 60.366 de 110.362 (54,70%).

- **Responsável sugerido:** execução pela engenharia de dados; validação pela qualidade de dados.

- **Prazo sugerido:** antes do próximo uso do campo em indicador ou painel.

#### R2 — Verificar se o `"nan"` já está na origem (A1)

- **Ação:** aplicar ao campo região de saúde o teste de proveniência usado para o código 16 (PySUS, `source="origin"`), versionando o script e registrando a data de execução.

- **Controle:** investigação, sem alerta automático.

- **Indicador:** teste executado e registrado; resultado: `"nan"` presente ou ausente na origem consultada.

- **Responsável sugerido:** análise de dados.

- **Prazo sugerido:** próxima revisão do projeto.

#### R3 — Priorizar os municípios com maior ausência de região de saúde (A6)

- **Ação:** usar a distribuição municipal da ausência para direcionar apoio ao cadastro, começando pelos municípios acima de 75% de ausência, entre os 347 com pelo menos 20 estabelecimentos.

- **Controle:** detectivo, a cada fechamento de competência (framework, Regra 8).

- **Indicador:** proporção de municípios em cada faixa de ausência. Linha de base: taxas de 0% a 99,18%.

- **Responsável sugerido:** execução pela engenharia de dados ou suporte analítico; validação pela governança com a gestão regional.

- **Prazo sugerido:** a cada fechamento de competência.

#### R4 — Monitorar o tempo sem alteração cadastral e confirmar o significado do campo (A5)

- **Ação:** acompanhar a cada carga os estabelecimentos sem alteração registrada há mais de 24 meses; confirmar junto à fonte o que `ano_atualizacao` registra e se o arquivo publicado inclui estabelecimentos desativados; submeter o corte de 24 meses à área de gestão, porque ele é critério do projeto e não a regra de 6 meses da Portaria SAS/MS nº 118/2014.

- **Controle:** detectivo, mensal (framework, Regra 7).

- **Indicador:** percentual de estabelecimentos sem alteração registrada há mais de 24 meses. Linha de base: 22.868 de 110.362 (20,72%); com a janela de 6 meses, 50.785 (46,02%).

- **Responsável sugerido:** execução pela engenharia de dados; validação pela governança com a gestão em saúde.

- **Prazo sugerido:** ratificar o corte antes de usar o indicador como meta.

#### R5 — Restringir `cpf_cnpj` a resultados agregados (A10)

- **Ação:** não publicar, versionar nem exportar valores individuais do campo; não gerar identificador de CPF ou CNPJ nos recursos FHIR desta versão; submeter qualquer uso individual futuro a revisão de privacidade.

- **Controle:** preventivo, em toda consulta ou artefato que use o campo (framework, Regra 10).

- **Indicador:** número de valores individuais de `cpf_cnpj` em arquivos versionados ou artefatos públicos. Meta: zero.

- **Responsável sugerido:** execução pela engenharia de dados; validação pela governança e pela área de privacidade.

- **Prazo sugerido:** imediato e contínuo.

#### R6 — Tratar o ano 9999 como prazo não definido (A2)

- **Ação:** excluir `ano_competencia_final = 9999` das comparações de data, contá-lo à parte como "sem prazo definido" e consultar a fonte sobre o significado do sentinela e dos 4 registros com mês `9`.

- **Controle:** detectivo, a cada carga (framework, Regra 1).

- **Indicador:** percentual de habilitações com o sentinela. Linha de base: 6.072 de 6.764 (89,77%).

- **Responsável sugerido:** execução pela engenharia de dados; validação pela qualidade de dados.

- **Prazo sugerido:** antes do próximo cálculo da regra de habilitação vencida.

#### R7 — Confirmar o significado das duas quantidades de leitos antes de cruzá-las (A3)

- **Ação:** comparar leitos e habilitações só entre as habilitações que têm leitos e, de preferência, por categoria de leito, como no A4; investigar o estabelecimento com mais leitos habilitados do que leitos SUS; confirmar junto à fonte o significado de `habilitacao.quantidade_leitos`.

- **Controle:** investigação (framework, Regra 2).

- **Indicador:** número de estabelecimentos com mais leitos habilitados do que leitos SUS, entre os que têm habilitação com leitos. Linha de base: 1 de 304.

- **Responsável sugerido:** execução pela qualidade ou análise de dados; validação pela área de negócio do CNES ou da regulação.

- **Prazo sugerido:** antes de publicar qualquer indicador que use os dois campos juntos.

#### R8 — Calcular a regra de UTI com leitos SUS e manter o de-para alinhado às portarias (A4)

- **Ação:** calcular a correspondência entre leitos de UTI e habilitações com `quantidade_sus`, usando o de-para alinhado às Portarias SAES/MS nº 2.902/2025 e nº 3.511/2025; revisar o de-para a cada nova portaria (a 3.511/2025 exclui as categorias tipo I a partir da competência 12/2025); acompanhar habilitações extintas ainda registradas, como a 2602.

- **Controle:** detectivo, a cada carga (framework, Regra 2).

- **Indicador:** número de combinações estabelecimento + categoria de UTI com leitos SUS sem habilitação correspondente. Linha de base: 0 de 550.

- **Responsável sugerido:** execução pela análise de dados; validação pela regulação ou gestão assistencial.

- **Prazo sugerido:** a cada carga e a cada nova portaria sobre leitos ou habilitações de UTI.

#### R9 — Confirmar o significado do código 16 de `tipo_unidade` (A8)

- **Ação:** consultar a documentação oficial do CNES/DATASUS sobre o tipo de estabelecimento 16; até a confirmação, manter o código sem rótulo inferido no mapeamento FHIR e acompanhar sua ocorrência nas próximas competências.

- **Controle:** investigação, com controle preventivo no mapeamento FHIR (`docs/investigacao-proveniencia-tipo-unidade-16.md`, seção 7). Não há regra própria no framework.

- **Indicador:** número de estabelecimentos com `tipo_unidade = 16` por competência. Linha de base: 5 em SP e 43 no Brasil, em 2025-11.

- **Responsável sugerido:** execução pela análise de dados; validação pela governança de dados.

- **Prazo sugerido:** antes da próxima versão do mapeamento FHIR.

#### R10 — Calcular a completude de `cnpj_mantenedora` só onde o campo se aplica (A9)

- **Ação:** calcular a métrica sobre os estabelecimentos Mantidos e disponibilizar uma visão com o status "Preenchido", "Faltante" ou "Não se aplica".

- **Controle:** preventivo (framework, Regra 6).

- **Indicador:** percentual de estabelecimentos Mantidos com o campo preenchido. Linha de base: 12.264 de 12.264 (100%).

- **Responsável sugerido:** execução pela engenharia de dados; validação pela análise de dados ou governança.

- **Prazo sugerido:** na próxima publicação do indicador.

#### R11 — Repetir o teste de unicidade a cada carga (A7)

- **Ação:** verificar a duplicidade de `id_estabelecimento_cnes` em cada nova competência, antes de usar contagens de registros como contagens de estabelecimentos.

- **Controle:** detectivo, a cada carga. Não há regra própria no framework.

- **Indicador:** número de identificadores repetidos. Linha de base: 0 em 110.362.

- **Responsável sugerido:** execução pela engenharia de dados; validação pela qualidade de dados.

- **Prazo sugerido:** a cada carga.

## 7. Limitações e premissas

Os resultados valem para o dado observado em SP, competência novembro de 2025, no estado em que foi consultado na Base dos Dados. As limitações abaixo dizem o que não foi possível verificar; nenhuma delas altera os números publicados na seção 5.

### 7.1 Alcance do recorte

- O diagnóstico cobre uma UF e uma competência. Os resultados não devem ser estendidos a outras UFs ou competências sem nova medição.
- A completude foi medida em cinco campos escolhidos na exploração inicial, sem critério formal prévio (seção 4.1); não descreve a completude de todo o cadastro.
- Os dados foram coletados depois do tratamento pela Base dos Dados. O projeto não acompanhou o cadastramento na origem e não atribui os problemas a uma etapa específica (seção 3). A única exceção é o código 16 (A8), cuja presença foi testada na origem consultada.

### 7.2 Interpretações não verificadas junto à fonte

Exceto pela correspondência entre leitos de UTI e habilitações (A4), confirmada nas Portarias SAES/MS nº 2.902/2025 e nº 3.511/2025, nenhuma documentação oficial do CNES/DATASUS foi consultada para confirmar as interpretações abaixo. Elas estão marcadas como hipótese nos achados e geram recomendações de investigação (seção 6).

- O ano `9999` como prazo indeterminado, e o mês `9` em 4 registros (A2).
- O significado de `habilitacao.quantidade_leitos` e sua relação com os leitos SUS cadastrados (A3).
- A leitura das 553 combinações de UTI só com leitos não SUS como UTIs que atendem fora do SUS, e a presença da habilitação 2602 depois da extinção (A4).
- O significado do código 16 de `tipo_unidade`. A ausência no ValueSet versão 1.1.0, ativo desde 2026-08-22, não prova ausência de significado em 2025-11 (A8).
- A origem do texto `"nan"` na região de saúde (A1).
- O corte de 24 meses, que é critério do projeto e não a regra de 6 meses da Portaria SAS/MS nº 118/2014, e o que o campo `ano_atualizacao` registra (A5).

### 7.3 O que não foi medido

- A inspeção dos 298 estabelecimentos com combinações de UTI só com leitos não SUS, para confirmar que não atendem pelo SUS (A4).
- A duplicidade de um mesmo estabelecimento real com códigos CNES diferentes (A7).
- O impacto financeiro, clínico ou regulatório de qualquer achado.
- A inspeção individual, por amostra, dos estabelecimentos apontados nas regras de consistência, prevista no planejamento: este documento não apresenta o resultado dessa inspeção.
- A reprodução independente em Python dos resultados de consistência e atualidade (seção 4.3).
- A validação FHIR além dos cinco bundles de exemplo e das regras do FHIR R4 base. A validação foi executada com `-tx n/a`, sem consulta a servidor de terminologia, e não verifica a conformidade com perfis da RNDS nem os 110.362 registros do recorte. O recurso `Location` não foi gerado (seção 5.3).

### 7.4 Rastreabilidade e reprodutibilidade

- **Datas de execução.** As consultas das Fases 1 a 3 (`sql/01` a `sql/10` e `sql/13`) não registram data de execução. Nos arquivos `sql/11` e `sql/12`, a data registrada (2026-10-04) é a de uma verificação posterior, não a da execução original. As consultas da Fase 6 (`sql/14` a `sql/19`) registram datas entre 2026-10-01 e 2026-10-04. A etapa 9 da `sql/06` registra execução em 01/11/2026.
- **Reproduções.** Em `sql/17`, `sql/18` e `sql/19`, os resultados são reproduções independentes; a consulta original do histórico do código 16 não foi versionada.
- **Teste de proveniência do código 16.** Foi executado com PySUS 2.11.1, na imagem Docker `alertadengue/pysus`, sem script versionado, sem data registrada e sem registro da versão do Docker ou do identificador exato (digest) da imagem.
- **Comparações manuais.** A correspondência de 37 dos 38 códigos de `tipo_unidade` com a tabela `dicionario` resultou da comparação manual de duas listas (`sql/07`, etapas 1 e 2), sem consulta que faça o cruzamento.
- **Valores fora do log.** A média de 97,88 leitos de diferença no A3 só é calculada na `sql/05` (linha 152); a consulta registrada no log não a produz.
- **Base sujeita a atualização.** A Base dos Dados pode reprocessar tabelas publicadas. Uma nova execução das consultas pode produzir números diferentes sem que o método tenha mudado.
- **Correções de registro.** Em 02/11/2026, duas descrições incorretas foram corrigidas com nota datada, mantendo o texto original: a origem da redução de 19 para 14 códigos de habilitação de UTI e a contagem de pares do de-para (`docs/log-de-queries.md`, linha 362; `sql/06`, linha 85). As notas foram escritas na própria linha corrigida, para não alterar a numeração citada nos achados. No mesmo dia, depois da auditoria do projeto, a comparação do A3 foi verificada e restrita às habilitações que têm leitos (`sql/05`, etapas 6 a 8), com nota datada na `sql/05` (linha 84) e no log (linha 336 e decisão da mesma seção). Também depois da auditoria, a regra do A4 foi recalculada com leitos SUS (`sql/06`, etapa 10), com nota datada na `sql/06` (linha 174) e no log (linha 403). Por fim, a atualidade do A5 foi comparada com a janela de 6 meses da Portaria SAS/MS nº 118/2014 (`sql/08`, etapa 6), com nota datada na `sql/08` (linha 104) e no log (linha 510).

### 7.5 Premissas adotadas

- A chave de um estabelecimento é `id_estabelecimento_cnes` + `ano` + `mes`; com a competência fixa, o código basta (A7).
- As tabelas `leito` e `habilitacao` foram agregadas a uma linha por estabelecimento antes de qualquer junção.
- O texto `"nan"` e o texto em branco foram tratados como ausência de informação.
- A competência de novembro de 2025, e não a data da consulta, é a referência de tempo para a atualidade.

## 8. Próximos passos

Os passos abaixo são o que viria depois deste diagnóstico, em ordem. Nenhum deles foi executado.

1. **Validar as interpretações junto à fonte.** Consultar a documentação oficial ou a área responsável pelo CNES sobre o ano `9999`, o significado de `habilitacao.quantidade_leitos`, a habilitação extinta ainda registrada e o código 16 (R6 a R9). É o passo que pode transformar hipóteses em fatos ou descartá-las.
2. **Testar a origem do `"nan"`** na região de saúde com o mesmo método usado para o código 16, com script versionado (R2).
3. **Pilotar os controles de menor custo** em uma nova competência: tratamento do `"nan"` (R1), completude de `cnpj_mantenedora` sobre os Mantidos (R10) e teste de unicidade (R11).
4. **Repetir a medição em outra competência**, para comparar resultados e ativar os controles que dependem de série histórica (framework, Regras 5 e 8).
5. **Fechar as lacunas de registro** da seção 7.4: reconstruir e versionar o teste PySUS e registrar a data de execução de cada consulta reexecutada.

## 9. Anexos técnicos

Todos os arquivos estão no repositório indicado na seção 0.

| Arquivo | Conteúdo |
|---|---|
| `sql/01` a `sql/19` | Consultas SQL de exploração, indicadores, regras de consistência e validações |
| `docs/log-de-queries.md` | Registro de cada consulta, do resultado e da decisão tomada |
| `docs/dicionario-de-dados.md` | Dicionário dos campos analisados, derivado da tabela `dicionario` |
| `docs/framework-governanca.md` | Regras de governança, responsáveis e indicadores (base da seção 6) |
| `docs/mapeamento-cnes-fhir.md` | De-para CNES → FHIR e decisões de mapeamento |
| `docs/investigacao-proveniencia-tipo-unidade-16.md` | Investigação do código 16 (A8) |
| `docs/achados-verificacao-estrutura.md` | Achados da verificação de estrutura do conjunto |
| `docs/decisao-recorte.md` | Justificativa do recorte SP + novembro de 2025 |
| `docs/projeto-portfolio-cnes-qualidade-dados-v2.md` | Planejamento do projeto (versão 2) |
| `python/fase2-limpeza-tratamento.ipynb` | Limpeza e tratamento dos dados (Fase 2) |
| `python/fase6-conversor-fhir.py` e `tests/test_fase6_conversor_fhir.py` | Conversor para FHIR e seus testes |
| `fhir/exemplos/` e `fhir/validacao/` | Cinco bundles FHIR de exemplo e o registro da validação |
| `dashboard/` | Painéis de completude, atualidade e distribuição regional (PDF) |
| `requirements.txt` | Versões das bibliotecas do ambiente de reprodução |

**Glossário**

| Termo | Significado |
|---|---|
| CNES | Cadastro Nacional de Estabelecimentos de Saúde, mantido pelo Ministério da Saúde |
| DATASUS | Departamento de Informática do SUS, que publica os dados do CNES |
| Competência | Mês de referência dos dados (aqui, novembro de 2025) |
| Habilitação | Autorização formal de um estabelecimento para prestar um tipo de serviço pelo SUS |
| Valor sentinela | Valor usado no lugar de uma informação ausente, como o ano `9999` |
| De-para | Tabela de correspondência entre códigos de duas listas diferentes |
| FHIR | Padrão internacional de troca de dados em saúde (HL7 FHIR) |
| ValueSet | Lista oficial de códigos válidos para um campo, publicada em terminologia FHIR |
