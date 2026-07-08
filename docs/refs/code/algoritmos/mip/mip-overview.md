# MIP Overview: Metodologia de Solucao para Alocacao de Medicos

## Objetivo Metodologico

Este documento consolida a metodologia MIP usada no projeto para resolver o problema de alocacao de medicos em clinicas de imagem com dois objetivos conflitantes:

1. Minimizar exames nao atendidos.
2. Minimizar trocas de clinica por medico ao longo do horizonte.

A estrategia combina otimizacao exata multiobjetivo (epsilon-constraint) com matheuristicas (Relax-and-Fix e Fix-and-Optimize), mantendo compatibilidade com execucao local e em cluster.

---

## Definicao do Problema

### Horizonte e Indices

1. `i`: medico.
2. `u`: clinica.
3. `d`: data.
4. `t`: turno.

Um periodo e definido como a tupla `(d, t)`.

### Variaveis de Decisao

1. `x[i,u,d,t]`: 1 se medico `i` atende clinica `u` no periodo `(d,t)`.
2. `w[i,u,d]`: 1 se medico `i` esta associado a clinica `u` no dia `d`.
3. `c[u,d,t]`: demanda nao atendida na clinica `u` no periodo `(d,t)`.
4. `z[i,d]`: indicador de troca de clinica do medico `i` no dia `d`.

### Restricoes Estruturais

1. Qualificacao: medico so pode atuar em clinicas permitidas.
2. Disponibilidade: medico so pode atuar em periodos disponiveis.
3. Consistencia diaria: alocacoes por turno respeitam alocacao diaria (`x` coerente com `w`).
4. Capacidade de salas: numero de medicos por clinica/periodo limitado por salas disponiveis.
5. Cobertura minima: clinica aberta e com sala disponivel deve receber ao menos um medico.

---

## Abordagem Multiobjetivo

### Metodo Principal: Epsilon-Constraint

O framework MIP usa o metodo epsilon-constraint para gerar fronteira de Pareto:

1. Define-se um objetivo primario (`swaps` ou `exams`).
2. O objetivo secundario e limitado por uma grade de valores epsilon.
3. Para cada epsilon, resolve-se um problema mono-objetivo restrito.

Esse desenho permite comparar com clareza qualidade de cobertura versus estabilidade de agenda.

### Fase Lexicografica

A fase lexicografica calcula os extremos da fronteira e pode usar:

1. `exact`.
2. `relax_and_fix`.
3. `hybrid` (R&F + F&O).
4. `tiered` (exato e fallback/melhoria hibrida conforme gap).

---

## Solvers e Matheuristicas

## 1) Exato (Branch-and-Bound)

Resolucao direta do MIP com limite de tempo e `mip_gap`, apropriada para instancias menores ou como referencia de qualidade.

## 2) Relax-and-Fix (R&F)

Heuristica de construcao por janelas temporais:

1. Decompoe o horizonte em janelas de periodos.
2. Mantem integralidade na janela corrente.
3. Relaxa periodos futuros.
4. Fixa decisoes binarias (`w`) da janela.
5. Executa solve final de polish com warm-start.

Observacoes praticas:

1. `mip_gap` retornado e fracao (nao percentual).
2. Parametro legado `window_size` (dias) ainda existe; preferir `window_size_pct`.
3. O default de `overlap` pode variar entre classe e pipelines de execucao.

## 3) Fix-and-Optimize (F&O)

Heuristica de refinamento local:

1. Requer solucao inicial (de R&F, exato, ou warm-start).
2. Libera uma vizinhanca de periodos por iteracao.
3. Fixa variaveis fora da vizinhanca com base na solucao corrente.
4. Mantem a melhor solucao encontrada (best-tracking).

Observacoes praticas:

1. Retorno e focado em melhoria primal (`obj_val`).
2. `obj_bound` e `mip_gap` globais nao sao reportados (None).
3. Em horizontes curtos, `neighborhood_size_pct` e truncado com piso minimo de 2 periodos.

