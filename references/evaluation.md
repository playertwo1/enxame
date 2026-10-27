# Avaliar antes de otimizar

O Enxame não inclui benchmark de economia validado. Um piloto de 30–50 tarefas reais ajuda a calibrar a política; não garante significância estatística.

Compare, no mesmo estado inicial e com critérios definidos antes:

1. Um agente capaz executando sozinho.
2. Um executor econômico fixo com revisão.
3. A política adaptativa, sem mudar simultaneamente os critérios de aceite.

Separe casos usados para calibrar das tarefas de avaliação. Inclua tarefas mecânicas, bugs reproduzíveis, mudanças entre módulos e cenários de risco. Avalie paralelismo somente onde houver frentes independentes. Repita parte dos casos para observar variação. Use testes de comportamento e inspeção independente pertinente; o veredito do próprio executor não basta.

Registre uma linha JSONL por execução, em uma pasta local escolhida pelo operador. Não envie código privado, credenciais ou prompts sensíveis ao repositório:

```json
{"task":"bug-local-01","snapshot":"<commit+patch_sha256>","risk":"low","route":"economic","provider":"<provider>","model":"<effective-id>","effort":"<effective-or-not-exposed>","attempts":1,"input_tokens":null,"output_tokens":null,"cached_tokens":null,"cost":null,"cost_basis":"unknown","currency":null,"elapsed_seconds":null,"validation":"NOT_RUN","accepted":false}
```

`null` significa desconhecido, nunca zero. Se o harness não expõe custo ou tokens, registre essa limitação. Inclua custos do coordenador, workers, verificação, cache, reparos e resultados rejeitados. Tokens não equivalem a dinheiro quando modelos e categorias têm preços diferentes. Não trate cota de assinatura como preço de API.

**Métricas:** custo total do lote / tarefas aceitas; taxa de aceite; regressões e falsos aceites; tempo total (incluindo revisão e reparo). Sem tarefas aceitas, o custo por tarefa aceita é indefinido. Reporte também casos de risco, pois uma média pode esconder falhas graves.

Uma aproximação para uma cascata curta é `custo econômico + verificação + P(escalar) × (custo forte + reverificação) + coordenação`. Use dados observados para cada parcela. Mais esforço, mais workers ou um modelo maior são alternativas a comparar, não melhorias garantidas.
