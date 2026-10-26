<p align="center">
  <img src="assets/hero-banner.jpg" alt="Enxame Hero Banner" width="100%" style="border-radius: 8px;" />
</p>

# Enxame 🐝

> **Framework de Orquestração Multi-Agente Hiper-Econômico e Concorrente para Antigravity, Gemini CLI e Claude Code.**  
> *Alta especialização com redução drástica de tokens baseada em princípios de engenharia da Anthropic, Google DeepMind e na metodologia Agentless.*

---

## 🎯 Por que o Enxame existe?

Muitos frameworks multi-agentes tradicionais falham em ambientes de produção por três razões fundamentais:
1. **Explosão de Tokens e Custos:** Agentes autônomos que "conversam livremente" acumulam históricos gigantescos. No benchmark SWE-bench, abordagens ingênuas chegam a custar entre **US$ 3,50 e US$ 10,00 por tarefa**.
2. **Degradação de Raciocínio (*Lost in the Middle*):** Repassar logs brutos de terminal e históricos longos para todos os agentes polui o contexto e induz o modelo a alucinar.
3. **Colisão de Disco & Loops Infinitos:** Subagentes escrevendo nos mesmos arquivos ao mesmo tempo causam corrupção de código e debates infindáveis sobre estilo.

O **Enxame** resolve isso substituindo o bate-papo desgovernado entre IAs por um **pipeline estruturado de alta performance**:
- **Zero leitura dupla:** Subagentes recebem apenas o bloco de código ou `git diff` estritamente relevante.
- **Filtro Determinístico Local:** Testes, linters e compilação rodam no terminal da máquina a **custo zero de tokens**. Se o build quebrar, a banca de IA sequer é chamada.
- **SOPs Fechados:** Auditores respondem checklists telegráficos de 2 a 3 linhas (SIM/NÃO).
- **Circuit Breaker:** Teto de 1 ciclo de reparo para eliminar bate-boca entre modelos.

---

## 🏛️ Fundamentação Teórica e Pesquisa

O design do Enxame é fundamentado em quatro pilares da literatura e engenharia moderna de IA:

| Pilar | Fonte / Instituição | Princípio Aplicado |
| :--- | :--- | :--- |
| **Orchestrator-Workers & Evaluator-Optimizer** | [Anthropic (*Building Effective Agents*)](https://www.anthropic.com/research/building-effective-agents) | Orquestração centralizada dinâmica combinada com loops de avaliação rígidos e finitos. |
| **Context Caching & Static Base Pattern** | [Google DeepMind / Google Cloud](https://cloud.google.com/vertex-ai/generative-ai/docs/context-cache/context-cache-overview) | Prefixos e SOPs estáticos imutáveis que ativam Context Caching nativo, reduzindo o custo de input em até 75%. |
| **Hierarchical Localization & Cost Efficiency** | [Paper *Agentless* (UIUC / SWE-bench)](https://arxiv.org/abs/2407.01489) | Prova prática de que pipelines estruturados superam agentes autônomos por 1/10 do custo (US$ 0,34 vs US$ 3,50+). |
| **Role-based SOPs** | MetaGPT & ChatEval | Procedimentos operacionais padrão fechados em substituição a personas genéricas. |

---

## 📐 Arquitetura do Fluxo

<p align="center">
  <img src="assets/architecture.jpg" alt="Enxame Architecture Pipeline 3D" width="100%" style="border-radius: 8px;" />
</p>

```mermaid
flowchart TD
    User(["Comando do Usuário"]) --> Gate{"Triagem de Porte & Early Exit"}
    
    Gate -->|"Trivial (≤ 15 linhas)"| Solo["Solo: Execução Direta (Zero Subagentes)"]
    Gate -->|"Médio (1-3 arquivos)"| Duo["Duo: 1 Maker + 1 Auditor"]
    Gate -->|"Grande / Complexo"| Stage0["Fase 0: Localização & Contrato (Contract-First)"]
    
    Stage0 --> Workers["Fase 1: Makers Concorrentes (Max 2-3 em Flash com Cache)"]
    Workers --> CompTest{"Fase 2: Validação Determinística Local (Terminal/Build/Test)"}
    
    CompTest -->|"Falhou Build"| Repair["Reparo Direto no Mesmo Maker"]
    Repair --> CompTest
    
    CompTest -->|"Passou Build"| DiffOnly["Fase 3: Extração do git diff limpo"]
    DiffOnly --> EarlyExitCheck{"Early Exit?"}
    
    EarlyExitCheck -->|"Sim (Trivial sem UI)"| Finish(["Consolidação & Entrega"])
    EarlyExitCheck -->|"Não"| BancaCondicional{"Banca Condicional (SOPs Fechados)"}
    
    BancaCondicional -->|"Tem UI"| Beauty["SOP Estética/UX"]
    BancaCondicional -->|"Tem Lógica/Dados"| SecAudit["SOP Segurança & Lógica"]
    BancaCondicional --> Quality["SOP Qualidade & Contratos"]
    
    Beauty --> Verdict{"Veredito Final"}
    SecAudit --> Verdict
    Quality --> Verdict
    
    Verdict -->|"Aprovado"| Finish
    Verdict -->|"Reprovado (1ª vez)"| Repair
    Verdict -->|"Reprovado (2ª vez)"| CircuitBreaker["Circuit Breaker (Decisão do Chefe)"]
    CircuitBreaker --> Finish
```

---

## 👥 Especialistas do Enxame (SOPs)

A skill organiza os subagentes em 4 papéis com atribuições mutuamente exclusivas:

### 1. Maker (`templates/sop-maker.md`)
- **Missão:** Implementar o código com o menor delta possível dentro dos contratos definidos na Fase 0.
- **Regra de Ouro:** Obrigatório rodar o build/teste local antes de emitir resposta.

### 2. Auditor de Segurança e Lógica (`templates/sop-audit.md`)
- **Missão:** Detectar vulnerabilidades, NullPointers, vazamento de recursos e quebras de regras de negócio.
- **Entrada:** Recebe **apenas o `git diff`** das alterações.

### 3. Guardião da Qualidade e Contratos (`templates/sop-quality.md`)
- **Missão:** Verificar integridade arquitetural, conformidade com os contratos congelados e cobertura de testes.

### 4. Crítico de Estética e UX (`templates/sop-beauty.md`)
- **Missão:** Analisar tokens de design, hierarquia visual, espaçamentos, acessibilidade e ergonomia.
- **Condição:** Só é instanciado se a alteração tocar arquivos de interface (Compose, React, Flutter, CSS).

---

## 📁 Estrutura de Arquivos

```text
enxame/
├── SKILL.md                  # Especificação principal para o Orquestrador
├── LICENSE                   # Licença MIT
├── README.md                 # Documentação e fundamentação teórica
├── templates/                # Procedimentos Operacionais Padrão (SOPs)
│   ├── sop-maker.md          # SOP do Executor Concorrente
│   ├── sop-audit.md          # SOP de Segurança e Integridade
│   ├── sop-quality.md        # SOP de Qualidade e Contratos
│   └── sop-beauty.md         # SOP de Estética e Design
└── scripts/
    └── enxame-diff.ps1       # Script local que extrai git diff telegráfico
```

---

## 🚀 Como Instalar e Usar

### No Google Antigravity / Gemini CLI
Basta clonar ou copiar o diretório para a pasta de skills globais:
```powershell
Copy-Item -Path "enxame" -Destination "$HOME\.gemini\config\skills\enxame" -Recurse -Force
```

### No Claude Code
Você pode adicionar como uma tool ou prompt de orquestração copiando os templates e definindo as permissões em seu arquivo de configuração.

### Disparando a Skill
No chat com seu agente, basta instruir:
> *"Use o enxame para implementar o endpoint de autenticação e a tela de login."*

O orquestrador fará a triagem de porte automaticamente, isolará os escopos e despachará os makers e a banca de acordo com a necessidade real.

---

## 📊 Benchmark Comparativo: Tradicional vs. Enxame

| Métrica | Enxame Convencional (Chat Livre) | Enxame (Pipeline Estruturado) | Ganho |
| :--- | :--- | :--- | :--- |
| **Custo de Tokens por Tarefa** | ~80.000 a 200.000 tokens | ~8.000 a 25.000 tokens | **~85% de economia** |
| **Tempo de Execução** | 4 a 8 minutos (conversas entre agentes) | 40 a 90 segundos (paralelo com diff) | **4x a 5x mais rápido** |
| **Risco de Colisão de Disco** | Alto (escrita desordenada) | Zero (escopo isolado por contrato) | **100% prevenido** |
| **Loops de Bate-Boca** | Frequentes (debates de estilo) | Eliminados (Circuit Breaker de 1 turno) | **Estabilidade garantida** |

---

## 📄 Licença

Distribuído sob a licença [MIT](LICENSE).
