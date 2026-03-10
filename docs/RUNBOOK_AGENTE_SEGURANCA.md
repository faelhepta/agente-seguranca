# RUNBOOK — COMO RODAR O AGENTE DE SEGURANCA EM CADA PROJETO
## Guia Operacional para o Time de Seguranca

---

## PRE-REQUISITOS

Antes de iniciar qualquer analise, verifique:

1. **Node.js instalado** (versao 18+)
   ```
   node --version
   ```

2. **Claude Code CLI instalado**
   ```
   npm install -g @anthropic-ai/claude-code
   ```

3. **Autenticacao configurada** — sua chave de API da Anthropic deve estar ativa
   ```
   claude --version
   ```

4. **Artefatos do projeto recebidos e organizados** (ver estrutura abaixo)

---

## ESTRUTURA DE PASTAS PARA CADA PROJETO

Sempre organize os artefatos antes de iniciar a analise:

```
projetos/
  NOME_DO_PROJETO/
    codigo/           <- codigo fonte (clonar ou extrair aqui)
    documentacao/     <- PDFs, DOCs, diagramas de fluxo, especificacoes
    infraestrutura/   <- desenhos de rede, diagramas cloud, IaC (Terraform, etc.)
    relatorios/       <- relatorios internos gerados nas fases de analise
    apresentacoes/    <- HTMLs gerados para apresentar a fabrica de software
```

**Comando para criar a estrutura:**
```bash
mkdir -p projetos/NOME_DO_PROJETO/{codigo,documentacao,infraestrutura,relatorios,apresentacoes}
```

---

## PASSO A PASSO — EXECUTANDO A ANALISE

### PASSO 0 — Iniciar o Agente de Seguranca

Abra o terminal na pasta raiz do projeto e inicie o agente:

```bash
cd projetos/NOME_DO_PROJETO
npx claude-code-templates@latest --agent devops-infrastructure/security-engineer
```

O agente esta pronto quando exibir o menu de boas-vindas.

---

### PASSO 1 — ANALISE DE CODIGO FONTE

Navegue para a pasta de codigo e execute:

```bash
cd codigo/
```

#### 1A. Analise Geral de Seguranca do Codigo

Cole o prompt abaixo no agente:

```
Voce e um analista de segurança senior. Analise todo o codigo fonte nesta pasta.
Identifique vulnerabilidades seguindo o OWASP Top 10 e boas praticas de seguranca.
Para cada achado, informe:
- Arquivo e linha exata
- Tipo de vulnerabilidade (CWE se possivel)
- Severidade (Critico/Alto/Medio/Baixo)
- Descricao tecnica do problema
- Recomendacao de correcao com exemplo de codigo seguro

Foque em: injecao (SQL, Command, LDAP), autenticacao quebrada, exposicao de dados sensiveis,
controle de acesso, configuracoes inseguras, componentes vulneraveis, logging insuficiente.
```

#### 1B. Analise de Autenticacao e Autorizacao

```
Analise especificamente os mecanismos de autenticacao e autorizacao neste codigo.
Verifique:
- Implementacao de JWT/OAuth/sessoes
- Armazenamento de senhas (algoritmo de hash utilizado)
- Controle de acesso por role/perfil (RBAC)
- Presenca de credenciais hardcoded
- Protecao contra brute force
- Invalidacao de sessao no logout
Gere um relatorio detalhado com os achados.
```

#### 1C. Auditoria de Dependencias

```
Liste todas as dependencias do projeto (package.json, requirements.txt, pom.xml, etc.).
Para cada dependencia identifique:
- Versao utilizada
- Se existe CVE critico ou alto conhecido
- Se a biblioteca esta ativa e mantida
- Recomendacao de atualizacao se necessario
Use a base OWASP, NVD e dados conhecidos ate sua data de corte.
```

#### 1D. Busca por Secrets e Dados Sensiveis

```
Realize uma varredura completa no codigo buscando:
- Chaves de API, tokens, passwords hardcoded
- Conexoes de banco de dados com credenciais no codigo
- Arquivos .env commitados
- Chaves privadas ou certificados no repositorio
- Informacoes PII expostas nos logs ou respostas de API
Liste cada ocorrencia com arquivo e numero de linha.
```

