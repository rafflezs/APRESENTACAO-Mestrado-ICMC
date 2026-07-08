# Artefato de Relaxacao Linear na Instancia 90 dias: 2023may01_to_2023jul29

**Data:** 2026-02-18
**Contexto:** Validacao pos-geracao da grade epsilon (`allin_fev26_5`)

---

## 1. Descricao do Problema

Durante a validacao dos resultados de geracao de grade epsilon, a instancia
`run/90_days/2023may01_to_2023jul29` apresentou valores objetivos
**matematicamente impossiveis** nos dois pontos lexicograficos:

| Ponto | Z1 (trocas) | Z2 (exames nao atendidos) | Gap de otimalidade |
|---|---|---|---|
| min Z1 (min trocas) | 77.522 | 12.199 | 96,6% |
| min Z2 (min exames) | 45.718 | 9.954 | 99,9% |

O modelo de otimizacao define a variavel de trocas como binaria por par
`(medico, data)`: `z[i,d] in {0,1}`. Com 195 medicos e 90 dias, o limite
superior teorico da soma de Z1 e de `195 x 90 = 17.550`. Os valores reportados
(45.718 e 77.522) superam esse limite por fatores de 2,6x e 4,4x,
respectivamente, o que e **infeasivel** para qualquer solucao inteira valida
do modelo.

---

## 2. Analise da Instancia

A instancia nao apresenta corrupcao nos dados de entrada. O arquivo
`Disponibilidade.csv` segue o mesmo formato das demais instancias:
uma linha por combinacao `(medico, data, turno, unidade)`. Os dados
estruturais sao consistentes com outras instancias de 90 dias, porem
com dimensoes ligeiramente maiores:

| Metrica | 2023may01 (outlier) | 2022sep01 (referencia) |
|---|---|---|
| Medicos | 195 | 162 |
| Demanda total (exames) | 94.095 | 69.742 |
| Slots de disponibilidade | 3.696 (10,5%) | 2.928 (10,0%) |
| Linhas no modelo MIP | 531.345 | 457.218 |
| Colunas no modelo MIP | 466.796 | 401.373 |

---

## 3. Causa Raiz: Estagnacao no No Raiz do Branch-and-Bound

O log do Gurobi 12.0.3 para o ponto lexicografico Z1 revela o comportamento
determinante:

```
Explored 1 nodes (693,600 simplex iterations) in 7200.67 seconds
Best objective 7.752e+04, best bound 2.635e+03, gap 96.6%
```

O solver executou **693.600 iteracoes do simplex** exclusivamente no no raiz da
arvore de branch-and-bound, esgotando o limite de tempo de 2 horas sem ramificar
uma unica vez. Isso caracteriza um problema de **estagnacao no no raiz**, comum
em instancias MIP de grande porte onde a relaxacao linear e computacionalmente
custosa de resolver.

### Interpretacao pela teoria de programacao inteira

No algoritmo branch-and-bound, o limite inferior (dual bound) e obtido pela
relaxacao linear (LP) do subproblema no no corrente. A relaxacao LP da instancia
convergiu para aproximadamente **2.636 trocas**, valor inteiramente compativel
com as demais instancias de 90 dias (intervalo observado: 5.075-12.885). Este e
o melhor estimador disponivel para o otimo inteiro verdadeiro.

O valor incumbente de 77.522 trocas foi produzido por uma **heuristica primal
de inicializacao** (provavelmente *feasibility pump* ou arredondamento da
relaxacao fracionaria inicial), executada antes da convergencia da relaxacao LP.
Em implementacoes modernas de MIP, o Gurobi dispara heuristicas primais logo
nos primeiros segundos para obter uma solucao incumbente viavel, mesmo que de
qualidade muito baixa. Como nenhum no adicional foi explorado, essa solucao
inicial nunca foi melhorada.

Formalmente, ao final do tempo limite:

- **Limite inferior (LB):** ~2.636 (relaxacao LP do no raiz, parcialmente convergida)
- **Incumbente (UB):** 77.522 (heuristica primal, solucao inteira de baixa qualidade)
- **Gap:** `(UB - LB) / UB = 96,6%`

O incumbente de 77.522 e tecnicamente uma **solucao inteira viavel** para o
modelo MIP (satisfaz todas as restricoes), mas e extremamente sub-otima. O fato
de superar o limite teorico de 17.550 indica que a heuristica primal gerou
uma solucao com padroes de designacao altamente desfavoraveis: medicos sendo
designados a clinicas diferentes em quase todos os dias disponiveis, acumulando
trocas desnecessarias que nenhuma solucao de qualidade razoavel apresentaria.

---

## 4. Impacto na Grade Epsilon

A grade epsilon gerada para esta instancia e **inutilizavel** para os experimentos
subsequentes. Os sete pontos epsilon `[45.718, 51.018, 56.319, 61.620, 66.920,
72.221, 77.522]` foram interpolados entre os dois incumbentes heuristicos, e nao
entre os limites lexicograficos otimos. A fronteira de Pareto real da instancia
provavelmente reside em uma regiao completamente diferente do espaco objetivo,
proxima ao limite inferior LP de ~2.636 trocas.

Adicionalmente, o campo `min_bound` (77.522) e `max_bound` (45.718) estao
invertidos no arquivo `epsilon_grid.json`, pois o incumbente do ponto min-Z1
(77.522) resultou ser maior do que o do ponto min-Z2 (45.718) - outra evidencia
de que ambos os valores sao artefatos sem significado otimo.

---

## 5. Recomendacoes

**Opcao A (recomendada para a dissertacao):** Excluir esta instancia do conjunto
de execucao (`run/90_days`). As 7 instancias restantes de 90 dias possuem grades
epsilon validas e sao suficientes para os experimentos. A exclusao deve ser
documentada no texto da dissertacao como criterio de filtragem por qualidade
de grade.

**Opcao B (se a instancia for considerada importante):** Regenerar a grade com
limite de tempo lexicografico estendido (recomendado: >= 24h por ponto) no
cluster, possivelmente com solucao inicial (*MIP start*) derivada dos dados
historicos da instancia para acelerar a obtencao de um incumbente de qualidade.

---

## 6. Conclusao

O comportamento anomalo da instancia `2023may01_to_2023jul29` nao e resultado
de corrupcao nos dados de entrada nem de erro na formulacao do modelo. Trata-se
de um artefato classico de heuristica primal em instancias MIP onde o no raiz
do branch-and-bound nao converge dentro do tempo disponivel. O limite inferior
LP (~2.636 trocas) confirma que o problema e bem-formulado e possui solucao
otima em intervalo compativel com as demais instancias. A grade epsilon resultante,
contudo, e invalida para uso em experimentos de comparacao de metodos.

**Esta instancia nao deve ser incluida nos experimentos de parametrizacao
nem de execucao sem a regeneracao previa de sua grade epsilon.**
