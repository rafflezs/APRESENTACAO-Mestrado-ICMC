<!-- docs/summary-chat/LITERATURE-relax-and-fix.md

Based on my comprehensive research, I now have sufficient information to provide a detailed academic response. Let me compile the findings.

## Relax-and-Fix Design for Physician Scheduling Problems

### Overview of Relax-and-Fix (RF) Methodology

**Relax-and-Fix** is a constructive heuristic for mixed-integer linear programming (MILP) problems that decomposes large-scale optimization problems into manageable subproblems through **planning horizon decomposition**. The method maintains integrality constraints (binary variables must take integer values) on a "decision window" while relaxing integrality constraints on the remaining horizon, then iteratively shifts this window forward.[1][2][3]

### Core Parametrization Framework

The **three-window decomposition structure** (foundational for physician scheduling applications) partitions the scheduling horizon $[1, T]$ into:

**1. Frozen Window** $[1, a_k - 1]$
- **Setup variables fixed** from previous iterations  
- **Production/assignment variables optionally frozen**
- Reduces computational burden by eliminating integrality constraints for already-decided periods[1]

**2. Decision Window** $[a_k, b_k]$ **(size σ_k - the primary parameter)**
- **Integrality constraints maintained** on binary variables  
- Full mixed-integer model solved via branch-and-bound
- For physician scheduling: **dimension choices are critical**
  - **By period** (days): σ_k = 3-4 days typical for short-term scheduling
  - **By week**: σ_k = 1-2 weeks for biweekly/monthly rosters
  - **By physician group/clinic**: Decompose across physician pools or departments simultaneously[2][4]

**3. Approximation Window** $[b_k + 1, c_k]$ **(size ρ_k)**
- **Integrality constraints relaxed** (continuous variables)
- Provides lower bound on capacity/resource requirements
- Critical in **Double-Fix-and-Relax (DFR)**: provides "default estimation" of demand anticipation for future periods[1]

***

### Key Parametrization Parameters

| Parameter | Role | Typical Values | Application to Physician Scheduling |
|-----------|------|----------------|---------------------------------------|
| **σ_k** | Decision window size | 3-4 periods | **By period**: 3-4 days; **By week**: 1-2 weeks; **By clinic**: 1 clinic block |
| **δ_k** | Overlap between consecutive decision windows | 1-2 periods | Enables re-optimization and production anticipation; essential for fairness of duty distribution |
| **ρ_k** | Approximation window size (DFR only) | 4-6 periods | Should be **larger than σ_k** to capture demand spikes (e.g., weekend patterns, clinic closures) |
| **Opt_k** | Branch-and-bound optimality gap per iteration | 1-5% | Tight gap (1%) for early steps; relaxed (5%) for later steps to save CPU time |
| **Time_k** | CPU time limit per iteration | 60-300 seconds | Adaptive: smaller windows = shorter time limits |

***

### Strategic Choices: WHERE, HOW, AND HOW MUCH to Apply the Integrality Window

#### **1. WHERE to Apply (Decomposition Dimension)**

For physician scheduling, the decision window can be strategically positioned:

**Option A: Temporal Decomposition (By Period)**
- **Frozen window**: Physicians' assignments from past week(s) fixed
- **Decision window**: Current or next 3-4 days (tight coupling with shift constraints)
- **Approximation window**: Future 5-7 days (loose forecast of demand)
- **Best for**: Emergency departments, short-shift staffing (8-12 hour shifts)
- **Constraint**: Difficult to enforce weekly patterns (e.g., consecutive night shifts, weekend fairness) when horizon is <7 days[5][2]

**Option B: Clinic/Department Decomposition (By Clinic)**
- **Approach**: Decompose the full physician roster by clinical units (e.g., ICU, ER, general medicine ward)
- **Decision window**: All physicians assigned to one clinic optimized simultaneously
- **Coupling constraints**: Cross-clinic requirements (e.g., shared on-call duties) relaxed in approximation window
- **Best for**: Multi-specialty hospitals with relatively independent clinic schedules[6]

**Option C: Physician Pool Decomposition**
- **Approach**: Partition physicians into groups (e.g., senior/junior, full-time/part-time) based on contractual or skill constraints
- **Decision window**: One physician group at a time
- **Best for**: Large departments (>20 physicians) with heterogeneous contracts and qualifications[7][8]

