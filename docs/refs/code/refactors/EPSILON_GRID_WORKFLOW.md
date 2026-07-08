# Epsilon Grid Pre-Computation Workflow

## Overview

When comparing MIP methods (Exact, Relax-and-Fix, Hybrid), they must all solve problems with the **SAME epsilon values**. Different epsilon values = different problems, making results incomparable.

**Problem**: In cluster environments, jobs run in parallel. If R&F/Hybrid start before Exact finishes, they generate different epsilon grids.

**Solution**: Pre-compute epsilon grids as a separate prerequisite step, then all methods load the same grid.

## Architecture

```
                  +---------------------+
                  |  Epsilon Grid Gen   |
                  |  (Lexicographic)    |
                  +----------+----------+
                             |
                             v
        +------------------+-+-----------------+
        |                  |                   |
        v                  v                   v
+-------+------+  +-------+-------+  +--------+------+
|    Exact     |  | Relax-and-Fix |  |    Hybrid     |
| (uses grid)  |  |  (uses grid)  |  |  (uses grid)  |
+--------------+  +---------------+  +---------------+
```

## Files Created/Modified

### New Files

1. **`pipelines/run_epsilon_grid_pipeline.py`**
   - Standalone pipeline for epsilon grid generation
   - Runs only lexicographic phase (min_z1, min_z2)
   - Outputs: `epsilon_grid.json`, `lexicographic_results.json`

2. **`cluster/batch/batch_epsilon_grid.py`**
   - Batch script for generating grids for multiple instances
   - Validates grid existence before running MIP experiments

3. **`cluster/pbs/euler_epsilon_grid.pbs`**
   - PBS script for cluster execution
   - Must complete before MIP jobs are submitted

4. **`cluster/configs/epsilon_grid/epsilon_grid_60days.yaml`**
   - Sample config for epsilon grid generation

5. **`cluster/configs/local_test/mip_60days_*_v2.yaml`**
   - Updated configs that use pre-computed shared grids

### Modified Files

1. **`engine/mip/utils/epsilon_grid.py`**
   - Added `InstanceMismatchError` exception
   - Added `instance_info` parameter to `generate_from_bounds()`
   - Added `validate_instance()` and `load_and_validate()` methods
   - Added `get_grid_file_for_instance()` helper function

2. **`engine/mip/exact/multi_method/epsilon_method.py`**
   - For heuristics: REQUIRES valid pre-computed grid
   - Validates grid matches current instance
   - Fails fast with clear error message if grid missing/invalid

3. **`cluster/batch/batch_mip.py`**
   - Pre-validates all grids before running experiments
   - Aborts batch if any heuristic experiment has missing/invalid grid

4. **`bin/run-mip-local`**
   - Added `--generate-grid` mode for local grid generation

## Usage Workflow

### 1. Generate Epsilon Grids (Run Once Per Instance)

**Cluster:**
```bash
qsub -N epsilon_grid -l ncpus=32 -l walltime=24:00:00 \
     -v CONFIG_FILE=cluster/configs/epsilon_grid/epsilon_grid_60days.yaml \
     cluster/pbs/euler_epsilon_grid.pbs
```

**Local:**
```bash
bash bin/run-mip-local --generate-grid cluster/configs/epsilon_grid/epsilon_grid_60days.yaml
```

**Direct Python:**
```bash
python pipelines/run_epsilon_grid_pipeline.py \
    --instance_file data/input/instances/60_days/2022jan02_to_2022mar02 \
    --primary_objective swaps \
    --num_epsilons 7
```

### 2. Run MIP Experiments (All Use Same Grid)

**Cluster:** (can now run in parallel!)
```bash
# All three jobs can be submitted at once after grid is ready
qsub -v CONFIG_FILE=cluster/configs/local_test/mip_60days_exact_v2.yaml cluster/pbs/euler_exact_batch.pbs
qsub -v CONFIG_FILE=cluster/configs/local_test/mip_60days_rf_v2.yaml cluster/pbs/euler_rf_batch.pbs
qsub -v CONFIG_FILE=cluster/configs/local_test/mip_60days_hybrid_v2.yaml cluster/pbs/euler_fo_batch.pbs
```

