# Diagnóstico de Qualidade e Governança de Dados em Estabelecimentos de Saúde (CNES/DATASUS)

**Versão 2 — 19/08/2026**

---

## Resumo

Este projeto usa a base pública do CNES (Cadastro Nacional de Estabelecimentos de Saúde), mantida pelo DATASUS/Ministério da Saúde, para medir a qualidade do cadastro de estabelecimentos de saúde e propor um conjunto mínimo de regras de governança a partir dos achados. Ao final, os dados tratados são mapeados para os recursos FHIR `Organization` e `Location`, como exercício de interoperabilidade.

O CNES é a base cadastral que sustenta outros sistemas do SUS — SIA, SIH, e-SUS AB. Problemas de qualidade nele se propagam para a rede inteira, o que torna o diagnóstico relevante para organizações de saúde públicas e privadas.

**Recorte:** São Paulo (SP), competência novembro/2025.
**Ferramentas:** SQL (BigQuery), Python, Power BI, Git.

---

## 1. Diagnóstico

**Problema.** Gestores tomam decisões sobre alocação de leitos, distribuição de profissionais e planejamento regional com base em cadastros que podem estar incompletos, desatualizados ou inconsistentes entre si.

**Necessidade.** Um diagnóstico com métricas de onde estão as falhas de completude, consistência e atualidade do cadastro.

**Stakeholders.** Gestores de saúde municipais e estaduais, times de dados de operadoras e hospitais, pesquisadores em saúde pública.

**Restrições.** Dados públicos, sem acesso a sistemas internos. O CNES é atualizado mensalmente, com defasagem de divulgação.

**Recorte e sua justificativa.** SP + novembro/2025. A escolha foi validada por contagem: essa combinação apresentou o maior número de estabelecimentos entre as testadas. Ganhou uma segunda justificativa após a verificação de estrutura — como `sigla_uf`, `ano` e `mes` existem em todas as tabelas envolvidas, o recorte limita o volume lido de cada uma antes das junções, o que controla o custo de processamento.

**Dependências.** Acesso ao conjunto `basedosdados.br_ms_cnes` via BigQuery Sandbox.

---

## 2. Definição do Projeto

### Objetivos

- Medir completude, consistência e atualidade do cadastro de estabelecimentos
- Aplicar três regras de consistência com base na estrutura real do CNES, incluindo uma regra que depende de conhecimento clínico
- Propor um conjunto mínimo de regras de governança e responsabilidades
- Mapear os dados tratados para os recursos FHIR `Organization` e `Location`, com validação

### Escopo

Extração de uma competência do CNES para SP; construção de indicadores de qualidade; três regras de consistência; dashboard; documento de governança; módulo de mapeamento FHIR com tabela de-para documentada.

### Não escopo

- **Tabela `profissional`.** Contém `nome`, `cartao_nacional_saude` e `id_municipio_6_residencia` — dado pessoal de profissional de saúde. A presença desse dado fica registrada como achado (seção 8), mas a tabela não é utilizada nesta versão. Decisão tomada para não introduzir risco de exposição de dado pessoal em repositório público.
- **Submissão de dados à RNDS.** O projeto mapeia dados para recursos FHIR e valida o resultado. Não envolve certificação digital, autenticação ou submissão à Rede Nacional de Dados em Saúde, que exigem credenciais indisponíveis em projeto de portfólio.
- **Modelos preditivos.** Ver seção 12.
- Integração com sistemas hospitalares; correção dos dados na fonte.

### Indicadores de sucesso

- Taxa de completude por campo crítico do cadastro
- Percentual de estabelecimentos sem atualização recente
- Número de estabelecimentos que violam cada uma das três regras de consistência
- Percentual de campos do CNES mapeados para FHIR, com os não mapeados justificados

### Critérios de aceitação

