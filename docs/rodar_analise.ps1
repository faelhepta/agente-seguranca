#Requires -Version 5.1
<#
.SYNOPSIS
    Automacao completa da analise de seguranca de um projeto.

.DESCRIPTION
    Executa todos os prompts do Runbook automaticamente usando o Claude Code
    em modo nao-interativo (claude -p). Gera todos os relatorios na pasta
    relatorios/ do projeto e, ao final, gera as apresentacoes para a fabrica.

    O analista ainda precisa:
      - Revisar os relatorios gerados
      - Preencher o CHECKLIST_SEGURANCA_PROJETOS.md
      - Assinar o parecer final

.PARAMETER Projeto
    Nome da pasta do projeto em ~/Documents/projetos/

.PARAMETER Fase
    Qual fase executar. Padrao: "todas"
    Opcoes: todas | codigo | docs | infra | threat | relatorio | apresentacoes | reanalise

.PARAMETER Versao
    Versao da reanalise (ex: v1, v2). Usado apenas com -Fase reanalise.

.PARAMETER DryRun
    Exibe o que seria executado sem rodar de fato.

.EXAMPLE
    .\rodar_analise.ps1 -Projeto "SistemaRH"
    .\rodar_analise.ps1 -Projeto "SistemaRH" -Fase codigo
    .\rodar_analise.ps1 -Projeto "SistemaRH" -Fase reanalise -Versao v1
    .\rodar_analise.ps1 -Projeto "SistemaRH" -DryRun
#>

param(
    [Parameter(Mandatory)]
    [string]$Projeto,

    [ValidateSet("todas","codigo","docs","infra","threat","relatorio","apresentacoes","reanalise")]
    [string]$Fase = "todas",

    [string]$Versao = "v1",

    [switch]$DryRun
)

# ─────────────────────────────────────────────
#  CONFIGURACAO
# ─────────────────────────────────────────────
$BASE          = "$env:USERPROFILE\Documents\projetos"
$PROJ          = Join-Path $BASE $Projeto
$REL           = Join-Path $PROJ "relatorios"
$APRES         = Join-Path $PROJ "apresentacoes"
$CODIGO        = Join-Path $PROJ "codigo"
$DOCS          = Join-Path $PROJ "documentacao"
$INFRA         = Join-Path $PROJ "infraestrutura"
$REANALISE_DIR = Join-Path $PROJ "reanalise\$Versao\relatorios"

$erros  = @()
$tempos = @{}
$inicio_total = Get-Date

# ─────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────
function Write-Header {
    $modo = if ($DryRun) { " [DRY RUN]" } else { "" }
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║   AUTOMACAO DE ANALISE DE SEGURANCA$($modo.PadRight(20))║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Projeto : $Projeto" -ForegroundColor White
    Write-Host "  Fase    : $Fase" -ForegroundColor White
    Write-Host "  Inicio  : $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -ForegroundColor White
    if ($Fase -eq "reanalise") { Write-Host "  Versao  : $Versao" -ForegroundColor White }
    Write-Host ""
}

function Write-PhaseHeader([string]$titulo, [string]$cor = "Cyan") {
    Write-Host ""
    Write-Host "  ── $titulo " -ForegroundColor $cor -NoNewline
    Write-Host ("─" * (55 - $titulo.Length)) -ForegroundColor DarkGray
}

function Run-Claude {
    param(
        [string]$Descricao,
        [string]$Diretorio,
        [string]$Prompt,
        [string]$Saida
    )

    Write-Host "  [>] $Descricao" -ForegroundColor White
    Write-Host "      Dir  : $Diretorio" -ForegroundColor DarkGray
    Write-Host "      Saida: $Saida" -ForegroundColor DarkGray

    if ($DryRun) {
        Write-Host "      [DRY RUN] claude -p [$(($Prompt -replace '\s+', ' ').Substring(0, [Math]::Min(80, ($Prompt -replace '\s+', ' ').Length)))...]" -ForegroundColor Yellow
        return $true
    }

    $inicio = Get-Date
    Push-Location $Diretorio
    try {
        $saida_dir = Split-Path $Saida -Parent
        if (-not (Test-Path $saida_dir)) { New-Item -ItemType Directory -Path $saida_dir -Force | Out-Null }

        claude -p $Prompt | Out-File -FilePath $Saida -Encoding UTF8 -Force

        $elapsed = [math]::Round(((Get-Date) - $inicio).TotalMinutes, 1)
        $tempos[$Descricao] = $elapsed
        Write-Host "      OK em ${elapsed}min -> $Saida" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "      ERRO: $_" -ForegroundColor Red
        $erros += $Descricao
        return $false
    } finally {
        Pop-Location
    }
}

