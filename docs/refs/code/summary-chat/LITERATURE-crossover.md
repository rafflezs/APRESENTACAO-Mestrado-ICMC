<!-- docs/summary-chat/LITERATURE-crossover.md

For genetic algorithms tackling scheduling (and similar combinatorial optimization) problems, recent studies have placed strong emphasis on constraint-aware crossover operators—specifically, operators designed to maintain or enforce feasibility during recombination. There are also sophisticated extensions for diversity preservation during crossover. Here are relevant papers and implementation details found in the research:

### Papers and Studies on Constraint-Aware Crossover for Scheduling

#### 1. Adaptive Multiple Crossover for Workforce Scheduling ()[1]
- **Method:** Multiple crossovers are applied adaptively during the GA run for workforce scheduling and routing. Crossover selection considers feasibility (valid assignments, no double-booking, etc.) and may repair infeasible solutions post-crossover.
- **Implementation:** Offspring are checked for hard constraint violations. If needed, a repair operator is triggered (shuffling assignments, swapping tasks, etc.), until the solution is feasible.

#### 2. Multi-Parent Order Crossover for Course Timetabling ()[2]
- **Method:** Proposes a multi-parent order crossover specifically designed to minimize soft constraint violations. The operator selects segments from several parents using ordering heuristics compatible with timetabling constraints.
- **Repair/Enforcement:** Hard constraints (e.g., avoiding overlapping classes) are strictly enforced by the operator's construction; if a violation occurs, genes are swapped or reordered until feasibility is restored.

#### 3. Resource-Constrained Scheduling with Feasible Offspring ()[3][4]
- **Method:** Chromosomes represent feasible schedules, respecting precedence and resource constraints. Crossover is allowed between feasible parents only, and infeasible offspring are rejected or repaired.
- **Common Operators:** Precedence Preserving Crossover (PPX), Order Crossover (OX), and Partially Matched Crossover (PMX) are enhanced or modified to maintain precedence/resource constraints.

#### 4. Diversity-Preserving Exploitation of Crossover (DiPEC) [arxiv.org/pdf/2507.01524][5][6]
- **Novel Paradigm:** Traditional crossover reduces diversity by producing offspring closer (in Hamming distance) to parents. The DiPEC approach creates biased crossover offspring ("mutation masks") that only flip selected critical bits, prioritizing fitness improvement but explicitly limiting diversity loss.
- **Implementation:** For each crossover output, a subset of critical bits is randomly selected with a tunable probability. The offspring is accepted only if it is both fitter and maintains population diversity above a set threshold.

#### 5. Crossover Operators Comparison Papers ()[7][8][9]
- **Hands-on Findings:** Major studies compare PMX, OX, PPX, Cycle, and Uniform crossover in job-shop and other scheduling. Implementations often add a test for feasibility post-crossover, rejecting or repairing infeasible chromosomes.
- **Key Operators:**
  - **PMX (Partially Matched Crossover):** Used in permutation-based encodings (e.g., job-shop schedules) to maintain feasible assignments.
  - **PPX (Precedence Preservative):** Maintains order relations to enforce feasibility.
  - **Order Crossover:** Uses segments and orderings to produce offspring respecting problem constraints.

### How Are Constraint-Aware & Diversity-Preserving Crossover Operators Implemented?

#### **General Design Strategies:**
- Crossover functions are adapted so that:
  - Only feasible parent pairs are selected for reproduction, when possible.
  - Post-crossover, offspring are repaired: violated constraints are fixed by local swaps, segment replacements, or re-insertion of tasks at feasible positions.
  - Some studies use a "feasibility mask" to mark the viable gene pool for crossover—only permitted combinations are attempted.
  - Some resort to "feasibility preservation" by encoding solutions so all valid permutations are feasible by construction.

#### **Diversity Mechanisms:**
- Operators like DiPEC ([arxiv.org/pdf/2507.01524]) maintain diversity by introducing randomization into which genes are swapped and limiting the number of gene changes per recombination.
- Some GAs use explicit metrics (Hamming distance, entropy) as secondary criteria in selection, ensuring offspring populations are not too homogeneous.
- Multi-parent crossover and adaptive crossover rates are used to inject diversity when populations begin to converge prematurely.

