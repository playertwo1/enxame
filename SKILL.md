---
name: enxame
description: >-
  Coordena trabalho de engenharia com várias etapas ou risco relevante, mesmo em mudança
  pequena. Use ao escrever, executar ou revisar um plano; pedir revisão independente; conferir
  relato de outro agente; decidir sobre delegação; retomar trabalho interrompido; ou alterar
  dados, autenticação, dinheiro, migração ou contrato público. Não use para correção pequena
  sem esse risco nem para perguntas simples.
---

# Enxame

## Limites

- Relato de agente não é evidência. Só conta o que você conferiu no estado atual.
- Revisor ausente ou falho, ou teste não executado, é `NOT_RUN`, nunca aprovação.
- Delegar não amplia escopo nem permissão.
- Regras do projeto e pedidos explícitos do usuário prevalecem sobre esta skill, inclusive pedidos para não delegar ou não abrir revisão independente.
- Em mudança de dinheiro, cobrança, dados pessoais, autenticação ou migração, não declare que testes passaram sem tê-los executado. Sem ferramenta de execução, diga `NOT_RUN` e liste o que ficou sem verificação.

## Escolher

Faça diretamente por padrão, inclusive em risco alto: o ponto arriscado fica com o coordenador.

Delegue somente se tudo for verdade: a parte é independente; o contrato já está fechado; o resultado é barato de conferir; e isso poupa contexto do coordenador ou permite avançar em paralelo. Esperar parado não compensa.

Subagentes herdam o modelo da sessão. Use opção econômica só em trabalho mecânico verificável. Escolha apenas modelos oferecidos pelo host, registre o modelo usado e o motivo quando ele diferir da sessão, e não troque em silêncio.

## Planejar

Escreva plano só se o trabalho puder sobreviver à sessão ou for executado por outro agente. Use o plano que já existe em vez de criar outro. Ele contém objetivo, limites, contratos, decisões difíceis de reverter e checkpoints, cada um com resultado observável e validação. Quem executa decide o que é reversível.

## Retomar

Ao continuar trabalho interrompido ou compactado, trate cada checkpoint marcado como feito como afirmação a conferir, não como fato. Antes de seguir, verifique no estado atual (arquivos, funções, testes) que o resultado do checkpoint existe. Se houver divergência, por exemplo um checkpoint marcado como feito cuja função não existe, relate-a ao usuário e corrija-a antes de avançar.

## Delegar

Passe objetivo, arquivos permitidos e proibidos, contrato, validação e o aviso de que há outros trabalhando e que alterações alheias não devem ser revertidas. Peça de volta status, arquivos, comando com resultado e pendências. Workers não delegam nem editam o plano.

Quando duas partes dependem uma da outra (ex.: API e interface que consome um campo), escreva o contrato antes de dividir: nome do campo, tipo, unidade e formato. Isso vale também se você mesmo fizer as duas partes em sequência.

Na integração, releia os dois lados, confirme que usam o mesmo contrato e confira um fluxo que atravesse as partes. Testes isolados não provam integração; sem essa conferência, não declare integração.

## Revisar sem histórico

Salvo pedido do usuário para não revisar ou não delegar, faça automaticamente, sem pedir licença, se qualquer um valer: decisão difícil de reverter (dados, contrato público, autenticação, dinheiro, migração); plano que será executado por quem não tem o contexto; ou risco que os testes não alcançam. Fora desses casos, não revise por rotina.

Abra um agente novo, sem a conversa, conforme [hosts.md](references/hosts.md). Passe apenas caminhos do documento, critérios e fontes, sem sua defesa nem o resultado esperado. Peça, sem editar nada:

1. Paráfrase do que é proposto. Uma paráfrase errada já é um achado.
2. O que falta para entender ou executar sem adivinhar.
3. Achados com evidência e impacto: premissas falsas, incompatibilidades, reuso ignorado e complexidade desnecessária.

Faça uma passagem. Outra só para risco distinto ou depois de correção material. Sem achados não prova correção.

**Sem ferramenta de subagente, a primeira linha da sua resposta deve dizer: "Revisão independente: `NOT_RUN`. Esta é uma revisão minha, com o contexto desta sessão."** Só então apresente seus achados. Contexto novo não isola arquivos, memória ou instruções do projeto: chame de "sem histórico", não de isolada.

## Entregar

Separe: feito e provado (com a evidência), não provado, não feito, bloqueios. Se houve contrato entre partes, cite-o (campo, tipo, unidade) e escreva uma linha de conferência nomeando os arquivos relidos, por exemplo: "Conferido: api.py e ui.py usam `shipping_cents` (centavos, inteiro)". Sem essa linha, a integração conta como não provada. Custo desconhecido continua desconhecido; não prometa economia sem medir.
