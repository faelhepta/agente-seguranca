#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  AUTOMACAO DE ANALISE DE SEGURANCA
#  Coordenacao de Seguranca de TI
#
#  Uso:
#    bash rodar_analise.sh -p SistemaRH
#    bash rodar_analise.sh -p SistemaRH -f codigo
#    bash rodar_analise.sh -p SistemaRH -f reanalise -v v1
#    bash rodar_analise.sh -p SistemaRH --dry-run
#
#  Fases: todas | codigo | docs | infra | threat | relatorio | apresentacoes | reanalise
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ─────────────────────────────────────────────
#  DEFAULTS
# ─────────────────────────────────────────────
PROJETO=""
FASE="todas"
VERSAO="v1"
DRY_RUN=false

BASE="$HOME/Documents/projetos"

# ─────────────────────────────────────────────
#  CORES
# ─────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; WHITE='\033[1;37m'; GRAY='\033[0;37m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; DARKGRAY='\033[1;30m'; NC='\033[0m'

# ─────────────────────────────────────────────
#  PARSE DE ARGUMENTOS
# ─────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--projeto)  PROJETO="$2"; shift 2 ;;
        -f|--fase)     FASE="$2";    shift 2 ;;
        -v|--versao)   VERSAO="$2";  shift 2 ;;
        --dry-run)     DRY_RUN=true; shift ;;
        -h|--help)
            grep "^#  " "$0" | sed 's/^#  //'
            exit 0 ;;
        *) echo "Argumento desconhecido: $1"; exit 1 ;;
    esac
done

if [[ -z "$PROJETO" ]]; then
    echo -e "${RED}ERRO: informe o projeto com -p NomeDoProjeto${NC}"
    exit 1
fi

# ─────────────────────────────────────────────
#  CAMINHOS
# ─────────────────────────────────────────────
PROJ="$BASE/$PROJETO"
REL="$PROJ/relatorios"
APRES="$PROJ/apresentacoes"
CODIGO="$PROJ/codigo"
DOCS_DIR="$PROJ/documentacao"
INFRA="$PROJ/infraestrutura"
REANALISE_DIR="$PROJ/reanalise/$VERSAO/relatorios"

ERROS=()
FASES_PULADAS=()
INICIO_TOTAL=$(date +%s)

# ─────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────
has_files() {
    [[ -d "$1" ]] && [[ -n "$(find "$1" -type f 2>/dev/null | head -1)" ]]
}

header() {
    local dry=""
    $DRY_RUN && dry=" [DRY RUN]"
    echo ""
    echo -e "  ${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║   AUTOMACAO DE ANALISE DE SEGURANCA${dry}$(printf '%*s' $((20-${#dry})) '')║${NC}"
    echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Projeto : ${WHITE}$PROJETO${NC}"
    echo -e "  Fase    : ${WHITE}$FASE${NC}"
    echo -e "  Inicio  : ${WHITE}$(date '+%d/%m/%Y %H:%M')${NC}"
    [[ "$FASE" == "reanalise" ]] && echo -e "  Versao  : ${WHITE}$VERSAO${NC}"
    echo ""
}

phase_header() {
    local cor="${2:-$CYAN}"
    echo ""
    echo -e "  ${!cor}── $1 ${DARKGRAY}$(printf '─%.0s' $(seq 1 $((50-${#1}))))${NC}"
}

TEMPOS=()

run_claude() {
    local descricao="$1"
    local diretorio="$2"
    local prompt="$3"
    local saida="$4"

    echo -e "  ${WHITE}[>] $descricao${NC}"
    echo -e "  ${DARKGRAY}    Dir  : $diretorio${NC}"
    echo -e "  ${DARKGRAY}    Saida: $saida${NC}"

    if $DRY_RUN; then
        echo -e "  ${YELLOW}    [DRY RUN] claude -p [${#prompt} chars] > $saida${NC}"
        return 0
    fi

    mkdir -p "$(dirname "$saida")"
    local inicio=$(date +%s)

    if (cd "$diretorio" && claude -p "$prompt" > "$saida" 2>&1); then
        local fim=$(date +%s)
        local elapsed=$(( (fim - inicio) / 60 ))
        echo -e "  ${GREEN}    OK em ${elapsed}min -> $saida${NC}"
        TEMPOS+=("$descricao|${elapsed}min")
    else
        echo -e "  ${RED}    ERRO ao executar Claude para: $descricao${NC}"
        ERROS+=("$descricao")
    fi
}

