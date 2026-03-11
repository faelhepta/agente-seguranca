#!/usr/bin/env bash
# =============================================================================
#  ANALISADOR DE SEGURANCA — Coordenacao de Seguranca de TI
#  Uso: bash analisar.sh
#  O script pergunta o caminho da pasta e executa toda a analise.
# =============================================================================

set -euo pipefail

# ─── Cores ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; WHITE='\033[1;37m'; DARKGRAY='\033[1;30m'; NC='\033[0m'

clear
echo ""
echo -e "  ${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}║   ANALISADOR DE SEGURANCA                            ║${NC}"
echo -e "  ${CYAN}║   Coordenacao de Seguranca de TI                     ║${NC}"
echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${DARKGRAY}Este script analisa o projeto e gera:${NC}"
echo -e "  ${DARKGRAY}  relatorios/    — 5 relatorios Markdown${NC}"
echo -e "  ${DARKGRAY}  apresentacoes/ — 2 slides HTML para a fabrica${NC}"
echo ""

# ─── Verificar Claude Code ────────────────────────────────────────────────────
if ! command -v claude &>/dev/null; then
    echo -e "  ${RED}ERRO: Claude Code nao encontrado.${NC}"
    echo -e "  ${YELLOW}Execute: npm install -g @anthropic-ai/claude-code${NC}"
    exit 1
fi

# ─── Pedir caminho da pasta ───────────────────────────────────────────────────
echo -e "  ${WHITE}Informe o caminho completo da pasta do projeto:${NC}"
echo -e "  ${DARKGRAY}(ex: /home/usuario/projetos/SistemaRH)${NC}"
echo ""
read -rp "  Caminho: " PROJ
PROJ="${PROJ%/}"   # remove trailing slash

if [[ ! -d "$PROJ" ]]; then
    echo ""
    echo -e "  ${RED}ERRO: Pasta nao encontrada: $PROJ${NC}"
    exit 1
fi

# ─── Detectar subpastas com conteudo ─────────────────────────────────────────
has_files() {
    [[ -d "$1" ]] && [[ -n "$(find "$1" -type f 2>/dev/null | head -1)" ]]
}

CODIGO="$PROJ/codigo"
DOCS="$PROJ/documentacao"
INFRA="$PROJ/infraestrutura"
REL="$PROJ/relatorios"
APRES="$PROJ/apresentacoes"

has_files "$CODIGO" && TEM_CODIGO=true || TEM_CODIGO=false
has_files "$DOCS"   && TEM_DOCS=true   || TEM_DOCS=false
has_files "$INFRA"  && TEM_INFRA=true  || TEM_INFRA=false

echo ""
echo -e "  Projeto : ${WHITE}$PROJ${NC}"
echo ""
echo -e "  ${CYAN}Estrutura encontrada:${NC}"

if $TEM_CODIGO; then
    echo -e "    ${GREEN}[OK]${NC} codigo/         — analise sera executada"
else
    echo -e "    ${RED}[--]${NC} codigo/         — vazia ou ausente (OBRIGATORIO)"
fi

if $TEM_DOCS; then
    echo -e "    ${GREEN}[OK]${NC} documentacao/   — analise sera executada"
else
    echo -e "    ${YELLOW}[--]${NC} documentacao/   — vazia ou ausente (fase sera pulada)"
fi

if $TEM_INFRA; then
    echo -e "    ${GREEN}[OK]${NC} infraestrutura/ — analise sera executada"
else
    echo -e "    ${YELLOW}[--]${NC} infraestrutura/ — vazia ou ausente (fase sera pulada)"
fi

echo ""

if ! $TEM_CODIGO; then
    echo -e "  ${RED}ERRO: pasta codigo/ esta vazia ou nao existe.${NC}"
    echo -e "  ${YELLOW}Coloque o codigo fonte em: $CODIGO${NC}"
    exit 1
fi

echo -e "  ${DARKGRAY}Pressione ENTER para iniciar ou Ctrl+C para cancelar.${NC}"
read -r

# ─── Helpers ─────────────────────────────────────────────────────────────────
ERROS=()
FASES_PULADAS=()
TEMPOS=()
INICIO_TOTAL=$(date +%s)

mkdir -p "$REL" "$APRES"

