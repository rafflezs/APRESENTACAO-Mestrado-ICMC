# NSGA-2 Extended Implementation Summary

**Date**: 2026-02-02
**Status**: ✅ Implemented
**Purpose**: Address solution clustering, poor diversity, and large gap to Exact MIP methods

---

## What Was Implemented

### 1. **Operator Refactoring** (Streamlined - Best Strategies Only)

#### Sampling (constraint_aware_sampling.py)
**Before**: 8 strategies (many weak)
**After**: 5 core + 2 extreme strategies

**Removed**:
- temporal_late
- swap_minimize (old version)
- room_efficient

**Kept (Core)**:
- demand_first
- coverage_first
- workload_balance
- temporal_early
- random_greedy

**Added (Extreme - Option 3)**:
- minimize_swaps: Targets min F2 (low swaps) - keeps physicians at same clinics
- minimize_unmet: Targets min F1 (low unmet) - maximizes coverage aggressively

**New Feature**: `use_extreme_strategies=True` enables extreme initialization

#### Crossover (constraint_aware_crossover.py)
**Before**: 3 strategies (day_based, physician_based, uniform)
**After**: **Only day_based** (proven best)

**Removed**:
- physician_based (room capacity coupling issues)
- uniform (high violation rate)

**Kept**:
- DayBasedCrossover: F1=590, F2=162, Score=0.838 (recommendations.txt)

#### Mutation (constraint_aware_mutation.py)
**Before**: 4 strategies + mixed
**After**: **Only slot_reassignment** (proven best)

**Removed**:
- physician_swap
- add_remove
- shift_swap
- mixed

**Kept**:
- SlotReassignmentMutation: Best performer per recommendations.txt

---

### 2. **Option 3: Extreme-Biased Initialization**

**File**: `engine/metaheuristics/nsga2/operators/constraint_aware_sampling.py`

**Problem Addressed**: Solutions cluster in middle range, don't explore lexicographic extremes like MIP epsilon-constraint

**Implementation**:
- New strategies: `minimize_swaps`, `minimize_unmet`
- 20% of population generated with extreme strategies (configurable)
- Seeds population at both ends of Pareto front
- Mimics MIP behavior (min swaps with high unmet, min unmet with high swaps)

**Usage**:
```python
sampling = ConstraintAwareSampling(
    use_extreme_strategies=True,
    extreme_ratio=0.2  # 20% extreme solutions
)
```

**Expected Impact**: Full Pareto range coverage (min swaps → min unmet)

---

### 3. **Option 4: Two-Stage Evolution Framework**

**File**: `engine/metaheuristics/nsga2/core/two_stage_evolution.py`

**Problem Addressed**: No differentiation between exploration and exploitation phases

**Implementation**:

**Stage 1: Discovery (0-50% of evolution)**
- High diversity maintenance (target=0.15)
- High crossover (0.9), moderate mutation (0.3)
- Focus: Find different feasible regions
- No local search (too expensive early)

**Stage 2: Refinement (50-100% of evolution)**
- Low diversity (target=0.05) - allow convergence
- Lower crossover (0.7), higher mutation (0.4) for fine-tuning
- Focus: Optimize within discovered regions
- Local search enabled (optional)

**Automatic Transition**: At progress=0.5, parameters switch automatically

**Expected Impact**: Better exploration early, intensive exploitation late

---

### 4. **Option 2: Adaptive Diversity Control**

**File**: `engine/metaheuristics/nsga2/core/adaptive_diversity.py`

**Problem Addressed**: Low genetic diversity (<0.05) throughout evolution

**Implementation**: Transient Diversity Principle (Smaldino et al. 2023)

**Diversity Tracking**:
- Hamming distance (genetic diversity)
- Phenotypic diversity (objective space spread)
- Pareto front coverage
- Composite metric (weighted combination)

**Adaptive Actions**:
- Diversity too low → increase mutation, decrease crossover
- Diversity too high → decrease mutation, increase crossover
- Target varies by stage:
  - Early (0-30%): 0.15
  - Middle (30-70%): 0.10
  - Late (70-100%): 0.05

**Expected Impact**: High diversity early for exploration, convergence late for exploitation

---

### 5. **NSGA2Extended: Integration Class**

**File**: `engine/metaheuristics/nsga2/core/nsga2_extended.py`

**Main Class**: Integrates all enhancements

**Key Features**:
- Still 100% NSGA-II core (same sorting, selection, crowding distance)
- Enhancements are initialization and parameter adaptation
- All enhancements can be toggled on/off

**Monitoring**:
- `NSGA2ExtendedMonitor` callback for real-time logging
- Tracks stage transitions, diversity adaptations
- Logs every N generations

**Usage**:
```python
from engine.metaheuristics.nsga2.core.nsga2_extended import NSGA2Extended

algorithm = NSGA2Extended(
    pop_size=100,
    sampling=sampling,
    crossover=crossover,
    mutation=mutation,
    use_extreme_initialization=True,  # Option 3
    use_two_stage=True,               # Option 4
    use_adaptive_diversity=True,      # Option 2
    verbose=True
)
```

