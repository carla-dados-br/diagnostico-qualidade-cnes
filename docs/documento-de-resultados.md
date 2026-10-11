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

**Consistência:** verifica se informações relacionadas são compatíveis entre si. Neste projeto, foi aplicada a três regras; por exemplo, à comparação entre a quantidade total de leitos informada para o estabelecimento e a quantidade de leitos registrada nas habilitações correspondentes, para identificar diferenças que precisassem de investigação.

**Atualidade:** verifica há quanto tempo o cadastro recebeu uma atualização registrada. Neste projeto, foi aplicada à data de atualização dos estabelecimentos, utilizando uma janela metodológica de 24 meses para classificar os registros.

**Unicidade:** verifica se cada estabelecimento aparece de forma única na identificação usada pelo projeto. Neste projeto, foi aplicada ao código CNES do estabelecimento, buscando identificar repetições desse identificador no recorte analisado.

### 4.2 Como foi medido

As medições foram feitas com consultas em SQL sobre a base disponibilizada no Google BigQuery. Para a completude, foram consideradas três formas diferentes de registrar a ausência de informação — campo sem valor, o texto `"nan"` e texto em branco —, porque considerar apenas o campo sem valor, que é a forma detectada pelas verificações usuais, faria registros sem informação parecerem preenchidos e poderia subestimar a incompletude. Para a atualidade, a referência de tempo foi a competência de novembro de 2025, e não a data em que a consulta foi executada, para que o resultado permanecesse vinculado ao período analisado e não mudasse artificialmente com o passar do tempo. Nas regras de consistência, o ano `9999` foi tratado separadamente por representar ausência de data final da habilitação, e as informações de leitos e habilitações foram resumidas a uma linha por estabelecimento antes da comparação, para evitar que estabelecimentos com vários registros fossem contados repetidamente e produzissem resultados inflados.

### 4.3 Como os números foram conferidos

Os resultados de completude e unicidade foram calculados em SQL e refeitos de forma independente em Python. A conferência identificou cinco registros com texto em branco no campo região de saúde que não estavam sendo contabilizados pela consulta SQL. Isso levou à correção da métrica de 54,69% para 54,70%; após a correção, os dois caminhos passaram a apresentar o mesmo resultado. A alteração foi registrada na documentação do projeto.

Os resultados de consistência e atualidade não passaram por essa reprodução independente em Python. Além disso, resultados extremos, como os 100% de divergência encontrados na comparação entre leitos e habilitações, foram investigados antes de serem aceitos como achados, para verificar se representavam um erro confirmado ou uma situação que exigia análise adicional. O resultado dessa investigação é apresentado na seção 5, junto aos demais resultados do diagnóstico.

As consultas, os critérios técnicos de cada medição e o registro das decisões estão listados na seção 9 (Anexos).

## 5. Resultados

_Em construção._

## 6. Recomendações e controles

_Em construção._

## 7. Limitações e premissas

_Em construção._

## 8. Próximos passos

_Em construção._

## 9. Anexos técnicos

_Em construção._
