# Response: Feasibility of NSGA-II Solutions — Empirical Analysis

**Context:** This document records findings from empirical investigation of constraint violations in NSGA-II solutions (run `allin_fev26_5`), addressing the advisor's claim that NSGA-II produces no feasible solutions and thus cannot be compared to exact/heuristic methods.

**Data source:** `data/output/allin_fev26_5/run/` — verification reports from 32 instances across 4 horizons (15, 30, 60, 90 days), both `nsga2_compact` and `nsga2_extended` variants.

**Investigation files used:**
- `*/nsga2_{compact,extended}/analysis/verification_report.csv`
- `*/nsga2_{compact,extended}/analysis/c5_violations.csv`
- `logs/allin_fev26_5/run/nsga2_compact/PaNIIRC{15,30,60,90}days.log`
- `*/exact_swaps/solution/*/results.json`

---

## 1. Full Feasibility (C1-C5): Advisor is Correct

No NSGA-II solution — compact or extended, across any horizon — satisfies all five constraints simultaneously. C5 (minimum coverage requirement) is violated in every Pareto front produced. This is empirically confirmed: `feasible = False` for all 448 verified solutions (225 compact + 223 extended).

**Consequence:** NSGA-II solutions cannot be described as feasible without qualification.

---

## 2. Structural Feasibility (C1-C4): Advisor Claim is Partially Incorrect

The advisor stated "the genetic algorithm produces no feasible solutions" without distinguishing constraint classes. Empirical data contradicts this for structural constraints:

| Variant | Total solutions | C1-C4 satisfied | C5-only violated | C4 also violated |
|---------|-----------------|-----------------|-----------------|------------------|
| nsga2_compact | 225 | 202 (89.8%) | 202 (89.8%) | 23 (10.2%) |
| nsga2_extended | 223 | 223 (100.0%) | 223 (100.0%) | 0 (0.0%) |

**nsga2_extended satisfies all structural constraints (C1-C4) without exception.** Only C5 is violated. This is the key distinction the advisor's critique misses.

### C4 violations in nsga2_compact

The 23 C4-violating solutions (room capacity) are **not distributed randomly**. They are concentrated in clinic **U06** across multiple instances and horizons, suggesting a systematic defect in the compact chromosome representation when handling this specific clinic's room constraints. Specifically:

- All C4 violations occur in `Tarde` (afternoon) shift
- Clinic U06 appears in violation records for 15-, 30-, 60-, and 90-day instances
- No other clinic shows C4 violations

These solutions have invalid Z1/Z2 values and cannot be used for comparison.

---

## 3. C5 Violation Magnitude

For solutions satisfying C1-C4, C5 violations (unattended active slots) grow with horizon:

| Horizon | Avg violation rate (slot %) | Avg uncovered slots per solution |
|---------|----------------------------|----------------------------------|
| 15 days | 3.8% | ~11 slots |
| 30 days | 4.2% | ~26 slots |
| 60 days | 4.6-4.8% | ~56 slots |
| 90 days | 5.7% | ~100 slots |

C5 violations are exclusively in `Tarde` (afternoon) shifts — the morning shift achieves full coverage in most solutions. This suggests the afternoon assignments are harder to fill, possibly due to physician availability constraints being tighter in that period.

---

## 4. Objective Value Accuracy

### Z1 (unmet exams) — critical for comparison validity

The verification procedure fixes NSGA-II assignment variables and uses Gurobi to compute the true Z1. Discrepancies indicate the NSGA-II objective evaluator underestimates unmet exams.

**nsga2_compact:**
- 181/202 C1-C4-valid solutions: reported Z1 = Gurobi-verified Z1 (zero diff)
- 21/202 solutions: reported Z1 < actual Z1 (mean diff = 22.3, max = 474)
- Affected solutions: predominantly `1_min_unmet` extreme points and `2_solution`
- At 60 days: one instance shows reported Z1 = 2046, actual Z1 = 2520 (474 undercount — 23% optimistic bias)

**nsga2_extended:**
- 0/223 solutions show any Z1 discrepancy. Reported Z1 = Gurobi-verified Z1 for all solutions across all horizons.

### Z2 (swaps) — reliable in both variants

Maximum observed |Z2 diff| = 10, mean < 0.4 across compact solutions. Extended: zero diff. Z2 values are trustworthy for both variants.

### Implication

Z1 bias in nsga2_compact means the compact Pareto front presents artificially good coverage at the `min_unmet` extreme. The front appears to cover more exams than the allocation actually guarantees. For nsga2_extended, reported Pareto fronts are exact — every point is Gurobi-verified.

---

## 5. The "Exact" Solver is Not Exact for Horizons >= 30 Days

