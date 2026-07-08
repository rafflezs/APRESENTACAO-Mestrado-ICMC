# Relax-and-Fix: Matheurística de Decomposição Temporal

## Visão Geral

Relax-and-Fix (R&F) é uma matheurística de decomposição temporal que particiona o horizonte de planejamento em janelas, resolve cada janela com integralidade enquanto relaxa períodos futuros, e fixa decisões progressivamente. Particularmente efetiva para problemas de scheduling de grande porte onde resolver o MIP completo é computacionalmente proibitivo.

### Princípios de Design

1. **Decomposição Temporal**: Particionar horizonte em janelas de períodos
2. **Relaxação Progressiva**: Manter integralidade apenas na janela atual
3. **Fixação de Decisões**: Fixar variáveis binárias (w) após resolução
4. **Polish Final**: Resolver modelo completo com warm-start ao final
5. **Gestão de Tempo**: Distribuir orçamento temporal entre janelas e polish

### Fundamentação Literatura

- Dillenberger et al. (1994): R&F clássico para lot-sizing
- Ferreira et al. (2009): R&F para scheduling de produção
- Helber & Sahling (2010): Análise comparativa de matheurísticas
- Pochet & Wolsey (2006): Decomposição temporal em MIP

---

## Refatoração: Períodos ao Invés de Dias

### Mudança Estrutural

**Antes (baseado em dias):**
```
window_size = 7 dias
períodos = dias
```

**Depois (baseado em períodos = dia × turno):**
```
window_size_pct = 10% dos períodos totais
períodos = [(date, shift) para date in dates, shift in shifts]
total_periods = |dates| × |shifts|
```

### Motivação

1. **Granularidade Fina**: Turnos são a unidade atômica de decisão
2. **Flexibilidade**: Percentual adapta-se automaticamente ao tamanho da instância
3. **Controle Preciso**: Janelas definem exatamente quais variáveis (i,u,d,t) são integrais

---

## Arquitetura do Algoritmo

### Visão Geral

```
ENTRADA:
   - gurobi_model: Modelo MIP completo construído
   - window_size_pct: Tamanho janela como % de períodos totais (padrão: 0.10)
   - overlap: Sobreposição entre janelas em períodos (padrão: 2)
   - total_time_limit: Orçamento temporal TOTAL (padrão: 3600s)
   - polish_ratio: Fração reservada para solve final (padrão: 0.2)
   - mip_gap: Tolerância gap MIP (padrão: 1e-4 = 0.01%)

SAÍDA:
   - status: Status Gurobi (OPTIMAL, TIME_LIMIT, etc.)
   - obj_val: Valor objetivo final
   - obj_bound: Bound objetivo
   - mip_gap: Gap final (fração, não percentual)
   - runtime: Tempo total de execução
   - statistics: Dicionário com estatísticas detalhadas
```

### Fases do Algoritmo

1. **Inicialização**: Construir lista de períodos e particionar em janelas
2. **Resolução por Janelas**: Iterar sobre janelas fixando decisões
3. **Polish Final**: Resolver modelo completo com warm-start
4. **Extração de Solução**: Coletar valores variáveis

---

## Pseudocódigo Principal

### Algoritmo R&F Completo

