# Optimization-Only Mode

## Overview

All optimization pipelines (NSGA-2, Exact, Relax-and-Fix, Fix-and-Optimize/Hybrid) now run in **optimization-only mode by default**. This means:

- ✅ Optimization runs and saves all necessary data
- ❌ Analysis (plots, Gantt charts, reports) is **skipped**
- 📊 Analysis is done **separately after all optimization jobs complete**

## Why This Change?

1. **Performance**: Analysis (especially Gantt charts) was consuming 2/3 of NSGA-2 runtime
2. **Efficiency**: Run all optimizations first, analyze later
3. **Flexibility**: Can re-run analysis with different parameters without re-optimizing
4. **Standardization**: All methods (NSGA-2, MIP) now work the same way

## Directory Structure

### NSGA-2 Output Structure

```
<output_dir>/
├── solution/
│   ├── solutions_summary.csv          # Pareto front summary (all solutions)
│   ├── evolution_history.csv          # Evolution metrics per generation
│   ├── evolution_summary.txt          # Evolution statistics
│   ├── diversity_history.json         # Diversity tracking data
│   ├── diversity_summary.csv          # Diversity statistics
│   ├── sol_1/                         # Individual Pareto solutions
│   │   ├── allocation.csv
│   │   ├── coverage.csv
│   │   └── swaps.csv
│   ├── sol_2/
│   │   └── ...
│   └── ...
├── config.json                        # Optimization configuration
└── instance_info.json                 # Instance metadata
```

### MIP Output Structure (Exact/RF/Hybrid)

```
<output_dir>/
├── solution/
│   ├── eps294/                        # Epsilon point 294
│   │   ├── allocation.csv
│   │   ├── coverage.csv
│   │   ├── swaps.csv
│   │   ├── results.txt
│   │   └── results_summary.csv
│   ├── eps804/
│   │   └── ...
│   └── ...
├── analysis/                          # Created by epsilon method
│   ├── swaps_epsilon_solutions.csv    # Summary of all epsilon points
│   └── swaps_summary_stats.txt        # Statistics
├── config.json                        # (saved by runner if available)
└── instance_info.json                 # Instance metadata
```

## Usage

### Running Optimization (Default)

```bash
# NSGA-2 (optimization only - DEFAULT)
python pipelines/run_nsga2_pipeline.py \
    --instance_file data/input/instances/30_days/2022jan02_to_2022jan31 \
    --output_dir data/output/nsga2_test \
    --skip_internal_analysis

# MIP methods (optimization only - DEFAULT)
python pipelines/run_epsilon_pipeline.py \
    --instance_file data/input/instances/30_days/2022jan02_to_2022jan31 \
    --output_dir data/output/exact_test \
    --primary_objective swaps \
    --num_epsilons 7
```

### Running Optimization + Analysis (Optional)

```bash
# If you want analysis during optimization (slower)
python pipelines/run_nsga2_pipeline.py \
    --instance_file ... \
    --output_dir ... \
    --with_analysis
```

### Running Analysis After Optimization

```bash
# After all optimization jobs complete
python analytics/runners/run_analysis.py \
    data/output/nsga2_test \
    --method nsga2

# For MIP methods
python analytics/runners/run_analysis.py \
    data/output/exact_test \
    --method math_model \
    --primary_objective swaps
```

## Data Saved for Post-Analysis

### NSGA-2

1. **Pareto Front**: `solutions_summary.csv` with objectives for all solutions
2. **Evolution History**: `evolution_history.csv` with fitness, feasibility, diversity per generation
3. **Diversity History**: `diversity_history.json` with population diversity tracking
4. **Individual Solutions**: CSVs (allocation, coverage, swaps) for each Pareto solution
5. **Configuration**: `config.json` with all optimization parameters
6. **Instance Info**: `instance_info.json` with problem size and metadata

### MIP (Exact/RF/Hybrid)

1. **Epsilon Solutions**: Individual directories with allocation/coverage/swaps CSVs
2. **Runtime Data**: `results_summary.csv` per epsilon with runtime, gap, status
3. **Aggregate Results**: `epsilon_solutions.csv` with all epsilon points
4. **Configuration**: Saved by run_epsilon.py if available
5. **Instance Info**: `instance_info.json` with problem metadata

## Cluster Workflow

```bash
# 1. Submit all optimization jobs
bash cluster/submit_run_1.sh

# 2. Wait for jobs to complete (check with qstat)
qstat -u $USER

# 3. Run analysis on all results (single PBS job)
qsub cluster/pbs/run_full_analysis.pbs
```

## Migration Notes

### Old Behavior (Before)
- Pipeline ran optimization + analysis by default
- `--only_optimization` flag skipped analysis
- Analysis consumed significant time (2-3x slower)

### New Behavior (Now)
- Pipeline runs optimization only by default
- `--with_analysis` flag enables analysis
- `--only_optimization` is deprecated (now default)
- Analysis is a separate post-processing step

### Backward Compatibility
- Old scripts with `--only_optimization` still work (flag ignored)
- Batch processors updated to remove redundant flag
- All data structures remain compatible

## Benefits

1. **3x faster NSGA-2**: 3h → 1h per instance (skipping 2h of analysis)
2. **Flexible analysis**: Re-run with different parameters without re-optimizing
3. **Better resource usage**: Optimize on high-CPU nodes, analyze on single node
4. **Standardized workflow**: All methods work consistently
5. **Easier debugging**: Optimization logs are cleaner without analysis output

## See Also

- [COMPARATIVE_GANTT_DESIGN.md](COMPARATIVE_GANTT_DESIGN.md) - Gantt chart generation
- [GANTT_OPTIMIZATION_SUMMARY.md](GANTT_OPTIMIZATION_SUMMARY.md) - Gantt optimization details
- `analytics/runners/run_analysis.py` - Main analysis script
- `analytics/analysis/` - Analysis modules
