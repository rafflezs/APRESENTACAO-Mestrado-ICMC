<!-- docs/summary-chat/LITERATURE-sampling.md

## Greedy Sampling with Diversity Preservation in Sparse Search Spaces

Your challenge with developing a Pymoo sampling operator for discontinuous, sparse search spaces where greedy bias leads to low diversity (Hamming distance < 0.05) is well-documented in the literature. Several studies have tackled this exact problem with different approaches.

### Key Studies on Diversifying Greedy Sampling

**Diversifying Greedy Sampling (DGS) by Neumann et al. (2021)**

The seminal work "Diversifying Greedy Sampling and Evolutionary Diversity Optimisation for Constrained Monotone Submodular Functions" by Aneta Neumann, Jakob Bossek, and Frank Neumann directly addresses your problem. This work is particularly relevant because:[^1][^2][^3][^4]

- **The Margin Parameter (m)**: DGS introduces a margin parameter that controls the quality-diversity trade-off. Instead of always selecting the element with the largest marginal gain, the algorithm builds solutions by selecting the first B-m elements greedily, then allows m additional elements to be chosen more randomly. This creates multiple high-quality solutions with guaranteed approximation bounds while maintaining diversity.[^1]
- **Theoretical Guarantees**: The algorithm maintains approximation guarantees of (1 - 1/e)(1 - m/(B-m)) for solutions, where B is the constraint bound. When m is small compared to B, you retain near-optimal quality while enabling diversity.[^1]
- **Entropy-Based Diversity Measure**: They use entropy as the primary diversity metric, measuring how uniformly solutions are distributed across the solution space. This is more robust than simple Hamming distance for sparse spaces.[^5][^1]

**Evolutionary Diversity Optimisation (EDO)**

After generating initial diverse solutions with DGS, they propose coupling it with an Evolutionary Diversity Optimisation (EDO) approach:[^6][^1]

- **Quality Threshold**: Set a minimum quality threshold (f_min) based on the worst solution from DGS
- **Maximize Entropy**: Use evolutionary algorithms to further improve diversity while maintaining solutions above the quality threshold
- **Result**: Significantly higher entropy values compared to greedy sampling alone, particularly beneficial for sparse, discontinuous spaces


### Practical Implementation Strategies

**1. Generalized Diversifying Greedy Sampling (GDGS)**

Building on DGS, the GDGS variant generates μ solutions by randomly selecting unchosen elements until constraints are violated. For your sparse space:[^1]

```
Algorithm: GDGS(V, B, m, μ)
1. For each solution i = 1 to μ:
   - Start with empty set S
   - Add B-m elements with largest marginal gains
   - Randomly add remaining elements until |S| ≈ B
2. Return population of μ solutions
```

**2. Coevolutionary Pareto Diversity Optimization**

Neumann et al. (2022) extended this with a coevolutionary approach that maintains two populations:[^6]

- **Primary Population**: Focuses on objective quality
- **Diversity Population**: Optimizes diversity while maintaining quality threshold
- **Inter-population Crossover**: Creates offspring by combining solutions from both populations, improving both quality and diversity

**3. High-Order Entropy Measure**

For problems with low Hamming distance, consider the high-order entropy measure proposed by Nikfarjam et al. (2021):[^5]

- Instead of measuring diversity on individual elements, it measures diversity of **segments** (subsequences of your solution)
- More effective for structured problems where local patterns matter
- Significantly outperforms edge-based diversity when working with large populations


### Addressing Sparse Feasible Spaces

Your discontinuous, sparse search space creates additional challenges. Several constraint-handling strategies can help:

**1. Repair Operators**

Multiple studies show repair operators effectively handle sparse feasible regions:[^7][^8][^9]

- **Gradient-Based Repair**: If constraints are differentiable, use gradient information to guide infeasible solutions toward feasibility[^8][^7]
- **Reference-Based Repair**: Maintain a pool of feasible solutions; repair infeasibles by interpolating toward nearest feasible reference[^8]
- **Adaptive Greedy Repair**: Adjust exploration vs. exploitation during repair based on population convergence[^9]

