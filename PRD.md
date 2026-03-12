# Product Requirements Document — Agente de Seguranca

**Versao:** 1.0
**Data:** Março 2026
**Repositorio:** https://github.com/faelhepta/agente-seguranca
**Status:** Ativo

---

## 1. Visao Geral

O **Agente de Seguranca** e um toolkit de automacao de revisao de seguranca para times de seguranca que avaliam projetos de software entregues por fabricas de software (terceiros). O produto automatiza o ciclo completo de analise — do codigo-fonte ao relatorio executivo com parecer final — usando o **Claude Code CLI** como motor de analise, e gera apresentacoes HTML prontas para reunioes com as equipes de desenvolvimento.

---

## 2. Problema

Times de seguranca que fazem revisao de projetos de terceiros enfrentam um processo intensamente manual:

| Problema | Impacto |
|----------|---------|
| Analise de codigo, documentacao e infraestrutura e feita prompto a prompto no agente interativo | 7 a 12 horas por projeto, processo fragmentado |
| Nao ha padrao de saida entre analistas | Relatorios inconsistentes, dificuldade de governanca |
| Apresentacoes para a fabrica sao criadas manualmente | Retrabalho, apresentacoes de qualidade variavel |
| Ciclo de reanalise (verificar correcoes) nao tem fluxo estruturado | Risco de aprovar projetos com correcoes superficiais ou incompletas |
| Onboarding de novo analista depende de conhecimento tacito | Alta curva de aprendizado, inconsistencia na equipe |

---

## 3. Objetivo do Produto

Reduzir o tempo de analise de seguranca de projetos de software, padronizar os entregaveis e estruturar o ciclo de revisao e reanalise, mantendo o analista humano como responsavel pela revisao final e pelo parecer.

### O que o produto NAO faz

- Nao substitui a revisao humana — o analista valida, ajusta e assina todos os entregaveis
- Nao executa testes dinamicos (DAST) — e analise estatica e documental
- Nao tem interface grafica propria — opera via terminal e navegador (para as apresentacoes)
- Nao se conecta a repositorios remotos automaticamente — os artefatos sao copiados manualmente pelo analista

---

## 4. Usuarios

### 4.1 Analista de Seguranca (usuario primario)

Profissional responsavel por executar a analise de cada projeto recebido. Usa os scripts de automacao diariamente. Familiaridade com terminal, seguranca de aplicacoes e infraestrutura.

**Necessidades:**
- Executar uma analise completa com o minimo de passos manuais
- Ter saida padronizada e confiavel para revisar
- Apresentar os resultados para a fabrica sem precisar criar slides do zero

### 4.2 Coordenador de Seguranca

Responsavel por revisar pareceres, escalar situacoes criticas e assinar formalmente os relatorios. Usa os entregaveis gerados pelo analista, nao o terminal.

**Necessidades:**
- Relatorio executivo claro e com parecer justificado
- Visibilidade do ciclo de cada projeto (analise → reanalise → aprovacao)

### 4.3 Fabrica de Software (receptor dos entregaveis)

Time de desenvolvimento que recebeu o projeto avaliado. Participa das reunioes de devolutiva e e responsavel por corrigir os achados.

**Necessidades:**
- Entender o que foi encontrado sem precisar de conhecimento em seguranca
- Ter um roadmap claro e priorizavel de correcoes
- Saber exatamente o que precisa ser corrigido para obter aprovacao de deploy

### 4.4 Novo Analista (instalacao)

Profissional que acabou de entrar no time. Precisa instalar o ambiente na maquina e entender o fluxo de trabalho.

**Necessidades:**
- Processo de instalacao simples e documentado
- Material de referencia rapida (runbook, checklists)

---

## 5. Arquitetura do Produto

