# TUTORIAL — COMO RODAR A ANALISE DE SEGURANCA
## Script de Automacao `rodar_analise.ps1`

---

## VISAO GERAL

O script `rodar_analise.ps1` executa automaticamente todas as fases de analise do Runbook. Voce aponta o projeto, ele roda os prompts no Claude Code, salva os relatorios e gera as apresentacoes. Ao final, voce revisa, preenche o checklist e assina o parecer.

```
Voce faz                          O script faz
─────────────────────             ──────────────────────────────────────
Organizar os arquivos       -->   Fase 1: Analise de codigo
Rodar o script              -->   Fase 2: Analise de documentacao
Tomar um cafe               -->   Fase 3: Analise de infraestrutura
                                  Fase 4: Threat modeling
Voce volta e revisa         -->   Fase 5: Relatorio executivo
Preencher o checklist       -->   Fase 6: Apresentacao de vulnerabilidades
Assinar o parecer           -->   Fase 7: Apresentacao de melhorias + roadmap
```

**Tempo estimado:** 7 a 12 horas de processamento (o script roda sem voce precisar ficar na frente do computador).

---

## PRE-REQUISITOS

Confirme que o instalador ja foi executado na sua maquina:

```powershell
# Deve retornar v18 ou maior
node --version

# Deve retornar a versao do Claude Code
claude --version

# Deve existir a pasta de projetos
ls "$env:USERPROFILE\Documents\projetos"
```

Se qualquer um falhar, rode o `instalar.ps1` primeiro.

---

## PASSO 1 — RECEBER OS ARQUIVOS DA FABRICA

A fabrica precisa entregar exatamente 3 itens:

| Item | O que e | Para onde vai |
|------|---------|---------------|
| Codigo fonte | Repositorio ou pacote zip | Pasta `codigo/` |
| Documentacao | PDFs, DOCs, diagramas | Pasta `documentacao/` |
| Infraestrutura | Diagramas de rede, Terraform, etc. | Pasta `infraestrutura/` |

> Se qualquer um dos 3 estiver faltando, devolva para a fabrica antes de comecar. Analise incompleta nao e aceita.

---

## PASSO 2 — CRIAR A PASTA DO PROJETO

Copie o template para um novo projeto. Substitua `NOME_DO_PROJETO` pelo nome real:

```powershell
# Abra o PowerShell e execute:
$nome = "NOME_DO_PROJETO"
$base = "$env:USERPROFILE\Documents\projetos"

Copy-Item "$base\_TEMPLATE" "$base\$nome" -Recurse
```

Voce tera essa estrutura criada automaticamente:

```
projetos/
  NOME_DO_PROJETO/
    codigo/              <- coloque o codigo da fabrica aqui
    documentacao/        <- coloque os documentos aqui
    infraestrutura/      <- coloque os diagramas e IaC aqui
    relatorios/          <- o script salva os relatorios aqui
    apresentacoes/       <- o script salva os HTMLs aqui
    reanalise/           <- usado nas rodadas de reanalise
```

---

## PASSO 3 — COLOCAR OS ARQUIVOS NAS PASTAS

**Codigo fonte:**
```powershell
# Opção A: clonar repositorio git direto na pasta
git clone https://repositorio.empresa.com/projeto "$base\$nome\codigo"

# Opção B: extrair zip enviado pela fabrica
Expand-Archive "C:\Downloads\codigo_projeto.zip" "$base\$nome\codigo"

# Opção C: copiar pasta existente
Copy-Item "C:\Downloads\codigo_projeto\*" "$base\$nome\codigo\" -Recurse
```

**Documentacao:**
```powershell
Copy-Item "C:\Downloads\docs_projeto\*" "$base\$nome\documentacao\" -Recurse
```

**Infraestrutura:**
```powershell
Copy-Item "C:\Downloads\infra_projeto\*" "$base\$nome\infraestrutura\" -Recurse
```

