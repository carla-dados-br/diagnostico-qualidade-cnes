# Mapeamento CNES → HL7 FHIR R4

## 1. Objetivo

Este documento registra as decisões semânticas utilizadas para mapear campos selecionados do CNES para recursos HL7 FHIR R4 no projeto de diagnóstico de qualidade e governança de dados.

O mapeamento é definido antes da implementação em Python para separar:

- a decisão semântica;
- a transformação técnica;
- a validação do recurso FHIR gerado.

O escopo inicial de avaliação da Fase 6 considerou os recursos:

- `Organization`;
- `Location`.

Durante a revisão semântica, a criação de um recurso `Location` independente não foi aprovada para os dados implementados nesta versão. A implementação final permanece restrita a `Organization`, conforme as decisões documentadas neste arquivo.

A existência de um campo no CNES não implica que ele possua correspondência direta no FHIR. Cada campo deve ser analisado individualmente.

### 1.1 Escopo de seleção e limite de rastreabilidade

A tabela analítica principal `basedosdados.br_ms_cnes.estabelecimento` possui 204 colunas identificadas na etapa de exploração do projeto. A presente versão da Fase 6 analisou formalmente os dez campos registrados na matriz deste documento.

O critério histórico utilizado para selecionar especificamente esses dez campos entre as 204 colunas não foi formalmente registrado nos artefatos disponíveis. A revisão corretiva, portanto, não atribui retroativamente uma justificativa que não possa ser demonstrada pela documentação versionada.

Os dez campos devem ser entendidos como o escopo efetivamente analisado nesta versão, e não como uma avaliação exaustiva de todas as colunas disponíveis. Campos fora desse conjunto, como `sigla_uf`, permanecem não avaliados para mapeamento nesta versão. Sua ausência da matriz não significa rejeição semântica de possíveis elementos FHIR, como `Organization.address.state`; significa apenas que essa correspondência não recebeu decisão formal neste ciclo.

De modo equivalente, o critério original de escolha dos cinco estabelecimentos utilizados nos exemplos FHIR não foi recuperado nos artefatos disponíveis. O `sql/14-proveniencia-exemplos-fhir.sql` confirma que os pares CNES/CEP versionados pertencem à mesma linha da fonte analítica no recorte SP/nov-2025, mas não demonstra o critério histórico utilizado para selecionar esses cinco registros.

---

## 2. Classificação dos mapeamentos

### DIRETO

O campo de origem e o elemento FHIR representam o mesmo conceito do mundo real, sem alteração relevante de significado.

### APROXIMADO

Existe correspondência conceitual parcial, mas há diferença de escopo, granularidade ou significado que precisa ser documentada.

### DEPENDENTE DE TRANSFORMAÇÃO

O conceito pode ser representado no FHIR, mas exige uma regra explícita de transformação antes da geração do recurso.

### SEM CORRESPONDÊNCIA CLARA

Não existe evidência suficiente para definir um elemento FHIR de destino sem introduzir interpretação ou significado não sustentado pela fonte.

---

## 3. Regras de decisão

O mapeamento não será definido pela semelhança entre nomes de campos.

Para cada campo serão avaliados:

1. significado do campo na fonte;
2. conceito representado no mundo real;
3. definição do elemento FHIR de destino;
4. tipo de dado e cardinalidade;
5. terminologia ou sistema de identificação aplicável;
6. transformação necessária;
7. possíveis perdas semânticas;
8. exceções conhecidas.

Nenhum código, `display`, sistema terminológico ou significado será inventado para preencher lacunas da fonte.

---

## 4. Matriz de mapeamento

| Campo CNES | Significado na fonte | Resource FHIR | Elemento FHIR | Transformação | Sistema / terminologia | Classificação | Perda semântica |
|---|---|---|---|---|---|---|---|
| `id_estabelecimento_cnes` | Identificador CNES do estabelecimento | `Organization` | `identifier.value` | Preservar como `string` | `identifier.system = https://saude.gov.br/fhir/sid/cnes` | **DIRETO** | Nenhuma perda relevante identificada |
| `cep` | Código de Endereçamento Postal do estabelecimento | `Organization` | `address.postalCode` | Preservar como `string`; não converter para número | Não se aplica | **DIRETO** | Não foi identificada perda semântica relevante na representação do valor do CEP; nesta versão, o endereço postal permanece associado à própria `Organization`, sem criação de `Location` independente |
| `tipo_gestao` | Esfera de gestão do estabelecimento no contexto do CNES (`M` municipal; `E` estadual no recorte analisado) | — | — | Não mapear para `Organization.type` | — | **SEM CORRESPONDÊNCIA CLARA** | O conceito administrativo de gestão não equivale ao tipo da organização |
| `tipo_esfera_administrativa` | Campo derivado de `ESFERA_A`; a representação observada apresenta descontinuidade temporal e a semântica atual não foi validada | — | — | Não mapear enquanto a semântica não estiver comprovada | — | **SEM CORRESPONDÊNCIA CLARA** | O mapeamento poderia consolidar como equivalente a `tipo_gestao` uma coincidência de valores sem equivalência conceitual comprovada |
| `tipo_unidade` | Classificação do tipo do estabelecimento no contexto do CNES; o código `16` permanece sem significado terminológico comprovado | `Organization` | `type` (`CodeableConcept`) | Converter somente valores com significado e sistema terminológico validados; não gerar `Coding` para valores não validados | Sistema terminológico do domínio deve ser comprovado antes da geração do `Coding`; não inferir `system` ou `display` | **DEPENDENTE DE TRANSFORMAÇÃO** | Valores sem validação terminológica não são codificados; `16` permanece como exceção bloqueada |
| `tipo_natureza_administrativa` | Classificação histórica da natureza da organização; sem valores em SP, nov/2025 | `Organization` (candidato histórico) | `type` (`CodeableConcept`) | Não gerar no recorte atual; para dados históricos, exigir validação terminológica e temporal | Sistema terminológico ainda não validado | **DEPENDENTE DE TRANSFORMAÇÃO** | Campo omitido no recorte atual; não substituir por natureza jurídica nem por valores históricos |
| `id_natureza_juridica` | Código de natureza jurídica do estabelecimento (`NAT_JUR`); `4000` possui tratamento específico de equivalência para pessoas físicas no CNES | `Organization` (candidato) | `type` (`CodeableConcept`) | Preservar o valor original, a competência e a proveniência; não gerar `Coding` nesta versão | Nenhum CodeSystem adotado para esta implementação; avaliação da RNDS e da SES-GO documentada na Decisão 06 | **DEPENDENTE DE TRANSFORMAÇÃO** | A natureza jurídica não será representada nos recursos FHIR desta versão; o dado original permanece preservado |
| `cpf_cnpj` | Identificador fiscal armazenado em campo misto, com documentos ausentes, possíveis CPFs preenchidos com zeros e possíveis CNPJs | `Organization` (candidato, condicionado ao tipo e à titularidade do identificador) | `identifier` (candidato; não implementado) | Preservar o valor original apenas na camada de dados; não classificar pelo comprimento, prefixo ou validação matemática isoladamente; não exportar nesta versão | Nenhum sistema de identificação fiscal adotado para esta implementação | **DEPENDENTE DE TRANSFORMAÇÃO** | CPF/CNPJ não será representado nos recursos FHIR desta versão; o identificador CNES permanece disponível |
| `cnpj_mantenedora` | CNPJ da entidade cadastrada como mantenedora do estabelecimento no CNES | `Organization` (recurso separado para a mantenedora, candidato) | `identifier.value` da mantenedora (candidato); `partOf` não aprovado automaticamente | Preservar o CNPJ original e a competência; não substituir o documento fiscal do estabelecimento nem criar recursos ou relações nesta versão | Sistema de identificação CNPJ a definir em eventual implementação futura | **DEPENDENTE DE TRANSFORMAÇÃO** | Relação com a mantenedora não representada nos recursos FHIR desta versão |
| `tipo_atividade_ensino_pesquisa` | Classificação da atividade de ensino do estabelecimento, conforme o domínio consultado na tabela dicionario da Base dos Dados | — | — | Preservar código original e competência; não gerar elemento FHIR nesta versão | Dicionário CNES consultado; nenhum CodeSystem FHIR adotado para este campo | **SEM CORRESPONDÊNCIA CLARA** | A classificação de atividade de ensino não será representada nos recursos FHIR desta versão |

