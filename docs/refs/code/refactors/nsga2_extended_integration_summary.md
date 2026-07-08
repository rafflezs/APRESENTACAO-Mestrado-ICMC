# NSGA-2 Extended Integration Summary

**Date**: 2026-02-02
**Status**: ✅ Complete
**Purpose**: Update all configuration files and pipeline scripts to support NSGA2Extended

---

## Files Updated

### 1. YAML Configuration Files

**Updated Files**:
- `cluster/configs/jan_26_allin/parametrization/nsga2/nsga2_15days.yaml`
- `cluster/configs/jan_26_allin/parametrization/nsga2/nsga2_30days.yaml`
- `cluster/configs/jan_26_allin/parametrization/nsga2/nsga2_60days.yaml`
- `cluster/configs/jan_26_allin/parametrization/nsga2/nsga2_90days.yaml`

**Changes**:
- ✅ Added `ALGORITHM: "nsga2_extended"` parameter
- ✅ Updated operators to best strategies:
  - `CROSSOVER_STRATEGY: "day_based"` (proven best: F1=590, F2=162)
  - `MUTATION_STRATEGY: "slot_reassignment"` (proven best)
- ✅ Added sampling extreme parameters:
  - `SAMPLING_USE_EXTREME: true`
  - `SAMPLING_EXTREME_RATIO: 0.2`
- ✅ Added NSGA2Extended enhancement toggles:
  - `USE_EXTREME_INITIALIZATION: true` (Option 3)
  - `EXTREME_RATIO: 0.2`
  - `USE_TWO_STAGE: true` (Option 4)
  - `STAGE_TRANSITION: 0.5`
  - `USE_ADAPTIVE_DIVERSITY: true` (Option 2)
  - `DIVERSITY_EARLY: 0.15`
  - `DIVERSITY_MID: 0.10`
  - `DIVERSITY_LATE: 0.05`
- ✅ Updated output directories to `nsga2_extended`
- ✅ Updated aggregation files to `*_NSGA2_EXTENDED.csv`
- ✅ Updated job names with 'E' suffix (e.g., `PaNIIPE15days`)
- ✅ Updated log directories to `nsga2_extended`

---

### 2. Batch Processor

**File**: `cluster/batch/batch_nsga2.py`

**Changes**:
- ✅ Added parameter forwarding for:
  - `SAMPLING_USE_EXTREME` → `--sampling_use_extreme`
  - `SAMPLING_EXTREME_RATIO` → `--sampling_extreme_ratio`
  - `ALGORITHM` → `--algorithm`
  - `USE_EXTREME_INITIALIZATION` → `--use_extreme_initialization`
  - `EXTREME_RATIO` → `--extreme_ratio`
  - `USE_TWO_STAGE` → `--use_two_stage`
  - `STAGE_TRANSITION` → `--stage_transition`
  - `USE_ADAPTIVE_DIVERSITY` → `--use_adaptive_diversity`
  - `DIVERSITY_EARLY` → `--diversity_early`
  - `DIVERSITY_MID` → `--diversity_mid`
  - `DIVERSITY_LATE` → `--diversity_late`

---

### 3. Pipeline Script

**File**: `pipelines/run_nsga2_pipeline.py`

**Changes**:
- ✅ Added argument group `NSGA2Extended Configuration`
- ✅ Added arguments for all enhancement parameters
- ✅ Added sampling extreme arguments
- ✅ Updated `run_optimization()` to forward all new parameters to `run_nsga2.py`

**New Arguments**:
```python
--algorithm {nsga2,nsga2_extended}
--sampling_use_extreme BOOL
--sampling_extreme_ratio FLOAT
--use_extreme_initialization BOOL
--extreme_ratio FLOAT
--use_two_stage BOOL
--stage_transition FLOAT
--use_adaptive_diversity BOOL
--diversity_early FLOAT
--diversity_mid FLOAT
--diversity_late FLOAT
```

---

### 4. NSGA-2 Runner

**File**: `engine/runners/run_nsga2.py`

**Changes**:
- ✅ Added import for `NSGA2Extended` and `NSGA2ExtendedMonitor`
- ✅ Added argument parsing for all NSGA2Extended parameters
- ✅ Updated sampling operator creation to support extreme strategies
- ✅ Added algorithm selection logic:
  - If `algorithm='nsga2'`: Creates baseline `NSGA2`
  - If `algorithm='nsga2_extended'`: Creates `NSGA2Extended` with enhancements
- ✅ Added `NSGA2ExtendedMonitor` to callbacks when using extended algorithm
- ✅ Updated instance_info.json to include enhancement parameters
- ✅ Updated config.json to include enhancement parameters

**Algorithm Creation Logic**:
```python
if algorithm_type == 'nsga2_extended':
    algorithm = NSGA2Extended(
        pop_size=pop_size,
        sampling=sampling,
        crossover=crossover,
        mutation=mutation,
        use_extreme_initialization=True,
        extreme_ratio=0.2,
        use_two_stage=True,
        stage_transition=0.5,
        use_adaptive_diversity=True,
        diversity_early=0.15,
        diversity_mid=0.10,
        diversity_late=0.05,
        verbose=True
    )
else:
    algorithm = NSGA2(...)
```

---

## Parameter Mapping

### YAML → Batch → Pipeline → Runner