## 4) Hibrido (R&F + F&O)

Pipeline de duas fases:

1. R&F constroi solucao factivel rapidamente.
2. F&O refina qualidade com o tempo restante.

Essa combinacao melhora robustez em instancias medias e grandes, com controle explicito de orcamento temporal.

---

## Gestao de Tempo e Orçamento Computacional

O controle de tempo usa hierarquia unica por ponto epsilon:

1. `TIME_LIMIT`: orcamento total por epsilon.
2. Em R&F: divisao entre janelas e polish via `RF_POLISH_RATIO`.
3. Em hibrido: divisao entre R&F e F&O via `RF_RATIO`.

Consequencia metodologica: comparacoes entre metodos devem usar o mesmo `TIME_LIMIT` e configuracao coerente de ratios.

---

## Pipeline Experimental

Fluxo recomendado para comparabilidade:

1. Gerar grade epsilon compartilhada (`run_epsilon_grid_pipeline.py`).
2. Executar experimentos (`run_epsilon.py` ou `run_epsilon_pipeline.py`) com o mesmo grid.
3. Rodar analise posterior (`analytics/runners/run_analysis.py` ou pipeline de analise).

Pontos relevantes para reproducao:

1. O pipeline de grid aceita `lex_method` com `exact`, `relax_and_fix`, `hybrid` e `tiered`.
2. O pipeline de epsilon aceita parametros modernos e legados (`rf_*`, `fo_*`).
3. Parametros de memoria (`soft_mem_limit`, `nodefile_start`, `nodefile_dir`) devem ser registrados em execucoes longas.

---

## Metricas para Capitulo de Metodologia

Para reporte academico, recomenda-se destacar:

1. Qualidade multiobjetivo: pares `(exams, swaps)` e fronteira de Pareto.
2. Eficiência: tempo total, tempo por epsilon, uso de memoria.
3. Robustez: taxa de sucesso, status de solve, ocorrencias de `TIME_LIMIT` e `MEM_LIMIT`.
4. Estabilidade: variacao entre instancias e horizontes (15, 30, 60, 90 dias).
5. Comparabilidade: mesmo grid epsilon e mesmo budget temporal por metodo.

---

## Diretrizes de Escrita para a Tese (Capitulo de Metodologia)

Estrutura sugerida:

1. **Modelagem do problema**: conjuntos, parametros, variaveis, restricoes e objetivos.
2. **Metodo de solucao**: epsilon-constraint e justificativa de multiobjetivo.
3. **Aceleracao computacional**: R&F, F&O e estrategia hibrida.
4. **Protocolo experimental**: datasets, horizontes, parametros, infraestrutura.
5. **Validade e reproducibilidade**: controle de grid, tempo, gap e seeds.

Aspectos que merecem justificativa explicita no texto:

1. Escolha de decomposicao por periodo `(data, turno)`.
2. Uso de grade epsilon compartilhada para comparacao justa.
3. Uso de metodos hibridos em cenarios de maior escala.
4. Interpretacao de gap em heuristicas sem bound dual global (caso F&O).

---

## Limitacoes Metodologicas

1. Metodos heuristico-matheuristicos nao garantem otimalidade global.
2. F&O fornece melhoria local sem bound dual confiavel do problema completo.
3. Sensibilidade de desempenho a parametrizacao temporal (`window_size_pct`, `rf_ratio`, `polish_ratio`).
4. Resultados dependem de qualidade da instancia e da condicao inicial.

---

## Conclusao

A metodologia MIP adotada equilibra qualidade e escalabilidade por meio de uma arquitetura em camadas:

1. Modelagem exata para fidelidade das restricoes.
2. Epsilon-constraint para exploracao multiobjetivo.
3. Matheuristicas para viabilidade computacional em horizontes longos.
4. Pipelines reprodutiveis para comparacao rigorosa entre metodos.

Esse desenho e adequado para um capitulo de metodologia de mestrado orientado a pesquisa aplicada em otimizacao de escalas medicas.
