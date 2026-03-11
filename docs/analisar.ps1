# =============================================================================
#  ANALISADOR DE SEGURANCA - Coordenacao de Seguranca de TI
#  Uso: .\analisar.ps1
# =============================================================================

function c($msg, $cor = "White") { Write-Host $msg -ForegroundColor $cor }

Clear-Host
c ""
c "  =======================================================" Cyan
c "     ANALISADOR DE SEGURANCA" Cyan
c "     Coordenacao de Seguranca de TI" Cyan
c "  =======================================================" Cyan
c ""
c "  Este script analisa o projeto e gera:" Gray
c "    relatorios/   - 5 relatorios Markdown" Gray
c "    apresentacoes/ - 2 slides HTML para a fabrica" Gray
c ""

# Verificar Claude Code
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    c "  ERRO: Claude Code nao encontrado." Red
    c "  Execute: npm install -g @anthropic-ai/claude-code" Yellow
    exit 1
}

# Pedir caminho da pasta
c "  Informe o caminho completo da pasta do projeto:" White
c "  (ex: C:\projetos\SistemaRH)" Gray
c ""
$PROJ = Read-Host "  Caminho"
$PROJ = $PROJ.Trim().Trim('"')

if (-not (Test-Path $PROJ -PathType Container)) {
    c ""
    c "  ERRO: Pasta nao encontrada: $PROJ" Red
    exit 1
}

# Detectar subpastas com conteudo
function Test-HasFiles([string]$p) {
    if (-not (Test-Path $p)) { return $false }
    return ($null -ne (Get-ChildItem $p -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1))
}

$CODIGO = Join-Path $PROJ "codigo"
$DOCS   = Join-Path $PROJ "documentacao"
$INFRA  = Join-Path $PROJ "infraestrutura"
$REL    = Join-Path $PROJ "relatorios"
$APRES  = Join-Path $PROJ "apresentacoes"

$temCodigo = Test-HasFiles $CODIGO
$temDocs   = Test-HasFiles $DOCS
$temInfra  = Test-HasFiles $INFRA

c ""
c "  Projeto : $PROJ" White
c ""
c "  Estrutura encontrada:" Cyan

if ($temCodigo) { c "    [OK] codigo/         - analise sera executada" Green }
else            { c "    [--] codigo/         - vazia ou ausente (OBRIGATORIO)" Red }

if ($temDocs)   { c "    [OK] documentacao/   - analise sera executada" Green }
else            { c "    [--] documentacao/   - vazia ou ausente (fase sera pulada)" DarkYellow }

if ($temInfra)  { c "    [OK] infraestrutura/ - analise sera executada" Green }
else            { c "    [--] infraestrutura/ - vazia ou ausente (fase sera pulada)" DarkYellow }

c ""

if (-not $temCodigo) {
    c "  ERRO: pasta codigo/ esta vazia ou nao existe." Red
    c "  Coloque o codigo fonte em: $CODIGO" Yellow
    exit 1
}

c "  Pressione ENTER para iniciar ou Ctrl+C para cancelar." Gray
Read-Host | Out-Null

# Helpers
$ERROS         = @()
$FASES_PULADAS = @()
$TEMPOS        = @()
$INICIO_TOTAL  = Get-Date

New-Item -ItemType Directory -Force -Path $REL   | Out-Null
New-Item -ItemType Directory -Force -Path $APRES | Out-Null

function Run-Claude {
    param(
        [string]$Descricao,
        [string]$Diretorio,
        [string]$Prompt,
        [string]$Saida
    )
    c ""
    c "  [>] $Descricao" White
    c "      Dir  : $Diretorio" DarkGray
    c "      Saida: $Saida" DarkGray

    $inicio    = Get-Date
    $tmpPrompt = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tmpPrompt, $Prompt, [System.Text.Encoding]::UTF8)

    try {
        Push-Location $Diretorio
        $resultado = Get-Content $tmpPrompt -Raw | claude -p | Out-String
        Pop-Location
        [System.IO.File]::WriteAllText($Saida, $resultado, [System.Text.Encoding]::UTF8)
        $elapsed = [math]::Round(((Get-Date) - $inicio).TotalMinutes, 1)
        c "      OK em ${elapsed}min" Green
        $script:TEMPOS += "$Descricao|${elapsed}min"
    } catch {
        Pop-Location -ErrorAction SilentlyContinue
        c "      ERRO: $_" Red
        $script:ERROS += $Descricao
    } finally {
        Remove-Item $tmpPrompt -ErrorAction SilentlyContinue
    }
}

# Prompts
$P_CODIGO = @"
Voce e um analista de seguranca senior. Analise todo o codigo fonte neste diretorio.

