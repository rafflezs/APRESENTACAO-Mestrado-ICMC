# Limitacoes do NSGA-II Base e Extended para o Problema de Alocacao de Medicos

**Data:** 2026-02-20
**Contexto:** Analise pos-execucao de experimentos locais com NSGA-II Extended vs. metodos MIP exatos

---

## 1. Introducao

Este documento apresenta uma analise das limitacoes observadas nas implementacoes NSGA-II base e NSGA-II Extended para o problema biobjetivo de alocacao de medicos a clinicas de diagnostico por imagem. A avaliacao compara os resultados obtidos pelo algoritmo genetico com os produzidos pelo metodo epsilon-restrito exato (Gurobi 12.0.3), identificando lacunas estruturais e operacionais que comprometem a competitividade do NSGA-II neste dominio.

Os dados experimentais provem de execucoes locais (NSGA-II Extended, 300s, pop=100) e execucoes em cluster (MIP Exato, 3600s por ponto epsilon, 7 pontos). Embora os orcamentos temporais sejam distintos, a analise foca em limitacoes qualitativas que persistem independentemente do tempo disponivel.

---

## 2. Descricao dos Metodos Avaliados

### 2.1 NSGA-II Extended

Implementacao estendida do NSGA-II (Deb et al., 2002) com seis modulos adicionais:

1. **Inicializacao com estrategias extremas** (20% da populacao): solucoes orientadas a minimizar trocas ou exames nao atendidos individualmente.
2. **Controle adaptativo de diversidade**: ajuste dinamico das taxas de cruzamento e mutacao com base em metricas de diversidade genotipica e fenotipica.
3. **Evolucao em dois estagios**: fase de exploracao (0-50% das geracoes) seguida de fase de refinamento (50-100%).
4. **Reinjecao periodica de extremos**: insercao de 4 solucoes extremas a cada 20 geracoes para prevenir perda de cobertura lexicografica.
5. **Arquivo de solucoes de fronteira**: preservacao dos melhores valores historicos de cada objetivo.
6. **Busca local em elite** (desabilitada por padrao).

Operadores geneticos: cruzamento por blocos diarios (`day_based`, prob=0.9), mutacao por reatribuicao de slots (`slot_reassignment`, prob=0.3).

### 2.2 MIP Exato (Epsilon-Restrito)

Metodo epsilon-restrito com resolucao lexicografica para determinacao dos limites da fronteira de Pareto, seguido de 7 pontos epsilon uniformemente espacados. Cada ponto resolvido como MIP com Gurobi 12.0.3, limite de 3600s por ponto. 

---

## 3. Limitacoes Identificadas

### 3.1 Gargalo Computacional na Inicializacao

A limitacao mais critica observada e o custo computacional da geracao da populacao inicial. O `ConstraintAwareSampling` constroi cada individuo de forma incremental, verificando todas as restricoes (G1-G6) a cada atribuicao. Para instancias de grande porte, a geracao de 100 individuos consome a quase totalidade do orcamento temporal.

| Horizonte | Medicos | Variaveis | Tempo total | Geracoes evolutivas |
|-----------|---------|-----------|-------------|---------------------|
| 15 dias   | 127     | ~430.530  | 300s        | 1                   |
| 30 dias   | 141     | ~592.200  | 300s        | 1                   |
| 60 dias   | 146     | ~1.226.400| 300s        | 1                   |
| 90 dias   | 154     | ~1.496.880| 300s        | 1                   |

Em todos os horizontes testados localmente, o algoritmo completou **apenas 1 geracao** (exceto a instancia 30d Jul, que atingiu 4 geracoes em 2942s). Isso significa que a populacao final e essencialmente a populacao inicial -- nenhuma pressao seletiva, cruzamento ou mutacao efetiva ocorreu. Os modulos de adaptacao de diversidade, evolucao em dois estagios e reinjecao periodica tornam-se inoperantes quando nao ha geracoes suficientes para ativa-los. 

**Implicacao:** O NSGA-II Extended, nestes experimentos, funciona como um algoritmo construtivo multipartida (*multi-start greedy*), nao como um algoritmo evolutivo propriamente dito.

### 3.2 Compressao da Fronteira de Pareto

A fronteira de Pareto produzida pelo NSGA-II apresenta amplitude drasticamente
inferior a do MIP exato. A tabela abaixo compara as faixas objetivas para
instancias representativas:

