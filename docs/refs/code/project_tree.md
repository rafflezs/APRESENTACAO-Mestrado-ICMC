# Arquitetura do Projeto - Alocação de Médicos

Este documento descreve a estrutura modular do projeto, separando responsabilidades entre resolução de problemas (engine), análise de resultados (analytics), execução (runners/pipelines) e infraestrutura de cluster.

## 🎯 Visão Geral da Arquitetura

O projeto implementa múltiplas abordagens para o problema de alocação de médicos:
1. **Meta-heurística NSGA-II** - Algoritmo genético multiobjetivo
2. **Programação Matemática (Gurobi)** - Solver exato MIP
3. **Método Épsilon-restrito** - Técnica multiobjetivo baseada em MIP

Todos os métodos compartilham a mesma interface através de `InstanceObject`, permitindo execução independente e modular.

---

## Estrutura Geral

```
.
├── analytics
│   ├── analysis
│   │   ├── epsilon_analyzer.py
│   │   ├── gantt_generator.py
│   │   ├── __init__.py
│   │   ├── MANUAL_metrics_collector.md
│   │   ├── metrics_collector.py
│   │   └── solution_analyzer.py
│   ├── comparison
│   │   ├── epsilon_scenario_analyzer.py
│   │   ├── __init__.py
│   │   ├── method_comparator.py
│   │   ├── pareto_analyzer.py
│   │   ├── primary_objective_comparator.py
│   │   └── tradeoff_analyzer.py
│   ├── etl
│   │   └── data_reader.py
│   ├── evaluators
│   │   ├── coverage.py
│   │   ├── example_usage.py
│   │   ├── idle_physicians.py
│   │   ├── idle_rooms.py
│   │   ├── __init__.py
│   │   ├── README.md
│   │   ├── swaps.py
│   │   └── unattended_exams.py
│   ├── performance
│   │   └── computational_performance_analyzer.py
│   ├── runners
│   │   ├── run_analysis.py
│   │   └── run_retrospective_analysis.py
│   ├── sensitivity
│   │   └── sensitivity_analyzer.py
│   ├── summaries
│   │   ├── extra
│   │   │   └── summary_operations.py
│   │   ├── parser
│   │   │   ├── general_summary.py
│   │   │   ├── gurobi_summary.py
│   │   │   ├── obj_summary.py
│   │   │   └── run_summary.py
│   │   ├── cross_experiment_analyzer.py
│   │   └── summary_pipeline.py
│   ├── visualization
│   │   ├── gantt_chart.py
│   │   ├── __init__.py
│   │   ├── pareto_plotter.py
│   │   └── solution_plotter.py
│   ├── __init__.py
│   └── README.md
├── bin
│   ├── config
│   │   ├── epsilon
│   │   │   ├── epsilon_30days_all.yaml
│   │   │   ├── epsilon_3days_exams.yaml
│   │   │   ├── epsilon_3days_swaps.yaml
│   │   │   └── epsilon_5days_all.yaml
│   │   └── nsga2
│   │       ├── nsga2_15days.yaml
│   │       ├── nsga2_30days.yaml
│   │       └── nsga2_90days.yaml
│   ├── run-epsilon-local
│   └── run-nsga2-local
├── cluster
│   ├── configs
│   │   ├── epsilon_exams
│   │   │   ├── epsilon_15days_exams.yaml
│   │   │   ├── epsilon_30days_exams.yaml
│   │   │   ├── epsilon_60days_exams.yaml
│   │   │   └── epsilon_90days_exams.yaml
│   │   └── epsilon_swaps
│   │       ├── epsilon_15days_swaps.yaml
│   │       ├── epsilon_30days_swaps.yaml
│   │       ├── epsilon_60days_swaps.yaml
│   │       └── epsilon_90days_swaps.yaml
│   ├── pbs
│   │   └── euler_exact_batch.pbs
│   ├── batch_nsga2.py
│   ├── batch_mip.py
│   ├── README.md
│   └── submit_euler.sh
├── docs
│   ├── algoritmos
│   │   ├── crossover.md
│   │   └── sampling.md
│   ├── next-chat
│   │   └── chat_handover_crossover.md
│   ├── summary-chat
│   │   ├── context-deadline.md
│   │   ├── DESIGN-ca_sampling_ref.md
│   │   ├── handover_document_sampling_to_operators.md
│   │   ├── LITERATURE-crossover.md
│   │   ├── LITERATURE-genetic_diversity.md
│   │   ├── LITERATURE-mutation.md
│   │   ├── LITERATURE-nsga2-alternatives.md
│   │   ├── LITERATURE-nsga2_implementations.md
│   │   ├── LITERATURE-operator_design.md
│   │   └── LITERATURE-sampling.md
│   ├── branch_priority_guide.md
│   ├── chapter3-digest.md
│   ├── new_rules.docx
│   └── project_tree.md
├── engine
│   ├── data_pipeline
│   │   ├── input_loader
│   │   │   ├── csv_data_reader.py
│   │   │   ├── csv_instance_loader.py
│   │   │   ├── data_loader.py
│   │   │   ├── excel_data_reader.py
│   │   │   ├── instance_reader.py
│   │   │   └── json_instance_loader.py
│   │   └── output_writer
│   │       ├── gurobi_output_writer.py
│   │       └── output_writer.py
│   ├── heuristics
│   │   ├── analysis
│   │   │   ├── constraint_violation_analyzer.py
│   │   │   ├── convergence_analyzer.py
│   │   │   ├── __init__.py
│   │   │   └── results_analyzer.py
│   │   ├── core
│   │   │   ├── constraint_manager.py
│   │   │   ├── constraints.py
│   │   │   ├── __init__.py
│   │   │   └── problem.py
│   │   ├── diagnostics
│   │   │   ├── diversity_collapse.py
│   │   │   ├── repair_tracker.py
│   │   │   ├── slot_analyzer.py
│   │   │   └── solution_validator.py
│   │   ├── monitoring
│   │   │   ├── diversity_monitor.py
│   │   │   ├── evolution_logger.py
│   │   │   ├── __init__.py
│   │   │   ├── operator_tracker.py
│   │   │   └── operator_tracking_callback.py
│   │   ├── operators
│   │   │   ├── constraint_aware_crossover.py
│   │   │   ├── constraint_aware_mutation.py
│   │   │   ├── constraint_aware_sampling.py
│   │   │   └── __init__.py
│   │   ├── tests
│   │   │   ├── conftest.py
│   │   │   ├── test_crossover.py
│   │   │   ├── test_mutation.py
│   │   │   ├── test_sampling.py
│   │   │   └── test_utils.py
│   │   ├── vendor
│   │   │   └── fixed_callback_collection.py
│   │   └── __init__.py
│   ├── math_solver
│   │   ├── analytics
│   │   │   ├── branch_priority_analyzer.py
│   │   │   ├── gurobi_analyzer.py
│   │   │   ├── __init__.py
│   │   │   └── README_BRANCH_PRIORITY.md
│   │   ├── math_model
│   │   │   ├── constraints.py
│   │   │   ├── model.py
│   │   │   └── objs.py
│   │   └── solver_model
│   │       ├── mono_solver.py
│   │       └── multi_solver.py
│   ├── problem
│   │   ├── dataclass
│   │   │   ├── clinic_class.py
│   │   │   └── physician_class.py
│   │   ├── instance
│   │   │   ├── instance_factory.py
│   │   │   └── instance_object.py
│   │   └── __init__.py
│   ├── runners
│   │   ├── run_epsilon.py
│   │   └── run_nsga2.py
│   └── scripting
│       ├── debug_wrapper.py
│       ├── hyperparameter_auxiliar.py
│       ├── test_constraint_analyzer.py
│       └── test_gamma_model.sh
├── extra
│   ├── euler_1_exemplo.sh
│   ├── euler_2_exemplo.sh
│   └── relax_and_fix_exemplo_1.md
├── logs
│   ├── euler
│   │   ├── 4085287.icex.OU
│   │   ├── 4085288.icex.OU
│   │   ├── 4085289.icex.OU
│   │   ├── 4085290.icex.OU
│   │   ├── 4085291.icex.OU
│   │   ├── 4085292.icex.OU
│   │   ├── 4085293.icex.OU
│   │   └── 4085294.icex.OU
│   └── mutation_test.log
├── notebooks
│   ├── ARTIGO-SBPO2025.ipynb
│   ├── nsga2-test.ipynb
│   ├── QUALIFICACAO-analise1-gantt.ipynb
│   ├── QUALIFICACAO-analise-caso-gantt.ipynb
│   └── QUALIFICACAO-analise-resultados.ipynb
├── pipelines
│   └── run_epsilon_pipeline.py
├── .pytest_cache
│   ├── v
│   │   └── cache
│   │       ├── lastfailed
│   │       └── nodeids
│   ├── CACHEDIR.TAG
│   └── README.md
├── scripts
│   ├── templates/
│   ├── testing
│   │   ├── test_branch_priorities.py
│   │   ├── test_gantt_real_data.py
│   │   └── test_loaders.py
│   ├── utils
│   │   ├── aggregate_epsilon_results.py
│   │   └── create_yaml_model.py
│   ├── analyze_branch_priority_batch.py
│   └── compare_primary_objectives.sh
├── README.md
├── requirements.txt
└── TODO.md
```

