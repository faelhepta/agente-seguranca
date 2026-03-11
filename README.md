# Agente de Seguranca

Toolkit de analise de seguranca para avaliacao de projetos de software.
Automatiza todo o ciclo de revisao — do codigo-fonte ao relatorio executivo — usando o **Claude Code** como motor de analise, e gera apresentacoes HTML prontas para reuniao com as equipes de desenvolvimento.

---

## Como funciona

O agente recebe os artefatos de um projeto (codigo, documentacao e infraestrutura), executa cinco fases de analise em sequencia e entrega:

- **5 relatorios Markdown** com achados tecnicos detalhados
- **2 apresentacoes HTML** para as reunioes de devolutiva com o time de desenvolvimento
- **Parecer final** — Aprovado / Aprovado com Ressalvas / Reprovado

Quando o time de desenvolvimento corrige os achados e devolve o projeto, o agente executa o ciclo de **reanalise** e verifica cada correcao individualmente.

---

## Fases de analise

| Fase | O que analisa | Saida |
|------|---------------|-------|
| 1 — Codigo | OWASP Top 10, autenticacao, dependencias (CVEs), secrets, seguranca de API | `01_analise_codigo.md` |
| 2 — Documentacao | Arquitetura, fluxo de dados, conformidade LGPD, requisitos de seguranca | `02_analise_documentacao.md` |
| 3 — Infraestrutura | Rede, IAM, IaC (Terraform/CF), containers, monitoramento | `03_analise_infraestrutura.md` |
| 4 — Threat Modeling | Framework STRIDE por componente critico | `04_threat_modeling.md` |
| 5 — Relatorio Executivo | Consolidado com matriz de risco, plano de correcao e parecer | `00_RELATORIO_EXECUTIVO.md` |

Apos as cinco fases, dois skills do Claude Code geram as apresentacoes:

- `/relatorio-fabrica` — apresentacao de vulnerabilidades + plano de melhorias com roadmap visual
- `/reanalise-fabrica` — verifica correcoes entregues e emite novo parecer

---

## Pre-requisitos

- **Node.js 18+** — `node --version`
- **Claude Code** — `npm install -g @anthropic-ai/claude-code`
- **Autenticacao** — `claude auth login`

---

## Instalacao

```powershell
# Windows — PowerShell
git clone https://github.com/faelhepta/agente-seguranca.git
cd agente-seguranca
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\instalar.ps1
```

```bash
# Git Bash / WSL
git clone https://github.com/faelhepta/agente-seguranca.git
cd agente-seguranca
bash instalar.sh
```

O instalador copia os skills, documentos e scripts para os destinos corretos na maquina do analista e cria a estrutura de pastas para os projetos.

Ver detalhes em [GUIA_INSTALACAO.md](GUIA_INSTALACAO.md).

---

## Uso

### Modo simples (recomendado)

```powershell
cd "$env:USERPROFILE\Documents\Seguranca-TI"
.\analisar.ps1
```

O script pede o caminho da pasta do projeto, detecta quais artefatos estao presentes (codigo, documentacao, infraestrutura) e executa todas as fases automaticamente.

### Modo avancado (por parametros)

```powershell
cd "$env:USERPROFILE\Documents\Seguranca-TI"

# Analise completa
.\rodar_analise.ps1 -Projeto "NomeDoProjeto"

# Fase especifica
.\rodar_analise.ps1 -Projeto "NomeDoProjeto" -Fase codigo

# Simular sem executar
.\rodar_analise.ps1 -Projeto "NomeDoProjeto" -DryRun

# Reanalise apos correcoes
.\rodar_analise.ps1 -Projeto "NomeDoProjeto" -Fase reanalise -Versao v1
```

Fases disponiveis: `codigo` | `docs` | `infra` | `threat` | `relatorio` | `apresentacoes` | `reanalise` | `todas`

---

## Estrutura do repositorio

```
.
|-- instalar.ps1              <- instalador Windows
|-- instalar.sh               <- instalador Linux/WSL/Git Bash
|-- GUIA_INSTALACAO.md        <- instrucoes detalhadas de instalacao
|-- skills/
|   |-- relatorio-fabrica.md  <- skill /relatorio-fabrica (apresentacoes HTML)
|   `-- reanalise-fabrica.md  <- skill /reanalise-fabrica (verificacao de correcoes)
|-- docs/                     <- instalados em ~/Documents/Seguranca-TI/
|   |-- analisar.ps1          <- SCRIPT PRINCIPAL: pede o caminho e roda tudo (Windows)
|   |-- analisar.sh           <- SCRIPT PRINCIPAL: pede o caminho e roda tudo (Linux/WSL)
|   |-- rodar_analise.ps1     <- script avancado com parametros (Windows)
|   |-- rodar_analise.sh      <- script avancado com parametros (Linux/WSL)
|   |-- RUNBOOK_AGENTE_SEGURANCA.md
|   |-- CHECKLIST_SEGURANCA_PROJETOS.md
|   |-- CHECKLIST_REANALISE_PROJETOS.md
|   |-- TUTORIAL_RODAR_ANALISE.md
|   `-- apresentacao_time_seguranca.html
`-- extras/
    |-- gerar_apresentacoes.ps1 <- regenera as apresentacoes HTML de um projeto ja analisado
    `-- analisar_api.ps1
```

---

## Documentacao

| Documento | Descricao |
|-----------|-----------|
| [GUIA_INSTALACAO.md](GUIA_INSTALACAO.md) | Instalacao, atualizacao e solucao de problemas |
| [docs/RUNBOOK_AGENTE_SEGURANCA.md](docs/RUNBOOK_AGENTE_SEGURANCA.md) | Fluxo operacional completo — analise e reanalise |
| [docs/TUTORIAL_RODAR_ANALISE.md](docs/TUTORIAL_RODAR_ANALISE.md) | Como usar o script de automacao `rodar_analise.ps1` |
| [docs/CHECKLIST_SEGURANCA_PROJETOS.md](docs/CHECKLIST_SEGURANCA_PROJETOS.md) | Checklist da analise inicial |
| [docs/CHECKLIST_REANALISE_PROJETOS.md](docs/CHECKLIST_REANALISE_PROJETOS.md) | Checklist de verificacao de correcoes |

---

## Atualizando o time

Quando houver atualizacao nos skills ou documentos:

```powershell
git pull
.\instalar.ps1 -Modo update
```

---

`v1.0` — Marco 2026