**Local:**
```bash
bash bin/run-mip-local cluster/configs/local_test/mip_60days_exact_v2.yaml
bash bin/run-mip-local cluster/configs/local_test/mip_60days_rf_v2.yaml
bash bin/run-mip-local cluster/configs/local_test/mip_60days_hybrid_v2.yaml
```

## Grid File Structure

Grids are stored in a standardized location:

```
data/output/epsilon_grids/
├── 2022jan02_to_2022mar02/
│   └── swaps/
│       ├── epsilon_grid.json       # The shared epsilon grid
│       └── lexicographic_results.json  # Detailed lexicographic info
├── 2023apr01_to_2023may30/
│   └── swaps/
│       ├── epsilon_grid.json
│       └── lexicographic_results.json
```

## Grid File Format

`epsilon_grid.json`:
```json
{
  "epsilons": [5323, 6602, 7882, 9162, 10441, 11720, 13000],
  "metadata": {
    "source_method": "exact",
    "primary_objective": "swaps",
    "min_bound": 5323,
    "max_bound": 13000,
    "num_points": 7,
    "step_size": 1279.5,
    "generated_at": "2024-01-15T10:30:00",
    "instance": {
      "instance_file": "data/input/instances/60_days/2022jan02_to_2022mar02",
      "start_date": "2022-01-02",
      "end_date": "2022-03-02",
      "instance_name": "2022jan02_to_2022mar02"
    },
    "lexicographic": {
      "min_z1": {"z1": 5323, "z2": 8500, "status": "Optimal", "gap": 0.0},
      "min_z2": {"z1": 13000, "z2": 2100, "status": "Optimal", "gap": 0.0}
    }
  }
}
```

## Validation

The system validates that grids match the target instance:

1. **Instance name** must match
2. **Start date** must match
3. **End date** must match

If validation fails, you get a clear error message:

```
Epsilon grid does not match target instance:
  Grid file instance: 2022jan02_to_2022mar02 (2022-01-02 to 2022-03-02)
  Target instance: 2023apr01_to_2023may30 (2023-04-01 to 2023-05-30)
  Errors: Instance mismatch: grid=2022jan02_to_2022mar02, target=2023apr01_to_2023may30

  Please generate a grid for this specific instance first using:
    python pipelines/run_epsilon_grid_pipeline.py --instance_file data/input/instances/60_days/2023apr01_to_2023may30
```

## YAML Config Changes

### Grid Generation Config (`epsilon_grid_60days.yaml`)

```yaml
configuration:
  LEX_METHOD: "exact"           # or "relax_and_fix" for faster bounds
  PRIMARY_OBJECTIVE: "swaps"
  NUM_EPSILONS: 7
  LEX_TIME_LIMIT: 7200          # 2 hours per lexicographic point
  BASE_OUTPUT_DIR: "data/output"

instances:
  - INSTANCE_FILE: data/input/instances/60_days/2022jan02_to_2022mar02
  - INSTANCE_FILE: data/input/instances/60_days/2023apr01_to_2023may30
```

### MIP Experiment Config (heuristics must specify `EPSILON_GRID_FILE`)

```yaml
experiments:
  - INSTANCE_FILE: data/input/instances/60_days/2022jan02_to_2022mar02
    OUTPUT_DIR: "data/output/mip_comparison/60_days/2022jan02_to_2022mar02/rf_swaps"
    
    # REQUIRED for heuristics - points to shared grid
    EPSILON_GRID_FILE: "data/output/epsilon_grids/2022jan02_to_2022mar02/swaps/epsilon_grid.json"
    
    SUB_SOLVER: "relax_and_fix"
    # ... other parameters
```

## Error Handling

### Missing Grid File
```
EPSILON GRID FILE NOT FOUND
================================================================================
Grid file: data/output/epsilon_grids/2022jan02_to_2022mar02/swaps/epsilon_grid.json

For heuristic methods (sub_solver=relax_and_fix), a pre-computed
epsilon grid is REQUIRED to ensure method comparability.

Please generate the grid first using:
  python pipelines/run_epsilon_grid_pipeline.py \
      --instance_file data/input/instances/60_days/2022jan02_to_2022mar02 \
      --base_output_dir data/output \
      --primary_objective swaps
================================================================================
```

