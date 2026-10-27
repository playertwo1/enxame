# Harnesses e despacho

O skill fornece procedimento e templates; instalar os arquivos **não** valida a descoberta do skill, a ferramenta do harness, a delegação, a qualidade do resultado ou o consumo real.

| Harness | Capacidade confirmada | Como aplicar o Enxame |
|---|---|---|
| Codex | Ferramenta de colaboração cria e coordena agentes; tool/runtime disponível nesta conversa depende do host. | Delegue makers em paralelo quando a ferramenta estiver exposta; atribua arquivos exclusivos e recolha resultado. Sem ela, execute makers/revisão diretamente em sequência. |
| Claude Code | Skills podem executar em subagente via frontmatter `context: fork`/`agent` e ferramenta `Agent`; agentes built-in variam por configuração. | Só despache quando `/agents` ou ferramenta Agent confirmar capacidade/configuração. Caso contrário, fluxo direto. |
| Hermes Agent | `delegate_task` cria subagentes, sujeito ao backend/plugin e configuração ativa. | Verifique ferramenta e backend antes; em erro/indisponibilidade, execute diretamente. |
| Antigravity | Docs do App e CLI confirmam subagentes customizados e ferramenta `invoke_subagent`; IDE não aparece nessa lista de superfícies. | App/CLI: use `invoke_subagent` quando exposta. Em IDE ou sem ferramenta, execução direta. |

## Porte e economia

Use **econômico** para trabalho mecânico e escopo pequeno; **intermediário** para maker e revisão independentes; **forte** apenas para raciocínio difícil, risco alto ou síntese ampla. Esses aliases são relativos ao catálogo e controles do harness: escolha o equivalente mais barato que cumpra a tarefa. Registre no resultado o modelo realmente usado e o esforço efetivo (ou `não exposto`); não afirme alias executado quando o harness não oferece controle observável.

Mapeamento inicial, a confirmar no catálogo da execução atual:

| Alias | Claude Code (`Agent`: `model`, `effort`) | Antigravity / Gemini | Codex |
|---|---|---|---|
| econômico | `haiku`, `low`/`medium` | Flash, thinking baixo | modelo mini, reasoning `low` |
| intermediário | `sonnet`, `medium`/`high` | Flash, thinking alto | modelo padrão, reasoning `medium` |
| forte | `opus`, `high` | Pro, thinking alto | modelo padrão ou maior, reasoning `high` |

Só a coluna do Claude Code foi observada diretamente: a ferramenta `Agent` aceita `model` e `effort` por despacho. Nas demais, o controle por subagente depende da versão do host; sem controle observável, registre `não exposto`. Use o coordenador forte como consultor antes de trocar o worker de modelo (veja a escada em [routing.md](routing.md)).

Mantenha limites de concorrência e circuit breaker do `SKILL.md`. Delegação falhou ou não está disponível? Faça o trabalho sem agentes e registre `delegação: direta`.

## Perfil efetivo do Hermes

`~/.hermes/skills` é o destino padrão do instalador, mas o Hermes pode usar um home personalizado ou uma distribuição Windows em `%LOCALAPPDATA%/hermes`. Consulte `hermes config path` e use `scripts/install.ps1 -Target Hermes -HermesHome <pasta-da-configuração>`. Para um perfil nomeado, consulte `hermes -p <perfil> config path` antes de instalar. Confira a descoberta com `hermes skills list --source local` no mesmo perfil. Copiar arquivos para o home portátil não prova que um perfil diferente os carregue.

## Descoberta Antigravity

Google documenta `~/.gemini/config/skills/<skill>/` para App e IDE; CLI usa `~/.gemini/antigravity-cli/skills/<skill>/`. A documentação do IDE ainda suporta o caminho legado `~/.gemini/antigravity/skills/<skill>/`. O instalador grava no caminho global atual e no legado para compatibilidade; não instala no caminho CLI.

Fontes oficiais consultadas (26-10-2026): [Codex skills](https://developers.openai.com/codex/skills/), [Claude Code skills](https://code.claude.com/docs/en/skills), [Hermes skills](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills/), [Hermes delegation](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation/), [Antigravity skills](https://antigravity.google/docs/skills?app=antigravity-ide), [Antigravity subagents](https://antigravity.google/docs/subagents/).
