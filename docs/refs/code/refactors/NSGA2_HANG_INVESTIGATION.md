# NSGA-2 Extended Local Execution Hang - Investigation Report

**Date**: 2026-02-04
**Issue**: NSGA-2 runs hang locally after NSGA2Extended changes
**Status**: Partially resolved - root cause still under investigation

## Summary

Local NSGA-2 runs hang indefinitely after implementing NSGA2Extended enhancements. The hang occurs at different points in execution, suggesting a race condition or resource contention issue rather than a simple code bug.

## Initial Problem

### Original Hang Point
- **Location**: "SETTING UP PROBLEM" step in `engine/runners/run_nsga2.py:94-96`
- **Symptom**: Process hung for 30+ minutes at a step that should be instantaneous
- **Root Cause**: `NCPUS: 20` in YAML configuration being passed as `--n_workers 32`
  - Created 32 worker processes on local machine (likely has < 32 cores)
  - `multiprocessing.Pool(32)` creation either hung or caused resource exhaustion

### Initial Fix Applied
1. **Created local-specific configs** in `cluster/configs/local-tests/nsga2/`
   - Set `N_WORKERS: 1` in each experiment
   - Set `NCPUS: 1` in configuration
   - Reduced `TERMINATION_VALUE: 3600` (5 minutes for quick tests)
   - Changed output directories to `data/output/local-tests/`

2. **Improved multiprocessing.Pool handling** in `engine/runners/run_nsga2.py`:
   - Added CPU count validation (warns if n_workers > cpu_count)
   - Added proper error handling and cleanup
   - Added safeguards in `finally` block for cleanup on error

## Current Problem

### New Hang Point (After Fixes)
- **Location**: Between `setup_instance()` completion and `setup_problem()` start
- **Log Output**: Stops after "CHECKPOINT: Instance loaded and validated"
- **Expected Next Output**: "DEBUG: About to call setup_problem()" (line 789)
- **Symptom**: No output after checkpoint, process hangs indefinitely

### Investigation Steps Taken

1. **Verified Imports**: `test_import_hang.py` confirms all imports work fine (0.94s)
2. **Added Debug Output**: Debug prints at lines 789, 791, 94, 95 to isolate hang point
3. **Cleared Python Cache**: Removed `__pycache__` and `.pyc` files
4. **Tested Direct Execution**: Attempted to run `run_nsga2.py` directly (arg parsing issues)

### Diagnostic Output Not Appearing

The debug line at line 789:
```python
print(f"DEBUG: About to call setup_problem()")
sys.stdout.flush()
```

Does NOT appear in log output, suggesting:
- Code execution stops before line 789
- OR output buffering issue despite `sys.stdout.flush()`
- OR subprocess stdout capture issue in batch script

## Code Modifications Made

### Files Modified

1. **cluster/configs/local-tests/nsga2/** (NEW)
   - nsga2_15days.yaml
   - nsga2_30days.yaml
   - nsga2_60days.yaml
   - nsga2_90days.yaml

2. **engine/runners/run_nsga2.py**
   - Lines 92-139: Improved `setup_problem()` with CPU validation
   - Lines 785-793: Added debug output in `run()` method
   - Lines 813-823: Improved `finally` block cleanup (partially reverted by user)

### Key Changes to multiprocessing.Pool Setup

**Before:**
```python
if n_workers > 1:
    self.pool = multiprocessing.Pool(n_workers)
    elementwise_runner = StarmapParallelization(self.pool.starmap)
```

**After:**
```python
if n_workers > 1:
    cpu_count = multiprocessing.cpu_count()
    if n_workers > cpu_count:
        print(f"WARNING: Requested {n_workers} workers but only {cpu_count} CPUs available")
        n_workers = cpu_count

    self.pool = multiprocessing.Pool(n_workers)
    elementwise_runner = StarmapParallelization(self.pool.starmap)
```

## Suspected Issues

### Hypothesis 1: Output Buffering in Subprocess
The batch script (`cluster/batch/batch_nsga2.py`) uses:
```python
result = subprocess.run(cmd, cwd=project_root, stderr=subprocess.PIPE, text=True)
```

This may buffer stdout/stderr differently than direct execution. The Python `-u` flag wasn't used.

### Hypothesis 2: Race Condition in NSGA2Extended Initialization
The hang occurs at an inconsistent point:
- First hang: "SETTING UP PROBLEM" (before multiprocessing setup)
- Second hang: After instance load, before problem setup

This suggests a timing-dependent issue, possibly related to:
- Import-time side effects in new NSGA2Extended modules
- Global state initialization
- Circular imports (though `test_import_hang.py` suggests not)

### Hypothesis 3: Resource Contention
Even with `N_WORKERS: 1`, there may be resource issues:
- NumPy/SciPy thread pools (`OMP_NUM_THREADS` set to 1, but may not be enough)
- File I/O blocking
- Database/cache locking (unlikely but possible)

## Recommendations

### Immediate Next Steps

1. **Run with Python `-u` flag for unbuffered output**
   ```bash
   python -u cluster/batch/batch_nsga2.py --config ...
   ```

2. **Add strace/debugging to see system-level hang**
   ```bash
   strace -e trace=open,openat,read,write,clone,fork,execve \
     python cluster/batch/batch_nsga2.py --config ...
   ```

3. **Test pipeline script directly (bypass batch script)**
   ```bash
   python -u pipelines/run_nsga2_pipeline.py \
     --instance_file data/input/instances/30_days/2022jan02_to_2022jan31 \
     --output_dir data/output/test \
     --pop_size 10 \
     --termination_method n_gen \
     --termination_value 2 \
     --seed 42 \
     --initial_condition_method mixed \
     --n_workers 1 \
     --algorithm nsga2 \
     --skip_internal_analysis \
     ... (all required params)
   ```

4. **Check for file descriptor leaks or locks**
   ```bash
   lsof -p <PID> | grep -E "(PIPE|FIFO|sock)"
   ```

5. **Simplify to baseline NSGA-2 (not Extended)**
   - Set `ALGORITHM: "nsga2"` in local configs
   - If baseline works, issue is in NSGA2Extended modules
   - If baseline also hangs, issue is in common code/environment

### Long-term Fixes

1. **Improve subprocess handling in batch script**
   - Use `subprocess.Popen` with real-time stdout streaming
   - Add timeout parameter to detect hangs early
   - Better error reporting

2. **Add process monitoring/watchdog**
   - Detect when process produces no output for N seconds
   - Auto-kill and report hang location

3. **Review NSGA2Extended for import-time side effects**
   - Check `adaptive_diversity.py`, `two_stage_evolution.py`, `nsga2_extended.py`
   - Look for global variables, expensive operations at import time
   - Check for circular import chains

4. **Add telemetry/heartbeat logging**
   - Print progress markers every N seconds from main thread
   - Helps identify if hang is complete freeze vs slow operation

## Files for Reference

- Hang logs: `logs/nsga2-extended-trial-run-local.log`
- Local configs: `cluster/configs/local-tests/nsga2/`
- Runner: `engine/runners/run_nsga2.py`
- Batch script: `cluster/batch/batch_nsga2.py`
- Pipeline: `pipelines/run_nsga2_pipeline.py`

## Status Summary

- [X] Identified original hang cause (NCPUS=32)
- [X] Created local test configs
- [X] Improved multiprocessing.Pool handling
- [ ] Resolved current hang (after instance load)
- [ ] Verified cluster execution still works
- [ ] Validated all local configs work end-to-end

**Conclusion**: The issue is complex and likely related to how subprocess executes the pipeline, not a simple bug in the NSGA-2 code itself. More system-level debugging needed.