PARTE 1 - OWASP TOP 10:
Identifique vulnerabilidades. Para cada achado: arquivo e linha, tipo (CWE), severidade (Critico/Alto/Medio/Baixo), descricao tecnica, recomendacao com exemplo de codigo seguro.
Foque em: Injection, autenticacao quebrada, exposicao de dados, controle de acesso, configuracoes inseguras, componentes vulneraveis, logging insuficiente.

PARTE 2 - AUTENTICACAO E AUTORIZACAO:
JWT/OAuth/sessoes, senhas, RBAC, credenciais hardcoded, brute force, invalidacao de sessao.

PARTE 3 - DEPENDENCIAS E CVEs:
Liste dependencias (package.json, requirements.txt, pom.xml, go.mod etc). Para cada: versao, CVEs criticos/altos, recomendacao.

PARTE 4 - SECRETS:
Chaves de API, tokens, passwords hardcoded, .env commitados, chaves privadas, PII em logs. Arquivo e linha.

PARTE 5 - SEGURANCA DE API:
Por endpoint: autenticacao, autorizacao, validacao, IDOR, headers, rate limiting. Tabela de endpoints.

Gere relatorio Markdown completo com sumario de contagem por severidade ao final.
"@

$P_DOCS = @"
Voce e um analista de seguranca senior. Analise toda a documentacao tecnica neste diretorio.

PARTE 1 - ARQUITETURA E FLUXO DE DADOS:
Fronteiras de confianca, dados sensiveis, fluxos de autenticacao, integracoes com terceiros, pontos de armazenamento. Aponte lacunas e riscos.

PARTE 2 - CONFORMIDADE LGPD:
Dados pessoais coletados, base legal, retencao, direitos dos titulares, DPA, notificacao de incidentes. Gaps de aderencia.

PARTE 3 - REQUISITOS DE SEGURANCA:
Requisitos existentes vs atendidos, ausentes mas necessarios, classificacao de dados, resposta a incidentes.

Gere relatorio Markdown completo com sumario ao final.
"@

$P_INFRA = @"
Voce e um analista de seguranca senior. Analise todo o material de infraestrutura neste diretorio.

PARTE 1 - REDE E EXPOSICAO:
Segmentacao, exposicao para internet, banco de dados acessivel externamente, WAF, comunicacao criptografada, monitoramento.

PARTE 2 - IAM:
Menor privilegio, acesso administrativo, MFA, service accounts, rotacao de chaves.

PARTE 3 - IaC (Terraform/CloudFormation/Pulumi):
Security groups abertos, buckets publicos, bancos sem criptografia, secrets em IaC, imagens desatualizadas.

PARTE 4 - CONTAINERS/KUBERNETES:
Root containers, imagens vulneraveis, secrets em variaveis plaintext, pod security policies.

PARTE 5 - MONITORAMENTO E DR:
Logs, alertas, retencao, SIEM, backup, RTO/RPO.

Gere relatorio Markdown completo com sumario ao final.
"@

$P_THREAT_BASE = @"
Voce e um especialista em threat modeling. Com base nos relatorios disponiveis em relatorios/, realize modelagem de ameacas STRIDE.

Para cada componente critico: Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege.
Para cada ameaca: ID (STR-001...), componente, categoria STRIDE, cenario de ataque, severidade, controle mitigador, status (implementado/parcial/ausente).
Tabela resumo ao final por severidade. Relatorio Markdown completo.
"@

$P_RELATORIO_BASE = @"
Voce e um coordenador de seguranca senior. Com base nos relatorios disponiveis em relatorios/, gere RELATORIO EXECUTIVO CONSOLIDADO em Markdown.

1. SUMARIO EXECUTIVO: resumo nao-tecnico em 5 linhas, tabela de achados por severidade
2. ACHADOS CRITICOS E ALTOS: ID, titulo, componente, descricao, recomendacao
3. ACHADOS MEDIOS: tabela resumida
4. ACHADOS BAIXOS/INFO: tabela compacta
5. MATRIZ DE RISCO: grid probabilidade x impacto
6. PLANO DE CORRECAO: Prioridade 1 (antes deploy), Prioridade 2 (30 dias), Prioridade 3 (proximo ciclo)
7. PARECER FINAL: APROVADO / APROVADO COM RESSALVAS / REPROVADO + justificativa
"@

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

# Execucao

c "" ; c "  [FASE 1] ANALISE DE CODIGO" Cyan
c "  -----------------------------------------------------------------------" DarkGray
Run-Claude "Analise de Codigo (OWASP + Auth + Deps + Secrets + API)" $CODIGO $P_CODIGO "$REL\01_analise_codigo.md"

