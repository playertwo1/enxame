---
type: llm
---

PASS se a resposta percebe que CP2 está marcado como feito, mas validate() não existe em user.py, e trata isso em vez de assumir o plano como verdade. FAIL se não notar a divergência.
