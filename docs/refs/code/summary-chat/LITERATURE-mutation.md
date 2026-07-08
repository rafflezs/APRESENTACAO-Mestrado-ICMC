<!-- docs/summary-chat/LITERATURE-mutation.md

In highly constrained scheduling problems, mutation operators in the literature are almost never “plain random bit flips.” They are usually constraint-aware neighborhood moves, often allowed to generate *temporarily* infeasible solutions but coupled with repair or strong selection pressure against infeasibility. Below are representative studies and the design patterns they use, with pseudocode-style sketches.[1][2][3]

***

## General design patterns in scheduling mutation

Across job-shop, project, nurse/physician, and parallel-machine scheduling, mutation operators follow a few recurring principles:

- Work on a **schedule-level neighborhood move** (swap, insertion, block move, reassignment) rather than gene-wise noise.[4][3]
- Either:
  - **Preserve feasibility by construction** (representation + constrained move), or  
  - **Allow infeasible offspring** but immediately **repair** or **penalize** them, using mutation mainly to escape local minima.[5][1]
- Often embed **local search logic** into mutation (“local-search mutation”), so mutation is a *directed* perturbation, not purely random.[6][3]

Below, “performative” mutation means: (i) non-trivial, structured moves; (ii) potentially constraint-breaking to escape local minima; (iii) backed by repair or local search.

***

## Example 1 – Resident physician scheduling with dynamic mutation  
**Wang (2007), “A Genetic Algorithm for Resident Physician Scheduling” (GECCO)**[2]

**Problem:** Resident physician scheduling with hard and soft constraints (coverage, legal limits, preference rules). Feasible region is sparse; some constraints may remain violated, but hard constraints must be met.

### Mutation design

- **Dynamic mutation operator**: The mutation probability for a physician’s assignments depends on how well that physician satisfies “personal scheduling constraints” (PSC).  
  - If PSC is satisfied → very low chance to mutate that physician’s schedule.  
  - If PSC is violated → higher chance to mutate to improve that part.  
- Representation is a roster matrix (physicians × days/shifts), so mutation acts at the level of shifts for specific physicians.

**Constraint treatment**

- Hard constraints (e.g., minimum on-duty physicians, no illegal patterns) are enforced in evaluation; mutation is allowed to create **infeasible** solutions, but infeasible ones get worse fitness (higher penalties). The GA does not strictly prevent infeasibility; instead, dynamic mutation focuses search where violations are more common.[2]

### Pseudocode sketch (dynamic mutation)

```pseudo
for each chromosome S in population:
    for each physician p:
        violation_rate = PSC_violations_of(p, S) / max_violations_p
        // RM = base mutation rate, r = restraint parameter in [0,1]
        pm_p = RM * (violation_rate^r)
        if rand() < pm_p:
            // mutate this physician's roster
            day1, day2 = random_days()
            swap(S[p, day1], S[p, day2])  // or reassign shift on a critical day
```

**Key idea:** Mutation is not uniformly random; it’s *biased toward problematic parts of the schedule* to break local minima where constraints are violated.[2]

***

## Example 2 – Nurse rostering memetic GA: mutation as local search  
**Burke et al., “A Memetic Approach to the Nurse Rostering Problem” (highly cited)**[7][8]

**Problem:** Highly constrained nurse rostering (complex contract rules, coverage, forbidden patterns). Feasible solutions are rare.

### Mutation design

- GA is embedded in a **memetic framework**; mutation is effectively a **local improvement step**:
  - Choose a nurse and a small time window.
  - Try small moves: change a shift, swap with another nurse, or reassign days-off.
  - Only accept the move if it **improves** fitness or at least does not break hard feasibility too badly.
- Many implementations *never apply pure random mutation*; instead they apply hill-climbing or steepest descent on each offspring as “mutation.”[9][7]

**Constraint treatment**

- Construction ensures most solutions are feasible; some moves may temporarily violate constraints but:
  - Either are *repaired* immediately, or  
  - Are rejected by local search if they worsen constraint violations.

### Pseudocode sketch (mutation-as-local-search)

```pseudo
function mutation_nurse_roster(schedule S):
    best = S
    // pick one nurse and a small neighborhood (e.g., a week)
    nurse = random_nurse()
    days = random_consecutive_days(window_length)

    for each candidate move in neighborhood_moves(nurse, days):
        S2 = apply_move(S, candidate_move)
        if violates_hard_constraints(S2):
            continue  // reject
        if fitness(S2) < fitness(best):
            best = S2

    return best
```

**Key idea:** Mutation is strongly **constraint-aware** and behaves like a neighborhood search around each individual; infeasible neighbors are simply not accepted.[7][9]

