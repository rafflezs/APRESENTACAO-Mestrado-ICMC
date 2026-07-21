# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

LaTeX Beamer slide deck for a Master's degree defense (Final Master's Exam / "Defesa"), USP-ICMC. It reuses the qualification exam's Beamer template/theme (`docs/refs/apresentacao_qualificacao/` is a frozen copy of that quali deck), but the **content is being rebuilt from scratch** to match the finished dissertation (`docs/refs/dissertacao_tex/`).

The deck is **in active development**, restructured into **6 sections** that mirror the dissertation chapters — with the **literature review folded into the Introdução** for narrative cohesion. Target: **~30 content slides / ~30 minutes**, excluding filler (title, section dividers, references, acknowledgements). Good academic storytelling is an explicit goal. `sections/*.tex` are currently **skeletons** — each holds a `\section{}` + a comment header describing intended content — and are filled/audited **one section at a time**, drawing content and figures from `docs/refs/`.

## Build

Uses `abntex2cite` + the bundled `abntex2-alf.bst`, so it needs classic BibTeX, not biber.

**Preferred — `latexmk` (config checked in):** a `.latexmkrc` is present. Just run:

```
latexmk -pdf -synctex=1 -interaction=nonstopmode main.tex
```

`.latexmkrc` sets `pdflatex` mode, routes aux files to `tmp/` (`$aux_dir`), and copies the final PDF to `out/main.pdf` (`$out_dir`), with SyncTeX on. Both `tmp/` and `out/` are generated dirs (git-ignored) — the compiled PDF lands in `out/`, **not** the repo root. `latexmk -c` cleans.

**Manual equivalent** (writes `.aux`/`.bbl`/`.pdf` to the repo root instead of `tmp`/`out`):

```
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex
```

## Structure

- `main.tex` — document class (`beamer`, `xcolor={dvipsnames}, 10pt, brazil`), title/author/date/advisor metadata, `\input{customizacoes}`, then `\include`s each file in `sections/` in order, then bibliography + acknowledgements + closing title frame.
- `customizacoes.tex` — all theme/styling: CambridgeUS theme, custom `UFTgreen/UFTblue/UFTyellow/UFTgray`/`PROFMATgreen` palette, custom title page layout (`\setbeamertemplate{title page}`), full-page background image (`img/modelo/bakcground.png`), ABNT citation setup, caption/spacing tweaks. Also loads `booktabs` and defines an `\AtBeginSection` **section-divider** frame (mini-TOC via `\tableofcontents[currentsection]`, highlighting the current section). Edit here for anything deck-wide (colors, fonts, title page layout, dividers); edit `sections/*.tex` for content.
- `sections/*.tex` — one file per `\section`, `\include`d in order by `main.tex`: `1-intro` (Introdução **+ literature/research gaps**), `2-definicao-problema` (Definição do Problema — formal model), `3-metodologia` (Metodologia e Abordagens — exact/MIP-heuristics/NSGA-II), `4-experimentos` (setup: environment, instances, protocol, metrics), `5-resultados` (Resultados e Discussão), `6-conclusao` (Conclusões e Perspectivas). Each is currently a `\section{}` + comment header (skeleton), filled one at a time. `99-outros.tex` is leftover generic PROFMAT example content, **not** `\include`d — ignore/delete.
- `img/` — **flat** image directory referenced by the slides (paths are always `img/...`, `img/modelo/...`). Now holds the dissertation figures (copied from `assets/images/`, flattening the `images/` prefix) plus the custom `lacuna-literatura.png` (research-gap matrix built for the Introdução).
- `assets/` (and `assets/images/`) — the original superset image pool. It contains the dissertation figures (NSGA-II operator diagrams `01_sampling.png`…`05_encoding.png`, `exato_mipgap_heatmap_*`, `exato_pareto_overlay_*`, `exato_runtime_boxplot_*`, `escalabilidade_metodos.png`, `param_mip_barchart.png`, `param_nsga2_heatmap.png`, `pareto_comparativo_*`, clinic-relationship diagrams, etc.). **When a new figure is needed, copy it from `assets/images/` into `img/`** (flattening `images/`) rather than referencing `assets/` directly, to keep the `img/...` path convention.
- `references.bib` (repo root, **70 entries**) — the **active** bibliography; `main.tex` uses `\bibliography{references}`. Copied from `docs/refs/dissertacao_tex/references.bib` (the master thesis bib). `bibliografia.bib` (8 entries) is the legacy quali bib, no longer referenced. `abntex2-alf.bst` is the ABNT-ALF BibTeX style; keys follow `Author_Year` (e.g. `Deb_Pratap_Agarwal_Meyarivan_2002`), cited via `\cite{...}`/`\citeonline{...}` (abntex2cite → classic BibTeX). Note: dissertation-text keys sometimes differ from the legacy quali keys (e.g. `MedicinaSA2024` vs `MedicinaSA_2024`); pull the key from `references.bib`.
- `.latexmkrc` — latexmk config (see Build): `pdflatex` mode, `$aux_dir='tmp'`, `$out_dir='out'`, SyncTeX on, and an `END` block copying `tmp/*.pdf` → `out/`. Compiled output goes to `out/main.pdf`; `tmp/` and `out/` are generated (not source).

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

