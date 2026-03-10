#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  INSTALADOR — AGENTE DE SEGURANCA
#  Coordenacao de Seguranca de TI | v1.0
#
#  Uso:
#    bash instalar.sh             -> instalacao completa
#    bash instalar.sh --update    -> atualiza skills e docs apenas
#    bash instalar.sh --origem /caminho/do/pacote
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ─────────────────────────────────────────────
#  CONFIGURACAO
# ─────────────────────────────────────────────
VERSAO_PACOTE="1.0"
NODE_VERSAO_MIN=18
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGEM_DOCS="$SCRIPT_DIR"
MODO="install"

DESTINO_SKILLS="$HOME/.claude/skills"
DESTINO_DOCS="$HOME/Documents/Seguranca-TI"
DESTINO_PROJETOS="$HOME/Documents/projetos"

ERROS=()
AVISOS=()
COPIADOS=0

# ─────────────────────────────────────────────
#  PARSE DE ARGUMENTOS
# ─────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --update)   MODO="update"; shift ;;
        --origem)   ORIGEM_DOCS="$2"; shift 2 ;;
        *) echo "Argumento desconhecido: $1"; exit 1 ;;
    esac
done

ORIGEM_SKILLS="$ORIGEM_DOCS/skills"
ORIGEM_DOCS_DIR="$ORIGEM_DOCS/docs"

# ─────────────────────────────────────────────
#  CORES
# ─────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; WHITE='\033[1;37m'; GRAY='\033[0;37m'
DARKGRAY='\033[1;30m'; NC='\033[0m'

ok()   { echo -e "       ${GREEN}OK${NC}  $1"; }
warn() { echo -e "    ${YELLOW}AVISO${NC}  $1"; AVISOS+=("$1"); }
fail() { echo -e "     ${RED}ERRO${NC}  $1"; ERROS+=("$1"); }
info() { echo -e "     ${CYAN}INFO${NC}  $1"; }
step() { echo -e "\n  ${CYAN}[$1]${NC} ${WHITE}$2${NC}"; }

# ─────────────────────────────────────────────
#  HEADER
# ─────────────────────────────────────────────
echo ""
echo -e "  ${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}║   INSTALADOR — AGENTE DE SEGURANCA                  ║${NC}"
echo -e "  ${CYAN}║   Coordenacao de Seguranca de TI  •  v${VERSAO_PACOTE}           ║${NC}"
echo -e "  ${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

MODO_LABEL="INSTALACAO COMPLETA"
[[ "$MODO" == "update" ]] && MODO_LABEL="ATUALIZACAO"
echo -e "  Modo    : ${WHITE}$MODO_LABEL${NC}"
echo -e "  Usuario : ${WHITE}$(whoami)${NC}"
echo -e "  Maquina : ${WHITE}$(hostname)${NC}"
echo -e "  Origem  : ${WHITE}$ORIGEM_DOCS${NC}"

# ─────────────────────────────────────────────
#  PASSO 1 — PRE-REQUISITOS
# ─────────────────────────────────────────────
step "1/5" "Verificando pre-requisitos..."

# Node.js
if command -v node &>/dev/null; then
    NODE_VER=$(node --version | sed 's/v//')
    NODE_MAJOR=$(echo "$NODE_VER" | cut -d. -f1)
    if [[ "$NODE_MAJOR" -ge "$NODE_VERSAO_MIN" ]]; then
        ok "Node.js $NODE_VER encontrado"
    else
        fail "Node.js $NODE_VER encontrado, necessario v${NODE_VERSAO_MIN}+. Baixe em https://nodejs.org"
    fi
else
    fail "Node.js nao encontrado. Instale v${NODE_VERSAO_MIN}+ em https://nodejs.org"
fi

# Claude Code
if command -v claude &>/dev/null; then
    CLAUDE_VER=$(claude --version 2>/dev/null || echo "versao desconhecida")
    ok "Claude Code encontrado: $CLAUDE_VER"
else
    fail "Claude Code nao encontrado. Execute: npm install -g @anthropic-ai/claude-code"
fi

# Pasta de skills
if [[ -d "$ORIGEM_SKILLS" ]]; then
    QTD=$(find "$ORIGEM_SKILLS" -name "*.md" | wc -l | tr -d ' ')
    ok "Pasta de skills encontrada ($QTD arquivos)"
else
    fail "Pasta 'skills' nao encontrada em: $ORIGEM_SKILLS"
fi

# Pasta de docs
if [[ -d "$ORIGEM_DOCS_DIR" ]]; then
    QTD=$(ls "$ORIGEM_DOCS_DIR" | wc -l | tr -d ' ')
    ok "Pasta de documentos encontrada ($QTD arquivos)"
else
    fail "Pasta 'docs' nao encontrada em: $ORIGEM_DOCS_DIR"
fi

