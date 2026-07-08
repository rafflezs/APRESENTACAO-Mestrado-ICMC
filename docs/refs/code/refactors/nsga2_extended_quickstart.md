# NSGA-2 Extended - Quick Start Guide

## TL;DR

**What**: Enhanced NSGA-II with extreme initialization, two-stage evolution, and adaptive diversity
**Why**: Fix solution clustering, poor diversity, and large gap to Exact MIP
**How**: Use `NSGA2Extended` class with streamlined operators

---

## Minimal Example

```python
from engine.metaheuristics.nsga2.core.nsga2_extended import NSGA2Extended
from engine.metaheuristics.nsga2.operators.constraint_aware_sampling import ConstraintAwareSampling
from engine.metaheuristics.nsga2.operators.constraint_aware_crossover import DayBasedCrossover
from engine.metaheuristics.nsga2.operators.constraint_aware_mutation import SlotReassignmentMutation
from pymoo.optimize import minimize
from pymoo.termination import get_termination

# Problem setup (your existing code)
problem = PhysicianSchedulingProblem(instance_object)

# Operators (best strategies only)
sampling = ConstraintAwareSampling(use_extreme_strategies=True)
crossover = DayBasedCrossover()
mutation = SlotReassignmentMutation()

# Algorithm (all enhancements enabled)
algorithm = NSGA2Extended(
    pop_size=100,
    sampling=sampling,
    crossover=crossover,
    mutation=mutation
)

# Run
res = minimize(problem, algorithm, get_termination("time", "01:00:00"))
```

That's it! All enhancements are enabled by default.

---

## Operators Cheat Sheet

### Sampling
```python
# Standard (5 core strategies)
ConstraintAwareSampling()

# With extremes (5 core + 2 extreme)
ConstraintAwareSampling(use_extreme_strategies=True, extreme_ratio=0.2)
```

**Strategies**:n
- Core: demand_first, coverage_first, workload_balance, temporal_early, random_greedy
- Extreme: minimize_swaps, minimize_unmet

### Crossover
```python
# Only one strategy (proven best)
DayBasedCrossover(prob=0.9)
```

### Mutation
```python
# Only one strategy (proven best)
SlotReassignmentMutation(prob_mutation=0.3)
```

---

## NSGA2Extended Parameters

### All Defaults (Recommended)
```python
NSGA2Extended(
    pop_size=100,
    sampling=sampling,
    crossover=crossover,
    mutation=mutation
    # All enhancements enabled by default
)
```

### Custom Configuration
```python
NSGA2Extended(
    pop_size=100,
    sampling=sampling,
    crossover=crossover,
    mutation=mutation,

    # Option 3: Extreme initialization
    use_extreme_initialization=True,
    extreme_ratio=0.2,  # 20% extreme solutions

    # Option 4: Two-stage evolution
    use_two_stage=True,
    stage_transition=0.5,  # Transition at 50%

    # Option 2: Adaptive diversity
    use_adaptive_diversity=True,
    diversity_early=0.15,   # Target diversity 0-30%
    diversity_mid=0.10,     # Target diversity 30-70%
    diversity_late=0.05,    # Target diversity 70-100%

    # Monitoring
    verbose=True  # Print adaptation events
)
```

### Disable Enhancements (Baseline NSGA-2)
```python
NSGA2Extended(
    pop_size=100,
    sampling=sampling,
    crossover=crossover,
    mutation=mutation,
    use_extreme_initialization=False,
    use_two_stage=False,
    use_adaptive_diversity=False
)

# Or just use standard NSGA2
from pymoo.algorithms.moo.nsga2 import NSGA2
algorithm = NSGA2(pop_size=100, ...)
```

---

## Monitoring

### Add Callback
```python
from engine.metaheuristics.nsga2.core.nsga2_extended import NSGA2ExtendedMonitor

monitor = NSGA2ExtendedMonitor(log_interval=10, verbose=True)

res = minimize(
    problem,
    algorithm,
    termination,
    callback=monitor
)
```