### Grid Not Specified
```
NO EPSILON GRID FILE SPECIFIED
================================================================================
For heuristic methods (sub_solver=relax_and_fix), an epsilon grid
must be pre-computed to ensure method comparability.

Expected grid location:
  data/output/epsilon_grids/2022jan02_to_2022mar02/swaps/epsilon_grid.json

Please generate the grid first, then add to your config:
  EPSILON_GRID_FILE: "data/output/epsilon_grids/2022jan02_to_2022mar02/swaps/epsilon_grid.json"
================================================================================
```

## Reference Gap Computation (Post-Processing)

### The Problem

When heuristic methods (R&F, Hybrid) solve epsilon-constrained subproblems, Gurobi reports the gap as 0% (optimal for that subproblem). However, this is **misleading** because:

1. The subproblem uses a relaxed model (fewer variables/constraints)
2. The "optimal" solution for the relaxed model may be suboptimal for the full model
3. We need gaps computed against the **exact method's bounds** for true comparability

### The Solution

The `compute_reference_gaps.py` script computes accurate reference gaps:

1. Loads exact method's Pareto front (the reference bounds)
2. For each heuristic solution, calculates gap against exact bounds
3. Outputs `pareto_front_with_ref_gaps.csv` with new columns:
   - `ref_z1_gap`: Gap in primary objective vs exact reference
   - `ref_z2_gap`: Gap in secondary objective vs exact reference
   - `ref_combined_gap`: Combined reference gap

### Automatic Integration

**Local execution** (`bin/run-mip-local`):
- Automatically runs reference gap computation after experiments complete
- Detects exact results and heuristic results in the same base directory
- Generates `gap_comparison.csv` summary

**Cluster execution** (`cluster/pbs/euler_reference_gaps.pbs`):
- Run as a separate post-processing job after all MIP experiments complete:

```bash
qsub -N ref_gaps -l ncpus=4 -l walltime=01:00:00 \
     -v BASE_DIR=data/output/mip_comparison/60_days/2022jan02_to_2022mar02 \
     cluster/pbs/euler_reference_gaps.pbs
```

**Manual execution**:
```bash
python scripts/utils/compute_reference_gaps.py \
    --exact_dir data/output/mip_comparison/60_days/2022jan02_to_2022mar02/exact_swaps \
    --heuristics_base data/output/mip_comparison/60_days/2022jan02_to_2022mar02 \
    --heuristic_dirs rf_swaps hybrid_swaps \
    --comparison_output data/output/mip_comparison/60_days/2022jan02_to_2022mar02/gap_comparison.csv
```

### Output Files

After reference gap computation:

```
BASE_DIR/
├── exact_swaps/
│   └── analysis/
│       └── pareto_front.csv              # Reference bounds
├── rf_swaps/
│   └── analysis/
│       ├── pareto_front.csv              # Original (misleading gaps)
│       └── pareto_front_with_ref_gaps.csv  # Accurate reference gaps
├── hybrid_swaps/
│   └── analysis/
│       ├── pareto_front.csv
│       └── pareto_front_with_ref_gaps.csv
└── gap_comparison.csv                     # Summary comparison table
```

### Complete Workflow Summary

```
1. Generate Epsilon Grid
   └── pipelines/run_epsilon_grid_pipeline.py
   
2. Run MIP Experiments (in parallel)
   ├── Exact
   ├── Relax-and-Fix
   └── Hybrid
   
3. Compute Reference Gaps (post-processing)
   └── scripts/utils/compute_reference_gaps.py
   
4. Analysis & Visualization
   └── Use pareto_front_with_ref_gaps.csv for accurate comparisons
```

## Migration from Old Workflow

If you have existing experiments that relied on the old flow (exact generates grid, others load from exact's output_dir):

1. **For new experiments**: Use the new workflow (generate grid first)
2. **For existing results**: Results are still valid, but grids are in `exact_swaps/epsilon_grid.json` instead of the shared location
3. **To migrate**: Simply re-run grid generation, then update YAML configs to point to shared location
4. **For gap analysis**: Run `compute_reference_gaps.py` on existing results to get accurate reference gaps