#### 1E. Analise de Seguranca de API (se aplicavel)

```
Analise todos os endpoints de API presentes no codigo.
Para cada endpoint verifique:
- Autenticacao exigida
- Autorizacao por role/permissao
- Validacao dos parametros de entrada
- Risco de IDOR (objeto acessivel por ID sem verificar ownership)
- Headers de seguranca configurados (CORS, CSP, HSTS)
- Rate limiting implementado
Gere uma lista de endpoints com status de seguranca de cada um.
```

**Salvar resultado:**
```
Salve o relatorio completo da analise de codigo em: ../relatorios/01_analise_codigo.md
```

---

### PASSO 2 — ANALISE DE DOCUMENTACAO

Navegue para a pasta de documentacao:

```bash
cd ../documentacao/
```

#### 2A. Revisao de Arquitetura e Fluxo de Dados

```
Analise a documentacao tecnica deste projeto.
Com base nos documentos, identifique e avalie:
- Fronteiras de confianca e pontos de entrada de dados externos
- Dados sensiveis que trafegam pelo sistema (PII, financeiro, credenciais)
- Fluxos de autenticacao e autorizacao documentados
- Integracoes com sistemas terceiros e dados compartilhados
- Pontos de armazenamento de dados sensiveis

Verifique se a documentacao esta coerente com boas praticas de seguranca e
aponte lacunas ou riscos identificados nos fluxos descritos.
```

#### 2B. Revisao de Conformidade com LGPD

```
Com base na documentacao, avalie a conformidade com a LGPD:
- Quais dados pessoais sao coletados e processados?
- Ha base legal definida para cada tipo de dado?
- Existe politica de retencao e descarte de dados?
- Usuarios podem exercer seus direitos (acesso, exclusao, portabilidade)?
- Terceiros recebem dados pessoais? Ha DPA (Data Processing Agreement)?
- Incidentes de seguranca tem processo de notificacao definido?
Gere um relatorio de aderencia LGPD com gaps identificados.
```

#### 2C. Avaliacao de Requisitos de Seguranca

```
Analise os requisitos de seguranca documentados para este projeto.
Identifique:
- Requisitos de seguranca existentes e se estao sendo atendidos
- Requisitos de seguranca ausentes mas necessarios para o tipo de sistema
- Classificacao de dados realizada (publico/interno/confidencial/restrito)
- Procedimentos de resposta a incidentes documentados
Aponte os gaps criticos que precisam ser enderecos antes do go-live.
```

**Salvar resultado:**
```
Salve o relatorio completo da analise de documentacao em: ../relatorios/02_analise_documentacao.md
```

---

### PASSO 3 — ANALISE DE INFRAESTRUTURA

Navegue para a pasta de infraestrutura:

```bash
cd ../infraestrutura/
```

#### 3A. Revisao do Desenho de Rede e Arquitetura Cloud

```
Analise o desenho de infraestrutura deste projeto.
Avalie:
- Segmentacao de rede (DMZ, zona de dados, zona de aplicacao)
- Exposicao de servicos para a internet (o que esta publicamente acessivel)
- Banco de dados acessivel diretamente da internet?
- Presenca de WAF, balanceador de carga, CDN
- Comunicacao interna entre componentes esta criptografada?
- Monitoramento e logging de infraestrutura previsto

Gere um relatorio com riscos identificados e recomendacoes por componente.
```

#### 3B. Revisao de IAM e Controle de Acesso de Infraestrutura

```
Com base no desenho de infraestrutura, avalie o gerenciamento de identidade e acesso:
- Roles e permissoes de cloud seguem o principio do menor privilegio?
- Acesso administrativo (SSH, RDP, console cloud) esta restrito e monitorado?
- MFA exigido para acessos privilegiados?
- Service accounts com permissoes excessivas?
- Rotacao de chaves e credenciais esta prevista?
Identifique cada ponto de risco com recomendacao de correcao.
```