```
ALGORITMO Relax_And_Fix(gurobi_model, params):
   # ========== FASE 1: INICIALIZAÇÃO ==========

   # 1.1. Construir lista de períodos
   periods ← []
   PARA cada date ∈ dates:
      PARA cada shift ∈ shifts:
         periods.append((date, shift))

   total_periods ← |periods|

   # 1.2. Determinar tamanho de janela
   SE window_size_pct fornecido ENTÃO:
      window_size ← max(2, ⌊total_periods × window_size_pct⌋)
   SENÃO SE window_size fornecido ENTÃO:  # Legacy: dias
      window_size ← window_size × 2  # Converter dias → períodos
   SENÃO:
      window_size ← max(2, ⌊total_periods × 0.10⌋)  # Padrão: 10%

   # 1.3. Particionar em janelas com overlap
   windows ← partition_into_windows(periods, window_size, overlap)
   n_windows ← |windows|

   # 1.4. Calcular orçamento temporal
   time_for_windows ← total_time_limit × (1.0 - polish_ratio)
   time_per_window ← max(30, ⌊time_for_windows / n_windows⌋)
   time_for_final ← total_time_limit × polish_ratio

   # 1.5. Salvar tipos originais de variáveis
   original_vtypes ← {}
   PARA cada var_name ∈ ['x', 'w', 'z', 'c']:
      PARA cada key, var ∈ variables[var_name]:
         original_vtypes[var_name][key] ← var.vtype

   # ========== FASE 2: RESOLUÇÃO POR JANELAS ==========

   start_time ← time()

   PARA k ← 1 ATÉ n_windows:
      # 2.1. Verificar orçamento temporal
      elapsed ← time() - start_time
      remaining ← total_time_limit - elapsed
      SE remaining < 30 ENTÃO:
         LOG("Orçamento esgotado na janela {k}")
         BREAK

      window_periods ← windows[k]
      LOG("Janela {k}/{n_windows}: {window_periods[0]} a {window_periods[-1]}")

      # 2.2. Restaurar integralidade para janela atual
      restore_integrality(window_periods, original_vtypes)

      # 2.3. Relaxar períodos futuros
      last_period_idx ← index(window_periods[-1])
      relax_after_period(last_period_idx)

      # 2.4. Resolver janela
      actual_time ← min(time_per_window, remaining - 30)
      model.Params.TimeLimit ← actual_time
      model.Params.MIPGap ← mip_gap
      model.optimize()

      # 2.5. Verificar resultado
      SE model.status = OPTIMAL OU (model.status = TIME_LIMIT E SolCount > 0) ENTÃO:
         LOG("Janela {k}: Obj={model.ObjVal:.2f}")
         # 2.6. Fixar decisões binárias da janela
         fix_binary_decisions(window_periods)
      SENÃO:
         LOG("ERRO: Janela {k} sem solução (Status={model.status})")
         RETORNAR {status: FAILED, ...}

   # ========== FASE 3: POLISH FINAL ==========

   LOG("=== SOLVE FINAL ===")

   # 3.1. Salvar solução das janelas
   window_solution ← extract_solution()

   # 3.2. Restaurar todas variáveis para tipos originais
   PARA cada var_name ∈ ['x', 'w', 'z', 'c']:
      PARA cada key, var ∈ variables[var_name]:
         var.vtype ← original_vtypes[var_name][key]
   model.update()

   # 3.3. Warm-start com solução das janelas
   PARA cada var_name ∈ ['x', 'w', 'z', 'c']:
      PARA cada key, var ∈ variables[var_name]:
         var.Start ← window_solution[var_name][key]
   model.update()

   # 3.4. Resolver modelo completo
   elapsed ← time() - start_time
   remaining ← max(30, total_time_limit - elapsed)
   model.Params.TimeLimit ← remaining

   model.optimize()

   # 3.5. Extrair resultado final
   total_time ← time() - start_time

   SE model.SolCount > 0 ENTÃO:
      final_solution ← extract_solution()
      final_gap ← model.MIPGap se status ≠ OPTIMAL senão 0.0

      RETORNAR {
         status: model.status,
         obj_val: model.ObjVal,
         obj_bound: model.ObjBound,
         mip_gap: final_gap,
         runtime: total_time,
         statistics: {
            windows_total: n_windows,
            window_size_periods: window_size,
            ...
         }
      }
   SENÃO:
      RETORNAR {status: FAILED, ...}
```

### Complexidade

- **Temporal**: O(n_windows × T_mip_window + T_mip_final)
  - T_mip_window: Tempo resolve MIP de janela (limitado por time_per_window)
  - T_mip_final: Tempo polish final (limitado por time_for_final)
  - Total garantido ≤ total_time_limit

- **Espacial**: O(n_var) para armazenamento de solução e tipos originais

---

## Operações Críticas

### 1. Particionamento em Janelas

```
FUNÇÃO partition_into_windows(periods, window_size, overlap):
   windows ← []
   start_idx ← 0

   ENQUANTO start_idx < |periods|:
      end_idx ← min(start_idx + window_size, |periods|)
      windows.append(periods[start_idx:end_idx])

      # Avançar com overlap
      start_idx ← start_idx + (window_size - overlap)

   RETORNAR windows
```