---

## 5. Decisão 01 — Identificador CNES

### Origem

Campo:

`id_estabelecimento_cnes`

No recorte analisado de estabelecimentos de São Paulo, competência novembro de 2025, foram observados:

- 110.362 registros;
- 110.362 identificadores distintos;
- nenhuma ausência nas formas verificadas;
- comprimento observado de 7 caracteres;
- somente valores numéricos no recorte analisado.

Essas características são evidências do recorte estudado e não são tratadas neste documento como regra normativa universal do CNES.

### Destino FHIR

Recurso:

`Organization`

Elemento:

`Organization.identifier.value`

Sistema do identificador:

`https://saude.gov.br/fhir/sid/cnes`

Fonte oficial do sistema identificador:

O Guia de Implementação de Terminologias do Brasil, publicado pelo Ministério da Saúde, documenta o `NamingSystemCNES`, cuja URL canônica é `https://terminologia.saude.gov.br/fhir/NamingSystem/cnes`. Nesse artefato, o URI `https://saude.gov.br/fhir/sid/cnes` é registrado como identificador do tipo URI e marcado como preferencial (`preferred = true`). Por esse motivo, esta versão utiliza esse URI em `Organization.identifier.system`.

A URL canônica do recurso `NamingSystem` e o URI preferencial do sistema identificador são identidades distintas: a primeira identifica o artefato FHIR que documenta o sistema, enquanto a segunda é utilizada em `Identifier.system` para identificar o sistema ao qual pertence o valor CNES.

Esta fonte fundamenta exclusivamente o sistema identificador CNES utilizado em `Organization.identifier.system`; ela não valida códigos, domínios ou significados terminológicos de outros campos do CNES.

Representação conceitual:

```text
Organization
└── identifier
    ├── system = https://saude.gov.br/fhir/sid/cnes
    └── value  = <id_estabelecimento_cnes>
```

### Por que não usar `Organization.id`

`Organization.id` representa o identificador lógico do recurso FHIR.

O número CNES é um identificador de negócio atribuído externamente ao estabelecimento e, portanto, deve ser representado em `Organization.identifier`.

Essa separação evita confundir a identidade lógica do recurso FHIR com o identificador administrativo do estabelecimento.

### Classificação

**DIRETO**

O identificador CNES mantém sua função semântica de identificação do estabelecimento quando representado em `Organization.identifier`.

---

## 6. Decisão 02 — CEP do estabelecimento

### Origem

Campo:

`cep`

O campo representa o Código de Endereçamento Postal do estabelecimento.

No recorte de estabelecimentos de São Paulo, competência novembro de 2025, foram observados:

- 110.362 registros;
- nenhuma ocorrência de `NULL`;
- nenhuma ocorrência de `"nan"`;
- nenhuma string vazia nas verificações realizadas;
- comprimento mínimo e máximo de 8 caracteres;
- nenhum valor fora do padrão de 8 dígitos numéricos.

Esses resultados descrevem o recorte analisado e não são tratados como regra normativa universal para todos os dados do CNES.

### Destino FHIR revisado

Recurso:

`Organization`

Elemento:

`Organization.address.postalCode`

O valor será preservado como `string`.

Mesmo quando composto apenas por dígitos, CEP é um código postal e não uma grandeza quantitativa. A conversão para número poderia eliminar zeros à esquerda e alterar o valor.

### Revisão da decisão de modelagem

A versão inicial desta decisão representava o CEP em `Location.address.postalCode` e gerava um recurso `Location` separado da `Organization`.

A revisão identificou que os dois recursos eram apenas agrupados no mesmo `Bundle`, sem uma referência FHIR explícita que demonstrasse que o `Location` contendo o CEP correspondia à `Organization` identificada pelo CNES.

A existência de `Location.managingOrganization` não foi considerada evidência suficiente para utilizá-lo automaticamente, pois a relação administrativa expressa por esse elemento exige justificativa semântica própria.

Nesta implementação mínima, o CEP permanece associado diretamente à `Organization` por meio de `Organization.address.postalCode`. Não será criado um recurso `Location` independente apenas para transportar o CEP.

Um recurso `Location` poderá ser avaliado futuramente caso existam dados e requisitos semânticos suficientes para representar uma localização física como entidade independente e estabelecer sua relação com a organização.

### Escopo da decisão

Este mapeamento valida somente o componente `postalCode`.

Ele não significa que o endereço completo em `Organization.address` esteja mapeado. Os demais componentes do tipo `Address` exigem análise independente e não fazem parte desta implementação.

### Classificação

**DIRETO**

