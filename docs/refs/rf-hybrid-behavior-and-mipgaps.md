# RF and Hybrid: Behaviour Analysis and MIP Gaps

## Purpose and scope

This document consolidates the investigation into two related questions raised
during results review:

1. Why does the **Relax-and-Fix (RF)** matheuristic produce Pareto fronts that
   appear _better_ than both the **Exact** method and the **Hybrid**
   (RF + Fix-and-Optimize) matheuristic on the larger horizons (60 and 90 days),
   which is counter-intuitive for a heuristic.
2. What are the **MIP gaps** of the MIP-heuristic runs (RF and Hybrid), to be
   documented alongside the Exact-method gap tables already present in the
   dissertation slides.

All numeric evidence below was extracted from the experiment run stored at
`data/output/allin_fev26_5/run/`. Instances are the multi-objective
epsilon-constraint runs with primary objective **swaps** (`*_swaps` output
directories), constraining unmet exams (Z1) and minimising clinic swaps (Z2).

---

## 1. Root cause: none of the runs converged

Across every horizon beyond 15 days, **all epsilon points terminate with Gurobi
Status 9 (TIME_LIMIT reached)** and large optimality gaps. The reported Pareto
"fronts" are therefore **incumbents captured at the time limit, not proven
optimal fronts**. Any dominance relation between methods reflects _which method
found a better feasible incumbent within the same wall-clock_, not which method
is intrinsically superior.

Example, 60-day instance `2022dec01_to_2023jan29`, all epsilon points
(Status 9 for every cell):

| eps     | Exact ObjVal | Exact gap | RF ObjVal | RF gap | Hybrid ObjVal | Hybrid gap |
| ------- | ------------ | --------- | --------- | ------ | ------------- | ---------- |
| eps2154 | 1521         | 91.0%     | 586       | 79.7%  | 1479          | 90.8%      |
| eps3172 | 941          | 89.0%     | 476       | 81.3%  | 932           | 88.9%      |
| eps4190 | 606          | 86.5%     | 372       | 79.6%  | 646           | 87.4%      |
| eps5208 | 367          | 80.8%     | 285       | 77.5%  | 448           | 84.7%      |
| eps6226 | 208          | 68.9%     | 312       | 82.2%  | 233           | 75.0%      |
| eps7244 | 202          | 70.7%     | 190       | 71.5%  | 208           | 72.1%      |
| eps8263 | 194          | 69.5%     | 171       | 66.5%  | 193           | 70.0%      |

Note RF's runtime per point (~1666 s after the first) is lower than Exact and
Hybrid (~3600 s), yet RF still yields much lower Z2 at the low-epsilon end.

---

## 2. Why RF appears to dominate Exact and Hybrid

RF decomposes the planning horizon into small temporal windows (date x shift)
and solves them sequentially with a rolling horizon. Each window is a tractable
subproblem, so Gurobi can drive the swaps objective (Z2) down and reach a
**good feasible solution quickly**.

The Exact method and the Hybrid method (see Section 3) end up solving the
**monolithic model** (~314302 rows, ~276567 columns for the 60-day instance).
At 60-90 days this model is so large that, within the one-hour budget, the
solver barely improves on its first feasible incumbent (gaps of 91-100%). That
first incumbent is a poor swap-solution.

Consequence: at the low-epsilon (min-unmet, high-swaps) end, RF's decomposed
incumbent (e.g. 586 swaps) is far better than the monolithic incumbent
(e.g. 1521 swaps). This is **not** evidence that RF beats the true optimum; the
true optimum is unknown and bounded below by roughly 119-136 for that point. RF
simply produces a better _feasible_ solution in the same wall-clock.

### 90-day catastrophic incumbents (the plot "spikes")

On the 90-day instance `2022feb01_to_2022may01`, several Exact and Hybrid points
report Z2 near 9200 swaps with gaps of ~100% (lower bound near zero): the
incumbent is essentially the first feasible solution found. RF avoids these
because decomposition still yields reasonable feasible solutions.

| eps (approx) | Exact Z2 | Exact gap | RF Z2 | RF gap | Hybrid Z2 | Hybrid gap |
| ------------ | -------- | --------- | ----- | ------ | --------- | ---------- |
| 5825         | 2222     | 96.9%     | 1691  | 96.4%  | 2211      | 96.5%      |
| 7333         | 2109     | 97.2%     | 1625  | 96.9%  | 1510      | 96.0%      |
| 8842         | 9230     | 100.0%    | 1014  | 99.8%  | 9221      | 99.5%      |
| 10351        | 1220     | 96.3%     | 535   | 91.6%  | 1009      | 95.2%      |
| 11860        | 9228     | 100.0%    | 907   | 99.8%  | 169       | 73.3%      |
| 13369        | 9157     | 100.0%    | 835   | 99.8%  | 238       | 82.7%      |
| 14878        | 166      | 74.7%     | 197   | 79.2%  | 144       | 69.2%      |