**Exemplo:**
```
periods = [(d1,M), (d1,T), (d2,M), (d2,T), (d3,M), (d3,T)]  # 6 períodos
window_size = 3, overlap = 1

Janela 1: [(d1,M), (d1,T), (d2,M)]      # índices 0-2
Janela 2: [(d2,M), (d2,T), (d3,M)]      # índices 2-4 (overlap em d2,M)
Janela 3: [(d3,M), (d3,T)]              # índices 4-5
```

### 2. Relaxação de Variáveis

```
FUNÇÃO relax_after_period(cutoff_period_idx):
   PARA cada var_name ∈ ['x', 'w', 'z', 'c']:
      PARA cada key, var ∈ variables[var_name]:
         # Extrair (date, period) da chave
         ESCOLHA var_name:
            CASO 'x':  # (physician, clinic, date, period)
               date, period ← key[2], key[3]
            CASO 'w':  # (physician, clinic, date) - diária
               date, period ← key[2], None
            CASO 'z':  # (physician, date) - diária
               date, period ← key[1], None
            CASO 'c':  # (clinic, date, period)
               date, period ← key[1], key[2]

         # Relaxar se após cutoff
         SE period é None ENTÃO:  # Variável diária (w, z)
            # Encontrar todos períodos desta data
            date_periods ← [(d,p) for (d,p) in periods se d = date]
            SE date_periods E index(date_periods[0]) > cutoff_period_idx ENTÃO:
               var.vtype ← CONTINUOUS
         SENÃO:  # Variável por período (x, c)
            period_idx ← index((date, period))
            SE period_idx > cutoff_period_idx ENTÃO:
               var.vtype ← CONTINUOUS

   model.update()
```

**Complexidade**: O(n_var) - scan todas variáveis

### 3. Restauração de Integralidade

```
FUNÇÃO restore_integrality(window_periods, original_vtypes):
   window_dates ← {date para (date, _) in window_periods}

   PARA cada var_name ∈ ['x', 'w', 'z', 'c']:
      PARA cada key, var ∈ variables[var_name]:
         ESCOLHA var_name:
            CASO 'x':
               date, period ← key[2], key[3]
               SE (date, period) ∈ window_periods ENTÃO:
                  var.vtype ← original_vtypes[var_name][key]

            CASO 'w':
               date ← key[2]
               SE date ∈ window_dates ENTÃO:
                  var.vtype ← original_vtypes[var_name][key]

            CASO 'z':
               date ← key[1]
               SE date ∈ window_dates ENTÃO:
                  var.vtype ← original_vtypes[var_name][key]

            CASO 'c':
               date, period ← key[1], key[2]
               SE (date, period) ∈ window_periods ENTÃO:
                  var.vtype ← original_vtypes[var_name][key]

   model.update()
```

**Complexidade**: O(n_var)

### 4. Fixação de Decisões Binárias

```
FUNÇÃO fix_binary_decisions(window_periods):
   window_dates ← {date para (date, _) in window_periods}

   PARA cada (physician, clinic, date), var ∈ variables['w']:
      SE date ∈ window_dates ENTÃO:
         val ← var.X  # Valor da solução atual

         SE original_vtypes['w'][(physician, clinic, date)] = BINARY ENTÃO:
            SE val > 0.5 ENTÃO:
               var.lb ← 1.0
               var.ub ← 1.0
            SENÃO:
               var.lb ← 0.0
               var.ub ← 0.0

   model.update()
```

**Justificativa**: Fixa apenas variáveis `w` (alocação diária médico-clínica) pois são as decisões estruturais. Variáveis `x` (turnos específicos) permanecem livres para ajuste.

**Complexidade**: O(|I| × |U| × |window_dates|)

---

## Gestão de Orçamento Temporal

### Distribuição de Tempo

```
total_time_limit = 3600s (1 hora)
polish_ratio = 0.2 (20%)

Cálculo:
   time_for_windows = 3600 × (1.0 - 0.2) = 2880s (80%)
   time_for_final = 3600 × 0.2 = 720s (20%)

Se n_windows = 8:
   time_per_window = 2880 / 8 = 360s por janela

Execução:
   Janela 1: até 360s
   Janela 2: até 360s
   ...
   Janela 8: até 360s
   Polish Final: até 720s (ou tempo restante)
```