| YAML Parameter | Batch Flag | Pipeline Flag | Runner Usage |
|----------------|------------|---------------|--------------|
| `ALGORITHM` | `--algorithm` | `--algorithm` | Algorithm selection |
| `SAMPLING_USE_EXTREME` | `--sampling_use_extreme` | `--sampling_use_extreme` | `ConstraintAwareSampling(use_extreme_strategies=...)` |
| `SAMPLING_EXTREME_RATIO` | `--sampling_extreme_ratio` | `--sampling_extreme_ratio` | `ConstraintAwareSampling(extreme_ratio=...)` |
| `USE_EXTREME_INITIALIZATION` | `--use_extreme_initialization` | `--use_extreme_initialization` | `NSGA2Extended(use_extreme_initialization=...)` |
| `EXTREME_RATIO` | `--extreme_ratio` | `--extreme_ratio` | `NSGA2Extended(extreme_ratio=...)` |
| `USE_TWO_STAGE` | `--use_two_stage` | `--use_two_stage` | `NSGA2Extended(use_two_stage=...)` |
| `STAGE_TRANSITION` | `--stage_transition` | `--stage_transition` | `NSGA2Extended(stage_transition=...)` |
| `USE_ADAPTIVE_DIVERSITY` | `--use_adaptive_diversity` | `--use_adaptive_diversity` | `NSGA2Extended(use_adaptive_diversity=...)` |
| `DIVERSITY_EARLY` | `--diversity_early` | `--diversity_early` | `NSGA2Extended(diversity_early=...)` |
| `DIVERSITY_MID` | `--diversity_mid` | `--diversity_mid` | `NSGA2Extended(diversity_mid=...)` |
| `DIVERSITY_LATE` | `--diversity_late` | `--diversity_late` | `NSGA2Extended(diversity_late=...)` |

---

## Backward Compatibility

**Baseline NSGA-2 Still Works**:
- If `ALGORITHM: "nsga2"` or parameter omitted, uses standard NSGA2
- All old YAML files will work with `algorithm='nsga2'` (default)
- No breaking changes to existing pipelines

**To Use NSGA2Extended**:
- Set `ALGORITHM: "nsga2_extended"` in YAML
- Or use `--algorithm nsga2_extended` in command line

---

## Testing Checklist

### Unit Tests
- [ ] Test YAML loading with new parameters
- [ ] Test batch processor with both `nsga2` and `nsga2_extended`
- [ ] Test pipeline parameter forwarding
- [ ] Test runner algorithm selection

### Integration Tests
- [ ] Run 15-day instance with `nsga2` (baseline)
- [ ] Run 15-day instance with `nsga2_extended` (full enhancements)
- [ ] Verify output directory structure
- [ ] Verify config.json includes new parameters
- [ ] Verify instance_info.json includes enhancement settings

### Cluster Tests
- [ ] Submit PBS job with updated YAML
- [ ] Verify logs show enhancement activity
- [ ] Verify convergence metrics are saved
- [ ] Compare results: baseline vs extended

---

## Quick Start Examples

### Local Testing (Baseline)
```bash
python pipelines/run_nsga2_pipeline.py \
  --instance_file data/input/instances/15_days/2022jan02_to_2022jan16 \
  --output_dir data/output/test_nsga2_baseline \
  --algorithm nsga2 \
  --pop_size 50 \
  --termination_method n_gen \
  --termination_value 100
```

### Local Testing (Extended)
```bash
python pipelines/run_nsga2_pipeline.py \
  --instance_file data/input/instances/15_days/2022jan02_to_2022jan16 \
  --output_dir data/output/test_nsga2_extended \
  --algorithm nsga2_extended \
  --pop_size 50 \
  --termination_method n_gen \
  --termination_value 100 \
  --verbose
```

### Cluster Execution
```bash
# Using updated YAML
bash bin/run-nsga2-local cluster/configs/jan_26_allin/parametrization/nsga2/nsga2_15days.yaml

# Or PBS submission
qsub -N NSGA2E_15d -l ncpus=32 -l walltime=10:00:00 \
  -v CONFIG_FILE=cluster/configs/jan_26_allin/parametrization/nsga2/nsga2_15days.yaml \
  cluster/pbs/euler_nsga2_batch.pbs
```

---

## Expected Output

### Console Output (NSGA2Extended)
```
Creating NSGA-2 Extended algorithm (pop_size=100)...
  Enhancement: Extreme initialization (ratio=0.2)
  Enhancement: Two-stage evolution (transition=0.5)
  Enhancement: Adaptive diversity (early=0.15, mid=0.10, late=0.05)

Gen   10 | Stage: discovery   | Div: 0.1423 | F1:   590 (  612) | F2: 162 ( 168)
Gen   20 | Stage: discovery   | Div: 0.1389 | F1:   580 (  605) | F2: 158 ( 165)
...
Gen  100 | Stage: refinement  | Div: 0.0987 | F1:   565 (  590) | F2: 155 ( 162)
[NSGA2Extended] Gen 100: Diversity=0.0987, Target=0.1000 → maintain
```

### Output Files
```
data/output/run_jan26/run/15_days/2022jan02_to_2022jan16/nsga2_extended/
├── solution/
│   ├── solutions_summary.csv
│   ├── evolution_history.csv
│   ├── diversity_history.json
│   ├── convergence_metrics.json
│   ├── config.json               # Includes enhancement parameters
│   └── 1_min_unmet/
│       ├── allocation.csv
│       ├── coverage.csv
│       └── ...
└── analysis/
    ├── pareto_front.png
    ├── diversity_diagnostics.png
    └── evolution_plots.png
```

---

## Documentation References

- **Implementation Details**: `docs/refactors/nsga2_extended_implementation.md`
- **Quick Start Guide**: `docs/refactors/nsga2_extended_quickstart.md`
- **Main Documentation**: `CLAUDE.md` (updated)

---

**Status**: ✅ All files updated and ready for testing
