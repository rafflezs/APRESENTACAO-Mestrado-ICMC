# Compact NSGA-2 Local Test Analysis

**Date**: 2026-02-24
**Branch**: `nsga`
**Test execution**: `bash bin/run-nsga2-local cluster/configs/local-tests/nsga2-compact/ | tee logs/local-test/nsga2-compact-full.log`
**Instances**: 2022jan02_to_2022jan16 (15d), 2022jan02_to_2022jan31 (30d), 2022jan02_to_2022mar02 (60d), 2022jan02_to_2022apr01 (90d)
**Time limit**: 3600s (1 hour) per instance

---

## 1. Executive Summary

The Compact NSGA-2 pipeline ran successfully for all 4 horizons. The compact encoding (w[i,d] integer) enabled **94-930 generations** in 1 hour, compared to only **1-8 generations** for Extended NSGA-2 with the same time budget. However, a **critical bug** was identified in the objective function: `_count_unmet_fast()` counts physicians as binary (0/1) instead of using their exam capacity Q[i,d,t] (values 16 or 28). This causes the reported F1 (unmet exams) to be **5-9x higher** than the actual value computed by Gurobi verification. Despite the wrong objective landscape, the Compact method produced surprisingly competitive solutions in terms of Gurobi-verified objectives.

### Key Findings

| Aspect | Result |
|--------|--------|
| Pipeline stability | All 4 horizons completed successfully |
| Generations (1h) | 930 (15d), 460 (30d), 220 (60d), 130 (90d) |
| F1 computation bug | **CRITICAL** -- overestimates unmet exams by 5-9x |
| Gurobi-verified Z1 quality | Comparable or better than Extended on 60d/90d |
| F2 (swaps) quality | Significantly better range than Extended |
| C4 feasibility | Many solutions have room capacity violations |
| C5 violations | Similar rate to Extended (~10-14%) |
| Enhancement stats recording | Not working (empty arrays in JSON) |

---

## 2. Critical Bug: F1 Objective Computation

### Root Cause

In `engine/metaheuristics/nsga2/compact/problem.py`, the method `_count_unmet_fast()` computes:

```python
# Current (WRONG):
unmet += max(0, demand[u,d,t] - count_of_assigned_physicians)
```

The MIP model (`engine/mip/formulation/constraints.py`) computes:

```python
# Correct:
attendance = sum(Q[i,d,t] * x[i,u,d,t])  # Q = exam capacity (16 or 28)
unmet += max(0, demand[u,d,t] - attendance)
```

The demand values represent **exam counts** (mean=45, max=161), while physician availability Q represents **exam capacity** per physician per shift (values: {0, 16, 28}). The compact method treats each assigned physician as contributing 1 unit instead of their actual capacity.

### Impact

| Horizon | Compact Reported F1 | Gurobi Verified Z1 | Overestimation Factor |
|---------|---------------------|---------------------|----------------------|
| 15 days | 7,297-7,330 | 1,169-1,206 | ~6.1x |
| 30 days | 15,870-15,905 | 2,332 (only 1 feasible) | ~6.8x |
| 60 days | 37,115-37,253 | 4,038-5,199 | ~7.2-9.2x |
| 90 days | 59,717-60,002 | 6,857-9,375 | ~6.4-8.7x |

### Consequence

The optimization is NOT minimizing actual unmet exams. It is minimizing `demand - #physicians`, which is a **monotonically correlated but significantly distorted** proxy for the true objective. Fortunately, the ordinal ranking is partially preserved (more physicians assigned = lower unmet in both metrics), which explains why the Gurobi-verified quality is still reasonable.

**FIX REQUIRED**: Store `Q[i,d,t]` (exam capacities) in `CompactProblem` and use them in `_count_unmet_fast`:
```python
effective_capacity = (assigned_mask & (avail_t > 0)) * self.Q[:, :, t]
assigned_per_day = effective_capacity.sum(axis=0)  # sum of capacities, not counts
```

---

## 3. Convergence Analysis

### Generations per Horizon (1 hour)

| Horizon | Compact Gens | Extended Gens | Speedup |
|---------|-------------|---------------|---------|
| 15 days | 930 | 8 | **116x** |
| 30 days | 460 | 1 | **460x** |
| 60 days | 220 | 2 | **110x** |
| 90 days | 130 | 1 | **130x** |