### Output Example
```
Gen   10 | Stage: discovery   | Div: 0.1423 | F1:   590 (  612) | F2: 162 ( 168)
Gen   20 | Stage: discovery   | Div: 0.1389 | F1:   580 (  605) | F2: 158 ( 165)
...
Gen  100 | Stage: refinement  | Div: 0.0987 | F1:   565 (  590) | F2: 155 ( 162)
[NSGA2Extended] Gen 100: Diversity=0.0987, Target=0.1000 → maintain
...
Gen  180 | Stage: refinement  | Div: 0.0512 | F1:   550 (  575) | F2: 150 ( 158)
```

### Get Statistics
```python
stats = algorithm.get_enhancement_statistics()

print(f"Stage transitions: {stats['stage_transitions']}")
print(f"Diversity history: {stats['diversity_history']}")
print(f"Adaptations: {len(stats['diversity_adaptations'])}")
```

---

## YAML Configuration

### Baseline NSGA-2
```yaml
ALGORITHM: "nsga2"
POP_SIZE: 100
TERMINATION_METHOD: "time"
TERMINATION_VALUE: 3600

CROSSOVER_STRATEGY: "day_based"
CROSSOVER_PROB: 0.9
MUTATION_STRATEGY: "slot_reassignment"
MUTATION_PROB: 0.3
```

### NSGA-2 Extended (Full Features)
```yaml
ALGORITHM: "nsga2_extended"
POP_SIZE: 100
TERMINATION_METHOD: "time"
TERMINATION_VALUE: 3600

# Enhancements (all true by default)
USE_EXTREME_INITIALIZATION: true
EXTREME_RATIO: 0.2
USE_TWO_STAGE: true
STAGE_TRANSITION: 0.5
USE_ADAPTIVE_DIVERSITY: true
DIVERSITY_EARLY: 0.15
DIVERSITY_MID: 0.10
DIVERSITY_LATE: 0.05

# Operators
CROSSOVER_STRATEGY: "day_based"
CROSSOVER_PROB: 0.9
MUTATION_STRATEGY: "slot_reassignment"
MUTATION_PROB: 0.3

# Monitoring
VERBOSE: true
LOG_INTERVAL: 10
```

---

## Troubleshooting

### "Only 'day_based' strategy is supported"
✅ **Good** - You're using the streamlined operators correctly
❌ **If you see this with other strategies**: Update your code to use `'day_based'`

### "Only 'slot_reassignment' strategy is supported"
✅ **Good** - Correct strategy
❌ **If error**: Update to use `'slot_reassignment'` instead of other strategies

### Sampling doesn't support extreme strategies
Check that you're using the updated `ConstraintAwareSampling`:
```python
# Should have use_extreme parameter
sampling = ConstraintAwareSampling(use_extreme_strategies=True)
```

### Diversity not adapting
Ensure `use_adaptive_diversity=True` in NSGA2Extended initialization

### No stage transitions
Check that `use_two_stage=True` and evolution runs long enough (>50 generations)

---

## Comparison Template

### Running Both Versions
```python
# Baseline NSGA-2
from pymoo.algorithms.moo.nsga2 import NSGA2

algorithm_baseline = NSGA2(
    pop_size=100,
    sampling=ConstraintAwareSampling(),  # No extremes
    crossover=DayBasedCrossover(),
    mutation=SlotReassignmentMutation()
)

res_baseline = minimize(problem, algorithm_baseline, termination)

# NSGA-2 Extended
algorithm_extended = NSGA2Extended(
    pop_size=100,
    sampling=ConstraintAwareSampling(use_extreme_strategies=True),
    crossover=DayBasedCrossover(),
    mutation=SlotReassignmentMutation()
)

res_extended = minimize(problem, algorithm_extended, termination)

# Compare
print("Baseline Pareto size:", len(res_baseline.F))
print("Extended Pareto size:", len(res_extended.F))

print("Baseline F1 range:", res_baseline.F[:, 0].min(), "-", res_baseline.F[:, 0].max())
print("Extended F1 range:", res_extended.F[:, 0].min(), "-", res_extended.F[:, 0].max())

print("Baseline F2 range:", res_baseline.F[:, 1].min(), "-", res_baseline.F[:, 1].max())
print("Extended F2 range:", res_extended.F[:, 1].min(), "-", res_extended.F[:, 1].max())
```

---

## File Locations

**Core Files**:
- `engine/metaheuristics/nsga2/core/nsga2_extended.py` - Main class
- `engine/metaheuristics/nsga2/core/adaptive_diversity.py` - Option 2
- `engine/metaheuristics/nsga2/core/two_stage_evolution.py` - Option 4

