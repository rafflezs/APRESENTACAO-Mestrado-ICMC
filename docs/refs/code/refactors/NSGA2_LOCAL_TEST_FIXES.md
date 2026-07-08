# NSGA-2 Local Testing Fixes

**Date**: 2026-02-04
**Status**: Fixed - Ready for testing

## Issues Fixed

### Issue 1: Analysis Script Method Argument Error

**Problem:**
```
run_analysis.py: error: argument --method: invalid choice: 'nsga2' (choose from 'math_model', 'heuristic')
```

When running with `OPTIMIZATION_ONLY: false`, the pipeline tried to call analysis with `--method nsga2` but the analysis script only accepts `math_model` or `heuristic`.

**Root Cause:**
`pipelines/run_nsga2_pipeline.py:231` was passing `--method nsga2` to `analytics/runners/run_analysis.py`

**Fix Applied:**
Changed line 231 in `pipelines/run_nsga2_pipeline.py`:
```python
# Before
"--method", "nsga2",

# After
"--method", "heuristic",  # NSGA-2 is a heuristic method
```

**Files Modified:**
- `pipelines/run_nsga2_pipeline.py` (line 231)

---

### Issue 2: Inconsistent Solution Naming

**Problem:**
Two different code paths used different naming schemes:
- `_run_analysis()` → `_export_standardized_solutions()`: Good naming (`1_min_unmet`, `5_min_swaps`)
- `_save_minimal_outputs()`: Bad naming (`sol_1`, `sol_2`, ...)

When using `--skip_internal_analysis`, solutions were saved with generic `sol_<id>` names that don't indicate which are lexicographic extremes.

**Root Cause:**
`_save_minimal_outputs()` method (lines 382-398) used simple sequential naming instead of semantic naming.

**Fix Applied:**
Updated `engine/runners/run_nsga2.py` `_save_minimal_outputs()` method to use same naming logic as `_export_standardized_solutions()`:

- **Lexicographic extremes clearly labeled:**
  - `1_min_unmet` → Minimum unmet demand (maximum swaps)
  - `<N>_min_swaps` → Minimum swaps (maximum unmet demand)

- **Middle solutions numbered:**
  - `2_solution`, `3_solution`, etc. → Well-distributed intermediate solutions

- **Consistent selection:** Evenly-spaced solutions along Pareto front (sorted by F1)

**Naming Logic:**
```python
if n_solutions == 1:
    ['1_min_unmet']
elif n_solutions == 2:
    ['1_min_unmet', '2_min_swaps']
else:  # 3-7 solutions
    ['1_min_unmet', '2_solution', ..., 'N_min_swaps']
```

**Files Modified:**
- `engine/runners/run_nsga2.py` (lines 382-398 → expanded to 382-420)

---

### Issue 3: Output Directory Path

**Problem:**
Config had `OUTPUT_DIR: "tmp/local-tests/..."` which is inconsistent with the standard `data/output/` location.

**Fix Applied:**
Updated `cluster/configs/local-tests/nsga2/nsga2_30days.yaml`:
```yaml
# Before
OUTPUT_DIR: "tmp/local-tests/30_days/..."

# After
OUTPUT_DIR: "data/output/local-tests/30_days/..."
```

**Files Modified:**
- `cluster/configs/local-tests/nsga2/nsga2_30days.yaml` (line 8)

---

## Testing Checklist

### Quick Test (5 minutes)
```bash
# Test with minimal time to verify fixes work
bash bin/run-nsga2-local cluster/configs/local-tests/nsga2/nsga2_30days.yaml | tee logs/test-fixes-quick.log
```

**Expected behavior:**
- [X] No hang during setup
- [X] Optimization runs with N_WORKERS: 1
- [X] Solutions saved with good naming (1_min_unmet, 5_min_swaps)
- [X] Analysis runs successfully (if OPTIMIZATION_ONLY: false)

### Full Test (1 hour)
```bash
# Your 1-hour test configuration
bash bin/run-nsga2-local cluster/configs/local-tests/nsga2/nsga2_30days.yaml | tee logs/nsga2-1hour-local-test.log
```

**Expected outputs:**
```
data/output/local-tests/30_days/2022jan02_to_2022jan31/nsga2_extended/
├── solution/
│   ├── 1_min_unmet/          # Lexicographic extreme (min F1)
│   │   ├── allocation.csv
│   │   ├── coverage.csv
│   │   ├── results.json
│   │   └── ...
│   ├── 2_solution/           # Intermediate solution
│   ├── 3_solution/           # Intermediate solution
│   ├── ...
│   ├── N_min_swaps/          # Lexicographic extreme (min F2)
│   ├── solutions_summary.csv
│   ├── evolution_history.csv
│   └── diversity_history.json
└── analysis/
    ├── pareto_front.png
    ├── diversity_diagnostics_composite.png
    ├── evolution_fitness.png
    └── ...
```

---

## Current Configuration Status

### Local Test Config: `cluster/configs/local-tests/nsga2/nsga2_30days.yaml`

**Instance 1 (Jan 2-31):**
- Population: 100
- Termination: 300s (5 minutes) - Quick test
- N_WORKERS: 1 (sequential)
- ALGORITHM: nsga2_extended (all enhancements enabled)

**Instance 2 (Jul 1-30):**
- Population: 100
- Termination: 3600s (1 hour) - Full test
- N_WORKERS: 1 (sequential)
- ALGORITHM: nsga2_extended (all enhancements enabled)

**Configuration:**
- NCPUS: 1 (local single-thread)
- OPTIMIZATION_ONLY: false (runs analysis after optimization)

---

## Recommendations

### For Local Testing
1. **Use Instance 1 for quick validation** (5 min)
2. **Use Instance 2 for full test** (1 hour)
3. **Monitor logs in real-time:**
   ```bash
   tail -f logs/nsga2-extended-trial-run-local.log
   ```

### For Cluster Execution
- Use configs in `cluster/configs/jan_26_allin/parametrization/nsga2/`
- Those have NCPUS: 20 and longer time limits appropriate for cluster

### Solution Naming Guide
- **`1_min_unmet`**: Best for coverage (minimizes unmet demand F1)
- **`N_min_swaps`**: Best for stability (minimizes physician swaps F2)
- **`<K>_solution`**: Trade-off solutions (balanced between F1 and F2)
- Solutions are evenly distributed along Pareto front for representative sampling

---

## Files Modified Summary

1. **pipelines/run_nsga2_pipeline.py**
   - Line 231: Fixed analysis method argument

2. **engine/runners/run_nsga2.py**
   - Lines 382-420: Unified solution naming in `_save_minimal_outputs()`

3. **cluster/configs/local-tests/nsga2/nsga2_30days.yaml**
   - Line 8: Fixed output directory path

---

## Next Steps

1. Run quick test to verify all fixes work
2. If successful, run 1-hour test on Instance 2
3. Verify solution naming is correct in output directory
4. Check that analysis completes without errors
5. Compare results with previous runs to ensure quality
