# NSGA-II Base: Metodologia e Configuração

## Escopo

Este documento descreve a configuração baseline do NSGA-II usada no projeto.

Referências de implementação:
- [engine/runners/run_nsga2.py](engine/runners/run_nsga2.py)
- [engine/metaheuristics/nsga2/core/problem.py](engine/metaheuristics/nsga2/core/problem.py)

---

## Núcleo Algorítmico

O baseline utiliza o NSGA-II padrão da biblioteca `pymoo` com:

1. non-dominated sorting,
2. crowding distance,
3. elitismo implícito na seleção de sobreviventes.

---

## Formulação

Objetivos minimizados:
1. `F1`: demanda não atendida,
2. `F2`: trocas de clínica.

Representação da solução:
1. vetor binário concatenando `x[i,u,d,t]` e `w[i,u,d]`.

---

## Operadores (Estado Atual)

## Sampling
1. `ConstraintAwareSampling` (5 estratégias core + 2 extremas opcionais).

## Crossover
1. `DayBasedCrossover`.

## Mutation
1. `SlotReassignmentMutation`.

Observação:
1. opções legadas de estratégia ainda aparecem na CLI, mas as fábricas ativas aceitam somente os operadores acima.

---

## Pseudocódigo do NSGA-II Base

```text
ENTRADA: instancia, parametros de operadores, criterio de parada, seed
SAIDA: fronteira de Pareto aproximada e artefatos de execucao

1. Carregar instancia e construir PhysicianSchedulingProblem.
2. Inicializar operadores:
	sampling  <- ConstraintAwareSampling(...)
	crossover <- DayBasedCrossover(...)
	mutation  <- SlotReassignmentMutation(...)
3. Criar algoritmo NSGA2(pop_size, sampling, crossover, mutation).
4. Definir terminacao (n_gen | n_eval | time).
5. Gerar populacao inicial P0 com sampling.
6. Avaliar objetivos (F1, F2) em P0.
7. Enquanto criterio de parada nao for atingido:
8.    Gerar descendentes Q por selecao + crossover + mutation.
9.    Avaliar Q.
10.   R <- P uniao Q.
11.   Aplicar non-dominated sorting em R.
12.   Construir nova populacao P por fronts e crowding distance.
13. Retornar solucoes nao dominadas de P e historico de execucao.
```

---

## Configuração Típica

Parâmetros comuns do baseline:
1. `pop_size = 100`,
2. `crossover_prob = 0.9`,
3. `mutation_prob = 0.3`,
4. `termination_method = n_gen|n_eval|time`,
5. `seed = 42`.

Exemplo de chamada:

```bash
python engine/runners/run_nsga2.py \
	--instance_file data/input/instances/... \
	--output_dir data/output/nsga2/base_run \
	--algorithm nsga2 \
	--pop_size 100 \
	--crossover_strategy day_based \
	--mutation_strategy slot_reassignment \
	--termination_method time \
	--termination_value 3600
```

---

## Reprodutibilidade

Para cada execução, registrar:
1. instância e horizonte,
2. seed,
3. configuração de terminação,
4. parâmetros de sampling/crossover/mutation,
5. versão de código/commit.

---

## Texto Sugerido para Metodologia (Tese)

"Como baseline metaheurístico, empregou-se o NSGA-II clássico com operadores especializados para o contexto de escalonamento médico. A configuração base combina amostragem gulosa com consciência de restrições, recombinação por blocos diários e mutação por realocação de slot, permitindo evolução multiobjetivo estável sob restrições operacionais complexas."

