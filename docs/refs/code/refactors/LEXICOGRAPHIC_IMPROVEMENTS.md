# Lexicographic Phase Improvements for Epsilon-Grid Generation

**Date:** 2026-02-06
**File:** `engine/mip/exact/multi_method/epsilon_method.py`

## Problem Statement

The epsilon-constraint method relies on a lexicographic phase to determine the
extreme points of the Pareto front. Two sequential optimizations are performed:

- **Lex 1**: Minimize Z1 (unmet exams), with Z2 as tie-breaker
- **Lex 2**: Minimize Z2 (swaps), with Z1 as tie-breaker

On larger instances (60+ days), Lex 2 frequently hits the `LEX_TIME_LIMIT`
without proving optimality. The resulting suboptimal Z2* value compresses the
epsilon grid range, causing the downstream epsilon-constraint solves to miss
portions of the true Pareto front. Increasing `LEX_TIME_LIMIT` is not viable
due to total walltime constraints on the computational cluster.

## Implemented Improvements

Three complementary techniques were applied to improve Lex 2 convergence
without increasing the per-lexicographic-point time budget.

### 1. Cross-Lexicographic Warm-Starting

**Rationale.** Lex 1 and Lex 2 share the same feasible region (identical
constraints). The Lex 1 solution is therefore feasible for Lex 2. Providing it
as a MIP start gives Gurobi a known-feasible incumbent from the outset,
enabling earlier pruning of the branch-and-bound tree.

**Implementation.** After Lex 1 completes, all decision variable values (x, w,
z, c, gamma) are extracted via `_extract_solution_values()`. Before Lex 2
begins, these values are injected into the target model via
`_inject_warm_start()`, which sets the `.Start` attribute on each variable.

**Applicability.**
- *Exact method*: The same `self.model` is reused. Although Gurobi retains
  variable values after `optimize()`, modifying the objective invalidates the
  previous solution as an automatic MIP start. Explicitly setting `.Start`
  ensures the warm-start is honored.
- *Relax-and-Fix method*: A fresh model is created for Lex 2, which has no
  knowledge of the Lex 1 solution. The warm-start is injected before the R&F
  construction phase, providing the solver with a feasible starting point for
  both window sub-problems and the final polish solve.

### 2. Asymmetric Time Redistribution

**Rationale.** Both lexicographic points receive identical time budgets
(`LEX_TIME_LIMIT`). When Lex 1 terminates early (e.g., proves optimality in
3000s of a 7200s budget), the remaining 4200s is wasted. Redistributing this
unused time to Lex 2 increases its effective budget without changing the total
walltime.

**Implementation.** After Lex 1 returns, the elapsed runtime is compared
against `LEX_TIME_LIMIT`. The difference `max(0, LEX_TIME_LIMIT - runtime)` is
passed to Lex 2 as `extra_time`. Lex 2 sets its effective time limit to
`LEX_TIME_LIMIT + extra_time`.

**Applicability.** Works identically for both exact and Relax-and-Fix methods.
The total lexicographic phase time is bounded by `2 * LEX_TIME_LIMIT`
regardless, so no walltime increase occurs.

### 3. Bound Tightening via Valid Inequality

**Rationale.** After Lex 1 finds solution (Z1*, Z2_at_Z1*), we know that
Z2* <= Z2_at_Z1* -- any feasible solution achieving Z2 > Z2_at_Z1* cannot be
the lexicographic minimum of Z2, since we already found a feasible solution
with fewer swaps. Adding the constraint Z2 <= Z2_at_Z1* tightens the feasible
region explored during Lex 2.

**Implementation.** Before Lex 2's optimization call, the constraint
`sum(z[i,d]) <= Z2_at_Z1*` is added to the model. For the exact path
(which reuses `self.model`), this constraint is stored and removed after
Lex 2 completes to avoid interfering with subsequent epsilon-constraint solves.
For the R&F path (which uses a disposable fresh model), no cleanup is needed.

**Applicability.** Works for both methods. The inequality is valid regardless
of the solution method -- it follows directly from the definition of Pareto
dominance in the bi-objective space.

## Modified Methods

| Method | Changes |
|--------|---------|
| `_extract_solution_values()` | New helper. Extracts all variable values from a solved model. |
| `_inject_warm_start()` | New helper. Sets `.Start` on matching variables across models. |
| `_solve_for_lexicographic_min_unmet()` | Returns `solution` dict in result for downstream reuse. |
| `_solve_lex_min_unmet_with_rf()` | Returns `solution` dict in result. |
| `_solve_lex_min_unmet_exact_fallback()` | Returns `solution` dict in result. |
| `_solve_for_lexicographic_min_swap()` | Accepts `lex1_result`, `extra_time`. Applies all three improvements. |
| `_solve_lex_min_swap_with_rf()` | Accepts `lex1_result`, `extra_time`. Applies all three improvements. |
| `_solve_lex_min_swap_exact_fallback()` | Accepts `lex1_result`, `extra_time`. Applies all three improvements. |
| `_generate_epsilons()` | Computes unused Lex 1 time, passes Lex 1 result to Lex 2. |
| `_save_lexicographic_results()` | Records improvement metadata in output JSON. |

## Backward Compatibility

All three improvements are **fully backward-compatible**:

- `lex1_result` and `extra_time` default to `None` and `0` respectively
- When `lex1_result` is `None` (e.g., Lex 1 failed / infeasible), no
  warm-start, bound tightening, or time redistribution is applied
- Existing YAML configurations require no changes
- Output format is extended (new `improvements` key in
  `lexicographic_results.json`) but existing keys are unchanged

## Expected Impact

| Scenario | Warm-Start | Time Redistribution | Bound Tightening |
|----------|:----------:|:-------------------:|:----------------:|
| Lex 1 optimal, Lex 2 hits time limit | High | High | Medium |
| Both hit time limit | Medium | None | Medium |
| Both prove optimal | Low | None | Low |
| Lex 1 infeasible | N/A | None | N/A |

The combined effect is most significant when Lex 1 converges quickly (common
for the "minimize unmet exams" objective, which tends to have tighter LP
relaxation bounds) while Lex 2 struggles (common for "minimize swaps", where
the LP relaxation is weaker). This is precisely the scenario reported as
problematic.