```
DISTRIBUICAO (repositorio git)
  instalar.ps1 / instalar.sh
  skills/
    relatorio-fabrica.md
    reanalise-fabrica.md
  docs/
    analisar.ps1 / analisar.sh          <- copiados para ~/Documents/Seguranca-TI/
    rodar_analise.ps1 / rodar_analise.sh
    RUNBOOK_AGENTE_SEGURANCA.md
    CHECKLIST_SEGURANCA_PROJETOS.md
    CHECKLIST_REANALISE_PROJETOS.md
    TUTORIAL_RODAR_ANALISE.md
    onboarding_equipe.html
  extras/
    gerar_apresentacoes.ps1
    analisar_api.ps1

MAQUINA DO ANALISTA (apos instalacao)
  ~/.claude/skills/                      <- skills do Claude Code
  ~/Documents/Seguranca-TI/             <- scripts e documentos de referencia
  ~/Documents/projetos/                 <- workspace de projetos analisados
    _TEMPLATE/                          <- estrutura padrao de pastas
    NOME_DO_PROJETO/
      codigo/
      documentacao/
      infraestrutura/
      relatorios/                       <- saidas das fases 1-5
      apresentacoes/                    <- HTMLs para as reunioes
      reanalise/
        v1/ v2/ ...
          evidencias/
          relatorios/
          apresentacoes/

MOTOR DE ANALISE
  Claude Code CLI (claude -p)           <- analisa o conteudo das pastas
  Anthropic API                         <- consumida pelo Claude Code
```

---

## 6. Funcionalidades

### 6.1 Instalacao e Setup

**F-01 — Instalador Windows**
Script `instalar.ps1` que verifica pre-requisitos (Node.js 18+, Claude Code CLI), copia skills para `~/.claude/skills/`, copia documentos para `~/Documents/Seguranca-TI/` e cria a estrutura de pastas de projetos. Suporta modo `install` (completo) e `update` (atualiza apenas skills e docs).

**F-02 — Instalador Linux/WSL**
Script `instalar.sh` equivalente para ambientes bash.

**F-03 — Template de Projeto**
Pasta `_TEMPLATE` criada automaticamente com a estrutura correta de subpastas para cada novo projeto.

---

### 6.2 Execucao da Analise

**F-04 — Modo Simples (analisar.ps1 / analisar.sh)**
Script interativo: solicita apenas o caminho completo da pasta do projeto, detecta automaticamente quais subpastas existem (codigo, documentacao, infraestrutura) e executa todas as fases disponiveis. Fases com pasta vazia sao puladas com aviso. Ideal para uso diario.

```
cd ~/Documents/Seguranca-TI
.\analisar.ps1
```

**F-05 — Modo Avancado (rodar_analise.ps1 / rodar_analise.sh)**
Script parametrico com controle fino de execucao:

| Parametro | Descricao |
|-----------|-----------|
| `-Projeto` | Nome da pasta em `~/Documents/projetos/` (obrigatorio) |
| `-Fase` | `todas` \| `codigo` \| `docs` \| `infra` \| `threat` \| `relatorio` \| `apresentacoes` \| `reanalise` |
| `-Versao` | Versao da reanalise (ex: `v1`, `v2`) — usado com `-Fase reanalise` |
| `-DryRun` | Exibe o que seria executado sem chamar o Claude Code |

**F-06 — Execucao Isolada de Apresentacoes (gerar_apresentacoes.ps1)**
Script auxiliar que regenera apenas os dois HTMLs de apresentacao a partir de relatorios ja existentes. Util quando o analista quer refinar a apresentacao sem reexecutar toda a analise.

---

### 6.3 Fases de Analise

Cada fase chama o Claude Code em modo nao-interativo (`claude -p`) com um prompt especializado e salva a saida como arquivo Markdown.

**F-07 — Fase 1: Analise de Codigo**
- OWASP Top 10 com arquivo, linha, CWE, severidade e recomendacao com exemplo de codigo seguro
- Autenticacao e autorizacao (JWT/OAuth, RBAC, hash de senhas, brute force, invalidacao de sessao)
- Dependencias com CVEs criticos/altos (package.json, requirements.txt, pom.xml, go.mod, etc.)
- Secrets e dados sensiveis hardcoded (chaves de API, .env commitados, PII em logs)
- Seguranca de API (por endpoint: autenticacao, autorizacao, IDOR, headers, rate limiting)