run_claude() {
    local descricao="$1"
    local diretorio="$2"
    local prompt="$3"
    local saida="$4"

    echo ""
    echo -e "  ${WHITE}[>] $descricao${NC}"
    echo -e "  ${DARKGRAY}      Dir  : $diretorio${NC}"
    echo -e "  ${DARKGRAY}      Saida: $saida${NC}"

    local inicio=$(date +%s)
    local tmp
    tmp=$(mktemp)
    printf '%s' "$prompt" > "$tmp"

    if (cd "$diretorio" && claude -p "$(cat "$tmp")" > "$saida" 2>&1); then
        local fim=$(date +%s)
        local elapsed=$(( (fim - inicio) / 60 ))
        echo -e "  ${GREEN}      OK em ${elapsed}min${NC}"
        TEMPOS+=("$descricao|${elapsed}min")
    else
        echo -e "  ${RED}      ERRO ao executar Claude para: $descricao${NC}"
        ERROS+=("$descricao")
    fi
    rm -f "$tmp"
}

# ─── Prompts ──────────────────────────────────────────────────────────────────
P_CODIGO="Voce e um analista de seguranca senior. Analise todo o codigo fonte neste diretorio.

PARTE 1 — OWASP TOP 10:
Identifique vulnerabilidades. Para cada achado: arquivo e linha, tipo (CWE), severidade (Critico/Alto/Medio/Baixo), descricao tecnica, recomendacao com exemplo de codigo seguro.
Foque em: Injection, autenticacao quebrada, exposicao de dados, controle de acesso, configuracoes inseguras, componentes vulneraveis, logging insuficiente.

PARTE 2 — AUTENTICACAO E AUTORIZACAO:
JWT/OAuth/sessoes, senhas, RBAC, credenciais hardcoded, brute force, invalidacao de sessao.

PARTE 3 — DEPENDENCIAS E CVEs:
Liste dependencias (package.json, requirements.txt, pom.xml, go.mod etc). Para cada: versao, CVEs criticos/altos, recomendacao.

PARTE 4 — SECRETS:
Chaves de API, tokens, passwords hardcoded, .env commitados, chaves privadas, PII em logs. Arquivo e linha.

PARTE 5 — SEGURANCA DE API:
Por endpoint: autenticacao, autorizacao, validacao, IDOR, headers, rate limiting. Tabela de endpoints.

Gere relatorio Markdown completo com sumario de contagem por severidade ao final."

P_DOCS="Voce e um analista de seguranca senior. Analise toda a documentacao tecnica neste diretorio.

PARTE 1 — ARQUITETURA E FLUXO DE DADOS:
Fronteiras de confianca, dados sensiveis, fluxos de autenticacao, integracoes com terceiros, pontos de armazenamento. Aponte lacunas e riscos.

PARTE 2 — CONFORMIDADE LGPD:
Dados pessoais coletados, base legal, retencao, direitos dos titulares, DPA, notificacao de incidentes. Gaps de aderencia.

PARTE 3 — REQUISITOS DE SEGURANCA:
Requisitos existentes vs atendidos, ausentes mas necessarios, classificacao de dados, resposta a incidentes.

Gere relatorio Markdown completo com sumario ao final."

P_INFRA="Voce e um analista de seguranca senior. Analise todo o material de infraestrutura neste diretorio.

PARTE 1 — REDE E EXPOSICAO:
Segmentacao, exposicao para internet, banco de dados acessivel externamente, WAF, comunicacao criptografada, monitoramento.

PARTE 2 — IAM:
Menor privilegio, acesso administrativo, MFA, service accounts, rotacao de chaves.

PARTE 3 — IaC (Terraform/CloudFormation/Pulumi):
Security groups abertos, buckets publicos, bancos sem criptografia, secrets em IaC, imagens desatualizadas.

PARTE 4 — CONTAINERS/KUBERNETES:
Root containers, imagens vulneraveis, secrets em variaveis plaintext, pod security policies.

PARTE 5 — MONITORAMENTO E DR:
Logs, alertas, retencao, SIEM, backup, RTO/RPO.

Gere relatorio Markdown completo com sumario ao final."

P_THREAT="Voce e um especialista em threat modeling. Com base nos relatorios disponiveis em relatorios/, realize modelagem de ameacas STRIDE.

Para cada componente critico: Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege.
Para cada ameaca: ID (STR-001...), componente, categoria STRIDE, cenario de ataque, severidade, controle mitigador, status (implementado/parcial/ausente).
Tabela resumo ao final por severidade. Relatorio Markdown completo."

