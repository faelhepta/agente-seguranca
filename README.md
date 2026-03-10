# Agente de Seguranca — Coordenacao de Seguranca de TI

Toolkit para analise de seguranca de projetos entregues por fabricas de software.
Automatiza as fases de analise usando o **Claude Code** e gera relatorios e apresentacoes profissionais.

---

## O que este repositorio instala

| Artefato | Destino na maquina |
|----------|--------------------|
| Skill `/relatorio-fabrica` | `%USERPROFILE%\.claude\skills\` |
| Skill `/reanalise-fabrica` | `%USERPROFILE%\.claude\skills\` |
| Runbook do agente | `%USERPROFILE%\Documents\Seguranca-TI\` |
| Checklists de analise e reanalise | `%USERPROFILE%\Documents\Seguranca-TI\` |
| Tutorial e apresentacao do time | `%USERPROFILE%\Documents\Seguranca-TI\` |
| Script de automacao `rodar_analise.ps1` | `%USERPROFILE%\Documents\Seguranca-TI\` |
| Template de pasta de projetos | `%USERPROFILE%\Documents\projetos\_TEMPLATE\` |

---

## Pre-requisitos

- Node.js 18+: `node --version`
- Claude Code: `npm install -g @anthropic-ai/claude-code`
- Autenticacao ativa: `claude auth login`

---

## Instalacao

```powershell
# Windows (PowerShell)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\instalar.ps1
```

```bash
# Git Bash / WSL
bash instalar.sh
```

Ver detalhes completos em: [GUIA_INSTALACAO.md](GUIA_INSTALACAO.md)

---

## Fluxo de analise

```
PROJETO RECEBIDO DA FABRICA
         |
         v
[rodar_analise.ps1]  <- automacao completa
         |
         v
relatorios/
  01_analise_codigo.md
  02_analise_documentacao.md
  03_analise_infraestrutura.md
  04_threat_modeling.md
  00_RELATORIO_EXECUTIVO.md
         |
         v
[/relatorio-fabrica]  <- skill Claude Code
         |
         v
apresentacoes/
  apresentacao_vulnerabilidades.html
  apresentacao_melhorias_roadmap.html
         |
         v
REUNIOES COM A FABRICA -> ROADMAP APROVADO
         |
         v
[/reanalise-fabrica]  <- quando fabrica entregar correcoes
```

---

## Estrutura do repositorio

```
.
|-- instalar.ps1                  <- instalador Windows
|-- instalar.sh                   <- instalador Linux/WSL/Git Bash
|-- GUIA_INSTALACAO.md            <- instrucoes detalhadas
|-- skills/
|   |-- relatorio-fabrica.md      <- skill /relatorio-fabrica
|   `-- reanalise-fabrica.md      <- skill /reanalise-fabrica
|-- docs/
|   |-- RUNBOOK_AGENTE_SEGURANCA.md
|   |-- CHECKLIST_SEGURANCA_PROJETOS.md
|   |-- CHECKLIST_REANALISE_PROJETOS.md
|   |-- TUTORIAL_RODAR_ANALISE.md
|   |-- apresentacao_time_seguranca.html
|   |-- rodar_analise.ps1         <- script de automacao (Windows)
|   `-- rodar_analise.sh          <- script de automacao (Linux/WSL)
`-- extras/
    |-- analisar.ps1              <- analise interativa (pede caminho)
    |-- analisar.sh
    |-- gerar_apresentacoes.ps1   <- gera so as apresentacoes HTML
    `-- analisar_api.ps1
```

---

## Uso rapido (apos instalacao)

```powershell
# Analise completa de um projeto
cd "$env:USERPROFILE\Documents\Seguranca-TI"
.\rodar_analise.ps1 -Projeto "NomeDoProjeto"

# Apenas uma fase especifica
.\rodar_analise.ps1 -Projeto "NomeDoProjeto" -Fase codigo

# Simular sem executar (dry run)
.\rodar_analise.ps1 -Projeto "NomeDoProjeto" -DryRun

# Reanalise apos correcoes da fabrica
.\rodar_analise.ps1 -Projeto "NomeDoProjeto" -Fase reanalise -Versao v1
```

---

## Documentacao

| Documento | Descricao |
|-----------|-----------|
| [GUIA_INSTALACAO.md](GUIA_INSTALACAO.md) | Instalacao passo a passo |
| [docs/RUNBOOK_AGENTE_SEGURANCA.md](docs/RUNBOOK_AGENTE_SEGURANCA.md) | Fluxo completo de analise (Passos 0-7 + Reanalise) |
| [docs/TUTORIAL_RODAR_ANALISE.md](docs/TUTORIAL_RODAR_ANALISE.md) | Como usar o script de automacao |
| [docs/CHECKLIST_SEGURANCA_PROJETOS.md](docs/CHECKLIST_SEGURANCA_PROJETOS.md) | Checklist de analise inicial |
| [docs/CHECKLIST_REANALISE_PROJETOS.md](docs/CHECKLIST_REANALISE_PROJETOS.md) | Checklist de reanalise |

---

## Versao

`v1.0` — Marco 2026