# Abortar se houver erros
if [[ ${#ERROS[@]} -gt 0 ]]; then
    echo ""
    echo -e "  ${RED}INSTALACAO INTERROMPIDA — corrija os erros acima e execute novamente.${NC}"
    exit 1
fi

# ─────────────────────────────────────────────
#  PASSO 2 — CRIAR ESTRUTURA DE PASTAS
# ─────────────────────────────────────────────
step "2/5" "Criando estrutura de pastas..."

create_dir() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
        ok "Criada: $1"
    else
        info "Ja existe: $1"
    fi
}

create_dir "$DESTINO_SKILLS"
create_dir "$DESTINO_DOCS"
create_dir "$HOME/.claude"

if [[ "$MODO" == "install" ]]; then
    create_dir "$DESTINO_PROJETOS"
    create_dir "$DESTINO_PROJETOS/_TEMPLATE/codigo"
    create_dir "$DESTINO_PROJETOS/_TEMPLATE/documentacao"
    create_dir "$DESTINO_PROJETOS/_TEMPLATE/infraestrutura"
    create_dir "$DESTINO_PROJETOS/_TEMPLATE/relatorios"
    create_dir "$DESTINO_PROJETOS/_TEMPLATE/apresentacoes"
    create_dir "$DESTINO_PROJETOS/_TEMPLATE/reanalise/v1/evidencias"
    create_dir "$DESTINO_PROJETOS/_TEMPLATE/reanalise/v1/relatorios"
    create_dir "$DESTINO_PROJETOS/_TEMPLATE/reanalise/v1/apresentacoes"
fi

# ─────────────────────────────────────────────
#  PASSO 3 — INSTALAR SKILLS
# ─────────────────────────────────────────────
step "3/5" "Instalando skills do agente..."

for skill in "$ORIGEM_SKILLS"/*.md; do
    nome=$(basename "$skill")
    destino="$DESTINO_SKILLS/$nome"
    acao="Instalado"
    [[ -f "$destino" ]] && acao="Atualizado"
    if cp "$skill" "$destino"; then
        ok "$acao skill: $nome"
        ((COPIADOS++))
    else
        fail "Falha ao copiar skill: $nome"
    fi
done

# ─────────────────────────────────────────────
#  PASSO 4 — INSTALAR DOCUMENTOS
# ─────────────────────────────────────────────
step "4/5" "Instalando documentos do processo..."

for doc in "$ORIGEM_DOCS_DIR"/*; do
    nome=$(basename "$doc")
    destino="$DESTINO_DOCS/$nome"
    acao="Instalado"
    [[ -f "$destino" ]] && acao="Atualizado"
    if cp "$doc" "$destino"; then
        ok "$acao doc: $nome"
        ((COPIADOS++))
    else
        warn "Falha ao copiar: $nome"
    fi
done

# ─────────────────────────────────────────────
#  PASSO 5 — VALIDACAO FINAL
# ─────────────────────────────────────────────
step "5/5" "Validando instalacao..."

FALHAS_VAL=0
check_file() {
    if [[ -f "$1" ]]; then
        ok "$2"
    else
        fail "NAO ENCONTRADO: $2"
        ((FALHAS_VAL++))
    fi
}

check_file "$DESTINO_SKILLS/relatorio-fabrica.md"          "Skill /relatorio-fabrica"
check_file "$DESTINO_SKILLS/reanalise-fabrica.md"          "Skill /reanalise-fabrica"
check_file "$DESTINO_DOCS/CHECKLIST_SEGURANCA_PROJETOS.md" "Checklist de analise"
check_file "$DESTINO_DOCS/CHECKLIST_REANALISE_PROJETOS.md" "Checklist de reanalise"
check_file "$DESTINO_DOCS/RUNBOOK_AGENTE_SEGURANCA.md"     "Runbook do agente"
check_file "$DESTINO_DOCS/apresentacao_time_seguranca.html" "Apresentacao do time"

# ─────────────────────────────────────────────
#  RESUMO FINAL
# ─────────────────────────────────────────────
echo ""
echo -e "  ${DARKGRAY}─────────────────────────────────────────────────────────${NC}"
echo ""

if [[ ${#ERROS[@]} -eq 0 && "$FALHAS_VAL" -eq 0 ]]; then
    echo -e "  ${GREEN}INSTALACAO CONCLUIDA COM SUCESSO${NC}"
    echo ""
    echo -e "  ${WHITE}$COPIADOS arquivo(s) instalado(s)/atualizado(s)${NC}"
    echo ""
    echo -e "  ${CYAN}Proximos passos:${NC}"
    echo -e "  ${WHITE}1. Abra o terminal na pasta de um projeto${NC}"
    echo -e "  ${WHITE}2. Execute: npx claude-code-templates@latest --agent devops-infrastructure/security-engineer${NC}"
    echo -e "  ${WHITE}3. Para analise: siga o Runbook (Passos 0 a 7)${NC}"
    echo -e "  ${WHITE}4. Para reanalise: use /reanalise-fabrica no agente${NC}"
    echo -e "  ${WHITE}5. Para apresentacoes: use /relatorio-fabrica no agente${NC}"
    echo ""
    echo -e "  Documentos em : ${CYAN}$DESTINO_DOCS${NC}"
    echo -e "  Skills em     : ${CYAN}$DESTINO_SKILLS${NC}"
    if [[ "$MODO" == "install" ]]; then
        echo -e "  Projetos em   : ${CYAN}$DESTINO_PROJETOS${NC}"
        echo -e "  Template em   : ${CYAN}$DESTINO_PROJETOS/_TEMPLATE${NC}"
    fi
elif [[ ${#ERROS[@]} -eq 0 ]]; then
    echo -e "  ${YELLOW}INSTALACAO CONCLUIDA COM AVISOS${NC}"
    for a in "${AVISOS[@]}"; do warn "$a"; done
else
    echo -e "  ${RED}INSTALACAO CONCLUIDA COM ERROS${NC}"
    for e in "${ERROS[@]}"; do fail "$e"; done
    echo ""
    echo -e "  ${RED}Corrija os erros acima e execute o script novamente.${NC}"
fi

echo ""
echo -e "  ${DARKGRAY}─────────────────────────────────────────────────────────${NC}"
echo ""