**Option D: Block/Pattern Decomposition**
- **Approach**: Fix "shift blocks" (e.g., specific night-shift sequences, weekend pairings) and optimize individual physician assignments to blocks
- **Best for**: Enforcing pattern-based constraints (e.g., consecutive night shifts, weekend continuity)[9]

#### **2. HOW to Apply (Decomposition Strategy)**

**Fix-and-Relax (FR) Strategy:**[1]
- Initialize: Solve with **approximation window only** (all binary variables relaxed)
- Step k: Fix decisions from step k-1, optimize decision window, relax step k+1 onward
- **Advantage**: Simpler, fewer parameters; works when future periods are unconstrained
- **Disadvantage**: May miss critical future constraints (e.g., physician availability patterns, rotating schedule requirements)[2]

**Double-Fix-and-Relax (DFR) Strategy:**[1]
- Step 0: Solve full horizon with **all integrality relaxed** to capture global interactions
- Step k ≥ 1: Keep end-of-horizon frozen (from Step 0), shift decision and approximation windows forward
- **Advantage**: Captures interactions between early and late periods; superior for problems with long-range dependencies
- **Disadvantage**: More parameters (ρ_k); additional Step 0 computational cost
- **Physician scheduling advantage**: Captures cyclical patterns (e.g., ensuring fair weekend distribution over entire month even in early-week decisions)[1]

#### **3. HOW MUCH to Apply (Window Size Configuration)**

**Decision Window Size σ_k:**
- **Small (σ_k = 2-3 days)**: 
  - Pros: Faster subproblem solving; tight control over daily staffing levels
  - Cons: Cannot enforce weekly patterns; potential infeasibility at window boundaries
  - Use for: Daily contingency scheduling, shift swaps

- **Medium (σ_k = 7 days = 1 week)**:
  - Pros: **Aligns with weekly scheduling cycles** in most hospitals; permits consecutive-day and weekend constraints
  - Cons: Moderate subproblem size
  - Use for: Standard biweekly/monthly rosters with weekly fairness requirements

- **Large (σ_k = 14-21 days)**:
  - Pros: Captures multi-week fairness rules (e.g., "physician works at most 2 night-shifts per month")
  - Cons: Slower solving; larger branch-and-bound tree
  - Use for: Monthly/quarterly rosters; strategic scheduling to enforce long-term constraints

**Overlap Parameter δ_k:**
- **δ_k = 0**: No overlap (non-overlapping subproblems)
  - Pros: Minimal re-computation
  - Cons: Decisions made in window k cannot be reconsidered; poor solution quality
  
- **δ_k = 0.25 to 0.5 × σ_k**: Moderate overlap (25-50%)
  - Pros: Balances re-optimization cost with solution quality
  - Cons: Requires careful tuning
  - Typical: **δ_k = 1 day when σ_k = 3-4 days**[4]

- **δ_k ≥ 0.5 × σ_k**: Large overlap (50%+ of decision window rechecked)
  - Pros: Better anticipation of future periods; improved fairness
  - Cons: Higher CPU time (approaching full re-optimization)
  - Example from literature: With σ_k = 3, using δ_k = 1 reduced demand shortages vs. δ_k = 0[1]

**Approximation Window Size ρ_k:**
- **Guideline**: ρ_k ≥ 1.5 × σ_k or ρ_k = (longest recurring scheduling pattern)
  - For physician scheduling: If the longest imposed pattern is "no more than 2 consecutive weekend nights in 4 weeks," then ρ_k ≥ 28 days
  
- **Empirical evidence**: DFR with ρ_k = 4 and σ_k = 3 outperformed FR on lot-sizing instances; smaller approximation windows missed constraint interactions[1]

***

### Practical Application to Physician Scheduling: Recommended Configurations

**Scenario 1: Emergency Department Daily Scheduling (1-2 week horizon, 20 physicians)**
- **Decision window**: σ_k = 3 days (covers typical rest-period patterns: 2 on, 2 off)
- **Overlap**: δ_k = 1 day
- **Approximation window**: ρ_k = 5 days (captures patient volume peaks, weekend staffing)
- **Decomposition**: By period
- **Rationale**: Short horizon permits tighter control; daily decisions can be re-optimized with minimal overlap[10]