## 📂 Estrutura de Diretórios

### `engine/` - Motor de Resolução
**Responsabilidade:** Implementações dos métodos de otimização e suas dependências diretas.

```
engine/
├── data_pipeline/          # I/O de dados
│   ├── input_loader/       # Leitura de instâncias (CSV, Excel, JSON)
│   │   ├── csv_instance_loader.py      # Carrega dados de CSV
│   │   ├── excel_data_reader.py        # Lê dados brutos do Excel
│   │   └── instance_reader.py          # Interface unificada de leitura
│   └── output_writer/      # Persistência de resultados
│       ├── gurobi_output_writer.py     # Salva soluções MIP (CSVs + JSON)
│       └── output_writer.py            # Interface abstrata de escrita
│
├── problem/                # Definição do problema
│   ├── dataclass/          # Estruturas de dados do domínio
│   │   ├── clinic_class.py             # Dados de clínicas/salas
│   │   └── physician_class.py          # Dados de médicos
│   └── instance/           # Representação de instâncias
│       ├── instance_factory.py         # Criação de instâncias
│       └── instance_object.py          # INTERFACE COMUM - Usada por todos os métodos
│
├── heuristics/             # NSGA-II e operadores genéticos
│   ├── core/
│   │   ├── problem.py                  # Classe Problem do pymoo adaptada
│   │   └── constraint_manager.py       # Gestão de restrições do problema
│   ├── operators/          # Operadores genéticos customizados
│   │   ├── constraint_aware_sampling.py    # Sampling inicial viável
│   │   ├── constraint_aware_crossover.py   # Crossover que respeita restrições
│   │   └── constraint_aware_mutation.py    # Mutação com reparo
│   ├── monitoring/         # Rastreamento da evolução
│   │   ├── diversity_monitor.py        # Monitora diversidade genética
│   │   ├── evolution_logger.py         # Logs de gerações
│   │   └── operator_tracker.py         # Estatísticas de operadores
│   ├── diagnostics/        # Ferramentas de depuração
│   │   ├── diversity_collapse.py       # Detecta convergência prematura
│   │   ├── solution_validator.py       # Valida factibilidade
│   │   └── slot_analyzer.py            # Analisa alocações por slot
│   └── analysis/           # Análise de resultados NSGA-II
│       ├── convergence_analyzer.py     # Métricas de convergência
│       └── constraint_violation_analyzer.py
│
├── math_solver/            # Programação Matemática (Gurobi)
│   ├── math_model/         # Definição do modelo MIP
│   │   ├── model.py                    # GurobiModel - classe principal
│   │   ├── constraints.py              # Implementação de restrições
│   │   └── objs.py                     # Funções objetivo
│   ├── solver_model/       # Estratégias de resolução
│   │   ├── mono_solver.py              # Resolução mono-objetivo
│   │   └── multi_solver.py             # Resolução multiobjetivo (épsilon)
│   └── analytics/          # Análise específica do Gurobi
│       ├── gurobi_analyzer.py          # Estatísticas do solver
│       └── branch_priority_analyzer.py # Análise de prioridades de branching
│
├── runners/                # Scripts de execução de alto nível
│   ├── run_nsga2.py                    # Pipeline NSGA-II
│   └── run_epsilon.py                  # Pipeline Método Épsilon
│
└── scripting/              # Utilitários de desenvolvimento
    ├── debug_wrapper.py                # Wrapper para debugging
    └── hyperparameter_auxiliar.py      # Auxiliar de hiperparâmetros
```

