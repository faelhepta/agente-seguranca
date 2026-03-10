# CHECKLIST DE REANALISE — VERIFICACAO DE CORRECOES
## Coordenacao de Seguranca | Fabrica de Software

---

## INFORMACOES DA REANALISE

| Campo                        | Preenchimento                                      |
|------------------------------|----------------------------------------------------|
| Nome do Projeto              |                                                    |
| Numero da Reanalise          | v[ ] (ex: v1, v2...)                               |
| Analista Responsavel         |                                                    |
| Data da Analise Original     |                                                    |
| Parecer Original             | [ ] Reprovado  [ ] Aprovado com Ressalvas           |
| Data de Entrega das Correcoes|                                                    |
| Data de Inicio da Reanalise  |                                                    |
| Data de Conclusao            |                                                    |

---

## ARTEFATOS RECEBIDOS DA FABRICA PARA REANALISE

A fabrica DEVE entregar todos os itens abaixo antes do inicio da reanalise.
Reanalise sem evidencias nao sera aceita.

- [ ] Codigo fonte atualizado (versao corrigida)
- [ ] Lista de commits ou Pull Requests com as correcoes (link ou diff)
- [ ] Documento de evidencias de correcao por achado (descricao do que foi feito)
- [ ] Evidencias de testes realizados apos as correcoes (prints, logs, resultados)
- [ ] Declaracao do responsavel tecnico confirmando que todos os achados foram endereados

**Artefatos opcionais mas recomendados:**
- Resultados de scan automatizado (SAST, dependencias) rodados pela propria fabrica
- Cobertura de testes de seguranca implementados

> Se qualquer artefato obrigatorio estiver ausente, devolver a fabrica com solicitacao
> de complemento. Nao iniciar a reanalise com documentacao incompleta.

---

## LEGENDA DE STATUS DE CORRECAO

| Status                  | Significado                                                                 |
|-------------------------|-----------------------------------------------------------------------------|
| CORRIGIDO               | A correcao foi implementada corretamente e o achado nao e mais exploravel   |
| PARCIALMENTE CORRIGIDO  | A correcao foi feita mas esta incompleta ou introduz limitacoes             |
| NAO CORRIGIDO           | O achado ainda existe exatamente como estava                                |
| CORRECAO INADEQUADA     | Foi feita uma mudanca mas ela nao resolve o problema de seguranca           |
| NOVO ACHADO             | A correcao introduziu uma nova vulnerabilidade nao existente antes          |
| NAO VERIFICAVEL         | Nao foi possivel verificar por falta de evidencia ou acesso                 |

---

## PARTE 1 — VERIFICACAO DE ACHADOS CRITICOS

> Todos os achados criticos DEVEM estar com status CORRIGIDO para aprovacao.
> Qualquer outro status resulta em REPROVADO automaticamente.

| ID       | Titulo do Achado Original | Componente | Status da Correcao | Evidencia Verificada | Observacoes do Analista |
|----------|--------------------------|------------|--------------------|----------------------|-------------------------|
| VUL-001  |                          |            |                    |                      |                         |
| VUL-002  |                          |            |                    |                      |                         |
| VUL-003  |                          |            |                    |                      |                         |

**Adicionar linhas conforme necessario.**

### Detalhamento por Achado Critico

Para cada achado critico, preencher:

#### [ID do Achado] — [Titulo]
- **Vulnerabilidade original:** (descrever brevemente)
- **Correcao declarada pela fabrica:** (o que a fabrica disse que fez)
- **O que o analista verificou:** (o que foi realmente checado — arquivo, linha, configuracao)
- **A correcao resolve o problema?** [ ] Sim [ ] Nao [ ] Parcialmente
- **A correcao introduz novo problema?** [ ] Sim [ ] Nao
- **Status final:** _______________

---

## PARTE 2 — VERIFICACAO DE ACHADOS ALTOS

> Todos os achados altos DEVEM estar com status CORRIGIDO para aprovacao.
> Status PARCIALMENTE CORRIGIDO pode ser aceito com justificativa escrita do coordenador.

| ID       | Titulo do Achado Original | Componente | Status da Correcao | Evidencia Verificada | Observacoes do Analista |
|----------|--------------------------|------------|--------------------|----------------------|-------------------------|
| VUL-004  |                          |            |                    |                      |                         |
| VUL-005  |                          |            |                    |                      |                         |

---

## PARTE 3 — VERIFICACAO DE ACHADOS MEDIOS

> Achados medios devem estar corrigidos se o prazo de 30 dias ja transcorreu.
> Se ainda dentro do prazo, verificar se o plano de correcao esta sendo executado.

| ID       | Titulo do Achado Original | Prazo Acordado | Status da Correcao | Dentro do Prazo? | Observacoes |
|----------|--------------------------|----------------|--------------------|-----------------|-------------|
| VUL-006  |                          |                |                    | [ ] Sim [ ] Nao |             |
| VUL-007  |                          |                |                    | [ ] Sim [ ] Nao |             |