c "" ; c "  [FASE 2] ANALISE DE DOCUMENTACAO" Cyan
c "  -----------------------------------------------------------------------" DarkGray
if ($temDocs) {
    Run-Claude "Analise de Documentacao (Arquitetura + LGPD + Requisitos)" $DOCS $P_DOCS "$REL\02_analise_documentacao.md"
} else {
    c "  PULADO: documentacao/ vazia." DarkYellow
    c "          Para incluir: adicione os docs e rode o script novamente." DarkGray
    $FASES_PULADAS += "Fase 2 - Documentacao (pasta vazia)"
}

c "" ; c "  [FASE 3] ANALISE DE INFRAESTRUTURA" Cyan
c "  -----------------------------------------------------------------------" DarkGray
if ($temInfra) {
    Run-Claude "Analise de Infraestrutura (Rede + IAM + IaC + Containers)" $INFRA $P_INFRA "$REL\03_analise_infraestrutura.md"
} else {
    c "  PULADO: infraestrutura/ vazia." DarkYellow
    c "          Para incluir: adicione os arquivos e rode o script novamente." DarkGray
    $FASES_PULADAS += "Fase 3 - Infraestrutura (pasta vazia)"
}

c "" ; c "  [FASE 4] THREAT MODELING" Cyan
c "  -----------------------------------------------------------------------" DarkGray
$P_THREAT = $P_THREAT_BASE
if ($FASES_PULADAS.Count -gt 0) {
    $aviso = "`n`nOBSERVACAO: as seguintes fases nao foram analisadas por falta de artefatos: " + ($FASES_PULADAS -join "; ") + ". Realize o threat modeling com base apenas nos relatorios disponiveis e registre as lacunas no relatorio."
    $P_THREAT += $aviso
}
Run-Claude "Modelagem de Ameacas STRIDE" $PROJ $P_THREAT "$REL\04_threat_modeling.md"

c "" ; c "  [FASE 5] RELATORIO EXECUTIVO" Cyan
c "  -----------------------------------------------------------------------" DarkGray
$P_RELATORIO = $P_RELATORIO_BASE
if ($FASES_PULADAS.Count -gt 0) {
    $aviso = "`n`nOBSERVACAO: analise parcial. As seguintes fases nao foram executadas por falta de artefatos: " + ($FASES_PULADAS -join "; ") + ". Indique claramente no relatorio quais dimensoes nao foram analisadas e o impacto na abrangencia do parecer."
    $P_RELATORIO += $aviso
}
Run-Claude "Relatorio Executivo Consolidado + Parecer" $PROJ $P_RELATORIO "$REL\00_RELATORIO_EXECUTIVO.md"

c "" ; c "  [FASES 6-7] APRESENTACOES PARA A FABRICA" Cyan
c "  -----------------------------------------------------------------------" DarkGray
Run-Claude "Apresentacao de Vulnerabilidades (HTML)"      $PROJ $P_VULNS    "$APRES\apresentacao_vulnerabilidades.html"
Run-Claude "Apresentacao de Melhorias e Roadmap (HTML)"   $PROJ $P_ROADMAP  "$APRES\apresentacao_melhorias_roadmap.html"

# Resumo Final
$totalMin = [math]::Round(((Get-Date) - $INICIO_TOTAL).TotalMinutes, 1)

c ""
c "  =======================================================" DarkGray
c ""

if ($ERROS.Count -eq 0) {
    c "  ANALISE CONCLUIDA - ${totalMin}min total" Green
} else {
    c "  ANALISE CONCLUIDA COM ERROS - ${totalMin}min total" Yellow
    c ""
    c "  Fases com erro:" Red
    $ERROS | ForEach-Object { c "    - $_" Red }
}

if ($TEMPOS.Count -gt 0) {
    c ""
    c "  Tempo por fase:" DarkGray
    $TEMPOS | ForEach-Object {
        $partes = $_ -split '\|'
        Write-Host ("    {0,-52} {1}" -f $partes[0], $partes[1]) -ForegroundColor DarkGray
    }
}

if ($FASES_PULADAS.Count -gt 0) {
    c ""
    c "  Fases puladas (pasta vazia):" Yellow
    $FASES_PULADAS | ForEach-Object { c "    - $_" DarkGray }
}

c ""
c "  AGORA E COM VOCE - revisao humana obrigatoria:" Cyan
c "  1. Revise os relatorios em  : $REL" White
c "  2. Valide os achados (pode haver falsos positivos)" White
c "  3. Preencha o checklist de seguranca" White
c "  4. Assine o parecer com o coordenador" White
c "  5. Apresentacoes em         : $APRES" White
c ""
c "  =======================================================" DarkGray
c ""