**2. Biased Initialization with Feasibility Focus**

Instead of pure random initialization:

- **Heuristic Seeding**: Use problem-specific heuristics to generate initial feasible solutions[^10][^11]
- **Feasibility Pump**: Adapted from MILP, alternates between objective optimization and feasibility restoration[^12]
- **Clustered Initialization**: Divide search space into regions, ensure diverse sampling across regions[^13]

**3. Diversity-Aware Population Initialization**

From the review by Kazimipour et al. (2014):[^14]

- **Opposition-Based Learning (OBL)**: Generate initial population, then add opposite points in search space[^15]
- **Quasi-Random Sequences**: Use low-discrepancy sequences (Sobol, Halton) for better space coverage than random sampling[^14]
- **Chaotic Initialization**: Chaotic number generators can improve diversity while maintaining feasibility[^14]


### Measuring Diversity in Sparse Spaces

Since your Hamming distance is very low (< 0.05), consider alternative diversity metrics:

**Dimension Entropy (Kang et al., 2021)**[^16]

```python
# For each dimension k:
# 1. Divide dimension range into M intervals
# 2. Calculate pm,k = (number of particles in interval m) / (total population)
# 3. Dimension entropy = -1/n * Σ_k Σ_m pm,k * log(pm,k)
```

This metric:

- Works better with small populations in high dimensions
- Independent thinking across dimensions overcomes usual entropy limitations
- Directly applicable to sparse spaces

**Diversity Subsampling (Shang et al., 2022)**[^17]

For very sparse spaces where replication is unavoidable:

- Aim for i.i.d. uniform distribution over effective support of feasible region
- Uses density estimation to select maximally diverse samples
- Handles replicated observations better than repulsion-based methods


### Pymoo-Specific Implementation

For your Pymoo implementation, here's a concrete approach:

```python
from pymoo.core.sampling import Sampling
import numpy as np

class DiversifyingGreedySampling(Sampling):
    def __init__(self, margin_ratio=0.2, quality_heuristic=None):
        super().__init__()
        self.margin_ratio = margin_ratio  # m/B ratio
        self.quality_heuristic = quality_heuristic
    
    def _do(self, problem, n_samples, **kwargs):
        # 1. Generate base greedy solutions
        # 2. Apply margin-based diversification
        # 3. Use repair operator for feasibility
        # 4. Measure and enforce diversity threshold
        pass
```

Key components to implement:

1. **Greedy Construction Phase**: Use problem-specific heuristic to build high-quality solutions
2. **Diversification Phase**: Apply margin parameter to allow diverse choices
3. **Repair Phase**: Implement adaptive repair for infeasible solutions
4. **Diversity Enforcement**: Measure dimension entropy or segment-based diversity; reject solutions below threshold

### Additional Resources

- **Quality-Diversity Algorithms**: MAP-Elites and variants maintain archives of diverse high-quality solutions across behavior descriptors[^18][^19]
- **Submodular Optimization Framework**: If your problem has submodular structure, leverage approximation guarantees from greedy algorithms[^4][^20][^21]
- **GRASP (Greedy Randomized Adaptive Search)**: Combines greedy construction with randomization through restricted candidate lists[^22][^23]


### Recommendations for Your Specific Case

Given your constraints:

1. **Start with GDGS**: Implement the margin-based approach with margin = 0.15-0.25 * solution_size
2. **Use Dimension Entropy**: More sensitive to diversity in sparse spaces than Hamming distance
3. **Implement Adaptive Repair**: Essential for sparse feasible regions; gradient-based if differentiable, reference-based otherwise
4. **Consider Two-Phase Approach**:
    - Phase 1: Generate diverse feasible solutions with relaxed quality
    - Phase 2: Improve quality while maintaining diversity via EDO
5. **Leverage Problem Structure**: If your problem has any submodular or matroid structure, exploit it for better guarantees

