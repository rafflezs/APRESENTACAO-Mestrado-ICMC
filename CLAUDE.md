# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

LaTeX Beamer slide deck for a Master's degree defense (Final Master's Exam / "Defesa"), USP-ICMC. The deck at the repo root is currently a **verbatim copy of the qualification exam presentation** (`docs/refs/apresentacao_qualificacao/`) — `main.tex`, `customizacoes.tex`, `sections/*.tex` are byte-identical to that reference copy. The live task for this repo is to evolve this qualification deck into the **final defense deck**, reusing the template/theme but replacing content to match the finished dissertation (`docs/refs/dissertacao_tex/`), whose results are substantially more advanced than what the qualification slides show (see below).

## Build

No Makefile/latexmk config checked in. Compile with the standard ABNT sequence (uses `abntex2cite` + the bundled `abntex2-alf.bst`, so it needs classic BibTeX, not biber):

```
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex
```

Or, if `latexmk` is available: `latexmk -pdf -bibtex main.tex`.

## Structure

- `main.tex` — document class (`beamer`, `xcolor={dvipsnames}, 10pt, brazil`), title/author/date/advisor metadata, `\input{customizacoes}`, then `\include`s each file in `sections/` in order, then bibliography + acknowledgements + closing title frame.
- `customizacoes.tex` — all theme/styling: CambridgeUS theme, custom `UFTgreen/UFTblue/UFTyellow/UFTgray`/`PROFMATgreen` palette, custom title page layout (`\setbeamertemplate{title page}`), full-page background image (`img/modelo/bakcground.png`), ABNT citation setup, caption/spacing tweaks. Edit here for anything deck-wide (colors, fonts, title page layout); edit `sections/*.tex` for content.
- `sections/1-intro.tex` … `sections/5-conclusao.tex` — one file per `\section`, each a sequence of `\begin{frame}{...}` blocks. `99-outros.tex` exists but is **not** `\include`d from `main.tex` — it's leftover generic PROFMAT-template example content (theorems, parabola, SI units), safe to ignore/delete.
- `img/` — **flat** image directory actually referenced by the current slides (paths in `sections/*.tex` are always `img/...`, `img/modelo/...`, `img/modelo/tikz/...`). Only ~32 files, a subset of what's available.
- `assets/` (and `assets/images/`) — a superset image pool (~88 files) not yet wired into any `\includegraphics` call. It contains the newer figures generated for the dissertation (NSGA-II operator diagrams `01_sampling.png`…`05_encoding.png`, `exato_mipgap_heatmap_*`, `exato_pareto_overlay_*`, `exato_runtime_boxplot_*`, `escalabilidade_metodos.png`, `param_mip_barchart.png`, `param_nsga2_heatmap.png`, clinic-relationship diagrams, etc.). **When building the final deck, new figures should be copied/linked from `assets/images/` into `img/`** (flattening `images/` prefix) rather than referenced via `assets/`, to stay consistent with the existing path convention.
- `bibliografia.bib` / `abntex2-alf.bst` — bibliography source and the ABNT-ALF BibTeX style; keys generally follow `Author_Year` (e.g. `Liebel_2021`), cited via `\citeonline{...}` (abntex2cite).

## `docs/refs/` — reference material, not compiled

Read-only source material for building the final deck. Nothing under here is included by `main.tex`.

