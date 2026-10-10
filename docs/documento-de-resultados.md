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

_Em construção._

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
