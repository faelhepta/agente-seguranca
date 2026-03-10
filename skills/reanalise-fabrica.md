---
description: Executa a reanalise de seguranca apos a fabrica de software entregar as correcoes. Verifica se cada achado do relatorio original foi devidamente corrigido, identifica correcoes inadequadas e novos achados introduzidos pelas alteracoes. Usar apos receber o codigo corrigido e as evidencias da fabrica. Precisa do relatorio executivo original (00_RELATORIO_EXECUTIVO.md) e do codigo/infra corrigidos.
---

# Skill: Reanalise de Seguranca

Este skill conduz a verificacao das correcoes entregues pela fabrica de software.
Execute os prompts abaixo em sequencia dentro da pasta do projeto.

---

## PRE-CONDICAO

Antes de executar, confirme que existem:

**Da analise original:**
- `relatorios/00_RELATORIO_EXECUTIVO.md`
- `relatorios/01_analise_codigo.md`
- `relatorios/03_analise_infraestrutura.md`

**Da fabrica (correcoes entregues):**
- Codigo corrigido na pasta `codigo/` (substituir ou versionar)
- Evidencias da fabrica em `reanalise/evidencias/` (diffs, commits, documentos)

**Estrutura recomendada para a reanalise:**
```
projetos/NOME_DO_PROJETO/
  reanalise/
    v1/                        <- versionar cada rodada de reanalise
      evidencias/              <- documentos e diffs enviados pela fabrica
      relatorios/              <- relatorios gerados nesta reanalise
        RA_01_achados_criticos_altos.md
        RA_02_achados_medios.md
        RA_03_novos_achados.md
        RA_00_relatorio_reanalise.md
      apresentacoes/           <- opcional: apresentacao do resultado para a fabrica
        apresentacao_resultado_reanalise.html
```

---

## PROMPT 1 — VERIFICACAO DE ACHADOS CRITICOS E ALTOS

Cole este prompt no agente:

```
Leia o relatorio executivo original em relatorios/00_RELATORIO_EXECUTIVO.md
e os relatorios de fase em relatorios/01_analise_codigo.md e relatorios/03_analise_infraestrutura.md.

Em seguida, leia o codigo corrigido na pasta codigo/ e as evidencias em reanalise/v[N]/evidencias/.

Para cada achado com severidade CRITICO ou ALTO listado no relatorio original:

1. Identifique o arquivo, funcao ou componente que continha o problema
2. Verifique se a correcao foi implementada no codigo/configuracao atual
3. Avalie se a correcao e tecnicamente adequada (nao e apenas um patch superficial)
4. Verifique se a correcao introduziu novos problemas de seguranca na mesma area
5. Classifique com um dos status:
   - CORRIGIDO: problema eliminado corretamente
   - PARCIALMENTE CORRIGIDO: correcao existe mas esta incompleta ou tem limitacoes
   - NAO CORRIGIDO: problema persiste identico ao original
   - CORRECAO INADEQUADA: mudanca feita mas nao resolve o risco
   - NOVO ACHADO: a correcao introduziu vulnerabilidade nova
   - NAO VERIFICAVEL: impossivel verificar sem evidencia ou acesso adicional

Para cada achado, gere um bloco com:
- ID original (ex: VUL-001)
- Titulo original
- O que foi encontrado no codigo/infra atual
- Status (da lista acima)
- Justificativa tecnica do status atribuido
- Se NOVO ACHADO: descricao completa do novo problema encontrado

Ao final, gere uma tabela resumo com todos os achados criticos e altos e seus status.

Salve em: reanalise/v[N]/relatorios/RA_01_achados_criticos_altos.md
```

---

## PROMPT 2 — VERIFICACAO DE ACHADOS MEDIOS

Cole este prompt no agente:

```
Com base no relatorio original em relatorios/00_RELATORIO_EXECUTIVO.md,
identifique todos os achados com severidade MEDIO.

Para cada achado medio:
1. Verifique a data acordada para correcao (conforme roadmap da apresentacao anterior)
2. Verifique se a correcao foi implementada no codigo/configuracao atual
3. Se ainda dentro do prazo: verifique se ha evidencia de trabalho em andamento
4. Classifique com o mesmo sistema de status (CORRIGIDO / PARCIALMENTE / NAO CORRIGIDO / etc.)

Considere que achados medios tem prazo de 30 dias apos o deploy.
Se o prazo ja venceu e o achado nao foi corrigido, sinalize como VENCIDO NAO CORRIGIDO.

Gere tabela com: ID, titulo, prazo acordado, status atual, observacao.

Salve em: reanalise/v[N]/relatorios/RA_02_achados_medios.md
```

---

## PROMPT 3 — VARREDURA DE NOVOS ACHADOS NAS AREAS MODIFICADAS

Cole este prompt no agente:

```
Com base nas evidencias em reanalise/v[N]/evidencias/ (diffs e commits),
identifique quais arquivos e componentes foram modificados pela fabrica.

Para cada area modificada, realize uma analise de seguranca focada:
- As mudancas introduziram novos vetores de ataque?
- Foram adicionadas novas dependencias? Se sim, verificar CVEs.
- Foram feitas alteracoes de permissoes, autenticacao ou autorizacao?
- Novos endpoints ou rotas foram criados?
- Configuracoes de infraestrutura foram alteradas alem do necessario?

Tambem verifique:
- Se foram adicionados novos hardcoded secrets ou tokens
- Se novos arquivos .env ou de configuracao foram adicionados ao repositorio
- Se o escopo das mudancas vai alem das correcoes acordadas

Para cada novo achado encontrado, informe:
- ID novo (NEW-001, NEW-002...)
- Arquivo e linha
- Descricao tecnica
- Severidade (Critico/Alto/Medio/Baixo)
- Como surgiu (introducao direta, efeito colateral, mudanca de escopo)

Se nenhum novo achado for identificado, declare explicitamente:
"Nenhum novo achado identificado nas areas modificadas."

Salve em: reanalise/v[N]/relatorios/RA_03_novos_achados.md
```

