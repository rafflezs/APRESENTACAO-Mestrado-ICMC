# Time Limit Parameter Migration Guide

## Summary of Changes

**Legacy parameters REMOVED:**
- `RF_TIME_LIMIT` - No longer used
- `FO_TIME_LIMIT` - No longer used
- `FO_TIME_LIMIT_PER_ITER` - No longer used
- `FO_DECOMPOSITION` - No longer used
- `FO_PHYSICIANS` - No longer used

**New parameters ADDED:**
- `RF_POLISH_RATIO` - Controls time split within Relax-and-Fix

## Motivation

The old system had confusing and redundant time limit parameters:
- `RF_TIME_LIMIT` was ignored (RF actually used `TIME_LIMIT`)
- `FO_TIME_LIMIT` was ignored (hybrid calculated time dynamically)
- Users had to manually calculate `RF_TIME_LIMIT + FO_TIME_LIMIT = TIME_LIMIT`
- The polish time ratio in R&F was hardcoded at 20%

The new system is clearer:
- **One primary parameter**: `TIME_LIMIT` (total budget per epsilon)
- **Ratio-based allocation**: `RF_RATIO` and `RF_POLISH_RATIO` for fine control
- **No redundancy**: Remove unused parameters to avoid confusion

## How Time Limits Work Now

### 1. Exact Solver
```yaml
TIME_LIMIT: 3600      # 1 hour total per epsilon
SUB_SOLVER: exact
```

**Behavior:** Gurobi runs for exactly 3600s per epsilon point.

---

### 2. Relax-and-Fix Only
```yaml
TIME_LIMIT: 3600           # 1 hour total per epsilon
SUB_SOLVER: relax_and_fix
RF_POLISH_RATIO: 0.2       # Optional: 20% for final polish (default)
```

**Behavior:**
- Total R&F time: 3600s
- Window solves: 2880s (80%)
- Final polish: 720s (20%)

**Note:** The old `RF_TIME_LIMIT: 900` would be ignored. R&F gets the full `TIME_LIMIT`.

---

### 3. Hybrid (R&F + F&O)
```yaml
TIME_LIMIT: 3600           # 1 hour total per epsilon
SUB_SOLVER: hybrid
RF_RATIO: 0.25             # Optional: 25% for R&F (default)
RF_POLISH_RATIO: 0.2       # Optional: 20% of R&F time for polish (default)
```

**Behavior:**
- R&F phase: 900s (25% of 3600s)
  - R&F windows: 720s (80% of 900s)
  - R&F polish: 180s (20% of 900s)
- F&O phase: ~2700s (remaining time after R&F)

**Note:** The old `RF_TIME_LIMIT: 900` and `FO_TIME_LIMIT: 2700` would be ignored. The system calculates these from `TIME_LIMIT` and `RF_RATIO`.

---

## Migration Examples

### Before (Old Config)
```yaml
TIME_LIMIT: 3600
RF_TIME_LIMIT: 900        # ❌ Ignored!
FO_TIME_LIMIT: 2700       # ❌ Ignored!
SUB_SOLVER: hybrid
```

### After (New Config)
```yaml
TIME_LIMIT: 3600          # ✅ Only parameter needed
SUB_SOLVER: hybrid
RF_RATIO: 0.25            # Optional: defaults to 0.25 anyway
```

---

### Before (R&F Only)
```yaml
TIME_LIMIT: 3600
RF_TIME_LIMIT: 900        # ❌ Ignored! RF actually got full 3600s
SUB_SOLVER: relax_and_fix
```

### After (R&F Only)
```yaml
TIME_LIMIT: 3600          # ✅ Explicit and correct
SUB_SOLVER: relax_and_fix
RF_POLISH_RATIO: 0.2      # Optional: control polish time
```

---