**Pipeline típico no `engine/`:**
```
InstanceObject (problem/instance) 
    ↓
Método escolhido (heuristics/ OU math_solver/)
    ↓
OutputWriter (data_pipeline/output_writer)
```

---

### `analytics/` - Análise de Resultados
**Responsabilidade:** Processamento, comparação e visualização de resultados de experimentos.

```
analytics/
├── etl/
│   └── data_reader.py              # Leitura de CSVs de resultados
│
├── evaluators/             # Cálculo de métricas de qualidade
│   ├── coverage.py                 # Taxa de cobertura de exames
│   ├── idle_physicians.py          # Médicos ociosos
│   ├── idle_rooms.py               # Salas ociosas
│   ├── swaps.py                    # Contagem de trocas
│   └── unattended_exams.py         # Exames não atendidos
│
├── analysis/               # Análise individual de soluções
│   ├── solution_analyzer.py        # Análise detalhada de uma solução
│   ├── gantt_generator.py          # Geração de gráficos de Gantt
│   └── metrics_collector.py        # Coleta de métricas agregadas
│
├── comparison/             # Comparação entre métodos
│   ├── method_comparator.py        # Comparação NSGA-II vs Gurobi
│   ├── pareto_analyzer.py          # Análise de fronteiras de Pareto
│   ├── epsilon_scenario_analyzer.py # Comparação de cenários épsilon
│   └── tradeoff_analyzer.py        # Análise de trade-offs
│
├── summaries/              # Agregação de resultados
│   ├── parser/
│   │   ├── gurobi_summary.py       # Parseia logs do Gurobi
│   │   ├── obj_summary.py          # Sumariza objetivos
│   │   └── run_summary.py          # Sumariza execuções
│   ├── summary_pipeline.py         # Pipeline de geração de sumários
│   └── cross_experiment_analyzer.py # Análise cross-experiment
│
├── visualization/          # Plotagem de resultados
│   ├── gantt_chart.py              # Gráficos de Gantt
│   ├── pareto_plotter.py           # Plotagem de fronteiras de Pareto
│   └── solution_plotter.py         # Visualização geral de soluções
│
├── performance/
│   └── computational_performance_analyzer.py # Tempo, memória, gap
│
├── sensitivity/
│   └── sensitivity_analyzer.py     # Análise de sensibilidade de parâmetros
│
└── runners/
    ├── run_analysis.py             # Análise pós-execução
    └── run_retrospective_analysis.py # Análise retrospectiva de batches
```

