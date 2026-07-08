# Branch Priority Configuration Guide

## Overview

Branch priorities control the order in which Gurobi explores variables during the branch-and-bound algorithm. Higher priority variables are branched on first, which can significantly impact solver performance.

## Default Priority Order

The default configuration follows the hierarchy: **W > X >> Z >> C**

```
w (daily assignment)     = 4  [HIGHEST PRIORITY]
x (allocation)           = 3
z (swap tracking)        = 2
c (unmet exams)          = 1  [LOWEST PRIORITY]
```

### Rationale

1. **W (Daily Assignment) - Priority 4**: These are high-level decisions that determine which clinic a physician works at on each day. Fixing these early provides strong structure to the solution.

2. **X (Allocation) - Priority 3**: Period-level allocations within each day. Once `w` is fixed, exploring `x` efficiently fills in the schedule details.

3. **Z (Swap Tracking) - Priority 2**: These are derived variables that track clinic changes. They depend on `w` decisions, so they're explored after the main assignment variables.

4. **C (Unmet Exams) - Priority 1**: These slack variables capture constraint violations. They're the least critical for branching since they adapt to the allocation decisions.

## Usage

### Command Line

When running epsilon-constraint optimization:

```bash
python pipelines/run_epsilon_pipeline.py \
    --instance_file data/input/instances/15_days/example \
    --output_dir data/output/test \
    --branch_priority_w 4 \
    --branch_priority_x 3 \
    --branch_priority_z 2 \
    --branch_priority_c 1
```

### YAML Configuration

Add to experiment configurations:

```yaml
experiments:
  - INSTANCE_FILE: "data/input/instances/15_days/2022jan02_to_2022jan16"
    OUTPUT_DIR: "data/output/epsilon_euler/15_days/2022jan02_to_2022jan16/swaps"
    NUM_EPSILONS: 5
    TIME_LIMIT: 3600
    PRIMARY_OBJECTIVE: "swaps"
    
    # Branch priorities (optional, defaults shown)
    BRANCH_PRIORITY_W: 4
    BRANCH_PRIORITY_X: 3
    BRANCH_PRIORITY_Z: 2
    BRANCH_PRIORITY_C: 1
```

### Python API

When creating a model programmatically:

```python
from engine.math_solver.math_model.model import GurobiModel

model = GurobiModel()
model.create_model(
    instance=instance,
    model_type="2",
    branch_priorities={
        "w": 4,  # Daily assignment
        "x": 3,  # Allocation
        "z": 2,  # Swap tracking
        "c": 1   # Unmet exams
    }
)
```

## Customization Scenarios

### Scenario 1: Minimize Swaps is Critical

If minimizing swaps is the top priority, you might want to emphasize swap tracking:

```python
branch_priorities = {
    "w": 4,
    "z": 3,  # Increased priority for swap tracking
    "x": 2,  # Decreased priority for allocation
    "c": 1
}
```

### Scenario 2: Fast Feasibility Search

To quickly find feasible solutions, deprioritize derived variables:

```python
branch_priorities = {
    "w": 5,  # Highest priority on main decisions
    "x": 4,
    "z": 1,  # Let swaps be determined by w
    "c": 1
}
```

### Scenario 3: Balanced Exploration

For a more balanced approach across all variables:

```python
branch_priorities = {
    "w": 3,
    "x": 3,
    "z": 2,
    "c": 2
}
```

## Performance Impact

Branch priorities can affect:
- **Solution time**: Proper priorities can reduce search time by 10-50%
- **Solution quality**: Early exploration of key variables can find better solutions faster
- **Node count**: Efficient branching reduces the number of nodes explored

## Recommendations

1. **Start with defaults**: The default priorities (4, 3, 2, 1) work well for most instances
2. **Monitor performance**: Track solve times and adjust if needed
3. **Test variations**: For critical instances, experiment with different configurations
4. **Document changes**: Keep notes on why custom priorities were chosen

## Technical Details

- Branch priorities are set via Gurobi's `BranchPriority` attribute
- Values are relative (absolute magnitudes don't matter, only the order)
- Variables with the same priority are branched using Gurobi's default heuristics
- Priorities are set after all variables and constraints are added to the model

## References

- [Gurobi BranchPriority Documentation](https://www.gurobi.com/documentation/current/refman/branchpriority.html)
- Model implementation: `engine/math_solver/math_model/model.py`
- Priority setter: `GurobiModel._set_branch_priorities()`