# ─────────────────────────────────────────────
#  VALIDACOES INICIAIS
# ─────────────────────────────────────────────
Write-Header

if (-not (Test-Path $PROJ)) {
    Write-Host "  ERRO: Projeto nao encontrado em: $PROJ" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Projetos disponiveis:" -ForegroundColor Yellow
    if (Test-Path $BASE) {
        Get-ChildItem $BASE -Directory | ForEach-Object { Write-Host "    - $($_.Name)" -ForegroundColor White }
    }
    exit 1
}

try {
    $claudeVer = claude --version 2>$null
    if (-not $claudeVer) { throw }
    Write-Host "  Claude Code: $claudeVer" -ForegroundColor DarkGray
} catch {
    Write-Host "  ERRO: Claude Code nao encontrado. Execute: npm install -g @anthropic-ai/claude-code" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $REL)) { New-Item -ItemType Directory -Path $REL -Force | Out-Null }
if (-not (Test-Path $APRES)) { New-Item -ItemType Directory -Path $APRES -Force | Out-Null }

# ─────────────────────────────────────────────
#  DEFINICAO DOS PROMPTS
# ─────────────────────────────────────────────

$PROMPT_CODIGO = @"
Voce e um analista de seguranca senior. Analise todo o codigo fonte neste diretorio.

PARTE 1 — ANALISE GERAL OWASP TOP 10:
Identifique vulnerabilidades seguindo o OWASP Top 10. Para cada achado informe:
- Arquivo e linha exata
- Tipo de vulnerabilidade (CWE se possivel)
- Severidade (Critico/Alto/Medio/Baixo)
- Descricao tecnica do problema
- Recomendacao de correcao com exemplo de codigo seguro
Foque em: SQL/Command/LDAP Injection, autenticacao quebrada, exposicao de dados, controle de acesso, configuracoes inseguras, componentes vulneraveis, logging insuficiente.

PARTE 2 — AUTENTICACAO E AUTORIZACAO:
Analise os mecanismos de autenticacao: JWT/OAuth/sessoes, armazenamento de senhas (hash utilizado), controle de acesso por role/perfil (RBAC), credenciais hardcoded, protecao contra brute force, invalidacao de sessao no logout.

PARTE 3 — DEPENDENCIAS E CVEs:
Liste todas as dependencias (package.json, requirements.txt, pom.xml, go.mod, Gemfile, etc.). Para cada dependencia informe: versao utilizada, CVEs criticos ou altos conhecidos, se esta ativa e mantida, recomendacao de atualizacao.

PARTE 4 — SECRETS E DADOS SENSIVEIS:
Varra o codigo buscando: chaves de API/tokens/passwords hardcoded, conexoes de banco com credenciais no codigo, arquivos .env commitados, chaves privadas ou certificados, PII exposta em logs ou respostas de API. Liste cada ocorrencia com arquivo e linha.

PARTE 5 — SEGURANCA DE API:
Para cada endpoint de API: autenticacao exigida, autorizacao por role, validacao de inputs, risco de IDOR, headers de seguranca (CORS, CSP, HSTS), rate limiting. Gere tabela de endpoints com status de seguranca.

Gere um relatorio Markdown completo e estruturado com todos os achados agrupados por parte. Inclua um sumario ao final com contagem por severidade.
"@

$PROMPT_DOCS = @"
Voce e um analista de seguranca senior. Analise toda a documentacao tecnica neste diretorio.

