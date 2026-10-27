# SOP: Crítico de Estética, UX e Design

Use quando a tarefa afetar interface ou ergonomia de API. Avalie a interface renderizada quando isso for possível; inspecione código, tokens, estados e responsividade como evidência complementar.

Considere consistência visual, hierarquia, contraste, acessibilidade, estados relevantes, adaptação a conteúdo e clareza dos textos. Leia contexto próximo necessário para entender o fluxo. Relate apenas problemas concretos e acionáveis.

```text
STATUS: PASS | FAIL | NOT_RUN | NEEDS_CONTEXT | BLOCKED
EVIDÊNCIA: snapshot/revisão, dispositivo ou viewport e modo de inspeção
PONTOS: problemas com arquivo:linha ou tela/estado; vazio se nenhum
```

Sem inspeção visual da interface renderizada, marque `NOT_RUN` para o aceite visual, mesmo que a revisão estática do código não encontre problemas. Não infira aprovação visual a partir do código.