The compact encoding (1,905 genes for 15d vs ~133,350 for extended) enables dramatically more generations. The Extended NSGA-2 essentially only performs initialization and 0-7 generations of evolution due to the massive chromosome size.

### Convergence Trajectory (15-day instance, 930 generations)

| Generation | F1 range (reported) | F2 range | Stage | NDS |
|-----------|--------------------|---------|-----------|----|
| 10 | 7303-7353 | 40-213 | Discovery | 16 |
| 50 | 7299-7350 | 37-219 | Discovery | 7 |
| 100 | 7298-7346 | 30-193 | Refinement | 9 |
| 300 | 7298-7347 | 30-179 | Refinement | 9 |
| 500 | 7297-7348 | 30-154 | Refinement | 10 |
| 750 | 7297-7330 | 30-74 | Refinement | 4 |
| 930 | 7297-7330 | 29-65 | Refinement | 7 |

F1 converges early (gen ~50), while F2 continues improving throughout (213 -> 65 swaps). The two-stage transition occurs at gen ~100 (50% of time-based budget). Most F2 improvement occurs during refinement stage.

### Convergence Trajectory (90-day instance, 130 generations)

| Generation | F1 range (reported) | F2 range | Stage | NDS |
|-----------|--------------------|---------|-----------|----|
| 10 | 59718-60190 | 327-1548 | Discovery | 30 |
| 50 | 59718-60144 | 258-1410 | Discovery | 50 |
| 100 | 59718-60181 | 220-1650 | Refinement | 59 |
| 130 | 59717-60021 | 216-1393 | Refinement | 61 |

Larger instances show richer Pareto fronts (61-77 non-dominated solutions vs 7-10 for 15d) but converge more slowly relative to the problem size.

---

## 4. Comparison: Compact vs Extended vs Exact

### 4.1 Gurobi-Verified Quality Comparison

Using Gurobi verification Z1 (after fixing w and optimizing x) for fair comparison.

#### 15-day Instance (2022jan02_to_2022jan16)

| Method | Best Z1 (unmet) | Best Z2 (swaps) | Z1 range | Z2 range | Solutions |
|--------|-----------------|-----------------|----------|----------|-----------|
| **Exact MIP** | **144** | **34** | 144-1,496 | 34-100 | 7 |
| Extended NSGA-2 | 824 | 98 | 824-1,021 | 98-195 | 7 |
| Compact (verified) | 1,169 | 63* | 1,169-1,206 | 63-92 | 2 feasible |

*Compact reported F2; verified F2 = 92 (Gurobi recalculates slightly more swaps).

**Gap to Exact (best Z1)**: Extended = 472% | Compact = 712%
**Gap to Exact (best Z2)**: Extended = 188% | Compact = 85% (BETTER than Extended)

#### 30-day Instance (2022jan02_to_2022jan31)

| Method | Best Z1 (unmet) | Best Z2 (swaps) | Z1 range | Z2 range | Solutions |
|--------|-----------------|-----------------|----------|----------|-----------|
| **Exact MIP** | **819** | **63** | 819-2,970 | 63-130 | 6 |
| Extended NSGA-2 | 1,945 | 248 | 1,945-2,215 | 248-359 | 7 |
| Compact (verified) | 2,332 | 281* | 2,332 (1 only) | 128-281 | 1 feasible |

*Only 1 of 5 compact solutions passed C1-C4 Gurobi verification.

**Gap to Exact (best Z1)**: Extended = 137% | Compact = 185%

#### 60-day Instance (2022jan02_to_2022mar02)

| Method | Best Z1 (unmet) | Best Z2 (swaps) | Z1 range | Z2 range | Solutions |
|--------|-----------------|-----------------|----------|----------|-----------|
| **Exact MIP** | **1,860** | **135** | 1,860-6,945 | 135-856 | 6 (gap: 62-85%) |
| Extended NSGA-2 | 4,717 | 583 | 4,717-4,982 | 583-598 | 3 |
| Compact (verified) | **4,038** | 891* | 4,038-5,199 | 576-891 | 5 feasible |

*F2 range for Gurobi-verified solutions.