The Exact and Hybrid spikes occur at _different_ epsilon points, which confirms
they are arbitrary bad incumbents at timeout rather than a structural feature of
the front.

---

## 3. Why Hybrid tracks Exact (poor) instead of RF (good)

The Hybrid sub-solver is `RF construction -> Fix-and-Optimize (F&O) improvement`.
Two defects make it worse than standalone RF.

### 3.1 Orchestration defect: F&O result kept even when worse

In `engine/mip/exact/multi_method/epsilon_method.py`, method
`_solve_with_hybrid_heuristic` (lines ~2231-2334), the return logic is:

```python
if fo_model.model.SolCount > 0:
    fo_obj_val = fo_model.model.ObjVal
    improvement = rf_obj_val - fo_obj_val   # computed only to print
    ...
    model.dispose()      # discards the RF model
    return fo_model      # returns F&O result unconditionally
```

The F&O model is returned **whenever it has any feasible solution
(`SolCount > 0`)**, without checking that its objective actually improved on the
RF warm-start. F&O runs on the full monolithic model (warm-started from RF),
times out, and frequently lands on a solution _worse_ than the RF solution it
started from. Hybrid then keeps that worse solution.

Evidence, 60-day instance `2022dec01_to_2023jan29`, reading the two Gurobi solve
blocks in each per-point `gurobi.log` (first block = end of RF construction
phase, second block = end of F&O phase, which is the value reported in
`results.json`):

| eps     | RF-phase-end obj | RF gap | F&O-phase-end obj | F&O gap | F&O vs RF | Reported |
| ------- | ---------------- | ------ | ----------------- | ------- | --------- | -------- |
| eps2154 | 1155             | 87.8%  | 1479              | 90.8%   | worse     | 1479     |
| eps3172 | 989              | 89.5%  | 932               | 88.9%   | better    | 932      |
| eps4190 | 612              | 87.0%  | 646               | 87.4%   | worse     | 646      |
| eps5208 | 367              | 81.2%  | 448               | 84.7%   | worse     | 448      |
| eps6226 | 233              | 73.2%  | 233               | 75.0%   | equal     | 233      |
| eps7244 | 235              | 76.0%  | 208               | 72.1%   | better    | 208      |
| eps8263 | 184              | 67.5%  | 193               | 70.0%   | worse     | 193      |

In 4 of 7 points the F&O phase degraded the incumbent, and Hybrid reported the
degraded value every time (the "Reported" column always equals the F&O-phase
value).

### 3.2 Hybrid's RF phase is weaker than standalone RF

Inside Hybrid the RF construction receives only `rf_ratio` of the time budget
(configured value `rf_ratio = 0.25`, i.e. 25%), whereas standalone RF receives
the full budget and keeps its own decomposed incumbent. At eps2154 this shows as
standalone RF = 586 versus Hybrid's RF-phase = 1155, before F&O degrades it
further to 1479.

Combined effect: standalone RF keeps a strong decomposed incumbent; Hybrid
weakens the RF phase and then discards its result in favour of a timed-out
monolithic F&O solve.

Hybrid configuration in this run (`args.json`): `sub_solver = hybrid`,
`rf_ratio = 0.25`, `rf_window_size = 7`, `rf_overlap = 0`,
`rf_polish_ratio = 0.2`, `fo_window_size_pct = 0.5`, `fo_max_iterations = 50`,
`fo_no_improvement = 10`, `time_limit = 3600`.

---

## 4. MIP gaps of the MIP-heuristic methods (RF and Hybrid)

### 4.1 Summary per horizon

Mean MIP gap across all instances and all epsilon points, with the count of
epsilon points that reached optimality (gap <= 1%). Data source:
`data/output/allin_fev26_5/run/`.