PARTE 1 — ARQUITETURA E FLUXO DE DADOS:
Com base nos documentos, identifique e avalie: fronteiras de confianca e pontos de entrada externos, dados sensiveis que trafegam pelo sistema (PII, financeiro, credenciais), fluxos de autenticacao e autorizacao, integracoes com terceiros e dados compartilhados, pontos de armazenamento de dados sensiveis.
Verifique coerencia com boas praticas e aponte lacunas ou riscos nos fluxos.

PARTE 2 — CONFORMIDADE LGPD:
Avalie: quais dados pessoais sao coletados e processados, se ha base legal definida para cada tipo, politica de retencao e descarte, direitos dos titulares (acesso, exclusao, portabilidade), DPA com terceiros, processo de notificacao de incidentes. Gere relatorio de aderencia com gaps.

PARTE 3 — REQUISITOS DE SEGURANCA:
Identifique: requisitos de seguranca existentes e se estao sendo atendidos, requisitos ausentes mas necessarios, classificacao de dados realizada (publico/interno/confidencial/restrito), procedimentos de resposta a incidentes documentados.
Aponte gaps criticos que precisam ser endereados antes do go-live.

Gere um relatorio Markdown completo com os achados das 3 partes. Inclua sumario ao final.
"@

$PROMPT_INFRA = @"
Voce e um analista de seguranca senior. Analise todo o material de infraestrutura neste diretorio (diagramas, arquivos IaC, configuracoes).

PARTE 1 — REDE E EXPOSICAO:
Avalie: segmentacao de rede (DMZ, zona de dados, zona de aplicacao), exposicao de servicos para a internet, banco de dados acessivel diretamente da internet, presenca de WAF/balanceador/CDN, comunicacao interna criptografada, monitoramento e logging previstos. Gere relatorio por componente.

PARTE 2 — IAM E CONTROLE DE ACESSO:
Avalie: principio do menor privilegio nas roles, acesso administrativo (SSH/RDP/console) restrito e monitorado, MFA exigido para privilegiados, service accounts com permissoes excessivas, rotacao de chaves prevista.

PARTE 3 — INFRASTRUCTURE AS CODE (se existir Terraform, CloudFormation, Pulumi, etc.):
Verifique: security groups com regras abertas (0.0.0.0/0), buckets S3/blobs publicos, bancos sem criptografia em repouso, instancias sem monitoramento, secrets nos arquivos IaC, AMIs/imagens desatualizadas. Use CIS Benchmark como referencia.

PARTE 4 — CONTAINERS E KUBERNETES (se existir Docker, k8s):
Verifique: containers rodando como root, imagens base vulneraveis, secrets em variaveis de ambiente plaintext, politicas de seguranca de pods, registry sem scan, privilegios excessivos.

PARTE 5 — MONITORAMENTO E CONTINUIDADE:
Avalie: logs de infra habilitados, alertas configurados, retencao de logs (minimo 90 dias), SIEM previsto, estrategia de backup e DR, RTO/RPO definidos.

Gere relatorio Markdown completo por parte. Inclua sumario ao final.
"@

$PROMPT_THREAT = @"
Voce e um especialista em threat modeling. Com base em todos os relatorios ja gerados nas pastas relatorios/ (01_analise_codigo.md, 02_analise_documentacao.md, 03_analise_infraestrutura.md), realize uma modelagem de ameacas completa usando o framework STRIDE.

Para cada componente critico do sistema, analise:
- Spoofing: como um atacante pode falsificar identidade de usuario ou servico?
- Tampering: como dados podem ser adulterados em transito ou em repouso?
- Repudiation: existem acoes criticas sem rastro de auditoria?
- Information Disclosure: onde dados sensiveis podem ser expostos indevidamente?
- Denial of Service: quais componentes sao vulneraveis a indisponibilidade?
- Elevation of Privilege: como um usuario pode obter mais permissoes do que deveria?

Para cada ameaca identificada informe:
- ID da ameaca (ex: STR-001)
- Componente afetado
- Categoria STRIDE
- Descricao do cenario de ataque
- Severidade (Critico/Alto/Medio/Baixo)
- Controle mitigador recomendado
- Status do controle (implementado / parcial / ausente)