The key insight from the literature is that maintaining diversity in sparse, discontinuous spaces requires **explicit diversity objectives** combined with **adaptive quality thresholds**, rather than hoping diversity emerges naturally from random initialization.
<span style="display:none">[^100][^101][^102][^103][^104][^105][^106][^107][^108][^109][^110][^111][^112][^113][^114][^115][^116][^117][^118][^119][^120][^121][^122][^123][^124][^125][^126][^127][^128][^129][^130][^131][^132][^133][^134][^24][^25][^26][^27][^28][^29][^30][^31][^32][^33][^34][^35][^36][^37][^38][^39][^40][^41][^42][^43][^44][^45][^46][^47][^48][^49][^50][^51][^52][^53][^54][^55][^56][^57][^58][^59][^60][^61][^62][^63][^64][^65][^66][^67][^68][^69][^70][^71][^72][^73][^74][^75][^76][^77][^78][^79][^80][^81][^82][^83][^84][^85][^86][^87][^88][^89][^90][^91][^92][^93][^94][^95][^96][^97][^98][^99]</span>

<div align="center">⁂</div>

[^1]: https://cs.adelaide.edu.au/~frank/papers/GECCO2021-Submodular.pdf

[^2]: https://dl.acm.org/doi/abs/10.1145/3449639.3459385

[^3]: https://www.wi.uni-muenster.de/research/publications/165970

[^4]: https://dl.acm.org/doi/10.1145/3449639.3459385

[^5]: https://arxiv.org/abs/2104.13538

[^6]: https://arxiv.org/abs/2204.05457

[^7]: https://peerj.com/articles/cs-2095

[^8]: https://cs.adelaide.edu.au/~frank/papers/evostar-impact-repair.pdf

[^9]: https://www.aimspress.com/article/doi/10.3934/math.2025600?viewType=HTML

[^10]: https://pubs2.ascee.org/index.php/IJRCS/article/view/1652

[^11]: https://www.mdpi.com/2075-1680/11/7/318

[^12]: https://onlinelibrary.wiley.com/doi/10.1155/2019/5615243

[^13]: https://www.ajol.info/index.php/njtd/article/view/201020

[^14]: https://titan.csit.rmit.edu.au/~e46507/publications/borhan-initReview-cec14.pdf

[^15]: https://www.sciencedirect.com/science/article/pii/S0898122107001344

[^16]: https://pmc.ncbi.nlm.nih.gov/articles/PMC8065515/

[^17]: https://arxiv.org/pdf/2206.10812.pdf

[^18]: https://algorithmafternoon.com/novelty/map_elites/

[^19]: https://proceedings.neurips.cc/paper/2021/file/532923f11ac97d3e7cb0130315b067dc-Paper.pdf

[^20]: https://ojs.aaai.org/index.php/AAAI/article/view/5504

[^21]: https://www.sciencedirect.com/science/article/abs/pii/S0167637718300038

[^22]: http://profs.ic.uff.br/~celso/artigos/grasp.pdf

[^23]: http://profs.ic.uff.br/~celso/artigos/resende-ribeiro-GRASP.pdf

[^24]: https://ieeexplore.ieee.org/document/9019603/

[^25]: https://www.semanticscholar.org/paper/9f30ac455f96030b1c6ed36b946c7b01f4ef2e64

[^26]: https://www.semanticscholar.org/paper/a9ed23016a1b89fc78f23f8a03d6491219216d67

[^27]: https://www.nature.com/articles/s41591-019-0671-4

[^28]: https://www.semanticscholar.org/paper/47064837571ea8a2cee51cd481a2acea1b01f032

[^29]: http://arxiv.org/pdf/2406.14876.pdf

[^30]: http://arxiv.org/pdf/2403.00540.pdf

[^31]: https://arxiv.org/pdf/2303.01015.pdf

[^32]: http://arxiv.org/pdf/2410.17938.pdf

[^33]: http://arxiv.org/pdf/2209.01754.pdf

[^34]: https://joss.theoj.org/papers/10.21105/joss.04468.pdf

[^35]: https://joss.theoj.org/papers/10.21105/joss.06014

[^36]: http://arxiv.org/pdf/2412.03718.pdf