The advisor's comparison concern also has an overlooked counterpart: the reference method (epsilon-constraint with Gurobi) does not produce provably optimal solutions for horizons beyond 15 days.

| Horizon | Runs hitting time limit | Avg MIP gap | Min gap | Max gap |
|---------|------------------------|-------------|---------|---------|
| 15 days | 33/55 (60%) | 4.8% | 0.0% | 34.9% |
| 30 days | 49/49 (100%) | 44.8% | 25.7% | 75.0% |
| 60 days | 56/56 (100%) | **78.9%** | 42.7% | 98.8% |
| 90 days | 55/55 (100%) | **97.1%** | 74.7% | 100.0% |

At 60 days, every exact run exhausts the time limit. The solver explores only 1 B&B node on average (confirmed in sample `results.json`: `NodeCount=1`). The best bound at termination is ~136, the incumbent ~1521 — a 91% optimality gap in the inspected instance. The returned "exact" solution is simply the best incumbent found, not a bound-certified solution.

At 90 days, the method is essentially non-functional: 97.1% average MIP gap means the solution quality guarantee is near-zero.

**This invalidates the comparison in both directions.** Even if NSGA-II were fully C5-feasible, comparing it to these 60-day and 90-day "exact" solutions would be meaningless — the reference itself is highly sub-optimal.

---

## 6. Why NSGA-IIc Appeared to Outperform Exact at 60 Days (HV = 1.039)

Two compounding causes, not one:

**Cause 1 — The reference is weak.** The exact solver at 60 days has 79% average MIP gap. NSGA-II genuinely outperforms an extremely poor MIP incumbent, not the true optimum. This is not NSGA-II being good; it is the MIP failing to search.

**Cause 2 — nsga2_compact has biased Z1.** The `1_min_unmet` extreme in the compact front reports lower unmet exams than the allocation actually produces (up to 23% undercount at 60 days). This inflates the Pareto front leftward, artificially improving hypervolume relative to the exact reference.

Both causes must be addressed before any HV comparison at these horizons is publishable.

---

## 7. Conclusions per Checklist Item (from DIGEST)

| Item | Finding |
|------|---------|
| Which constraints violated? | C5 always (all); C4 in 10.2% of nsga2_compact (U06 clinic only); 0% in nsga2_extended |
| C4 violations confirm infeasibility? | Only for nsga2_compact, only for U06 subset. nsga2_extended is C4-clean |
| Z1/Z2 valid for comparison? | nsga2_extended: fully valid, Gurobi-verified exact. nsga2_compact: biased Z1 in ~10% |
| HV computed from valid solutions? | If computed from nsga2_compact including C4 violators + biased Z1 → invalid. nsga2_extended solutions → valid for C1-C4-feasible comparison |
| Solutions with Z1=0? | None across any horizon |
| Why NSGAIIc HV > 1 at 60d? | Both: (1) exact reference is 79% from optimum; (2) nsga2_compact Z1 underreported at min_unmet extreme |
| Is the exact solver actually exact? | No. 30+d: always hits time limit. 60d: 79% avg gap. 90d: 97% avg gap |

---

## 8. Recommended Actions

### For dissertation text

1. **Remove or reframe HV comparisons at 60d and 90d.** The exact reference is not reliable at these horizons. Frame all method comparisons as "within equal time budget" (heuristic race), not "gap to optimality."

2. **nsga2_extended comparisons are defensible.** Solutions satisfy C1-C4 with Gurobi-verified Z1/Z2. State clearly: solutions are "structurally valid but coverage-incomplete (C5 violation, ~4-6% uncovered slots)."

3. **nsga2_compact comparisons require filtering:**
   - Drop C4-violating solutions (10.2%) — identified as U06 clinic issue
   - For remaining solutions, note Z1 bias at `1_min_unmet` extreme; use Gurobi-verified Z1 from `verification_report.csv` instead of reported values

4. **15-day comparisons are most valid** — exact method achieves near-optimality (4.8% avg gap), some instances reach proven optimal. Both NSGA-II variants are C4-valid at this horizon. This is the only horizon where "comparison to exact" is meaningful.

5. **Separate analysis sections** by horizon group:
   - 15 days: comparison valid (low gap exact reference, C4-clean NSGA-II)
   - 30 days: comparison is time-budget race (exact always hits TL, 45% gap avg)
   - 60-90 days: state limitations explicitly; present method quality metrics (coverage, swap count) without claiming optimality comparison

### For future work

- Fix C4 violation in nsga2_compact for clinic U06 (likely a room-counting bug in compact chromosome decoder)
- Repair operator for C5: assign minimum 1 physician to uncovered `Tarde` slots
- Revisit 60d/90d with longer time budget or warm-start from NSGA-II solutions for exact method