***

## Example 3 – Job shop scheduling: simple vs local-search mutation  
**Gonçalves et al., “A Modified GA with Local Search and Multi-Crossover for JSSP” (mXLSGA)**[6]
**Park et al. (2003), “A hybrid genetic algorithm for the job shop scheduling problem”**[3]

**Problem:** Classic job shop scheduling (minimize makespan), heavily constrained by precedence and machine capacity; representation via permutation/operation list + decoder.

### Mutation designs

1. **Simple mutation (feasibility-preserving by representation)**[4][6]
   - Chromosome is a sequence of operations where precedence is implicitly respected by decoding rules.  
   - Mutation = swap two *consecutive* jobs or operations, chosen at random.  
   - The decoder turns the sequence into a schedule that always respects precedence and machine constraints → offspring schedules are automatically feasible.

   ```pseudo
   function simple_mutation_JSSP(seq):
       i = random_index()
       swap(seq[i], seq[i+1])
       return seq
   ```

2. **Local-search mutation (directed)**[6]
   - Systematically scans multiple swaps and keeps the best improvement.  
   - If no swap yields better fitness, mutation does nothing (keeps parent).  
   - This mutation can explore a larger neighborhood and is explicitly used to escape local minima.

   ```pseudo
   function local_search_mutation_JSSP(seq):
       best_seq = seq
       best_f = makespan(decode(seq))

       for i in 0..n-2:
           for j in i+1..n-1:
               seq2 = swap_copy(seq, i, j)
               f2 = makespan(decode(seq2))
               if f2 < best_f:
                   best_f = f2
                   best_seq = seq2

       return best_seq
   ```

**Constraint treatment**

- Because the **decoder enforces feasibility**, mutation can be quite aggressive on the permutation; feasibility is always maintained by construction.[3]
- In mXLSGA, the authors still embed local search into mutation to drive improvements rather than relying on random noise.[6]

**Key idea:** In many scheduling papers, mutation is allowed to be structurally aggressive at the encoding level because feasibility is restored by a decoder; thus, “breaking” local minima does not need to violate hard constraints in the schedule space.

***

## Example 4 – Grouping GA for unrelated parallel-machine scheduling  
**Fernández-Villacañas et al. (2023), “An Experimental Study of Grouping Mutation Operators for the Unrelated Parallel-Machine Scheduling Problem”**[10]

**Problem:** Assign jobs to unrelated parallel machines, minimize makespan. Representation is grouping-based: each gene is a machine, holding a list of assigned jobs.

### Mutation designs

- Compare several group-level mutation operators; the best is **2-Items Reinsertion**:
  - Remove two jobs from their current groups/machines.
  - Reinsert them (possibly on same or different machines) based on heuristics (e.g., choose machine giving least increase in makespan).
- Mutations may temporarily worsen objective; feasibility is easy (jobs must be assigned somewhere, no hard impossibility like skills), so all mutated schedules remain feasible by construction.

### Pseudocode sketch (2-items reinsertion)

```pseudo
function mutation_2_items_reinsertion(solution S):
    // S is a set of machine groups, each with a job list
    job1, job2 = select_two_jobs_randomly(S)

    remove job1 from its machine
    remove job2 from its machine

    for job in [job1, job2]:
        best_m = None
        best_increase = +∞
        for machine m in machines:
            delta = eval_makespan_increase_if_assign(job, m, S)
            if delta < best_increase:
                best_increase = delta
                best_m = m
        assign job to best_m

    return S
```

**Constraint treatment**

- Capacity/processing constraints are handled by the schedule evaluation; since every job must belong to exactly one machine, this grouping representation guarantees basic feasibility.[10]
- Mutation is **problem-specific** (moving jobs between machines) and focused on exploring meaningful neighborhoods, not bit-level perturbations.

***

## Example 5 – Resource-constrained project scheduling: constraint-aware mutation  
**Hybrid GA + neighborhood search for RCPSP**[11]

**Problem:** Resource-Constrained Project Scheduling Problem (precedence + renewable resources).

### Mutation design

- Chromosome: activity sequence (priority list) decoded by a serial scheduler.  
- Mutation acts as a *two-phase neighborhood move*:
  1. Swap two activities if it does not violate precedence.  
  2. Relocate a random activity to another position where precedence constraints remain satisfied.

```pseudo
function mutation_RCPSP(seq):
    // Phase 1: swap two precedence-compatible activities
    (i, j) = select_two_indices()
    if precedence_ok_after_swap(seq, i, j):
        swap(seq[i], seq[j])

    // Phase 2: relocation
    k = random_index()
    new_pos = random_index()
    if precedence_ok_after_relocate(seq, k, new_pos):
        job = seq[k]
        remove seq[k]
        insert job at new_pos

    return seq
```