**Pipeline típico no `analytics/`:**
```
CSVs de resultados (output do engine/)
    ↓
etl/data_reader.py
    ↓
evaluators/ (métricas) + analysis/ (análise detalhada)
    ↓
comparison/ (comparação entre métodos)
    ↓
visualization/ (gráficos e plots)
```

---

### `bin/` - Executáveis Locais
**Responsabilidade:** Scripts bash para execução rápida em ambiente local.

```
bin/
├── config/                 # Configurações YAML
│   ├── epsilon/
│   │   ├── epsilon_30days_all.yaml     # 30 dias, todos objetivos
│   │   ├── epsilon_3days_exams.yaml    # 3 dias, foco em exames
│   │   └── epsilon_5days_all.yaml      # 5 dias, todos objetivos
│   └── nsga2/
│       ├── nsga2_15days.yaml           # NSGA-II, 15 dias
│       ├── nsga2_30days.yaml           # NSGA-II, 30 dias
│       └── nsga2_90days.yaml           # NSGA-II, 90 dias
│
├── run-epsilon-local       # Executa método épsilon localmente
└── run-nsga2-local         # Executa NSGA-II localmente
```

**Uso:**
```bash
# Executar NSGA-II com configuração de 30 dias
./bin/run-nsga2-local bin/config/nsga2/nsga2_30days.yaml

# Executar método épsilon com 3 dias
./bin/run-epsilon-local bin/config/epsilon/epsilon_3days_exams.yaml
```