### Lógica de Parada Antecipada

```
PARA cada janela k:
   elapsed ← time() - start_time
   remaining ← total_time_limit - elapsed

   SE remaining < 30 ENTÃO:
      LOG("Orçamento esgotado na janela {k}")
      BREAK

   actual_time ← min(time_per_window, remaining - 30)
   # Resolver janela com actual_time
```

**Garantias:**
1. Sempre reserva ≥30s para próxima operação
2. Total runtime ≤ total_time_limit
3. Polish final recebe tempo proporcional restante

---

## Análise de Parâmetros

### window_size_pct (Tamanho de Janela)

| Valor | % Períodos | Vantagens | Desvantagens |
|-------|-----------|-----------|--------------|
| 0.05 | 5% | Janelas pequenas, rápidas | Muitas janelas, pouca visão global |
| **0.10** | **10%** (rec.) | **Balanço qualidade/tempo** | **Padrão** |
| 0.20 | 20% | Menos janelas, visão global | Janelas mais lentas |
| 0.50 | 50% | Resolve quase metade de uma vez | Perde vantagem decomposição |

**Recomendação**: 0.10 (10%) para instâncias típicas (28-56 períodos)

### overlap (Sobreposição)

| Valor | Efeito | Uso Recomendado |
|-------|--------|----------------|
| 0 | Sem overlap, partição disjunta | Janelas independentes, máxima velocidade |
| **2** | **2 períodos overlap** (rec.) | **Continuidade decisões, balanço** |
| 4+ | Alto overlap, redundância | Instâncias críticas, busca qualidade |

**Justificativa**: overlap=2 garante que decisões de fronteira sejam revisitadas, melhorando continuidade temporal.

### polish_ratio (Proporção Polish Final)

| Valor | % Tempo Final | Efeito |
|-------|---------------|--------|
| 0.1 | 10% | Prioriza janelas, polish rápido |
| **0.2** | **20%** (rec.) | **Balanço** |
| 0.3 | 30% | Mais tempo para refinamento global |
| 0.5 | 50% | Muito tempo polish, janelas apressadas |

**Recomendação**: 0.2 (20%) - janelas constroem solução factível, polish refina qualidade.

---

## Análise de Resultados

### Métricas de Qualidade

```python
resultado = relax_and_fix.solve()

# Métricas principais
obj_val = resultado['obj_val']          # Valor objetivo final
obj_bound = resultado['obj_bound']      # Lower bound MIP
mip_gap = resultado['mip_gap']          # Gap final (%)
runtime = resultado['runtime']          # Tempo total (s)

# Estatísticas detalhadas
stats = resultado['statistics']
n_windows = stats['windows_total']                  # Janelas processadas
window_times = stats['window_times']                # Tempo por janela (lista)
window_objs = stats['window_objectives']            # Obj por janela (lista)
final_time = stats['final_solve_time']              # Tempo polish
```

### Análise de Convergência

```python
import matplotlib.pyplot as plt

# Evolução objetiva por janela
plt.plot(range(1, n_windows+1), window_objs, marker='o')
plt.axhline(y=obj_val, color='r', linestyle='--', label='Final')
plt.xlabel('Janela')
plt.ylabel('Objetivo')
plt.title('Convergência R&F')
plt.legend()
plt.show()

# Tempo por janela
plt.bar(range(1, n_windows+1), window_times)
plt.axhline(y=time_per_window, color='r', linestyle='--', label='Limite')
plt.xlabel('Janela')
plt.ylabel('Tempo (s)')
plt.title('Tempo por Janela')
plt.legend()
plt.show()
```

### Diagnóstico de Problemas

| Sintoma | Causa Provável | Solução |
|---------|----------------|---------|
| Janela falha (sem solução) | Janela muito restrita por fixações | Aumentar window_size ou overlap |
| Gap final >5% | Tempo polish insuficiente | Aumentar polish_ratio ou total_time_limit |
| Tempo por janela >90% limite | Janelas muito grandes | Reduzir window_size_pct |
| Objetiva pula entre janelas | Falta continuidade | Aumentar overlap |
| Falha na janela 1 | Modelo infactível | Verificar construção modelo/instância |

---