#### 3C. Revisao de IaC (Terraform, CloudFormation, etc.) — se aplicavel

```
Analise os arquivos de Infrastructure as Code presentes.
Verifique:
- Security groups / NSGs com regras abertas demais (0.0.0.0/0 em portas sensiveis)
- Buckets S3 ou blobs com acesso publico
- Bancos de dados sem criptografia em repouso
- Instancias sem monitoramento habilitado
- Secrets ou senhas nos arquivos de IaC
- Versoes desatualizadas de AMIs ou imagens base
Use as melhores praticas CIS Benchmark para a plataforma identificada.
```

#### 3D. Revisao de Containers e Kubernetes — se aplicavel

```
Analise os Dockerfiles e configuracoes de orquestracao de containers.
Verifique:
- Containers executando como root?
- Imagens base com vulnerabilidades conhecidas?
- Secrets embutidos nas imagens ou variaveis de ambiente em plaintext?
- Politicas de seguranca de pods configuradas (PodSecurity, NetworkPolicy)?
- Registry privado e com scan de vulnerabilidades habilitado?
- Privilegios excessivos (--privileged, capabilities desnecessarias)?
```

**Salvar resultado:**
```
Salve o relatorio completo da analise de infraestrutura em: ../relatorios/03_analise_infraestrutura.md
```

---

### PASSO 4 — MODELAGEM DE AMEACAS (THREAT MODELING)

Execute com o contexto completo dos tres artefatos:

```
Com base em tudo que foi analisado (codigo, documentacao e infraestrutura),
realize uma modelagem de ameacas completa usando o framework STRIDE.

Para cada componente critico do sistema, identifique:

STRIDE:
- Spoofing: Como um atacante pode se passar por outro usuario ou servico?
- Tampering: Como dados podem ser adulterados em transito ou em repouso?
- Repudiation: Existem acoes criticas sem rastro de auditoria?
- Information Disclosure: Onde dados sensiveis podem ser expostos indevidamente?
- Denial of Service: Quais componentes sao vulneraveis a indisponibilidade?
- Elevation of Privilege: Como um usuario pode obter mais permissoes do que deveria?

Para cada ameaca identificada, informe:
- Componente afetado
- Descricao do ataque
- Severidade (Critico/Alto/Medio/Baixo)
- Controle mitigador recomendado
- Status do controle (implementado / parcial / ausente)

Gere uma tabela resumo ao final com todas as ameacas priorizadas.
```

**Salvar resultado:**
```
Salve o relatorio de threat modeling em: ../relatorios/04_threat_modeling.md
```

---

### PASSO 5 — RELATORIO CONSOLIDADO E PARECER FINAL

```
Com base em todos os relatorios gerados (analise de codigo, documentacao,
infraestrutura e threat modeling), gere um RELATORIO EXECUTIVO CONSOLIDADO contendo:

1. SUMARIO EXECUTIVO
   - Nome do projeto e data da analise
   - Resumo em 5 linhas para gestao nao tecnica
   - Total de achados por severidade (tabela)

2. ACHADOS CRITICOS E ALTOS (listagem detalhada)
   - ID, descricao, componente afetado, recomendacao

3. ACHADOS MEDIOS E BAIXOS (listagem resumida)

4. MATRIZ DE RISCO (probabilidade x impacto)

5. PLANO DE CORRECAO RECOMENDADO
   - Prioridade 1 (antes do deploy): achados criticos e altos
   - Prioridade 2 (primeiros 30 dias): achados medios
   - Prioridade 3 (roadmap): achados baixos e melhorias

6. PARECER FINAL
   - APROVADO / APROVADO COM RESSALVAS / REPROVADO
   - Justificativa tecnica
   - Condicoes para aprovacao (se reprovado)

Formato: Markdown bem estruturado, adequado para apresentacao ao gestor.
```

**Salvar resultado:**
```
Salve o relatorio consolidado em: ../relatorios/00_RELATORIO_EXECUTIVO.md
```

---

### PASSO 6 — APRESENTACAO DE VULNERABILIDADES PARA A FABRICA