---

### `cluster/` - Infraestrutura de Cluster
**Responsabilidade:** Submissão de jobs em lote no cluster Euler (PBS).

```
cluster/
├── configs/                # Configurações para cluster
│   ├── epsilon_exams/
│   │   ├── epsilon_15days_exams.yaml
│   │   ├── epsilon_30days_exams.yaml
│   │   ├── epsilon_60days_exams.yaml
│   │   └── epsilon_90days_exams.yaml
│   └── epsilon_swaps/
│       ├── epsilon_15days_swaps.yaml
│       └── ... (30, 60, 90 dias)
│
├── pbs/
│   └── euler_exact_batch.pbs # Template PBS para Euler
│
├── batch_mip.py         # Submissão de múltiplos jobs
├── batch_nsga2.py          # Batch específico NSGA-II
└── submit_euler.sh         # Wrapper para submissão
```

**Uso:**
```bash
# Submeter batch de experimentos épsilon
python cluster/batch/batch_mip.py --config cluster/configs/epsilon_exams/*.yaml

# Submeter NSGA-II
python cluster/batch/batch_nsga2.py --days 30 --pop 100
```

---

### `pipelines/` - Pipelines de Alto Nível
**Responsabilidade:** Orquestração de execuções complexas (múltiplas instâncias, múltiplos parâmetros).

```
pipelines/
└── run_epsilon_pipeline.py # Executa método épsilon para múltiplas configurações
```

**Diferença entre `runners/` e `pipelines/`:**
- `engine/runners/`: Execução **única** (uma instância, uma configuração)
- `pipelines/`: Execução **em lote** (múltiplas instâncias, grid search de parâmetros)

---

### `scripts/` - Utilitários e Templates
**Responsabilidade:** Scripts auxiliares para criação de templates, testes e análises.

```
scripts/
├── templates/
│
├── testing/                        # Scripts de teste ad-hoc
│   ├── test_branch_priorities.py  # Testa prioridades de branching
│   ├── test_gantt_real_data.py    # Testa geração de Gantt
│   └── test_loaders.py             # Testa carregadores de dados
│
├── utils/
│   ├── aggregate_epsilon_results.py # Agrega resultados épsilon
│   └── create_yaml_model.py        # Gera YAMLs de modelos
│
├── analyze_branch_priority_batch.py # Análise em lote de prioridades
└── compare_primary_objectives.sh   # Compara objetivos primários
```

---

### `docs/` - Documentação Técnica
**Responsabilidade:** Documentação de algoritmos, decisões de design e contexto do projeto.

```
docs/
├── algoritmos/             # Explicação de implementações
│   ├── crossover.md                # Design do crossover
│   └── sampling.md                 # Design do sampling inicial
│
├── summary-chat/           # Resumos de discussões com LLMs
│   ├── DESIGN-ca_sampling_ref.md   # Design do sampling constraint-aware
│   ├── LITERATURE-crossover.md     # Literatura sobre crossover
│   └── LITERATURE-nsga2_implementations.md
│
├── next-chat/              # Contexto para próximas conversas
│   └── chat_handover_crossover.md  # Handover sobre crossover
│
├── branch_priority_guide.md # Guia de prioridades de branching
├── chapter3-digest.md       # Resumo do capítulo 3 da tese
└── project_tree.md          # Este arquivo
```

---

### `notebooks/` - Análises Interativas
**Responsabilidade:** Notebooks Jupyter para análise exploratória e geração de visualizações.

```
notebooks/
├── ARTIGO-SBPO2025.ipynb               # Análises para artigo SBPO
├── QUALIFICACAO-analise1-gantt.ipynb   # Gráficos de Gantt para qualificação
├── QUALIFICACAO-analise-caso-gantt.ipynb
├── QUALIFICACAO-analise-resultados.ipynb
└── nsga2-test.ipynb                    # Testes do NSGA-II
```

---

### `logs/` - Logs de Execução
**Responsabilidade:** Armazenamento de logs de execuções (local e cluster).

```
logs/
├── euler/                  # Logs do cluster Euler
│   ├── 4085287.icex.OU
│   └── ... (outros jobs)
└── mutation_test.log       # Logs locais de testes
```

---

