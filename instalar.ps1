#Requires -Version 5.1
<#
.SYNOPSIS
    Instalador do Ambiente de Seguranca - Coordenacao de Seguranca de TI

.DESCRIPTION
    Instala os skills do agente de seguranca e os documentos do processo
    na maquina do analista. Requer Claude Code ja instalado.

.PARAMETER Modo
    install  (padrao) — instalacao completa
    update   — atualiza apenas skills e documentos, sem recriar pastas

.PARAMETER OrigemDocs
    Caminho para a pasta do pacote. Padrao: pasta onde o script esta localizado.

.EXAMPLE
    .\instalar.ps1
    .\instalar.ps1 -Modo update
    .\instalar.ps1 -OrigemDocs "\\servidor\TI\Seguranca-TI-Setup"
#>

param(
    [ValidateSet("install","update")]
    [string]$Modo = "install",
    [string]$OrigemDocs = $PSScriptRoot
)

# ─────────────────────────────────────────────
#  CONFIGURACAO
# ─────────────────────────────────────────────
$VERSAO_PACOTE    = "1.0"
$NODE_VERSAO_MIN  = 18
$DESTINO_SKILLS   = "$env:USERPROFILE\.claude\skills"
$DESTINO_DOCS     = "$env:USERPROFILE\Documents\Seguranca-TI"
$DESTINO_PROJETOS = "$env:USERPROFILE\Documents\projetos"
$ORIGEM_SKILLS    = Join-Path $OrigemDocs "skills"
$ORIGEM_DOCS_DIR  = Join-Path $OrigemDocs "docs"

# ─────────────────────────────────────────────
#  CORES E HELPERS
# ─────────────────────────────────────────────
function Write-Header {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║   INSTALADOR — AGENTE DE SEGURANCA                  ║" -ForegroundColor Cyan
    Write-Host "  ║   Coordenacao de Seguranca de TI  •  v$VERSAO_PACOTE           ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step {
    param([string]$Numero, [string]$Texto)
    Write-Host "  [$Numero] " -ForegroundColor DarkCyan -NoNewline
    Write-Host $Texto -ForegroundColor White
}

function Write-OK   { Write-Host "       OK  " -ForegroundColor Green -NoNewline;  Write-Host $args[0] -ForegroundColor Gray }
function Write-WARN { Write-Host "     AVISO  " -ForegroundColor Yellow -NoNewline; Write-Host $args[0] -ForegroundColor Gray }
function Write-FAIL { Write-Host "     ERRO  " -ForegroundColor Red -NoNewline;    Write-Host $args[0] -ForegroundColor Gray }
function Write-INFO { Write-Host "     INFO  " -ForegroundColor DarkCyan -NoNewline; Write-Host $args[0] -ForegroundColor Gray }

$erros   = @()
$avisos  = @()
$copiados = @()

# ─────────────────────────────────────────────
#  INICIO
# ─────────────────────────────────────────────
Write-Header

$modo_label = if ($Modo -eq "update") { "ATUALIZACAO" } else { "INSTALACAO COMPLETA" }
Write-Host "  Modo    : $modo_label" -ForegroundColor White
Write-Host "  Usuario : $env:USERNAME" -ForegroundColor White
Write-Host "  Maquina : $env:COMPUTERNAME" -ForegroundColor White
Write-Host "  Origem  : $OrigemDocs" -ForegroundColor White
Write-Host ""

# ─────────────────────────────────────────────
#  PASSO 1 — VERIFICAR PRE-REQUISITOS
# ─────────────────────────────────────────────
Write-Step "1/5" "Verificando pre-requisitos..."

# Node.js
try {
    $nodeVer = (node --version 2>$null).TrimStart('v')
    $nodeMajor = [int]($nodeVer -split '\.')[0]
    if ($nodeMajor -ge $NODE_VERSAO_MIN) {
        Write-OK "Node.js $nodeVer encontrado"
    } else {
        Write-FAIL "Node.js $nodeVer encontrado, mas e necessario v$NODE_VERSAO_MIN+. Baixe em https://nodejs.org"
        $erros += "Node.js desatualizado ($nodeVer)"
    }
} catch {
    Write-FAIL "Node.js nao encontrado. Instale v$NODE_VERSAO_MIN+ em https://nodejs.org"
    $erros += "Node.js nao encontrado"
}