Compact Gurobi-verified best Z1 (4,038) is **14% better** than Extended (4,717). Compact also has a much wider Z2 range (576-891 vs 583-598).

Note: Exact MIP achieves Z1=1,860 but with 84.5% MIP gap (highly uncertain).

#### 90-day Instance (2022jan02_to_2022apr01)

| Method | Best Z1 (unmet) | Best Z2 (swaps) | Z1 range | Z2 range | Solutions |
|--------|-----------------|-----------------|----------|----------|-----------|
| **Exact MIP** | **3,947** | **182** | 3,947-14,673 | 182-2,187 | 7 (gap: 73-96%) |
| Extended NSGA-2 | 8,621 | 892 | 8,621-9,117 | 892-1,441 | 5 |
| Compact (verified) | **6,857** | 1,391* | 6,857-9,375 | 513-1,391 | 6 feasible |

Compact best Gurobi Z1 (6,857) is **20% better** than Extended (8,621). Swap range is also wider (513-1,391 vs 892-1,441).

Note: Exact MIP achieves Z1=3,947 but with 95.7% MIP gap (essentially unreliable).

### 4.2 Summary: Gurobi-Verified Z1 Gap to Extended

| Horizon | Compact Z1 | Extended Z1 | Compact Advantage |
|---------|-----------|-------------|-------------------|
| 15 days | 1,169 | 824 | -42% (worse) |
| 30 days | 2,332 | 1,945 | -20% (worse) |
| 60 days | **4,038** | 4,717 | **+14% (better)** |
| 90 days | **6,857** | 8,621 | **+20% (better)** |

The Compact method becomes progressively more competitive on larger instances, surpassing Extended on 60+ day horizons despite having a wrong objective function. This is because Extended can barely evolve (1-2 generations) on large instances, while Compact achieves 130-220 generations.

### 4.3 Swap (F2) Comparison

| Horizon | Compact Best F2 | Extended Best F2 | Compact Advantage |
|---------|-----------------|------------------|-------------------|
| 15 days | 29 (reported) / 92 (verified) | 98 | Similar |
| 30 days | 62 (reported) | 248 | **75% better** |
| 60 days | 131 (reported) / 576 (verified) | 583 | Similar (verified) |
| 90 days | 216 (reported) / 513 (verified) | 892 | **42% better** |

F2 (swaps) is computed identically in both methods (gamma/state tracking). The Compact method consistently achieves better or comparable swap values.

---

## 5. Feasibility Analysis

### C1-C4 Feasibility (Gurobi Verification)

| Horizon | Total Solutions | C1-C4 Feasible | Infeasible | C4 Violations |
|---------|----------------|----------------|------------|---------------|
| 15 days | 7 | 2 (29%) | 5 (71%) | U06, U15 room capacity |
| 30 days | 5 | 1 (20%) | 4 (80%) | U06 room capacity |
| 60 days | 6 | 5 (83%) | 1 (17%) | U06 room capacity |
| 90 days | 7 | 6 (86%) | 1 (14%) | U06 room capacity |

**Clinic U06** is the most common C4 violator. The repair mechanism struggles with room capacity on this clinic specifically. On larger instances, the feasibility rate is actually higher, possibly because the relative impact of a single clinic violation is smaller.

For comparison, **Extended NSGA-2 has 100% C1-C4 feasibility** across all horizons. The Extended method's constraint repair (using the full x[i,u,d,t] encoding) is more precise.

### C5 Violations (Minimum Coverage)

| Horizon | Compact C5 Rate | Extended C5 Rate |
|---------|-----------------|------------------|
| 15 days | 6-23% | 9-12% |
| 30 days | 11-27% | 12-14% |
| 60 days | 9-12% | 10-12% |
| 90 days | 10-13% | 13-18% |

Both methods have similar C5 violation rates. Neither method fully enforces minimum coverage (G6). C5 violations mean an open clinic (demand > 0, rooms > 0) has zero physicians assigned -- this contributes directly to unmet demand.

---

## 6. Enhancement Features Analysis

### Feature Activation

Based on log analysis and enhancement_stats.json:

| Feature | Active in Log? | Recorded in Stats? |
|---------|---------------|-------------------|
| Extreme-biased init | Yes | Yes (flag only) |
| Stage transitions | Yes (gen 100 for 15d/30d/60d/90d) | **No** (empty array) |
| Diversity adaptation | Yes (logged every gen) | **No** (empty array) |
| Extreme injection | Yes (every 20 gens: 4 solutions) | **No** (empty array) |
| Local search | Yes (LS messages in log) | **No** (empty array) |
| Boundary archive | Appears active | **No** (0 count) |

**Bug**: Enhancement statistics are not being saved to `enhancement_stats.json`. The `get_enhancement_statistics()` method returns empty arrays despite features being active during evolution. This should be investigated.

### Diversity Evolution

| Horizon | Initial Div | Final Div | Trend |
|---------|-------------|-----------|-------|
| 15 days | 10.66 | 4.24 | Decreasing (convergence) |
| 30 days | 21.77 | 14.87 | Decreasing |
| 60 days | 47.35 | 45.32 | Stable |
| 90 days | 76.34 | 60.47 | Slow decrease |

Diversity decreases as expected during evolution. The adaptive diversity control constantly triggers `increase_exploitation` because the measured diversity (Hamming) exceeds the target (0.15). This suggests the diversity target thresholds need recalibration for the compact encoding scale.

---

## 7. Recommendations

### Priority 1: Fix F1 Objective Computation (CRITICAL)

Modify `CompactProblem._count_unmet_fast()` to use exam capacities instead of binary counts:
- Store `self.Q[i,d,t]` (raw exam capacity values from `get_all_availabilities()`)
- Replace `effective.sum(axis=0)` with `(effective * self.Q[:, :, t]).sum(axis=0)`
- This will align the internal F1 with Gurobi's Z1 computation

**Expected impact**: Fixing this will allow NSGA-2 to optimize the correct objective landscape. Current results show the method already finds good w[i,d] assignments despite the wrong F1; correct F1 computation should yield significant improvement, especially in the Pareto front coverage.

### Priority 2: Fix C4 Room Capacity Repair

The compact repair mechanism does not adequately handle room capacity constraints, particularly for Clinic U06. Options:
- Strengthen `repair()` to check and enforce room capacity limits per clinic per shift
- Add a dedicated C4 repair step after the current repair pipeline
- Penalize C4 violations in the constraint violation function

### Priority 3: Fix Enhancement Statistics Recording

The `get_enhancement_statistics()` method returns empty arrays. Either:
- The stats are being accumulated in the wrong data structure
- The `_advance()` method is not calling the recording functions
- The stats object is being re-initialized

### Priority 4: Recalibrate Diversity Targets

The adaptive diversity control always triggers `increase_exploitation` because the Hamming diversity metric (~4-76) is on a completely different scale than the target (0.15). For compact encoding:
- Normalize the Hamming diversity relative to chromosome length
- Or set targets appropriate for the compact encoding scale (e.g., 5-15% of num_genes)

### Priority 5: Investigate F2 Discrepancy

Some compact solutions show small Z2 differences between reported and Gurobi-verified values (e.g., 29 vs 49 for 15d solution 3). This suggests the swap counting logic (_count_swaps_fast) may have minor discrepancies with the MIP model's swap definition. Verify the gamma/state persistence logic matches exactly.

---

## 8. Conclusion

The Compact NSGA-2 demonstrates significant potential as a competitive metaheuristic for large-scale physician allocation:

**Strengths**:
- 100-460x more generations than Extended NSGA-2 in same time budget
- Better Gurobi-verified Z1 than Extended on 60+ day instances (+14-20%)
- Much wider Pareto front coverage (especially F2 range)
- 100% feasibility rate at the compact encoding level

**Weaknesses**:
- Critical F1 computation bug inflates reported unmet exams by 5-9x
- Lower C1-C4 feasibility rate on smaller instances (29-80% vs 100% for Extended)
- Enhancement statistics not recorded properly
- Diversity control miscalibrated for compact encoding scale

**After fixing the F1 bug**, the method is expected to improve substantially, as the optimization will be guided by the correct objective landscape. Combined with C4 repair improvements, the Compact NSGA-2 should become a highly competitive alternative to both Extended NSGA-2 and MIP-based methods, especially for large instances (60+ days) where MIP solvers struggle with high gaps (62-96%).