### `extra/` - Exemplos e Tutoriais
**Responsabilidade:** Scripts de exemplo e tutoriais.

```
extra/
├── euler_1_exemplo.sh              # Exemplo de submissão PBS
├── euler_2_exemplo.sh
└── relax_and_fix_exemplo_1.md      # Tutorial de heurísticas MIP
```

---

## 🔄 Fluxos Principais

### 1. Execução NSGA-II

```
Preparação:
    bin/config/nsga2/nsga2_30days.yaml
        ↓
Execução:
    bin/run-nsga2-local (chama engine/runners/run_nsga2.py)
        ↓
Engine:
    InstanceObject ← csv_instance_loader.py
        ↓
    Problem (heuristics/core/problem.py)
        ↓
    NSGA-II com operadores (heuristics/operators/)
        ↓
    output_writer.py → results/nsga2/30days/*.csv
        ↓
Análise:
    analytics/runners/run_analysis.py
        ↓
    Métricas (analytics/evaluators/) + Plots (analytics/visualization/)
```

### 2. Execução Método Épsilon

```
Preparação:
    bin/config/epsilon/epsilon_3days_exams.yaml
        ↓
Execução:
    bin/run-epsilon-local (chama engine/runners/run_epsilon.py)
        ↓
Engine:
    InstanceObject ← csv_instance_loader.py
        ↓
    GurobiModel (math_solver/math_model/model.py)
        ↓
    MultiSolver com EpsilonMethod (math_solver/solver_model/)
        ↓
    gurobi_output_writer.py → results/epsilon/3days/*.csv
        ↓
Análise:
    analytics/comparison/epsilon_scenario_analyzer.py
        ↓
    Fronteira de Pareto (analytics/visualization/pareto_plotter.py)
```

### 3. Execução em Cluster (Batch)

```
Preparação:
    cluster/configs/epsilon_exams/epsilon_30days_exams.yaml
        ↓
Submissão:
    cluster/batch/batch_mip.py
        ↓
    cluster/pbs/euler_exact_batch.pbs (template PBS)
        ↓
Cluster Euler:
    Job executado → logs/euler/JOBID.icex.OU
        ↓
    Resultados → results/ (diretório compartilhado)
        ↓
Coleta:
    analytics/runners/run_retrospective_analysis.py
        ↓
    analytics/summaries/cross_experiment_analyzer.py
```

### 4. Análise Comparativa

```
Resultados de múltiplos métodos:
    results/nsga2/*.csv + results/epsilon/*.csv
        ↓
Agregação:
    analytics/summaries/summary_pipeline.py
        ↓
Comparação:
    analytics/comparison/method_comparator.py
        ↓
Visualização:
    notebooks/ARTIGO-SBPO2025.ipynb
```

---

## 🧩 Princípios de Design

### 1. **Modularidade**
- Cada método de otimização é **independente** (NSGA-II não depende de Gurobi e vice-versa)
- Interface comum através de `InstanceObject` permite trocar métodos sem alterar código

### 2. **Separação de Responsabilidades**
- `engine/`: **Resolução** do problema
- `analytics/`: **Análise** de resultados
- `bin/` + `cluster/`: **Execução** (local e remota)
- `scripts/`: **Utilitários** auxiliares

### 3. **Configuração Declarativa**
- Parâmetros em arquivos YAML (`bin/config/`, `cluster/configs/`)
- Permite reprodutibilidade e versionamento de experimentos

### 4. **Pipeline Extensível**
- Novos métodos devem:
  1. Implementar interface de `InstanceObject`
  2. Criar runner em `engine/runners/`
  3. Adicionar configuração em `bin/config/`
  4. (Opcional) Adicionar script batch em `cluster/`

---

## 🚀 Como Adicionar uma MIP Heurística (Relax-and-Fix / Fix-and-Optimize)

Seguindo os princípios de design:

### 1. Criar módulo em `engine/math_solver/`

```
engine/math_solver/
└── mip_heuristics/         # NOVO
    ├── __init__.py
    ├── base_heuristic.py           # Classe base abstrata
    ├── relax_and_fix.py            # Implementação R&F
    └── fix_and_optimize.py         # Implementação F&O
```

