# GUIA DE INSTALACAO — AGENTE DE SEGURANCA
## Coordenacao de Seguranca de TI | v1.0

---

## O QUE ESTE PACOTE INSTALA

| O que | Onde fica na maquina |
|-------|----------------------|
| Skill `/relatorio-fabrica` | `%USERPROFILE%\.claude\skills\` |
| Skill `/reanalise-fabrica` | `%USERPROFILE%\.claude\skills\` |
| Checklist de analise | `%USERPROFILE%\Documents\Seguranca-TI\` |
| Checklist de reanalise | `%USERPROFILE%\Documents\Seguranca-TI\` |
| Runbook do agente | `%USERPROFILE%\Documents\Seguranca-TI\` |
| Apresentacao do time | `%USERPROFILE%\Documents\Seguranca-TI\` |
| Pasta template de projetos | `%USERPROFILE%\Documents\projetos\_TEMPLATE\` |

---

## PRE-REQUISITOS

Antes de rodar o instalador, verifique:

### 1. Node.js 18 ou superior

```powershell
node --version
# deve retornar v18.x.x ou maior
```

Se nao tiver ou estiver desatualizado, baixe em: https://nodejs.org

### 2. Claude Code

```powershell
claude --version
```

Se o comando nao existir:
```powershell
npm install -g @anthropic-ai/claude-code
```

### 3. Autenticacao Claude Code ativa

```powershell
claude auth status
```

Se nao estiver autenticado, solicite a chave de API ao coordenador e configure com:
```powershell
claude auth login
```

---

## ESTRUTURA DO PACOTE

```
seguranca-ti/                      <- pasta do repositorio (nome pode variar)
  instalar.ps1                     <- script principal (Windows PowerShell)
  instalar.sh                      <- script alternativo (Git Bash / WSL)
  GUIA_INSTALACAO.md               <- este arquivo
  README.md
  skills/
    relatorio-fabrica.md
    reanalise-fabrica.md
  docs/
    CHECKLIST_SEGURANCA_PROJETOS.md
    CHECKLIST_REANALISE_PROJETOS.md
    RUNBOOK_AGENTE_SEGURANCA.md
    TUTORIAL_RODAR_ANALISE.md
    apresentacao_time_seguranca.html
    rodar_analise.ps1              <- script de automacao (Windows)
    rodar_analise.sh               <- script de automacao (Linux/WSL)
  extras/
    analisar.ps1                   <- analise interativa (pede caminho)
    analisar.sh
    gerar_apresentacoes.ps1        <- regenera apenas as apresentacoes HTML
    analisar_api.ps1
```

---

## INSTALACAO — PASSO A PASSO

### Opcao A: PowerShell (recomendado no Windows)

**1. Abra o PowerShell como usuario normal** (nao precisa de administrador)

**2. Va ate a pasta do pacote:**
```powershell
cd "C:\caminho\para\Seguranca-TI-Setup"
```

**3. Libere a execucao do script (necessario uma unica vez):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
> Isso autoriza scripts locais para o seu usuario. Nao afeta outros usuarios da maquina.

**4. Execute o instalador:**
```powershell
.\instalar.ps1
```

**5. Aguarde o resumo final.**
Um resultado assim indica sucesso:
```
  INSTALACAO CONCLUIDA COM SUCESSO

  12 arquivo(s) instalado(s)/atualizado(s)

  Proximos passos:
  1. Abra o terminal na pasta de um projeto
  2. Execute: npx claude-code-templates@latest --agent devops-infrastructure/security-engineer
  ...
```

---

### Opcao B: Git Bash ou WSL

**1. Abra o Git Bash**

**2. Va ate a pasta do pacote:**
```bash
cd "/c/caminho/para/Seguranca-TI-Setup"
```

**3. Torne o script executavel e rode:**
```bash
chmod +x instalar.sh
bash instalar.sh
```

---

## ATUALIZANDO (quando o coordenador liberar uma nova versao)

Quando houver atualizacao nos skills ou documentos, o coordenador enviara um novo pacote.
Execute o instalador com a flag `--update` — ela so atualiza os arquivos, sem recriar a pasta de projetos:

```powershell
# PowerShell
.\instalar.ps1 -Modo update