Ao final, gere uma tabela resumo com todas as ameacas priorizadas por severidade.
Gere relatorio Markdown completo e estruturado.
"@

$PROMPT_RELATORIO = @"
Voce e um coordenador de seguranca senior. Com base em todos os relatorios gerados (01_analise_codigo.md, 02_analise_documentacao.md, 03_analise_infraestrutura.md e 04_threat_modeling.md na pasta relatorios/), gere um RELATORIO EXECUTIVO CONSOLIDADO em Markdown.

Estrutura obrigatoria:

# 1. SUMARIO EXECUTIVO
- Nome do projeto e data
- Resumo em 5 linhas para gestao nao tecnica
- Tabela: total de achados por severidade (Critico / Alto / Medio / Baixo / Info)

# 2. ACHADOS CRITICOS E ALTOS — detalhamento completo
Para cada: ID, titulo, componente afetado, descricao tecnica resumida, recomendacao de correcao.

# 3. ACHADOS MEDIOS — listagem resumida
Tabela: ID, titulo, componente, recomendacao resumida.

# 4. ACHADOS BAIXOS E INFO — listagem compacta

# 5. MATRIZ DE RISCO
Grid probabilidade x impacto com os achados posicionados.

# 6. PLANO DE CORRECAO RECOMENDADO
- Prioridade 1 — antes do deploy: achados criticos e altos
- Prioridade 2 — ate 30 dias: achados medios
- Prioridade 3 — proximo ciclo: achados baixos e melhorias estrategicas

# 7. PARECER FINAL
- APROVADO / APROVADO COM RESSALVAS / REPROVADO
- Justificativa tecnica objetiva
- Condicoes para aprovacao (se reprovado)

Seja objetivo, tecnicamente preciso e claro para leitores nao-tecnicos no sumario.
"@

$PROMPT_APRES_VULNS = @"
Leia todos os relatorios na pasta relatorios/ (arquivos 00 ao 04).

Com base nos achados REAIS encontrados, gere um arquivo HTML completo de apresentacao de slides profissional para entregar a fabrica de software. Salve como apresentacoes/apresentacao_vulnerabilidades.html.

