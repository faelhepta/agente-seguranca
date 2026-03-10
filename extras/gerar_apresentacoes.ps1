# =============================================================================
#  GERAR APRESENTACOES - Coordenacao de Seguranca de TI
#  Uso: .\gerar_apresentacoes.ps1
#  Gera (ou regenera) as 2 apresentacoes HTML de um projeto ja analisado.
# =============================================================================

function c($msg, $cor = "White") { Write-Host $msg -ForegroundColor $cor }

Clear-Host
c ""
c "  =======================================================" Cyan
c "     GERADOR DE APRESENTACOES" Cyan
c "     Coordenacao de Seguranca de TI" Cyan
c "  =======================================================" Cyan
c ""
c "  Gera os 2 slides HTML a partir dos relatorios existentes:" Gray
c "    - apresentacao_vulnerabilidades.html" Gray
c "    - apresentacao_melhorias_roadmap.html" Gray
c ""

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    c "  ERRO: Claude Code nao encontrado." Red
    c "  Execute: npm install -g @anthropic-ai/claude-code" Yellow
    exit 1
}

c "  Informe o caminho completo da pasta do projeto:" White
c "  (a pasta que contem relatorios/ e apresentacoes/)" Gray
c ""
$PROJ = Read-Host "  Caminho"
$PROJ = $PROJ.Trim().Trim('"')

if (-not (Test-Path $PROJ -PathType Container)) {
    c "  ERRO: Pasta nao encontrada: $PROJ" Red
    exit 1
}

$REL   = Join-Path $PROJ "relatorios"
$APRES = Join-Path $PROJ "apresentacoes"

if (-not (Test-Path $REL)) {
    c "  ERRO: pasta relatorios/ nao encontrada em $PROJ" Red
    c "  Execute a analise completa primeiro com .\analisar.ps1" Yellow
    exit 1
}

$qtdRel = (Get-ChildItem $REL -Filter "*.md" -ErrorAction SilentlyContinue).Count
if ($qtdRel -eq 0) {
    c "  ERRO: nenhum relatorio .md encontrado em $REL" Red
    c "  Execute a analise completa primeiro com .\analisar.ps1" Yellow
    exit 1
}

c ""
c "  Projeto   : $PROJ" White
c "  Relatorios: $qtdRel arquivo(s) encontrado(s)" Green
c ""
c "  Pressione ENTER para gerar as apresentacoes ou Ctrl+C para cancelar." Gray
Read-Host | Out-Null

New-Item -ItemType Directory -Force -Path $APRES | Out-Null

$INICIO = Get-Date

function Run-Claude {
    param([string]$Descricao, [string]$Prompt, [string]$Saida)
    c ""
    c "  [>] $Descricao" White
    c "      Saida: $Saida" DarkGray

    $inicio    = Get-Date
    $tmpPrompt = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tmpPrompt, $Prompt, [System.Text.Encoding]::UTF8)

    try {
        Push-Location $PROJ
        $resultado = Get-Content $tmpPrompt -Raw | claude -p | Out-String
        Pop-Location
        [System.IO.File]::WriteAllText($Saida, $resultado, [System.Text.Encoding]::UTF8)
        $elapsed = [math]::Round(((Get-Date) - $inicio).TotalMinutes, 1)
        c "      OK em ${elapsed}min" Green
    } catch {
        Pop-Location -ErrorAction SilentlyContinue
        c "      ERRO: $_" Red
    } finally {
        Remove-Item $tmpPrompt -ErrorAction SilentlyContinue
    }
}

$P_VULNS = @"
Leia todos os relatorios na pasta relatorios/. Com base nos achados REAIS, gere e imprima diretamente o HTML completo de uma apresentacao de slides para a fabrica. Nao salve arquivos - apenas imprima o HTML no output.
Visual: fundo escuro (#0a0e1a), navegacao por setas, barra de progresso, CSS inline, sem dependencias externas, sem emojis.
Slides: capa com badge de parecer, sumario executivo com contadores reais, grafico de barras CSS por severidade, matriz de risco CSS, um slide por achado critico/alto, tabela de medios, tabela de baixos/info, proximos passos.
Paleta: critico=#ef4444, alto=#f97316, medio=#f59e0b, baixo=#3b82f6, info=#00d4a1.
Use APENAS dados reais dos relatorios. Nao invente vulnerabilidades. Imprima apenas o HTML, sem texto antes ou depois.
"@

$P_ROADMAP = @"
Leia todos os relatorios na pasta relatorios/. Com base nas recomendacoes REAIS, gere e imprima diretamente o HTML completo de uma apresentacao de melhorias para a fabrica. Nao salve arquivos - apenas imprima o HTML no output.
Tom: CONSTRUTIVO. Visual: tons de verde e azul, fundo escuro, CSS inline, sem dependencias externas, sem emojis.
Slides: capa Plano de Melhorias, visao geral dos pilares, roadmap 4 fases (antes-deploy/vermelho, 30dias/amarelo, 90dias/azul, 6meses/verde), solucao por achado critico/alto, melhorias medias, Gantt CSS, metricas de sucesso.
Use APENAS dados reais. Imprima apenas o HTML, sem texto antes ou depois.
"@

Run-Claude "Apresentacao de Vulnerabilidades (HTML)"    $P_VULNS   "$APRES\apresentacao_vulnerabilidades.html"
Run-Claude "Apresentacao de Melhorias e Roadmap (HTML)" $P_ROADMAP "$APRES\apresentacao_melhorias_roadmap.html"

$totalMin = [math]::Round(((Get-Date) - $INICIO).TotalMinutes, 1)
c ""
c "  =======================================================" DarkGray
c "  CONCLUIDO - ${totalMin}min" Green
c ""
c "  Arquivos gerados em: $APRES" White
c "    - apresentacao_vulnerabilidades.html" White
c "    - apresentacao_melhorias_roadmap.html" White
c ""
c "  Para abrir:" Cyan
c "    Invoke-Item '$APRES\apresentacao_vulnerabilidades.html'" DarkGray
c "    Invoke-Item '$APRES\apresentacao_melhorias_roadmap.html'" DarkGray
c ""