#### **Constraint-Aware Examples in Scheduling:**
- **Timetabling:** Order-based crossover (select parent orderings that don't create overlaps), repair operator to swap conflicting periods.
- **Project Scheduling:** Chromosomes represent sequences; PPX or Order crossover maintain task precedences, and feasibility checks adjust invalid sequences.
- **Resource Constraints:** Before evaluation, the scheduler converts a chromosome to a feasible schedule using priority lists and, if needed, serial or parallel schedule generation schemes—restoring any lost feasibility from crossover.

### Notable Implementation References

- **Diversity-Preserving Crossover (DiPEC) Algorithm:** [arxiv.org/pdf/2507.01524]  
  - Algorithm 1 in the paper gives pseudocode for the (2+1)-DEGA, alternating between diversity enhancement and exploitation phases using biased crossover.
- **Precedence Preserving and Order Crossover:**[8][7]
  - Both provide details on how to construct feasible offspring from parent schedules.
- **Multi-parent Constraint-Aware Crossover:**[2]
  - Segment selection and gene reordering ensure hard constraints are always satisfied.


### 1. Adaptive Multiple Crossover Genetic Algorithm for Workforce Scheduling ()[1]
**Summary:**  
This study introduces multiple crossover operators applied adaptively for workforce scheduling and routing problems. It focuses on maintaining feasibility by applying repair operators after crossover, ensuring assignments are valid and no double-booking occurs.

**Pseudocode:**
```
For each generation:
    Select parent solutions P1 and P2 (both feasible)
    Choose a crossover operator adaptively (e.g., PMX, OX, etc.)
    Generate offspring O by applying chosen crossover to P1 and P2
    If O is infeasible:
        Apply repair operator to O
    Add feasible O to new population
```

***

### 2. Multi-Parent Order Crossover for Timetabling ()[2]
**Summary:**  
Proposes a multi-parent order crossover to minimize soft constraint violations in course timetabling. The operator builds offspring from segments of several parents, selecting non-conflicting assignments.

**Pseudocode:**
```
For each offspring to generate:
    Select multiple parent schedules
    For each time slot or assignment:
        Randomly select assignment from a parent (no conflict)
        If assignment causes a conflict:
            Swap/reorder genes to achieve feasibility
    Add completed offspring to population
```

***

### 3. Precedence Preserving Crossover (PPX) for Project Scheduling ()[3][4]
**Summary:**  
PPX ensures offspring adhere to precedence and resource constraints. Chromosomes are sequences of tasks; crossover maintains ordering and moves genes to feasible positions.

**Pseudocode:**
```
For parents P1 and P2 (task sequences):
    Initialize empty offspring sequence O
    While O not complete:
        Randomly select next task from P1 or P2
        If adding task preserves all precedence and resource constraints:
            Add task to O
        Else:
            Skip or try next permissible task
    Add feasible offspring O to population
```

***

### 4. Diversity-Preserving Exploitation of Crossover (DiPEC) ([arxiv.org/pdf/2507.01524])[5]
**Summary:**  
DiPEC introduces a diversity-aware crossover that only flips selected critical bits, prioritizing fitness improvement and maintaining population diversity.

**Pseudocode:**
```
For each generation:
    Select parents P1, P2
    For each gene:
        With probability p, carry gene from P1
        Else, carry gene from P2
    Apply mutation mask (limit changed genes to critical subset)
    If offspring higher fitness and diversity above threshold:
        Add to population
    Else:
        Discard or repair
```

***

### 5. Comparative Study of Crossover Operators ()[6]
**Summary:**  
This study compares PMX, OX, Cycle, and Uniform crossover on scheduling problems, emphasizing additional steps to enforce feasibility after crossover.

**Pseudocode for PMX:**
```
Select crossover points
Copy segment from P1 to O
Fill remaining positions from P2, ensuring validity
If assignment invalid:
    Swap or insert missing elements in correct order
Add feasible O to population
```

***

These approaches demonstrate both how constraint-aware crossovers are implemented and how they incorporate repair or diversity mechanisms to maintain feasible, varied populations. If you need full pseudocode from a specific paper, let me know which operator or scheduling problem to focus on.

[1](https://nottingham-repository.worktribe.com/preview/940277/dls_joh2018.pdf)
[2](http://www.journal.unipdu.ac.id:8080/index.php/register/article/download/1663/pdf)
[3](https://journals.umcs.pl/ai/article/download/3274/2468)
[4](https://www.sciencedirect.com/science/article/pii/S0020025523007491)
[5](https://arxiv.org/abs/2507.01524)
[6](https://wseas.com/journals/computers/2013/5705-156.pdf)

[1](https://nottingham-repository.worktribe.com/preview/940277/dls_joh2018.pdf)
[2](http://www.journal.unipdu.ac.id:8080/index.php/register/article/download/1663/pdf)
[3](https://journals.umcs.pl/ai/article/download/3274/2468)
[4](https://www.sciencedirect.com/science/article/pii/S0020025523007491)
[5](https://arxiv.org/abs/2507.01524)
[6](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5691595)
[7](https://pmc.ncbi.nlm.nih.gov/articles/PMC7599983/)
[8](https://wseas.com/journals/computers/2013/5705-156.pdf)
[9](https://arts.units.it/retrieve/e2913fdd-dce0-f688-e053-3705fe0a67e0/post%20print.pdf)
[10](http://thesai.org/Downloads/Volume4No2/Paper_31-GASolver-A_Solution_to_Resource_Constrained_Project_Scheduling_by_Genetic_Algorithm.pdf)
[11](http://article.sciencepublishinggroup.com/pdf/10.11648.j.sjbm.20160406.18.pdf)
[12](https://mfr.edp-open.org/articles/mfreview/pdf/2023/01/mfreview230009.pdf)
[13](https://downloads.hindawi.com/journals/sp/2006/271608.pdf)
[14](https://nottingham-repository.worktribe.com/preview/864238/dls_cec2017.pdf)
[15](https://arxiv.org/html/2509.06981v1)
[16](https://riomaisseguro.rio.rj.gov.br/fetch.php/virtual-library/SAZ6rt/FinalExamAndSolutionForGeneticAlgorithm.pdf)
[17](https://dl.acm.org/doi/10.1145/3583131.3590440)
[18](https://onlinelibrary.wiley.com/doi/10.1155/2022/6355192)
[19](https://sci2s.ugr.es/keel/pdf/keel/articulo/Ortiz-Boyer-Hervas-Garcia-vparents2007.pdf)
[20](https://orbit.dtu.dk/files/326110996/1_s2.0_S0020025523007491_main.pdf)
[21](https://stackoverflow.com/questions/26845823/genetic-algorithm-best-crossover-operator-for-a-weights-assignment)
[22](https://www.sciencedirect.com/science/article/pii/S156849461000013X)
[23](https://www.sciencedirect.com/science/article/abs/pii/S2210650225000070)
[24](https://arxiv.org/pdf/1109.2146.pdf)
[25](https://dl.acm.org/doi/10.1145/3638529.3654020)