| Horizonte | Metodo | Trocas (min-max) | Exames nao atendidos (min-max) | Amplitude trocas | Amplitude exames |
|-----------|--------|------------------|-------------------------------|------------------|------------------|
| 30d (Jan) | NSGA-II Ext. | 248 - 359 | 1.945 - 2.215 | 111 | 270 |
| 30d (Jan) | MIP Exato | 58 - 202 | 1.194 - 4.469 | 144 | 3.275 |
| 30d (Jul) | NSGA-II Ext. | 251 - 300 | 1.745 - 2.162 | 49 | 417 |
| 30d (Jul) | MIP Exato | 46 - 301 | 2.065 - 6.689 | 255 | 4.624 |
| 60d       | NSGA-II Ext. | 583 - 598 | 4.717 - 4.982 | 15 | 265 |
| 60d       | MIP Exato | 64 - 1.387 | 2.861 - 9.895 | 1.323 | 7.034 |
| 90d       | NSGA-II Ext. | 892 - 1.441 | 8.621 - 9.117 | 549 | 496 |
| 90d       | MIP Exato | 182 - 2.187 | 3.947 - 14.673 | 2.005 | 10.726 |

A compressao e mais severa no objetivo de trocas. No caso de 60 dias, o NSGA-II produz uma faixa de apenas 15 trocas (583-598), enquanto o MIP cobre 1.323 trocas (64-1.387) -- uma razao de compressao de **88:1**.

**Causa raiz:** Os operadores geneticos (cruzamento por blocos diarios e mutacao por reatribuicao de slots) produzem perturbacoes locais que nao conseguem explorar regioes distantes do espaco de solucoes. A ausencia de evolucao efetiva (Secao 3.1) agrava este problema, pois as estrategias extremas de inicializacao cobrem apenas 20% da populacao e nao sao refinadas.

### 3.3 Incapacidade de Atingir Extremos Lexicograficos

O metodo epsilon-restrito determina os extremos da fronteira de Pareto via otimizacao lexicografica: primeiro minimiza-se Z1 (trocas), depois minimiza-se Z2 (exames nao atendidos) sujeito a Z1 <= Z1*. Esses extremos definem a extensao real da fronteira.

O NSGA-II nao possui mecanismo analogo. Mesmo com estrategias de inicializacao extrema, as solucoes geradas por heuristicas construtivas ficam distantes dos otimos lexicograficos:

| Horizonte | Obj. | NSGA-II melhor | MIP melhor | Gap relativo |
|-----------|------|----------------|------------|--------------|
| 30d (Jan) | Trocas | 248 | 58 | +327% |
| 30d (Jan) | Exames | 1.945 | 1.194 | +63% |
| 60d | Trocas | 583 | 64 | +811% |
| 60d | Exames | 4.717 | 2.861 | +65% |
| 90d | Trocas | 892 | 182 | +390% |
| 90d | Exames | 8.621 | 3.947 | +118% |

Os gaps sao particularmente elevados no objetivo de trocas, onde o NSGA-II apresenta solucoes 3x a 9x piores que o MIP. No objetivo de exames nao atendidos, os gaps variam de 63% a 118%.

**Interpretacao:** A exploracao lexicografica do MIP beneficia-se da relaxacao linear (LP) e do branch-and-bound, que fornecem limites duais e orientam a busca para regioes otimas. O NSGA-II, por operar exclusivamente no espaco de solucoes inteiras viaveis, carece de informacao dual para guiar a exploracao.

### 3.4 Violacoes da Restricao de Cobertura Minima (G6)

Nas execucoes mais recentes, todas as solucoes NSGA-II apresentaram violacoes da restricao G6 (cobertura minima), com valores tipicos entre 49 e 64 periodos sem cobertura minima atendida. Em contrapartida, o modelo MIP garante G6 como restricao rigida (hard constraint).

| Horizonte | Solucoes | G6 media | G6 max |
|-----------|----------|----------|--------|
| 30d (Jan) | 7 | 60,6 | 64 |
| 30d (Jul) | 22 | 53,1 | 63 |
| 90d       | 5 | 225,6 | 289 |

A implementacao atual trata G6 no modo `hard` no `ConstraintManager`, porem o sistema de reparo iterativo (maximo 3 iteracoes) nao garante convergencia para satisfacao completa de G6 em instancias de grande porte. O mecanismo de reparo de G6 depende da disponibilidade de medicos nao alocados com qualificacao para a clinica demandante -- recurso frequentemente esgotado apos os reparos de G2 (um clinica por dia) e G5 (capacidade de salas).