**Verifique antes de continuar:**
```powershell
# Deve mostrar arquivos nas 3 pastas
ls "$base\$nome\codigo"
ls "$base\$nome\documentacao"
ls "$base\$nome\infraestrutura"
```

---

## PASSO 4 — RODAR A ANALISE COMPLETA

Abra o PowerShell e navegue ate a pasta onde o script esta instalado:

```powershell
cd "$env:USERPROFILE\Documents\Seguranca-TI"
```

Execute a analise completa:

```powershell
.\rodar_analise.ps1 -Projeto "NOME_DO_PROJETO"
```

**Pronto. O script agora roda sozinho.**

Voce vera o progresso em tempo real:

```
  ╔═══════════════════════════════════════════════════════╗
  ║   AUTOMACAO DE ANALISE DE SEGURANCA                  ║
  ╚═══════════════════════════════════════════════════════╝

  Projeto : SistemaRH
  Fase    : todas
  Inicio  : 15/03/2026 09:00

  ── FASE 1 — ANALISE DE CODIGO ──────────────────────────
  [>] Analise de Codigo (OWASP + Auth + Deps + Secrets + API)
      Dir  : C:\Users\...\projetos\SistemaRH\codigo
      Saida: C:\Users\...\projetos\SistemaRH\relatorios\01_analise_codigo.md
      OK em 18.3min -> ...\01_analise_codigo.md

  ── FASE 2 — ANALISE DE DOCUMENTACAO ────────────────────
  [>] Analise de Documentacao (Arquitetura + LGPD + Requisitos)
      ...
```

Enquanto o script processa, voce pode fazer outras coisas. Ele avisa quando terminar.

---

## PASSO 5 — O QUE O SCRIPT GERA

Quando terminar, voce encontrara os seguintes arquivos:

```
projetos/NOME_DO_PROJETO/
  relatorios/
    01_analise_codigo.md            <- achados de seguranca no codigo
    02_analise_documentacao.md      <- avaliacao de arquitetura e LGPD
    03_analise_infraestrutura.md    <- riscos de rede, IAM, containers
    04_threat_modeling.md           <- ameacas STRIDE por componente
    00_RELATORIO_EXECUTIVO.md       <- consolidado com parecer final
  apresentacoes/
    apresentacao_vulnerabilidades.html    <- para a Reuniao 1 com a fabrica
    apresentacao_melhorias_roadmap.html   <- para a Reuniao 2 com a fabrica
```

O resumo final do script tambem mostra o tempo de cada fase:

```
  ANALISE CONCLUIDA — 94min total

  Tempo por fase:
    Analise de Codigo                              18.3min
    Analise de Documentacao                         9.1min
    Analise de Infraestrutura                      11.4min
    Modelagem de Ameacas STRIDE                    14.2min
    Relatorio Executivo Consolidado + Parecer       8.7min
    Apresentacao de Vulnerabilidades (HTML)        16.3min
    Apresentacao de Melhorias e Roadmap (HTML)     16.0min

  AGORA E COM VOCE — revisao humana obrigatoria:
  1. Revise os relatorios em: ...\relatorios\
  2. Preencha o checklist   : ...\Seguranca-TI\CHECKLIST_SEGURANCA_PROJETOS.md
  3. Valide os achados (o agente pode ter falsos positivos)
  4. Assine o parecer final com o coordenador
  5. Apresentacoes em       : ...\apresentacoes\
```

---

## PASSO 6 — REVISAR OS RELATORIOS (OBRIGATORIO)

Abra cada relatorio e valide o que o agente gerou:

```powershell
# Abrir todos os relatorios de uma vez no editor padrao
Invoke-Item "$base\$nome\relatorios\01_analise_codigo.md"
Invoke-Item "$base\$nome\relatorios\02_analise_documentacao.md"
Invoke-Item "$base\$nome\relatorios\03_analise_infraestrutura.md"
Invoke-Item "$base\$nome\relatorios\04_threat_modeling.md"
Invoke-Item "$base\$nome\relatorios\00_RELATORIO_EXECUTIVO.md"
```