Não foi identificada perda semântica relevante na representação do valor do CEP como `Organization.address.postalCode`. A decisão sobre o recurso que contém o endereço foi revisada separadamente para evitar a criação de uma relação entre `Organization` e `Location` sem evidência suficiente.

---

## 7. Decisão 03 — tipo_esfera_administrativa

### Origem e comportamento observado

Campo tratado no conjunto utilizado pelo projeto:

`tipo_esfera_administrativa`

Campo correspondente investigado na origem consultada:

`ESFERA_A`

A análise temporal mostrou descontinuidade na representação do campo:

- em outubro de 2015, foram observados códigos numéricos de `1` a `4`;
- de novembro de 2015 até julho de 2025, o campo permaneceu sem preenchimento no período analisado;
- em julho de 2025, no conjunto obtido via PySUS com `source="origin"`, `ESFERA_A` estava representado como string vazia (`''`) nos 108.732 registros observados;
- em agosto de 2025, no mesmo caminho de origem, foram observadas 108.603 ocorrências de `ESFERA_A = M` com `TPGESTAO = M` e 631 ocorrências de `ESFERA_A = E` com `TPGESTAO = E`.

Esse comportamento demonstra uma ruptura temporal na representação de `ESFERA_A` entre julho e agosto de 2025 e mostra que essa ruptura já está presente no conjunto obtido a montante da Base dos Dados.

### Interpretação da evidência

A coincidência observada entre `ESFERA_A` e `TPGESTAO` a partir de agosto de 2025 não demonstra equivalência semântica entre os campos.

A evidência histórica reforça essa cautela: em outubro de 2015, `tipo_esfera_administrativa` apresentava códigos numéricos de `1` a `4`, enquanto `tipo_gestao` utilizava valores como `M` e `E`, mostrando que os campos já tiveram representações distintas.

Na implementação atual consultada da pipeline da Base dos Dados, `tipo_gestao` deriva de `TPGESTAO` e `tipo_esfera_administrativa` deriva de `ESFERA_A`. Não foi identificada regra explícita no modelo dbt atual que copie `tipo_gestao` para `tipo_esfera_administrativa`.

Essa observação enfraquece a hipótese de espelhamento explícito no modelo atual, mas não comprova qual implementação foi utilizada em todas as cargas históricas.

### Limitações

A investigação de proveniência permite localizar a ruptura a montante da Base dos Dados, mas não determina sua causa.

Não foi estabelecido, com a evidência disponível, se a mudança decorreu de alteração de sistema, regra de geração ou carga, recodificação, mudança normativa ou outro processo na origem.

Também não foi comprovado que os valores `M` e `E` em `ESFERA_A` representem semanticamente o mesmo conceito expresso por `TPGESTAO`.

### Decisão FHIR

`tipo_esfera_administrativa` não será mapeado para um elemento FHIR enquanto seu significado semântico e a relação conceitual com `tipo_gestao` não estiverem comprovados.

Não será reutilizado o mapeamento de `tipo_gestao`, nem serão criados `system`, `code` ou `display` por inferência a partir da coincidência dos valores observados.

### Classificação

**SEM CORRESPONDÊNCIA CLARA**

A ausência de evidência semântica suficiente impede a escolha de um elemento FHIR sem risco de consolidar como regra conceitual uma coincidência observada nos dados.


---

## 8. Decisão 04 — tipo_unidade

### Origem e conceito

Campo tratado no conjunto utilizado pelo projeto:

`tipo_unidade`

Campo correspondente investigado na origem consultada:

`TP_UNID`

O campo representa uma classificação relacionada ao tipo do estabelecimento e possui correspondência conceitual candidata com `Organization.type`, cujo tipo em FHIR R4 é `CodeableConcept`.

Essa correspondência conceitual, porém, não autoriza a transformação automática de qualquer valor bruto em um `Coding` FHIR. Os valores precisam possuir significado e sistema terminológico suficientemente validados.

### Proveniência do código 16

Na competência de novembro de 2025 para São Paulo, a investigação identificou cinco estabelecimentos com `TP_UNID = 16`:

- `4932609`;
- `5767032`;
- `5828953`;
- `9340459`;
- `9570365`.

A consulta realizada via PySUS com `source="origin"` confirmou `TP_UNID = 16` nesses registros.

Assim, no recorte investigado, o valor já estava presente no conjunto obtido da origem consultada e não foi criado pela transformação final da Base dos Dados.

Essa confirmação estabelece proveniência, mas não estabelece o significado terminológico do código.

### Investigação temporal reproduzível

A evolução temporal do código `16` foi reproduzida em `sql/19-validacao-historico-tipo-unidade-16.sql`, na janela de 2024-01 a 2026-02. Dentro dessa janela pesquisada, a primeira ocorrência nacional observada foi em 2025-09; essa constatação não estabelece que setembro de 2025 tenha sido a primeira ocorrência histórica absoluta do código.

Os cinco estabelecimentos de São Paulo apresentavam códigos anteriores distintos antes de assumir o valor `16`. O estabelecimento CNES `5767032`, por exemplo, passou de `36` para `16` em 2025-11 e voltou a `36` em 2026-02. Nacionalmente, os registros com código `16` cresceram de 10 estabelecimentos em 7 UFs em 2025-09 para 86 estabelecimentos em 18 UFs em 2026-02.

A série temporal comprova ocorrência e evolução do valor nos dados consultados, mas não determina seu significado terminológico nem autoriza inferência de `system`, `code` ou `display` FHIR.

### Investigação terminológica

O significado oficial de `TP_UNID = 16` não foi comprovado de forma suficiente para sustentar a geração de um `Coding` FHIR.

Na interface histórica consultada do CNES Web para São Paulo e competência novembro de 2025, o código `16` não foi localizado entre os tipos apresentados no domínio consultado. A chamada direta com `VTipo=16` carregou a estrutura da página de listagem, mas não apresentou estabelecimentos. Um controle positivo com um tipo reconhecido retornou registros normalmente.

Também foram consultadas as fichas atuais dos cinco estabelecimentos. Entre elas, duas apresentaram tipos preenchidos e diferentes entre si — `CLINICA/CENTRO DE ESPECIALIDADE` e `CONSULTORIO ISOLADO` — enquanto três apresentaram `Tipo Estabelecimento` sem valor exibido.

Essas fichas representam o estado atual consultado e não são temporalmente equivalentes ao recorte de novembro de 2025. Portanto, seus valores atuais não podem ser utilizados como tradução retroativa do código `16`.

A causa das diferenças observadas entre o recorte histórico e as fichas atuais não foi determinada.

