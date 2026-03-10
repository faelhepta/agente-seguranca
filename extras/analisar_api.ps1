# =============================================================================
#  MODULO DE ANALISE DE API - Coordenacao de Seguranca de TI
#  Uso: .\analisar_api.ps1
#  Aponte para a pasta do codigo da API. O script sobe a aplicacao,
#  mapeia os endpoints e executa testes de seguranca ativos.
# =============================================================================

function c($msg, $cor = "White") { Write-Host $msg -ForegroundColor $cor }

Clear-Host
c ""
c "  =======================================================" Cyan
c "     MODULO DE ANALISE DE API" Cyan
c "     Coordenacao de Seguranca de TI" Cyan
c "  =======================================================" Cyan
c ""
c "  O que este modulo faz:" Gray
c "    1. Detecta a stack (Node.js ou .NET)" Gray
c "    2. Sobe a aplicacao localmente" Gray
c "    3. Mapeia todos os endpoints" Gray
c "    4. Executa testes de seguranca ativos (HTTP reais)" Gray
c "    5. Gera relatorio de achados" Gray
c ""

# Verificar pre-requisitos
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    c "  ERRO: Claude Code nao encontrado." Red
    c "  Execute: npm install -g @anthropic-ai/claude-code" Yellow
    exit 1
}

# Pedir caminho da pasta
c "  Informe o caminho completo da pasta do codigo da API:" White
c "  (ex: C:\projetos\SistemaRH\codigo\api)" Gray
c ""
$PASTA = Read-Host "  Caminho"
$PASTA = $PASTA.Trim().Trim('"')

if (-not (Test-Path $PASTA -PathType Container)) {
    c "  ERRO: Pasta nao encontrada: $PASTA" Red
    exit 1
}

# Detectar stack
$ehNode  = Test-Path (Join-Path $PASTA "package.json")
$ehDotnet = (Get-ChildItem $PASTA -Filter "*.csproj" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1) -ne $null

if (-not $ehNode -and -not $ehDotnet) {
    c ""
    c "  AVISO: nao foi possivel detectar automaticamente a stack (Node.js ou .NET)." Yellow
    c "  Certifique-se de que o package.json ou .csproj estao na pasta informada." Yellow
    c ""
    $stackManual = Read-Host "  Informe a stack manualmente (node / dotnet)"
    $ehNode   = ($stackManual.Trim().ToLower() -eq "node")
    $ehDotnet = ($stackManual.Trim().ToLower() -eq "dotnet")
    if (-not $ehNode -and -not $ehDotnet) {
        c "  ERRO: stack nao reconhecida. Informe 'node' ou 'dotnet'." Red
        exit 1
    }
}

$stack = if ($ehNode) { "Node.js" } else { ".NET" }
c ""
c "  Stack detectada : $stack" Green
c "  Pasta da API    : $PASTA" White

# Verificar se o runtime necessario esta instalado
if ($ehNode) {
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        c ""
        c "  ERRO: Node.js nao encontrado no PATH." Red
        c "  Instale o Node.js em: https://nodejs.org" Yellow
        exit 1
    }
    $nodeVer = node --version 2>$null
    c "  Runtime         : Node.js $nodeVer" DarkGray
}

if ($ehDotnet) {
    $dotnetOk = $false
    try {
        $dotnetVer = dotnet --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $dotnetVer) { $dotnetOk = $true }
    } catch {}

    if (-not $dotnetOk) {
        c ""
        c "  ERRO: .NET SDK nao encontrado nesta maquina." Red
        c ""
        c "  Para analisar este projeto voce tem duas opcoes:" Yellow
        c ""
        c "  OPCAO A - Instalar o .NET SDK:" White
        c "    Acesse: https://dotnet.microsoft.com/download" DarkGray
        c "    Instale o SDK (nao apenas o Runtime)" DarkGray
        c "    Reinicie o PowerShell e rode este script novamente" DarkGray
        c ""
        c "  OPCAO B - Subir a API manualmente em outra maquina e informar a URL:" White
        c "    Rode este script novamente e informe a URL quando solicitado" DarkGray
        c ""
        $continuar = Read-Host "  Deseja continuar informando a URL manualmente? (S/N)"
        if ($continuar.Trim().ToUpper() -ne "S") { exit 1 }
        $ehDotnet = $false  # pula o auto-start, cai no fluxo de URL manual
    } else {
        c "  Runtime         : .NET SDK $dotnetVer" DarkGray
    }
}