# Claude Code
try {
    $claudeVer = (claude --version 2>$null)
    if ($claudeVer) {
        Write-OK "Claude Code encontrado: $claudeVer"
    } else { throw }
} catch {
    Write-FAIL "Claude Code nao encontrado. Instale com: npm install -g @anthropic-ai/claude-code"
    $erros += "Claude Code nao encontrado"
}

# Pasta de origem dos skills
if (Test-Path $ORIGEM_SKILLS) {
    $qtdSkills = (Get-ChildItem $ORIGEM_SKILLS -Filter "*.md").Count
    Write-OK "Pasta de skills encontrada ($qtdSkills arquivos)"
} else {
    Write-FAIL "Pasta 'skills' nao encontrada em: $ORIGEM_SKILLS"
    $erros += "Pasta skills ausente"
}

# Pasta de origem dos docs
if (Test-Path $ORIGEM_DOCS_DIR) {
    $qtdDocs = (Get-ChildItem $ORIGEM_DOCS_DIR).Count
    Write-OK "Pasta de documentos encontrada ($qtdDocs arquivos)"
} else {
    Write-FAIL "Pasta 'docs' nao encontrada em: $ORIGEM_DOCS_DIR"
    $erros += "Pasta docs ausente"
}

# Abortar se houver erros criticos
if ($erros.Count -gt 0) {
    Write-Host ""
    Write-Host "  INSTALACAO INTERROMPIDA — corrija os erros acima e execute novamente." -ForegroundColor Red
    exit 1
}

# ─────────────────────────────────────────────
#  PASSO 2 — CRIAR ESTRUTURA DE PASTAS
# ─────────────────────────────────────────────
Write-Host ""
Write-Step "2/5" "Criando estrutura de pastas..."

$pastas = @(
    $DESTINO_SKILLS,
    $DESTINO_DOCS,
    "$env:USERPROFILE\.claude"
)

if ($Modo -eq "install") {
    $pastas += @(
        $DESTINO_PROJETOS,
        "$DESTINO_PROJETOS\_TEMPLATE\codigo",
        "$DESTINO_PROJETOS\_TEMPLATE\documentacao",
        "$DESTINO_PROJETOS\_TEMPLATE\infraestrutura",
        "$DESTINO_PROJETOS\_TEMPLATE\relatorios",
        "$DESTINO_PROJETOS\_TEMPLATE\apresentacoes",
        "$DESTINO_PROJETOS\_TEMPLATE\reanalise\v1\evidencias",
        "$DESTINO_PROJETOS\_TEMPLATE\reanalise\v1\relatorios",
        "$DESTINO_PROJETOS\_TEMPLATE\reanalise\v1\apresentacoes"
    )
}

foreach ($pasta in $pastas) {
    if (-not (Test-Path $pasta)) {
        New-Item -ItemType Directory -Path $pasta -Force | Out-Null
        Write-OK "Criada: $pasta"
    } else {
        Write-INFO "Ja existe: $pasta"
    }
}

# ─────────────────────────────────────────────
#  PASSO 3 — INSTALAR SKILLS DO AGENTE
# ─────────────────────────────────────────────
Write-Host ""
Write-Step "3/5" "Instalando skills do agente..."

$skills = Get-ChildItem $ORIGEM_SKILLS -Filter "*.md"
foreach ($skill in $skills) {
    $destino = Join-Path $DESTINO_SKILLS $skill.Name
    $acao = if (Test-Path $destino) { "Atualizado" } else { "Instalado" }
    try {
        Copy-Item $skill.FullName $destino -Force
        Write-OK "$acao skill: $($skill.Name)"
        $copiados += $skill.Name
    } catch {
        Write-FAIL "Falha ao copiar skill: $($skill.Name) — $_"
        $erros += "Skill: $($skill.Name)"
    }
}

# ─────────────────────────────────────────────
#  PASSO 4 — INSTALAR DOCUMENTOS DO PROCESSO
# ─────────────────────────────────────────────
Write-Host ""
Write-Step "4/5" "Instalando documentos do processo..."

