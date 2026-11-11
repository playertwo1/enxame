# Hosts

Observado em 2026-11-02 (Claude Code 2.1.310, Codex 0.166). Confira as ferramentas expostas na sessão atual; se algo divergir, vale o que a sessão oferece.

| | Claude Code | Codex |
|---|---|---|
| Despachar | `Agent` | `spawn_agent`, nome conforme o schema exposto |
| Contexto novo | `Agent` comum. Não use `fork` nem `/subtask`, que herdam a conversa | `fork_context: false` ou `fork_turns: "none"`, conforme o schema. Só a execução mostra se foi respeitado |
| Modelo | Parâmetro `model` da chamada tem prioridade. Omitido, usa a definição do agente, depois `CLAUDE_CODE_SUBAGENT_MODEL`, depois a sessão: confirme o padrão antes de confiar em herança | Não confirmado por subagente; registre `não exposto` se não houver controle observável |
| O que chega mesmo sem histórico | `CLAUDE.md`, git status e hooks `SubagentStart`, como os do Ponytail | `AGENTS.md`, hooks e serviços de memória |

Se não houver ferramenta de subagente, trabalhe diretamente e aplique a regra de `NOT_RUN` do `SKILL.md`.
