---
description: Gera duas apresentacoes HTML para a fabrica de software apos a analise de seguranca: (1) apresentacao de vulnerabilidades encontradas e (2) apresentacao de sugestoes de melhorias com roadmap. Usar apos concluir todos os 5 passos de analise do runbook. Precisa dos relatorios gerados nas fases anteriores.
---

# Skill: Relatorio para a Fabrica de Software

Este skill gera automaticamente duas apresentacoes HTML profissionais baseadas nos relatorios de analise de seguranca do projeto. Execute os prompts abaixo em sequencia no agente de seguranca.

---

## PRE-CONDICAO

Antes de executar este skill, confirme que os seguintes arquivos existem:

- `relatorios/00_RELATORIO_EXECUTIVO.md`
- `relatorios/01_analise_codigo.md`
- `relatorios/02_analise_documentacao.md`
- `relatorios/03_analise_infraestrutura.md`
- `relatorios/04_threat_modeling.md`

Se algum estiver faltando, volte ao runbook e complete a fase correspondente primeiro.

---

## PROMPT 1 — GERAR APRESENTACAO DE VULNERABILIDADES

Cole este prompt completo no agente de seguranca:

```
Leia todos os relatorios na pasta relatorios/ (00 ao 04).

Com base nos achados reais encontrados, gere um arquivo HTML completo chamado
"apresentacoes/apresentacao_vulnerabilidades.html" com uma apresentacao de slides
profissional para ser entregue a fabrica de software.

A apresentacao deve ter visual escuro e moderno (similar ao padrao de seguranca),
navegacao por teclado (setas) e barra de progresso.

Estrutura obrigatoria dos slides:

SLIDE 1 - CAPA
- Titulo: "Relatorio de Vulnerabilidades — [NOME DO PROJETO]"
- Subtitulo: "Analise de Seguranca realizada pela Coordenacao de Seguranca"
- Data da analise
- Badge com o parecer final (APROVADO / APROVADO COM RESSALVAS / REPROVADO)
  com cor correspondente (verde / amarelo / vermelho)

SLIDE 2 - SUMARIO EXECUTIVO
- Paragrafo de resumo da analise (nao tecnico, para gestao)
- 4 cards com contadores reais: total Critico, Alto, Medio, Baixo
- Parecer final destacado com justificativa em 2 linhas

SLIDE 3 - DISTRIBUICAO DOS ACHADOS
- Grafico visual em barras horizontais (CSS puro) mostrando quantidade por severidade
- Distribuicao por categoria (Codigo / Documentacao / Infraestrutura / Threat Model)
- Percentual de itens do checklist atendidos vs nao atendidos

SLIDE 4 - MATRIZ DE RISCO
- Grid 3x3 ou 4x4 de probabilidade (baixa/media/alta) x impacto (baixo/medio/alto/critico)
- Cada achado posicionado como um ponto/badge na matriz
- Legenda de cores (verde=baixo, amarelo=medio, laranja=alto, vermelho=critico)

SLIDES 5 em diante - UM SLIDE POR ACHADO CRITICO E ALTO
Para cada achado critico ou alto, criar um slide individual com:
- ID do achado (ex: VUL-001)
- Badge de severidade colorido
- Titulo descritivo da vulnerabilidade
- Componente afetado (arquivo, endpoint, servico de infra)
- Descricao tecnica do problema em linguagem clara
- Impacto potencial se explorado
- Evidencia (arquivo:linha ou trecho de configuracao anonimizado)
- CWE ou OWASP category se aplicavel

SLIDE - RESUMO DOS ACHADOS MEDIOS
- Tabela com todos os achados medios: ID, titulo, componente, recomendacao resumida

SLIDE - RESUMO DOS ACHADOS BAIXOS E INFO
- Tabela compacta com ID, titulo e status

SLIDE FINAL - PROXIMOS PASSOS
- 3 acoes imediatas requeridas (antes do deploy se reprovado, ou pos-deploy se aprovado)
- Contato do time de seguranca para duvidas
- Mensagem de encerramento profissional

REQUISITOS TECNICOS DO HTML:
- Todo CSS inline no <style> tag, sem dependencias externas
- Navegacao: setas do teclado, ESC para fullscreen
- Barra de progresso na base
- Contador de slides (ex: "03 / 12")
- Responsivo para tela cheia
- Paleta: fundo #0a0e1a, critico #ef4444, alto #f97316, medio #f59e0b, baixo #3b82f6, info #00d4a1
- Tipografia: Segoe UI ou system-ui
- Sem emojis — usar simbolos unicode (&#9888; etc)

Substitua todos os dados pelos achados reais dos relatorios.
Nao invente vulnerabilidades — use apenas o que foi documentado.
Salve o arquivo em: apresentacoes/apresentacao_vulnerabilidades.html
```

---

## PROMPT 2 — GERAR APRESENTACAO DE MELHORIAS E ROADMAP

Cole este prompt completo no agente de seguranca:

```
Leia todos os relatorios na pasta relatorios/ (00 ao 04).

Com base nas recomendacoes reais encontradas, gere um arquivo HTML completo chamado
"apresentacoes/apresentacao_melhorias_roadmap.html" com uma apresentacao de slides
profissional orientada a solucoes para a fabrica de software.

Esta apresentacao deve ter tom CONSTRUTIVO — o objetivo e mostrar o caminho
para corrigir e evoluir a maturidade de seguranca do projeto, nao apenas apontar erros.

Visual: tons de verde e azul sobre fundo escuro, transmitindo progresso e solucao.
Navegacao por teclado (setas), barra de progresso, contador de slides.

Estrutura obrigatoria dos slides:

SLIDE 1 - CAPA
- Titulo: "Plano de Melhorias e Roadmap de Seguranca"
- Subtitulo: "[NOME DO PROJETO] — Coordenacao de Seguranca"
- Data
- Tag: "Orientado a Solucoes"

SLIDE 2 - VISAO GERAL DO PLANO
- Resumo em texto: quantas melhorias foram identificadas no total
- 3 pilares das melhorias (Codigo Seguro / Infraestrutura / Processos)
- Frase motivacional sobre seguranca como qualidade de software

SLIDE 3 - COMO LER ESTE PLANO
- Explicacao das 4 fases do roadmap:
  FASE 1 - Imediato (antes do deploy): correcoes criticas e altas
  FASE 2 - Curto prazo (ate 30 dias): correcoes medias
  FASE 3 - Medio prazo (ate 90 dias): melhorias baixas + boas praticas
  FASE 4 - Longo prazo (ate 6 meses): evolucao estrategica de maturidade
- Tabela: fase / prazo / tipo de item / responsavel sugerido

SLIDES 4 em diante - UM SLIDE POR MELHORIA CRITICA/ALTA
Para cada achado critico ou alto, criar um slide de SOLUCAO com:
- ID da melhoria (MEL-001, MEL-002...)
- Titulo: "Como corrigir: [nome da vulnerabilidade]"
- Problema resumido (1-2 linhas, sem repeticao do slide de vuln)
- Solucao recomendada passo a passo (numerada, pratica)
- Exemplo de codigo ou configuracao segura (em bloco de codigo estilizado)
- Esforco estimado: Horas / Dias
- Fase do roadmap: badge colorido (Fase 1 = vermelho, Fase 2 = amarelo, etc.)
- Responsavel sugerido: Dev Backend / Dev Frontend / DevOps / Arquiteto

SLIDE - MELHORIAS DE MEDIO PRAZO
- Tabela com as melhorias medias: ID, titulo, acao, esforco, responsavel

SLIDE - MELHORIAS DE LONGO PRAZO E EVOLUCAO ESTRATEGICA
- Lista de melhorias estruturais recomendadas:
  (ex: implementar SAST no CI/CD, adotar secret manager, treinamento OWASP,
  revisao periodica de dependencias, pen test anual, politica de senhas corporativa)
- Para cada item: descricao, beneficio esperado, esforco (P/M/G)

SLIDE - ROADMAP VISUAL (slide mais importante)
- Timeline horizontal com as 4 fases
- Cada fase em um bloco colorido com:
  - Nome e prazo
  - Lista de itens (IDs das melhorias) a realizar nessa fase
  - Barra de progresso visual mostrando o peso de esforco
- Linha do tempo na base mostrando semanas/meses
- Fases: Fase 1 (vermelho) / Fase 2 (amarelo) / Fase 3 (azul) / Fase 4 (verde)
- Visual tipo Gantt simplificado em CSS puro

SLIDE - METRICAS DE SUCESSO
- Indicadores para a fabrica acompanhar apos as correcoes:
  (ex: zero CVE critico em dependencias, cobertura de testes de seguranca > X%,
  tempo de resposta a incidentes < Y horas)
- Tabela: metrica / valor atual / meta / como medir

SLIDE - BOAS PRATICAS PARA OS PROXIMOS PROJETOS
- 5 a 7 praticas que a fabrica deve adotar desde o inicio de novos projetos
  (ex: threat modeling na fase de design, SAST no pipeline, secrets manager desde o dia 1,
  revisao de dependencias a cada sprint, headers de seguranca como padrao)
- Visual de cards em grade

SLIDE FINAL - COMPROMISSO CONJUNTO
- Mensagem de parceria entre seguranca e fabrica
- Tabela de responsabilidades: o que a fabrica faz, o que a seguranca faz
- Proxima data de revisao (sugerir 30 dias)
- Contato do time de seguranca

REQUISITOS TECNICOS DO HTML:
- Todo CSS inline no <style> tag, sem dependencias externas
- Navegacao: setas do teclado, ESC para fullscreen
- Barra de progresso na base
- Contador de slides
- Paleta de cores: fundo #0a0e1a, fase1 #ef4444, fase2 #f59e0b, fase3 #3b82f6, fase4 #22c55e
- Tipografia: Segoe UI ou system-ui
- O slide do roadmap visual deve ser o mais elaborado visualmente
- Blocos de codigo com syntax highlighting basico em CSS
- Sem emojis — usar simbolos unicode

Substitua todos os dados pelas recomendacoes reais dos relatorios.
Nao invente melhorias — derive tudo dos achados documentados.
Salve o arquivo em: apresentacoes/apresentacao_melhorias_roadmap.html
```

---

## RESULTADO ESPERADO

Apos executar os dois prompts, voce tera:

```
projetos/NOME_DO_PROJETO/
  apresentacoes/
    apresentacao_vulnerabilidades.html     <- para a reuniao de devolutiva
    apresentacao_melhorias_roadmap.html    <- para a reuniao de plano de acao
```

Abra cada arquivo diretamente no navegador. Nao e necessario servidor web.

---

## COMO USAR NAS REUNIOES

**Reuniao 1 — Devolutiva de Vulnerabilidades**
- Participantes: Time de seguranca + Tech Lead da fabrica + Gerente de projeto
- Use: `apresentacao_vulnerabilidades.html`
- Objetivo: Apresentar os achados, explicar o impacto e obter ciencia formal
- Ao final: Fabrica assina o recebimento do relatorio

**Reuniao 2 — Plano de Acao e Roadmap**
- Participantes: Time de seguranca + Desenvolvedores + DevOps + Gerente
- Use: `apresentacao_melhorias_roadmap.html`
- Objetivo: Alinhar as correcoes, definir responsaveis e prazos do roadmap
- Ao final: Roadmap aprovado e formalizado com datas e responsaveis