$docs = Get-ChildItem $ORIGEM_DOCS_DIR
foreach ($doc in $docs) {
    $destino = Join-Path $DESTINO_DOCS $doc.Name
    $acao = if (Test-Path $destino) { "Atualizado" } else { "Instalado" }
    try {
        Copy-Item $doc.FullName $destino -Force
        Write-OK "$acao doc: $($doc.Name)"
        $copiados += $doc.Name
    } catch {
        Write-FAIL "Falha ao copiar: $($doc.Name) — $_"
        $avisos += "Doc: $($doc.Name)"
    }
}

# ─────────────────────────────────────────────
#  PASSO 5 — VALIDACAO FINAL
# ─────────────────────────────────────────────
Write-Host ""
Write-Step "5/5" "Validando instalacao..."

$validacoes = @(
    @{ Caminho = "$DESTINO_SKILLS\relatorio-fabrica.md";          Label = "Skill /relatorio-fabrica" },
    @{ Caminho = "$DESTINO_SKILLS\reanalise-fabrica.md";          Label = "Skill /reanalise-fabrica" },
    @{ Caminho = "$DESTINO_DOCS\CHECKLIST_SEGURANCA_PROJETOS.md"; Label = "Checklist de analise" },
    @{ Caminho = "$DESTINO_DOCS\CHECKLIST_REANALISE_PROJETOS.md"; Label = "Checklist de reanalise" },
    @{ Caminho = "$DESTINO_DOCS\RUNBOOK_AGENTE_SEGURANCA.md";     Label = "Runbook do agente" },
    @{ Caminho = "$DESTINO_DOCS\apresentacao_time_seguranca.html";Label = "Apresentacao do time" }
)

$falhas_val = 0
foreach ($v in $validacoes) {
    if (Test-Path $v.Caminho) {
        Write-OK $v.Label
    } else {
        Write-FAIL "NAO ENCONTRADO: $($v.Label)"
        $falhas_val++
    }
}

# ─────────────────────────────────────────────
#  RESUMO FINAL
# ─────────────────────────────────────────────
Write-Host ""
Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

if ($erros.Count -eq 0 -and $falhas_val -eq 0) {
    Write-Host "  INSTALACAO CONCLUIDA COM SUCESSO" -ForegroundColor Green
    Write-Host ""
    Write-Host "  $($copiados.Count) arquivo(s) instalado(s)/atualizado(s)" -ForegroundColor White
    Write-Host ""
    Write-Host "  Proximos passos:" -ForegroundColor Cyan
    Write-Host "  1. Abra o terminal na pasta de um projeto" -ForegroundColor White
    Write-Host "  2. Execute: npx claude-code-templates@latest --agent devops-infrastructure/security-engineer" -ForegroundColor White
    Write-Host "  3. Para analise: siga o Runbook (Passos 0 a 7)" -ForegroundColor White
    Write-Host "  4. Para reanalise: use /reanalise-fabrica no agente" -ForegroundColor White
    Write-Host "  5. Para apresentacoes: use /relatorio-fabrica no agente" -ForegroundColor White
    Write-Host ""
    Write-Host "  Documentos em : $DESTINO_DOCS" -ForegroundColor DarkCyan
    Write-Host "  Skills em     : $DESTINO_SKILLS" -ForegroundColor DarkCyan
    if ($Modo -eq "install") {
        Write-Host "  Projetos em   : $DESTINO_PROJETOS" -ForegroundColor DarkCyan
        Write-Host "  Template em   : $DESTINO_PROJETOS\_TEMPLATE" -ForegroundColor DarkCyan
    }
} elseif ($avisos.Count -gt 0 -and $erros.Count -eq 0) {
    Write-Host "  INSTALACAO CONCLUIDA COM AVISOS" -ForegroundColor Yellow
    foreach ($a in $avisos) { Write-WARN $a }
} else {
    Write-Host "  INSTALACAO CONCLUIDA COM ERROS" -ForegroundColor Red
    foreach ($e in $erros) { Write-FAIL $e }
    Write-Host ""
    Write-Host "  Corrija os erros acima e execute o script novamente." -ForegroundColor Red
}

Write-Host ""
Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