# ─────────────────────────────────────────────
#  VALIDACOES
# ─────────────────────────────────────────────
header

if [[ ! -d "$PROJ" ]]; then
    echo -e "  ${RED}ERRO: Projeto nao encontrado em: $PROJ${NC}"
    echo ""
    echo -e "  ${YELLOW}Projetos disponiveis:${NC}"
    ls "$BASE" 2>/dev/null | while read p; do echo "    - $p"; done
    exit 1
fi

if ! command -v claude &>/dev/null; then
    echo -e "  ${RED}ERRO: Claude Code nao encontrado. Execute: npm install -g @anthropic-ai/claude-code${NC}"
    exit 1
fi

echo -e "  ${DARKGRAY}Claude Code: $(claude --version 2>/dev/null || echo 'ok')${NC}"

mkdir -p "$REL" "$APRES"

# ─────────────────────────────────────────────
#  PROMPTS
# ─────────────────────────────────────────────

PROMPT_CODIGO="Voce e um analista de seguranca senior. Analise todo o codigo fonte neste diretorio.

PARTE 1 — ANALISE GERAL OWASP TOP 10:
Identifique vulnerabilidades seguindo o OWASP Top 10. Para cada achado informe:
- Arquivo e linha exata
- Tipo de vulnerabilidade (CWE se possivel)
- Severidade (Critico/Alto/Medio/Baixo)
- Descricao tecnica do problema
- Recomendacao de correcao com exemplo de codigo seguro
Foque em: SQL/Command/LDAP Injection, autenticacao quebrada, exposicao de dados, controle de acesso, configuracoes inseguras, componentes vulneraveis, logging insuficiente.

PARTE 2 — AUTENTICACAO E AUTORIZACAO:
JWT/OAuth/sessoes, armazenamento de senhas, RBAC, credenciais hardcoded, brute force, invalidacao de sessao.

PARTE 3 — DEPENDENCIAS E CVEs:
Liste todas as dependencias (package.json, requirements.txt, pom.xml, go.mod, etc.). Para cada: versao, CVEs criticos/altos, se ativa, recomendacao.

PARTE 4 — SECRETS:
Varra buscando: chaves de API/tokens/passwords hardcoded, conexoes de banco com credenciais, .env commitados, chaves privadas, PII em logs. Liste arquivo e linha.

PARTE 5 — SEGURANCA DE API:
Para cada endpoint: autenticacao, autorizacao, validacao de inputs, risco de IDOR, headers de seguranca, rate limiting. Tabela de endpoints com status.

Gere relatorio Markdown completo com sumario de contagem por severidade ao final."

PROMPT_DOCS="Voce e um analista de seguranca senior. Analise toda a documentacao tecnica neste diretorio.

PARTE 1 — ARQUITETURA E FLUXO DE DADOS:
Fronteiras de confianca, dados sensiveis no sistema (PII/financeiro/credenciais), fluxos de autenticacao, integracoes com terceiros, pontos de armazenamento sensiveis. Aponte lacunas e riscos.

PARTE 2 — CONFORMIDADE LGPD:
Dados pessoais coletados, base legal, retencao e descarte, direitos dos titulares, DPA com terceiros, notificacao de incidentes. Relatorio de aderencia com gaps.

PARTE 3 — REQUISITOS DE SEGURANCA:
Requisitos existentes vs atendidos, requisitos ausentes mas necessarios, classificacao de dados, procedimentos de resposta a incidentes. Gaps criticos antes do go-live.

Gere relatorio Markdown completo com sumario ao final."

PROMPT_INFRA="Voce e um analista de seguranca senior. Analise todo o material de infraestrutura neste diretorio.

