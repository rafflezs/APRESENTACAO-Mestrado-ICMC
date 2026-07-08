# Operador de Mutação no NSGA-II (Estado Atual do Código)

## Visão Geral

A mutação no NSGA-II também foi **streamlined** para uma única estratégia principal: `SlotReassignmentMutation`.

Arquivo de referência:
- [engine/metaheuristics/nsga2/operators/constraint_aware_mutation.py](engine/metaheuristics/nsga2/operators/constraint_aware_mutation.py)

Objetivo da simplificação:
1. reduzir variabilidade operacional,
2. focar no operador com melhor desempenho empírico,
3. manter factibilidade com verificações locais de restrições.

---

## Operador Implementado

## SlotReassignmentMutation

Mecanismo:
1. Seleciona aleatoriamente uma alocação ativa `(médico, clínica, dia, turno)`.
2. Busca clínicas alternativas válidas para o mesmo dia/turno.
3. Verifica restrições locais antes de mover.
4. Atualiza `var_x` e `var_w` de forma consistente.

Restrições verificadas no movimento:
1. disponibilidade do médico (G1),
2. clínica válida para o médico (G4),
3. capacidade de sala no destino (G5),
4. consistência diária da clínica (G2 via `var_w`).

Parâmetros principais:
1. `prob_mutation` (padrão 0.3),
2. `max_attempts` (padrão 10),
3. `n_mutations` (padrão 1).

---

## Pseudocódigo

```text
ENTRADA: individuo x
SAIDA: individuo mutado x'

1. (var_x, var_w) <- decode(x)
2. repetir ate max_attempts:
3.    escolher atribuicao ativa (i, u_old, d, t)
4.    construir conjunto U_cand de clinicas alternativas validas
5.    se U_cand vazio: continuar
6.    escolher u_new em U_cand
7.    mover var_x[i, u_old, d, t] -> var_x[i, u_new, d, t]
8.    ajustar var_w no dia d
9.    retornar encode(var_x, var_w)
10. retornar individuo original se nenhum movimento valido
```

---

## Complexidade

1. Tempo aproximado por mutação: O(max_attempts * n_var_ativo) no pior caso.
2. Memória: O(n_var), devido a cópias de trabalho do indivíduo.

---

## Observação Importante Sobre CLI

A CLI ainda lista estratégias legadas (`physician_swap`, `add_remove`, `shift_swap`, `mixed`), mas a fábrica atual aceita somente `slot_reassignment`.

Referências:
- [engine/runners/run_nsga2.py](engine/runners/run_nsga2.py#L1190)
- [engine/metaheuristics/nsga2/operators/constraint_aware_mutation.py](engine/metaheuristics/nsga2/operators/constraint_aware_mutation.py#L205)

Implicação para experimentos:
1. usar `--mutation_strategy slot_reassignment` para evitar falhas em runtime,
2. documentar explicitamente essa escolha no protocolo experimental.

---

## Texto Sugerido para Metodologia (Tese)

"A mutação foi implementada por realocação de slot (slot reassignment), na qual uma alocação ativa é movida para clínica alternativa no mesmo dia e turno, sob checagem local de disponibilidade, elegibilidade e capacidade. Esse mecanismo promove exploração controlada do espaço de soluções, preservando consistência estrutural sem necessidade de reparos globais agressivos."