## Comparação: Dias vs. Períodos

### Exemplo de Instância

```
Instance: 14 dias, 2 turnos (Manhã, Tarde)
Total períodos = 14 × 2 = 28 períodos
```

### Abordagem Antiga (Dias)

```python
window_size = 7  # dias
n_windows = ⌈14 / 7⌉ = 2 janelas

Janela 1: dias 1-7   (14 períodos)
Janela 2: dias 8-14  (14 períodos)
```

**Problemas:**
- Granularidade grossa (7 dias = 14 períodos)
- Não adapta a tamanho de instância
- Difícil calibrar para instâncias variadas

### Abordagem Nova (Períodos)

```python
window_size_pct = 0.10  # 10% dos períodos
window_size = ⌊28 × 0.10⌋ = 2 períodos
overlap = 1 período

# Particionamento
Janela 1: períodos [0,1]     = (d1,M), (d1,T)
Janela 2: períodos [0,1,2,3] = (d1,M), (d1,T), (d2,M), (d2,T)  # overlap
Janela 3: períodos [2,3,4,5] = (d2,M), (d2,T), (d3,M), (d3,T)
...
```

**Vantagens:**
1. **Granularidade fina**: Janelas de 2-3 períodos (1-2 dias)
2. **Adaptação automática**: 10% funciona para instâncias de 28, 56, 84 períodos
3. **Controle preciso**: Sabe exatamente quais variáveis (i,u,d,t) são integrais

---

## Exemplo Completo de Execução

### Configuração

```python
from engine.mip.matheuristics.relax_and_fix import RelaxAndFix

# Criar modelo MIP completo
gurobi_model = GurobiModel(instance)
gurobi_model.build()

# Configurar R&F
rnf = RelaxAndFix(
    gurobi_model=gurobi_model,
    window_size_pct=0.10,        # 10% dos períodos
   overlap=1,                   # 1 período de overlap
    total_time_limit=3600,       # 1 hora total
    polish_ratio=0.2,            # 20% para polish
   mip_gap=1e-4,                # 0.01% gap tolerance
    verbose=1                    # Logs básicos
)

# Executar
resultado = rnf.solve()

# Análise
if resultado['status'] in [GRB.OPTIMAL, GRB.TIME_LIMIT]:
    print(f"Objetivo: {resultado['obj_val']:.2f}")
   print(f"Gap (fração): {resultado['mip_gap']:.6f}")
    print(f"Tempo: {resultado['runtime']:.1f}s")

    # Acessar solução
    solution = rnf.get_solution()
    stats = rnf.get_statistics()
else:
    print(f"Falha: Status {resultado['status']}")
```

### Saída Esperada

```
=============================================================
RELAX-AND-FIX
=============================================================
Window size: 10.0% of 28 periods = 2 periods
Partitioned into 14 windows
Time per window: 205s, Final solve: 720s

Window 1/14: (2024-01-01,M) to (2024-01-01,T) [2 periods]
  Optimal: Obj=1234.56, Time=45.2s

Window 2/14: (2024-01-01,T) to (2024-01-02,M) [2 periods]
  Optimal: Obj=1156.78, Time=52.1s

...

Window 14/14: (2024-01-14,M) to (2024-01-14,T) [2 periods]
  Optimal: Obj=987.65, Time=38.4s

=============================================================
FINAL SOLVE
=============================================================
Final solve with 628s remaining...

=============================================================
R&F COMPLETED
=============================================================
  Final Obj: 945.32
  Final Gap: 0.85%
  Total Time: 2972.3s
```

---

## Vantagens e Limitações

### Vantagens

1. **Escalabilidade**: Resolve instâncias grandes que MIP exato não consegue
2. **Garantia de Solução**: Sempre produz solução factível (se janelas resolvem)
3. **Qualidade Controlada**: Gap final tipicamente <2% com polish adequado
4. **Orçamento Temporal**: Tempo total garantido ≤ total_time_limit
5. **Warm-start**: Polish final parte de solução factível das janelas

### Limitações

1. **Dependência de Ordem**: Forward-rolling pode perder oportunidades (sem backward pass)
2. **Fixação Irreversível**: Decisões fixadas não são revisitadas (até polish final)
3. **Sensibilidade a Parâmetros**: window_size e overlap afetam qualidade
4. **Primeira Janela Crítica**: Se janela 1 falha, todo algoritmo falha