> Esta etapa usa o **skill `relatorio-fabrica`**. Certifique-se de que todos os
> relatorios das fases anteriores (01 a 04 + 00) estao salvos antes de prosseguir.

#### Como ativar o skill

No terminal, dentro da pasta do projeto:

```bash
cd projetos/NOME_DO_PROJETO
npx claude-code-templates@latest --agent devops-infrastructure/security-engineer
```

Quando o agente iniciar, execute o skill:

```
/relatorio-fabrica
```

O skill vai exibir dois prompts prontos. **Execute o Prompt 1** para gerar a apresentacao de vulnerabilidades.

#### O que o skill gera

O agente vai ler todos os relatorios e produzir automaticamente:

```
apresentacoes/apresentacao_vulnerabilidades.html
```

Com os seguintes slides baseados nos achados reais do projeto:

- Capa com parecer final colorido (verde / amarelo / vermelho)
- Sumario executivo com contadores reais de achados por severidade
- Grafico de distribuicao por categoria (codigo, infra, docs, threat model)
- Matriz de risco (probabilidade x impacto) com os achados posicionados
- Um slide individual por achado **critico e alto** (ID, componente, impacto, evidencia)
- Tabela resumida de achados **medios**
- Tabela compacta de achados **baixos e info**
- Slide de proximos passos com acoes imediatas

#### Como usar na reuniao com a fabrica

- **Participantes:** Time de seguranca + Tech Lead + Gerente de projeto da fabrica
- **Objetivo:** Apresentar os achados, explicar o impacto de cada um e obter ciencia formal
- **Ao final:** Fabrica assina o recebimento do relatorio e confirma entendimento

**Salvar resultado:**
```
apresentacoes/apresentacao_vulnerabilidades.html
```

---

### PASSO 7 — APRESENTACAO DE MELHORIAS E ROADMAP PARA A FABRICA

> Tambem usa o **skill `relatorio-fabrica`**. Execute apos o Passo 6.

#### Como ativar

Com o agente ainda aberto (ou reinicie com o mesmo comando), execute novamente:

```
/relatorio-fabrica
```

Desta vez, **execute o Prompt 2** para gerar a apresentacao de melhorias e roadmap.

#### O que o skill gera

O agente vai produzir:

```
apresentacoes/apresentacao_melhorias_roadmap.html
```

Com os seguintes slides orientados a solucoes:

- Capa com tag "Orientado a Solucoes"
- Visao geral do plano (3 pilares: codigo seguro / infraestrutura / processos)
- Como ler o plano: explicacao das 4 fases do roadmap
- Um slide de **solucao detalhada** por achado critico e alto:
  - Passo a passo de correcao
  - Exemplo de codigo ou configuracao segura
  - Esforco estimado (horas/dias)
  - Fase do roadmap + responsavel sugerido
- Tabela de melhorias de medio prazo
- Lista de evolucoes estrategicas de longo prazo
- **Roadmap visual** (slide principal) — timeline horizontal tipo Gantt com 4 fases:

| Fase   | Prazo         | Conteudo                              | Cor       |
|--------|---------------|---------------------------------------|-----------|
| Fase 1 | Antes deploy  | Correcoes criticas e altas            | Vermelho  |
| Fase 2 | Ate 30 dias   | Correcoes medias                      | Amarelo   |
| Fase 3 | Ate 90 dias   | Melhorias baixas + boas praticas      | Azul      |
| Fase 4 | Ate 6 meses   | Evolucao estrategica de maturidade    | Verde     |

- Metricas de sucesso (indicadores para a fabrica acompanhar)
- Boas praticas para os proximos projetos
- Slide de compromisso conjunto (responsabilidades fabrica x seguranca)

#### Como usar na reuniao com a fabrica

- **Participantes:** Time de seguranca + Desenvolvedores + DevOps + Gerente
- **Objetivo:** Alinhar as correcoes, definir responsaveis e aprovar o roadmap
- **Ao final:** Roadmap formalizado com datas e responsaveis assinados

**Salvar resultado:**
```
apresentacoes/apresentacao_melhorias_roadmap.html
```

---