P_RELATORIO="Voce e um coordenador de seguranca senior. Com base nos relatorios disponiveis em relatorios/, gere RELATORIO EXECUTIVO CONSOLIDADO em Markdown.

1. SUMARIO EXECUTIVO: resumo nao-tecnico em 5 linhas, tabela de achados por severidade
2. ACHADOS CRITICOS E ALTOS: ID, titulo, componente, descricao, recomendacao
3. ACHADOS MEDIOS: tabela resumida
4. ACHADOS BAIXOS/INFO: tabela compacta
5. MATRIZ DE RISCO: grid probabilidade x impacto
6. PLANO DE CORRECAO: Prioridade 1 (antes deploy), Prioridade 2 (30 dias), Prioridade 3 (proximo ciclo)
7. PARECER FINAL: APROVADO / APROVADO COM RESSALVAS / REPROVADO + justificativa"

P_VULNS="Leia todos os relatorios na pasta relatorios/. Com base nos achados REAIS, gere HTML de apresentacao de slides para a fabrica. Salve como apresentacoes/apresentacao_vulnerabilidades.html.
Visual: fundo escuro (#0a0e1a), navegacao por setas, barra de progresso, CSS inline, sem dependencias, sem emojis.
Slides: capa com badge de parecer, sumario executivo com contadores reais, grafico de barras CSS por severidade, matriz de risco CSS, um slide por achado critico/alto, tabela de medios, tabela de baixos/info, proximos passos.
Paleta: critico=#ef4444, alto=#f97316, medio=#f59e0b, baixo=#3b82f6, info=#00d4a1.
Use APENAS dados reais dos relatorios. Nao invente vulnerabilidades."

P_ROADMAP="Leia todos os relatorios na pasta relatorios/. Com base nas recomendacoes REAIS, gere HTML de apresentacao de melhorias para a fabrica. Salve como apresentacoes/apresentacao_melhorias_roadmap.html.
Tom: CONSTRUTIVO. Visual: tons de verde e azul, fundo escuro, CSS inline, sem dependencias, sem emojis.
Slides: capa 'Plano de Melhorias', visao geral dos pilares, roadmap 4 fases (antes-deploy/vermelho, 30dias/amarelo, 90dias/azul, 6meses/verde), solucao por achado critico/alto, melhorias medias, Gantt CSS, metricas de sucesso.
Use APENAS dados reais."

# ─── Execucao ─────────────────────────────────────────────────────────────────

# Fase 1 — Codigo
echo "" ; echo -e "  ${CYAN}── FASE 1 — ANALISE DE CODIGO ──────────────────────────────${NC}"
run_claude "Analise de Codigo (OWASP + Auth + Deps + Secrets + API)" "$CODIGO" "$P_CODIGO" "$REL/01_analise_codigo.md"

# Fase 2 — Documentacao
echo "" ; echo -e "  ${CYAN}── FASE 2 — ANALISE DE DOCUMENTACAO ────────────────────────${NC}"
if $TEM_DOCS; then
    run_claude "Analise de Documentacao (Arquitetura + LGPD + Requisitos)" "$DOCS" "$P_DOCS" "$REL/02_analise_documentacao.md"
else
    echo -e "  ${YELLOW}  PULADO: documentacao/ vazia.${NC}"
    echo -e "  ${DARKGRAY}           Para incluir depois: adicione os docs e rode o script novamente.${NC}"
    FASES_PULADAS+=("Fase 2 - Documentacao (pasta vazia)")
fi

# Fase 3 — Infraestrutura
echo "" ; echo -e "  ${CYAN}── FASE 3 — ANALISE DE INFRAESTRUTURA ──────────────────────${NC}"
if $TEM_INFRA; then
    run_claude "Analise de Infraestrutura (Rede + IAM + IaC + Containers)" "$INFRA" "$P_INFRA" "$REL/03_analise_infraestrutura.md"
else
    echo -e "  ${YELLOW}  PULADO: infraestrutura/ vazia.${NC}"
    echo -e "  ${DARKGRAY}           Para incluir depois: adicione os arquivos e rode o script novamente.${NC}"
    FASES_PULADAS+=("Fase 3 - Infraestrutura (pasta vazia)")
fi

# Fase 4 — Threat Modeling (adaptativo)
echo "" ; echo -e "  ${CYAN}── FASE 4 — THREAT MODELING ─────────────────────────────────${NC}"
if [[ ${#FASES_PULADAS[@]} -gt 0 ]]; then
    PULADAS_STR=$(IFS='; '; echo "${FASES_PULADAS[*]}")
    P_THREAT+=$'\n\nOBSERVACAO: as seguintes fases nao foram analisadas por falta de artefatos: '"$PULADAS_STR"$'. Realize o threat modeling com base apenas nos relatorios disponiveis e registre as lacunas no relatorio.'
fi
run_claude "Modelagem de Ameacas STRIDE" "$PROJ" "$P_THREAT" "$REL/04_threat_modeling.md"

# Fase 5 — Relatorio Executivo (adaptativo)
echo "" ; echo -e "  ${CYAN}── FASE 5 — RELATORIO EXECUTIVO ─────────────────────────────${NC}"
if [[ ${#FASES_PULADAS[@]} -gt 0 ]]; then
    PULADAS_STR=$(IFS='; '; echo "${FASES_PULADAS[*]}")
    P_RELATORIO+=$'\n\nOBSERVACAO: analise parcial. As seguintes fases nao foram executadas por falta de artefatos: '"$PULADAS_STR"$'. Indique claramente no relatorio quais dimensoes nao foram analisadas e o impacto na abrangencia do parecer.'
fi
run_claude "Relatorio Executivo Consolidado + Parecer" "$PROJ" "$P_RELATORIO" "$REL/00_RELATORIO_EXECUTIVO.md"

# Fases 6-7 — Apresentacoes
echo "" ; echo -e "  ${CYAN}── FASES 6-7 — APRESENTACOES PARA A FABRICA ────────────────${NC}"
run_claude "Apresentacao de Vulnerabilidades (HTML)" "$PROJ" "$P_VULNS"    "$APRES/apresentacao_vulnerabilidades.html"
run_claude "Apresentacao de Melhorias e Roadmap (HTML)" "$PROJ" "$P_ROADMAP" "$APRES/apresentacao_melhorias_roadmap.html"

# ─── Resumo Final ─────────────────────────────────────────────────────────────
FIM_TOTAL=$(date +%s)
ELAPSED_TOTAL=$(( (FIM_TOTAL - INICIO_TOTAL) / 60 ))

echo ""
echo -e "  ${DARKGRAY}─────────────────────────────────────────────────────────${NC}"
echo ""

if [[ ${#ERROS[@]} -eq 0 ]]; then
    echo -e "  ${GREEN}ANALISE CONCLUIDA — ${ELAPSED_TOTAL}min total${NC}"
else
    echo -e "  ${YELLOW}ANALISE CONCLUIDA COM ERROS — ${ELAPSED_TOTAL}min total${NC}"
    echo ""
    echo -e "  ${RED}Fases com erro:${NC}"
    for e in "${ERROS[@]}"; do echo -e "    ${RED}- $e${NC}"; done
fi

if [[ ${#TEMPOS[@]} -gt 0 ]]; then
    echo ""
    echo -e "  ${DARKGRAY}Tempo por fase:${NC}"
    for t in "${TEMPOS[@]}"; do
        IFS='|' read -r desc elapsed <<< "$t"
        printf "  ${DARKGRAY}  %-52s %s${NC}\n" "$desc" "$elapsed"
    done
fi

if [[ ${#FASES_PULADAS[@]} -gt 0 ]]; then
    echo ""
    echo -e "  ${YELLOW}Fases puladas (pasta vazia):${NC}"
    for fp in "${FASES_PULADAS[@]}"; do
        echo -e "  ${DARKGRAY}    - $fp${NC}"
    done
fi

echo ""
echo -e "  ${CYAN}AGORA E COM VOCE — revisao humana obrigatoria:${NC}"
echo -e "  ${WHITE}1. Revise os relatorios em  : $REL${NC}"
echo -e "  ${WHITE}2. Valide os achados (pode haver falsos positivos)${NC}"
echo -e "  ${WHITE}3. Preencha o checklist de seguranca${NC}"
echo -e "  ${WHITE}4. Assine o parecer com o coordenador${NC}"
echo -e "  ${WHITE}5. Apresentacoes em         : $APRES${NC}"
echo ""
echo -e "  ${DARKGRAY}─────────────────────────────────────────────────────────${NC}"
echo ""