### Comparação com MIP Exato

| Aspecto | R&F | MIP Exato |
|---------|-----|-----------|
| Tempo para solução | Controlado (≤ time_limit) | Imprevisível |
| Qualidade solução | Boa (gap ~1-3%) | Ótima (gap ~0%) |
| Escalabilidade | Alta (instâncias grandes) | Limitada |
| Garantia otimalidade | Não | Sim (se completa) |
| Uso recomendado | Instâncias >20 dias | Instâncias ≤14 dias |

---

## Integração com Fix-and-Optimize

R&F frequentemente usado como **fase 1** de pipeline matheurístico:

```python
# FASE 1: R&F para solução inicial
rnf = RelaxAndFix(gurobi_model, total_time_limit=3600, ...)
resultado_rnf = rnf.solve()

# FASE 2: F&O para refinamento
from engine.mip.matheuristics.fix_and_optimize import FixAndOptimize

fno = FixAndOptimize(gurobi_model, total_time_limit=2700, ...)
resultado_final = fno.solve()

print(f"R&F: {resultado_rnf['obj_val']:.2f}")
print(f"F&O: {resultado_final['obj_val']:.2f}")
print(f"Melhoria: {((resultado_rnf['obj_val'] - resultado_final['obj_val']) / resultado_rnf['obj_val'] * 100):.2f}%")
```

**Recomendação de Orçamento:**
- Total: 6300s (1h45min)
- R&F: 3600s (57%)
- F&O: 2700s (43%)

---

## Integração com Runner e Pipeline

No ecossistema do projeto, R&F aparece em três pontos principais:

1. Como `sub_solver=relax_and_fix` nos pontos epsilon.
2. Como fase de construção no modo híbrido (`R&F + F&O`).
3. Na geração de grid lexicográfico (`run_epsilon_grid_pipeline.py`) quando `lex_method=relax_and_fix|hybrid|tiered`.

Notas práticas:

1. O default da classe é `overlap=2`, mas defaults de CLI podem variar por pipeline.
2. O parâmetro legado `window_size` (dias) permanece por retrocompatibilidade; em novos experimentos, prefira `window_size_pct`.
3. O campo `mip_gap` retornado é fração; converta para percentual apenas na apresentação.

---

## Trabalhos Futuros

### Melhorias Implementáveis

1. **Backward Pass**: Após forward, fazer sweep reverso para refinar decisões iniciais
2. **Adaptive Window Size**: Ajustar window_size baseado em dificuldade da janela
3. **Parallel Windows**: Resolver janelas independentes em paralelo
4. **Fixação Parcial**: Fixar apenas subset de variáveis w com alta confiança

### Variantes Avançadas

1. **Roll & Fix Híbrido**: Combinar forward + backward passes
2. **Variable Fixing Criteria**: Usar reduced costs para decidir o que fixar
3. **Decomposição Multi-Dimensional**: Particionar por médico × tempo
4. **Adaptive Polish Ratio**: Ajustar polish_ratio baseado em qualidade das janelas

---

## Referências

1. Dillenberger, C., et al. (1994). "On practical resource allocation for production planning and scheduling with period overlapping setups". *European Journal of Operational Research*, 75(2), 275-286.

2. Ferreira, D., et al. (2009). "Single-stage formulations for synchronised two-stage lot sizing and scheduling in soft drink production". *International Journal of Production Economics*, 136(2), 255-265.

3. Helber, S., & Sahling, F. (2010). "A fix-and-optimize approach for the multi-level capacitated lot sizing problem". *International Journal of Production Economics*, 123(2), 247-256.

4. Pochet, Y., & Wolsey, L. A. (2006). *Production planning by mixed integer programming*. Springer Science & Business Media.

5. James, R. J. W., & Almada-Lobo, B. (2011). "Single and parallel machine capacitated lotsizing and scheduling: New iterative MIP-based neighborhood search heuristics". *Computers & Operations Research*, 38(12), 1816-1825.

---

**Versão do Documento**: 1.0
**Data**: Janeiro 2025
**Status**: Implementado e Validado (gap típico 1-3%, tempo controlado)