# Detectar porta padrao
$portaPadrao = 3000
if ($ehDotnet) { $portaPadrao = 5000 }

if ($ehNode -and (Test-Path (Join-Path $PASTA "package.json"))) {
    $pkgJson = Get-Content (Join-Path $PASTA "package.json") -Raw -ErrorAction SilentlyContinue
    if ($pkgJson -match '"port"\s*:\s*(\d+)') { $portaPadrao = [int]$Matches[1] }
    if ($pkgJson -match 'PORT\s*[=|]\|*\s*(\d+)')  { $portaPadrao = [int]$Matches[1] }
}

c ""
c "  A aplicacao sera iniciada automaticamente." Cyan
c "  Se ela ja estiver rodando, pressione Ctrl+C e informe a URL abaixo." Gray
c ""
$urlCustom = Read-Host "  URL base da API (deixe em branco para auto-iniciar na porta $portaPadrao)"
$urlCustom = $urlCustom.Trim()

$URL_BASE = if ($urlCustom -ne "") { $urlCustom.TrimEnd('/') } else { "http://localhost:$portaPadrao" }
$appProcess = $null
$iniciouApp = $false

if ($urlCustom -eq "") {
    c ""
    c "  Iniciando a aplicacao..." Cyan

    if ($ehNode) {
        # Instalar dependencias se necessario
        if (-not (Test-Path (Join-Path $PASTA "node_modules"))) {
            c "  Instalando dependencias npm..." DarkGray
            $npm = Start-Process "npm" -ArgumentList "install" -WorkingDirectory $PASTA -Wait -PassThru -NoNewWindow
            if ($npm.ExitCode -ne 0) {
                c "  AVISO: npm install retornou erro. Tentando continuar..." Yellow
            }
        }

        # Detectar script de start
        $startScript = "start"
        $pkgJson = Get-Content (Join-Path $PASTA "package.json") -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($pkgJson.scripts.PSObject.Properties.Name -contains "dev")   { $startScript = "dev" }
        if ($pkgJson.scripts.PSObject.Properties.Name -contains "start") { $startScript = "start" }

        c "  Executando: npm run $startScript" DarkGray
        $appProcess = Start-Process "npm" -ArgumentList "run", $startScript -WorkingDirectory $PASTA -PassThru -NoNewWindow
    }

    if ($ehDotnet) {
        $csprojFile = Get-ChildItem $PASTA -Filter "*.csproj" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $csprojFile) {
            c "  ERRO: nenhum arquivo .csproj encontrado em $PASTA" Red
            exit 1
        }

        $csprojDir = $csprojFile.DirectoryName
        c "  Projeto encontrado: $($csprojFile.FullName)" DarkGray

        # Verificar compatibilidade de versao antes de subir
        c "  Verificando compatibilidade com o SDK instalado..." DarkGray
        $restoreOutput = & dotnet restore $csprojFile.FullName 2>&1 | Out-String

        # Detectar incompatibilidade de framework (ex: netcoreapp3.1 vs SDK 10)
        $frameworkIncompat = $restoreOutput -match "NU1100" -or $restoreOutput -match "nao foi possivel resolver" -or $restoreOutput -match "could not be resolved"
        $targetFramework = ""
        $csprojContent = Get-Content $csprojFile.FullName -Raw -ErrorAction SilentlyContinue
        if ($csprojContent -match "<TargetFramework>(.*?)</TargetFramework>") {
            $targetFramework = $Matches[1]
        }

        if ($frameworkIncompat) {
            c ""
            c "  ERRO: incompatibilidade de versao do .NET." Red
            if ($targetFramework) {
                c "  O projeto requer : $targetFramework" Yellow
                c "  SDK instalado    : $dotnetVer" Yellow
            }
            c ""
            c "  Este projeto foi desenvolvido para uma versao antiga do .NET" Yellow
            c "  que nao e compativel com o SDK instalado nesta maquina." Yellow
            c ""
            c "  Para resolver, voce tem duas opcoes:" Cyan
            c ""
            c "  OPCAO A - Subir a API em outra maquina com o SDK correto:" White
            c "    Informe a URL quando o script perguntar" DarkGray
            c ""
            c "  OPCAO B - Instalar o SDK correto nesta maquina:" White
            if ($targetFramework) {
                c "    Procure '$targetFramework SDK' em: https://dotnet.microsoft.com/download/dotnet" DarkGray
            }
            c "    Atenção: versoes antigas do .NET podem estar sem suporte de seguranca" DarkYellow
            c "             (isso em si ja e um achado para o relatorio)" DarkYellow
            c ""
            $continuar = Read-Host "  Deseja continuar informando a URL manualmente? (S/N)"
            if ($continuar.Trim().ToUpper() -ne "S") {
                exit 1
            }
            # Pedir URL manualmente e pular o auto-start
            $urlManual = Read-Host "  Informe a URL base da API (ex: http://localhost:5000)"
            $URL_BASE  = $urlManual.Trim().TrimEnd('/')
            $iniciouApp = $false
        } else {
            c "  Executando: dotnet run" DarkGray
            $appProcess = Start-Process "dotnet" -ArgumentList "run" -WorkingDirectory $csprojDir -PassThru -NoNewWindow
        }
    }

    $iniciouApp = $true

    # Aguardar a aplicacao responder
    c "  Aguardando a aplicacao responder em $URL_BASE ..." DarkGray
    $maxTentativas = 30
    $tentativa = 0
    $appOk = $false

    while ($tentativa -lt $maxTentativas) {
        Start-Sleep -Seconds 2
        $tentativa++
        try {
            $resp = Invoke-WebRequest -Uri $URL_BASE -TimeoutSec 3 -ErrorAction SilentlyContinue -UseBasicParsing
            if ($resp.StatusCode -lt 500) {
                $appOk = $true
                break
            }
        } catch {
            # ainda nao respondeu, continua tentando
        }
        Write-Host "    aguardando... ($tentativa/$maxTentativas)" -ForegroundColor DarkGray
    }

    if (-not $appOk) {
        c ""
        c "  AVISO: a aplicacao nao respondeu em ${URL_BASE} apos $maxTentativas tentativas." Yellow
        c "  Verifique se ela sobe corretamente e qual porta usa." Yellow
        $urlManual = Read-Host "  Informe a URL correta (ou deixe em branco para abortar)"
        if ($urlManual.Trim() -eq "") {
            if ($appProcess) { Stop-Process -Id $appProcess.Id -Force -ErrorAction SilentlyContinue }
            exit 1
        }
        $URL_BASE = $urlManual.Trim().TrimEnd('/')
    } else {
        c "  Aplicacao respondendo em $URL_BASE" Green
    }
}