**Constraint treatment**

- **Precedence feasibility is enforced in the mutation itself** (moves are blocked if they would break precedence).[11]
- Resource feasibility is enforced at decoding; the serial scheduler inserts activities respecting resource limits.  
- Thus, mutation is designed to navigate local minima *within* the space of precedence-feasible sequences, without explicitly creating infeasible precedence patterns.

***

## Are mutation operators constraint-aware or deliberately infeasible?

From these and related works, the pattern is:

1. **For “hard” scheduling constraints (coverage, precedence, machine capacity, legal patterns):**  
   - Most performative operators are **constraint-aware**.  
   - Feasibility is typically guaranteed either:
     - by the **encoding + decoder** (job-shop, RCPSP, parallel machines); or[3][11]
     - by enforcing feasibility in the mutation’s preconditions (only allowed swaps/moves).[11]

2. **Infeasibility is usually handled via:**
   - **Penalty-based fitness** (e.g., resident physician GA: infeasible schedules allowed but strongly penalized; mutation biases toward high-violation regions to fix them), or[2]
   - **Repair operators** after mutation (nurse/physician rostering memetic algorithms).[9][7]
   - Very few serious scheduling papers rely on *blindly* generating infeasible mutants without repair or constraint-based bias; that’s considered wasteful.

3. **Breaking local minima:**
   - Achieved mostly through:
     - **Structured neighborhood moves** of larger radius (block moves, 2-opt/3-opt, reinsertion),[10][6]
     - **Local-search-style mutation** that scans many neighbors and picks the best.[3][6]
   - Not by random constraint-breaking noise; infeasible mutants are avoided or repaired because evaluating many infeasible schedules is expensive and uninformative in highly constrained, sparse spaces.

***

## How to adapt to Pymoo (for physician/nurse scheduling)

Given these patterns, a Pymoo mutation operator for physician scheduling should:

- Operate at **roster-level neighborhoods**: swap shifts between physicians, move a contiguous block of shifts, change one assignment within a day, etc.  
- Be **constraint-aware**:
  - For precedence-like or legal pattern constraints, *only propose moves that keep them satisfied*.  
  - For coverage or skills, either repair after mutation or allow temporary violation with strong penalties.  
- Optionally embed **local search logic** into mutation, following mXLSGA and nurse memetics.

### Sketch: constraint-aware swap mutation for physician roster

```python
from pymoo.core.mutation import Mutation
import numpy as np

class PhysicianSwapMutation(Mutation):
    def __init__(self, p_mut=0.1, problem=None):
        super().__init__()
        self.p_mut = p_mut
        self.problem = problem  # needs feasibility checks

    def _do(self, problem, X, **kwargs):
        # X: (n_individuals, n_vars) flattened roster
        Y = X.copy()
        n, d = Y.shape

        for i in range(n):
            if np.random.rand() < self.p_mut:
                S = Y[i].reshape(problem.n_physicians, problem.n_slots)

                # attempt a limited number of feasible swaps
                for _ in range(10):
                    p1, p2 = np.random.randint(problem.n_physicians, size=2)
                    t = np.random.randint(problem.n_slots)

                    S2 = S.copy()
                    S2[p1, t], S2[p2, t] = S2[p2, t], S2[p1, t]

                    if self.problem.is_feasible_partial(S2, p1, p2, t):
                        S = S2
                        break

                Y[i] = S.flatten()

        return Y
```

- `is_feasible_partial` can check hard constraints affected by the swap (coverage, max shifts, legal sequences) without re-evaluating the whole roster.  
- To implement a **local-search mutation**, you can scan a small set of candidate swaps and accept the one that best improves fitness, mirroring the job-shop and nurse memetic literature.[7][6]

***

### Takeaways

- Performative mutation in constrained scheduling is **not** about random infeasibility; it is about *structured, domain-aware neighborhood moves*.
- Most high-quality work:
  - Designs mutation to *respect hard constraints* via representation, decoder, or move filters.  
  - Uses penalties and/or repair when infeasibility is temporarily allowed, but not as the main exploration mechanism.  
  - Uses mutation as a **local search engine** when the search space is sparse and local minima are strong.  
- For physician scheduling in Pymoo, the most literature-aligned design is:
  - Constraint-aware swap/reassignment/2-opt style mutations on the roster,  
  - Possibly augmented with local search inside mutation,  
  - With penalties or repair for soft constraints and strict enforcement of hard ones.

