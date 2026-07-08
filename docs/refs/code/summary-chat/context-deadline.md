# Project Context: Physician Scheduling Multi-Objective Optimization
## Document for New Chat Session Continuation

**Date**: November 11, 2025  
**Deadline**: December 25, 2025 (45 days remaining)
**Goal**: Complete Master's dissertation with working NSGA-2 implementation for physician scheduling
**Test Information (Important)**:
    - We need at least 3 weeks to test and write up results. That's because we have to run the experiments for lot's of instances (around 50 instances in total).
    - So we have, at most, 30 days for implementation and experimentation.
    - We aim for 100~500 generations with population size 50~250.
    - We will test around 6 90-day instances, 9 60-day instances, and 15 30-day instances.
    - It is possible to parallelize runs across multiple cores/machines, although it is preferable to keep runs on same environment for consistency (can be parallelized).
    - We probably, due to time constraints, will run things on ICMC's cluster Euler.
    - Initial tests (to see if code works) will be done on desktop and server with smaller instances (7-day instances).
    - Once we lock-in our operators (ideally one-above-all setting for each operator) we can run production experiments on cluster. That means we wont' be needing to run 224 experiments again (since this 224 experiments were only for operator analysis caused by permutating each operator setting in order to study current operator implementation and impact).
---

## My Configuration Summary
**Desktop**:
- OS: Debian 12 (Bare metal)
- CPU: AMD Ryzen 7 5700X 8-Core Processor
- RAM: 32 GB
- GPU: AMD Radeon RX 6750 XT (although not used for this project)
**Server**:
- OS: Debian 13 headless/No-GUI (Virtual Machine on Proxmox)
- VM CPUs: 8 vCPUs (Intel Xeon E5-2750 v3)
- VM RAM: 16 GB
- Host: Intel Xeon E5-2750 v3, 64 GB RAM
**Cluster**:
- Euler Cluster at ICMC (University of São Paulo)
- Access via SSH
- Multiple nodes with varying CPU/RAM configurations
- Queue system for job scheduling (SLURM)

---

## Problem Overview

### The Core Problem
Multi-objective physician scheduling optimization with:
- **Decision variables**: 
    - Above 44,520 binary variables 
    - Minimum, smallest instance possible being January 2nd 2022 to January 7th 2022 
    - Calculated as (P physicians × U clinics × D days × T time slots)
    - T always equals 2, Physician ranges from 100 to 130 usually, and Clinics range from 30 to 36 usually
    - Yeah, the search space if varied but always huge.
- **Objectives**: 
    - F1 (minimize): Penalty for unmet demand (workload balance)
    - F2 (minimize): Physician dissatisfaction (clinic swaps, preference violations)
- **Constraints**: 6 hard constraints (G1-G6)
    - G1: Physician availability
    - G2: One clinic per day
    - G3: X-W consistency
    - G4: Valid clinics only
    - G5: Room capacity
    - G6: Minimum coverage
- **Search space**: ~10^600 total solutions (will vary based on instance size)
- **Feasible space**: ~10^6 feasible solutions (extremely sparse)

### The Critical Challenge
**NSGA-2 produces Pareto fronts 400% worse than Gurobi's epsilon-constraint method.**

Root cause identified through 224 experiments: **Diversity collapse** - population converges to tiny feasible region within 1-2 generations, preventing exploration of full Pareto front.

**Note:** This convergence and exploration-difficulty can probably be attributed to discontinnuous feasible space with extreme sparsity and the absence of feasible region, since the problem is binary and solutions are represented as unitary points, so hopping between them is challenging (minima local). Deterministic approaches for mechanisms (like Sampling) seems to create feasible solutions at first, but these points are probably in a "island", so even if our greedy sampling creates $n$ different solutions, the average diversity will still be kinda low.

We also end the run with very few non-dominated solutions (usually less 1), indicating poor exploration, although all solutions seems to be feasible.
---

## Current State (Before New Implementation)

### Experimental Results (224 configurations tested)