# Pasta de saida dos relatorios
$REL = Join-Path $PASTA "relatorios-api"
New-Item -ItemType Directory -Force -Path $REL | Out-Null

c ""
c "  URL da API      : $URL_BASE" White
c "  Relatorios em   : $REL" White
c ""
c "  Pressione ENTER para iniciar os testes ou Ctrl+C para cancelar." Gray
Read-Host | Out-Null

$INICIO = Get-Date

# Prompt de analise e testes
$PROMPT_API = @"
Voce e um analista de seguranca senior especializado em testes de API. Sua tarefa e analisar o codigo desta API e executar testes de seguranca ativos contra ela rodando em $URL_BASE.

ETAPA 1 - MAPEAMENTO DE ENDPOINTS:
Leia todo o codigo fonte nesta pasta. Identifique e liste todos os endpoints da API:
- Metodo HTTP (GET/POST/PUT/DELETE/PATCH)
- Caminho completo
- Parametros esperados (path, query, body)
- Autenticacao exigida (sim/nao/qual tipo)
- Funcao do endpoint

ETAPA 2 - TESTES DE AUTENTICACAO E AUTORIZACAO:
Para cada endpoint, execute via Invoke-WebRequest ou curl:
a) Acesso sem token/credencial - espera 401/403
b) Token invalido ou expirado - espera 401
c) Token de usuario com perfil insuficiente - espera 403
d) Manipulacao de JWT (se aplicavel): alterar payload sem re-assinar
Registre cada teste: requisicao enviada, resposta recebida, resultado (PASS/FAIL).

ETAPA 3 - TESTES DE IDOR (Insecure Direct Object Reference):
Identifique endpoints que recebem IDs de recursos (ex: /users/123, /orders/456).
Para cada um:
a) Acesse um recurso com ID de outro usuario
b) Tente IDs sequenciais: 1, 2, 3, 100, 999
c) Tente IDs negativos e zero: 0, -1
d) Tente IDs alfanumericos: abc, null, undefined
Registre respostas e dados expostos indevidamente.

