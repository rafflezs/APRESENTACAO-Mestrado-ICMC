# Pymoo parallelization: Choosing the right method for HPC and local development

**Starmap wins for PBS/Torque clusters, while joblib's loky backend can cause CPU oversubscription that kills your jobs.** For researchers using Pymoo with Gurobi-based fitness functions, the `StarmapParallelization` class with `multiprocessing.Pool` provides the most reliable cross-environment compatibility with predictable resource usage. Vectorized evaluation offers the best performance for pure mathematical operations but won't help when each evaluation calls external solvers like Gurobi. The key insight: PBS clusters require explicit control over process spawning that joblib's automatic management can violate.

## The three parallelization methods compared head-to-head

Pymoo provides three distinct approaches to parallel evaluation, each with fundamentally different architectures. **Vectorized evaluation** uses NumPy matrix operations to process entire populations in a single function call—incredibly efficient for mathematical functions but incompatible with iterative solver calls. **Starmap parallelization** distributes individual solution evaluations across worker processes using Python's standard `multiprocessing.Pool.starmap()` interface. **Joblib parallelization** wraps this distribution in a higher-level API with automatic worker management and multiple backend options.

For Gurobi-based fitness functions, vectorized evaluation is **not applicable** since each evaluation must call the solver independently. The real comparison is between starmap and joblib:

| Aspect | Starmap | Joblib | Vectorized |
|--------|---------|--------|------------|
| **Implementation lines** | ~5 lines | ~3 lines | Restructure entire `_evaluate` |
| **Dependencies** | Standard library only | `joblib` package | `numpy` only |
| **PBS compatibility** | Excellent | Problematic | N/A for Gurobi |
| **Pool management** | Manual create/close | Automatic | None required |
| **CPU predictability** | Explicit, controlled | Can exceed allocation | Single-threaded |
| **Startup overhead** | ~0.1-0.3 seconds | ~6-15 seconds (loky) | Negligible |

## Why joblib fails on PBS clusters

Joblib's default `loky` backend creates serious compatibility issues in PBS/Torque environments. The core problem is **CPU oversubscription**: documented cases show jobs killed because joblib used **19.38 CPUs when only 8 were allocated**, despite setting `n_jobs=4`. This occurs because:

1. **Nested thread spawning**: Libraries like NumPy (MKL/OpenBLAS) spawn their own threads, compounding with joblib's processes
2. **Loky initialization overhead**: The backend can temporarily spike CPU usage during startup
3. **Automatic core detection**: Joblib's `-1` setting detects all node cores, not your PBS allocation
4. **Shared memory restrictions**: HPC nodes with limited `/dev/shm` cause `KeyError` exceptions

The error message `PBS: job killed: ncpus X exceeded limit Y` is a telltale sign of this behavior. Even setting `OMP_NUM_THREADS=1` may not fully prevent oversubscription because loky's fork+exec mechanism creates temporary resource spikes that PBS monitors.

## Implementation code for each method

### Starmap: The recommended HPC-compatible approach

```python
import os
import multiprocessing
from pymoo.core.problem import ElementwiseProblem, StarmapParallelization
from pymoo.algorithms.moo.nsga2 import NSGA2
from pymoo.optimize import minimize

class GurobiOptimizationProblem(ElementwiseProblem):
    def __init__(self, **kwargs):
        super().__init__(n_var=10, n_obj=2, n_ieq_constr=1, 
                         xl=0.0, xu=1.0, **kwargs)  # **kwargs passes elementwise_runner
    
    def _evaluate(self, x, out, *args, **kwargs):
        # x is 1D array (single solution) - call Gurobi here
        f1, f2, g1 = solve_gurobi_model(x)
        out["F"] = [f1, f2]
        out["G"] = [g1]

# Get cores from PBS or config
n_cpus = int(os.environ.get('PBS_NUM_PPN', 
             os.environ.get('NCPUS', 4)))

pool = multiprocessing.Pool(n_cpus)
runner = StarmapParallelization(pool.starmap)
problem = GurobiOptimizationProblem(elementwise_runner=runner)

res = minimize(problem, NSGA2(pop_size=100), 
               termination=("n_gen", 200), seed=1)
pool.close()
pool.join()
```

### Joblib: Simpler API but cluster-problematic

```python
from pymoo.parallelization.joblib import JoblibParallelization

# Not recommended for PBS, but works locally
runner = JoblibParallelization(
    n_jobs=4,
    backend="loky",  # or "multiprocessing" for better PBS compatibility
    timeout=300.0
)
problem = GurobiOptimizationProblem(elementwise_runner=runner)
```

### Modular configuration for multi-environment deployment

The most practical approach uses a factory function that selects parallelization based on configuration:

```python
import os
import yaml
from typing import Optional

def create_parallelization_runner(config_path: str = "config.yaml"):
    """Create appropriate runner based on environment and config."""
    
    # Load configuration
    with open(config_path) as f:
        config = yaml.safe_load(f)
    
    parallel_config = config.get('parallelization', {})
    enabled = parallel_config.get('enabled', False)
    n_cpus = parallel_config.get('ncpus', None)
    method = parallel_config.get('method', 'starmap')
    
    if not enabled:
        return None  # Sequential evaluation
    
    # Determine CPU count: config → PBS → fallback
    if n_cpus is None:
        n_cpus = int(os.environ.get('PBS_NUM_PPN',
                     os.environ.get('SLURM_CPUS_PER_TASK',
                     os.cpu_count() or 4)))
    
    if method == 'starmap':
        import multiprocessing
        from pymoo.core.problem import StarmapParallelization
        pool = multiprocessing.Pool(n_cpus)
        runner = StarmapParallelization(pool.starmap)
        runner._pool = pool  # Store reference for cleanup
        return runner
    
    elif method == 'joblib':
        from pymoo.parallelization.joblib import JoblibParallelization
        backend = parallel_config.get('backend', 'loky')
        return JoblibParallelization(n_jobs=n_cpus, backend=backend)
    
    elif method == 'threadpool':
        from multiprocessing.pool import ThreadPool
        from pymoo.core.problem import StarmapParallelization
        pool = ThreadPool(n_cpus)
        runner = StarmapParallelization(pool.starmap)
        runner._pool = pool
        return runner
    
    return None
```

**Example YAML configuration file:**

```yaml
# config.yaml
parallelization:
  enabled: true
  method: starmap      # starmap, joblib, or threadpool
  ncpus: null          # null = auto-detect from PBS_NUM_PPN or system
  backend: loky        # for joblib only: loky, multiprocessing, threading

optimization:
  algorithm: nsga2
  pop_size: 100
  n_gen: 200
```

## Critical PBS cluster configuration steps

To prevent CPU oversubscription on the USP Euler cluster or similar PBS environments:

**1. Control library threading in your PBS script:**
```bash
#!/bin/bash
#PBS -l select=1:ncpus=32:mem=128gb
#PBS -l walltime=24:00:00

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export GRB_LICENSE_FILE=/path/to/gurobi.lic

cd $PBS_O_WORKDIR
python run_optimization.py
```

**2. Set thread limits in Python before imports:**
```python
import os
os.environ['OMP_NUM_THREADS'] = '1'
os.environ['MKL_NUM_THREADS'] = '1'
# Must be set BEFORE importing numpy/scipy/gurobi

import numpy as np
from gurobipy import Model
```

**3. Read PBS allocation correctly:**
```python
def get_pbs_cores() -> int:
    """Safely get allocated cores from PBS environment."""
    pbs_vars = ['PBS_NUM_PPN', 'PBS_NP', 'NCPUS']
    for var in pbs_vars:
        if var in os.environ:
            return int(os.environ[var])
    return 1  # Safe fallback
```

## When each method performs best

**Use starmap with multiprocessing.Pool** for Gurobi fitness functions on PBS clusters. Each Gurobi solve is CPU-intensive and runs in its own process, making serialization overhead negligible compared to solve time. The **32 CPUs** typical of your PBS jobs will see near-linear speedup for population sizes ≥32.

**Use ThreadPool** (not multiprocessing.Pool) when fitness functions are I/O-bound or when you're calling GIL-releasing libraries. Since Gurobi's Python bindings release the GIL during optimization, ThreadPool can work, but process isolation is safer for solver stability.

**Avoid joblib on PBS** unless you switch to the `multiprocessing` backend (not loky) and carefully control all nested threading. Even then, starmap offers equivalent functionality with less abstraction.

**Consider vectorized evaluation** only if you can reformulate your problem to avoid per-solution Gurobi calls—for instance, if preprocessing can be vectorized while solving remains sequential.

### Scalability expectations for 32 CPUs

With expensive Gurobi evaluations (seconds to minutes each), parallelization efficiency should reach **85-95%** on 32 cores. The overhead breakdown:

- Pool creation: ~0.5 seconds (one-time)
- Per-evaluation serialization: ~1-10 milliseconds
- Gurobi solve time: 1-60+ seconds (dominates)

For a population of 100 solutions and 200 generations (20,000 total evaluations), starmap parallelization with 32 workers reduces wall-clock time from potentially **weeks** to **hours**.

## Conclusion

For Pymoo optimization with Gurobi on PBS/Torque clusters, **starmap parallelization is the clear winner**. It uses only standard library dependencies, provides explicit control over process allocation, and avoids the CPU oversubscription issues that make joblib problematic in HPC environments. The implementation requires approximately 5 lines of additional code and integrates cleanly with configuration-file-based CPU allocation. Reserve joblib for local development where its simpler API and automatic management provide convenience without cluster compatibility concerns.