Como verificação terminológica adicional, os 38 códigos distintos de `tipo_unidade` observados no recorte SP/2025-11 foram comparados com o ValueSet `BRTipoEstabelecimentoSaude` publicado no Guia de Implementação de Terminologias do Brasil, versão consultada 1.1.0, cujo artefato estava informado como ativo desde 2026-08-22. A comparação reproduzível está registrada em `sql/16-validacao-tipo_unidade-terminologia-fhir.sql`.

Dos 38 códigos observados, 37 aparecem entre os 39 conceitos do ValueSet consultado. O único código observado que não aparece nessa versão terminológica é o `16`, presente em 5 estabelecimentos. Os códigos `32` e `64` pertencem ao ValueSet consultado, mas não foram observados no recorte SP/2025-11.

Essa comparação reforça que o código `16` não possui cobertura na versão terminológica consultada, mas não demonstra que ele nunca tenha possuído significado oficial no período histórico de novembro de 2025. O artefato terminológico consultado é posterior ao snapshot analisado e, portanto, não autoriza inferência retroativa de significado.

### Decisão FHIR

`tipo_unidade` poderá alimentar `Organization.type` somente quando o valor de origem possuir significado terminológico e sistema de codificação comprovados.

Valores não validados não gerarão `Coding`.

Para `TP_UNID = 16`, no estado atual da investigação:

- não será inferido `system`;
- não será atribuído `display` por suposição;
- não será gerado `Coding` em `Organization.type`;
- a exceção permanecerá registrada como questão terminológica em aberto.

### Classificação

**DEPENDENTE DE TRANSFORMAÇÃO**

A correspondência conceitual entre tipo do estabelecimento e `Organization.type` é suficiente para definir o destino arquitetural do campo, mas a transformação depende da validação terminológica de cada valor utilizado.

O código `16` permanece bloqueado porque sua proveniência foi confirmada, mas sua semântica não foi estabelecida de forma suficiente para interoperabilidade.


---

## 9. Decisão 05 — tipo_natureza_administrativa

### Origem e significado histórico

O campo tratado `tipo_natureza_administrativa` corresponde ao campo `natureza` no modelo SQL público atual da Base dos Dados.

A investigação de outubro de 2015, em São Paulo, identificou os 13 códigos históricos de 1 a 13. Suas frequências coincidiram integralmente entre a Base dos Dados e o conjunto consultado via PySUS com `source="origin"`. Também foram conferidos individualmente 13 estabelecimentos, um para cada código, com 13 correspondências corretas.

O dicionário da Base dos Dados apresenta as descrições históricas desses códigos, referentes à natureza da organização. Também contém os códigos 0 e 99, que não apareceram na distribuição investigada de outubro de 2015.

### Descontinuidade temporal e proveniência

Na tabela nacional da Base dos Dados, o campo esteve praticamente integralmente preenchido entre 2005 e outubro de 2015. A partir de novembro de 2015, todos os registros consultados apresentaram valores nulos, inclusive no recorte principal de São Paulo, novembro de 2025.

No conjunto obtido via PySUS para São Paulo, outubro de 2015, `NATUREZA` apresentou os 13 códigos históricos. Em novembro de 2015, a coluna continuava presente, mas seus 68.471 registros continham strings vazias.

Portanto, o esvaziamento já aparece no conjunto obtido da origem consultada e não somente na tabela final tratada.

O modelo SQL público atual confirma a transformação de `natureza` em `tipo_natureza_administrativa`. Contudo, sua regra atual converteria diretamente uma string vazia em 0, enquanto a tabela histórica apresenta valores nulos. A representação efetiva no staging e a versão histórica da transformação não foram verificadas. O acesso ao staging foi negado, e a causa exata dessa diferença permanece indeterminada.

### Decisão FHIR

O significado histórico do campo apresenta correspondência conceitual possível com `Organization.type`, elemento do tipo `CodeableConcept` no FHIR R4.

A representação histórica somente poderá gerar `Coding` após validação do sistema terminológico, do domínio de códigos e da representação canônica dos valores. O dicionário consultado fornece descrições, mas não estabelece, por si só, um `Coding.system` oficialmente validado para esta implementação.

No recorte principal de novembro de 2025, o campo não possui valores. Não será gerado `Coding` de natureza administrativa, nem será utilizado `id_natureza_juridica` ou um valor histórico como substituto.

### Classificação

**DEPENDENTE DE TRANSFORMAÇÃO**

A classificação registra uma possibilidade de representação conceitual dos valores históricos, não uma autorização para implementar a conversão terminológica neste momento.

A ausência de valores no recorte atual, a falta de validação do sistema terminológico e a causa indeterminada da descontinuidade permanecem como limitações explícitas.

---

## 10. Decisão 06 — id_natureza_juridica

### Origem e significado

O campo `id_natureza_juridica`, na tabela
`basedosdados.br_ms_cnes.estabelecimento`, corresponde ao campo
`NAT_JUR` dos arquivos de estabelecimentos do CNES.

Não deve ser confundido com `tipo_natureza_administrativa`,
associado ao campo histórico `NATUREZA`, descontinuado nas
competências mais recentes.

Na competência de novembro de 2025, para São Paulo, foram
observados 110.362 registros, 41 códigos distintos não vazios
de natureza jurídica e ausência de valores nulos ou vazios
nesse campo.

A completude sintática não comprova a validade terminológica
ou a atualização cadastral de todos os códigos.

### Distinção terminológica: CONCLA e equivalência CNES

A Tabela de Natureza Jurídica da CONCLA/IBGE de 2021
documenta, entre outras categorias, `206-2` (Sociedade
Empresária Limitada) e `224-0` (Sociedade Simples Limitada).

Os valores correspondentes observados no conjunto tratado
são `2062` e `2240`, sem o hífen utilizado na apresentação
dos códigos pela CONCLA.

O artigo 236 da Portaria de Consolidação SAES/MS nº 1/2022
estabelece tratamento específico para pessoas físicas
cadastradas no CNES, atribuindo o código `400-0` para fins
de equivalência em pesquisa.

Essa disposição normativa não autoriza apresentar `4000`
como uma categoria individual da Tabela de Natureza Jurídica
da CONCLA de 2021.

Para a implementação FHIR, é necessário distinguir a
classificação publicada pela CONCLA da regra específica
de equivalência utilizada no CNES.

A existência de uma regra normativa não comprova, por si
só, a publicação de um CodeSystem FHIR com URI canônica
oficial para representar essa regra.