ETAPA 4 - TESTES DE INJECAO:
Envie payloads maliciosos nos parametros de entrada:
a) SQL Injection: ' OR 1=1--, 1; DROP TABLE users--, ' UNION SELECT 1,2,3--
b) NoSQL Injection (se Node/MongoDB): {"$gt":""}, {"$where":"1==1"}
c) Command Injection: ; ls, | whoami, && dir
d) XSS em campos de texto: <script>alert(1)</script>, <img src=x onerror=alert(1)>
Registre qualquer resposta que indique vulnerabilidade (erro de banco, execucao, reflexao).

ETAPA 5 - TESTES DE HEADERS DE SEGURANCA:
Faca uma requisicao GET para a raiz e endpoints principais.
Verifique presenca e configuracao de:
- Strict-Transport-Security
- X-Content-Type-Options
- X-Frame-Options
- Content-Security-Policy
- X-XSS-Protection
- Access-Control-Allow-Origin (CORS - checar se aceita qualquer origem)
Registre headers ausentes ou mal configurados.

ETAPA 6 - TESTES DE RATE LIMITING:
Escolha um endpoint de autenticacao (login, token) e envie 20 requisicoes em sequencia rapida.
Verifique se ha bloqueio, delay ou erro 429.
Repita para endpoints criticos de negocio.

ETAPA 7 - EXPOSICAO INDEVIDA DE DADOS:
Verifique nas respostas dos endpoints:
- Campos sensiveis desnecessarios (senhas, hashes, tokens internos, dados de outros usuarios)
- Stack traces ou mensagens de erro detalhadas expostas ao cliente
- Endpoints de debug ou documentacao acessiveis em producao (/swagger, /api-docs, /graphql, /.env, /debug)

FORMATO DO RELATORIO:
Gere relatorio Markdown completo com:
1. SUMARIO: total de endpoints testados, achados por severidade (Critico/Alto/Medio/Baixo/Info)
2. ENDPOINTS MAPEADOS: tabela completa
3. ACHADOS: para cada vulnerabilidade - ID, endpoint, tipo, payload usado, resposta obtida, severidade, recomendacao
4. ENDPOINTS SEM VULNERABILIDADES: lista resumida
5. CONCLUSAO: avaliacao geral da superficie de ataque

Imprima apenas o relatorio Markdown, sem texto antes ou depois.
"@

c "" ; c "  [FASE 1] MAPEAMENTO E TESTES DE SEGURANCA DA API" Cyan
c "  -----------------------------------------------------------------------" DarkGray
c ""
c "  [>] Analisando e testando a API em $URL_BASE" White
c "      Saida: $REL\relatorio_api.md" DarkGray

$inicio    = Get-Date
$tmpPrompt = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpPrompt, $PROMPT_API, [System.Text.Encoding]::UTF8)

try {
    Push-Location $PASTA
    $resultado = Get-Content $tmpPrompt -Raw | claude -p --allowedTools "Bash,Read,Glob,Grep" | Out-String
    Pop-Location
    [System.IO.File]::WriteAllText("$REL\relatorio_api.md", $resultado, [System.Text.Encoding]::UTF8)
    $elapsed = [math]::Round(((Get-Date) - $inicio).TotalMinutes, 1)
    c "      OK em ${elapsed}min" Green
} catch {
    Pop-Location -ErrorAction SilentlyContinue
    c "      ERRO: $_" Red
} finally {
    Remove-Item $tmpPrompt -ErrorAction SilentlyContinue
}

# Encerrar aplicacao se foi iniciada pelo script
if ($iniciouApp -and $appProcess -and -not $appProcess.HasExited) {
    c ""
    c "  Encerrando a aplicacao iniciada pelo script..." DarkGray
    Stop-Process -Id $appProcess.Id -Force -ErrorAction SilentlyContinue
    c "  Aplicacao encerrada." DarkGray
}

$totalMin = [math]::Round(((Get-Date) - $INICIO).TotalMinutes, 1)

c ""
c "  =======================================================" DarkGray
c "  ANALISE DE API CONCLUIDA - ${totalMin}min" Green
c ""
c "  Relatorio gerado em:" White
c "    $REL\relatorio_api.md" Cyan
c ""
c "  AGORA E COM VOCE:" Cyan
c "  1. Revise os achados - valide cada teste executado" White
c "  2. Confirme falsos positivos antes de reportar" White
c "  3. Combine com o relatorio de analise estatica (analisar.ps1)" White
c ""
c "  Para abrir o relatorio:" DarkGray
c "    Invoke-Item '$REL\relatorio_api.md'" DarkGray
c ""