- `docs/refs/apresentacao_qualificacao/` — frozen copy of the qualification deck (identical to repo root's current state). Diff against root to see what's already been changed for the final version.
- `docs/refs/dissertacao_tex/` — full dissertation LaTeX source (ICMC abnTeX2 class), the primary content source for the final deck:
  - `main.tex` — dissertation skeleton + abstract (resumo/abstract) with the up-to-date, condensed summary of everything (methods, results, conclusions).
  - `references.bib` — **the master thesis bibliography**, 70 entries. Far more entries than root `bibliografia.bib` (8 entries — only what the old qualification deck cited). Pull citations from here when the final deck needs a source already used in the dissertation, rather than re-sourcing it — same BibTeX/`abntex2cite` format as root `bibliografia.bib`, so entries copy in directly.
  - `2-textual/introducao.tex`, `revisao.tex`, `problema.tex`, `heuristicas.tex`, `experimentos-resultados.tex`, `fechamento.tex` — one file per dissertation chapter (intro, lit. review, problem/math model, solution methods, experiments/results, conclusions).
  - `4-apendice/` — appendix chapters (per-instance dataset stats, detailed exact-method results).
  - `0-extras/` — small `\input`-ed table fragments (dataset stats, epsilon triplets per horizon) pulled into the chapter files above.
- `docs/refs/code/` — digests/analyses from the actual optimization codebase (separate repo), for grounding claims made in slides:
  - `project_tree.md` — architecture of the solver codebase (`engine/` = math_solver + heuristics(NSGA-II) + data_pipeline; `analytics/` = post-hoc evaluation/comparison/visualization; `bin/`/`cluster/` = local vs PBS-cluster execution).
  - `chapter3-digest.md` — English digest of the problem formulation (mirrors `problema.tex`, includes the `γ_{iud}` GLSP-based state variable for swap detection across schedule gaps).
  - `NSGA-2-limitacoes.md`, `analysis_compact_vs_exact_vs_extended.md`, `analysis_compact_nsga2_local_tests.md`, `analysis_pipeline_audit.md`, `parallelization_nsga2.md`, `branch_priority_guide.md` — pre-dissertation investigative notes on NSGA-II Extended vs Compact vs exact MIP performance/scalability.
  - `res-heuristicas-DIGEST.md` / `res-heuristicas-RESPONSE-DIGEST.md` — advisor (Maristela) feedback thread specifically about **NSGA-II factibility**: her objection that NSGA-II solutions can't be compared to the exact method unless proven feasible. Resolved in the final dissertation text (`experimentos-resultados.tex` / `fechamento.tex`): NSGA-II violates only the minimum-coverage constraint (C5/`eq:r6`), never the structural constraints (C1-C4), and this caveat is stated explicitly wherever NSGA-II is compared to exact/MIP-heuristic results. **Any slide comparing NSGA-II to other methods must carry this caveat too.**
  - `URGENTE_artefato_relaxacao.md` — documents one excluded 90-day outlier instance (`2023may01_to_2023jul29`) whose epsilon-grid was invalid due to root-node B&B stagnation; excluded from all final experiments. Don't resurrect its numbers.

## Content delta: qualification deck → dissertation (what must change)

The qualification deck (current `sections/*.tex`) reflects an early, mono-objective-leaning stage of the project (FO1/FO2 as separate mono-objective runs, FO3 hierarchical presented as an open question, only Gurobi exact results, small "resultados-gerais" table). The dissertation is bi-objective throughout and adds two entire method families plus a much larger experimental protocol:

- Math model: FO2 (trocas) now uses the `γ_{iud}` state-preservation variable (not in the quali version) to correctly detect swaps across non-working-day gaps.
- Solution methods: exact ε-restrito (unchanged in spirit) + **Relax-and-Fix / Fix-and-Optimize / Hybrid MIP-heuristics** (new) + **NSGA-II Extended and Compact** (new, with custom day-block crossover, slot-reassignment mutation, constraint-aware sampling).
- Experiments: 4 horizons (15/30/60/90 days) × 10 instances each (2 parametrization + 8 validation), metrics = hypervolume, Pareto-front amplitude, reference gap, MIP gap, runtime, NSGA-II feasibility rate — none of this exists in the quali deck yet.
- Headline results to carry into the final deck: regime transition between 15 and 30 days (exact only converges at 15d), Híbrido MIP-heuristic ≈ exact at short horizons, NSGA-II Compacto dominates NSGA-II Estendido everywhere, and the NSGA-II feasibility caveat above.