PARTE 1 — REDE E EXPOSICAO:
Segmentacao (DMZ/dados/app), exposicao para internet, banco de dados acessivel externamente, WAF/balanceador/CDN, comunicacao interna criptografada, monitoramento.

PARTE 2 — IAM:
Principio do menor privilegio, acesso administrativo restrito e auditado, MFA para privilegiados, service accounts, rotacao de chaves.

PARTE 3 — IaC (Terraform/CloudFormation/Pulumi se existir):
Security groups abertos (0.0.0.0/0), buckets publicos, bancos sem criptografia, instancias sem monitoramento, secrets nos arquivos IaC, imagens desatualizadas.

PARTE 4 — CONTAINERS/KUBERNETES (se existir):
Root containers, imagens vulneraveis, secrets em variaveis plaintext, pod security policies, registry sem scan.

PARTE 5 — MONITORAMENTO E DR:
Logs habilitados, alertas, retencao (minimo 90 dias), SIEM, backup e DR, RTO/RPO.

Gere relatorio Markdown completo com sumario ao final."

PROMPT_THREAT="Voce e um especialista em threat modeling. Com base nos relatorios em relatorios/ (01, 02 e 03), realize modelagem de ameacas STRIDE.

Para cada componente critico do sistema, analise:
- Spoofing: falsificacao de identidade
- Tampering: adulteracao de dados
- Repudiation: acoes sem rastro de auditoria
- Information Disclosure: exposicao indevida de dados
- Denial of Service: componentes vulneraveis a indisponibilidade
- Elevation of Privilege: obtencao de mais permissoes

Para cada ameaca: ID (STR-001...), componente, categoria STRIDE, cenario de ataque, severidade, controle mitigador recomendado, status do controle (implementado/parcial/ausente).
Tabela resumo ao final com todas as ameacas priorizadas por severidade.
Gere relatorio Markdown completo."

PROMPT_RELATORIO="Voce e um coordenador de seguranca senior. Com base nos relatorios 01, 02, 03 e 04 em relatorios/, gere RELATORIO EXECUTIVO CONSOLIDADO em Markdown.

# 1. SUMARIO EXECUTIVO: nome/data, resumo nao-tecnico em 5 linhas, tabela de achados por severidade
# 2. ACHADOS CRITICOS E ALTOS: ID, titulo, componente, descricao, recomendacao
# 3. ACHADOS MEDIOS: tabela resumida
# 4. ACHADOS BAIXOS/INFO: tabela compacta
# 5. MATRIZ DE RISCO: grid probabilidade x impacto
# 6. PLANO DE CORRECAO: Prioridade 1 (antes deploy), Prioridade 2 (30 dias), Prioridade 3 (proximo ciclo)
# 7. PARECER FINAL: APROVADO / APROVADO COM RESSALVAS / REPROVADO + justificativa + condicoes

Seja objetivo e claro para leitores nao-tecnicos no sumario."