Até que os sistemas terminológicos, suas identificações
e suas versões aplicáveis sejam validados, não serão
gerados Coding para esses códigos.

Os valores originais, sua competência e sua proveniência
serão preservados para evitar atribuições terminológicas
não comprovadas.

Fontes:
- CONCLA/IBGE — Tabela de Natureza Jurídica 2021,
  Notas Explicativas:
  https://concla.ibge.gov.br/images/concla/documentacao/CONCLA-TNJ2021-NotasExplicativas.pdf
- Portaria de Consolidação SAES/MS nº 1/2022,
  artigo 236.
- HL7 FHIR R4 — Coding e CodeableConcept:
  https://hl7.org/fhir/R4/datatypes.html

### Investigação temporal de códigos históricos

Foram investigadas as transições individuais entre novembro
e dezembro de 2022, utilizando `id_estabelecimento_cnes`
como identificador de acompanhamento.

A reprodução quantitativa dessa investigação está registrada em `sql/18-validacao-transicoes-natureza-juridica-2022.sql`.

| Código em novembro | Situação em dezembro | Estabelecimentos |
|---|---|---:|
| 2305 | 2062 | 1.470 |
| 2305 | 2305 | 499 |
| 2305 | Não localizado em SP | 18 |
| 2305 | 2054 | 1 |
| 2313 | 2240 | 606 |
| 2313 | 2313 | 140 |
| 2313 | Não localizado em SP | 3 |
| 2313 | 2062 | 2 |

As coortes continham, respectivamente, 1.988 e 751
estabelecimentos. Não foram identificadas duplicidades
dos identificadores nos resultados dessas comparações.

As transições predominantes observadas foram `2305 → 2062`
e `2313 → 2240`. Esses resultados não autorizam regras
universais de conversão de registros históricos.

A reconciliação completa do código `2240` identificou
8.577 registros em novembro e 9.194 em dezembro de 2022:
661 entradas e 44 saídas, resultando na variação líquida
de 617 estabelecimentos.

A reconciliação quantitativa não demonstra a causa
administrativa nem a validade semântica de cada alteração.

### Contexto normativo e defasagem cadastral

O artigo 41 da Lei nº 14.195/2021 estabeleceu a transformação
automática das EIRELIs existentes em sociedades limitadas
unipessoais, independentemente de alteração do ato constitutivo.

O Ofício Circular SEI nº 4856/2022/ME, de 9 de dezembro de
2022, documentou dificuldades técnicas na implementação dessa
transformação nos sistemas governamentais e informou a
atualização cadastral pela Receita Federal prevista para
10 de dezembro de 2022.

As transições `2305 → 2062` e `2313 → 2240` observadas
no CNES entre novembro e dezembro de 2022 são compatíveis
com esse contexto normativo e operacional. Entretanto,
a análise longitudinal não demonstra que cada alteração
tenha sido causada diretamente pela atualização da
Receita Federal.

A presença dos códigos históricos `2305` e `2313` deve
ser interpretada considerando a competência do registro,
a vigência jurídica e a possível defasagem entre os
sistemas cadastrais.

Não serão realizadas conversões retroativas automáticas,
nem os registros históricos serão classificados como
erros exclusivamente por apresentarem códigos anteriores
à atualização cadastral.

Fontes:
- Lei nº 14.195/2021, artigo 41:
  https://www.planalto.gov.br/ccivil_03/_ato2019-2022/2021/lei/l14195.htm
- Ofício Circular SEI nº 4856/2022/ME:
  https://www.gov.br/empresas-e-negocios/pt-br/drei/legislacao/arquivos/oficios-circulares-drei/2022/SEI_30141120_Oficio_Circular_4856.pdf

### Investigação complementar: transições 4000 → 2240

A reconciliação identificou dois estabelecimentos que
passaram de `4000` para `2240` entre novembro e dezembro
de 2022: CNES `5030714` e `9744983`.

Nos dados da Base dos Dados, ambos apresentavam em novembro
um valor de `cpf_cnpj` com 14 dígitos, três zeros iniciais
e 11 dígitos restantes.

Após a remoção dos três zeros, ambos os candidatos passaram
na validação matemática de CPF.

Em dezembro, os documentos associados aos dois
estabelecimentos eram diferentes dos registrados em
novembro. Ambos continuavam com 14 dígitos, mas apresentavam
padrões distintos de zeros iniciais.

Esses resultados são compatíveis com alteração do
identificador fiscal associado aos estabelecimentos.
Não comprovam, isoladamente, a causa administrativa
da mudança de natureza jurídica.

### Proveniência dos zeros iniciais

**Fonte examinada:** arquivo `STSP2211.dbc`, distribuído
pelo FTP do DATASUS, correspondente aos estabelecimentos
de São Paulo na competência novembro de 2022.

**Diretório de origem:**
`/dissemin/publicos/CNES/200508_/Dados/ST/`

**SHA-256 da cópia examinada:**

`95c1418219362d1255850392801e5e2131844549c4131f06fa08076da60e4e75`

**Procedimento:** o arquivo DBC foi preservado localmente.
Uma cópia temporária foi processada com PySUS 2.11.1,
em contêiner Docker. A análise não modificou o arquivo
original e não exibiu os documentos completos.

Nos dois estabelecimentos, a leitura do DBC apresentou:

| CNES | PF_PJ | NAT_JUR | Dígitos | Zeros iniciais | Restantes |
|---|---|---|---:|---:|---:|
| 5030714 | 1 | 4000 | 14 | 3 | 11 |
| 9744983 | 1 | 4000 | 14 | 3 | 11 |

Foi encontrado exatamente um registro de cada
estabelecimento no arquivo examinado.

O significado normativo de `PF_PJ = 1` não foi utilizado
como prova independente nesta investigação, pois seu
domínio ainda não foi formalmente validado.

**Conclusão comprovada:** o padrão de três zeros iniciais
seguido de 11 dígitos já estava presente na representação
do arquivo DBC distribuído pelo DATASUS, conforme a
leitura realizada pelo PySUS. Portanto, sua presença
nesses dois registros não surgiu exclusivamente no
processamento da Base dos Dados.

**Limites da evidência:** não foi determinada a etapa
anterior à publicação do DBC em que os zeros foram
originalmente acrescentados. Também não foi realizada
uma comparação integral dos documentos entre DBC e
BigQuery; a correspondência demonstrada foi estrutural,
para os mesmos identificadores e competência.

A validade matemática dos candidatos a CPF foi testada
sobre os valores da Base dos Dados, não constitui
verificação de titularidade e não confirma a situação
cadastral dos documentos na Receita Federal.