**With Repair Operator:**
- Average time: 1590s (slow)
- Starting diversity: 0.011 (critically low)
- Final diversity: 0.0004 (complete convergence)
- Diversity loss: 97%
- Success rate: 100%

**Without Repair Operator:**
- Average time: 540s (3x faster)
- Starting diversity: 0.38 (with multigreedy_balanced_50)
- Final diversity: 0.008 (still low, but 10x better)
- Diversity loss: 97% (still collapses, but from higher baseline)
- Success rate: 100% (with greedy sampling; fails with pymoo_random)

### Key Findings from 224 Experiments

1. **Operator Importance for Starting Diversity:**
   - Sampling: 78.1%
   - Repair: 21.9%
   - Crossover/Mutation: <0.1%

2. **Operator Importance for Final Diversity:**
   - Crossover: 32.0%
   - Mutation: 27.0%
   - Sampling: 22.1%
   - Repair: 18.9%

3. **Best Configuration (locked):**
   - Sampling: multigreedy_balanced_50 (greedy_ratio=0.5)
   - Crossover: physician_cx_feas
   - Mutation: shift_swap_mut
   - Repair: **None** (to be dropped)

3.1. **Operators Configuration Commentary:**
    - Greedy sampling was never test with 100% greedy (multigreedy_balanced_100). It could yield lower starting diversity but might avoid collapse cause all solutions would be feasible from the-get-go. We must investigate if it makes sense meddling some more with sampling strategies later.
    - Sampling, even with different strategies (and fallbacks and taboo lists) seems to not prevent starting collapse when greedy ratio is too high. Coulde be because the feasible space is discontinuous (and since it's a binary problem, we are looking for points and not regions).
    - Custom-made Mutation has no feasibility-ensurance yet. We might study if it makes sense to add lightweight feasibility checks to it (similar to crossover).
    - We might also change Custom-Made Crossover feasibility-ensurance to be probabilistic instead of deterministic (to preserve diversity more).
    - We might meddle with Selection strategies later if needed.
    - To reinforce, 100% greedy might be preferable if we can make it diverse enough (since all solutions would be feasible from start, maybe collapse is avoided).

4. **Critical Pattern:**
   - ALL 196 successful configurations showed diversity collapse
   - Collapse happens at generation 1-2 regardless of operators
   - Even starting at 0.38 diversity → collapses to <0.01 by gen 10

### More experimental results - Sampling Diversity Study

This particular study was promoted to understand sampling configurations and their impact on diversity of generated solutions.
It test both Old Greedy Sampling (single-strategy) and New Multi-Strategy Greedy Sampling (6 strategies with taboo list).

These were the parameters for Multi-Strategy Greedy Sampling settings, as well as sampling size:
```python
SAMPLE_SIZE=100
multi_opts = [
    ('balanced', 'relaxed_greedy', 0.5),
    ('balanced', 'relaxed_greedy', 1.0),
    ('balanced', 'random_greedy', 0.5),
    ('balanced', 'random_greedy', 1.0),
    ('balanced', 'constraint_aware', 0.5),
    ('balanced', 'constraint_aware', 1.0),
    ('sequential', 'relaxed_greedy', 0.5),
    ('sequential', 'relaxed_greedy', 1.0),
    ('sequential', 'random_greedy', 0.5),
    ('sequential', 'random_greedy', 1.0),
    ('sequential', 'constraint_aware', 0.5),
    ('sequential', 'constraint_aware', 1.0),
]
old_opts = [
    ('mixed', 0.5, None),
    ('mixed', 1.0, None),
    ('greedy', 0.5, None), # Mesma coisa que mixed 1.0, esse teste e mais pra conferir se funciona
    ('greedy', 1.0, None), # Mesma coisa que mixed 1.0, esse teste e mais pra conferir se funciona
    ('constraint_aware', None, True),
    ('constraint_aware', None, False),
]
```

**1. Feasibility Rates of each sampling configuration:**
```plaintext
Multi-Strategy Sampling - Strategy: balanced, Fallback: relaxed_greedy, Greedy Ratio: 0.5 -> Found 50 infeasible solutions!
Multi-Strategy Sampling - Strategy: balanced, Fallback: relaxed_greedy, Greedy Ratio: 1.0 -> All solutions feasible.
Multi-Strategy Sampling - Strategy: balanced, Fallback: random_greedy, Greedy Ratio: 0.5 -> Found 50 infeasible solutions!
Multi-Strategy Sampling - Strategy: balanced, Fallback: random_greedy, Greedy Ratio: 1.0 -> All solutions feasible.
Multi-Strategy Sampling - Strategy: balanced, Fallback: constraint_aware, Greedy Ratio: 0.5 -> Found 87 infeasible solutions!
Multi-Strategy Sampling - Strategy: balanced, Fallback: constraint_aware, Greedy Ratio: 1.0 -> Found 78 infeasible solutions!
Multi-Strategy Sampling - Strategy: sequential, Fallback: relaxed_greedy, Greedy Ratio: 0.5 -> Found 50 infeasible solutions!
Multi-Strategy Sampling - Strategy: sequential, Fallback: relaxed_greedy, Greedy Ratio: 1.0 -> All solutions feasible.
Multi-Strategy Sampling - Strategy: sequential, Fallback: random_greedy, Greedy Ratio: 0.5 -> Found 50 infeasible solutions!
Multi-Strategy Sampling - Strategy: sequential, Fallback: random_greedy, Greedy Ratio: 1.0 -> All solutions feasible.
Multi-Strategy Sampling - Strategy: sequential, Fallback: constraint_aware, Greedy Ratio: 0.5 -> Found 87 infeasible solutions!
Multi-Strategy Sampling - Strategy: sequential, Fallback: constraint_aware, Greedy Ratio: 1.0 -> Found 79 infeasible solutions!
Old Sampling - Mode: mixed, Greedy Ratio: 0.5, Respect G2: None -> Found 50 infeasible solutions!
Old Sampling - Mode: mixed, Greedy Ratio: 1.0, Respect G2: None -> All solutions feasible.
Old Sampling - Mode: greedy, Greedy Ratio: 0.5, Respect G2: None -> All solutions feasible.
Old Sampling - Mode: greedy, Greedy Ratio: 1.0, Respect G2: None -> All solutions feasible.
Old Sampling - Mode: constraint_aware, Greedy Ratio: None, Respect G2: True -> Found 100 infeasible solutions!
Old Sampling - Mode: constraint_aware, Greedy Ratio: None, Respect G2: False -> Found 100 infeasible solutions!
```

**2. Diversity Ratios of each sampling configuration:**
```plaintext
Multi-Strategy Sampling - Strategy: balanced, Fallback: relaxed_greedy, Greedy Ratio: 0.5 -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.38
Multi-Strategy Sampling - Strategy: balanced, Fallback: relaxed_greedy, Greedy Ratio: 1.0 -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.01
Multi-Strategy Sampling - Strategy: balanced, Fallback: random_greedy, Greedy Ratio: 0.5 -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.38
Multi-Strategy Sampling - Strategy: balanced, Fallback: random_greedy, Greedy Ratio: 1.0 -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.01
Multi-Strategy Sampling - Strategy: balanced, Fallback: constraint_aware, Greedy Ratio: 0.5 -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.38
Multi-Strategy Sampling - Strategy: balanced, Fallback: constraint_aware, Greedy Ratio: 1.0 -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.01
Multi-Strategy Sampling - Strategy: sequential, Fallback: relaxed_greedy, Greedy Ratio: 0.5 -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.38
Multi-Strategy Sampling - Strategy: sequential, Fallback: relaxed_greedy, Greedy Ratio: 1.0 -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.01
Multi-Strategy Sampling - Strategy: sequential, Fallback: random_greedy, Greedy Ratio: 0.5 -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.38
Multi-Strategy Sampling - Strategy: sequential, Fallback: random_greedy, Greedy Ratio: 1.0 -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.01
Multi-Strategy Sampling - Strategy: sequential, Fallback: constraint_aware, Greedy Ratio: 0.5 -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.38
Multi-Strategy Sampling - Strategy: sequential, Fallback: constraint_aware, Greedy Ratio: 1.0 -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.01
Old Sampling - Mode: mixed, Greedy Ratio: 0.5, Respect G2: None -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.01
Old Sampling - Mode: mixed, Greedy Ratio: 1.0, Respect G2: None -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.01
Old Sampling - Mode: greedy, Greedy Ratio: 0.5, Respect G2: None -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.01
Old Sampling - Mode: greedy, Greedy Ratio: 1.0, Respect G2: None -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.01
Old Sampling - Mode: constraint_aware, Greedy Ratio: None, Respect G2: True -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.01
Old Sampling - Mode: constraint_aware, Greedy Ratio: None, Respect G2: False -> Uniqueness Ratio: 1.00 | Mean Hamming Distance: 0.01
```

These tests confirm that:
- 100% greedy sampling always produces feasible solutions
- However, 100% greedy sampling leads to extremely low diversity (0.01 mean Hamming distance)
- 50% greedy sampling produces higher diversity (0.38 mean Hamming distance) but many infeasible solutions
- Constraint-Aware Greedy Sampling does not help with diversity or feasibility
---

## Decisions Made (Consensus from Analysis)

### PHASE 1: Immediate Actions (Days 1-5)

1. **Drop Repair Operator Entirely** 
   - Reason: 3x time penalty, 97% diversity destruction
   - Impact: 3x faster, 38x better starting diversity
   - Risk: Zero (100% success with greedy sampling)

2. **Move Feasibility to Crossover/Mutation** 
   - Implement lightweight feasibility-aware operators
   - Only check critical constraints (G1, G2, G4)
   - Use probabilistic resolution (preserve diversity), __NOT full deterministic repair__

3. **Lock Operator Configuration** 
   ```python
   NSGA2(
       sampling=MultiStrategyGreedySampling(greedy_ratio=0.5),
       crossover=FeasibilityAwarePhysicianCrossover(),
       mutation=FeasibilityAwareShiftSwapMutation(),
       repair=None,
       eliminate_duplicates=True
   )
   ```

4. **Implement Diverse Fully-Greedy Sampling** 
   - multigreedy_balanced_100: 100% greedy with 6 strategies (or a new operator)
   - Goal: Test if 100% greedy can avoid collapse

### PHASE 2: Diversity Maintenance (Days 6-20)

Test approaches to prevent collapse:
- **Approach A**: Diversity-enforced selection (reject low-diversity offspring)
- **Approach B**: Adaptive selection pressure (reduce pressure when diversity low)
- **Approach C**: Periodic diversity re-injection (add new solutions every N gens)
- **Approach D**: Island model / niching (parallel subpopulations)

Decision checkpoint at Day 10: If >15% improvement → continue; else pivot to negative-result thesis.

### PHASE 3-4: Production & Writing (Days 21-50)
- Production experiments with final configuration
- Write dissertation explaining findings
- Both success and negative results are valid contributions

---

## Current Code Structure

### Key Files (from project)
- `problem.py` - PhysicianSchedulingProblem class (Pymoo problem definition)
- `constraints.py` - All constraint classes (G1-G6)
- `constraint_manager.py` - Centralized constraint handling
- `constraint_based_repair.py` - OLD repair operator (to be removed)
- `multi_strat_greedy_sampling.py` - Multi-strategy sampling with 6 strategies (might be overwritten or modified)
- `scheduling_crossover.py` - Custom crossover operators (probably will be fully modified)
- `scheduling_mutation.py` - Custom mutation operators (probably will be fully modified)
- `nsga2_custom.py` - NSGA-2 configuration wrapper. The name might change. This file **does not exists** yet.

### Implementation Status
-  Problem encoding/decoding working
-  Constraints implemented and tested
-  Sampling operators implemented (6 strategies with taboo list)
-  Custom crossover/mutation implemented
-  224 experiments completed and analyzed
-  Repair to be removed
-  Feasibility-aware operators to be implemented
-  Diversity maintenance mechanisms to be tested

---

## Open Questions for New Implementation

### Question 1: Operator Strategy Innovation
**Should we design new crossover/mutation strategies beyond feasibility-awareness?**

Current operators:
- Crossover: day_cx, physician_cx, uniform_cx, pymoo_twopoint
- Mutation: shift_swap, add_remove, clinic_transfer, pymoo_bitflip

Considerations:
- all `pymoo_` operators are generic from Pymoo's library, not problem-specific
- Experiments show crossover has 32% impact on final diversity
- Mutation has 27% impact
- Current strategies may be too homogenizing
- Perhaps need diversity-preserving strategies?

**Ideas to explore:**
- Multi-parent crossover (3+ parents)?
- Adaptive mutation rate based on diversity?
- Directed mutation toward sparse regions?
- Crossover that explicitly maximizes distance from existing solutions?

### Question 2: Sampling Innovation
**Should we develop fundamentally new sampling strategies?**

Advisor's suggestion: "100% greedy with fully different solutions would be better"

Current situation:
- multigreedy_balanced_50: 50% greedy + 50% random → 0.38 starting diversity
- multigreedy_balanced_100: 100% greedy → 0.01 starting diversity
- Problem: Greedy strategies converge to same region despite using 6 different heuristics

**Core issue**: All 6 greedy strategies produce similar solutions (~0.01 diversity among themselves)

**Ideas to explore:**
- Constraint-weighted greedy (prioritize different constraints per solution)?
- Perturbation-based: Start from 1 greedy, perturb heavily to create variants?
- Multi-objective greedy: Generate solutions optimizing different objective combinations?
- Region-based sampling: Explicitly target different areas of feasible space?
- Archive-based: Maintain history, force new solutions to be distant from archive?

**Key question**: How to generate 100 feasible solutions that are truly diverse (>0.3 average Hamming distance)?

### Question 3: Taboo List Inside NSGA-2
**Should we implement population-level taboo list to prevent duplicate generation?**

Proposal: Modified NSGA-2 that tracks all generated solutions and rejects duplicates/near-duplicates during variation.

```python
class DiversityAwareNSGA2(NSGA2):
    def __init__(self, min_hamming_distance=0.05, **kwargs):
        super().__init__(**kwargs)
        self.solution_archive = set()  # Track all solutions
        self.min_distance = min_hamming_distance
    
    def _next(self):
        offspring = super()._next()
        
        # Filter out solutions too similar to archive
        filtered = []
        for sol in offspring:
            if self._is_sufficiently_different(sol):
                filtered.append(sol)
                self.solution_archive.add(tuple(sol.X))
        
        return filtered
```

**Pros:**
- Prevents wasting computation on near-duplicates
- Forces exploration of new regions
- Could maintain diversity throughout evolution

**Cons:**
- Computational overhead (O(n) check per offspring)
- May reject many offspring → slow convergence
- Risk of getting stuck (all nearby solutions rejected)
- Memory overhead (archive grows linearly with generations)

**Questions:**
- Is overhead acceptable? (~1-2ms per check × 100 offspring × 100 gens = ~20s total)
- What's appropriate minimum distance? (0.05? 0.10?)
- Should we use exact duplicates only, or distance-based?
- Should archive decay over time (forget old solutions)?

**Important quote from advisor:** "Don't try decorating your room if you haven't built the house yet. Detect and fix the core problem first instead of proposing band-aid solutions. Memetic could be good? Yes. But your priority should be making what you already have work."

---

## Technical Specifications

### Problem Encoding
```python
# Flat decision vector X (length = 244,860)
# Decodes to:
# - var_x[i,u,d,t]: Binary (physician i works at clinic u on day d in slot t)
# - var_w[i,u,d]: Binary (physician i works at clinic u on day d)
```

### Diversity Metric
```python
# Hamming distance (proportion of differing bits)
def hamming_distance(x1, x2):
    return np.sum(x1 != x2) / len(x1)

# Population diversity (average pairwise distance)
def population_diversity(population):
    distances = []
    for i in range(len(population)):
        for j in range(i+1, len(population)):
            distances.append(hamming_distance(pop[i].X, pop[j].X))
    return np.mean(distances)
```

Thresholds:
- Random baseline: 0.50 (maximum for binary)
- Critical threshold: 0.05 (below = severe convergence)
- Severe threshold: 0.01 (nearly complete convergence)
- Current greedy: 0.01 (critically low)
- Current best: 0.38 starting → 0.008 final

### Performance Metrics
- Time: Target <600s per run (currently ~540s without repair)
- Success: 100% feasibility required
- Quality: Pareto front coverage, hypervolume indicator
- Diversity: Track per generation, flag collapse

---

## Implementation Priority Queue

### Immediate (This Week)
1. **Remove repair operator** from NSGA2 configuration
2. **Implement FeasibilityAwarePhysicianCrossover**
   - Lightweight G1, G2, G4 checks
   - Probabilistic conflict resolution
3. **Implement FeasibilityAwareShiftSwapMutation**
   - Same lightweight checks
4. **Validation run** (10 gens on small instance)
5. **30 production runs** to confirm 3x speedup + better diversity

### Short-term (Week 2)
6. **Evaluate need for new operators**
   - Analysis: Can current operators support diversity if other mechanisms work?
   - Decision: Implement new operators OR focus on algorithmic diversity maintenance
7. **Test Approach A**: Diversity-enforced selection
8. **Test Approach B**: Adaptive selection pressure

### Medium-term (Week 3-4)
9. **Decide on sampling innovation**
   - If Phase 2 approaches fail: New sampling may not help (collapse is algorithmic)
   - If Phase 2 approaches work: New sampling could amplify gains
10. **Implement taboo list** (if needed based on Phase 2 results)
11. **Production experiments** with final configuration

---

## Key Constraints for Implementation

### Time Budget
- 50 days total
- Phase 1: 5 days max
- Phase 2: 15 days max (stop if not working by Day 10)
- Phase 3: 10 days (production runs)
- Phase 4: 20 days (dissertation writing)

### Computational Budget
- Each experiment: ~540-600s (9-10 minutes)
- 30 runs per config: ~4.5 hours
- Can parallelize 3 configs simultaneously
- Total capacity: ~50-60 configs testable in remaining time

### Risk Management
- **Low risk**: Drop repair, add feasibility-aware ops (proven to work)
- **Medium risk**: Diversity-enforced selection (simple, likely helps somewhat)
- **High risk**: Complex algorithmic modifications (may not finish in time)

**Strategy**: Start low-risk, escalate only if showing promise

---

## Expected Outcomes (Realistic)

### Best Case (30% probability)
- Diversity maintenance works well
- Achieve 50-70% of Gurobi quality
- Thesis: "Improved NSGA-2 for constrained scheduling"

### Likely Case (50% probability)
- Diversity maintenance helps modestly (15-25% improvement)
- Still significantly worse than Gurobi
- Thesis: "Operator optimization and limits of metaheuristics"

### Worst Case (20% probability)
- Diversity maintenance doesn't work
- No improvement over baseline
- Thesis: "Why NSGA-2 fails in ultra-constrained spaces" (still valid!)

**All three are acceptable Master's theses given rigorous experimental methodology.**

---

## Code Readiness

### Already Implemented (Ready to Use)
```python
# Sampling with taboo list and 6 strategies
MultiStrategyGreedySampling(
    greedy_ratio=0.5,
    strategy_distribution='balanced',
    fallback_mode='relaxed_greedy',
    allow_swaps=True,
    randomization_level=0.3,
    max_retries=20
)

# Strategies: demand_first, workload_balanced, swap_allowing,
#             random_priority, clinic_first, availability_first
```

### To Be Implemented (Phase 1)
```python
# Feasibility-aware crossover (code provided in previous session)
class FeasibilityAwarePhysicianCrossover(Crossover):
    def _ensure_basic_feasibility(self, var_x, var_w, instance):
        # Fix G4 (invalid clinics)
        # Fix G1 (availability)
        # Fix G2 (one clinic per day) - probabilistic
        pass

# Feasibility-aware mutation (code provided)
class FeasibilityAwareShiftSwapMutation(Mutation):
    def _ensure_basic_feasibility(self, var_x, var_w, instance):
        # Same as crossover
        pass
```

### To Be Designed (Phase 2, if needed)
```python
# Diversity-aware NSGA-2 variants
class DiversityEnforcedNSGA2(NSGA2):
    # Reject offspring if diversity drops below threshold
    pass

class AdaptiveNSGA2(NSGA2):
    # Adjust selection pressure based on diversity
    pass

class TabooNSGA2(NSGA2):
    # Maintain archive, reject duplicates/near-duplicates
    pass
```

---

## Dissertation Narrative (Current Plan)

### Chapter Structure
1. **Introduction**: Problem motivation, scheduling challenges
2. **Background**: NSGA-2, scheduling literature, metaheuristics
3. **Methodology**: Problem formulation, operators, experimental design
4. **Experimental Analysis** ⭐ (Strongest chapter)
   - 224 configuration systematic analysis
   - Operator sensitivity analysis
   - Data-driven operator selection
5. **Diversity Collapse Phenomenon** ⭐ (Key contribution)
   - Empirical demonstration across all configs
   - Theoretical analysis of why it happens
   - Implications for metaheuristics in sparse feasible spaces
6. **Diversity Maintenance Attempts** (Phase 2 results)
   - What we tried, what worked/didn't work
   - Lessons learned
7. **Results & Discussion**
   - Comparison with Gurobi
   - Explanation of quality gap
   - When to use metaheuristics vs exact methods
8. **Conclusions**: Contributions, future work

### The Honest Story
"Despite systematic operator optimization (224 configs, 3x speedup, 38x diversity improvement), we discovered fundamental incompatibility between NSGA-2's elitism and ultra-sparse feasible spaces (density <10^-594). This explains the 400% quality gap versus exact methods and suggests hybrid approaches are necessary for this problem class."

**This is defensible scholarship regardless of whether we beat Gurobi.**

---

## Questions for New Chat Session

### Priority Questions (Need Answers to Proceed)

1. **Operator Innovation Depth**
   - Should we invest time (3-5 days) creating novel crossover/mutation strategies?
   - Or focus on algorithmic diversity maintenance with existing operators?
   - Trade-off: More operators = more exploration, but less time for main objective

2. **Sampling Redesign**
   - How to generate 100% greedy solutions that are truly diverse?
   - Current 6 strategies all converge to ~0.01 diversity
   - Ideas: Constraint-weighted? Perturbation-based? Multi-objective?
   - Should we prioritize sampling innovation over algorithmic diversity maintenance?

3. **Taboo List Implementation**
   - Worth the overhead (~20s total over 100 gens)?
   - Risk of getting stuck (rejecting too many offspring)?
   - Parameters: minimum distance threshold, archive size limit?
   - Should taboo list be:
     - Exact duplicates only (fast, minimal filtering)
     - Distance-based (expensive, aggressive filtering)
     - Adaptive threshold (complex, potentially optimal)

4. **Resource Allocation**
   - If we must choose, which has highest ROI:
     - New operators (crossover/mutation innovation)
     - New sampling (diverse greedy population)
     - Algorithmic diversity maintenance (modified NSGA-2)
     - Taboo list (prevent duplicate generation)
   - Can only do 2-3 well in remaining time

### Secondary Questions (Nice to Have)

5. **Hybrid Approaches**
   - Should we consider NSGA-2 + Gurobi hybrid?
   - Use NSGA-2 for broad exploration, Gurobi for local refinement?
   - Computational feasibility in 50-day timeframe?

6. **Alternative Algorithms**
   - Worth trying MOEA/D, SPEA2, or SMS-EMOA instead of NSGA-2?
   - Or stick with NSGA-2 since we have 224 experiments' worth of understanding?

7. **Objective Function Tuning**
   - Could different penalty weights help diversity?
   - Experiments used standard weights - worth exploring?

---

## Critical Success Factors

1.  **Systematic experimentation** (already done - 224 configs)
2.  **Clear methodology** (operator analysis framework established)
3. ⏳ **Time management** (50 days - must stay on schedule)
4. ⏳ **Scope control** (don't chase every idea - focus on highest impact)
5. ⏳ **Honest reporting** (negative results are valid contributions)
6.  **Code implementation** (Phase 1 operators need to be built)
7.  **Diversity maintenance** (Phase 2 approaches need testing)
8.  **Dissertation writing** (final 20 days - cannot be rushed)

---

## Files to Have Available

### From Previous Session
- `phase1_implementation_guide.py` - Ready-to-use code for feasibility-aware operators
- `dissertation_roadmap_strategic_plan.md` - Complete 50-day plan
- `operator_analysis_report.md` - Comprehensive analysis of 224 experiments
- `strategic_findings_visualization.png` - Key findings charts
- `roadmap_quick_reference.txt` - Quick reference summary

### From Project
- All constraint implementations (G1-G6)
- Current sampling strategies (6 greedy variants)
- Problem encoding/decoding
- Experimental results (224 configs data)

### To Be Created
- FeasibilityAwarePhysicianCrossover
- FeasibilityAwareShiftSwapMutation  
- Modified NSGA-2 variants (Phase 2)
- New sampling strategies (if needed)
- Taboo list implementation (if needed)

---

## Immediate Next Actions (Once New Chat Starts)

1. Review open questions and decide:
   - Operator innovation: Yes/No? How much time?
   - Sampling redesign: Yes/No? Which approach?
   - Taboo list: Yes/No? Which variant?

2. Implement Phase 1 operators (copy from implementation guide)

3. Validation run (10 gens, small instance)

4. If validation passes → 30 production runs

5. Checkpoint: Did we achieve 3x speedup + 38x diversity? 
   - Yes → Phase 1 complete, proceed to Phase 2
   - No → Debug and fix

6. Design Phase 2 experiments based on decisions from step 1

7. Execute, evaluate, iterate

---

## Final Notes

### What We Know for Certain
- Repair operator must be removed (100% confidence)
- Feasibility must move to variation operators (high confidence)
- Diversity collapse is fundamental problem (100% confidence from 224 experiments)
- Gurobi gap is explainable by diversity loss (high confidence)

### What We're Uncertain About
- Can diversity maintenance work? (test in Phase 2)
- Are new operators worth time investment? (need to decide)
- Will new sampling help? (unclear - may be algorithmic issue)
- Is taboo list net positive? (overhead vs benefit trade-off)

### What We Accept
- We may not beat Gurobi (realistic expectation)
- Negative results are publishable (honest scholarship)
- 50 days is tight but doable (if focused)
- Perfect is the enemy of done (ship > perfect)

---

## Contact Points for Continuation

**When starting new chat, provide this context document along with:**
- Specific question or task for this session
- Which phase we're in (1, 2, 3, or 4)
- Any new experimental results since this document
- Decisions made on open questions

**Example new chat opening:**
"I'm continuing the physician scheduling NSGA-2 optimization project. [attach PROJECT_CONTEXT_FOR_NEW_CHAT.md]. We're starting Phase 1 implementation. I've decided to [decisions on operators/sampling/taboo]. Please help me implement the feasibility-aware crossover operator and review the code for correctness."

---

**Document Version**: 1.0  
**Last Updated**: November 11, 2025  
**Status**: Ready for implementation Phase 1  
**Time Remaining**: 50 days to dissertation submission