Visual: fundo escuro (#0a0e1a), navegacao por setas do teclado, barra de progresso, contador de slides. CSS totalmente inline, sem dependencias externas. Sem emojis — use simbolos unicode.

Slides obrigatorios:
1. CAPA: titulo "Relatorio de Vulnerabilidades — [nome do projeto]", data, badge colorido com o parecer (verde=aprovado, amarelo=ressalvas, vermelho=reprovado)
2. SUMARIO EXECUTIVO: resumo nao-tecnico, 4 cards com contadores reais de achados por severidade
3. DISTRIBUICAO: grafico de barras CSS com achados por severidade e por categoria
4. MATRIZ DE RISCO: grid probabilidade x impacto com achados posicionados (CSS puro)
5. UM SLIDE POR ACHADO CRITICO E ALTO: ID, badge de severidade, componente afetado, descricao tecnica, impacto potencial, evidencia (arquivo:linha), CWE/OWASP
6. TABELA DE ACHADOS MEDIOS
7. TABELA COMPACTA DE ACHADOS BAIXOS/INFO
8. PROXIMOS PASSOS: 3 acoes imediatas requeridas

Paleta: critico=#ef4444, alto=#f97316, medio=#f59e0b, baixo=#3b82f6, info=#00d4a1.
Use APENAS dados reais dos relatorios. Nao invente vulnerabilidades.
"@

$PROMPT_APRES_ROADMAP = @"
Leia todos os relatorios na pasta relatorios/ (arquivos 00 ao 04).

Com base nas recomendacoes REAIS encontradas, gere um arquivo HTML completo de apresentacao de slides orientada a solucoes para a fabrica de software. Salve como apresentacoes/apresentacao_melhorias_roadmap.html.

Tom: CONSTRUTIVO — mostrar o caminho para corrigir, nao apenas apontar erros.
Visual: tons de verde e azul sobre fundo escuro. CSS inline, sem dependencias. Sem emojis — use unicode.

Slides obrigatorios:
1. CAPA: "Plano de Melhorias e Roadmap de Seguranca — [projeto]", tag "Orientado a Solucoes"
2. VISAO GERAL: total de melhorias, 3 pilares (Codigo Seguro / Infraestrutura / Processos)
3. COMO LER: explicacao das 4 fases do roadmap (Fase1=antes deploy/vermelho, Fase2=30dias/amarelo, Fase3=90dias/azul, Fase4=6meses/verde)
4. UM SLIDE DE SOLUCAO POR ACHADO CRITICO/ALTO: passo a passo de correcao, exemplo de codigo/config segura, esforco estimado, fase do roadmap, responsavel sugerido
5. TABELA DE MELHORIAS MEDIAS: ID, acao, esforco, responsavel
6. EVOLUCOES ESTRATEGICAS: lista de melhorias de longo prazo com beneficio e esforco P/M/G
7. ROADMAP VISUAL: timeline horizontal tipo Gantt em CSS com as 4 fases e itens de cada fase
8. METRICAS DE SUCESSO: indicadores para a fabrica acompanhar pos-correcao
9. BOAS PRATICAS PARA PROXIMOS PROJETOS: 5-7 praticas desde o inicio
10. COMPROMISSO CONJUNTO: responsabilidades fabrica x seguranca, proxima data de revisao

Use APENAS dados reais dos relatorios. Nao invente melhorias.
"@

$PROMPT_RA01 = @"
Leia o relatorio executivo original em relatorios/00_RELATORIO_EXECUTIVO.md e os relatorios de fase em relatorios/01_analise_codigo.md e relatorios/03_analise_infraestrutura.md.
Em seguida, analise o codigo e infra corrigidos na pasta atual e as evidencias em reanalise/$Versao/evidencias/.

Para cada achado CRITICO e ALTO do relatorio original:
1. Localize o arquivo/componente que continha o problema
2. Verifique se a correcao foi implementada corretamente
3. Avalie se a correcao e tecnicamente adequada (nao e apenas patch superficial)
4. Verifique se a correcao introduziu novos problemas na mesma area
5. Classifique: CORRIGIDO | PARCIALMENTE CORRIGIDO | NAO CORRIGIDO | CORRECAO INADEQUADA | NAO VERIFICAVEL | NOVO ACHADO

Para cada achado gere um bloco com: ID original, titulo, o que foi encontrado atualmente, STATUS, justificativa tecnica.
Se NOVO ACHADO: descricao completa do novo problema.
Ao final, tabela resumo de todos os criticos e altos com seus status.
Gere relatorio Markdown completo.
"@

$PROMPT_RA02 = @"
Com base no relatorio original em relatorios/00_RELATORIO_EXECUTIVO.md, identifique todos os achados MEDIOS.
Para cada achado medio: verifique se a correcao foi implementada, verifique se ainda esta dentro do prazo de 30 dias acordado, classifique com o mesmo sistema de status.
Achados medios com prazo vencido e nao corrigidos: status VENCIDO NAO CORRIGIDO.
Gere tabela: ID, titulo, prazo acordado, status atual, observacao.
Gere relatorio Markdown completo.
"@

$PROMPT_RA03 = @"
Com base nas evidencias em reanalise/$Versao/evidencias/ (diffs e commits), identifique todos os arquivos e componentes modificados.
Para cada area modificada, faca analise de seguranca focada:
- As mudancas introduziram novos vetores de ataque?
- Novas dependencias foram adicionadas? Verificar CVEs.
- Foram feitas alteracoes de permissoes, autenticacao ou autorizacao?
- Novos endpoints ou rotas foram criados?
- Configuracoes de infra foram alteradas alem do necessario?
Tambem verifique: novos hardcoded secrets, novos arquivos .env no repositorio, mudancas de escopo alem das correcoes acordadas.
Para cada novo achado: ID (NEW-001...), arquivo/linha, descricao, severidade, como surgiu.
Se nenhum novo achado: declare explicitamente "Nenhum novo achado identificado nas areas modificadas."
Gere relatorio Markdown completo.
"@

$PROMPT_RA00 = @"
Com base nos relatorios RA_01, RA_02 e RA_03 em reanalise/$Versao/relatorios/, gere o RELATORIO CONSOLIDADO DE REANALISE $Versao.

Estrutura:
# 1. CABECALHO: projeto, versao da reanalise, datas, analista
# 2. RESUMO: total verificado, tabela de contagem por status (Corrigido/Parc.Corrigido/NaoCorrigido/Correcao Inadequada/Novo Achado), percentual de resolucao dos criticos e altos
# 3. DETALHAMENTO DE NAO CORRIGIDOS E CORRECOES INADEQUADAS: o que foi feito vs o que era necessario, risco que permanece
# 4. NOVOS ACHADOS INTRODUZIDOS (se houver)
# 5. PARECER DA REANALISE com criterios:
   APROVADO: todos criticos=CORRIGIDO, todos altos=CORRIGIDO, sem novos criticos/altos
   APROVADO COM RESSALVAS: criticos=CORRIGIDO, altos parciais aceitos, novos achados so medios/baixos
   REPROVADO: qualquer critico!=CORRIGIDO, alto=NAO CORRIGIDO/INADEQUADO, novo achado critico/alto
# 6. PROXIMOS PASSOS: instrucoes especificas conforme parecer

Gere relatorio Markdown completo e estruturado.
"@

# ─────────────────────────────────────────────
#  EXECUCAO DAS FASES
# ─────────────────────────────────────────────

$fases_executar = switch ($Fase) {
    "todas"        { @("codigo","docs","infra","threat","relatorio","apresentacoes") }
    "reanalise"    { @("ra01","ra02","ra03","ra00") }
    default        { @($Fase) }
}

foreach ($f in $fases_executar) {
    switch ($f) {

        "codigo" {
            Write-PhaseHeader "FASE 1 — ANALISE DE CODIGO" "Blue"
            if (-not (Test-Path $CODIGO)) { Write-Host "  AVISO: pasta codigo/ nao encontrada, pulando." -ForegroundColor Yellow; continue }
            Run-Claude "Analise de Codigo (OWASP + Auth + Deps + Secrets + API)" `
                       $CODIGO `
                       $PROMPT_CODIGO `
                       "$REL\01_analise_codigo.md"
        }

        "docs" {
            Write-PhaseHeader "FASE 2 — ANALISE DE DOCUMENTACAO" "Magenta"
            if (-not (Test-Path $DOCS)) { Write-Host "  AVISO: pasta documentacao/ nao encontrada, pulando." -ForegroundColor Yellow; continue }
            Run-Claude "Analise de Documentacao (Arquitetura + LGPD + Requisitos)" `
                       $DOCS `
                       $PROMPT_DOCS `
                       "$REL\02_analise_documentacao.md"
        }

        "infra" {
            Write-PhaseHeader "FASE 3 — ANALISE DE INFRAESTRUTURA" "Yellow"
            if (-not (Test-Path $INFRA)) { Write-Host "  AVISO: pasta infraestrutura/ nao encontrada, pulando." -ForegroundColor Yellow; continue }
            Run-Claude "Analise de Infraestrutura (Rede + IAM + IaC + Containers)" `
                       $INFRA `
                       $PROMPT_INFRA `
                       "$REL\03_analise_infraestrutura.md"
        }

        "threat" {
            Write-PhaseHeader "FASE 4 — THREAT MODELING" "Red"
            Run-Claude "Modelagem de Ameacas STRIDE" `
                       $PROJ `
                       $PROMPT_THREAT `
                       "$REL\04_threat_modeling.md"
        }

        "relatorio" {
            Write-PhaseHeader "FASE 5 — RELATORIO EXECUTIVO" "Cyan"
            Run-Claude "Relatorio Executivo Consolidado + Parecer" `
                       $PROJ `
                       $PROMPT_RELATORIO `
                       "$REL\00_RELATORIO_EXECUTIVO.md"
        }

        "apresentacoes" {
            Write-PhaseHeader "FASE 6-7 — APRESENTACOES PARA A FABRICA" "Green"
            Run-Claude "Apresentacao de Vulnerabilidades (HTML)" `
                       $PROJ `
                       $PROMPT_APRES_VULNS `
                       "$APRES\apresentacao_vulnerabilidades.html"

            Run-Claude "Apresentacao de Melhorias e Roadmap (HTML)" `
                       $PROJ `
                       $PROMPT_APRES_ROADMAP `
                       "$APRES\apresentacao_melhorias_roadmap.html"
        }

        "ra01" {
            Write-PhaseHeader "REANALISE R1 — CRITICOS E ALTOS" "Yellow"
            if (-not (Test-Path $REANALISE_DIR)) { New-Item -ItemType Directory -Path $REANALISE_DIR -Force | Out-Null }
            Run-Claude "Verificacao de Achados Criticos e Altos" `
                       $PROJ `
                       $PROMPT_RA01 `
                       "$REANALISE_DIR\RA_01_achados_criticos_altos.md"
        }

        "ra02" {
            Write-PhaseHeader "REANALISE R2 — ACHADOS MEDIOS" "Yellow"
            if (-not (Test-Path $REANALISE_DIR)) { New-Item -ItemType Directory -Path $REANALISE_DIR -Force | Out-Null }
            Run-Claude "Verificacao de Achados Medios e Prazos" `
                       $PROJ `
                       $PROMPT_RA02 `
                       "$REANALISE_DIR\RA_02_achados_medios.md"
        }

        "ra03" {
            Write-PhaseHeader "REANALISE R3 — NOVOS ACHADOS" "Yellow"
            Run-Claude "Varredura de Novos Achados nas Areas Modificadas" `
                       $PROJ `
                       $PROMPT_RA03 `
                       "$REANALISE_DIR\RA_03_novos_achados.md"
        }

        "ra00" {
            Write-PhaseHeader "REANALISE R4 — RELATORIO CONSOLIDADO" "Cyan"
            Run-Claude "Relatorio Consolidado de Reanalise $Versao" `
                       $PROJ `
                       $PROMPT_RA00 `
                       "$REANALISE_DIR\RA_00_relatorio_reanalise.md"
        }
    }
}

# ─────────────────────────────────────────────
#  RESUMO FINAL
# ─────────────────────────────────────────────
$elapsed_total = [math]::Round(((Get-Date) - $inicio_total).TotalMinutes, 1)

Write-Host ""
Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

if ($DryRun) {
    Write-Host "  [DRY RUN] Nenhum arquivo foi gerado." -ForegroundColor Yellow
    exit 0
}

if ($erros.Count -eq 0) {
    Write-Host "  ANALISE CONCLUIDA — ${elapsed_total}min total" -ForegroundColor Green
} else {
    Write-Host "  ANALISE CONCLUIDA COM ERROS — ${elapsed_total}min total" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Fases com erro:" -ForegroundColor Red
    foreach ($e in $erros) { Write-Host "    - $e" -ForegroundColor Red }
}

if ($tempos.Count -gt 0) {
    Write-Host ""
    Write-Host "  Tempo por fase:" -ForegroundColor DarkGray
    foreach ($t in $tempos.GetEnumerator()) {
        Write-Host "    $($t.Key.PadRight(50)) $($t.Value)min" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "  AGORA E COM VOCE — revisao humana obrigatoria:" -ForegroundColor Cyan
Write-Host "  1. Revise os relatorios em: $REL" -ForegroundColor White
Write-Host "  2. Preencha o checklist   : $env:USERPROFILE\Documents\Seguranca-TI\CHECKLIST_SEGURANCA_PROJETOS.md" -ForegroundColor White
Write-Host "  3. Valide os achados (o agente pode ter falsos positivos ou perdido itens)" -ForegroundColor White
Write-Host "  4. Assine o parecer final com o coordenador" -ForegroundColor White
if ($Fase -eq "todas" -or $Fase -eq "apresentacoes") {
    Write-Host "  5. Apresentacoes em       : $APRES" -ForegroundColor White
}
Write-Host ""
Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