## Narrative target & headline content

The study is **bi-objective** throughout: minimize unmet exams (`Z1`) and clinic swaps (`Z2`), solved via the **ε-constraint** method, across three method families. Storytelling arc, section by section: imaging matters but physician scarcity + manual multi-unit scheduling is a costly combinatorial problem the literature barely addresses (**gap**) → formalize it, with a `γ_{iud}` state variable (GLSP-adapted) needed to detect swaps across schedule gaps → three solution families → how we tested (real data, 4 horizons, 2-stage protocol) → what we found → what it means.

Substance to land (all sourced from `docs/refs/dissertacao_tex/2-textual/`):

- **Model:** `Z1` (unmet exams) + `Z2` (swaps); swap detection uses the `γ_{iud}` state-preservation variable so swaps across non-working-day gaps are counted correctly.
- **Methods:** exact ε-constraint (Gurobi) + **Relax-and-Fix / Fix-and-Optimize / Hybrid** MIP-heuristics + **NSGA-II Extended and Compact** (custom day-block crossover, slot-reassignment mutation, constraint-aware sampling; Compact ≈ w-only encoding, ~70× smaller chromosome).
- **Experiments:** 4 horizons (15/30/60/90 d) × 10 instances (2 parametrization + 8 validation); metrics = hypervolume, Pareto amplitude, reference gap, MIP gap, runtime, NSGA-II feasibility.
- **Headline results:** regime transition between 15 and 30 days (exact converges only at 15 d; MIP gap 4%→97% by 90 d), Híbrido ≈ exact at short horizons, NSGA-II Compacto dominates Estendido everywhere, NSGA-II ~7× faster than the MIP family.
- **NSGA-II feasibility caveat (must appear wherever NSGA-II is compared):** NSGA-II violates only minimum-coverage (C5/`eq:r6`), never structural C1–C4 → not directly comparable to exact/MIP-heuristic fronts; present its results as trends/trade-offs and point to repair operators as future work (see `docs/refs/code/res-heuristicas-*`).

## Rules

- Prioritize visual storytelling over text-heavy slides. Use figures from `img/` (copied from `assets/images/`) wherever possible. Avoid tables of numbers unless they are **key results** (e.g., Pareto front comparisons, hypervolume metrics).
  - When a given figure is not present, generate a paste-ready prompt with context and file reference for Claude Design. Ask the user to inform you when the figure is ready, then continue.
- Avoid text-heavy slides. Use bullet points, not paragraphs. Keep each slide to **≤ 6 lines of text** (ideally ≤ 5). Avoid long sentences; use concise phrases.
- Avoid block-heavt slides with `\begin{block}{}`, unless when necessary for key definition or finding.
- Avoid monotonous slide layouts.