PROMPT_VULNS="Leia todos os relatorios na pasta relatorios/ (arquivos 00 ao 04). Com base nos achados REAIS, gere HTML de apresentacao de slides para a fabrica. Salve como apresentacoes/apresentacao_vulnerabilidades.html.
Visual: fundo escuro (#0a0e1a), navegacao por setas, barra de progresso, CSS inline, sem dependencias, sem emojis (use unicode).
Slides: capa com badge de parecer colorido, sumario executivo com contadores reais, grafico de barras CSS por severidade e categoria, matriz de risco CSS, um slide por achado critico/alto (ID/componente/impacto/evidencia/CWE), tabela de medios, tabela de baixos/info, proximos passos.
Paleta: critico=#ef4444, alto=#f97316, medio=#f59e0b, baixo=#3b82f6, info=#00d4a1.
Use APENAS dados reais. Nao invente vulnerabilidades."

PROMPT_ROADMAP="Leia todos os relatorios na pasta relatorios/ (arquivos 00 ao 04). Com base nas recomendacoes REAIS, gere HTML de apresentacao de melhorias para a fabrica. Salve como apresentacoes/apresentacao_melhorias_roadmap.html.
Tom: CONSTRUTIVO. Visual: tons de verde e azul, fundo escuro, CSS inline, sem dependencias, sem emojis.
Slides: capa 'Plano de Melhorias', visao geral dos 3 pilares, como ler o roadmap (4 fases: antes-deploy/vermelho, 30dias/amarelo, 90dias/azul, 6meses/verde), um slide de solucao por achado critico/alto (passo-a-passo/codigo-seguro/esforco/fase/responsavel), tabela de melhorias medias, evolucoes estrategicas, roadmap visual tipo Gantt CSS, metricas de sucesso, boas praticas, compromisso conjunto.
Use APENAS dados reais."

PROMPT_RA01="Leia relatorios/00_RELATORIO_EXECUTIVO.md, relatorios/01_analise_codigo.md e relatorios/03_analise_infraestrutura.md. Analise o codigo/infra corrigidos e evidencias em reanalise/$VERSAO/evidencias/.
Para cada achado CRITICO e ALTO do relatorio original: localize o componente, verifique a correcao, avalie adequacao tecnica, verifique novos problemas.
Status: CORRIGIDO | PARCIALMENTE CORRIGIDO | NAO CORRIGIDO | CORRECAO INADEQUADA | NAO VERIFICAVEL | NOVO ACHADO.
Para cada achado: ID original, titulo, situacao atual, STATUS, justificativa. Se NOVO ACHADO: descricao completa.
Tabela resumo ao final. Relatorio Markdown completo."

PROMPT_RA02="Com base em relatorios/00_RELATORIO_EXECUTIVO.md, verifique todos os achados MEDIOS.
Para cada: correcao implementada, se dentro do prazo de 30 dias, status com mesmo sistema.
Achados vencidos nao corrigidos: VENCIDO NAO CORRIGIDO.
Tabela: ID, titulo, prazo acordado, status atual, observacao. Relatorio Markdown completo."

PROMPT_RA03="Com base nas evidencias em reanalise/$VERSAO/evidencias/, identifique arquivos e componentes modificados.
Para cada area modificada: novos vetores de ataque, novas dependencias com CVEs, alteracoes de auth/permissoes, novos endpoints, mudancas de escopo.
Tambem: novos hardcoded secrets, novos .env, mudancas alem do acordado.
Para cada novo achado: ID (NEW-001...), arquivo/linha, descricao, severidade, como surgiu.
Se nada encontrado, declare explicitamente. Relatorio Markdown completo."

PROMPT_RA00="Com base nos relatorios RA_01, RA_02 e RA_03 em reanalise/$VERSAO/relatorios/, gere RELATORIO CONSOLIDADO DE REANALISE $VERSAO.
Estrutura: cabecalho, resumo com tabela de status, detalhamento de nao-corrigidos/inadequados, novos achados (se houver), parecer (APROVADO/APROVADO COM RESSALVAS/REPROVADO com criterios), proximos passos especificos.
Relatorio Markdown completo e estruturado."

# ─────────────────────────────────────────────
#  EXECUCAO
# ─────────────────────────────────────────────

declare -a FASES_EXECUTAR
case "$FASE" in
    todas)        FASES_EXECUTAR=(codigo docs infra threat relatorio apresentacoes) ;;
    reanalise)    FASES_EXECUTAR=(ra01 ra02 ra03 ra00) ;;
    *)            FASES_EXECUTAR=("$FASE") ;;
esac

