# Operador de Cruzamento no NSGA-II (Estado Atual do Código)

## Visão Geral

No estado atual da implementação, o cruzamento do NSGA-II foi **simplificado (streamlined)** para uma única estratégia: `DayBasedCrossover`.

Essa decisão foi tomada para priorizar robustez e desempenho em instâncias grandes, reduzindo variabilidade de comportamento e custo de manutenção.

---

## Operador Implementado

## DayBasedCrossover

Arquivo de referência:
- [engine/metaheuristics/nsga2/operators/constraint_aware_crossover.py](engine/metaheuristics/nsga2/operators/constraint_aware_crossover.py)

Ideia central:
1. Decodificar os dois pais para estruturas `var_x` e `var_w`.
2. Para cada dia `d`, sortear troca com probabilidade `day_exchange_prob`.
3. Trocar blocos completos daquele dia entre os pais.
4. Re-encodar para o vetor do indivíduo.

Parâmetros:
1. `prob`: probabilidade global de crossover (padrão 0.9).
2. `day_exchange_prob`: probabilidade de trocar cada dia (padrão 0.5).

Justificativa metodológica:
1. Preserva naturalmente a estrutura diária das decisões.
2. Reduz risco de gerar combinações muito destrutivas.
3. Mantém coerência com a restrição de consistência por dia (clínica do dia).

---

## Pseudocódigo

```text
ENTRADA: parent1, parent2
SAIDA: offspring1, offspring2

1. (x1, w1) <- decode(parent1)
2. (x2, w2) <- decode(parent2)

3. PARA cada dia d:
4.    SE rand() < day_exchange_prob:
5.       trocar x1[:,:,d,:] <-> x2[:,:,d,:]
6.       trocar w1[:,:,d]   <-> w2[:,:,d]

7. offspring1 <- encode(x1, w1)
8. offspring2 <- encode(x2, w2)
9. RETORNAR offspring1, offspring2
```

---

## Complexidade

1. Tempo: O(n_var), onde `n_var` é o tamanho da representação.
2. Memória: O(n_var), devido às cópias temporárias de blocos.

---

## Observação Importante Sobre CLI

Embora a CLI ainda exponha estratégias antigas (`physician_based`, `uniform`), a fábrica atual aceita apenas `day_based`.

Referências:
- [engine/runners/run_nsga2.py](engine/runners/run_nsga2.py#L1177)
- [engine/metaheuristics/nsga2/operators/constraint_aware_crossover.py](engine/metaheuristics/nsga2/operators/constraint_aware_crossover.py#L155)

Implicação para experimentos:
1. Para reprodutibilidade, usar explicitamente `--crossover_strategy day_based`.
2. Evitar estratégias legadas enquanto a CLI não for harmonizada com a fábrica.

---

## Texto Sugerido para Metodologia (Tese)

"O operador de recombinação adotado foi o cruzamento por blocos diários (day-based), no qual agendas completas de um mesmo dia são trocadas entre indivíduos pais. Essa escolha privilegia estabilidade estrutural e reduz perturbações incompatíveis com as restrições do problema, ao mesmo tempo em que preserva diversidade temporal na população."