## RESUMO DO FLUXO COMPLETO

```
PROJETO RECEBIDO
     |
     v
[PASSO 0] Iniciar Agente
     |
     v
[PASSO 1] Analise de Codigo          --> relatorios/01_analise_codigo.md
     |
     v
[PASSO 2] Analise de Documentacao    --> relatorios/02_analise_documentacao.md
     |
     v
[PASSO 3] Analise de Infraestrutura  --> relatorios/03_analise_infraestrutura.md
     |
     v
[PASSO 4] Threat Modeling            --> relatorios/04_threat_modeling.md
     |
     v
[PASSO 5] Relatorio Executivo        --> relatorios/00_RELATORIO_EXECUTIVO.md
     |
     v
PREENCHER CHECKLIST_SEGURANCA_PROJETOS.md
     |
     v
PARECER FINAL --> APROVAR / REPROVAR DEPLOY
     |
     v
[PASSO 6] /relatorio-fabrica (Prompt 1)
          --> apresentacoes/apresentacao_vulnerabilidades.html
     |
     v
REUNIAO 1 — Devolutiva de vulnerabilidades para a Fabrica
     |
     v
[PASSO 7] /relatorio-fabrica (Prompt 2)
          --> apresentacoes/apresentacao_melhorias_roadmap.html
     |
     v
REUNIAO 2 — Plano de acao e roadmap com a Fabrica
     |
     v
ROADMAP APROVADO E FORMALIZADO
     |
     v
(se REPROVADO ou APROVADO COM RESSALVAS apos 30 dias)
     |
     v
[REANALISE R0-R6] /reanalise-fabrica
     RA_01 + RA_02 + RA_03 + RA_00
     + CHECKLIST_REANALISE_PROJETOS.md
     |
     v
NOVO PARECER --> repetir ate APROVADO
```

---

## TEMPO ESTIMADO POR FASE

| Fase                                        | Estimativa       |
|---------------------------------------------|------------------|
| Setup e organizacao                         | 30 min           |
| Analise de codigo                           | 2 a 4 horas      |
| Analise de documentacao                     | 1 a 2 horas      |
| Analise de infraestrutura                   | 1 a 2 horas      |
| Threat modeling                             | 1 a 2 horas      |
| Relatorio executivo consolidado             | 1 hora           |
| Apresentacao de vulnerabilidades (skill)    | 30 min           |
| Apresentacao de melhorias + roadmap (skill) | 30 min           |
| **Total analise inicial**                   | **7 a 12 horas** |

> Projetos grandes ou criticos podem exigir analise mais aprofundada.
> As apresentacoes sao geradas automaticamente pelo skill — o tempo e de revisao e ajuste fino.

### Tempo estimado — Reanalise

| Fase da Reanalise                               | Estimativa    |
|-------------------------------------------------|---------------|
| Recebimento e verificacao de artefatos          | 15 min        |
| Criacao da estrutura de pastas reanalise/vN/    | 10 min        |
| R1 — Verificacao de criticos e altos            | 1 a 2 horas   |
| R2 — Verificacao de medios                      | 30 min        |
| R3 — Varredura de novos achados                 | 30 a 60 min   |
| R4 — Relatorio consolidado de reanalise         | 30 min        |
| R5 — Preenchimento do checklist                 | 30 min        |
| R6 — Apresentacao opcional                      | 20 min        |
| **Total por rodada de reanalise**               | **3 a 5 horas** |

> Reanalises subsequentes (v2, v3) tendem a ser mais rapidas se a fabrica
> corrigiu apenas os itens apontados sem introduzir novas mudancas estruturais.

---

## PROCESSO DE REANALISE

> Esta secao cobre o que acontece quando a fabrica entrega as correcoes e solicita
> nova avaliacao. Use sempre que o parecer original for REPROVADO ou APROVADO COM RESSALVAS
> e o prazo de correcao tiver vencido.

---

### QUANDO INICIAR UMA REANALISE