### Avaliação de CodeSystems FHIR publicados

Foram examinadas duas publicações FHIR de natureza
jurídica:

**RNDS — BRNaturezaJuridica, versão 1.0.0**

A publicação consultada, identificada como versão
de desenvolvimento, apresenta os conceitos `1` e
`101-5`. Seu conteúdo publicado não cobre o conjunto
de códigos observado no recorte do projeto.

**SES-GO — Natureza Jurídica, versão 1.1.0**

O guia de implementação da SES-GO, identificado como
`draft`, publica diversos códigos relevantes para
a investigação, incluindo `2062`, `2240`, `2305`,
`2313` e `4000`.

Nessa publicação, `4000` representa o grupo
"Pessoas Físicas". Essa representação não deve
ser automaticamente confundida com a finalidade
específica de equivalência em pesquisa prevista
para o código `400-0` na regulamentação do CNES.

A utilização de um CodeSystem publicado por outra
instituição não é proibida pelo FHIR. Entretanto,
sua adoção exige avaliação de cobertura, semântica,
versão, governança e requisitos de interoperabilidade.

**Decisão para esta versão do projeto**

Nenhuma das duas publicações será adotada nesta
implementação para gerar automaticamente `Coding`
a partir de `id_natureza_juridica`.

Os valores originais permanecerão preservados na
camada de dados, associados à competência e à
proveniência. A ausência desse campo nos recursos
FHIR gerados será registrada como limitação
deliberada de cobertura terminológica.

A escolha ou criação de um CodeSystem adequado
fica registrada como evolução futura, não como
impedimento para implementar os demais campos
já aprovados.

Fontes:
- RNDS — BRNaturezaJuridica:
  https://rnds-fhir.saude.gov.br/CodeSystem-BRNaturezaJuridica.html
- SES-GO — Natureza Jurídica:
  https://fhir.saude.go.gov.br/r4/core/CodeSystem-natureza-juridica.html
- HL7 FHIR R4 — Coding:
  https://hl7.org/fhir/R4/datatypes.html

### Decisão FHIR provisória

`Organization.type` permanece como destino conceitual
candidato para representar a natureza jurídica do
estabelecimento, condicionado à validação terminológica.

Não foi estabelecido um `CodeSystem` FHIR com URI,
versão e domínio comprovados para todos os códigos
observados. O código `4000` exige tratamento específico
por sua função de equivalência normativa para pessoas
físicas no CNES.

Não serão aplicadas conversões automáticas entre os
códigos históricos `2305`, `2313`, `2062` e `2240`.

Os valores originais deverão ser preservados, juntamente
com sua competência e proveniência.

### Classificação

**DEPENDENTE DE TRANSFORMAÇÃO — CODIFICAÇÃO ADIADA NESTA VERSÃO.**

Pendências: validar o sistema terminológico e sua
vigência temporal, definir uma codificação FHIR
sustentada por fonte oficial e estabelecer o tratamento
das exceções sem reescrever os registros históricos.

---

## 11. Decisão 07 — cpf_cnpj

### Escopo e perfilamento

Fonte: `basedosdados.br_ms_cnes.estabelecimento`.
Recorte: São Paulo, novembro de 2025, 110.362 registros.

O campo apresentou 11.803 strings vazias e 98.559 valores
preenchidos. Todos os valores preenchidos examinados
possuíam 14 dígitos.

Entre os valores preenchidos, 34.400 começavam com `000`,
enquanto 64.159 apresentavam outros padrões de 14 dígitos.

### Cruzamento com a natureza jurídica

Dos 34.125 registros com `id_natureza_juridica = 4000`,
34.124 apresentavam documento com prefixo `000`.
Um registro apresentava outro padrão de 14 dígitos.

Entre as demais naturezas jurídicas, 276 documentos
apresentavam prefixo `000`.

### Validação matemática

Os valores com prefixo `000` foram submetidos aos
algoritmos de dígitos verificadores de CPF, considerando
os últimos 11 dígitos, e de CNPJ, considerando os
14 dígitos completos.

Os demais documentos numéricos de 14 dígitos foram
submetidos ao algoritmo de CNPJ.

| Resultado matemático | Natureza 4000 | Outras naturezas | Total |
|---|---:|---:|---:|
| Somente CPF válido | 33.179 | 189 | 33.368 |
| Somente CNPJ válido | 1 | 64.240 | 64.241 |
| Válido nos dois algoritmos | 945 | 5 | 950 |
| Documento ausente | 0 | 11.803 | 11.803 |
| **Total** | **34.125** | **76.237** | **110.362** |

Os 276 documentos com prefixo `000` fora do grupo
`4000` foram distribuídos por código de natureza
jurídica. O código `2062` concentrou 176 registros,
dos quais 142 passaram somente no algoritmo de CPF,
32 somente no de CNPJ e dois em ambos.

### Limites da evidência

A validação matemática não comprova existência,
titularidade, situação cadastral ou tipo fiscal
efetivo do documento.

O prefixo `000` não determina isoladamente que
o valor representa um CPF. Os 950 documentos que
passaram nos dois algoritmos permanecem
matematicamente ambíguos.

Nenhuma ocorrência será classificada automaticamente
como erro cadastral apenas pela combinação entre
natureza jurídica e resultado do algoritmo.

### Situação do mapeamento FHIR

O perfilamento estrutural e a validação matemática
estão concluídos para o recorte analisado.

`Organization.identifier` é um destino conceitual
possível para identificadores fiscais adequadamente
classificados e associados ao estabelecimento.

Entretanto, o campo `cpf_cnpj` mistura representações
de documentos fiscais. O comprimento, o prefixo `000`
e a validação matemática não comprovam isoladamente
o tipo fiscal, a titularidade ou a situação cadastral
dos documentos.

Nesta versão, não serão gerados identificadores FHIR
de CPF ou CNPJ. O valor original permanecerá
preservado na camada de dados, sujeito aos controles
de privacidade apropriados.

Os recursos `Organization` continuarão identificáveis
pelo número CNES, conforme a Decisão 01.

### Classificação

**DEPENDENTE DE TRANSFORMAÇÃO — IDENTIFICADOR FISCAL
NÃO IMPLEMENTADO NESTA VERSÃO.**

Evolução futura: definir regras verificáveis de
classificação documental, titularidade, pertinência
ao recurso FHIR, sistemas de identificação e
proteção de dados pessoais antes de implementar
qualquer identificador fiscal.