- O dashboard responde a pelo menos três perguntas de gestão definidas nesta seção
- O relatório traduz achados técnicos em recomendações compreensíveis para leitor não técnico
- Todo recurso FHIR gerado passa em validador antes de entrar no repositório
- Toda regra de consistência é rastreável até o código de origem no dicionário oficial

---

## 3. Arquitetura do Projeto

```
Fontes → Coleta → Transformação → Modelagem → Análise
       → Visualização → Governança → Interoperabilidade
       → Documentação → Entrega
```

| Etapa | O que acontece |
|---|---|
| Fontes | CNES via Base dos Dados (BigQuery) |
| Coleta | Extração de SP + nov/2025 por SQL, com agregação prévia das tabelas 1:N |
| Transformação | Limpeza em Python: nulos, tipos, padronização |
| Modelagem | Tabela analítica com uma linha por estabelecimento |
| Análise | Indicadores de qualidade e três regras de consistência |
| Visualização | Power BI |
| Governança | Framework de qualidade proposto |
| Interoperabilidade | Mapeamento para FHIR `Organization` e `Location` |
| Documentação | README, dicionário de dados, tabela de-para FHIR |

---

## 4. Arquitetura Técnica

| Camada | Ferramenta | Por quê |
|---|---|---|
| Extração | SQL / BigQuery | prática de SQL sobre dado real, sem download de arquivos grandes |
| Tratamento | Python (pandas) | limpeza e validação |
| Armazenamento intermediário | CSV ou Parquet local | suficiente para o volume do recorte |
| Visualização | Power BI | ferramenta mais cobrada em vagas de análise de dados no Brasil |
| Interoperabilidade | a definir na Fase 6 | escolha depende da versão FHIR adotada (R4 ou R5); validação é obrigatória |
| Versionamento | Git / GitHub | histórico público do raciocínio |

A camada de interoperabilidade fica sem ferramenta definida de propósito. A decisão pertence à Fase 6 e depende de pesquisa sobre qual versão do FHIR usar. O requisito fixo é que o resultado passe por um validador — um JSON com nomes de campo FHIR mas sem validação formal não é entregável.

---

## 5. Arquitetura de Dados

### Estrutura real do conjunto

O `br_ms_cnes` tem 14 tabelas. As relevantes para este projeto:

| Tabela | Colunas | Papel |
|---|---|---|
| `estabelecimento` | 204 | cadastro base, uma linha por estabelecimento por competência |
| `leito` | 10 | capacidade de leitos, uma linha por especialidade e tipo |
| `habilitacao` | 16 | habilitações, uma linha por habilitação |
| `dicionario` | 5 | tradução dos códigos das demais tabelas |

### Chave de relacionamento

`id_estabelecimento_cnes` + `ano` + `mes`.

O código do estabelecimento sozinho não basta: cada tabela é uma fotografia mensal, e o mesmo estabelecimento aparece em várias competências. Junção apenas pelo código faria a linha de novembro casar com todas as competências da outra tabela.

### Granularidade

`leito` e `habilitacao` têm múltiplas linhas por estabelecimento. Junção direta multiplica as linhas do cadastro — um hospital com 5 tipos de leito e 3 habilitações produziria 15 linhas.

**Regra fixa deste projeto:** agregar cada tabela relacionada para uma linha por estabelecimento antes de juntar com `estabelecimento`.

### Dicionário de dados

Construído a partir da tabela `dicionario`, que traduz os códigos oficiais no formato `id_tabela` / `nome_coluna` / `chave` / `valor` / `cobertura_temporal`.

Interpretações próprias entram apenas onde a fonte oficial for omissa ou ambígua, e ficam explicitamente marcadas como tal. Nenhum significado de campo é inventado. Isso torna cada definição rastreável até a origem.

### Regras de negócio

**Desatualização.** Um estabelecimento é considerado desatualizado quando `ano_atualizacao` e `mes_atualizacao` indicam intervalo superior ao corte definido na Fase 3. O corte precisa ser justificado.