Saida: `relatorios/01_analise_codigo.md`

**F-08 — Fase 2: Analise de Documentacao**
- Arquitetura e fluxo de dados (fronteiras de confianca, dados sensiveis, integracoes)
- Conformidade LGPD (base legal, retencao, direitos dos titulares, DPA, notificacao de incidentes)
- Requisitos de seguranca (existentes vs necessarios, classificacao de dados, resposta a incidentes)

Saida: `relatorios/02_analise_documentacao.md`

**F-09 — Fase 3: Analise de Infraestrutura**
- Rede e exposicao (segmentacao, WAF, criptografia em transito)
- IAM (menor privilegio, MFA, service accounts, rotacao de chaves)
- IaC — Terraform/CloudFormation/Pulumi (security groups abertos, buckets publicos, secrets em IaC)
- Containers e Kubernetes (root containers, imagens vulneraveis, secrets em plaintext)
- Monitoramento e continuidade (logs, SIEM, backup, RTO/RPO)

Saida: `relatorios/03_analise_infraestrutura.md`

**F-10 — Fase 4: Threat Modeling STRIDE**
Modelagem de ameacas por componente critico com ID (STR-001...), cenario de ataque, severidade, controle mitigador e status (implementado/parcial/ausente).

Saida: `relatorios/04_threat_modeling.md`

**F-11 — Fase 5: Relatorio Executivo**
Consolidacao de todos os achados em documento executivo com: sumario nao-tecnico, tabela de achados por severidade, matriz de risco probabilidade x impacto, plano de correcao em 3 prioridades e parecer final (APROVADO / APROVADO COM RESSALVAS / REPROVADO).

Saida: `relatorios/00_RELATORIO_EXECUTIVO.md`

---

### 6.4 Apresentacoes HTML

**F-12 — Apresentacao de Vulnerabilidades**
Slides profissionais gerados automaticamente com: capa + badge de parecer colorido, sumario executivo com contadores reais, grafico de barras CSS por severidade, matriz de risco CSS, um slide por achado critico/alto, tabelas de medios e baixos, proximos passos. CSS inline, sem dependencias externas, navegacao por teclado.

Saida: `apresentacoes/apresentacao_vulnerabilidades.html`

**F-13 — Apresentacao de Melhorias e Roadmap**
Slides orientados a solucoes com: passo a passo de correcao por achado critico/alto (com exemplo de codigo seguro), Gantt CSS com 4 fases de roadmap (antes deploy / 30 dias / 90 dias / 6 meses), metricas de sucesso, boas praticas para novos projetos. Tom construtivo, paleta verde/azul.

Saida: `apresentacoes/apresentacao_melhorias_roadmap.html`

**Requisitos tecnicos comuns dos HTMLs:**
- CSS completamente inline, zero dependencias externas
- Navegacao por setas do teclado, contador de slides, barra de progresso
- Renderizacao direta no navegador sem servidor web
- Paleta: `#0a0e1a` fundo, `#ef4444` critico, `#f97316` alto, `#f59e0b` medio, `#3b82f6` baixo, `#00d4a1` info

---

### 6.5 Skills do Claude Code

**F-14 — Skill /relatorio-fabrica**
Ativado dentro do agente interativo do Claude Code. Exibe dois prompts completos prontos para copiar e colar. Prompt 1 gera a apresentacao de vulnerabilidades; Prompt 2 gera a de melhorias. Alternativa ao modo automatizado para analistas que preferem supervisionar cada etapa.

**F-15 — Skill /reanalise-fabrica**
Ativado dentro do agente interativo. Exibe 5 prompts para executar o ciclo de reanalise em sequencia: verificar criticos/altos, verificar medios, varrer novos achados, relatorio consolidado e (opcional) apresentacao do resultado.

---

### 6.6 Ciclo de Reanalise

**F-16 — Workflow de Reanalise**
Quando a fabrica entrega correcoes, o analista cria a estrutura `reanalise/vN/` e executa 4 fases:

| Fase | Verificacao | Saida |
|------|-------------|-------|
| RA-01 | Achados criticos e altos: CORRIGIDO / PARC. CORRIGIDO / NAO CORRIGIDO / CORRECAO INADEQUADA / NAO VERIFICAVEL | `RA_01_achados_criticos_altos.md` |
| RA-02 | Achados medios com controle de prazo de 30 dias | `RA_02_achados_medios.md` |
| RA-03 | Novos achados introduzidos pelas alteracoes | `RA_03_novos_achados.md` |
| RA-00 | Relatorio consolidado com aplicacao automatica dos criterios de parecer | `RA_00_relatorio_reanalise.md` |

**Criterios de parecer da reanalise:**

| Condicao | Parecer |
|----------|---------|
| Todos criticos e altos = CORRIGIDO, sem novos criticos/altos | APROVADO |
| Todos criticos = CORRIGIDO, algum alto parcial aceito, novos achados <= medio | APROVADO COM RESSALVAS |
| Qualquer critico != CORRIGIDO | REPROVADO |
| Qualquer alto = NAO CORRIGIDO ou CORRECAO INADEQUADA | REPROVADO |
| Novo achado critico ou alto introduzido pelas correcoes | REPROVADO |
| Evidencias insuficientes para verificacao | REPROVADO |

**Protocolo de multiplas rodadas:**
- v1: normal
- v2: notificar gestor da fabrica formalmente
- v3+: escalar para coordenador + gestor de TI; avaliar suspensao do projeto

---

### 6.7 Documentos de Governanca

**F-17 — CHECKLIST_SEGURANCA_PROJETOS.md**
Checklist manual preenchido pelo analista apos a analise automatizada. Cobre as fases 1 a 5 com itens booleans por categoria. Inclui tabela de achados com ID/severidade/status e campo para parecer final com assinatura do analista e aprovacao do coordenador.

**F-18 — CHECKLIST_REANALISE_PROJETOS.md**
Checklist equivalente para o ciclo de reanalise. Registra o status de cada achado original apos a verificacao das correcoes.

**F-19 — RUNBOOK_AGENTE_SEGURANCA.md**
Guia operacional completo com cada passo da analise e da reanalise, prompts de fallback para uso manual no agente interativo, fluxogramas, estimativas de tempo e criterios de bloqueio de deploy.

**F-20 — Criterios de Bloqueio de Deploy**
O deploy e **bloqueado automaticamente** quando qualquer um dos seguintes achados for identificado: credenciais hardcoded, SQL/Command Injection exploravel, autenticacao bypassavel, dados sensiveis sem criptografia, banco de dados exposto para internet, CVE critico em dependencia core, ausencia total de controle de acesso em endpoints sensiveis.

---

### 6.8 Onboarding

**F-21 — Apresentacao de Onboarding da Equipe**
Arquivo HTML `onboarding_equipe.html` com slides de apresentacao para replicar o ambiente em novos computadores do time. Inclui: pre-requisitos, passo a passo de instalacao, o que o instalador faz, como executar a analise, estrutura de pastas e como atualizar.

---

## 7. Requisitos Nao Funcionais

### 7.1 Compatibilidade

| Item | Requisito |
|------|-----------|
| Windows | PowerShell 5.1+, Node.js 18+, Claude Code CLI |
| Linux/WSL | bash, Node.js 18+, Claude Code CLI |
| Navegador (HTMLs) | Qualquer navegador moderno sem servidor web |
| Encoding | UTF-8 em todos os arquivos de saida; `.ps1` com CRLF, `.sh/.md/.html` com LF |

### 7.2 Autonomia e Dependencias

- Nenhum servidor proprio — totalmente local na maquina do analista
- Unica dependencia externa de runtime: Anthropic API (via Claude Code CLI)
- Apresentacoes HTML sem dependencias externas (CSS inline, sem CDN, sem fontes web)

### 7.3 Determinismo da Saida