**Características:**
- Recebe `GurobiModel` como entrada (reutiliza modelo existente)
- Retorna solução no mesmo formato que `MultiSolver`
- Independente: pode ser executada sem NSGA-II

### 2. Criar runner em `engine/runners/`

```python
# engine/runners/run_relax_and_fix.py
from engine.math_solver.mip_heuristics.relax_and_fix import RelaxAndFix
from engine.data_pipeline.output_writer.gurobi_output_writer import GurobiOutputWriter

def main(config_path):
    # 1. Setup (igual run_epsilon.py)
    instance = setup_instance(config_path)
    model = GurobiModel(instance)
    
    # 2. Executar heurística
    heuristic = RelaxAndFix(model, window_size=7)  # rolling horizon de 7 dias
    solution = heuristic.solve()
    
    # 3. Salvar resultados
    writer = GurobiOutputWriter(output_dir="results/relax_and_fix/")
    writer.write(solution)
```

### 3. Adicionar configuração em `bin/config/`

```yaml
# bin/config/mip_heuristics/rf_30days.yaml
instance:
  data_path: "data/instances/30days.csv"
heuristic:
  type: "relax_and_fix"
  window_size: 7
  overlap: 2
  time_limit_per_window: 300
output:
  directory: "results/relax_and_fix/30days/"
```

### 4. Criar script de execução

```bash
# bin/run-mip-heuristics-local
#!/bin/bash
python -m engine.runners.run_relax_and_fix $1
```

### 5. (Opcional) Adicionar batch para cluster

```python
# cluster/batch_mip_heuristics.py
# Similar a batch_mip.py, mas para heurísticas MIP
```

---

## 📊 Estrutura de Resultados

```
results/
├── nsga2/
│   └── 30days/
│       ├── solutions.csv           # Soluções da fronteira de Pareto
│       ├── objectives.csv          # Valores dos objetivos
│       └── convergence.csv         # Histórico de convergência
│
├── epsilon/
│   └── 3days_exams/
│       ├── epsilon_points.csv      # Soluções para cada ε
│       ├── pareto_front.csv        # Fronteira de Pareto
│       └── gurobi_logs/            # Logs do Gurobi para cada ε
│
└── mip_heuristics/                 # NOVO (estrutura sugerida)
    ├── relax_and_fix/
    │   └── 30days/
    │       ├── final_solution.csv  # Solução final
    │       ├── intermediate/       # Soluções intermediárias (por janela)
    │       └── rf_summary.csv      # Resumo (tempo, gap, janelas)
    └── fix_and_optimize/
        └── 30days/
            ├── final_solution.csv
            └── fo_summary.csv
```

---

## 🧪 Testes

```
engine/heuristics/tests/        # Testes unitários de operadores NSGA-II
scripts/testing/                # Testes ad-hoc de componentes
```

**Executar testes:**
```bash
pytest engine/heuristics/tests/
python scripts/testing/test_loaders.py
```

---

## 📝 Convenções de Nomenclatura

- **Diretórios**: `snake_case` (ex: `math_solver`, `output_writer`)
- **Arquivos Python**: `snake_case` (ex: `gurobi_model.py`, `run_nsga2.py`)
- **Classes**: `PascalCase` (ex: `GurobiModel`, `RelaxAndFix`)
- **Funções/Métodos**: `snake_case` (ex: `setup_instance()`, `solve()`)
- **Constantes**: `UPPER_SNAKE_CASE` (ex: `MAX_ITERATIONS`)
- **Configurações**: `snake_case` com sufixo descritivo (ex: `nsga2_30days.yaml`)

---

## 🔗 Dependências Principais

- **Otimização**: `gurobipy` (MIP), `pymoo` (NSGA-II)
- **Dados**: `pandas`, `numpy`
- **Visualização**: `matplotlib`, `plotly`
- **Configuração**: `pyyaml`
- **Cluster**: PBS (Portable Batch System)

---

## 📚 Referências Rápidas

- **Como executar localmente**: Ver `bin/README.md` (se existir) ou `bin/run-*-local`
- **Como submeter ao cluster**: Ver `cluster/README.md`
- **Como analisar resultados**: Ver `analytics/README.md`
- **Design de operadores**: Ver `docs/algoritmos/`
- **Contexto de decisões**: Ver `docs/summary-chat/`