**Identificação de leitos.** Toda contagem de leitos usa `tipo_especialidade_leito` **e** `tipo_leito` em conjunto. A especialidade sozinha não identifica o leito: cardiologia aparece como código 2 (cirúrgico) e 32 (clínico). Agrupar só por especialidade somaria categorias diferentes sem gerar erro.

**Identificação de UTI.** Os códigos de UTI em `tipo_especialidade_leito` são 74 a 83, 85 e 86. A faixa não é contínua — 84 é acolhimento noturno. O filtro lista os códigos explicitamente; intervalo numérico traria o código errado.

### Dimensões de qualidade

Completude, consistência, atualidade e unicidade, como categorias fixas de análise.

---

## 6. Plano de Desenvolvimento

### Fase 1 — Exploração e extração (SQL)

Entender a estrutura do CNES e escrever as queries de extração do recorte.

*Estado: concluída.* Inclui a verificação de estrutura documentada em `docs/achados-verificacao-estrutura.md`, que confirmou onde estão os dados de capacidade instalada e quais são as chaves de junção.

**Entregável:** base extraída, estatísticas descritivas, `sql/01-exploracao-fase1.sql` e `sql/02-verificacao-estrutura.sql`.

### Fase 2 — Limpeza e tratamento (Python)

Tratar nulos, tipos e inconsistências. Agregar `leito` e `habilitacao` para uma linha por estabelecimento antes de qualquer junção.

**Entregável:** base tratada e log com cada decisão de limpeza.

### Fase 3 — Indicadores e regras de consistência

Duas partes.

**Indicadores gerais.** Completude por campo crítico, atualidade e distribuição regional.

**Três regras de consistência**, escolhidas para cobrir três níveis técnicos distintos:

| Regra | Tabelas | Nível técnico |
|---|---|---|
| Habilitação com competência final anterior a nov/2025 ainda registrada | `habilitacao` | sem JOIN — comparação de datas dentro da tabela |
| Divergência entre `leito.quantidade_total` e `habilitacao.quantidade_leitos` para o mesmo estabelecimento | `leito` + `habilitacao` | JOIN simples, com agregação prévia |
| Estabelecimento com leito de UTI cadastrado sem habilitação correspondente | `leito` + `habilitacao` | JOIN + conhecimento clínico para definir correspondência |

A terceira regra exige decidir quais habilitações são compatíveis com cada tipo de UTI. Essa decisão é clínica, não técnica, e precisa ser justificada no documento de achados.

**Entregável:** tabela de indicadores e relatório das três regras, com contagem de estabelecimentos em violação.

### Fase 4 — Dashboard (Power BI)

Painel respondendo às perguntas de gestão definidas na seção 2.

**Entregável:** dashboard publicado.

### Fase 5 — Framework de governança

Documento com regras mínimas de qualidade e responsabilidades: quem valida o quê, com que frequência. Inclui recomendações derivadas dos achados de metadados registrados na seção 8.

**Entregável:** documento de governança.

### Fase 6 — Mapeamento FHIR

Converter os estabelecimentos tratados para os recursos `Organization` e `Location`. Validar os recursos gerados. Documentar a tabela de-para, incluindo os campos que não foram mapeados e o motivo.

**Entregável:** script de conversão, amostra de recursos validados, tabela de-para.

### Fase 7 — Portfólio

Consolidar tudo em README e resumo executivo.

**Entregável:** README e material de divulgação.

---

## 7. Roadmap

| Marco | Descrição |
|---|---|
| 1 | Base extraída e estrutura verificada — **concluído** |
| 2 | Base tratada e validada |
| 3 | Indicadores e três regras de consistência calculados |
| 4 | Dashboard publicado |
| 5 | Framework de governança entregue |
| 6 | Estabelecimentos mapeados e validados em FHIR |
| Final | Documentação de portfólio consolidada |

---

## 8. Gestão de Riscos

### Riscos técnicos