**Scenario 2: General Medicine Ward Monthly Roster (30 physicians, complex fairness rules)**
- **Decision window**: σ_k = 7-10 days (one week + overlap buffer to capture weekly cycles)
- **Overlap**: δ_k = 2-3 days
- **Approximation window**: ρ_k = 10-14 days (ensures 2-week fairness patterns are considered)
- **Decomposition**: By physician pool (senior/junior/part-time) **OR by clinic/ward** if departments are independent
- **Rationale**: Weekly boundaries align with typical rostering practices; larger window size needed for monthly fairness constraints[8]

**Scenario 3: Multi-Specialty Hospital (Integrated scheduling across 5 departments, 100+ physicians)**
- **Primary decomposition**: By department/clinic
- **Within each clinic, secondary decomposition**: By period or physician pool
- **Decision window**: σ_k = 7-14 days (department-level conflicts often span 1-2 weeks)
- **Overlap**: δ_k = 2 days
- **Approximation window**: ρ_k = 14-21 days
- **Use DFR, not FR**: Initial full-horizon relaxation (Step 0) captures cross-department constraints (e.g., shared surgical teams)[6]

***

### Evidence from Literature on Parameter Tuning

Research on lot-sizing (most analogous to physician scheduling) demonstrates:

1. **No universally optimal σ_k**: The best decision window size is **problem-dependent** and correlates with constraint structure. For physician scheduling: if longest "hard" pattern is 7 days, σ_k should be ≥ 7.[11][1]

2. **Overlapping periods improve solution quality significantly**: With σ_k = 3, shifting from δ_k = 0 to δ_k = 1 reduced demand shortages from 300 units to 0 in a small test case.[1]

3. **DFR superiority**: DFR achieved nearly identical optimality gaps (5%) to monolithic branch-and-cut while running **2.5-4× faster** on real-world instances.[1]

4. **Approximation window criticality**: In problems with capacity constraints, undersizing ρ_k led to infeasible subproblems; ρ_k ≥ σ_k + 3-4 periods was necessary.[5][1]

5. **Stopping criteria sensitivity**: Tight optimality gaps (Opt_k = 1%) in early iterations but loose gaps (Opt_k = 5%) in later iterations balanced solution quality and CPU time.[4][2]

***

### Summary: Decision Framework

| Dimension | Small Problem (≤15 physicians) | Medium (15-50 physicians) | Large (>50 physicians) |
|-----------|---------|----------|---------|
| **Decomposition Method** | FR by period | DFR by period then by physician pool | DFR by clinic, then by period |
| **σ_k (days)** | 3-4 | 7-14 | 7-21 |
| **δ_k (days)** | 1 | 2-3 | 2-4 |
| **ρ_k (days)** | 5-7 | 10-14 | 14-28 |
| **Parallelization** | Single thread | Parallel over physician pools | Parallel over clinics + pools |

The **integrality window should expand with**: (1) complexity of fairness constraints, (2) number of physicians, (3) length of recurring scheduling patterns. **Overlap (δ_k > 0) is essential** for re-optimizing across window boundaries, especially in fairness-critical healthcare applications.

