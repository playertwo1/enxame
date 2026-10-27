# Matriz de roteamento

Use julgamento proporcional ao impacto e à evidência disponível. Os eixos orientam decisões; não são uma pontuação automática nem exigem criação de agentes.

| Risco | Ambiguidade | Verificabilidade | Execução e revisão |
|---|---|---|---|
| Baixo | Baixa | Alta | Solo costuma bastar. Esforço econômico baixo ou médio; validação direta e barata quando útil. Delegue só se o custo total cair. |
| Baixo ou médio | Média | Alta | Resolva a incerteza primeiro com leitura focalizada ou pergunta, se indispensável. Solo ou divisão pequena; esforço baixo/médio se a saída for conferível. |
| Médio | Baixa ou média | Média | Um worker pode ajudar se houver fronteira independente e dono claro da integração. Reserve revisão focalizada e verifique evidência no mesmo snapshot. |
| Alto | Qualquer | Alta ou média | Raciocínio forte diretamente no ponto de risco. Mantenha ownership claro; delegue análise independente se acrescentar cobertura, e confira evidência de forma proporcional. |
| Qualquer | Alta | Baixa | Não presuma que mais agentes resolvem falta de informação. Busque o contexto mínimo, delimite a incerteza ou reporte `NEEDS_CONTEXT`/`BLOCKED`; não declare `PASS` sem base suficiente. |

## Escolhas independentes

- **Delegação:** solo é uma opção completa. Use workers para trabalho realmente separável; o planejador é dono do plano e da integração.
- **Modelo e esforço:** escolha dentre as opções anunciadas pelo harness da execução atual. Esforço econômico baixo/médio serve quando a tarefa é verificável e o custo total justifica. Para alto risco, aplique raciocínio forte diretamente; não dependa de uma revisão barata para compensar execução fraca.
- **Paralelismo:** padrão de até 2 workers. Aumente apenas quando as partes forem independentes e o benefício superar coordenação, contenção e custo de revisão.
- **Disponibilidade:** se modelo ou nível escolhido não estiver disponível, não faça fallback silencioso. Selecione explicitamente uma opção disponível compatível com o risco ou prossiga solo e registre a limitação quando relevante.

## Explorar antes de rotear

A descrição da tarefa costuma esconder a dificuldade: o mesmo pedido pode ser um typo ou uma mudança entre módulos. Quando o escopo for incerto e o risco não for alto, despache primeiro um worker econômico só para localizar e devolver `arquivo:linha` com o sinal de complexidade (arquivos tocados, contrato ou teste afetado, reprodução disponível). Escolha a rota de execução com esse sinal; o mesmo worker pode seguir se a rota econômica bastar. Referência: [SWE-Router, arXiv 2607.00053](https://arxiv.org/abs/2607.00053), que roteia por trajetória parcial em vez de só pela descrição.

## Escada de escalada

1. **Mesmo worker, um reparo** com o erro real.
2. **Mais esforço** no mesmo modelo, se o harness expõe esforço.
3. **Consulta ao coordenador:** o worker devolve `NEEDS_CONTEXT` com uma pergunta objetiva; o coordenador responde com um plano curto e o mesmo worker continua, preservando o contexto. Inspirado na [advisor strategy da Anthropic](https://claude.com/blog/the-advisor-strategy).
4. **Modelo maior** (intermediário → forte) com contrato e evidência acumulada, não o histórico inteiro.
5. **`BLOCKED`** com causa e próximo passo.

Suba um degrau só com falha objetiva: teste vermelho, critério de aceite não cumprido ou erro de raciocínio demonstrado. Confiança declarada pelo worker não conta. Pule degraus quando o risco já for alto desde o início. Falta de contexto volta ao passo 3; erro de ambiente ou quota exige diagnóstico, não escalada.

## Contrato de despacho

Todo despacho registra, em uma linha: `ROTA: <alias> <modelo>/<esforço> | MOTIVO: <risco/sinal> | ESCALAR SE: <gatilho objetivo>`. Isso torna a decisão auditável e alimenta o [piloto](evaluation.md).

O custo total inclui preparação de contexto, despacho, coordenação, integração, validação, revisão e retrabalho. Uma chamada ou agente mais barato não é economia se aumentar esses custos ou reduzir a confiança necessária.