| Horizon | Exact (mean gap) | Exact optimal | RF (mean gap) | RF optimal | Hybrid (mean gap) | Hybrid optimal |
| ------- | ---------------- | ------------- | ------------- | ---------- | ----------------- | -------------- |
| 15 d    | 4.8%             | 23/55         | 10.8%         | 15/53      | 4.9%              | 21/56          |
| 30 d    | 44.8%            | 0/49          | 53.7%         | 0/49       | 44.3%             | 0/49           |
| 60 d    | 78.9%            | 0/56          | 82.2%         | 0/56       | 81.1%             | 0/56           |
| 90 d    | 97.1%            | 0/55          | 97.7%         | 0/56       | 94.9%             | 0/56           |

Beyond 15 days, no method proves any optimum; every point hits the time limit.

### 4.2 RF - 30-day per-instance heatmap (gap %)

| Instance  | e1   | e2   | e3   | e4   | e5   | e6   | e7   |
| --------- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| 2022mar01 | 57.3 | 54.3 | 39.8 | 34.7 | 27.8 | 26.7 | -    |
| 2022may01 | 70.2 | 63.8 | 47.4 | 41.4 | 42.8 | 33.9 | -    |
| 2022nov01 | 63.9 | 59.0 | 46.8 | 43.8 | 39.9 | 31.5 | -    |
| 2022sep01 | 66.5 | 66.5 | 56.3 | 37.1 | 33.2 | 25.8 | -    |
| 2023jan01 | 56.0 | 68.9 | 59.9 | 52.6 | 46.5 | 43.1 | -    |
| 2023jul01 | 79.8 | 85.2 | 77.4 | 56.8 | 52.4 | 46.0 | -    |
| 2023mar01 | 68.7 | 82.8 | 73.2 | 61.3 | 47.1 | 31.7 | -    |
| 2023may01 | 71.2 | 82.1 | 80.6 | 65.5 | 60.4 | 42.1 | 31.3 |

### 4.3 Hybrid - 30-day per-instance heatmap (gap %)

| Instance  | e1   | e2   | e3   | e4   | e5   | e6   | e7   |
| --------- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| 2022mar01 | 41.9 | 39.8 | 33.1 | 29.1 | 27.0 | 26.5 | -    |
| 2022may01 | 54.9 | 49.1 | 38.6 | 34.7 | 30.6 | 32.5 | -    |
| 2022nov01 | 42.1 | 45.3 | 42.5 | 29.8 | 32.3 | 30.8 | -    |
| 2022sep01 | 51.1 | 58.0 | 50.3 | 34.6 | 28.7 | 23.3 | -    |
| 2023jan01 | 49.8 | 53.9 | 52.1 | 40.1 | 37.1 | 36.0 | -    |
| 2023jul01 | 72.9 | 70.1 | 61.5 | 47.0 | 43.2 | 41.8 | -    |
| 2023mar01 | 61.8 | 64.6 | 51.8 | 43.5 | 34.0 | 31.7 | -    |
| 2023may01 | 69.9 | 71.9 | 65.1 | 52.2 | 45.4 | 38.4 | 28.9 |

### 4.4 Exact - 30-day per-instance heatmap (regenerated from the same run)

Provided so all three tables are comparable (see caveat in Section 5.1).

| Instance  | e1   | e2   | e3   | e4   | e5   | e6   | e7   |
| --------- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| 2022mar01 | 41.6 | 45.9 | 38.1 | 28.5 | 30.4 | 28.7 | -    |
| 2022may01 | 49.3 | 48.7 | 34.7 | 37.1 | 31.2 | 33.1 | -    |
| 2022nov01 | 43.4 | 47.0 | 38.8 | 35.6 | 31.9 | 31.4 | -    |
| 2022sep01 | 50.9 | 56.6 | 41.9 | 34.6 | 28.3 | 25.7 | -    |
| 2023jan01 | 47.0 | 51.9 | 54.0 | 43.4 | 33.3 | 35.8 | -    |
| 2023jul01 | 75.0 | 71.4 | 70.6 | 50.2 | 42.3 | 41.2 | -    |
| 2023mar01 | 61.6 | 68.5 | 58.3 | 45.8 | 34.8 | 28.9 | -    |
| 2023may01 | 71.7 | 71.0 | 61.6 | 52.8 | 48.1 | 35.2 | 29.6 |

Note: only `2023may01` has 7 epsilon points; the other instances have 6 (grid
generation produced different counts per instance).

---

## 5. Interpretation caveats (must accompany any published table)

### 5.1 The slide's Exact heatmap comes from a different, now-unavailable run

The Exact MIP-gap heatmaps currently in the slides (10 instances per horizon,
including `2022jan02_to_2022jan31`, with epsilon point e1 infeasible for 8 of 10
instances at 30 days) originate from an **older experiment whose raw data is no
longer in the repository** - only the PNG images survive
(`03_APRESENTACAO/img/exato_mipgap_heatmap_*.png`).

