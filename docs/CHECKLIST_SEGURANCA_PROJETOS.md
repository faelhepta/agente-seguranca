# CHECKLIST DE SEGURANCA - ANALISE DE PROJETOS
## Coordenacao de Seguranca | Fabrica de Software

---

## INFORMACOES DO PROJETO

| Campo                  | Preenchimento                        |
|------------------------|--------------------------------------|
| Nome do Projeto        |                                      |
| Analista Responsavel   |                                      |
| Data de Inicio         |                                      |
| Data de Conclusao      |                                      |
| Versao do Checklist    | v1.0                                 |
| Classificacao do Risco | [ ] Critico [ ] Alto [ ] Medio [ ] Baixo |

---

## ARTEFATOS RECEBIDOS DA FABRICA

- [ ] Codigo Fonte (repositorio ou pacote)
- [ ] Documentacao tecnica (especificacoes, fluxos, DFD)
- [ ] Desenho de Infraestrutura (diagrama de rede, cloud, containers)
- [ ] Documento de requisitos de seguranca (se houver)

---

## FASE 1 — ANALISE DE CODIGO FONTE (SAST)

### 1.1 Autenticacao e Autorizacao
- [ ] Mecanismo de autenticacao implementado corretamente (JWT, OAuth2, session)
- [ ] Senhas armazenadas com hash seguro (bcrypt, argon2, scrypt)
- [ ] Controle de acesso baseado em roles/perfis (RBAC) aplicado
- [ ] Ausencia de credenciais hardcoded no codigo
- [ ] Tokens com tempo de expiracao definido
- [ ] Protecao contra brute force (rate limiting, lockout)
- [ ] Logout invalida sessao/token no servidor

### 1.2 Injecao e Validacao de Entrada
- [ ] Ausencia de SQL Injection (uso de prepared statements / ORM)
- [ ] Ausencia de Command Injection
- [ ] Ausencia de LDAP/XPath Injection
- [ ] Ausencia de SSTI (Server-Side Template Injection)
- [ ] Validacao e sanitizacao de todos os inputs do usuario
- [ ] Protecao contra XSS (encoding de output, CSP)
- [ ] Protecao contra XXE (XML External Entity)
- [ ] Protecao contra SSRF (Server-Side Request Forgery)

### 1.3 Controle de Acesso
- [ ] Ausencia de IDOR (Insecure Direct Object Reference)
- [ ] Verificacao de autorizacao em todas as rotas/endpoints
- [ ] Principio do menor privilegio aplicado
- [ ] Ausencia de funcionalidades administrativas expostas sem controle
- [ ] Upload de arquivos com validacao de tipo e tamanho

### 1.4 Criptografia e Dados Sensiveis
- [ ] Dados sensiveis em transito protegidos com TLS 1.2+
- [ ] Dados sensiveis em repouso criptografados
- [ ] Algoritmos criptograficos seguros (sem MD5, SHA1 para senhas, sem DES/RC4)
- [ ] Chaves e segredos gerenciados via cofre (Vault, AWS Secrets Manager, etc.)
- [ ] PII/dados pessoais identificados e protegidos (LGPD)
- [ ] Logs nao contem dados sensiveis (senhas, tokens, CPF, cartao)

### 1.5 Tratamento de Erros e Logging
- [ ] Mensagens de erro nao expoe stack trace ou informacoes internas
- [ ] Logs de segurança implementados (login, acesso negado, erros criticos)
- [ ] Sem informacoes sensiveis nos logs
- [ ] Logs com timestamp, usuario e IP registrados

### 1.6 Dependencias e Bibliotecas
- [ ] Dependencias auditadas (npm audit, pip-audit, OWASP Dependency Check)
- [ ] Ausencia de CVEs criticos ou altos nas dependencias
- [ ] Sem uso de bibliotecas abandonadas ou sem manutencao ativa
- [ ] Versoes fixadas (sem wildcards em versoes de producao)

### 1.7 Segurança da API
- [ ] Rate limiting implementado
- [ ] Headers de seguranca configurados (HSTS, X-Frame-Options, CSP, etc.)
- [ ] CORS configurado corretamente (sem wildcard * em producao)
- [ ] Verbos HTTP utilizados corretamente (GET nao modifica dados)
- [ ] Paginacao em endpoints de listagem (prevencao de mass data exposure)
- [ ] Autenticacao exigida em todos os endpoints sensiveis

### 1.8 Configuracao e Ambiente
- [ ] Secrets e configuracoes via variaveis de ambiente (nao em codigo)
- [ ] Arquivos .env excluidos do repositorio (.gitignore)
- [ ] Modo debug/verbose desabilitado em producao
- [ ] Nao ha rotas ou funcoes de teste expostas em producao

---

## FASE 2 — ANALISE DE DOCUMENTACAO

### 2.1 Arquitetura e Fluxo de Dados
- [ ] Diagrama de fluxo de dados (DFD) avaliado — fronteiras de confianca identificadas
- [ ] Todos os dados sensiveis mapeados e classificados
- [ ] Fluxo de autenticacao documentado e coerente com a implementacao
- [ ] Integrações com terceiros identificadas e avaliadas
- [ ] Dados transmitidos a terceiros mapeados (LGPD)

### 2.2 Requisitos de Seguranca
- [ ] Requisitos de seguranca estao documentados
- [ ] Classificacao de dados (publico, interno, confidencial, restrito) definida
- [ ] Politica de retencao de dados definida
- [ ] Procedimento de resposta a incidentes descrito