# ou Git Bash
bash instalar.sh --update
```

---

## INSTALANDO A PARTIR DE PASTA DE REDE

Se o pacote estiver em um servidor compartilhado, voce pode apontar o script para ele:

```powershell
# PowerShell — pasta de rede
.\instalar.ps1 -OrigemDocs "\\servidor\TI\Seguranca-TI-Setup"

# Git Bash — pasta de rede mapeada
bash instalar.sh --origem "//servidor/TI/Seguranca-TI-Setup"
```

---

## VERIFICACAO POS-INSTALACAO

Verifique manualmente se tudo foi instalado:

```powershell
# Verificar skills
ls "$env:USERPROFILE\.claude\skills" | Where-Object {$_.Name -like "*fabrica*" -or $_.Name -like "*reanalise*"}

# Verificar documentos
ls "$env:USERPROFILE\Documents\Seguranca-TI"

# Verificar template de projetos
ls "$env:USERPROFILE\Documents\projetos\_TEMPLATE"
```

---

## TESTANDO O AGENTE

Apos a instalacao, teste se o agente e os skills estao funcionando:

**1. Crie uma pasta de teste:**
```powershell
mkdir "$env:USERPROFILE\Documents\projetos\TESTE"
cd "$env:USERPROFILE\Documents\projetos\TESTE"
```

**2. Inicie o agente:**
```powershell
npx claude-code-templates@latest --agent devops-infrastructure/security-engineer
```

**3. Quando o agente iniciar, teste os skills:**
```
/relatorio-fabrica
```
e
```
/reanalise-fabrica
```

Se ambos exibirem os prompts, a instalacao esta correta.

---

## PROBLEMAS FREQUENTES

| Problema | Causa provavel | Solucao |
|----------|---------------|---------|
| `instalar.ps1 nao pode ser carregado` | ExecutionPolicy bloqueando | Execute `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| `claude: command not found` | Claude Code nao instalado | `npm install -g @anthropic-ai/claude-code` |
| `node: command not found` | Node.js nao instalado ou nao esta no PATH | Reinstale o Node.js marcando "Add to PATH" |
| Skills nao aparecem no agente | Arquivos foram copiados para pasta errada | Verifique se estao em `%USERPROFILE%\.claude\skills\` |
| Agente nao inicia | Autenticacao expirada | `claude auth login` |
| `npx` demora muito | Cache do npx vazio | Normal na primeira execucao, aguarde |

---

## SUPORTE

Em caso de problemas nao listados acima, entre em contato com o **Coordenador de Seguranca** informando:
- Mensagem de erro completa
- Resultado de `node --version` e `claude --version`
- Sistema operacional e versao do Windows

---

## USANDO A AUTOMACAO COMPLETA

Apos a instalacao, o script `rodar_analise.ps1` (ou `.sh`) executa todo o runbook automaticamente usando `claude -p` em modo nao-interativo. Ele roda todos os prompts das fases 1 a 7 e salva os relatorios na pasta certa.

### Uso basico

```powershell
# Analise completa (fases 1 a 7)
.\rodar_analise.ps1 -Projeto "SistemaRH"

# Apenas uma fase especifica
.\rodar_analise.ps1 -Projeto "SistemaRH" -Fase codigo
.\rodar_analise.ps1 -Projeto "SistemaRH" -Fase infra

# Reanalise apos correcoes da fabrica
.\rodar_analise.ps1 -Projeto "SistemaRH" -Fase reanalise -Versao v1

# Ver o que seria executado sem rodar de fato
.\rodar_analise.ps1 -Projeto "SistemaRH" -DryRun
```

### O que a automacao faz vs o que exige revisao humana

| Automatizado pelo script | Obrigatorio pelo analista |
|--------------------------|--------------------------|
| Roda todos os prompts das fases 1-7 | Revisar os relatorios gerados |
| Salva cada relatorio no arquivo certo | Validar achados (falsos positivos) |
| Gera as 2 apresentacoes HTML | Preencher o checklist |
| Executa a reanalise completa (R1-R4) | Assinar o parecer final |
| Exibe tempo de cada fase | Apresentar para a fabrica |

> O agente pode ter falsos positivos ou deixar de identificar algo. A revisao humana e insubstituivel para o parecer final.

---

## HISTORICO DE VERSOES

| Versao | Data | Mudancas |
|--------|------|----------|
| 1.0 | 2026-03 | Versao inicial — skills relatorio-fabrica e reanalise-fabrica |