## New Parameter Reference

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `TIME_LIMIT` | int | required | Total time budget per epsilon (seconds) |
| `RF_RATIO` | float | 0.25 | Fraction of `TIME_LIMIT` for R&F in hybrid mode |
| `RF_POLISH_RATIO` | float | 0.2 | Fraction of R&F time for final polish solve |
| `RF_WINDOW_SIZE_PCT` | float | 0.10 | Window size as percentage of total periods |
| `RF_OVERLAP` | int | 1 | Overlap between windows in periods |
| `FO_WINDOW_SIZE_PCT` | float | 0.05 | F&O neighborhood size as percentage |
| `FO_MAX_ITERATIONS` | int | 50 | Maximum F&O iterations |
| `FO_NO_IMPROVEMENT` | int | 15 | Early stop after N iterations without improvement |

---

## Adjusting Time Allocation

### To give more time to F&O in hybrid:
```yaml
RF_RATIO: 0.15   # R&F gets 15%, F&O gets 85%
```

### To give more time to final polish in R&F:
```yaml
RF_POLISH_RATIO: 0.3   # 30% for polish, 70% for windows
```

### To reduce overall time:
```yaml
TIME_LIMIT: 1800   # 30 minutes instead of 1 hour
```

---

## What to Do

1. **Remove these lines** from your YAML configs:
   - `RF_TIME_LIMIT: ...`
   - `FO_TIME_LIMIT: ...`
   - `FO_TIME_LIMIT_PER_ITER: ...`
   - `FO_DECOMPOSITION: ...`
   - `FO_PHYSICIANS: ...`

2. **Keep these lines** (they work correctly):
   - `TIME_LIMIT: ...` ✅
   - `RF_RATIO: ...` ✅ (hybrid only)
   - `RF_WINDOW_SIZE_PCT: ...` ✅
   - `RF_OVERLAP: ...` ✅
   - `FO_WINDOW_SIZE_PCT: ...` ✅
   - `FO_MAX_ITERATIONS: ...` ✅
   - `FO_NO_IMPROVEMENT: ...` ✅

3. **Optionally add** (for fine-tuning):
   - `RF_POLISH_RATIO: 0.2` (default is already 0.2)

---

## Questions?

**Q: Do I need to specify both `TIME_LIMIT` and `RF_RATIO` for hybrid?**
A: No, `RF_RATIO` defaults to 0.25 (25% for R&F, 75% for F&O). Only specify if you want a different split.

**Q: What if I want to give R&F exactly 900 seconds in hybrid mode?**
A: Calculate the ratio: `RF_RATIO = 900 / TIME_LIMIT`. For `TIME_LIMIT=3600`, that's `RF_RATIO = 0.25`.

**Q: Can I still use the old parameters?**
A: No, they have been completely removed from the codebase to prevent confusion.

**Q: Does `RF_POLISH_RATIO` apply to hybrid mode?**
A: Yes! It controls the time split within the R&F phase of hybrid.

---

## Implementation Details

For developers interested in the code changes:

- `engine/runners/run_epsilon.py`: Removed legacy argument parser entries
- `engine/mip/exact/multi_method/epsilon_method.py`: Added documentation, removed legacy fallbacks
- `engine/mip/matheuristics/relax_and_fix.py`: Added `polish_ratio` parameter
- `cluster/batch/batch_mip.py`: Removed legacy parameter mapping
- All YAML configs: Removed `RF_TIME_LIMIT` and `FO_TIME_LIMIT` lines

---

## Migration Script

If you have many YAML files to update, use this command:

```bash
# Remove legacy parameters from all YAML files
find cluster/configs -name "*.yaml" -type f -exec sed -i '/^  RF_TIME_LIMIT:/d; /^  FO_TIME_LIMIT:/d; /^  FO_TIME_LIMIT_PER_ITER:/d; /^  FO_DECOMPOSITION:/d; /^  FO_PHYSICIANS:/d' {} \;
```

---

**Last Updated:** 2026-01-29
