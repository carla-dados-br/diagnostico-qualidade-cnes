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

_Em construção._

## 2. Contexto e objetivo

**Problema.** Gestores decidem sobre leitos, profissionais e planejamento regional com base em cadastros que podem estar incompletos, desatualizados ou inconsistentes. O CNES é a base cadastral que sustenta outros sistemas do SUS, como SIA, SIH e e-SUS AB; problemas de qualidade nele se propagam para esses sistemas.

**Pergunta do projeto.** Em que medida o cadastro de estabelecimentos do CNES de São Paulo, em novembro de 2025, é completo, consistente, atual e único, e quais controles reduziriam os problemas encontrados?

**Objetivos.**

- Medir completude, consistência, atualidade e unicidade do cadastro de estabelecimentos.
- Aplicar três regras de consistência baseadas na estrutura real do CNES, uma delas dependente de conhecimento clínico (leito de UTI e habilitação).
- Propor regras mínimas de governança, com responsáveis e indicadores.
- Mapear os dados para os recursos FHIR `Organization` e `Location`, com validação.

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
| A3 | Divergência entre quantidade de leitos e habilitações | 768 de 768; leitos maiores que habilitações em todos os casos | Consistência | Fato; interpretação é hipótese | **Média** |
| A4 | Leito de UTI sem habilitação correspondente segundo o de-para | 553 de 1.103 combinações (50,1%); 7.312 leitos; universo de 547 estabelecimentos com UTI | Consistência | Fato; interpretação é hipótese | **Média** |
| A8 | Código 16 de `tipo_unidade` sem significado semântico confirmado | 5 de 110.362 estabelecimentos; 37 de 38 códigos presentes no ValueSet FHIR e na tabela `dicionario` | Consistência | Fato; interpretação é hipótese | **Média** |
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

- **Onde ocorre no processo:** O sentinela já está presente na tabela `habilitacao` disponibilizada pela Base dos Dados, ou seja, foi registrado antes da coleta do projeto: no cadastramento, na consolidação pelo DATASUS ou no tratamento intermediário. O projeto não acompanhou o cadastramento na origem e, portanto, não atribui o padrão observado a uma etapa específica.

- **Causa provável (hipótese):** O registro de um ano futuro extremado (`9999`) sugere o uso de uma convenção sistêmica pela origem para designar habilitações de prazo indeterminado. Essa interpretação foi deduzida pelo comportamento dos dados e não foi verificada junto à fonte. A hipótese de convenção sistemática não explica, porém, por que 4 dos registros apresentam o mês `9`.

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

#### A8 — Código 16 de `tipo_unidade` sem significado semântico confirmado

- **Achado:** O código `16` aparece no campo `tipo_unidade` em 5 estabelecimentos do recorte, mas seu significado não está documentado em nenhuma das duas referências consultadas: a tabela `dicionario` da Base dos Dados e o ValueSet FHIR `BRTipoEstabelecimentoSaude` (versão 1.1.0). Dos 38 códigos observados no recorte, é o único sem correspondência nas duas.

- **Evidência:** Presença no ValueSet: `sql/16`, resultados 1 e 2 (linhas 58–80; resultados registrados nas linhas 101–111), executada em 2026-10-04: 37 de 38 códigos presentes; o `16` ocorre em 5 estabelecimentos. Correspondência com a tabela `dicionario`: `sql/07`, etapas 1 e 2 (linhas 22–44), por comparação manual entre as duas listas, sem data de execução registrada. Histórico e ocorrência nacional: a query original não foi versionada; a `sql/19` é uma reprodução independente, executada em 2026-10-04, que chegou aos mesmos números registrados em `docs/investigacao-proveniencia-tipo-unidade-16.md` (seções 2 e 3). Presença na origem: mesmo documento, seções 4 e 5 (PySUS 2.11.1, `source="origin"`), sem script versionado e sem data registrada. Log de queries, nota na linha 432.

- **Dimensão:** Consistência, entendida como consistência do valor com o domínio de referência do campo. O campo está 100% preenchido no recorte (`sql/07`, etapa 3), por isso o problema não é de completude. Se o `16` for um código válido ainda não documentado nas fontes consultadas, a inconsistência não está no dado, e sim na documentação de referência.

- **Onde ocorre no processo:** O valor já está presente nos mesmos 5 estabelecimentos no arquivo da origem consultada (CNES/ST/SP/2025-11, obtido pelo PySUS com `source="origin"`), e não foi encontrada evidência de que a transformação da Base dos Dados o tenha introduzido. O problema surge, portanto, antes da publicação desse arquivo, no cadastramento ou no processamento da origem. O teste não determina em qual dessas etapas, e o projeto não acompanhou o cadastramento na origem.