[^37]: https://anyoptimization.com/projects/pysamoo/

[^38]: https://pymoo.org/customization/initialization.html

[^39]: https://en.wikipedia.org/wiki/Evolutionary_algorithm

[^40]: https://stackoverflow.com/questions/75775606/constructing-a-custom-problem-in-pymoo-picking-a-subset-of-vehicles-from-a-bag

[^41]: https://www.ijcai.org/Proceedings/15/Papers/248.pdf

[^42]: https://community.ibm.com/community/user/discussion/evolutionary-algorithms-the-future-of-optimization-and-problem-solving

[^43]: https://pymoo.org/algorithms/soo/brkga.html

[^44]: https://www.pymoo.org/operators/index.html

[^45]: https://www.sciencedirect.com/science/article/abs/pii/S0031320310005340

[^46]: https://ieeexplore.ieee.org/document/5675672/

[^47]: https://pymoo.org/operators/sampling.html

[^48]: https://dl.acm.org/doi/abs/10.1109/TEVC.2010.2058121

[^49]: https://www.egr.msu.edu/coinlab/blankjul/pymoo-rc/algorithms/genetic_algorithm.html

[^50]: https://link.aps.org/doi/10.1103/PhysRevE.108.065303

[^51]: https://www.semanticscholar.org/paper/4a731104eed26837cc929c5871ebb6f3f0d3efd6

[^52]: https://ieeexplore.ieee.org/document/9185823/

[^53]: https://iopscience.iop.org/article/10.1088/2632-2153/acca60

[^54]: https://arxiv.org/abs/2505.21372

[^55]: https://arxiv.org/abs/2411.05010

[^56]: https://ieeexplore.ieee.org/document/10426762/

[^57]: https://imanagerpublications.com/article/19099

[^58]: https://ieeexplore.ieee.org/document/8879518/

[^59]: https://ieeexplore.ieee.org/document/11083625/

[^60]: http://arxiv.org/pdf/2402.04646.pdf

[^61]: https://dl.acm.org/doi/pdf/10.1145/3637034

[^62]: https://arxiv.org/pdf/2503.01335.pdf

[^63]: https://arxiv.org/pdf/1306.4157.pdf

[^64]: https://arxiv.org/pdf/2010.06176.pdf

[^65]: https://arxiv.org/pdf/2403.17421.pdf

[^66]: https://arxiv.org/pdf/2105.12920.pdf

[^67]: http://arxiv.org/pdf/2408.04313.pdf

[^68]: https://www.nature.com/articles/s41598-024-68436-1

[^69]: https://www.research-collection.ethz.ch/bitstreams/0e2aa20f-b45d-4ceb-ba8a-f864a5a64421/download

[^70]: https://pmc.ncbi.nlm.nih.gov/articles/PMC7403618/

[^71]: https://en.wikipedia.org/wiki/Genetic_algorithm

[^72]: https://arxiv.org/pdf/1109.0085.pdf

[^73]: https://www.sciencedirect.com/science/article/pii/S0020025523015177

[^74]: https://cimat.repositorioinstitucional.mx/jspui/bitstream/1008/1164/1/TE 865.pdf

[^75]: http://iwbbio.ugr.es/2014/papers/IWBBIO_2014_paper_58.pdf

[^76]: https://esj-journals.onlinelibrary.wiley.com/doi/10.1111/1440-1703.12102

[^77]: https://www.datacamp.com/tutorial/hamming-distance

[^78]: http://research.engineering.uiowa.edu/cbig/sites/research.engineering.uiowa.edu.cbig/files/files/ongie2015_piecewise_linear.pdf

[^79]: https://arxiv.org/pdf/1411.4148.pdf

[^80]: https://oa.upm.es/82785/1/Manuscrito.pdf

[^81]: https://ieeexplore.ieee.org/iel7/5971803/10258149/10258255.pdf

[^82]: https://dl.acm.org/doi/pdf/10.1162/evco.1998.6.1.81

[^83]: https://www.idsia.ch/~tino/papers/gomez.gecco09.pdf

