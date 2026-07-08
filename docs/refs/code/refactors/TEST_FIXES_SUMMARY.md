# Test Fixes and Coverage Setup Summary

**Date:** 2026-02-03

## Issues Fixed

### 1. Test Method Signature Errors

**File:** `engine/metaheuristics/nsga2/tests/test_sampling.py`

**Issue:** Incorrect method signatures for `_count_unmet()` and `_count_swaps()`

```python
# BEFORE (incorrect - 2 parameters)
f1 = problem._count_unmet(var_x, var_w)
f2 = problem._count_swaps(var_x, var_w)

# AFTER (correct - 1 parameter each)
f1 = problem._count_unmet(var_x)
f2 = problem._count_swaps(var_w)
```

**Location:** Line 388-389

### 2. Removed Obsolete Stats Reference

**File:** `engine/metaheuristics/nsga2/tests/test_crossover.py`

**Issue:** Reference to `.stats` attribute that was removed in streamlining refactor

```python
# BEFORE
print(f"  Stats: {operator.stats}")

# AFTER
# Note: Stats tracking removed in streamlining refactor
```

**Location:** Line 499 (in standalone execution block)

## Coverage Setup

### Scripts Created

1. **run_coverage.sh** - Full test coverage (may be slow)
   - Runs all non-slow, non-integration tests
   - Generates HTML and terminal reports
   - Creates markdown summary in cov.md

2. **run_coverage_quick.sh** - Quick coverage (fast subset of tests)
   - Runs only 5-10 fast tests
   - Useful for quick feedback during development
   - Also generates cov.md

3. **scripts/generate_coverage_md.py** - Markdown generator
   - Converts coverage data to markdown format
   - Can be run separately after pytest
   - Usage: `python3 scripts/generate_coverage_md.py`

### Coverage Report Output

**File:** `cov.md` - Markdown coverage report

The report includes:
- Coverage summary table
- Instructions for viewing HTML report
- Command examples for running tests
- Notes about test performance

### Current Coverage Status

From quick subset (5 tests):
- **Overall:** 23% coverage
- **Operators:**
  - Mutation: 95% coverage
  - Sampling: 78% coverage
  - Crossover: 29% coverage
- **Core modules:**
  - Problem: 35% coverage
  - Constraint manager: 42% coverage
  - Constraints: 42% coverage

## Test Performance Notes

### Current Status

- **Individual tests:** Fast (2-9 seconds each)
- **Test files:** Slow (30+ seconds per file)
- **Full suite:** Very slow (timeout >2 minutes)

### Reason

- Session-scoped fixtures (instance, constraint_manager) are shared
- Function-scoped fixture (feasible_population) regenerated per test
- Each population generation takes ~5-8 seconds
- Multiple tests = cumulative time adds up

### Recommendations

1. **During development:** Run specific tests
   ```bash
   pytest engine/metaheuristics/nsga2/tests/test_mutation.py::test_slot_reassignment_feasibility -v
   ```

2. **For coverage:** Use quick subset
   ```bash
   bash run_coverage_quick.sh
   ```

3. **Before commits:** Run full suite (with patience)
   ```bash
   bash run_coverage.sh
   ```

4. **Skip slow tests:** Use markers
   ```bash
   pytest -m "not slow and not integration"
   ```

## Usage Examples

### Generate coverage report
```bash
# Activate environment
source venv/bin/activate

# Run tests with coverage
pytest engine/metaheuristics/nsga2/tests/ \\
    --cov=engine/metaheuristics/nsga2 \\
    --cov-report=html:htmlcov \\
    --cov-report=term \\
    -v

# Generate markdown report
python3 scripts/generate_coverage_md.py

# View results
cat cov.md                    # Markdown summary
open htmlcov/index.html       # Detailed HTML report
coverage report               # Terminal output
```

### Run specific test with coverage
```bash
source venv/bin/activate
pytest engine/metaheuristics/nsga2/tests/test_sampling.py::test_sampling_generates_solutions --cov -v
```

### Quick coverage check
```bash
bash run_coverage_quick.sh
```

## Files Modified

1. `engine/metaheuristics/nsga2/tests/test_sampling.py` - Fixed method signatures
2. `engine/metaheuristics/nsga2/tests/test_crossover.py` - Removed stats reference
3. `cov.md` - Coverage report (generated)
4. `run_coverage.sh` - Full coverage script (new)
5. `run_coverage_quick.sh` - Quick coverage script (new)
6. `scripts/generate_coverage_md.py` - Markdown generator (new)

## Next Steps

1. **Optimize test fixtures:** Consider caching feasible_population at session scope
2. **Add more unit tests:** Increase coverage for core modules
3. **Profile slow tests:** Identify and optimize bottlenecks
4. **CI/CD integration:** Set up automated coverage reporting

## Verification

All fixes verified by running:
- Individual test: `test_sampling_generates_solutions` - PASSED
- Individual test: `test_slot_reassignment_feasibility` - PASSED
- Quick subset (5 tests) - ALL PASSED
- Coverage report generation - SUCCESS

Current coverage: 23% (from quick subset)
Target coverage: 80%+ (recommended)