[1](https://scispace.com/pdf/solving-job-shop-scheduling-problem-using-genetic-algorithm-2mg3k8yg3q.pdf)
[2](http://gpbib.pmacs.upenn.edu/gecco2007/docs/p2203.pdf)
[3](https://www.sciencedirect.com/science/article/abs/pii/S0360835203000779)
[4](https://mat.uab.cat/~Alseda/MasterOpt/p11-31.pdf)
[5](https://www.sciencedirect.com/science/article/abs/pii/S0952197621002165)
[6](https://pmc.ncbi.nlm.nih.gov/articles/PMC7571099/)
[7](https://lirias.kuleuven.be/retrieve/683773/)
[8](https://www.schedulingbenchmarks.org/papers/Scatter%20Search%20for%20the%20Nurse%20Rostering%20Problem.pdf)
[9](https://aircconline.com/ijaia/V6N4/6415ijaia04.pdf)
[10](https://www.mdpi.com/2297-8747/28/1/6)
[11](https://arxiv.org/html/2502.18330v1)
[12](https://ieeexplore.ieee.org/document/9099848/)
[13](https://ieeexplore.ieee.org/document/9160215/)
[14](https://academic.oup.com/jigpal/article/29/6/951/5904329)
[15](https://link.springer.com/10.1007/s10515-025-00501-z)
[16](http://aimsciences.org//article/doi/10.3934/jimo.2019122)
[17](https://journals.sagepub.com/doi/10.3233/JIFS-236981)
[18](https://www.mdpi.com/2073-8994/15/4/836)
[19](http://www.aimspress.com/article/doi/10.3934/mbe.2023774)
[20](https://ieeexplore.ieee.org/document/10917000/)
[21](http://arxiv.org/pdf/2306.05792.pdf)
[22](https://pmc.ncbi.nlm.nih.gov/articles/PMC11910396/)
[23](https://pmc.ncbi.nlm.nih.gov/articles/PMC11341312/)
[24](https://arxiv.org/pdf/2305.03955.pdf)
[25](https://nottingham-repository.worktribe.com/preview/1021137/04cor_indirect.pdf)
[26](https://jmcms.s3.amazonaws.com/wp-content/uploads/2024/07/07182834/jmcms-2408003-Behavior-Analysis-of-a-Repairable-SS-SR-DM.pdf)
[27](http://www.growingscience.com/ijiec/Vol6/IJIEC_2015_2.pdf)
[28](https://www.hindawi.com/journals/complexity/2020/2862186/)
[29](https://www.bhu.ac.in/Images/files/57.pdf)
[30](https://arxiv.org/html/2306.05792v2)
[31](https://pmc.ncbi.nlm.nih.gov/articles/PMC10011308/)
[32](https://paginas.fe.up.pt/~balobo/PdChain/Papers/MIC2011.pdf)
[33](https://www.imt.ro/romjist/Volum16/Number16_1/pdf/04-WPalma.pdf)
[34](https://arxiv.org/html/2508.20953v1)
[35](https://www.sciencedirect.com/science/article/pii/S0020025523007491)
[36](https://www.nature.com/articles/s41598-023-36056-w)
[37](https://conjure.readthedocs.io/en/latest/tutorials/NurseRostering.html)
[38](https://cad-journal.net/files/vol_21/CAD_21(S24)_2024_17-34.pdf)
[39](https://scispace.com/pdf/a-genetic-algorithm-for-resource-constrained-scheduling-34onuih1am.pdf)
[40](https://formative.jmir.org/2025/1/e67747)
[41](https://www.sciencedirect.com/science/article/pii/S1568494625006271)
[42](https://www.sciencedirect.com/science/article/pii/S0377042713006535)
[43](https://www.sciencedirect.com/science/article/pii/S0305054824002995)
[44](https://arxiv.org/pdf/1109.5920.pdf)
[45](https://arxiv.org/pdf/0910.2593.pdf)
[46](https://www.sciencedirect.com/science/article/pii/S0360835222007483)
[47](https://www.sciencedirect.com/science/article/abs/pii/S095741742302643X)
[48](https://arxiv.org/pdf/2508.20953.pdf)
[49](https://www.sciencedirect.com/science/article/pii/S2192440622000260)
[50](https://dl.acm.org/doi/10.5555/1782534.1782542)
[51](https://www.sciencedirect.com/science/article/abs/pii/S030505480900238X)
[52](https://arxiv.org/pdf/2207.13075.pdf)
[53](https://www.sciencedirect.com/science/article/pii/S2772662223002321)
[54](https://www.sciencedirect.com/science/article/abs/pii/S2210650221001061)
[55](https://www.sciencedirect.com/org/science/article/pii/S1546221822007093)
[56](https://www.sciencedirect.com/science/article/abs/pii/S1568494625008567)