**O que verificar em cada relatorio:**

- [ ] Os achados fazem sentido tecnico para o tipo de sistema?
- [ ] Ha falsos positivos obvios? (remova ou marque como nao-aplicavel)
- [ ] Falta algum achado que voce identificou manualmente?
- [ ] A severidade atribuida esta correta?
- [ ] O parecer do relatorio executivo e justificado pelos achados?

> **Regra:** o agente e um assistente, nao o decisor. O analista e responsavel pelo conteudo final.

---

## PASSO 7 — PREENCHER O CHECKLIST

Abra o checklist padrao e preencha com base nos relatorios revisados:

```powershell
Invoke-Item "$env:USERPROFILE\Documents\Seguranca-TI\CHECKLIST_SEGURANCA_PROJETOS.md"
```

Siga as 6 fases do checklist:
- Fase 1: marque cada item de codigo como verificado ou nao-aplicavel
- Fase 2: marque cada item de documentacao
- Fase 3: marque cada item de infraestrutura
- Fase 4: confirme a analise STRIDE
- Fase 5: preencha a matriz de achados com os IDs e severidades
- Fase 6: marque o parecer final (APROVADO / APROVADO COM RESSALVAS / REPROVADO)

---

## PASSO 8 — APRESENTAR PARA A FABRICA

Abra as apresentacoes no navegador para as reunioes:

```powershell
# Reuniao 1 — Devolutiva de vulnerabilidades
Start-Process "$base\$nome\apresentacoes\apresentacao_vulnerabilidades.html"

# Reuniao 2 — Plano de acao e roadmap
Start-Process "$base\$nome\apresentacoes\apresentacao_melhorias_roadmap.html"
```

Navegacao nos slides: **setas do teclado** | ESC para tela cheia.

---

## OPCOES AVANCADAS

### Rodar apenas uma fase

Util quando voce precisa re-executar so uma parte (ex: a fabrica entregou codigo novo):

```powershell
# So o codigo
.\rodar_analise.ps1 -Projeto "SistemaRH" -Fase codigo

# So a infraestrutura
.\rodar_analise.ps1 -Projeto "SistemaRH" -Fase infra

# So as apresentacoes (relatorios ja prontos)
.\rodar_analise.ps1 -Projeto "SistemaRH" -Fase apresentacoes
```

Fases disponiveis:

| Fase | O que executa |
|------|--------------|
| `codigo` | Analise de codigo (OWASP, auth, deps, secrets, API) |
| `docs` | Analise de documentacao (arquitetura, LGPD, requisitos) |
| `infra` | Analise de infraestrutura (rede, IAM, IaC, containers) |
| `threat` | Threat modeling STRIDE |
| `relatorio` | Relatorio executivo consolidado |
| `apresentacoes` | As 2 apresentacoes HTML para a fabrica |
| `todas` | Tudo acima em sequencia (padrao) |
| `reanalise` | Processo completo de reanalise (R1 a R4) |

---

### Testar sem gastar creditos (dry run)

Mostra exatamente o que seria executado, sem chamar o Claude:

```powershell
.\rodar_analise.ps1 -Projeto "SistemaRH" -DryRun
```

Use antes de rodar um projeto grande para confirmar que tudo esta no lugar certo.

---

### Rodar a reanalise (quando a fabrica corrigir os achados)

**Antes de rodar**, coloque as evidencias da correcao em:
```
projetos/SistemaRH/reanalise/v1/evidencias/
  <- diffs, commits, documentos de correcao enviados pela fabrica
```

Depois execute:
```powershell
.\rodar_analise.ps1 -Projeto "SistemaRH" -Fase reanalise -Versao v1
```

O script gera 4 relatorios na pasta `reanalise/v1/relatorios/`:
```
RA_01_achados_criticos_altos.md    <- status de cada achado critico e alto
RA_02_achados_medios.md            <- status dos achados medios e prazos
RA_03_novos_achados.md             <- novos problemas introducidos pelas correcoes
RA_00_relatorio_reanalise.md       <- consolidado com parecer da reanalise
```