### 2.3 Autenticacao e Identidade (Documentacao)
- [ ] Fluxo de login/logout documentado
- [ ] Politica de senha documentada (comprimento, complexidade, expiracao)
- [ ] MFA documentado (se aplicavel)
- [ ] Processo de recuperacao de senha seguro e documentado

### 2.4 Integrações e APIs Externas
- [ ] Todas as APIs externas utilizadas identificadas
- [ ] Contratos/SLAs de segurança com terceiros documentados
- [ ] Dados enviados para terceiros minimizados (data minimization)

---

## FASE 3 — ANALISE DE INFRAESTRUTURA

### 3.1 Segmentacao de Rede
- [ ] Separacao entre zonas (DMZ, interna, dados)
- [ ] Banco de dados nao exposto diretamente para a internet
- [ ] Regras de firewall restritivas (whitelist, nao blacklist)
- [ ] WAF (Web Application Firewall) previsto
- [ ] Balanceador de carga com terminacao TLS configurado

### 3.2 Gerenciamento de Acesso (IAM)
- [ ] Principio do menor privilegio aplicado nas roles de cloud/servidor
- [ ] Acesso administrativo restrito e auditado
- [ ] MFA exigido para acesso administrativo
- [ ] Service accounts com permissoes minimas necessarias
- [ ] Rotacao de chaves e credenciais definida

### 3.3 Criptografia de Infraestrutura
- [ ] Volumes/discos criptografados em repouso
- [ ] Comunicacao interna entre servicos criptografada (mutual TLS ou equivalente)
- [ ] Certificados SSL/TLS validos e com renovacao automatica

### 3.4 Monitoramento e Deteccao
- [ ] Logs de infraestrutura habilitados (cloud trail, VPC flow logs, etc.)
- [ ] SIEM ou agregador de logs definido
- [ ] Alertas para eventos de segurança configurados
- [ ] Retencao de logs definida (minimo 90 dias, recomendado 1 ano)

### 3.5 Disponibilidade e Continuidade
- [ ] Estrategia de backup definida e testada
- [ ] RTO e RPO documentados
- [ ] Plano de DR (Disaster Recovery) existente
- [ ] Ausencia de SPOFs (Single Point of Failure) criticos

### 3.6 Containers e Orquestracao (se aplicavel)
- [ ] Imagens base oficiais e atualizadas
- [ ] Containers nao executam como root
- [ ] Secrets nao embutidos nas imagens Docker
- [ ] Politicas de segurança de pods (PodSecurityPolicy ou equivalente)
- [ ] Registry privado e com scan de vulnerabilidades

### 3.7 Exposicao de Servicos
- [ ] Portas de gerenciamento (SSH, RDP, DB) nao expostas para internet
- [ ] Inventario de portas e servicos exposto documentado
- [ ] Acesso remoto via VPN ou bastion host

---

## FASE 4 — MODELAGEM DE AMEACAS (THREAT MODELING)

### 4.1 Identificacao de Ativos Criticos
- [ ] Lista de ativos criticos levantada (dados, servicos, credenciais)
- [ ] Classificacao de criticidade por ativo

### 4.2 Superficies de Ataque
- [ ] Endpoints publicos mapeados
- [ ] Integrações externas mapeadas
- [ ] Vetores de entrada identificados (formularios, APIs, uploads, webhooks)

### 4.3 Analise STRIDE
- [ ] **S**poofing — ameacas de falsificacao de identidade analisadas
- [ ] **T**ampering — ameacas de adulteracao de dados analisadas
- [ ] **R**epudiation — rastros de auditoria presentes
- [ ] **I**nformation Disclosure — exposicao indevida de dados analisada
- [ ] **D**enial of Service — vetores de DOS/DDOS analisados
- [ ] **E**levation of Privilege — escalacao de privilegios analisada

### 4.4 Controles Mitigadores
- [ ] Cada ameaca identificada possui controle mitigador associado
- [ ] Riscos residuais documentados e aceitos formalmente

---

## FASE 5 — CLASSIFICACAO DE ACHADOS

### Matriz de Severidade

| ID  | Descricao do Achado | Fase | Severidade | Status | Responsavel |
|-----|---------------------|------|------------|--------|-------------|
|     |                     |      |            |        |             |

**Severidade:**
- **CRITICO** — Exploravel remotamente, impacto total, correcao obrigatoria antes do deploy
- **ALTO** — Alto impacto, correcao obrigatoria antes do deploy
- **MEDIO** — Correcao exigida dentro de 30 dias apos deploy
- **BAIXO** — Correcao recomendada no proximo ciclo de desenvolvimento
- **INFO** — Observacao ou melhoria de boas praticas

---

## FASE 6 — PARECER FINAL

### Resultado da Analise

- [ ] **APROVADO** — Nenhum achado critico ou alto. Sistema pode ir para producao.
- [ ] **APROVADO COM RESSALVAS** — Achados medios documentados. Deploy permitido com plano de correcao.
- [ ] **REPROVADO** — Achados criticos ou altos identificados. Deploy bloqueado ate correcao e reanalise.

### Justificativa do Parecer:

```
[Descreva aqui o resumo da analise e a justificativa do parecer]
```

### Proximos Passos:

```
[Liste as acoes requeridas com responsaveis e prazos]
```

---

**Analista:**  ________________________________
**Data:**       ________________________________
**Aprovacao Coordenador:**  ____________________