for f in "${FASES_EXECUTAR[@]}"; do
    case "$f" in
        codigo)
            phase_header "FASE 1 — ANALISE DE CODIGO" "BLUE"
            if ! has_files "$CODIGO"; then
                echo -e "  ${RED}    AVISO: pasta codigo/ esta vazia ou nao existe.${NC}"
                echo -e "  ${YELLOW}             A analise de codigo e obrigatoria. Adicione o codigo e rode novamente.${NC}"
                echo -e "  ${DARKGRAY}             Para rodar depois: bash rodar_analise.sh -p $PROJETO -f codigo${NC}"
                FASES_PULADAS+=("Fase 1 - Codigo (pasta vazia)")
                continue
            fi
            run_claude "Analise de Codigo (OWASP + Auth + Deps + Secrets + API)" \
                       "$CODIGO" "$PROMPT_CODIGO" "$REL/01_analise_codigo.md"
            ;;
        docs)
            phase_header "FASE 2 — ANALISE DE DOCUMENTACAO" "MAGENTA"
            if ! has_files "$DOCS_DIR"; then
                echo -e "  ${YELLOW}    PULADO: pasta documentacao/ esta vazia. Fase ignorada.${NC}"
                echo -e "  ${DARKGRAY}             Para incluir esta analise depois: bash rodar_analise.sh -p $PROJETO -f docs${NC}"
                FASES_PULADAS+=("Fase 2 - Documentacao (pasta vazia)")
                continue
            fi
            run_claude "Analise de Documentacao (Arquitetura + LGPD + Requisitos)" \
                       "$DOCS_DIR" "$PROMPT_DOCS" "$REL/02_analise_documentacao.md"
            ;;
        infra)
            phase_header "FASE 3 — ANALISE DE INFRAESTRUTURA" "YELLOW"
            if ! has_files "$INFRA"; then
                echo -e "  ${YELLOW}    PULADO: pasta infraestrutura/ esta vazia. Fase ignorada.${NC}"
                echo -e "  ${DARKGRAY}             Para incluir esta analise depois: bash rodar_analise.sh -p $PROJETO -f infra${NC}"
                FASES_PULADAS+=("Fase 3 - Infraestrutura (pasta vazia)")
                continue
            fi
            run_claude "Analise de Infraestrutura (Rede + IAM + IaC + Containers)" \
                       "$INFRA" "$PROMPT_INFRA" "$REL/03_analise_infraestrutura.md"
            ;;
        threat)
            phase_header "FASE 4 — THREAT MODELING" "RED"
            REL_DISPONIVEIS=()
            [[ -f "$REL/01_analise_codigo.md" ]]         && REL_DISPONIVEIS+=("relatorios/01_analise_codigo.md")
            [[ -f "$REL/02_analise_documentacao.md" ]]   && REL_DISPONIVEIS+=("relatorios/02_analise_documentacao.md")
            [[ -f "$REL/03_analise_infraestrutura.md" ]] && REL_DISPONIVEIS+=("relatorios/03_analise_infraestrutura.md")
            LISTA_REL=$(IFS=', '; echo "${REL_DISPONIVEIS[*]}")
            PROMPT_THREAT_DIN="${PROMPT_THREAT/relatorios\/ (01, 02 e 03)/relatorios\/ (disponiveis: $LISTA_REL)}"
            if [[ ${#FASES_PULADAS[@]} -gt 0 ]]; then
                PULADAS_STR=$(IFS='; '; echo "${FASES_PULADAS[*]}")
                PROMPT_THREAT_DIN+=$'\n\nOBSERVACAO: as seguintes fases nao foram analisadas por falta de artefatos: '"$PULADAS_STR"$'. Realize o threat modeling com base apenas nos relatorios disponiveis e registre as lacunas no relatorio.'
            fi
            run_claude "Modelagem de Ameacas STRIDE" \
                       "$PROJ" "$PROMPT_THREAT_DIN" "$REL/04_threat_modeling.md"
            ;;
        relatorio)
            phase_header "FASE 5 — RELATORIO EXECUTIVO" "CYAN"
            PROMPT_RELATORIO_DIN="$PROMPT_RELATORIO"
            if [[ ${#FASES_PULADAS[@]} -gt 0 ]]; then
                PULADAS_STR=$(IFS='; '; echo "${FASES_PULADAS[*]}")
                PROMPT_RELATORIO_DIN+=$'\n\nOBSERVACAO: analise parcial. As seguintes fases nao foram executadas por falta de artefatos: '"$PULADAS_STR"$'. Indique claramente no relatorio quais dimensoes nao foram analisadas e o impacto na abrangencia do parecer.'
            fi
            run_claude "Relatorio Executivo Consolidado + Parecer" \
                       "$PROJ" "$PROMPT_RELATORIO_DIN" "$REL/00_RELATORIO_EXECUTIVO.md"
            ;;
        apresentacoes)
            phase_header "FASES 6-7 — APRESENTACOES PARA A FABRICA" "GREEN"
            run_claude "Apresentacao de Vulnerabilidades (HTML)" \
                       "$PROJ" "$PROMPT_VULNS" "$APRES/apresentacao_vulnerabilidades.html"
            run_claude "Apresentacao de Melhorias e Roadmap (HTML)" \
                       "$PROJ" "$PROMPT_ROADMAP" "$APRES/apresentacao_melhorias_roadmap.html"
            ;;
        ra01)
            phase_header "REANALISE R1 — CRITICOS E ALTOS" "YELLOW"
            mkdir -p "$REANALISE_DIR"
            run_claude "Verificacao de Achados Criticos e Altos" \
                       "$PROJ" "$PROMPT_RA01" "$REANALISE_DIR/RA_01_achados_criticos_altos.md"
            ;;
        ra02)
            phase_header "REANALISE R2 — ACHADOS MEDIOS" "YELLOW"
            mkdir -p "$REANALISE_DIR"
            run_claude "Verificacao de Achados Medios e Prazos" \
                       "$PROJ" "$PROMPT_RA02" "$REANALISE_DIR/RA_02_achados_medios.md"
            ;;
        ra03)
            phase_header "REANALISE R3 — NOVOS ACHADOS" "YELLOW"
            run_claude "Varredura de Novos Achados nas Areas Modificadas" \
                       "$PROJ" "$PROMPT_RA03" "$REANALISE_DIR/RA_03_novos_achados.md"
            ;;
        ra00)
            phase_header "REANALISE R4 — RELATORIO CONSOLIDADO" "CYAN"
            run_claude "Relatorio Consolidado de Reanalise $VERSAO" \
                       "$PROJ" "$PROMPT_RA00" "$REANALISE_DIR/RA_00_relatorio_reanalise.md"
            ;;
    esac