---

## PARTE 4 — VERIFICACAO DE ACHADOS BAIXOS E INFO

> Verificar apenas se houver compromisso formal de correcao registrado no roadmap.

| ID       | Titulo                   | Status           | Previsto no Roadmap? |
|----------|--------------------------|------------------|----------------------|
| VUL-008  |                          |                  | [ ] Sim [ ] Nao      |

---

## PARTE 5 — VERIFICACAO DE NOVOS ACHADOS

> As correcoes podem introduzir novas vulnerabilidades. Esta secao e obrigatoria.

#### 5.1 O agente identificou novos achados nas areas corrigidas?
- [ ] Nao — nenhum novo achado identificado nas areas modificadas
- [ ] Sim — novos achados encontrados (preencher tabela abaixo)

| ID Novo  | Titulo do Novo Achado | Componente | Severidade | Como Surgiu |
|----------|-----------------------|------------|------------|-------------|
| NEW-001  |                       |            |            |             |

#### 5.2 As correcoes alteraram o escopo de analise?
- [ ] Nao — as correcoes foram cirurgicas e limitadas aos achados
- [ ] Sim — foram feitas mudancas estruturais que exigem nova analise completa

> Se marcado SIM, avaliar com o coordenador se e necessario iniciar uma nova analise
> completa (Passos 1 a 5 do Runbook) ao inves de uma reanalise pontual.

---

## PARTE 6 — CHECKLIST DE QUALIDADE DA CORRECAO

Para cada area onde houve correcoes, verificar:

### Qualidade das correcoes de codigo
- [ ] A correcao segue boas praticas (nao e apenas um patch superficial)
- [ ] Nao foram adicionados novos hardcoded secrets
- [ ] Nao foram adicionadas novas dependencias vulneraveis
- [ ] Logs nao passaram a expor dados sensiveis apos as alteracoes
- [ ] Testes foram adicionados ou atualizados para cobrir os cenarios corrigidos

### Qualidade das correcoes de infraestrutura (se aplicavel)
- [ ] Regras de firewall/security group nao ficaram mais permissivas
- [ ] Credenciais rotacionadas apos exposicao confirmada
- [ ] Configuracoes de criptografia nao foram degradadas
- [ ] Monitoramento nao foi removido ou desabilitado

---

## PARTE 7 — RESUMO DA REANALISE

### Contagem de Status

| Severidade Original | Total de Achados | Corrigido | Parc. Corrigido | Nao Corrigido | Correcao Inadequada | Novo Achado |
|---------------------|-----------------|-----------|-----------------|---------------|---------------------|-------------|
| Critico             |                 |           |                 |               |                     |             |
| Alto                |                 |           |                 |               |                     |             |
| Medio               |                 |           |                 |               |                     |             |
| Baixo / Info        |                 |           |                 |               |                     |             |
| **Total**           |                 |           |                 |               |                     |             |

---

## PARTE 8 — CRITERIOS DE PARECER DA REANALISE

### APROVADO
Todos os criterios abaixo devem ser verdadeiros:
- [ ] Todos os achados criticos com status CORRIGIDO
- [ ] Todos os achados altos com status CORRIGIDO
- [ ] Nenhum NOVO ACHADO critico ou alto introduzido pelas correcoes
- [ ] As correcoes nao alteraram o escopo a ponto de exigir nova analise completa

### APROVADO COM RESSALVAS
Todos os criterios abaixo devem ser verdadeiros:
- [ ] Todos os achados criticos com status CORRIGIDO
- [ ] Achados altos com status CORRIGIDO ou PARCIALMENTE CORRIGIDO (com justificativa)
- [ ] Novos achados medios ou baixos introduzidos pelas correcoes (sem criticos/altos)
- [ ] Plano de correcao para os itens pendentes formalizado e aceito

### REPROVADO
Qualquer um dos itens abaixo resulta em reprovacao:
- [ ] Qualquer achado critico com status diferente de CORRIGIDO
- [ ] Achado alto com status NAO CORRIGIDO ou CORRECAO INADEQUADA sem aceite de risco
- [ ] Novo achado critico ou alto introduzido pelas correcoes
- [ ] Evidencias insuficientes para verificar as correcoes declaradas
- [ ] Mudancas estruturais que exigem nova analise completa

---

## PARECER FINAL DA REANALISE

**Resultado:**
- [ ] APROVADO
- [ ] APROVADO COM RESSALVAS
- [ ] REPROVADO — retorna para correcao (reanalise v[X+1] necessaria)

**Justificativa:**
```
[Descreva aqui o resultado e a justificativa do parecer desta reanalise]
```

**Condicoes para aprovacao (se reprovado):**
```
[Liste o que precisa ser corrigido antes da proxima reanalise]
```

**Numero da proxima reanalise (se reprovado):** v___

---

**Analista:**  ________________________________
**Data:**       ________________________________
**Aprovacao Coordenador:**  ____________________