- O conteudo dos relatorios depende do modelo Claude — variacao entre execucoes e esperada
- O formato de saida (Markdown para relatorios, HTML para apresentacoes) e determinado pelos prompts
- A saida do `claude -p` e processada para remover blocos de codigo markdown (` ```html ``` `) antes de salvar, garantindo que HTMLs sejam validos

### 7.4 Seguranca do Proprio Produto

- Nenhum artefato analisado e enviado para fora da maquina diretamente pelo produto
- O Claude Code CLI gerencia a comunicacao com a API Anthropic
- Scripts nao executam comandos privilegiados; nao modificam o sistema alem das pastas do usuario

### 7.5 Tratamento de Falhas

- Fases com pasta vazia sao puladas com aviso, sem abortar o fluxo completo
- Erros de chamada ao Claude Code sao capturados, exibidos e registrados; o script continua as fases seguintes
- Resumo final exibe tempo por fase, fases com erro e fases puladas

---

## 8. Fluxo Completo

```
PROJETO RECEBIDO DA FABRICA
         |
         v
  Organizar artefatos nas pastas
  codigo/ documentacao/ infraestrutura/
         |
         v
  .\analisar.ps1   (modo simples)
  ou
  .\rodar_analise.ps1 -Projeto "Nome"   (modo avancado)
         |
         v
  [FASE 1] Analise de Codigo         --> relatorios/01_analise_codigo.md
  [FASE 2] Analise de Documentacao   --> relatorios/02_analise_documentacao.md
  [FASE 3] Analise de Infraestrutura --> relatorios/03_analise_infraestrutura.md
  [FASE 4] Threat Modeling STRIDE    --> relatorios/04_threat_modeling.md
  [FASE 5] Relatorio Executivo       --> relatorios/00_RELATORIO_EXECUTIVO.md
         |
         v
  Analista revisa e preenche CHECKLIST_SEGURANCA_PROJETOS.md
  Coordenador assina o parecer
         |
         v
  [FASE 6] apresentacao_vulnerabilidades.html
  [FASE 7] apresentacao_melhorias_roadmap.html
         |
         v
  REUNIAO 1 — Devolutiva de achados para a fabrica
  REUNIAO 2 — Alinhamento do roadmap de correcoes
         |
         v
  Fabrica entrega correcoes + evidencias
         |
         v
  .\rodar_analise.ps1 -Projeto "Nome" -Fase reanalise -Versao v1
         |
         v
  [RA-01] Verificar criticos e altos
  [RA-02] Verificar medios
  [RA-03] Varrer novos achados
  [RA-00] Relatorio consolidado de reanalise
         |
         v
  PARECER DA REANALISE
       /        |        \
  APROVADO  RESSALVAS  REPROVADO
       |        |        |
   Deploy    Monit.   Reanalise vN+1
```

---

## 9. Metricas de Sucesso

| Metrica | Baseline (manual) | Meta |
|---------|-------------------|------|
| Tempo de analise inicial | 7 a 12h | < 2h de trabalho ativo do analista |
| Tempo de reanalise | 3 a 5h | < 1h de trabalho ativo |
| Consistencia de formato | Variavel por analista | 100% dos relatorios no padrao definido |
| Tempo para gerar apresentacoes | 1 a 2h por apresentacao | < 30 min (revisao incluida) |
| Onboarding de novo analista | Sem prazo definido | Ambiente funcional no mesmo dia |

---

## 10. Restricoes e Limitacoes Conhecidas

| Restricao | Descricao |
|-----------|-----------|
| Analise estatica apenas | Nao detecta vulnerabilidades que exigem execucao (DAST). Recomenda-se pen test complementar para sistemas criticos. |
| Falsos positivos | O modelo pode reportar achados incorretos ou perder achados reais. Revisao humana e obrigatoria. |
| Knowledge cutoff do modelo | CVEs e vulnerabilidades publicadas apos a data de corte do Claude podem nao ser identificados. |
| Tamanho do codebase | Projetos muito grandes podem exceder a janela de contexto do modelo em uma unica chamada. O analista deve segmentar a analise por modulo. |
| Sem persistencia de estado | Cada chamada `claude -p` e independente. O modelo nao "lembra" fases anteriores a nao ser pelos relatorios em disco. |
| API Anthropic obrigatoria | Sem conexao com a API, nenhuma fase de analise pode ser executada. |

