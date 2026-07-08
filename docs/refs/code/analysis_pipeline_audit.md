# Analysis Pipeline - Audit Report & Usage Guide

## Audit Summary

### Data Verification

- **Total experiments**: 536 (68 methods x 8 instances)
- **Horizons**: 15, 30, 60, 90 days (2 instances each)
- **Methods per instance**: 1 exact + 6 RF + 6 hybrid + 27 nsga2c + 27 nsga2e + 1 grid_swaps = 68
- **Data integrity**: All 536 experiments have `instance_info.json` and raw solution files
- **OPTIMIZATION_ONLY=true impact**: None on raw data. Only `analysis/` directory (plots, derived metrics) is omitted -- fully regeneratable by `run_analysis.py`

### Bugs Found & Fixed

#### 1. nsga2e missing `solutions_summary.csv` (CRITICAL)

- **File**: `engine/runners/run_nsga2.py` line 391
- **Cause**: `_save_minimal_outputs()` instantiates `ResultsAnalyzer` without `output_mode='file'`, so `solutions_summary.csv` is printed to stdout instead of saved to disk
- **Impact**: ALL 216 nsga2e experiments were missing `solutions_summary.csv`
- **Fix**: Added `output_mode='file'` to `ResultsAnalyzer` constructor
- **Data recovery**: Script `scripts/utils/reconstruct_nsga2e_summaries.py` reconstructed all 216 files from individual `results.json` files (7 representative solutions each)

#### 2. `parametrization_analyzer` column name mismatch (CRITICAL)

- **File**: `analytics/comparison/parametrization_analyzer.py` line 246
- **Cause**: `_find_objective_columns()` did not recognize actual column names from output CSVs:
  - MIP produces `Z1_exams` -- was not in z1 candidates
  - NSGA2c produces `F1_unmet` -- was not in z1 candidates
  - NSGA2e (ResultsAnalyzer) produces `unmet` -- was not in z1 candidates
- **Impact**: Parametrization comparison would skip ALL configurations silently
- **Fix**: Added actual column names to candidates lists: `Z1_exams`, `F1_unmet`, `unmet`, `F2_swaps`, `F1_UnmetDemand`

#### 3. Shell script picking up non-method directories (from previous session)

- **File**: `scripts/run_full_parametrization_analysis.sh` line ~140
- **Fix**: Added exclusion filter for `parametrization_analysis/`, `cross_analysis/`, `analysis/`

#### 4. Pipeline duplicate work (from previous session)

- **File**: `pipelines/run_analysis_pipeline.py` line 227
- **Fix**: Added `analysis_summary.json` cache check to `run_individual_analysis()`

#### 5. Python script file handle leak (from previous session)

- **File**: `scripts/run_full_parametrization_analysis.py` lines ~76, ~148
- **Fix**: Wrapped `subprocess.run(stdout=open(...))` with `with open() as fh:` context managers

### Results Audit

#### MIP Gap Analysis

| Horizon | MIP Gap Range | Exact Convergence | Heuristic Dominance |
|---------|-------------|-------------------|---------------------|
| 15 days | 0-7% | Mostly optimal (6/7 eps optimal) | Rare, minor |
| 30 days | 5-50% | Partially converged | Common for F2 |
| 60 days | 52-95% | Poorly converged | Frequent for both F1/F2 |
| 90 days | 76-99.99% | Barely converged | Very common |

- **Conclusion**: Heuristics beating Exact is EXPECTED behavior, not a bug. The Exact method does not converge within the 1-hour time limit for larger instances. This is a valid experimental finding for the dissertation.

#### Extreme Z2 Values (90-day instances)

Several Exact solutions on 90-day instances show Z2 (swaps) > 9000 with 99.9%+ gap, meaning the solver returned near-first-feasible solutions with almost no optimization. These are valid but essentially useless datapoints.

#### Empty Epsilon Points

18 instances across 30/90-day horizons have 1 empty epsilon point (infeasible within time limit at the tightest constraint). The Exact method itself has 1 empty point on `30_days/2022jul01_to_2022jul30`.

### Pipeline Execution Results (2026-03-03)

Full pipeline executed successfully in **13298s (3.7 hours)** with 8 workers.

| Phase | Scope | Result |
|-------|-------|--------|
| Phase 1 | 536 individual analyses (parametrization) | 534 ok + 2 cached + 0 fail |
| Phase 2 | 8 instances x 4 method groups = 32 comparisons | 32 ok (exact skipped: < 2 configs) |
| Phase 3 | 32 run experiments (exact_swaps) | 32 ok |