- **Causa provável (hipótese):** O padrão é compatível com uma alteração na origem, e não com uma ocorrência isolada: na janela de 2024-01 a 2026-02, o código aparece pela primeira vez em 2025-09 e passa de 10 estabelecimentos em 7 UFs para 86 em 18 UFs; os 5 estabelecimentos de SP vieram de tipos diferentes (22, 36, 4 e 2), e um deles voltou ao tipo anterior (36 → 16 → 36). Os dados não distinguem entre explicações alternativas: código novo ainda não incorporado às referências consultadas, uso indevido do código no cadastramento ou reclassificação temporária. A interpretação não foi verificada junto à fonte. A ausência no ValueSet versão 1.1.0, ativo desde 2026-08-22, não prova que o código não tivesse significado oficial em 2025-11.

- **Alcance:** No recorte, 5 de 110.362 estabelecimentos (cerca de 0,005%). A contagem equivale a estabelecimentos porque não há duplicidade de `id_estabelecimento_cnes` no recorte (A7). Fora do recorte, 43 estabelecimentos em 15 UFs na mesma competência (2025-11) e 86 em 18 UFs em 2026-02. O universo nacional de estabelecimentos não foi calculado, por isso não há percentual nacional.

- **Prioridade:** Média. Em comparação com o A3 e o A4, a evidência do fato é mais forte (duas referências, presença na origem e histórico reproduzido), mas o alcance no recorte é muito menor. Fica em Média, e não em Baixa, porque o código não tem significado conhecido, afeta diretamente a classificação do estabelecimento e o mapeamento FHIR (`Organization.type`), e cresce em escala nacional. Diferente do A3, já existe tratamento técnico: o projeto não atribui rótulo ao código no FHIR, o que limita o impacto dentro do projeto, mas não resolve o problema no dado.

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

## 6. Recomendações e controles

As recomendações seguem a ordem de prioridade da tabela 5.1. Cada uma indica o achado que trata, o tipo de controle e o indicador de acompanhamento, com a linha de base medida no recorte. O detalhamento operacional (gatilho, responsáveis pela execução e pela validação, ação em caso de violação) está em `docs/framework-governanca.md`, na regra indicada.

Três tipos de controle são usados: **preventivo**, que impede o problema antes do uso do dado; **detectivo**, que identifica o problema a cada carga; e **investigação**, que verifica uma interpretação antes de qualquer alerta automático. Achados cuja interpretação é hipótese (A3, A4, A8) começam por investigação junto à fonte. Responsáveis e prazos são sugestões. O projeto não mediu impacto financeiro, clínico ou regulatório, e nenhuma recomendação pressupõe esse impacto.

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

#### R4 — Monitorar a atualidade cadastral e ratificar o corte de 24 meses (A5)

- **Ação:** acompanhar a cada carga os estabelecimentos sem atualização há mais de 24 meses e submeter esse corte à área de gestão, porque ele é critério do projeto e não regra oficial.

- **Controle:** detectivo, mensal (framework, Regra 7).

- **Indicador:** percentual de estabelecimentos desatualizados. Linha de base: 22.868 de 110.362 (20,72%).

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

- **Ação:** verificar o significado dos campos junto à fonte antes de utilizá-los em indicadores cruzados. Até lá, registrar a divergência como investigação, e não como violação.

- **Controle:** investigação (framework, Regra 2).

- **Indicador:** percentual de estabelecimentos com divergência entre `leito.quantidade_total` e `habilitacao.quantidade_leitos`, lido como descrição e não como taxa de erro. Linha de base: 768 de 768.

- **Responsável sugerido:** execução pela qualidade ou análise de dados; validação pela área de negócio do CNES ou da regulação.

- **Prazo sugerido:** antes de publicar qualquer indicador que use os dois campos juntos.

#### R8 — Validar o de-para entre leitos de UTI e habilitações (A4)

- **Ação:** submeter o de-para construído pelo projeto à validação da área assistencial ou regulatória, incluindo a premissa de que todo leito de UTI exige habilitação; só depois calcular o número de estabelecimentos afetados.

- **Controle:** investigação (framework, Regra 2).

- **Indicador:** percentual de combinações estabelecimento + categoria de UTI sem habilitação correspondente segundo o de-para. Linha de base: 553 de 1.103 (50,1%), com 7.312 leitos.

- **Responsável sugerido:** execução pela análise de dados; validação pela regulação ou gestão assistencial.

