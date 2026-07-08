# Operador de Amostragem no NSGA-II (Estado Atual do Código)

## Visão Geral

A amostragem inicial é implementada por `ConstraintAwareSampling`, com construção gulosa incremental e checagem de factibilidade durante a geração.

Arquivo de referência:
- [engine/metaheuristics/nsga2/operators/constraint_aware_sampling.py](engine/metaheuristics/nsga2/operators/constraint_aware_sampling.py)

No estado atual, a amostragem usa:
1. 5 estratégias centrais de exploração,
2. 2 estratégias extremas opcionais para ampliar a faixa de Pareto,
3. mecanismo de unicidade com lista taboo.

---

## Estratégias Ativas

### Core (sempre disponíveis)
1. `demand_first`
2. `coverage_first`
3. `workload_balance`
4. `temporal_early`
5. `random_greedy`

### Extreme (opcionais)
1. `minimize_swaps`
2. `minimize_unmet`

Controle das extremas:
1. `use_extreme_strategies` (boolean),
2. `extreme_ratio` (fração da população inicial).

---

## Pseudocódigo do Fluxo de Geração

```text
ENTRADA: problem, n_samples
SAIDA: populacao inicial X

1. definir quantas solucoes core e quantas extremas
2. para cada solucao:
3.    selecionar estrategia
4.    gerar candidatos validos (G1 e G4) com prioridade
5.    construir solucao por insercao gulosa com checks G2 e G5
6.    executar enforcement de cobertura minima (G6)
7.    aplicar taboo para evitar duplicatas (com retries)
8. retornar X
```

Observações importantes:
1. A randomização tipo GDGS é aplicada via `margin_k` na ordenação dos candidatos.
2. O enforcement de G6 ocorre em dois passes na atribuição de cobertura.

---

## Parâmetros Relevantes

1. `sampling_use_taboo` (default True no runner)
2. `sampling_taboo_retries` (default 50)
3. `sampling_margin_k` (default 5)
4. `sampling_use_extreme` (default False no runner base)
5. `sampling_extreme_ratio` (default 0.2)

Referência de CLI:
- [engine/runners/run_nsga2.py](engine/runners/run_nsga2.py#L1162)

---

## Complexidade (Ordem de Grandeza)

1. Tempo: aproximadamente O(n_samples * n_var), com fator adicional de ordenação de candidatos.
2. Memória: O(n_samples * n_var) para armazenar população e hashes de unicidade.

---

## Nota sobre Parâmetro Legado

O argumento `--sampling_strategies` ainda existe na CLI/pipeline, mas não é consumido pelo construtor atual de `ConstraintAwareSampling`.

Referências:
- [pipelines/run_nsga2_pipeline.py](pipelines/run_nsga2_pipeline.py#L127)
- [engine/runners/run_nsga2.py](engine/runners/run_nsga2.py#L1120)

Para reprodutibilidade, recomenda-se documentar explicitamente os parâmetros efetivos (`sampling_use_extreme`, `sampling_extreme_ratio`, `sampling_use_taboo`, `sampling_margin_k`).

---

## Texto Sugerido para Metodologia (Tese)

"A população inicial foi gerada por amostragem gulosa com consciência de restrições, combinando estratégias de cobertura e balanceamento com mecanismos de diversidade (randomização por margem e controle de duplicatas). Adicionalmente, estratégias extremas foram habilitadas quando necessário para ampliar a cobertura dos extremos da fronteira de Pareto."
