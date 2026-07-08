# Refatoração da Estrutura de Pastas - Output Directory

## Data: 16 de dezembro de 2025

## Objetivo

Padronizar a estrutura de saída de todos os métodos de otimização (Epsilon-Constraint, NSGA2, Matheuristics) para utilizar apenas duas subpastas dentro do `OUTPUT_DIR` especificado no YAML:
- `solution/` - Contém todos os arquivos de solução (.csv, .json, .sol)
- `analysis/` - Contém todos os arquivos de análise (gráficos, tabelas, relatórios)

## Estrutura Antiga

Antes, cada método criava uma estrutura diferente:

### Epsilon-Constraint (Antigo)
```
OUTPUT_DIR/
├── swaps/                    # Pasta criada automaticamente baseada em PRIMARY_OBJECTIVE
│   ├── eps0/
│   │   └── optimization/
│   │       ├── allocation.csv
│   │       └── ...
│   ├── eps1/
│   └── pareto_plot.png
```

### NSGA2 (Antigo)
```
OUTPUT_DIR/
├── evolution.png
├── diversity_diagnostics.png
├── pareto_solutions.csv
└── ...
```

## Estrutura Nova

Agora, **todos os métodos** seguem o mesmo padrão:

### Epsilon-Constraint (Novo)
```
OUTPUT_DIR/                   # Pasta especificada pelo usuário no YAML
├── solution/
│   ├── eps0/
│   │   ├── allocation.csv
│   │   ├── coverage.csv
│   │   ├── results.json
│   │   ├── solution.sol
│   │   └── ...
│   ├── eps1/
│   ├── swaps_epsilon_solutions.csv
│   └── swaps_summary_stats.txt
└── analysis/
    ├── pareto_plot.png
    ├── pareto_front.csv
    └── pareto_front_metrics.csv
```

### NSGA2 (Novo)
```
OUTPUT_DIR/
├── solution/
│   ├── pareto_solutions.csv
│   ├── evolution_logs.csv
│   └── experiment_config.json
└── analysis/
    ├── evolution.png
    └── diversity_diagnostics.png
```

### Matheuristics (Novo)
```
OUTPUT_DIR/
├── solution/
│   ├── allocation.csv
│   ├── coverage.csv
│   └── ...
└── analysis/
    ├── gantt_*.png
    └── metrics.json
```

## Alterações Implementadas

### 1. Engine - Epsilon Method
**Arquivo:** `engine/mip/exact/multi_method/epsilon_method.py`

- **`_save_solution()`**: Alterado para salvar em `solution/eps{epsilon}/` em vez de `{primary_obj}/eps{epsilon}/`
- **`_save_summary()`**: Alterado para salvar em `solution/` em vez do diretório raiz
- **Logging**: Atualizado para usar o novo caminho

### 2. Engine - Gurobi Output Writer
**Arquivo:** `engine/data_pipeline/output_writer/gurobi_output_writer.py`

- Removida a criação da subpasta `optimization/`
- Agora salva diretamente no `output_dir` fornecido (que será `solution/eps{n}/`)

### 3. Engine - NSGA2 Runner
**Arquivo:** `engine/runners/run_nsga2.py`

- **`_run_analysis()`**: Criação de `solution/` e `analysis/` separadamente
- Logs e configurações salvos em `solution/`
- Gráficos e diagnósticos salvos em `analysis/`

### 4. Analytics - Epsilon Analyzer
**Arquivo:** `analytics/analysis/epsilon_analyzer.py`

- **`__init__()`**: Busca por `solution/` em vez de `{primary_objective}/`
- Cria automaticamente o diretório `analysis/` para saída
- **`analyze_pareto_front()`**: Salva todos os resultados em `analysis/`
- **Backward compatibility**: Ainda funciona com estrutura antiga

### 5. Analytics - Aggregate Results
**Arquivo:** `scripts/utils/aggregate_epsilon_results.py`

- **`load_epsilon_solutions()`**: Busca por `solution/` primeiro, depois tenta estrutura antiga
- Mantém compatibilidade com experimentos antigos

### 6. Analytics - Primary Objective Comparator
**Arquivo:** `analytics/comparison/primary_objective_comparator.py`

- Marcado como **DEPRECATED** pois depende da estrutura antiga (`swaps/`, `exams/`)
- Ainda funciona para experimentos antigos por compatibilidade

## Componentes Já Compatíveis

Os seguintes componentes **já estavam preparados** para a nova estrutura:

- `analytics/analysis/gantt_generator.py` - Já usava `analysis/` como padrão
- `analytics/analysis/metrics_collector.py` - Já salvava em `analysis/metrics.json`
- `analytics/analysis/solution_analyzer.py` - Já suportava subpastas

## Uso

### YAML de Configuração

Agora você tem controle total sobre a estrutura de pastas:

```yaml
experiments:
  - INSTANCE_FILE: "data/input/local_test/3_days/2022jan02_to_2022jan04"
    OUTPUT_DIR: "data/output/meus_experimentos/teste_1/cenario_A"
    PRIMARY_OBJECTIVE: "swaps"
    # ...
```

Resultado:
```
data/output/meus_experimentos/teste_1/cenario_A/
├── solution/
│   ├── eps0/
│   ├── eps1/
│   └── ...
└── analysis/
    ├── pareto_plot.png
    └── ...
```

### Executando Análise

A pipeline de análise continua funcionando da mesma forma:

```bash
python analytics/runners/run_analysis.py \
    data/output/meus_experimentos/teste_1/cenario_A \
    --method math_model
```

A análise irá:
1. Buscar soluções em `solution/`
2. Gerar todos os gráficos e relatórios em `analysis/`

## Compatibilidade Retroativa

Todos os componentes mantêm compatibilidade com a estrutura antiga:

1. Se não encontrar `solution/`, busca por `swaps/` ou `exams/`
2. Se não encontrar `analysis/`, busca por arquivos no diretório raiz
3. Avisos são emitidos quando estrutura antiga é detectada

## Benefícios

1. **Controle Total**: Usuário define estrutura completa via YAML
2. **Consistência**: Todos os métodos usam a mesma estrutura
3. **Organização**: Separação clara entre soluções e análises
4. **Simplicidade**: Não há mais pastas criadas automaticamente baseadas em objetivos
5. **Flexibilidade**: Fácil criar múltiplos cenários sem conflitos de nomenclatura

## Migração de Experimentos Antigos

Para migrar experimentos com a estrutura antiga:

```bash
# Exemplo: migrar de swaps/ para solution/
cd data/output/epsilon_euler/3_days/2022jan02_to_2022jan04/

# Renomear swaps/ para solution/
mv swaps/ solution/

# Criar pasta analysis/
mkdir -p analysis/

# Mover arquivos de análise (se existirem)
mv solution/pareto_*.* analysis/ 2>/dev/null || true
```

## Notas Importantes

- A pasta especificada em `OUTPUT_DIR` **sempre será criada** automaticamente
- Não é mais necessário incluir `swaps/` ou `exams/` no caminho do `OUTPUT_DIR`
- `PrimaryObjectiveComparator` só funciona com estrutura antiga (deprecated)
- Todos os novos experimentos devem usar a nova estrutura