The tables in Section 4 come from `allin_fev26_5` (8 instances per horizon, no
infeasible points). The regenerated Exact means from this run (15 d 4.8%,
30 d 44.8%, 60 d 78.9%, 90 d 97.1%) differ slightly from the slide values
(4.1% / 42.7% / 78.1% / 96.8%) because the instance set is different.

Recommendation: to present Exact, RF and Hybrid side by side honestly, use the
regenerated Exact table from `allin_fev26_5` so all three share the same
instances and epsilon grid.

### 5.2 Heuristic MIP gap is not directly comparable to Exact MIP gap

Gurobi's `MIPGap` measures the distance between the incumbent and **each
method's own lower bound**. For RF the bound comes from its decomposed
subproblems and is looser than the monolithic bound, so its gap is inflated
relative to the quality of its solution.

Illustration, 60-day instance `2022dec01_to_2023jan29`, point eps2154:

| Method | Incumbent (ObjVal) | Lower bound (ObjBound) | MIP gap |
| ------ | ------------------ | ---------------------- | ------- |
| Exact  | 1521               | 136.3                  | 91.0%   |
| RF     | 586                | 119.0                  | 79.7%   |
| Hybrid | 1479               | 136.0                  | 90.8%   |

RF holds a solution roughly 2.6x better than Exact, yet its reported gap is only
modestly smaller, because its lower bound is weaker. A method with a better
incumbent can therefore display a large gap. When comparing solution _quality_
across methods, prefer a **reference gap** (incumbent versus best-known solution,
or versus a common lower bound) rather than the per-method `MIPGap`. Partial
`reference_bounds.json` artefacts already exist under some
`*/analysis/reference_bounds.json` paths (mainly 15-day) and could seed such a
computation.

---

## 6. Recommendations

1. **Fix the Hybrid orchestration defect.** Return the better of RF and F&O
   instead of always returning F&O. In `_solve_with_hybrid_heuristic`
   (`epsilon_method.py`, around line 2309):

    ```python
    if fo_model.model.SolCount > 0 and fo_model.model.ObjVal < rf_obj_val - 1e-6:
       model.dispose()
       return fo_model          # F&O strictly improved on RF
    else:
       fo_model.dispose()
       return model             # keep the RF result
    ```

    After this fix, Hybrid should be at least as good as its RF construction phase
    at every point.

2. **Reconsider Hybrid time split.** With `rf_ratio = 0.25`, the RF construction
   is much weaker than standalone RF. Increasing the RF share (or seeding F&O
   from a full-budget RF run) would give F&O a stronger warm-start.

3. **Regenerate the Exact gap table from `allin_fev26_5`** for a fair
   three-method comparison, and archive the raw data of any run used in the
   dissertation so tables remain reproducible.

4. **Report a reference gap** in addition to `MIPGap` when comparing heuristics,
   to avoid the misleading impression created by looser heuristic bounds.

5. **Frame the large-horizon results correctly.** Beyond 15 days no method
   converges; the fronts compare _feasible incumbents at timeout_. RF's advantage
   at 60-90 days is a property of temporal decomposition on an intractable
   monolithic model, not proof of optimality.

---

## 7. Reproduction

Data source: `data/output/allin_fev26_5/run/{15,30,60,90}_days/<instance>/<method>/`
where `<method>` is one of `exact_swaps`, `rf_swaps`, `hybrid_swaps`.

Per-point artefacts used:

- `solution/eps<value>/results.json` - fields `Status`, `ObjVal`, `ObjBound`,
  `MIPGap`, `Runtime`, `SolCount`.
- `solution/eps<value>/gurobi.log` - phase-by-phase solve blocks; for Hybrid the
  last two `Best objective ... gap` lines give the RF-phase and F&O-phase values.
- `solution/eps<value>/args.json` - sub-solver and matheuristic parameters.

Relevant code:

- Hybrid per-point orchestration:
  `engine/mip/exact/multi_method/epsilon_method.py`,
  `_solve_with_hybrid_heuristic` (approx. lines 2231-2334).
- Epsilon-point dispatch by sub-solver: same file,
  `_solve_epsilon_point` (approx. lines 2336-2369).
- Relax-and-Fix: `engine/mip/matheuristics/relax_and_fix.py`.
- Fix-and-Optimize: `engine/mip/matheuristics/fix_and_optimize.py`.