---

## PROMPT 4 — RELATORIO CONSOLIDADO DE REANALISE

Cole este prompt no agente:

```
Com base nos tres relatorios gerados (RA_01, RA_02, RA_03),
gere o RELATORIO CONSOLIDADO DE REANALISE v[N] contendo:

1. CABECALHO
   - Nome do projeto
   - Numero desta reanalise (ex: Reanalise v1)
   - Data da analise original e data desta reanalise
   - Analista responsavel

2. RESUMO DA SITUACAO
   - Quantos achados foram verificados no total
   - Tabela de contagem por status:
     | Severidade | Total | Corrigido | Parc. Corrigido | Nao Corrigido | Correcao Inadequada | Novo Achado |
   - Percentual de resolucao dos achados criticos e altos

3. DETALHAMENTO DOS NAO CORRIGIDOS E CORRECOES INADEQUADAS
   - Para cada achado nao corrigido ou com correcao inadequada:
     - ID, titulo, severidade
     - O que foi feito vs o que era necessario
     - Risco que permanece ativo

4. NOVOS ACHADOS INTRODUZIDOS (se houver)
   - Listagem completa com severidade e descricao

5. PARECER DA REANALISE
   Aplique os criterios abaixo:

   APROVADO se:
   - Todos os achados criticos estao CORRIGIDO
   - Todos os achados altos estao CORRIGIDO
   - Nenhum novo achado critico ou alto foi introduzido

   APROVADO COM RESSALVAS se:
   - Todos os criticos estao CORRIGIDO
   - Altos: CORRIGIDO ou PARCIALMENTE CORRIGIDO (com justificativa)
   - Novos achados, se houver, sao apenas medios ou baixos
   - Plano de correcao para pendencias foi formalizado

   REPROVADO se:
   - Qualquer critico nao esta CORRIGIDO
   - Alto com status NAO CORRIGIDO ou CORRECAO INADEQUADA
   - Novo achado critico ou alto introduzido pelas correcoes
   - Evidencias insuficientes para verificacao

   Declare o parecer com justificativa e, se REPROVADO, liste o que deve ser
   corrigido antes da proxima reanalise (Reanalise v[N+1]).

6. PROXIMOS PASSOS
   - Se APROVADO: instrucoes para liberar o deploy
   - Se APROVADO COM RESSALVAS: itens pendentes com prazos renovados
   - Se REPROVADO: lista do que deve ser feito antes da reanalise v[N+1]

Formato: Markdown bem estruturado.
Salve em: reanalise/v[N]/relatorios/RA_00_relatorio_reanalise.md
```

---

## PROMPT 5 (OPCIONAL) — APRESENTACAO DO RESULTADO DA REANALISE

Use este prompt apenas se quiser gerar uma apresentacao HTML para a reuniao de resultado:

```
Leia o relatorio consolidado de reanalise em reanalise/v[N]/relatorios/RA_00_relatorio_reanalise.md.

Gere um arquivo HTML de apresentacao de slides com visual profissional (fundo escuro,
navegacao por setas, barra de progresso, contador de slides) para apresentar o resultado
da reanalise a fabrica de software.

Estrutura dos slides:

SLIDE 1 - CAPA
- Titulo: "Resultado da Reanalise de Seguranca — [NOME DO PROJETO] — v[N]"
- Data
- Badge com o parecer (APROVADO verde / APROVADO COM RESSALVAS amarelo / REPROVADO vermelho)

SLIDE 2 - COMPARATIVO: ANALISE ORIGINAL vs REANALISE
- Tabela lado a lado mostrando achados originais x status atual
- Grafico visual de barras: "de X achados, Y foram corrigidos"

SLIDE 3 - ACHADOS RESOLVIDOS
- Lista dos achados confirmados como CORRIGIDO com destaque positivo
- Mensagem de reconhecimento pelo trabalho de correcao

SLIDE 4 - ACHADOS PENDENTES (se houver)
- Um bloco por achado nao corrigido ou com correcao inadequada
- O que falta para resolver
- Impacto que permanece ativo

SLIDE 5 - NOVOS ACHADOS (se houver)
- Listagem com severidade e descricao

SLIDE 6 - PARECER FINAL
- Resultado com justificativa clara
- Proximos passos especificos

Sem emojis — usar simbolos unicode. CSS inline, sem dependencias externas.
Salve em: reanalise/v[N]/apresentacoes/apresentacao_resultado_reanalise.html
```

---

## CRITERIOS RAPIDOS DE DECISAO

```
TODOS criticos e altos = CORRIGIDO       → APROVADO
TODOS criticos = CORRIGIDO
+ algum alto = PARCIALMENTE CORRIGIDO   → APROVADO COM RESSALVAS
                                          (coordenador decide)
QUALQUER critico != CORRIGIDO            → REPROVADO
QUALQUER alto = NAO CORRIGIDO            → REPROVADO
NOVO ACHADO critico ou alto encontrado   → REPROVADO
Evidencias insuficientes para verificar  → REPROVADO (solicitar complemento)
```

---

## NUMERO DE RODADAS E ESCALADA

- **v1:** primeira reanalise — normal
- **v2:** segunda reanalise — notificar gestor da fabrica formalmente
- **v3 ou mais:** escalar para coordenador de seguranca + gestor da fabrica + gestor de TI
  Considerar suspensao do projeto ate resolucao.