**Operators** (streamlined):
- `engine/metaheuristics/nsga2/operators/constraint_aware_sampling.py` - 5+2 strategies
- `engine/metaheuristics/nsga2/operators/constraint_aware_crossover.py` - Day-based only
- `engine/metaheuristics/nsga2/operators/constraint_aware_mutation.py` - Slot reassignment only

**Documentation**:
- `docs/refactors/nsga2_extended_implementation.md` - Full details
- `CLAUDE.md` - Updated with new features

---

## Quick Tests

### Test 1: Operators Work
```python
sampling = ConstraintAwareSampling(use_extreme_strategies=True)
crossover = DayBasedCrossover()
mutation = SlotReassignmentMutation()
print("✅ Operators imported successfully")
```

### Test 2: NSGA2Extended Works
```python
algorithm = NSGA2Extended(
    pop_size=10,
    sampling=sampling,
    crossover=crossover,
    mutation=mutation
)
print("✅ NSGA2Extended created successfully")
```

### Test 3: Run Short Evolution
```python
res = minimize(problem, algorithm, get_termination("n_gen", 5))
print(f"✅ Evolution completed: {len(res.F)} solutions in Pareto front")
```

---

## Testing

### Run Unit Tests

All NSGA2Extended features have comprehensive test coverage:

```bash
# Run all NSGA2Extended tests
pytest engine/metaheuristics/nsga2/tests/test_nsga2_extended.py -v

# Run adaptive diversity tests
pytest engine/metaheuristics/nsga2/tests/test_adaptive_diversity.py -v

# Run two-stage evolution tests
pytest engine/metaheuristics/nsga2/tests/test_two_stage_evolution.py -v

# Run extreme sampling tests
pytest engine/metaheuristics/nsga2/tests/test_extreme_sampling.py -v

# Run all tests
pytest engine/metaheuristics/nsga2/tests/ -v

# Run only fast tests (skip slow integration tests)
pytest engine/metaheuristics/nsga2/tests/ -v -m "not slow"
```

### Test Coverage

**Test Files**:
- `test_nsga2_extended.py` - Algorithm initialization, integration, statistics (18 tests)
- `test_adaptive_diversity.py` - Diversity control, parameter adaptation (15 tests)
- `test_two_stage_evolution.py` - Stage detection, transitions, parameters (15 tests)
- `test_extreme_sampling.py` - Extreme strategies, Pareto coverage (12 tests)

**Total**: 60+ tests covering all NSGA2Extended features

---

## Local Execution

### Quick Test Run (10 generations)

```bash
# Test with small configuration
python pipelines/run_nsga2_pipeline.py \
  --instance_file data/input/instances/15_days/2022jan02_to_2022jan16 \
  --output_dir data/output/test_nsga2_extended_quick \
  --algorithm nsga2_extended \
  --pop_size 20 \
  --termination_method n_gen \
  --termination_value 10 \
  --verbose
```

**Expected Output**:
```
Creating NSGA-2 Extended algorithm (pop_size=20)...
  Enhancement: Extreme initialization (ratio=0.2)
  Enhancement: Two-stage evolution (transition=0.5)
  Enhancement: Adaptive diversity (early=0.15, mid=0.10, late=0.05)
  Sampling: ConstraintAwareSampling
    - use_extreme_strategies: True
    - extreme_ratio: 0.2

Gen    1 | Stage: discovery   | Div: 0.1234 | F1:   612 (  648) | F2: 168 ( 182)
Gen    2 | Stage: discovery   | Div: 0.1189 | F1:   598 (  635) | F2: 165 ( 178)
...
Gen   10 | Stage: discovery   | Div: 0.1056 | F1:   580 (  615) | F2: 160 ( 172)
```

### Using Local Runner Script

Run experiments using YAML configuration files with the local runner:

```bash
# Run single YAML file
bash bin/run-nsga2-local cluster/configs/jan_26_allin/parametrization/nsga2/nsga2_15days.yaml

# Run all YAMLs in a directory
bash bin/run-nsga2-local cluster/configs/jan_26_allin/parametrization/nsga2/
```

**What It Does**:
1. Reads YAML configuration
2. Runs each experiment sequentially
3. Saves results to specified output directories
4. Generates summary report