**Multiplicação de linhas em JOIN.** Junção sem agregação prévia multiplica as linhas do cadastro. O erro é silencioso: a query roda e devolve número errado. *Mitigação:* agregar antes de juntar, e conferir a contagem de estabelecimentos antes e depois de cada junção.

**Custo de processamento.** O BigQuery cobra por coluna lida, não por linha devolvida. `SELECT *` em `estabelecimento` lê 204 colunas; em consulta com JOIN, o custo se multiplica pelas tabelas envolvidas. *Mitigação:* filtrar `ano`, `mes` e `sigla_uf` em todas as tabelas; nunca usar `SELECT *` em consulta com JOIN; conferir a estimativa de bytes antes de executar.

**Cobertura temporal desigual.** Nem toda tabela necessariamente tem novembro/2025. *Mitigação:* confirmar a cobertura de cada tabela antes de usá-la.

### Riscos de dados — achados registrados

Os quatro itens abaixo foram encontrados durante a verificação de estrutura, antes de a análise começar. Alimentam o framework de governança da Fase 5.

**Redundância de quantidade de leitos.** O mesmo fato é registrado em `leito.quantidade_total` e `habilitacao.quantidade_leitos`. Fontes internas divergentes não permitem saber qual está correta sem consultar a origem. Virou regra de consistência na Fase 3.

**Tipos inconsistentes em campos indicadores.** Em `servico_especializado`, os campos `indicador_*` são INT64; em `equipamento`, STRING. Mesma ideia semântica, tipos diferentes.

**Problemas no dicionário oficial.** Grafias inconsistentes (`nefrologiaurologia` no código 8, `nefrourologia` no 40) e códigos ambíguos: 88 e 90 significam "queimado adulto"; 89 e 91, "queimado pediátrico"; 73 e 87, "saúde mental" — sem critério visível para escolher entre eles. Diferente do caso da cardiologia, onde `tipo_leito` desfaz a ambiguidade, aqui não há campo que resolva. Fica como pergunta para a fonte oficial.

Esse último achado atinge a camada de metadados, o que compromete qualquer análise construída sobre ela.

### Risco regulatório

**Correção de premissa.** A versão 1 deste documento afirmava que o CNES é dado público agregado, sem dado pessoal, e propunha tratar LGPD como exercício hipotético. A verificação de estrutura mostrou que a premissa estava errada: a tabela `profissional` contém nome, cartão nacional de saúde e município de residência, junto com o estabelecimento de vínculo. Isso identifica indivíduos, em base pública acessível a qualquer pessoa com conta no BigQuery.

Não há dado de paciente. Há dado pessoal de profissional de saúde.

*Mitigação adotada:* a tabela `profissional` fica fora do escopo desta versão. Nenhum dado pessoal é extraído, tratado ou versionado.

### Risco de escopo

**Projeto grande demais para ser concluído.** Portfólio inacabado não demonstra competência. *Mitigação:* três regras de consistência em vez de cinco; `profissional` fora; modelo preditivo adiado. Cada item excluído fica registrado com o motivo.

---

## 9. Governança

Neste projeto solo, acumulo os papéis de dona do dado, analista e revisora. Em um cenário real, seriam pessoas diferentes, com separação de responsabilidades — o documento da Fase 5 detalha essa separação.

**Versionamento:** Git.
**Auditoria:** log de decisões de limpeza e transformação; queries validadas salvas em arquivo, já que o histórico do BigQuery não persiste entre sessões.
**Rastreabilidade:** toda definição de campo aponta para a tabela `dicionario` ou é marcada como interpretação própria.

---

## 10. Documentação

- README com contexto, perguntas de negócio, como reproduzir e principais achados
- Dicionário de dados derivado da tabela oficial
- Documento de achados da verificação de estrutura
- Tabela de-para CNES → FHIR, com os campos não mapeados justificados
- Diagrama da arquitetura
- Documento de governança, citável como peça própria

---

## 11. Qualidade

