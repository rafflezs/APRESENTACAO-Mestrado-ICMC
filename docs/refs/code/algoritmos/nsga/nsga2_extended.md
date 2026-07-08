# NSGA2Extended: Extensões Metodológicas

## Escopo

Este documento descreve a variante `nsga2_extended`, que mantém o núcleo do NSGA-II e adiciona mecanismos de diversidade, exploração de extremos e refinamento local.

Referência principal:
- [engine/metaheuristics/nsga2/core/nsga2_extended.py](engine/metaheuristics/nsga2/core/nsga2_extended.py)

---

## Princípio de Projeto

O algoritmo preserva a lógica do NSGA-II padrão e altera, sobretudo:
1. inicialização,
2. adaptação de parâmetros ao longo das gerações,
3. injeção de soluções extremas,
4. refinamento local opcional.

---

## Opções Implementadas

## Option 1: Local Search on Elite
1. busca local em fração elite da população,
2. frequência e orçamento de tempo configuráveis.

## Option 2: Adaptive Diversity Control
1. monitora diversidade ao longo da execução,
2. adapta parâmetros para manter alvo por estágio.

## Option 3: Extreme-Biased Initialization
1. inicialização com fração de indivíduos extremos,
2. aumenta cobertura de extremos da fronteira de Pareto.

## Option 4: Two-Stage Evolution
1. estágio inicial de exploração,
2. estágio posterior de refinamento.

## Option 5: Periodic Extreme Re-injection
1. reintroduz indivíduos extremos periodicamente,
2. mitiga convergência prematura no centro da fronteira.

## Option 6: Boundary Solution Archive
1. mantém soluções de fronteira (melhores extremos históricos),
2. permite reinjeção para preservar amplitude da fronteira.

---

## Parâmetros Centrais

1. `use_extreme_initialization`, `extreme_ratio`,
2. `use_two_stage`, `stage_transition`,
3. `use_adaptive_diversity`, `diversity_early|mid|late`,
4. `use_local_search`, `ls_elite_ratio`, `ls_frequency`, `ls_max_iterations`, `ls_time_budget`,
5. `use_periodic_injection`, `injection_frequency`, `injection_count`,
6. `use_boundary_archive`.

Referência de CLI:
- [engine/runners/run_nsga2.py](engine/runners/run_nsga2.py#L1275)

---

## Pseudocódigo do NSGA2Extended

```text
ENTRADA: problema, operadores, parametros O1..O6, criterio de parada
SAIDA: fronteira de Pareto e estatisticas de aprimoramentos

1. Configurar modulos opcionais (local search, diversidade, estagios, injecao, arquivo).
2. Inicializacao:
3.    se use_extreme_initialization:
4.       habilitar estrategias extremas no sampling e gerar P0
5.    senao:
6.       gerar P0 com inicializacao padrao
7. Avaliar P0.
8. Para cada geracao g ate parada:
9.    progress <- compute_progress(g)
10.   se use_two_stage: aplicar transicao e parametros do estagio
11.   se use_adaptive_diversity: medir diversidade e adaptar parametros
12.   Executar passo padrao NSGA-II (infill, avaliacao e sobrevivencia)
13.   se use_periodic_injection e g multiplo da frequencia: reinjetar extremos
14.   se use_boundary_archive: atualizar arquivo e reinjetar solucoes limite
15.   se use_local_search e g multiplo da frequencia: aplicar busca local na elite
16. Retornar populacao nao dominada e enhancement_stats.
```

---

## Quando Usar

Uso recomendado quando:
1. há evidência de clustering de soluções no centro da fronteira,
2. baseline apresenta baixa cobertura de extremos,
3. há orçamento computacional para mecanismos adicionais.

---

## Texto Sugerido para Metodologia (Tese)

"A variante NSGA2Extended foi empregada para ampliar a cobertura da fronteira de Pareto em ambientes com espaço factível esparso. As extensões preservam a estrutura canônica do NSGA-II e adicionam mecanismos de diversidade adaptativa, exploração orientada a extremos e refinamento local de elite, buscando reduzir convergência prematura e melhorar a amplitude de soluções não dominadas."