Não publicar documentos fiscais completos nos
exemplos, logs ou arquivos versionados.

---

## 12. Decisão 08 — cnpj_mantenedora

### Origem e significado

O campo `cnpj_mantenedora` registra o CNPJ da entidade
cadastrada como mantenedora do estabelecimento no CNES.

Segundo a documentação do CNES, a mantenedora provê
recursos necessários ao funcionamento do estabelecimento,
quando aplicável. O cadastro possui critérios específicos
de elegibilidade.

Fonte:
https://wiki.saude.gov.br/cnes/index.php/SCNES_-_Guia_de_Preenchimento

### Perfilamento e validação matemática

Recorte: São Paulo, novembro de 2025, 110.362 registros.

| Resultado | Registros |
|---|---:|
| String vazia | 98.098 |
| CNPJ preenchido com 14 dígitos | 12.264 |
| CNPJ preenchido matematicamente válido | 12.264 |
| CNPJ preenchido matematicamente inválido | 0 |

A ausência geral não será classificada automaticamente
como erro, pois a aplicabilidade do campo depende
das condições cadastrais da mantenedora.

A validade matemática não comprova titularidade
ou regularidade cadastral perante a Receita Federal.

### Relação com o documento do estabelecimento

O cruzamento reproduzível entre o CNPJ da mantenedora, o documento do estabelecimento e a natureza jurídica está registrado em `sql/17-validacao-relacao-cnpj-mantenedora.sql`.

Entre os 12.264 registros com CNPJ da mantenedora:

| Situação | Registros |
|---|---:|
| Documento próprio ausente | 11.803 |
| Documento próprio preenchido e diferente | 461 |
| Documento próprio idêntico ao da mantenedora | 0 |

O CNPJ da mantenedora não será utilizado para preencher
documentos fiscais ausentes do estabelecimento.

O grupo de natureza jurídica `1244` apresentou
10.161 registros com documento próprio ausente
e CNPJ da mantenedora preenchido.

Foram encontradas também ocorrências de CNPJ
de mantenedora em naturezas jurídicas que exigem
avaliação adicional de consistência cadastral.
Essas ocorrências não serão classificadas como
erros comprovados apenas pelo cruzamento realizado.

### Decisão FHIR

Um recurso `Organization` separado é um destino
conceitual possível para representar uma mantenedora,
com seu próprio identificador fiscal.

Entretanto, `Organization.partOf` representa uma
hierarquia estrita entre organizações. A relação
administrativa de mantenedora no CNES não será
automaticamente convertida nessa hierarquia.

Nesta versão, não serão criados recursos FHIR
separados para mantenedoras nem relações `partOf`
derivadas de `cnpj_mantenedora`.

Os valores originais e a competência permanecerão
preservados na camada de dados.

### Classificação

**DEPENDENTE DE TRANSFORMAÇÃO — RELAÇÃO FHIR
NÃO IMPLEMENTADA NESTA VERSÃO.**

Evolução futura: validar a representação da
mantenedora como organização separada e escolher
o modelo FHIR adequado à relação administrativa,
antes de gerar recursos e referências.

Referências:
- CNES — Guia de Preenchimento:
  https://wiki.saude.gov.br/cnes/index.php/SCNES_-_Guia_de_Preenchimento
- HL7 FHIR R4 — Organization:
  https://hl7.org/fhir/R4/organization-definitions.html

---

## 13. Decisão 09 — tipo_atividade_ensino_pesquisa

### Origem e domínio

O campo `tipo_atividade_ensino_pesquisa` pertence
à tabela `estabelecimento` da Base dos Dados.

O dicionário consultado apresenta os códigos:

| Código | Descrição |
|---|---|
| 1 | unidade universitaria |
| 2 | unidade escola superior isolada |
| 3 | unidade auxiliar de ensino |
| 4 | unidade sem atividade de ensino |
| 5 | hospital de ensino |
| 99 | atividade ensino nao informada |

O valor retornado em `cobertura_temporal` foi `(1)`.
Não foi estabelecida sua interpretação normativa
ou sua equivalência a um intervalo de vigência.

### Perfilamento

Recorte: São Paulo, novembro de 2025.
Total: 110.362 registros.

| Código | Registros | Percentual |
|---|---:|---:|
| 1 | 239 | 0,22% |
| 2 | 181 | 0,16% |
| 3 | 1.068 | 0,97% |
| 4 | 108.828 | 98,61% |
| 5 | 46 | 0,04% |
| 99 | 0 | 0% |

Todos os registros apresentaram valores incluídos
no domínio do dicionário consultado.

Não foram observadas ausências sintáticas no recorte.

A correspondência com o dicionário não comprova
a correção cadastral individual dos estabelecimentos.

### Avaliação semântica FHIR

No FHIR R4, `Organization.type` classifica o tipo
de organização. `Location.type` descreve a função
exercida em um local.

A classificação de atividade de ensino do CNES
não será considerada automaticamente equivalente
a nenhum desses elementos.

Não foi definido um perfil ou extensão FHIR
que represente integralmente o domínio consultado
no escopo atual do projeto.

### Decisão FHIR

O campo não será incluído nos recursos
`Organization` ou `Location` desta versão.

Seu valor original, competência e proveniência
permanecerão preservados na camada de dados.

### Classificação

**SEM CORRESPONDÊNCIA CLARA — NÃO IMPLEMENTADO
NESTA VERSÃO.**

Evolução futura: avaliar um perfil ou extensão
FHIR específico, com definição semântica,
terminologia e critérios de validação.

Referências:
- Base dos Dados, tabela
  `basedosdados.br_ms_cnes.dicionario`.
- HL7 FHIR R4 — Organization:
  https://hl7.org/fhir/R4/organization.html
- HL7 FHIR R4 — Location:
  https://hl7.org/fhir/R4/location-definitions.html

---

## 14. Decisão 10 — tipo_gestao

### Origem e significado

O campo `tipo_gestao` deriva de `TPGESTAO` na origem
consultada do CNES.

No recorte de São Paulo, novembro de 2025, foram
observados somente os valores `M` (municipal) e `E`
(estadual).

Em verificação posterior reproduzida no
`sql/11-completude-tipo_gestao.sql`, a tabela
`basedosdados.br_ms_cnes.dicionario` retornou para o campo
os valores `D = dupla`, `E = estadual`, `M = municipal`,
`S = sem gestao` e `Z = nao informado`.