Para a segunda rodada de reanalise:
```powershell
.\rodar_analise.ps1 -Projeto "SistemaRH" -Fase reanalise -Versao v2
```

---

## PROBLEMAS FREQUENTES

### "Projeto nao encontrado"

```
ERRO: Projeto nao encontrado em: C:\Users\...\projetos\SistemaRH
```

**Causa:** a pasta do projeto nao existe ou o nome esta errado.

**Solucao:**
```powershell
# Ver projetos existentes
ls "$env:USERPROFILE\Documents\projetos"

# Criar o projeto se ainda nao existir
Copy-Item "$env:USERPROFILE\Documents\projetos\_TEMPLATE" `
          "$env:USERPROFILE\Documents\projetos\SistemaRH" -Recurse
```

---

### "Claude Code nao encontrado"

```
ERRO: Claude Code nao encontrado
```

**Solucao:**
```powershell
npm install -g @anthropic-ai/claude-code
claude auth login
```

---

### O script trava em uma fase

Se o Claude demorar mais de 30 minutos em uma fase, pode ser problema de conexao ou contexto muito grande.

**Solucao:** pressione `Ctrl+C` para cancelar e rode apenas a fase com problema:
```powershell
# Cancelar e re-rodar so a fase travada
.\rodar_analise.ps1 -Projeto "SistemaRH" -Fase infra
```

---

### "claude: the term is not recognized"

O Claude Code nao esta no PATH da sessao atual.

**Solucao:** feche e reabra o PowerShell. Se persistir:
```powershell
npm install -g @anthropic-ai/claude-code
```

---

### Relatorio gerado esta vazio ou com erro

Abra o arquivo e veja se contem uma mensagem de erro do Claude. Geralmente acontece quando:
- A pasta de origem estava vazia (sem arquivos para analisar)
- O contexto ultrapassou o limite (projeto muito grande)

**Solucao para projeto muito grande:**
```powershell
# Rodar cada fase separadamente em vez de todas de uma vez
.\rodar_analise.ps1 -Projeto "SistemaRH" -Fase codigo
# revisar o resultado, depois:
.\rodar_analise.ps1 -Projeto "SistemaRH" -Fase docs
# e assim por diante
```

---

## REFERENCIA RAPIDA

```powershell
# INSTALACAO INICIAL (uma vez por maquina)
cd Seguranca-TI-Setup
.\instalar.ps1

# NOVO PROJETO
$nome = "NomeDoProjeto"
Copy-Item "$env:USERPROFILE\Documents\projetos\_TEMPLATE" `
          "$env:USERPROFILE\Documents\projetos\$nome" -Recurse
# coloque os arquivos nas pastas codigo/ docs/ infra/

# ANALISE COMPLETA
cd "$env:USERPROFILE\Documents\Seguranca-TI"
.\rodar_analise.ps1 -Projeto $nome

# FASE ESPECIFICA
.\rodar_analise.ps1 -Projeto $nome -Fase codigo

# DRY RUN
.\rodar_analise.ps1 -Projeto $nome -DryRun

# REANALISE
# coloque evidencias em reanalise/v1/evidencias/
.\rodar_analise.ps1 -Projeto $nome -Fase reanalise -Versao v1

# ABRIR RELATORIOS
$r = "$env:USERPROFILE\Documents\projetos\$nome\relatorios"
Invoke-Item "$r\00_RELATORIO_EXECUTIVO.md"

# ABRIR APRESENTACOES
$a = "$env:USERPROFILE\Documents\projetos\$nome\apresentacoes"
Start-Process "$a\apresentacao_vulnerabilidades.html"
Start-Process "$a\apresentacao_melhorias_roadmap.html"

# ABRIR CHECKLIST
Invoke-Item "$env:USERPROFILE\Documents\Seguranca-TI\CHECKLIST_SEGURANCA_PROJETOS.md"
```
