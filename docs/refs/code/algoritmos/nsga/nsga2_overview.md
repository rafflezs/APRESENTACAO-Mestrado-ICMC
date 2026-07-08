# NSGA-II no Projeto: Visão Metodológica Integrada

## Objetivo

Este documento consolida a metodologia de metaheurística multiobjetivo adotada no projeto para o problema de alocação de médicos, com foco em três variantes em produção:

1. `nsga2` (baseline),
2. `nsga2_extended` (enhanced),
3. `compact_nsga2` (representação compacta).

---

## Formulação de Objetivos

A otimização considera dois objetivos minimizados simultaneamente:

1. `F1`: demanda não atendida,
2. `F2`: número de trocas de clínica por médico ao longo dos dias.

No problema base, a avaliação dos indivíduos ocorre em [engine/metaheuristics/nsga2/core/problem.py](engine/metaheuristics/nsga2/core/problem.py).

---

## Variantes Algorítmicas

## 1) NSGA-II Baseline

Implementação:
- [engine/runners/run_nsga2.py](engine/runners/run_nsga2.py)

Características:
1. ordenação não-dominada e crowding distance (núcleo padrão NSGA-II),
2. sampling constraint-aware,
3. crossover day-based,
4. mutação slot reassignment.

## 2) NSGA2Extended

Implementação:
- [engine/metaheuristics/nsga2/core/nsga2_extended.py](engine/metaheuristics/nsga2/core/nsga2_extended.py)

Extensões incorporadas:
1. controle adaptativo de diversidade,
2. evolução em dois estágios,
3. inicialização enviesada para extremos,
4. injeção periódica de extremos,
5. arquivo de soluções de fronteira,
6. busca local em elite (opcional).

## 3) Compact NSGA-II

Implementações principais:
- [engine/runners/run_compact_nsga2.py](engine/runners/run_compact_nsga2.py)
- [engine/metaheuristics/nsga2/compact/problem.py](engine/metaheuristics/nsga2/compact/problem.py)

Diferença central:
1. codificação compacta `w[i,d]` (inteira) em vez de vetor binário completo,
2. redução drástica da dimensionalidade,
3. avaliação e reparo adaptados para preservar viabilidade prática em horizontes longos.

---

## Operadores Ativos (Estado Atual)

## Sampling
- `ConstraintAwareSampling` com 5 estratégias core + 2 extremas opcionais.
- Referência: [engine/metaheuristics/nsga2/operators/constraint_aware_sampling.py](engine/metaheuristics/nsga2/operators/constraint_aware_sampling.py)

## Crossover
- `DayBasedCrossover` (única estratégia ativa na fábrica).
- Referência: [engine/metaheuristics/nsga2/operators/constraint_aware_crossover.py](engine/metaheuristics/nsga2/operators/constraint_aware_crossover.py)

## Mutation
- `SlotReassignmentMutation` (única estratégia ativa na fábrica).
- Referência: [engine/metaheuristics/nsga2/operators/constraint_aware_mutation.py](engine/metaheuristics/nsga2/operators/constraint_aware_mutation.py)

Observação relevante:
1. A CLI ainda expõe opções legadas de crossover/mutation que não são aceitas pelas fábricas atuais.

---

## Restrições e Factibilidade

No problema base, o modo padrão opera com gerenciamento de restrições via `ConstraintManager`.

Referências:
- [engine/metaheuristics/nsga2/core/constraint_manager.py](engine/metaheuristics/nsga2/core/constraint_manager.py)
- [engine/metaheuristics/nsga2/core/problem.py](engine/metaheuristics/nsga2/core/problem.py)

Ponto metodológico:
1. a abordagem privilegia construção de soluções plausíveis por operador,
2. cobertura mínima (G6) é tratada por lógica de construção/enforcement e por sinalização no objetivo conforme modo,
3. isso evita rejeição excessiva de indivíduos em espaço factível esparso.

---

## Pipeline Experimental e Reprodutibilidade

Orquestração principal:
- [pipelines/run_nsga2_pipeline.py](pipelines/run_nsga2_pipeline.py)

Runners:
- [engine/runners/run_nsga2.py](engine/runners/run_nsga2.py)
- [engine/runners/run_compact_nsga2.py](engine/runners/run_compact_nsga2.py)

Diretrizes de reprodutibilidade:
1. fixar `seed`,
2. registrar variante algorítmica (`nsga2`, `nsga2_extended`, `compact_nsga2`),
3. registrar parâmetros de término (`termination_method`, `termination_value`),
4. registrar hiperparâmetros de operadores e extensões,
5. manter mesma instância e mesmo horizonte temporal em comparações.

---

## Pseudocódigo Integrado de Execução

```text
ENTRADA: configuracao experimental, algoritmo alvo, instancia
SAIDA: fronteira de Pareto, logs de evolucao e artefatos de analise

1. Ler configuracao e carregar instancia.
2. Selecionar variante:
3.    se algorithm == compact_nsga2:
4.       problem <- CompactProblem
5.       operadores <- compactos
6.       algoritmo <- CompactNSGA2Extended
7.    senao:
8.       problem <- PhysicianSchedulingProblem
9.       operadores <- constraint-aware (sampling, day-based, slot reassignment)
10.      se algorithm == nsga2_extended:
11.         algoritmo <- NSGA2Extended
12.      senao:
13.         algoritmo <- NSGA2 baseline
14. Definir criterio de parada (n_gen, n_eval ou time).
15. Executar minimize(problem, algoritmo, termination, seed, callbacks).
16. Extrair fronteira de Pareto e solucoes representativas.
17. Salvar resultados, historico de evolucao, diversidade e metadados.
18. Executar analises internas (ou pular via flag de performance).
```

---

## Estrutura Recomendada para Capítulo de Metodologia

1. Definição formal do problema e objetivos.
2. Fundamentação do NSGA-II e adequação ao problema multiobjetivo.
3. Descrição do baseline (operadores e avaliação).
4. Descrição das extensões (NSGA2Extended).
5. Justificativa da codificação compacta para escalabilidade.
6. Protocolo experimental (dados, parâmetros, critérios de parada, métricas).
7. Ameaças à validade e limitações.

---

## Limitações Metodológicas

1. Espaço factível altamente esparso pode reduzir diversidade genotípica.
2. Há desalinhamentos entre opções legadas de CLI e fábricas de operadores.
3. Custos computacionais crescem rapidamente com horizonte/dimensão no modo não-compacto.

---

## Conclusão

A arquitetura atual combina uma base NSGA-II estável com extensões de diversidade e uma variante compacta para escala. Esse conjunto é adequado para investigação metodológica em nível de mestrado, pois oferece:

1. comparação entre baseline e extensões,
2. análise de trade-offs qualidade-tempo,
3. caminho claro de reprodutibilidade experimental.