---

## File Structure

```
engine/metaheuristics/nsga2/
├── core/
│   ├── nsga2_extended.py          # NEW: Main extended algorithm
│   ├── adaptive_diversity.py      # NEW: Option 2 - Diversity control
│   ├── two_stage_evolution.py     # NEW: Option 4 - Two-stage framework
│   ├── problem.py                 # Existing
│   └── constraint_manager.py      # Existing
├── operators/
│   ├── constraint_aware_sampling.py    # REFACTORED: 5 core + 2 extreme
│   ├── constraint_aware_crossover.py   # REFACTORED: Day-based only
│   └── constraint_aware_mutation.py    # REFACTORED: Slot reassignment only
```

---

## Configuration

### Baseline NSGA-2 (For Comparison)
```yaml
ALGORITHM: "nsga2"
POP_SIZE: 100
CROSSOVER_STRATEGY: "day_based"
CROSSOVER_PROB: 0.9
MUTATION_STRATEGY: "slot_reassignment"
MUTATION_PROB: 0.3
```

### NSGA-2 Extended (Full Enhancements)
```yaml
ALGORITHM: "nsga2_extended"
POP_SIZE: 100

# Enhancements
USE_EXTREME_INITIALIZATION: true   # Option 3
EXTREME_RATIO: 0.2
USE_TWO_STAGE: true                # Option 4
STAGE_TRANSITION: 0.5
USE_ADAPTIVE_DIVERSITY: true       # Option 2
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

## Expected Results

### Problem 1: Solution Clustering (Poor Pareto Range)
**Before**: Solutions clustered in middle (e.g., F1=600±50, F2=160±10)
**After**: Full range coverage (F1: 200-1200, F2: 80-320) - like MIP

### Problem 2: Low Genetic Diversity
**Before**: Hamming distance ~0.05 throughout
**After**: 0.15 early → 0.10 mid → 0.05 late (transient diversity)

### Problem 3: Large Gap to Exact
**Before**: 30-50% gap on large instances
**After**: 10-20% gap (literature-based expectation)

---

## Testing Plan

### Phase 1: Validate Components (Week 1)
1. Test extreme initialization alone
2. Test two-stage evolution alone
3. Test adaptive diversity alone
4. Verify each component works

### Phase 2: Integrated Testing (Week 2)
1. Run NSGA2Extended on 15-day instance
2. Compare to baseline NSGA2
3. Measure:
   - Pareto range coverage
   - Diversity over time
   - Gap to Exact method
4. Adjust parameters if needed

### Phase 3: Full Experiments (Week 3-4)
1. Run on all horizons (15, 30, 60, 90 days)
2. Compare to MIP methods (Exact, RF, FO)
3. Document improvements for dissertation

---

## Backward Compatibility

**Aliases Provided**:
- `ConstraintAwareCrossover` = `DayBasedCrossover`
- `ConstraintAwareMutation` = `SlotReassignmentMutation`

**Old Code Still Works**:
```python
# Old way (still works)
from constraint_aware_crossover import create_constraint_aware_crossover
crossover = create_constraint_aware_crossover('day_based')

# New way (recommended)
from constraint_aware_crossover import DayBasedCrossover
crossover = DayBasedCrossover()
```

---

## References

**Literature Foundation**:
- Smaldino et al. (2023): Transient diversity principle
- Wang et al. (2025): SparseEA-AGDS adaptive operators
- Geng et al. (2022): DP-NSGA-III dual-population
- Hussain et al. (2019): Adaptive selection pressure
- Burke et al. (2004): Memetic nurse rostering
- Patel et al. (2025): Healthcare scheduling

**Project References**:
- `data/aggregate/recommendations.txt`: Operator testing results
- `docs/summary-chat/LITERATURE-genetic_diversity.md`: Diversity literature
- `docs/summary-chat/LITERATURE-nsga2-alternatives.md`: NSGA-2 variants
- `docs/summary-chat/LITERATURE-nsga2_implementations.md`: Implementation details

---

## Next Steps

1. **Test locally** on small instance (15 days)
2. **Compare** NSGA2Extended vs baseline NSGA2
3. **Measure** Pareto range, diversity, gap to Exact
4. **Tune parameters** if needed
5. **Run full experiments** (15, 30, 60, 90 days)
6. **Document results** for dissertation

---

## Notes

- All enhancements maintain **100% NSGA-II core** (sorting, selection, crowding)
- Can cite as "Enhanced NSGA-II" or "NSGA-II with adaptive diversity and two-stage evolution"
- Literature precedent: Many NSGA-II variants (DP-NSGA-III, C-NSGA-II, etc.)
- **Still NSGA family** - valid for dissertation proposal

---

**Implementation Status**: ✅ Complete
**Testing Status**: ⏳ Pending
**Documentation Status**: ✅ Complete