- **Prazo sugerido:** antes de qualquer uso do resultado como indicador de conformidade.

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

Nenhuma documentação oficial do CNES/DATASUS foi consultada para confirmar as interpretações abaixo. Elas estão marcadas como hipótese nos achados e geram recomendações de investigação (seção 6).

- O ano `9999` como prazo indeterminado, e o mês `9` em 4 registros (A2).
- O significado de `leito.quantidade_total` e `habilitacao.quantidade_leitos`, e se as duas medidas deveriam coincidir (A3).
- O de-para entre leitos de UTI e habilitações, incluindo os códigos 2610 e 2611 tratados como sinônimos, e a premissa de que todo leito de UTI exige habilitação (A4).
- O significado do código 16 de `tipo_unidade`. A ausência no ValueSet versão 1.1.0, ativo desde 2026-08-22, não prova ausência de significado em 2025-11 (A8).
- A origem do texto `"nan"` na região de saúde (A1).
- O corte de 24 meses para atualidade, que é critério do projeto e não regra oficial (A5).

### 7.3 O que não foi medido

- O número de estabelecimentos afetados no A4: o resultado está em combinações estabelecimento + categoria de UTI (553 de 1.103) e em leitos (7.312); 547 é o universo de estabelecimentos com UTI.
- A duplicidade de um mesmo estabelecimento real com códigos CNES diferentes (A7).
- O impacto financeiro, clínico ou regulatório de qualquer achado.
- A inspeção individual, por amostra, dos estabelecimentos apontados nas regras de consistência, prevista no planejamento: este documento não apresenta o resultado dessa inspeção.
- A reprodução independente em Python dos resultados de consistência e atualidade (seção 4.3).

### 7.4 Rastreabilidade e reprodutibilidade

- **Datas de execução.** As consultas das Fases 1 a 3 (`sql/01` a `sql/10` e `sql/13`) não registram data de execução. Nos arquivos `sql/11` e `sql/12`, a data registrada (2026-10-04) é a de uma verificação posterior, não a da execução original. As consultas da Fase 6 (`sql/14` a `sql/19`) registram datas entre 2026-10-01 e 2026-10-04. A etapa 9 da `sql/06` registra execução em 01/11/2026.
- **Reproduções.** Em `sql/17`, `sql/18` e `sql/19`, os resultados são reproduções independentes; a consulta original do histórico do código 16 não foi versionada.
- **Teste de proveniência do código 16.** Foi executado com PySUS 2.11.1, na imagem Docker `alertadengue/pysus`, sem script versionado, sem data registrada e sem registro da versão do Docker ou do identificador exato (digest) da imagem.
- **Comparações manuais.** A correspondência de 37 dos 38 códigos de `tipo_unidade` com a tabela `dicionario` resultou da comparação manual de duas listas (`sql/07`, etapas 1 e 2), sem consulta que faça o cruzamento.
- **Valores fora do log.** A média de 97,88 leitos de diferença no A3 só é calculada na `sql/05` (linha 152); a consulta registrada no log não a produz.
- **Base sujeita a atualização.** A Base dos Dados pode reprocessar tabelas publicadas. Uma nova execução das consultas pode produzir números diferentes sem que o método tenha mudado.
- **Correções de registro.** Em 02/11/2026, duas descrições incorretas foram corrigidas com nota datada, mantendo o texto original: a origem da redução de 19 para 14 códigos de habilitação de UTI e a contagem de pares do de-para (`docs/log-de-queries.md`, linha 362; `sql/06`, linha 85). As notas foram escritas na própria linha corrigida, para não alterar a numeração citada nos achados.

### 7.5 Premissas adotadas

- A chave de um estabelecimento é `id_estabelecimento_cnes` + `ano` + `mes`; com a competência fixa, o código basta (A7).
- As tabelas `leito` e `habilitacao` foram agregadas a uma linha por estabelecimento antes de qualquer junção.
- O texto `"nan"` e o texto em branco foram tratados como ausência de informação.
- A competência de novembro de 2025, e não a data da consulta, é a referência de tempo para a atualidade.

## 8. Próximos passos

Os passos abaixo são o que viria depois deste diagnóstico, em ordem. Nenhum deles foi executado.

1. **Validar as interpretações junto à fonte.** Consultar a documentação oficial ou a área responsável pelo CNES sobre o ano `9999`, o significado das duas quantidades de leitos, o de-para de UTI e o código 16 (R6 a R9). É o passo que pode transformar hipóteses em fatos ou descartá-las.
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