**Observacao:** As execucoes anteriores (`.old`) reportavam `fully_feasible=True` e `G6=0`, sugerindo que a logica de contagem de violacoes pode ter sido refinada entre as versoes, revelando violacoes que antes eram mascaradas.

### 3.5 Diversidade Genetica Insuficiente

As metricas de diversidade reportadas sao consistentemente baixas:

| Horizonte | Diversidade inicial | Diversidade final | Non-dominated |
|-----------|---------------------|-------------------|---------------|
| 15d | 0,0033 | 0,0033 | 6/100 |
| 30d (Jan) | 0,0027 | 0,0027 | 5/100 |
| 60d | 0,0030 | 0,0030 | 2/100 |
| 90d | 0,0042 | 0,0042 | 5/100 |

A diversidade permanece identica entre a geracao inicial e final (confirmando que nenhuma evolucao ocorreu). Os valores de diversidade de Hamming (~0,003) indicam que os individuos compartilham ~99,7% de seus genes -- uma populacao quase homogenea. Apenas 2% a 6% dos individuos sao nao dominados.

O controle adaptativo de diversidade, projetado para intervir quando a diversidade cai abaixo de 70% do alvo (0,15 na fase inicial), nunca tem oportunidade de atuar porque o limite de tempo e atingido antes da segunda geracao.

### 3.6 Escalabilidade Desfavoravel com o Horizonte de Planejamento

A dimensionalidade do problema cresce linearmente com o numero de dias (|I| x |U| x |D| x |T|), mas o custo da amostragem construtiva cresce super-linearmente devido as verificacoes de restricoes interdependentes. A tabela abaixo ilustra:

| Horizonte | Variaveis | Geracoes em 300s | Geracoes em 3600s (estimado) |
|-----------|-----------|------------------|------------------------------|
| 15d | ~430k | 1 | ~12 |
| 30d | ~592k | 1-4 | ~12-48 |
| 60d | ~1.226k | 1 | ~12 |
| 90d | ~1.497k | 1 | ~12 |

Mesmo com 12x mais tempo (3600s), a estimativa sugere que o numero de geracoes permaneceria insuficiente para convergencia evolutiva significativa. Algoritmos geneticos tipicamente requerem centenas a milhares de geracoes para convergir (Deb et al., 2002), o que e inviavel nesta escala de problema. 

### 3.7 Operadores Geneticos de Escopo Limitado

Os operadores selecionados como melhores durante a fase de parametrizacao apresentam limitacoes estruturais para este problema:

**Cruzamento por blocos diarios (`day_based`):**
- Preserva naturalmente G2 (um clinica por dia), o que e vantajoso para viabilidade, mas limita a exploracaoado a recombinacoes de dias inteiros. - Nao permite recombinacao intra-dia (trocar medico em um turno mantendo outro), o que reduz a resolucao da busca.

**Mutacao por reatribuicao de slots (`slot_reassignment`):**
- Realiza 1-3 reatribuicoes por evento de mutacao, o que e insuficiente para causar mudancas significativas em solucoes com centenas de milhares   de variaveis. - Maximo de 10 tentativas para encontrar uma mutacao valida; em instancias altamente restritas, frequentemente falha silenciosamente.

Ambos os operadores produzem perturbacoes de *vizinhanca local*, incapazes de transpor barreiras estruturais no espaco de solucoes -- comportamento analogo ao de uma busca local sem mecanismo de escape.

---

## 4. Comparacao Sintetica: Onde o NSGA-II Compete e Onde Falha

### 4.1 Regiao de Competitividade

O NSGA-II apresenta alguma competitividade na **regiao intermediaria** da fronteira de Pareto, onde ambos os objetivos possuem valores moderados. No caso de 90 dias, a solucao NSGA-II com 8.621 exames nao atendidos e 1.441 trocas situa-se em uma regiao que o MIP cobre com gap de otimalidade de 88-96% -- indicando que o MIP tambem produz solucoes de baixa qualidade nessa regiao quando limitado a 3600s por ponto.

### 4.2 Regioes de Falha

O NSGA-II falha consistentemente em duas regioes:

1. **Extremo de minimizacao de trocas:** Requer alocacoes estacionarias (medicos mantidos nas mesmas clinicas ao longo do horizonte), o que o algoritmo construtivo raramente produz. O MIP atinge ~182 trocas em 90d; o NSGA-II nao desce abaixo de 892.