[1](https://optimization-online.org/wp-content/uploads/2005/11/1244.pdf)
[2](https://repub.eur.nl/pub/117494/Relax_and_Fix-1-.pdf)
[3](https://dynresmanagement.com/wp-content/uploads/3/5/2/7/35274584/matheuristics_lotsizing_and_scheduling.pdf)
[4](http://ieomsociety.org/ieom2014/pdfs/497.pdf)
[5](https://arxiv.org/pdf/2208.03100.pdf)
[6](https://arxiv.org/pdf/2509.24806.pdf)
[7](https://arxiv.org/pdf/2407.06215.pdf)
[8](https://arxiv.org/html/2511.14536v1)
[9](https://people.cs.nott.ac.uk/pszrq/files/MISTA05.pdf)
[10](https://zhanksun.github.io/files/Physician_Rostering_POM.pdf)
[11](https://ieeexplore.ieee.org/document/9042504/)
[12](https://onlinelibrary.wiley.com/doi/pdfdirect/10.1002/lrh2.10393)
[13](https://pmc.ncbi.nlm.nih.gov/articles/PMC10582215/)
[14](https://ir.cwi.nl/pub/30780/30780.pdf)
[15](https://pmc.ncbi.nlm.nih.gov/articles/PMC6373312/)
[16](https://downloads.hindawi.com/journals/jhe/2022/1938719.pdf)
[17](http://www.jiem.org/index.php/jiem/article/download/1058/613)
[18](https://pmc.ncbi.nlm.nih.gov/articles/PMC4817334/)
[19](http://downloads.hindawi.com/journals/jhe/2017/9034737.pdf)
[20](https://www.nature.com/articles/s41598-021-98851-7)
[21](https://pmc.ncbi.nlm.nih.gov/articles/PMC10230508/)
[22](https://www.sciencedirect.com/science/article/pii/S1053811920305978)
[23](https://www.sciencedirect.com/science/article/abs/pii/S0305048317309726)
[24](https://www.ime.usp.br/~egbirgin/publications/abkm2020.pdf)
[25](https://jamanetwork.com/journals/jamanetworkopen/fullarticle/2812258)
[26](https://pmc.ncbi.nlm.nih.gov/articles/PMC7592316/)
[27](https://data.math.au.dk/publications/phd/2013/math-phd-2013-jb.pdf)
[28](https://www.fda.gov/media/77832/download)
[29](https://pmc.ncbi.nlm.nih.gov/articles/PMC5362101/)
[30](https://arxiv.org/pdf/1910.08526.pdf)
[31](https://www.sciencedirect.com/science/article/abs/pii/S0377221705004248)
[32](https://www.sciencedirect.com/science/article/pii/S101836470900010X)
[33](https://www.sciencedirect.com/science/article/pii/S0377221723001236)
[34](https://www.sciencedirect.com/science/article/abs/pii/S0968090X21000127)
[35](https://www.sciencedirect.com/science/article/pii/S0360835225008460?dgcid=rss_sd_all)
[36](https://www.sciencedirect.com/science/article/abs/pii/S0360835220302655)
[37](https://www.sciencedirect.com/science/article/abs/pii/S037722171930476X)
[38](https://www.sciencedirect.com/science/article/pii/S0957417424005943)
[39](https://pmc.ncbi.nlm.nih.gov/articles/PMC11343876/)
[40](https://pmc.ncbi.nlm.nih.gov/articles/PMC12107652/)
[41](https://journals.stfm.org/familymedicine/2023/october/hersch-0060/)
[42](https://www.sciencedirect.com/science/article/pii/S0305048324001191)
[43](https://ieeexplore.ieee.org/document/9082729/)
[44](https://www.semanticscholar.org/paper/b150806ce6b035e6d14bee89b8e209a0dcfc89f4)
[45](https://www.tandfonline.com/doi/full/10.1080/00207543.2025.2532140)
[46](https://link.springer.com/10.1007/978-3-030-86433-0_15)
[47](https://www.tandfonline.com/doi/full/10.1057/jors.2012.32)
[48](http://ieeexplore.ieee.org/document/5427002/)
[49](https://pubs.acs.org/doi/10.1021/ie980782t)
[50](https://www.tandfonline.com/doi/full/10.1057/jors.2010.123)
[51](https://www.semanticscholar.org/paper/fcd77522af4deae7111f045b2c74c5c48a588375)
[52](https://www.semanticscholar.org/paper/b1c200317fc207adcb728c5404a8bb78a58e8bd1)
[53](https://downloads.hindawi.com/journals/aor/2010/120756.pdf)
[54](http://downloads.hindawi.com/journals/jam/2013/138037.pdf)
[55](https://arxiv.org/abs/2206.12496)
[56](https://arxiv.org/pdf/2402.15485.pdf)
[57](https://arxiv.org/pdf/2308.15494.pdf)
[58](http://arxiv.org/pdf/2311.15639.pdf)
[59](https://arxiv.org/pdf/2203.14719.pdf)
[60](https://arxiv.org/pdf/1711.00599.pdf)
[61](https://optimization-online.org/wp-content/uploads/2020/05/7809.pdf)
[62](https://www.scielo.br/j/pope/a/v7XM7nLLkZzxnDnPmcGWpsR/?format=html&lang=en)
[63](https://aronlaszka.com/papers/kim2023rolling.pdf)
[64](https://www.arxiv.org/pdf/2507.20465.pdf)
[65](https://www.sciencedirect.com/science/article/abs/pii/S0098135404000845)
[66](https://www.sciencedirect.com/science/article/abs/pii/S0305054807000858)
[67](https://paginas.fe.up.pt/~balobo/PPExt/Papers/AAC08.pdf)
[68](https://www.sciencedirect.com/science/article/abs/pii/S0360835223000645)
[69](https://www.arxiv.org/pdf/2510.10891.pdf)
[70](https://www.sciencedirect.com/science/article/abs/pii/S0305054818303010)
[71](https://www.sciencedirect.com/science/article/abs/pii/S0305048315000432)
[72](https://www.sciencedirect.com/science/article/abs/pii/S0305054822002684)
[73](https://www.sciencedirect.com/science/article/abs/pii/S0305054805003291)
[74](https://www.sciencedirect.com/science/article/am/pii/S0305054822002684)
[75](https://arxiv.org/html/2406.15691v1)
[76](https://paginas.fe.up.pt/~balobo/PPExt/Papers/AAC07.pdf)
[77](https://arxiv.org/abs/2403.10554)
[78](https://ieeexplore.ieee.org/document/9644323/)
[79](https://link.springer.com/10.1007/s10878-022-00896-5)
[80](https://ieeexplore.ieee.org/document/10590994/)
[81](https://ieeexplore.ieee.org/document/9426454/)
[82](https://ieeexplore.ieee.org/document/8869784/)
[83](https://ieeexplore.ieee.org/document/9091608/)
[84](https://ijamjournal.org/ijam/publication/index.php/ijam/article/view/293)
[85](https://www.mdpi.com/2072-4292/17/12/1972)
[86](https://figshare.com/ndownloader/files/12237065)
[87](https://arxiv.org/pdf/1808.10139.pdf)
[88](https://arxiv.org/html/2306.07638)
[89](https://arxiv.org/pdf/2106.13008.pdf)
[90](https://arxiv.org/html/2408.06843v1)
[91](https://pmc.ncbi.nlm.nih.gov/articles/PMC2815492/)
[92](https://pmc.ncbi.nlm.nih.gov/articles/PMC8035616/)
[93](https://pmc.ncbi.nlm.nih.gov/articles/PMC11675476/)
[94](https://jthornton.org/wp-content/uploads/2021/04/ICCIMA97.pdf)
[95](https://pmc.ncbi.nlm.nih.gov/articles/PMC9972317/)
[96](https://www.cirrelt.ca/documentstravail/cirrelt-2019-10.pdf)
[97](https://dergipark.org.tr/en/download/article-file/884615)
[98](https://core.ac.uk/download/pdf/225888712.pdf)
[99](https://www.sciencedirect.com/science/article/abs/pii/S0377221725004199)
[100](https://arxiv.org/pdf/2008.02849.pdf)
[101](https://www.sciencedirect.com/science/article/abs/pii/S0360835225002426)
[102](https://www.sciencedirect.com/science/article/abs/pii/S0305048312000035)
[103](https://arxiv.org/pdf/2111.06680.pdf)
[104](https://www.sciencedirect.com/science/article/abs/pii/S0305054823002162)
[105](https://www.sciencedirect.com/science/article/abs/pii/S0305054818303265)
[106](https://www.sciencedirect.com/science/article/pii/S0140366425000271)
[107](https://www.anylogic.kr/upload/iblock/1d6/1d686f575b98c0a0e71ba6f11749cb99.pdf)
[108](https://www.sciencedirect.com/science/article/abs/pii/S0360835220300152)
[109](https://lume.ufrgs.br/bitstream/handle/10183/229994/001131622.pdf?sequence=1&isAllowed=y)
[110](https://www.qip-journal.eu/index.php/QIP/article/download/405/522)
[111](https://onlinelibrary.wiley.com/doi/10.1002/net.20472)
[112](https://www.semanticscholar.org/paper/2f9906e556a938e2551bfb62fefeca5f75de1a9b)
[113](http://arxiv.org/pdf/2501.08484.pdf)
[114](http://arxiv.org/pdf/2310.20334.pdf)
[115](https://arxiv.org/pdf/2401.09910.pdf)
[116](https://arxiv.org/pdf/2504.07495.pdf)
[117](https://arxiv.org/pdf/2402.14847.pdf)
[118](http://arxiv.org/pdf/2311.16177.pdf)
[119](https://arxiv.org/pdf/2312.12621.pdf)
[120](https://arxiv.org/pdf/2312.16977.pdf)
[121](https://arxiv.org/abs/2107.10738)
[122](https://arxiv.org/html/2512.01802v1)
[123](https://www.sciencedirect.com/science/article/abs/pii/S0925527302004000)
[124](https://arxiv.org/pdf/2511.10264v1.pdf)
[125](https://arxiv.org/pdf/2501.04563.pdf)
[126](https://www.sciencedirect.com/science/article/pii/S0377221723004290)
[127](https://arxiv.org/pdf/2511.16844.pdf)
[128](https://www.sciencedirect.com/science/article/pii/S0305054818303241)
[129](https://repositorio.usp.br/directbitstream/6cc94f60-2c6f-4206-8a6e-e2b7048a811a/3149960_va%20-%20The%20null%20set%20of%20a%20polytope,%20and%20the%20Pompeiu%20property%20for%20polytopes.pdf)
[130](https://arxiv.org/pdf/2502.15791.pdf)
[131](https://pmc.ncbi.nlm.nih.gov/articles/PMC11648726/)
[132](https://bmchealthservres.biomedcentral.com/track/pdf/10.1186/s12913-017-2407-9)
[133](https://downloads.hindawi.com/journals/cin/2022/4377142.pdf)
[134](https://pmc.ncbi.nlm.nih.gov/articles/PMC12102215/)
[135](http://arxiv.org/pdf/2312.02723.pdf)
[136](https://pmc.ncbi.nlm.nih.gov/articles/PMC7571727/)
[137](https://barkeywolf.consulting/posts/hospital-scheduling/)
[138](https://arxiv.org/pdf/2312.08032.pdf)
[139](https://pubmed.ncbi.nlm.nih.gov/12363047/)
[140](https://pmc.ncbi.nlm.nih.gov/articles/PMC10011308/)
[141](https://arxiv.org/pdf/2501.08929.pdf)
[142](https://www.sciencedirect.com/science/article/pii/S2211692324000225)
[143](https://www.sciencedirect.com/science/article/pii/S3050784725000133)
[144](https://www.arxiv.org/pdf/2411.16297.pdf)
[145](https://www.sciencedirect.com/science/article/abs/pii/S0377221708009612)
[146](https://arxiv.org/pdf/2503.19003.pdf)
[147](https://dl.acm.org/doi/abs/10.1007/s10951-014-0385-x)
[148](https://pmc.ncbi.nlm.nih.gov/articles/PMC359424/)
[149](https://juniperpublishers.com/ajpn/pdf/AJPN.MS.ID.555695.pdf)
[150](https://pmc.ncbi.nlm.nih.gov/articles/PMC3886449/)
[151](https://pmc.ncbi.nlm.nih.gov/articles/PMC3193114/)
[152](https://pmc.ncbi.nlm.nih.gov/articles/PMC6502920/)
[153](https://pmc.ncbi.nlm.nih.gov/articles/PMC6342364/)
[154](https://pmc.ncbi.nlm.nih.gov/articles/PMC4944256/)
[155](https://www.herobgyn.com/irregular-periods)
[156](https://onlinelibrary.wiley.com/doi/10.1155/2014/937842)
[157](https://papers.ssrn.com/sol3/Delivery.cfm/833c7f4f-6d64-4432-b4b6-52e36c305e4e-MECA.pdf?abstractid=4585257&mirid=1)
[158](https://re.public.polimi.it/retrieve/e0c31c10-1c02-4599-e053-1705fe0aef77/0A%20Matheuristic%20Approach%20for%20the%20Home%20Care%20Scheduling%20Problem%20With%20Chargeable%20Overtime%20and%20Preference%20Matching.pdf)
[159](https://www.kennesaw.edu/coles/research/docs/fall-2017/fall17-05.pdf)
[160](https://orbit.dtu.dk/files/6514763/Lusby.pdf)
[161](https://pmc.ncbi.nlm.nih.gov/articles/PMC5681403/)
[162](https://www.sciencedirect.com/science/article/pii/S2213076422000033)
[163](http://arxiv.org/pdf/2407.11195.pdf)
[164](https://www.sciencedirect.com/science/article/abs/pii/S0305048318308338)
[165](https://www.sciencedirect.com/science/article/abs/pii/S2211692314000423)
[166](https://arxiv.org/pdf/2302.09459.pdf)
[167](https://www.sciencedirect.com/science/article/pii/S0305054822003562)
[168](https://www.sciencedirect.com/science/article/abs/pii/S1931720421002312)
[169](https://www.sciencedirect.com/science/article/pii/S221169231400006X)
[170](https://www.sciencedirect.com/science/article/abs/pii/S0377221723001911)
[171](https://journalwjarr.com/sites/default/files/fulltext_pdf/WJARR-2025-2464.pdf)