Assim, `M` e `E` representam o domínio observado no recorte
SP/nov-2025, enquanto `D`, `E`, `M`, `S` e `Z` representam
o domínio registrado no dicionário do conjunto consultado.
A tabela `dicionario` é utilizada como fonte auxiliar do
conjunto e não, por si só, como terminologia FHIR oficial.

O campo descreve a esfera de gestão do estabelecimento
no contexto administrativo do CNES.

### Distinção entre os campos

`tipo_gestao` não deve ser confundido com
`tipo_esfera_administrativa`, derivado de `ESFERA_A`.

A investigação da Decisão 03 identificou períodos
em que os dois campos tinham representações
diferentes. Sua coincidência posterior de valores
não comprova equivalência semântica.

### Decisão FHIR

A esfera administrativa de gestão não será
convertida automaticamente em `Organization.type`.

Não foi aprovado um elemento FHIR, perfil ou
extensão que represente suficientemente esse
conceito no escopo atual.

O valor de origem e sua competência permanecerão
preservados na camada de dados.

### Classificação

**SEM CORRESPONDÊNCIA CLARA — NÃO IMPLEMENTADO
NESTA VERSÃO.**

Uma representação futura dependerá de definição
semântica explícita e de validação dos requisitos
de interoperabilidade.

---

## 15. Estado dos mapeamentos selecionados

Os dez campos selecionados para esta versão foram
analisados e possuem decisões documentadas.

A conclusão da análise não implica que todos
serão incluídos nos recursos FHIR.

Os campos sem representação aprovada permanecerão
preservados na camada de dados, conforme as
limitações e decisões registradas individualmente.

A validação terminológica de `TP_UNID = 16`
continua em aberto e não autoriza a geração
de `Coding` para esse valor.

---

## 16. Questões terminológicas em aberto

### `tipo_unidade`

A investigação realizada no projeto identificou a ocorrência de `tipo_unidade = 16` nos dados obtidos da origem do CNES.

A proveniência do valor foi confirmada no conjunto obtido da origem, mas seu significado terminológico não foi estabelecido de forma suficiente para sustentar um `Coding` FHIR.

Portanto:

- a proveniência do código não equivale à validação de seu significado;
- nenhum `display` será inventado;
- nenhum sistema terminológico será atribuído sem evidência;
- o destino conceitual do campo está definido como `Organization.type` (**DEPENDENTE DE TRANSFORMAÇÃO**), mas isso não aprova automaticamente seus valores;
- `TP_UNID = 16` permanece bloqueado para geração de `Coding` até que seu significado e o sistema terminológico sejam comprovados.

---

## 17. Estado da implementação e fechamento da Fase 6

A revisão corretiva da Fase 6 consolidou o escopo efetivamente implementado e as limitações que permanecem abertas.

### Implementação aprovada

Nesta versão, o conversor gera um `Bundle` FHIR R4 do tipo `collection` contendo uma única `Organization` com:

- `Organization.identifier`, utilizando o identificador CNES;
- `Organization.identifier.system = https://saude.gov.br/fhir/sid/cnes`;
- `Organization.address.postalCode`, utilizando o CEP.

A criação de um recurso `Location` independente não foi aprovada apenas para transportar o CEP.

Os demais campos analisados permanecem não implementados quando sua representação exigiria inferência semântica, relação não comprovada, tratamento de dado fiscal potencialmente pessoal ou terminologia insuficientemente validada.

### Rastreabilidade e validação

A revisão passou a registrar explicitamente que:

- os dez campos da matriz constituem o escopo efetivamente analisado nesta versão, sem pretensão de cobertura exaustiva das 204 colunas da tabela;
- o critério histórico usado para escolher esses dez campos não foi recuperado nos artefatos disponíveis;
- o critério original de seleção dos cinco estabelecimentos usados como exemplos FHIR também não foi recuperado;
- o `sql/14-proveniencia-exemplos-fhir.sql` confirma, entretanto, que cada par CNES/CEP versionado pertence à mesma linha da fonte analítica no recorte SP/nov-2025;
- a proveniência de um valor não é tratada como prova de seu significado terminológico.

O conversor utiliza `uuid5` determinístico para o `fullUrl` da `Organization` e aplica, como restrições de entrada desta implementação, CNES com exatamente 7 dígitos e CEP com exatamente 8 dígitos. Essas verificações estruturais não comprovam que um par CNES/CEP pertence ao mesmo registro; essa correspondência deve ser validada a montante.

A suíte automatizada em `tests/test_fase6_conversor_fhir.py` possui 13 testes e foi reexecutada com sucesso na verificação final de 2026-10-06.

Os cinco exemplos versionados possuem registro consolidado de validação com FHIR Validator CLI 6.10.4, FHIR R4 4.0.1 e `-tx n/a`, em `fhir/validacao/validacao-cinco-bundles-cnes.log`.

### Fechamento corretivo

A reconciliação documental, a reexecução da suíte automatizada e a revalidação dos cinco Bundles FHIR foram concluídas. Os 13 testes automatizados passaram na verificação final, e os cinco exemplos FHIR R4 foram aprovados novamente pelo FHIR Validator CLI 6.10.4 com `0 errors` e `0 warnings`.

Com a reconciliação documental, a reexecução dos testes e a revalidação dos exemplos FHIR, a revisão corretiva da Fase 6 encontra-se tecnicamente concluída.

---

## 18. Referências técnicas

### Sistema identificador CNES

- **Ministério da Saúde — Guia de Implementação de Terminologias do Brasil — NamingSystemCNES.** URL canônica do artefato: `https://terminologia.saude.gov.br/fhir/NamingSystem/cnes`. O artefato registra `https://saude.gov.br/fhir/sid/cnes` como URI preferencial do sistema identificador CNES. Utilizado neste projeto para fundamentar `Organization.identifier.system`. Acesso em: 2026-10-04.

### Tipo de estabelecimento de saúde

- **Ministério da Saúde — Guia de Implementação de Terminologias do Brasil — BRTipoEstabelecimentoSaude.** ValueSet canônico: `https://terminologia.saude.gov.br/fhir/ValueSet/BRTipoEstabelecimentoSaude`. CodeSystem canônico: `https://terminologia.saude.gov.br/fhir/CodeSystem/BRTipoEstabelecimentoSaude`. Versão consultada do guia: 1.1.0. Utilizado neste projeto como referência terminológica adicional para a investigação de `tipo_unidade`; a comparação reproduzível está em `sql/16-validacao-tipo_unidade-terminologia-fhir.sql`. O artefato consultado é posterior ao recorte SP/2025-11 e, por isso, não sustenta inferência retroativa sobre o significado histórico do código `16`.
