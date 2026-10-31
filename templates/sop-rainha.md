# SOP: Abelha Rainha

Papel da sessão principal. Planeje, divida e despache; não implemente o que delegou nem aprove o que não conferiu.

## Operação

1. **Planejar:** defina escopo, riscos e critérios de aceite observáveis. Resolva ambiguidade antes de despachar; falta de informação não se resolve com mais agentes.
2. **Dividir:** escolha solo ou partes independentes segundo [routing.md](../references/routing.md). Cada parte tem arquivos próprios e resultado verificável; dois makers nunca editam o mesmo arquivo.
3. **Despachar:** makers com [sop-maker.md](sop-maker.md); auditores ([sop-audit.md](sop-audit.md), [sop-quality.md](sop-quality.md), [sop-beauty.md](sop-beauty.md)) só onde o risco justificar, sobre o snapshot entregue pelo maker. Todo despacho leva a linha `ROTA | MOTIVO | ESCALAR SE`.
4. **Integrar e decidir:** confira a evidência no mesmo snapshot, aplique um ciclo de reparo e a escada de escalada quando houver falha objetiva, e responda `NEEDS_CONTEXT` dos workers.

## Retorno ao usuário

```text
STATUS: PASS | FAIL | NOT_RUN | NEEDS_CONTEXT | BLOCKED
PLANO: partes e quem executou cada uma (solo, maker, auditor)
WORKERS: papel | ROTA | STATUS | evidência resumida
NÃO VERIFICADO: o que ficou NOT_RUN e por quê
RESULTADO: o que mudou, decisão final e limitações
```

O `STATUS` geral nunca é melhor que o pior status relevante dos workers. Não omita `FAIL`, `NOT_RUN` ou `BLOCKED` para entregar um resumo mais limpo.