**Validação dos indicadores.** Conferir uma amostra manual de estabelecimentos para garantir que o indicador de completude corresponde ao dado real.

**Validação das regras.** Cada regra é conferida em uma amostra: os estabelecimentos apontados como violação são inspecionados individualmente antes de o número ir para o dashboard.

**Validação FHIR.** Nenhum recurso entra no repositório sem passar por validador. Recurso não validado não é entregável.

---

## 12. Escalabilidade

Próximos passos, fora do escopo atual:

**Comparação entre competências.** Rodar os mesmos indicadores em dois meses diferentes para observar evolução. Exige atenção ao campo `cobertura_temporal` do dicionário: códigos podem mudar de significado ao longo do tempo, e comparar competências sem checar isso produz análise errada.

**Tabela `profissional`.** Permitiria duas regras adicionais — registro de conselho incompleto, e serviço de alta complexidade sem profissional com CBO compatível vinculado. Exige tratamento de dado pessoal com anonimização antes de qualquer publicação.

Registro para essa fase: o CNES não tem campo de responsabilidade técnica. A regra de "alta complexidade sem responsável técnico habilitado", cogitada inicialmente, não é escrevível. A versão possível mede adequação da força de trabalho ao serviço declarado, que é coisa diferente e precisa ser nomeada como tal.

**Modelo preditivo de desatualização cadastral.** O obstáculo não é a técnica, é a variável-alvo. Definir "desatualizado" a partir de um campo de data de atualização torna o modelo quase tautológico — ele prevê o que já está escrito na coluna. Um alvo com sentido exige construção temporal a partir de múltiplas competências, o que muda o recorte e o volume processado. Modelo com alvo mal definido é pior que nenhum modelo.

**Cruzamento com outras bases.** Leitos de UTI e ocupação hospitalar, para análise de capacidade versus demanda.

**Ampliação do mapeamento FHIR.** `HealthcareService` para os serviços habilitados; `PractitionerRole` para profissionais, aproveitando que `cbo_2002` é vocabulário controlado de ocupações e o elemento `code` desse recurso recebe esse tipo de codificação.

---

## 13. Portfólio

**Título:** Diagnóstico de Qualidade e Governança de Dados em Estabelecimentos de Saúde no Brasil, com Mapeamento para FHIR

**Tecnologias:** SQL (BigQuery), Python, Power BI, Git, FHIR

**Resultados:** indicadores de qualidade do cadastro, três regras de consistência aplicadas, dashboard, framework de governança, mapeamento validado para recursos FHIR

**Aprendizados a documentar ao final:** a diferença entre ter dados e ter dados confiáveis; o que a verificação de estrutura revelou antes de a análise começar; e por que uma premissa escrita no próprio planejamento precisou ser corrigida depois de confrontada com os dados.

---

## Histórico de versões

**Versão 2 — 19/08/2026**

Alterações após a verificação da estrutura real do conjunto `br_ms_cnes`:

- Fase 3 reescrita com três regras de consistência ancoradas nas tabelas e códigos existentes, substituindo métricas genéricas
- Mapeamento FHIR promovido de escalabilidade a fase do projeto (Fase 6); portfólio passa a ser Fase 7
- Submissão à RNDS declarada explicitamente fora de escopo
- Tabela `profissional` retirada do escopo por conter dado pessoal
- Premissa de LGPD corrigida na seção 8: há dado pessoal de profissional de saúde na base
- Dicionário de dados passa a ser derivado da tabela oficial `dicionario`
- Chaves de junção, granularidade e regras de identificação de leitos incorporadas à seção 5
- Riscos de custo e de multiplicação de linhas em JOIN adicionados à seção 8
- Referência inexistente a uma "Fase 0" corrigida
- Título revisado para descrever o que o repositório entrega
- Documento convertido para voz de projeto

**Versão 1 — planejamento inicial**

Escopo original com seis fases, sem módulo de interoperabilidade e sem regras de consistência clínica.