2. **Extremo de minimizacao de exames:** Requer saturacao maxima de capacidade, priorizando cobertura sobre estabilidade. O MIP atinge ~3.947 exames nao atendidos em 90d; o NSGA-II nao desce abaixo de 8.621.

### 4.3 Vantagem Temporal

O NSGA-II completa sua execucao em 5-12 minutos (incluindo pos-processamento), enquanto o MIP requer 7-25 horas para 7 pontos epsilon. Em cenarios onde o tempo de resposta e critico e solucoes aproximadas sao aceitaveis, o NSGA-II oferece utilidade pratica, mesmo com qualidade inferior.

---

## 5. Analise das Causas Fundamentais

As limitacoes descritas decorrem de tres fatores inter-relacionados:

### 5.1 Representacao cromossomica de alta dimensionalidade

A codificacao direta (um gene por variavel `x[i,u,d,t]`) resulta em cromossomos com ~500k a ~1.5M genes. Essa dimensionalidade:
- Torna a amostragem inicial extremamente custosa.
- Dilui o efeito dos operadores geneticos (mutar 1-3 genes em 1.5M e estatisticamente irrelevante).
- Impede diversidade genuina (99,7% de homogeneidade genotipica).

### 5.2 Ausencia de informacao dual

O branch-and-bound do MIP utiliza limites duais (relaxacao LP) para podar regioes sub-otimas e orientar a busca. O NSGA-II nao possui mecanismo equivalente -- toda avaliacao e feita exclusivamente no espaco primal inteiro, sem estimativa de quao longe uma solucao esta do otimo.

### 5.3 Restricoes altamente acopladas

As seis restricoes do problema (G1-G6) sao interdependentes: reparar G2 pode violar G5; reparar G5 pode violar G6. O sistema iterativo de reparo (3 iteracoes) nao garante convergencia, e a ordem fixa de reparos (G4->G1->G3->G2->G5->G6) pode sistematicamente desfavorecer determinadas restricoes (notadamente G6).

---

## 6. Recomendacoes para Trabalhos Futuros

1. **Representacao compacta:** Codificar decisoes no nivel de medico-dia (`w[i,d]` = clinica atribuida), reduzindo a dimensionalidade para |I| x |D| (~14.000 variaveis para 90d vs. ~1.500.000).

2. **Inicializacao hibrida:** Utilizar solucoes MIP de qualidade (warm-start) como parte da populacao inicial, combinando a qualidade do MIP com a diversidade do NSGA-II.

3. **Busca local memética:** Implementar busca local intensiva como operador pos-cruzamento (algoritmo memetico), explorando vizinhancas maiores que a mutacao por reatribuicao de slots.

4. **Orcamento temporal aumentado:** Dado o custo da inicializacao, avaliar execucoes com 1-4 horas para permitir ao menos 10-50 geracoes evolutivas.

5. **Decomposicao temporal:** Resolver sub-horizontes menores (7-15 dias) e compor a solucao global, reduzindo a dimensionalidade efetiva.

---

## 7. Conclusao

As implementacoes NSGA-II base e Extended apresentam limitacoes fundamentais para o problema de alocacao de medicos na escala operacional avaliada (15-90 dias, 127-154 medicos, 35-36 clinicas). A principal deficiencia e o custo proibitivo da inicializacao construtiva, que consome o orcamento temporal antes que a evolucao genetica possa operar. Consequentemente, o algoritmo funciona como uma heuristica construtiva multi-partida, sem pressao seletiva efetiva.

As extensoes implementadas (controle adaptativo de diversidade, evolucao em dois estagios, inicializacao extrema, reinjecao periodica) sao teoricamente adequadas mas operacionalmente ineficazes, pois pressupoe dezenas a centenas de geracoes que o algoritmo nao consegue completar. A fronteira de Pareto resultante e comprimida em 88:1 a 1:1 em relacao ao MIP exato, com gaps de 63% a 811% nos extremos.

Para que o NSGA-II se torne competitivo neste dominio, seria necessario reduzir drasticamente a dimensionalidade do problema (representacao compacta) ou o custo por geracao (decomposicao temporal), alem de incorporar mecanismos de busca local intensiva.

---

## Referencias

- Deb, K., Pratap, A., Agarwal, S., & Meyarivan, T. (2002). A fast and elitist multiobjective genetic algorithm: NSGA-II. *IEEE Transactions on Evolutionary Computation*, 6(2), 182-197.
- Smaldino, P. E. et al. (2023). Maintaining transient diversity is important for management of multiobjective evolutionary optimization. *Evolutionary Computation*, 31(1), 1-27.