[^84]: https://dl.acm.org/doi/pdf/10.1145/3638529.3654082

[^85]: https://www.mdpi.com/1424-8220/23/5/2808

[^86]: http://link.springer.com/10.1007/978-3-030-31140-7_17

[^87]: https://ieeexplore.ieee.org/document/9436749/

[^88]: https://www.worldscientific.com/doi/10.1142/S021759592240005X

[^89]: https://pubsonline.informs.org/doi/10.1287/ijoc.2022.0372

[^90]: https://www.tandfonline.com/doi/full/10.1057/s41274-016-0146-7

[^91]: https://www.mdpi.com/2504-446X/7/7/407

[^92]: http://www.tandfonline.com/doi/full/10.1080/15325008.2015.1122113

[^93]: https://arxiv.org/pdf/2004.06661.pdf

[^94]: https://arxiv.org/pdf/2202.10267.pdf

[^95]: http://arxiv.org/pdf/1407.0088.pdf

[^96]: https://arxiv.org/abs/1203.5483v3

[^97]: http://arxiv.org/pdf/1910.12512.pdf

[^98]: https://pmc.ncbi.nlm.nih.gov/articles/PMC4784713/

[^99]: https://arxiv.org/abs/2003.06532

[^100]: http://arxiv.org/pdf/1907.00723.pdf

[^101]: https://www.jmlr.org/papers/volume3/nair02a/nair02a.pdf

[^102]: https://www.sciencedirect.com/science/article/abs/pii/S0377221711003626

[^103]: https://www.ijcai.org/proceedings/2024/0773.pdf

[^104]: https://arxiv.org/pdf/2005.04095.pdf

[^105]: https://45jaiio.sadio.org.ar/sites/default/files/ASAI-01_1.pdf

[^106]: https://sci2s.ugr.es/sites/default/files/ficherosPublicaciones/1410_10.1016@j.ejor_.2011.04.018.pdf

[^107]: https://www.sciencedirect.com/topics/engineering/greedy-algorithm

[^108]: http://ieeexplore.ieee.org/document/6089109/

[^109]: https://en.wikipedia.org/wiki/Greedy_algorithm

[^110]: https://dl.acm.org/doi/10.1145/3449639.3459384

[^111]: https://proceedings.neurips.cc/paper/2018/file/dbbf603ff0e99629dda5d75b6f75f966-Reviews.html

[^112]: https://ieeexplore.ieee.org/iel8/78/4359509/10572481.pdf

[^113]: https://www.sciencedirect.com/science/article/abs/pii/S0957417423026660

[^114]: https://dl.acm.org/doi/10.24963/ijcai.2024/773

[^115]: https://arxiv.org/pdf/2406.03731.pdf

[^116]: https://www.nature.com/articles/s41598-023-47729-x

[^117]: https://ieeexplore.ieee.org/document/8970919/

[^118]: https://www.semanticscholar.org/paper/c1957945df2943095c96b05268870136e40d00c4

[^119]: https://arxiv.org/abs/2404.03740

[^120]: https://arxiv.org/abs/2309.14359

[^121]: https://ojs.aaai.org/index.php/AAAI/article/view/25682

[^122]: https://ieeexplore.ieee.org/document/10103509/

[^123]: https://www.mdpi.com/2227-7390/12/10/1470

[^124]: https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.SEA.2025.19

[^125]: http://arxiv.org/pdf/1704.01652.pdf

[^126]: http://arxiv.org/pdf/2102.12879.pdf

[^127]: https://arxiv.org/pdf/2009.13998.pdf

[^128]: http://arxiv.org/pdf/1811.07673.pdf

[^129]: https://arxiv.org/pdf/2307.07567.pdf

[^130]: https://arxiv.org/html/2405.05202v1

[^131]: http://arxiv.org/pdf/2102.05782.pdf

[^132]: http://arxiv.org/pdf/1810.12861.pdf

[^133]: https://arxiv.org/abs/2307.07567

[^134]: https://optimization-online.org/wp-content/uploads/2018/04/6550.pdf