---

## 11. Estrutura do Repositorio

```
agente-seguranca/
  instalar.ps1              <- instalador Windows
  instalar.sh               <- instalador Linux/WSL/Git Bash
  GUIA_INSTALACAO.md        <- instrucoes detalhadas de instalacao
  README.md                 <- visao geral e guia de uso rapido
  PRD.md                    <- este documento
  .gitignore
  .gitattributes
  skills/
    relatorio-fabrica.md    <- skill /relatorio-fabrica
    reanalise-fabrica.md    <- skill /reanalise-fabrica
  docs/                     <- instalados em ~/Documents/Seguranca-TI/
    analisar.ps1            <- script principal (modo simples, Windows)
    analisar.sh             <- script principal (modo simples, Linux)
    rodar_analise.ps1       <- script avancado (modo parametrico, Windows)
    rodar_analise.sh        <- script avancado (Linux)
    RUNBOOK_AGENTE_SEGURANCA.md
    CHECKLIST_SEGURANCA_PROJETOS.md
    CHECKLIST_REANALISE_PROJETOS.md
    TUTORIAL_RODAR_ANALISE.md
    onboarding_equipe.html
    apresentacao_time_seguranca.html
  extras/
    gerar_apresentacoes.ps1 <- regenera HTMLs de projeto ja analisado
    analisar_api.ps1        <- analise focada em APIs REST
```

---

## 12. Decisoes de Design

**Por que `claude -p` (nao-interativo) em vez do agente interativo?**
O modo `claude -p` permite automacao total via script. O analista nao precisa estar presente durante a execucao das fases. O agente interativo e mantido como alternativa para analistas que preferem supervisao passo a passo (via skills).

**Por que HTML gerado (sem framework de apresentacao)?**
Apresentacoes HTML com CSS inline nao dependem de internet, servidor, ou instalacao de software extra. O analista abre o arquivo diretamente no navegador. A fabrica recebe um unico arquivo que funciona em qualquer maquina.

**Por que prompts embutidos nos scripts (nao em arquivos externos)?**
Manter os prompts dentro dos scripts simplifica a distribuicao (um arquivo por script) e evita que prompts desincronizem da logica de execucao. O custo e que alterar prompts requer editar o script — aceitavel dado o ritmo de evolucao do produto.

**Por que PowerShell como plataforma primaria?**
O ambiente operacional do time de seguranca e Windows. PowerShell 5.1 esta disponivel em todas as versoes do Windows sem instalacao adicional. Scripts bash equivalentes sao mantidos para suporte a WSL e Linux.

---

## 13. Roadmap

### v1.1 — Proximas melhorias priorizadas

- [ ] Adicionar suporte a analise de APIs REST a partir de colecoes Postman/OpenAPI (extras/analisar_api.ps1 atual e ponto de partida)
- [ ] Refatorar `gerar_apresentacoes.ps1` para aplicar o mesmo fix de strip de markdown code fences
- [ ] Adicionar parametro `-Modelo` para selecionar qual modelo Claude usar por fase

### v1.2 — Melhorias de processo

- [ ] Script de validacao pre-analise: verificar se o projeto tem `.env` commitado, `node_modules/` na pasta, arquivos binarios que devem ser excluidos
- [ ] Relatorio de comparativo automatico entre versoes (analise original vs reanalise) em formato tabular
- [ ] Suporte a analise parcial de codebase grande por subdiretorios

### Futuro (v2.x)

- [ ] Integracao com JIRA/GitHub Issues para criacao automatica de tasks a partir dos achados
- [ ] Dashboard de acompanhamento de projetos (status de cada projeto, historico de reanalises)
- [ ] Modulo DAST leve integrado (nuclei/zap headless) para complementar a analise estatica
