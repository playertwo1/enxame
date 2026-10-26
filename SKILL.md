---
name: enxame
description: >-
  Orquestração de enxame multi-agente hiper-eficiente com baixo consumo de tokens.
  Divide tarefas por porte, dispara makers em paralelo com escopo isolado,
  filtra via validação local determinística (zero tokens) e convoca banca examinadora
  condicional (Auditoria, Qualidade, Estética/UX) orientada a git diff e SOPs fechados.
---

# Enxame: Orquestração Multi-Agente Hiper-Econômica

O **Enxame** é um framework de execução concorrente de agentes projetado para **máxima velocidade e economia cirúrgica de tokens**. Ele substitui a desordem de agentes autônomos conversacionais por um pipeline estruturado inspirado nas melhores práticas da **Anthropic** (*Orchestrator-Workers & Evaluator-Optimizer*), **Google DeepMind** (*Context Caching & Signal Isolation*) e pesquisas de ponta como o **Agentless** (SWE-bench).

---

## 1. As 5 Leis Fundamentais do Enxame

1. **Zero Leitura Dupla & Localização Hierárquica:** O Maker nunca faz varredura cega no repositório. O Orquestrador determina a pasta/arquivo exato. O subagente lê apenas o bloco necessário.
2. **Filtro Determinístico Local (Zero Token de LLM):** Compiladores, linters e testes unitários locais rodam a custo zero. Se o build quebrou, **a banca examinadora não é chamada**.
3. **Auditoria Orientada a Diff:** A banca avaliadora **nunca abre arquivos inteiros**. Ela avalia exclusivamente o `git diff` limpo das alterações.
4. **Banca Condicional por SOP:** Subagentes de revisão não usam prompts abertos ("dê sua opinião"), e sim SOPs (*Standard Operating Procedures*) com perguntas fechadas (SIM/NÃO). Apenas áreas afetadas são instanciadas (ex: sem UI, sem Agente de Beleza).
5. **Circuit Breaker (Teto de 1 Reparo):** Se a banca reprovar, o feedback volta para o **mesmo Maker** (`send_message`). Máximo de 1 ciclo de reparo para impedir debates infinitos entre IAs.

---

## 2. Triagem de Porte & Matriz de Decisão

Antes de instanciar qualquer agente, o Orquestrador avalia o porte da tarefa:

| Porte | Condições | Fluxo de Ação |
| :--- | :--- | :--- |
| **Solo** (Trivial) | $\le$ 15 linhas, 1 arquivo ou tarefa mecânica | **Execução Direta pelo Orquestrador**. Zero subagentes. |
| **Duo** (Médio) | 1 funcionalidade coesa (1 a 3 arquivos) | **1 Maker (`flash`)** $\rightarrow$ Build local $\rightarrow$ **1 Auditor (`flash`)** via Diff. |
| **Enxame** (Grande) | Módulos independentes ou refatoração ampla | **Fase 0 (Contrato)** $\rightarrow$ **Makers em Paralelo** $\rightarrow$ **Banca Condicional**. |

---

## 3. Protocolo de Execução Passo a Passo

### Fase 0: Localização & Congelamento de Contrato (Contract-First)
Antes de disparar os makers em paralelo:
- Defina em 5 a 10 linhas os contratos de interface: nomes de funções, DTOs, rotas e tipos.
- Isole rigidamente o escopo de arquivos de cada Maker (ex: Maker A toca apenas `data/`, Maker B toca apenas `ui/`).

### Fase 1: Despacho Concorrente dos Makers
- Modelo: preferencialmente `flash` ou equivalente econômico.
- Limite de concorrência: **Máximo de 2 a 3 makers simultâneos** para evitar rate limits (429) e contenção de I/O.
- Prompt do Maker baseado em `templates/sop-maker.md`.
- Regra obrigatória: o Maker **deve rodar o comando local de teste/build antes de responder**.

### Fase 2: Extração de Diff & Gate Determinístico
Assim que os makers concluem:
1. O Orquestrador executa o script local:
   ```powershell
   powershell -ExecutionPolicy Bypass -File C:\Users\notefael\.gemini\config\skills\enxame\scripts\enxame-diff.ps1
   ```
2. Se o build/teste falhar, devolva o erro imediatamente para o Maker responsável via `send_message`.
3. Se o diff for minúsculo e trivial com testes passando: **Early Exit** ativado (entrega imediata, ignora Fase 3).

### Fase 3: Convocação da Banca Condicional (Paralela)
Dispare em paralelo **apenas** os auditores necessários, injetando **apenas o `git diff`**:
- **Auditor de Segurança e Lógica (`templates/sop-audit.md`):** Convocado se houve alteração de lógica, regras de negócio, dados, queries ou autenticação.
- **Guardião da Qualidade (`templates/sop-quality.md`):** Convocado se houve criação de contratos, integrações, APIs públicas ou novos fluxos.
- **Crítico de Estética e UX (`templates/sop-beauty.md`):** Convocado **exclusivamente** se houve alteração em telas, componentes de UI, estilos, CSS, Compose ou layouts.

### Fase 4: Avaliação & Circuit Breaker
- Cada auditor responde estritamente:
  ```text
  STATUS: PASS | FAIL
  MOTIVO: [arquivo:linha] Descrição pontual do problema (se houver)
  ```
- **Se todos PASS:** O Orquestrador consolida e entrega ao usuário.
- **Se FAIL (1ª vez):** Repassa o motivo em 2 linhas para o Maker original corrigir.
- **Se FAIL (2ª vez):** Circuit Breaker. O Orquestrador arbitra e decide se aprova com ressalva ou consulta o usuário.

---

## 4. Integração de Memória

- **Memória de Voo (Curto Prazo):** Durante a execução, estados e vereditos são mantidos no contexto do Orquestrador ou salvos temporariamente em `scratch/enxame-ledger.json`.
- **Memória Permanente (Longo Prazo):** Padrões arquiteturais aprendidos ou correções recorrentes são consolidados diretamente no **Hindsight** (`hindsight_reflect`) ou no **NexusVault (Obsidian)**. Não crie arquivos soltos de memória fora dos sistemas oficiais.
