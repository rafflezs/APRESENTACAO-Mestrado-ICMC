# Compact NSGA-II: Codificação Reduzida para Escalabilidade

## Escopo

Este documento descreve a variante `compact_nsga2`, projetada para reduzir dimensionalidade e melhorar escalabilidade em horizontes longos.

Referências principais:
- [engine/metaheuristics/nsga2/compact/problem.py](engine/metaheuristics/nsga2/compact/problem.py)
- [engine/runners/run_compact_nsga2.py](engine/runners/run_compact_nsga2.py)

---

## Ideia Central

Em vez de codificar diretamente `x[i,u,d,t]` e `w[i,u,d]` em vetor binário massivo, a variante compacta usa:

1. gene inteiro por par `(i,d)`,
2. valor 0 para não alocado,
3. valores `1..|U|` para clínica atribuída.

Com isso, o cromossomo passa a representar `w[i,d]` de forma direta.

---

## Benefícios Metodológicos

1. Redução significativa de dimensionalidade.
2. Melhor throughput de gerações por unidade de tempo.
3. Viabiliza experimentos com horizontes maiores mantendo diversidade evolutiva.

---

## Operadores Compactos

Implementações:
1. `CompactSampling` em [engine/metaheuristics/nsga2/compact/sampling.py](engine/metaheuristics/nsga2/compact/sampling.py)
2. `CompactDayBasedCrossover` em [engine/metaheuristics/nsga2/compact/crossover.py](engine/metaheuristics/nsga2/compact/crossover.py)
3. `CompactMutation` em [engine/metaheuristics/nsga2/compact/mutation.py](engine/metaheuristics/nsga2/compact/mutation.py)

Observações:
1. crossover mantém troca por blocos diários,
2. mutação aplica múltiplos movimentos por indivíduo (`mutation_n_moves_pct`),
3. amostragem pode usar estratégias extremas.

---

## Pseudocódigo da Avaliação Compacta

```text
ENTRADA: cromossomo x (inteiro) de tamanho |I|*|D|
SAIDA: vetor de objetivos [F1, F2]

1. w <- decode(x) para matriz w[i,d].
2. Expandir w para representacao completa x_full conforme disponibilidade.
3. Calcular F1 (demanda nao atendida):
	para cada (u,d,t), capacidade <- soma de Q[i,d,t] dos medicos com w[i,d]=u.
	unmet(u,d,t) <- max(0, demanda(u,d,t) - capacidade).
4. Calcular F2 (trocas):
	para cada medico, percorrer dias com estado inicial;
	contar troca quando clinica do dia difere do estado anterior.
5. Retornar [soma_unmet, soma_trocas].
```

---

## Pseudocódigo do CompactNSGA2Extended

```text
ENTRADA: instancia, operadores compactos, parametros O1..O6, criterio de parada
SAIDA: fronteira de Pareto compacta e estatisticas

1. Construir CompactProblem e operadores (CompactSampling, CompactDayBasedCrossover, CompactMutation).
2. Inicializar algoritmo CompactNSGA2Extended.
3. Se use_extreme_initialization: gerar P0 com vies para extremos; senao P0 padrao.
4. Avaliar P0.
5. Para cada geracao g ate parada:
6.    (Opcional) aplicar regras de two-stage evolution.
7.    (Opcional) adaptar parametros por diversidade observada.
8.    Gerar infills (offspring) por selecao + crossover + mutation.
9.    Se use_repair: reparar infills com problem.repair().
10.   Aplicar sobrevivencia NSGA-II padrao.
11.   (Opcional) reinjetar extremos periodicamente.
12.   (Opcional) atualizar arquivo de fronteira e injetar limites.
13.   (Opcional) aplicar busca local memetica na elite.
14. Retornar solucoes nao dominadas, historico e estatisticas de aprimoramento.
```

---

## Avaliação e Reparo

No modo compacto:
1. parte das restrições é respeitada por construção da codificação,
2. demais restrições são tratadas em avaliação e rotinas de reparo,
3. o algoritmo compacto estendido pode aplicar reparo pós-geração.

Referência:
- [engine/metaheuristics/nsga2/compact/algorithm.py](engine/metaheuristics/nsga2/compact/algorithm.py)

---

## Configuração Típica

```bash
python engine/runners/run_compact_nsga2.py \
	--instance_file data/input/instances/... \
	--output_dir data/output/nsga2/compact_run \
	--pop_size 100 \
	--termination_method time \
	--termination_value 3600 \
	--sampling_use_extreme true \
	--sampling_extreme_ratio 0.2
```

Parâmetros relevantes:
1. `day_exchange_prob`,
2. `mutation_n_moves_pct`,
3. `use_repair`,
4. opções de diversidade/estágios/extremos (análogas ao extended).

---

## Integração de Pipeline

O pipeline principal de NSGA despacha para a versão compacta quando `algorithm=compact_nsga2`.

Referência:
- [pipelines/run_nsga2_pipeline.py](pipelines/run_nsga2_pipeline.py#L101)

---

## Texto Sugerido para Metodologia (Tese)

"Para mitigar o custo computacional da codificação binária completa, adotou-se uma representação compacta por atribuição diária médico-clínica. Essa reformulação reduz a dimensão do espaço de decisão e permite aumentar o número efetivo de gerações, mantendo a natureza multiobjetivo do NSGA-II e favorecendo a exploração da fronteira de Pareto em horizontes temporais extensos."