**YAML Structure**:
```yaml
experiments:
  - INSTANCE_FILE: data/input/instances/15_days/2022jan02_to_2022jan16
    OUTPUT_DIR: "data/output/run/15_days/2022jan02_to_2022jan16/nsga2_extended"

    ALGORITHM: "nsga2_extended"
    POP_SIZE: 100
    TERMINATION_METHOD: "time"
    TERMINATION_VALUE: 3600  # 1 hour

    # Operators
    CROSSOVER_STRATEGY: "day_based"
    MUTATION_STRATEGY: "slot_reassignment"

    # NSGA2Extended enhancements
    USE_EXTREME_INITIALIZATION: true
    USE_TWO_STAGE: true
    USE_ADAPTIVE_DIVERSITY: true

    VERBOSE: true
```

### Test Baseline vs Extended

Compare baseline NSGA-2 with NSGA2Extended:

```bash
# Baseline (no enhancements)
python pipelines/run_nsga2_pipeline.py \
  --instance_file data/input/instances/15_days/2022jan02_to_2022jan16 \
  --output_dir data/output/baseline_nsga2 \
  --algorithm nsga2 \
  --pop_size 50 \
  --termination_method n_gen \
  --termination_value 50

# Extended (all enhancements)
python pipelines/run_nsga2_pipeline.py \
  --instance_file data/input/instances/15_days/2022jan02_to_2022jan16 \
  --output_dir data/output/extended_nsga2 \
  --algorithm nsga2_extended \
  --pop_size 50 \
  --termination_method n_gen \
  --termination_value 50 \
  --verbose
```

**Compare Results**:
```python
import pandas as pd

# Load Pareto fronts
baseline_pf = pd.read_csv("data/output/baseline_nsga2/solution/solutions_summary.csv")
extended_pf = pd.read_csv("data/output/extended_nsga2/solution/solutions_summary.csv")

print(f"Baseline Pareto size: {len(baseline_pf)}")
print(f"Extended Pareto size: {len(extended_pf)}")

print(f"\nBaseline F1 range: {baseline_pf['f1'].min():.0f} - {baseline_pf['f1'].max():.0f}")
print(f"Extended F1 range: {extended_pf['f1'].min():.0f} - {extended_pf['f1'].max():.0f}")

print(f"\nBaseline F2 range: {baseline_pf['f2'].min():.0f} - {baseline_pf['f2'].max():.0f}")
print(f"Extended F2 range: {extended_pf['f2'].min():.0f} - {extended_pf['f2'].max():.0f}")
```

### Verify Output Files

After running, check the output directory structure:

```bash
tree data/output/extended_nsga2/

# Expected structure:
data/output/extended_nsga2/
├── solution/
│   ├── solutions_summary.csv      # Pareto front
│   ├── evolution_history.csv      # Generation-by-generation metrics
│   ├── diversity_history.json     # Diversity tracking
│   ├── convergence_metrics.json   # Hypervolume, spread
│   ├── config.json                # Algorithm configuration
│   ├── instance_info.json         # Instance + enhancement parameters
│   └── 1_min_unmet/               # Best solutions
│       ├── allocation.csv
│       ├── coverage.csv
│       └── ...
└── analysis/
    ├── pareto_front.png
    ├── diversity_diagnostics.png
    └── evolution_plots.png
```

### Check Enhancement Activity

Verify enhancements are working by checking logs:

```bash
# Check for enhancement activity in output
grep "Enhancement:" data/output/extended_nsga2/logs/*.log
grep "NSGA2Extended" data/output/extended_nsga2/logs/*.log
grep "Stage:" data/output/extended_nsga2/logs/*.log
```

**Expected Log Lines**:
```
Enhancement: Extreme initialization (ratio=0.2)
Enhancement: Two-stage evolution (transition=0.5)
Enhancement: Adaptive diversity (early=0.15, mid=0.10, late=0.05)
[NSGA2Extended] Gen 10: Diversity=0.1234, Target=0.1500 → maintain
[NSGA2Extended] Gen 50: Stage transition at gen 50: REFINEMENT
[NSGA2Extended] Gen 75: Diversity=0.0823, Target=0.0750 → increase_exploitation
```

---

**Ready to use!** Start with the minimal example, run tests to verify, then scale up to full experiments.