**Generated artifacts**:
- 536 `analysis_summary.json` files (parametrization)
- 32 `analysis_summary.json` files (run experiments)
- 32 `parametrization_comparison.csv` + `parametrization_summary.json`
- 32 `pareto_comparison.png` (Pareto front overlay per group)
- 72 `sensitivity_*.png` (parameter sensitivity plots)
- 0 errors in individual analysis logs

---

## Usage Guide

### Quick Start

```bash
# Activate virtual environment
source venv/bin/activate

# Run full analysis (all 3 phases)
python3 scripts/run_full_parametrization_analysis.py --max_workers 8

# Run specific phases
python3 scripts/run_full_parametrization_analysis.py --skip_phase2 --skip_phase3  # Phase 1 only
python3 scripts/run_full_parametrization_analysis.py --skip_phase1 --skip_phase3  # Phase 2 only
python3 scripts/run_full_parametrization_analysis.py --skip_phase1 --skip_phase2  # Phase 3 only
```

### What Each Phase Does

#### Phase 1: Individual Method Analysis (parallel)
- Runs `analytics/runners/run_analysis.py` on each of the 536 method directories
- For MIP methods: Runs `EpsilonAnalyzer` (Pareto front analysis, performance metrics, solution structure)
- For NSGA-2 methods: Runs `SolutionAnalyzer` on each Pareto-representative solution
- Produces: `analysis/analysis_summary.json` per method directory (used as cache indicator)
- **Cache**: Skips if `analysis/analysis_summary.json` already exists
- **Time**: ~30s per 15-day, ~300s per 90-day, ~2h total with 8 workers

#### Phase 2: Parametrization Comparison (sequential per instance)
- Runs `analytics/comparison/parametrization_analyzer.py` per method group per instance
- Groups: all RF variants, all Hybrid variants, all nsga2c variants, all nsga2e variants
- Produces: `parametrization_analysis/{group}/` with comparison tables, Pareto overlay plots
- Reads from `solution/solutions_summary.csv` (NSGA-2) or `analysis/*_epsilon_solutions.csv` (MIP)

#### Phase 3: Run Experiment Analysis
- Same as Phase 1 but for `data/output/allin_fev26_5/run/` directory
- Typically contains the "production" exact_swaps experiments

### Running Individual Analyses

```bash
# Analyze a single MIP experiment
python3 analytics/runners/run_analysis.py \
    data/output/allin_fev26_5/parametrization/15_days/2022jan02_to_2022jan16/exact_swaps \
    --method math_model --primary_objective swaps --skip_gantt --save_summary

# Analyze a single NSGA-2 experiment
python3 analytics/runners/run_analysis.py \
    data/output/allin_fev26_5/parametrization/15_days/2022jan02_to_2022jan16/nsga2c_p100_m03_allon \
    --method heuristic --skip_gantt --save_summary
```

### Running Parametrization Comparison Manually

```bash
# Compare all RF variants for an instance
python3 analytics/comparison/parametrization_analyzer.py \
    --group_name rf_swaps \
    --config_dirs "dir1,dir2,dir3" \
    --output_dir output/parametrization_analysis/rf_swaps/
```

### Reconstructing nsga2e summaries (if needed)

```bash
# Reconstruct solutions_summary.csv for all nsga2e experiments
python3 scripts/utils/reconstruct_nsga2e_summaries.py \
    data/output/allin_fev26_5/parametrization

# Dry-run (no changes)
python3 scripts/utils/reconstruct_nsga2e_summaries.py \
    data/output/allin_fev26_5/parametrization --dry-run

# Force overwrite existing
python3 scripts/utils/reconstruct_nsga2e_summaries.py \
    data/output/allin_fev26_5/parametrization --force
```

### Monitoring Progress

```bash
# Check pipeline progress (if running in background)
tail -f logs/analysis_parametrization/full_run_*.log

# Count completed analyses
find data/output/allin_fev26_5/parametrization -name "analysis_summary.json" | wc -l

# Check for failures in individual logs
grep -r "FAIL\|ERROR\|Traceback" logs/analysis_parametrization/*.log | head -20
```

### Output Structure

After analysis, each method directory gains:
```
method_dir/
  analysis/
    analysis_summary.json          # Cache indicator + summary metrics
    performance_analysis/          # (MIP only) Runtime breakdown
    solution_structure/            # Structure analysis per solution
    aggregate_metrics.csv          # (MIP only) Aggregated metrics
  solution/
    eps*/analysis/                 # (MIP) Per-epsilon analysis
    {N}_solution/analysis/         # (NSGA-2) Per-solution analysis
```

Parametrization comparison output:
```
instance_dir/
  parametrization_analysis/
    rf_swaps/
      parametrization_comparison.csv
      pareto_comparison.png
      parameter_sensitivity.png
    hybrid_swaps/
      ...
    nsga2c/
      ...
    nsga2e/
      ...
```
