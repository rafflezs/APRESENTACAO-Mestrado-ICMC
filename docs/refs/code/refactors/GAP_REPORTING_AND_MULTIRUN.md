# Gap Reporting Corrections and Multi-Run NSGA-2 Infrastructure

**Date:** 2026-02-06
**Files:** `epsilon_method.py`, `fix_and_optimize.py`, `relax_and_fix.py`,
`multi_run_analyzer.py`, `unified_comparator.py`, `batch_nsga2.py`

## 1. Problem Statement

### 1.1 Misleading MIP Gaps

The Fix-and-Optimize (F&O) matheuristic reported `status = OPTIMAL` and
`mip_gap = 0.0` for every solution, despite lacking any global dual bound.
This occurred because the return dictionary hardcoded these values rather than
reflecting the actual solver state. Relax-and-Fix (R&F) reported a local
sub-problem gap from its final polish solve, which is valid but not comparable
to the exact method's global gap. Neither gap type was labeled, making
cross-method CSV comparisons unreliable.

### 1.2 No Multi-Run NSGA-2 Support

Stochastic metaheuristics require multiple independent runs (different random
seeds) to assess solution quality reliably. The codebase supported only
single-seed execution, lacking infrastructure for batch seed expansion,
per-run metric aggregation, and non-parametric significance testing.

## 2. Gap Reporting Corrections

### 2.1 Gap Type Classification

Each epsilon-constraint solve now carries a `gap_type` label:

| `gap_type` | Method | Meaning |
|---|---|---|
| `exact` | Epsilon-constraint (exact) | True MIP gap from global B&B |
| `local_polish` | Relax-and-Fix | Gap from the final polish sub-problem; NOT a global bound |
| `none` | Fix-and-Optimize / Hybrid F&O | No valid dual bound exists |

### 2.2 Honest F&O Reporting

The F&O return dictionary was changed from fabricated values to honest ones:

- `status`: actual `model.status` (not hardcoded `GRB.OPTIMAL`)
- `obj_bound`: `None` (not `self._best_obj`)
- `mip_gap`: `None` (not `0.0`)
- `gap_type`: `'none'`

### 2.3 Inline Reference Gap Computation

For heuristic methods (R&F, F&O, hybrid), the epsilon-constraint summary CSV
now includes reference gap columns computed against the exact method's dual
bounds, when available:

- `reference_bound`: best-matching lower bound from the exact method
- `reference_gap`: `|f(x_heur) - z_LB| / |f(x_heur)|` (absolute fraction)
- `reference_gap_pct`: reference_gap * 100

The exact method's bounds are loaded via `ReferenceBounds.from_pareto_csv()`.
Auto-detection searches sibling directories (`exact_swaps/`, `exact_exams/`,
`epsilon/`, `exact/`) for `analysis/pareto_front.csv`. If no exact results
exist, columns are set to `None` with a printed warning (safeguard).

For the exact method itself, reference columns equal the existing manual gap
columns (they ARE the reference).

### 2.4 Output CSV Columns

The epsilon summary CSV now contains (in addition to existing columns):

| Column | Description |
|---|---|
| `gap_type` | One of `exact`, `local_polish`, `none` |
| `reference_bound` | Exact method's dual bound for closest epsilon |
| `reference_gap` | Absolute fractional gap to exact bound |
| `reference_gap_pct` | Percentage gap to exact bound |

## 3. Multi-Run NSGA-2 Infrastructure

### 3.1 Batch Seed Expansion (`batch_nsga2.py`)

YAML configurations now support a `SEEDS` list key:

```yaml
experiments:
  - INSTANCE_FILE: "data/input/instances/60_days/..."
    OUTPUT_DIR: "data/output/nsga2_extended/instance/"
    SEEDS: [42, 100, 200, 300, 500]
    POP_SIZE: 100
    # ... other parameters
```

When `SEEDS` is present, the batch processor expands the experiment into
`len(SEEDS)` independent runs, each with `SEED = seed` and
`OUTPUT_DIR = <base>/seed_<seed>`. The `SEEDS` key is removed from sub-configs
to prevent recursion. When `SEEDS` is absent, the existing single-`SEED` flow
is used unchanged (full backward compatibility).

### 3.2 Multi-Run Analyzer (`multi_run_analyzer.py`)

The `MultiRunNSGA2Analyzer` class:

1. **Discovers** `seed_*` directories under a base directory
2. **Loads** each run's Pareto front (`pareto_front.csv` or `solutions_summary.csv`)
3. **Computes per-run metrics**:
   - Hypervolume (shared reference point: `max(Z_i) * 1.1` across all runs)
   - IGD to reference Pareto (optional, e.g., exact method)
   - Schott's spacing (spread uniformity)
   - Pareto front size, Z1/Z2 ranges
4. **Aggregates** with descriptive statistics: mean, std, median, min, max,
   95% CI (t-distribution), coefficient of variation
5. **Statistical tests**:
   - Shapiro-Wilk normality per metric
   - Mann-Whitney U for pairwise comparison
   - Vargha-Delaney A measure (effect size classification)
6. **Computes combined Pareto front**: merges all runs, filters non-dominated
7. **Exports**: `per_run_metrics.csv`, `aggregated_metrics.json`,
   `combined_pareto_front.csv`, `statistical_tests.json`

### 3.3 Unified Comparator Extension (`unified_comparator.py`)

The `UnifiedMethodComparator` now:

- **Auto-detects** `seed_*` subdirectories when loading method results
- **Delegates** multi-run loading to `MultiRunNSGA2Analyzer`
- **Uses combined Pareto front** as the method's representative result set
- **Injects multi-run columns** into the comparison table: `Num_Runs`,
  `HV_mean`, `HV_std`, `IGD_mean`, `IGD_std`, `Spread_mean`, `Spread_std`
- **Performs pairwise significance tests** between multi-run methods via
  the analyzer's `statistical_tests()` method

## 4. Backward Compatibility

All changes are additive and backward-compatible:

- Existing YAML configs without `SEEDS` work unchanged
- Existing single-run output directories are loaded as before
- New CSV columns (`gap_type`, `reference_*`) are appended; existing columns
  are unchanged
- Reference gap computation degrades gracefully (None + warning) when no
  exact results are available
- The `MultiRunNSGA2Analyzer` import in `unified_comparator.py` is
  unconditional but the class is only instantiated when `seed_*` dirs exist