done

# ─────────────────────────────────────────────
#  RESUMO FINAL
# ─────────────────────────────────────────────
FIM_TOTAL=$(date +%s)
ELAPSED_TOTAL=$(( (FIM_TOTAL - INICIO_TOTAL) / 60 ))

echo ""
echo -e "  ${DARKGRAY}─────────────────────────────────────────────────────────${NC}"
echo ""

if $DRY_RUN; then
    echo -e "  ${YELLOW}[DRY RUN] Nenhum arquivo foi gerado.${NC}"
    exit 0
fi

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
        printf "  ${DARKGRAY}  %-50s %s${NC}\n" "$desc" "$elapsed"
    done
fi

if [[ ${#FASES_PULADAS[@]} -gt 0 ]]; then
    echo ""
    echo -e "  ${YELLOW}Fases puladas (sem artefatos):${NC}"
    for fp in "${FASES_PULADAS[@]}"; do
        echo -e "  ${DARKGRAY}    - $fp${NC}"
    done
    echo -e "  ${DARKGRAY}  Para rodar depois: bash rodar_analise.sh -p $PROJETO -f docs  (ou -f infra)${NC}"
fi

echo ""
echo -e "  ${CYAN}AGORA E COM VOCE — revisao humana obrigatoria:${NC}"
echo -e "  ${WHITE}1. Revise os relatorios em: $REL${NC}"
echo -e "  ${WHITE}2. Preencha o checklist   : $HOME/Documents/Seguranca-TI/CHECKLIST_SEGURANCA_PROJETOS.md${NC}"
echo -e "  ${WHITE}3. Valide os achados (o agente pode ter falsos positivos ou perdido itens)${NC}"
echo -e "  ${WHITE}4. Assine o parecer final com o coordenador${NC}"
if [[ "$FASE" == "todas" || "$FASE" == "apresentacoes" ]]; then
    echo -e "  ${WHITE}5. Apresentacoes em       : $APRES${NC}"
fi
echo ""
echo -e "  ${DARKGRAY}─────────────────────────────────────────────────────────${NC}"
echo ""
