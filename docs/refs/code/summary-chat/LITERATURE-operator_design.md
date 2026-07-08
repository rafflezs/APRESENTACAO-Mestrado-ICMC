<!-- docs/summary-chat/LITERATURE-operator_design.md

Researchers in scheduling—particularly for physician or medical staff scheduling—base, choose, and design their problem-specific genetic operators by closely analyzing both the **structure of the solution representation** and the **real-world constraints and objectives** unique to the application. The choice and design of operators in the literature reflect several best practices:

***

### 1. **Representation Drives Operator Design**

- **Encoding matches reality**: For physician scheduling, chromosomes often encode rosters as 2D tables (`days × doctors`), assignment vectors, or permutations of shifts. Operator design begins with whatever encoding guarantees feasible or nearly-feasible schedules.[1][2]
- **Operators must preserve feasibility or be easily repairable**: If feasible solutions are rare due to complex constraints (e.g. coverage, fairness, rest hours), operators are designed to build or maintain schedules that remain valid without too much repair. For physician schedules, that might mean crossover operates only on compatible segments, like trading a contiguous set of shifts or exchanging entire weeks.[2][1]

### 2. **Domain-Informed Crossover and Mutation**

- **Crossover mimics schedule swaps**: Operators are often inspired by roster management practices—e.g., swapping shifts, reassigning blocks of days, or exchanging rotations among similar physicians. Multi-point or day-block crossover is common, exchanging larger schedule blocks instead of individual days to better preserve essential real-world patterns.[1][2]
- **Mutation models minor real-world changes**: Mutation may randomly assign or swap a specific shift, mimic late roster changes, or adjust shift patterns to handle last-minute changes—all tactics that mirror how hospitals adjust rosters in practice.

### 3. **Constraint-Awareness and Repairs Are Built-In**

- **Hard constraints are always checked**: Because real schedules must always obey certain hard rules (no double-booking, coverage, qualifications), problem-specific crossovers are coded to never (or rarely) violate these—by only combining valid segments, or using a pre/post-repair step when infeasible offspring are produced.[3][1]

### 4. **Operator Selection Is Empirically Guided**

- **Researchers test and compare several custom operators**: Studies usually compare problem-specific operators (block/day-point, uniform, two-point, etc.) with generic operators. The operator providing the best *trade-off between feasibility and exploration* is empirically chosen using benchmarks or real hospital data.[2][1]
- **The literature emphasizes that operator efficacy is problem-dependent**: There’s no “one-size-fits-all” operator—even for physician scheduling, the best operator for a small clinic may differ from a large multi-site roster due to constraint density and preference structures.[1]

### 5. **Fairness, Preferences, and Robustness Influence Design**

- **Operators often incorporate fairness**: To prevent overloading a single physician or violating labor laws, some crossovers redistribute load between staff or use swap/mutation steps that favor less-assigned members.[3]
- **Preference sensitivity**: If preferences are critical (e.g., specific days off), mutation or crossover is sometimes biased/ranked based on satisfaction of these preferences, or uses acceptance-probabilities related to preference violation.

***

## **Key Example from the Literature**

**Patel et al. (2025), "A Multi-Objective Genetic Algorithm for Healthcare Workforce Scheduling"**[3][1]

- **Encoding**: 2D representation (staff × shifts)
- **Crossover**: Two-point slot crossover (selects two points in the schedule and swaps the middle section between parents), explicitly to respect how shifts are blocked together in real schedules.
- **Mutation**: Random re-assignment within a shift, swapping assignments between two staff.
- **Operator Rationale**: Chosen after comparison to uniform and day-block crossover, as two-point slot crossover best preserved shift-contiguity and led to high feasibility across generations.
- **Hard constraints enforced**: Only valid shifts assigned, skills respected.
- **Soft constraint penalties**: Applied for fairness and preference.
- **Repair step**: If after crossover any coverage or skill constraint is broken, the solution is locally repaired.

**Why This Works**: Operators are founded on staff management logic, empirical testing, and adapted to the specific legal and logistical context of physician assignments.

***

### **Summary Table**

| Principle            | Literature Example                         | Design Guideline                                                  |
|----------------------|--------------------------------------------|-------------------------------------------------------------------|
| Encoding-aligned     | 2D roster, permutation, block-swap [1]   | Operator must fit solution structure                              |
| Domain-inspired      | Day-block, two-point slot, swap [1][2] | Operators mimic hospital scheduling (swap shifts, exchange blocks)|
| Constraint-aware     | Built-in/repair steps [1][3][2]      | Never/rarely produce infeasible rosters                           |
| Empirically tested   | Operator comparison studies [1][2]     | Select best on real/benchmark data                                |
| Fairness/preference  | Load-balancing, satisfaction-bias [3]    | Mutation/crossover steered by fairness or doctor preferences      |

***

## **How to Adapt to Pymoo**

- **Subclass `Crossover` and `Mutation`** with domain-inspired, constraint-obeying logic.
- **Design `Sampling`** to start from greedy or repaired feasible rosters, not random assignment.
- **Test several operators** on your instance, measure feasibility rate and quality, and empirically select best-performing variant, just as literature recommends.

***

**In sum:** Schedulers in literature design their operators by integrating domain constraints, encoding logic, and fairness/preference considerations, then empirically validate the best for their problem instance. This ensures high feasibility, practical relevance, and improved convergence—even for highly constrained, sparse scheduling as in physician rostering.[2][1][3]

[1](https://arxiv.org/html/2508.20953v1)
[2](https://pmc.ncbi.nlm.nih.gov/articles/PMC9098273/)
[3](https://modem2025.vub.ac.be/papers/MODeM_2025_paper_16.pdf)