| Situacao                                           | Acao                                          |
|----------------------------------------------------|-----------------------------------------------|
| Parecer original: REPROVADO                        | Reanalise obrigatoria antes de qualquer deploy |
| Parecer original: APROVADO COM RESSALVAS + 30 dias | Reanalise dos achados medios pendentes        |
| Fabrica alega ter corrigido e pede nova avaliacao  | Reanalise apos receber evidencias completas   |
| Nova versao major do sistema                       | Nova analise completa (Passos 1 a 5)          |

---

### O QUE A FABRICA DEVE ENTREGAR PARA A REANALISE

Nao inicie a reanalise sem todos os itens abaixo:

- [ ] Codigo fonte atualizado (versao corrigida)
- [ ] Lista de commits ou Pull Requests das correcoes
- [ ] Documento de evidencias por achado (o que foi feito em cada um)
- [ ] Evidencias de testes realizados apos as correcoes
- [ ] Declaracao formal do responsavel tecnico confirmando os endereamentos

> Devolva para a fabrica se qualquer item estiver ausente.

---

### ESTRUTURA DE PASTAS DA REANALISE

Crie dentro da pasta do projeto:

```bash
mkdir -p projetos/NOME_DO_PROJETO/reanalise/v1/{evidencias,relatorios,apresentacoes}
```

```
projetos/NOME_DO_PROJETO/
  reanalise/
    v1/                        <- versionar cada rodada (v1, v2, v3...)
      evidencias/              <- diffs, commits, docs enviados pela fabrica
      relatorios/
        RA_01_achados_criticos_altos.md
        RA_02_achados_medios.md
        RA_03_novos_achados.md
        RA_00_relatorio_reanalise.md
      apresentacoes/           <- opcional
        apresentacao_resultado_reanalise.html
```

---

### PASSO R0 — INICIAR O AGENTE PARA REANALISE

```bash
cd projetos/NOME_DO_PROJETO
npx claude-code-templates@latest --agent devops-infrastructure/security-engineer
```

Quando o agente iniciar, ative o skill de reanalise:

```
/reanalise-fabrica
```

O skill exibira 5 prompts numerados. Execute na ordem indicada.

---

### PASSO R1 — VERIFICAR ACHADOS CRITICOS E ALTOS

Execute o **Prompt 1** do skill `/reanalise-fabrica`.

O agente vai:
- Ler o relatorio executivo original
- Localizar cada achado critico e alto no codigo/infra atual
- Avaliar se a correcao foi feita corretamente
- Classificar com status: CORRIGIDO / PARCIALMENTE CORRIGIDO / NAO CORRIGIDO / CORRECAO INADEQUADA / NAO VERIFICAVEL

**Resultado:** `reanalise/v[N]/relatorios/RA_01_achados_criticos_altos.md`

---

### PASSO R2 — VERIFICAR ACHADOS MEDIOS

Execute o **Prompt 2** do skill `/reanalise-fabrica`.

O agente vai verificar se os achados medios foram corrigidos dentro do prazo
de 30 dias acordado no roadmap. Achados vencidos e nao corrigidos recebem
status especial **VENCIDO NAO CORRIGIDO**.

**Resultado:** `reanalise/v[N]/relatorios/RA_02_achados_medios.md`

---

### PASSO R3 — VARRER NOVOS ACHADOS NAS AREAS MODIFICADAS

Execute o **Prompt 3** do skill `/reanalise-fabrica`.

> Esta etapa e obrigatoria. Correcoes mal feitas frequentemente introduzem
> novos problemas. O agente foca exclusivamente nas areas que foram alteradas.

O agente vai:
- Identificar todos os arquivos e componentes modificados nas correcoes
- Fazer analise de seguranca focada nessas areas
- Reportar qualquer novo achado introduzido pelas mudancas

**Resultado:** `reanalise/v[N]/relatorios/RA_03_novos_achados.md`

---

### PASSO R4 — RELATORIO CONSOLIDADO DE REANALISE

Execute o **Prompt 4** do skill `/reanalise-fabrica`.

O agente consolida os tres relatorios anteriores e aplica automaticamente
os criterios de parecer:

| Criterio                                                   | Parecer                    |
|------------------------------------------------------------|----------------------------|
| Todos criticos e altos = CORRIGIDO, sem novos criticos/altos | APROVADO                 |
| Todos criticos = CORRIGIDO, algum alto parcial, novos <= medio | APROVADO COM RESSALVAS |
| Qualquer critico != CORRIGIDO                              | REPROVADO                  |
| Qualquer alto = NAO CORRIGIDO ou CORRECAO INADEQUADA       | REPROVADO                  |
| Novo achado critico ou alto introduzido                    | REPROVADO                  |
| Evidencias insuficientes para verificacao                  | REPROVADO                  |

**Resultado:** `reanalise/v[N]/relatorios/RA_00_relatorio_reanalise.md`

---

### PASSO R5 — PREENCHER CHECKLIST DE REANALISE

Preencha o arquivo `CHECKLIST_REANALISE_PROJETOS.md` com base nos relatorios gerados.

- Transcreva os status de cada achado para as tabelas do checklist
- Preencha o detalhamento de cada achado critico (Parte 1)
- Preencha a contagem resumo (Parte 7)
- Marque os criterios de parecer (Parte 8)
- Assine o parecer final

---

### PASSO R6 (OPCIONAL) — APRESENTACAO DO RESULTADO PARA A FABRICA

Execute o **Prompt 5** do skill `/reanalise-fabrica`.

Gera uma apresentacao HTML com o resultado da reanalise para reuniao com a fabrica,
mostrando o comparativo entre a analise original e o estado atual.

**Resultado:** `reanalise/v[N]/apresentacoes/apresentacao_resultado_reanalise.html`

---

### PROTOCOLO DE MULTIPLAS RODADAS

| Rodada | Acao adicional                                                             |
|--------|----------------------------------------------------------------------------|
| v1     | Processo normal conforme descrito acima                                    |
| v2     | Notificar formalmente o gestor da fabrica com relatorio de reincidencia    |
| v3+    | Escalar para coordenador de seguranca + gestor da fabrica + gestor de TI  |
|        | Avaliar suspensao do projeto ate resolucao definitiva                      |

---

### FLUXO DA REANALISE

```
FABRICA ENTREGA CORRECOES + EVIDENCIAS
     |
     v
VERIFICAR ARTEFATOS OBRIGATORIOS
  Incompleto? --> Devolver para a fabrica
     |
     v
[PASSO R0] Iniciar agente → /reanalise-fabrica
     |
     v
[PASSO R1] Verificar criticos e altos   --> RA_01_achados_criticos_altos.md
     |
     v
[PASSO R2] Verificar medios             --> RA_02_achados_medios.md
     |
     v
[PASSO R3] Varrer novos achados         --> RA_03_novos_achados.md
     |
     v
[PASSO R4] Relatorio consolidado        --> RA_00_relatorio_reanalise.md
     |
     v
[PASSO R5] Preencher checklist de reanalise
     |
     v
PARECER DA REANALISE
  |                    |                     |
APROVADO         APROVADO C/ RESSALVAS    REPROVADO
  |                    |                     |
Liberar           Acompanhar           Reanalise v[N+1]
deploy            pendencias           (ver protocolo)
```

---

## CRITERIOS DE BLOQUEIO DE DEPLOY

O deploy deve ser **BLOQUEADO** se qualquer um dos itens abaixo for identificado:

- Credenciais hardcoded no codigo ou repositorio
- SQL Injection ou Command Injection exploravel
- Autenticacao bypassavel
- Dados sensiveis expostos sem criptografia
- Banco de dados exposto diretamente para internet
- CVE critico em dependencia core da aplicacao
- Ausencia total de controle de acesso em endpoints sensiveis

---

## CONTATO E ESCALADA

| Situacao                              | Acao                                      |
|---------------------------------------|-------------------------------------------|
| Achado critico identificado           | Notificar coordenador imediatamente       |
| Duvida sobre severidade de um achado  | Consultar coordenador antes de fechar     |
| Fabrica questiona um achado           | Documentar e escalar para coordenador     |
| Necessidade de teste dinamico (DAST)  | Solicitar ambiente de homologacao         |
