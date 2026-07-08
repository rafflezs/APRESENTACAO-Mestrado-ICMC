# Relatório de Limpeza da Codebase

**Data:** 24 de dezembro de 2025

## Pipelines Principais (NÃO REMOVER)

✅ **Cluster:**
- `cluster/submit_run_1.sh` - Pipeline principal (30d, 60d, 90d)
- `cluster/submit_run_2.sh` - Pipeline secundário (15d)
- `cluster/pbs/*.pbs` - Scripts PBS usados pelos submit_run_*.sh

✅ **Local:**
- `bin/run-nsga2-local`
- `bin/run-epsilon-local`
- `bin/run-mip-heuristics-local`

---

##  ARQUIVOS PARA REMOÇÃO

### 1. Scripts Cluster Obsoletos (substituídos por submit_run_1/2.sh)

```bash
# Substituídos pelos novos submit_run_1.sh e submit_run_2.sh
cluster/submit_euler.sh              # Antigo: submit genérico
cluster/submit_all_methods.sh        # Antigo: submit por instância individual
cluster/submit_all_windows.sh        # Antigo: versão antiga
cluster/batch_submit_euler.sh        # Antigo: batch genérico

# Testes cluster não mais necessários
cluster/tests/test_pipeline.sh
cluster/tests/test_notifications.pbs
```

**Razão:** Os novos `submit_run_1.sh` e `submit_run_2.sh` consolidam toda a funcionalidade com melhorias (NCPUS do YAML, walltime correto, análise automática).

---

### 2. Scripts Temporários/Teste

```bash
# Script de teste criado hoje (já validado)
scripts/test_comparative_gantt.sh    # Teste local para Gantt comparativo

# Scripts utilitários pontuais
scripts/compare_primary_objectives.sh  # Wrapper simples para analytics

# Testes antigos
scripts/testing/test_branch_priorities.py
scripts/testing/test_gantt_real_data.py
scripts/testing/test_loaders.py
```

**Razão:** Scripts criados para validação pontual ou substituídos por funcionalidade nos runners.

---

### 3. Scripts Utilitários Temporários

```bash
scripts/utils/add_file_paths.py          # Utilitário pontual
scripts/utils/add_i18n_support.py        # Migração única (já aplicada)
scripts/utils/create_yaml_model.py       # Gerador pontual
scripts/utils/send_email_alert.py        # Experimental
scripts/utils/clear_pycache_dirs.sh      # Pode ser substituído por: find . -name __pycache__ -exec rm -rf {} +
```

**Razão:** Ferramentas de migração única ou funcionalidades não integradas às pipelines.

---

### 4. Scripts de Análise Obsoletos

```bash
# Análise de branch priorities (experimento concluído)
scripts/analyze_branch_priority_batch.py

# Script de dados agregados (migrado para analytics/etl/)
scripts/data/                            # Verificar conteúdo
```

**Razão:** Experimentos concluídos ou migrados para módulos permanentes.

---

### 5. Pipeline Obsoleto

```bash
pipelines/run_epsilon_pipeline.py        # Substituído por bin/run-epsilon-local + cluster/submit_run_*.sh
```

**Razão:** Orquestração antiga substituída pelos scripts bin/ + cluster/.

---

### 6. Arquivos de Exemplo/Template

```bash
extra/euler_1_exemplo.sh
extra/euler_2_exemplo.sh
extra/relax_and_fix_exemplo_1.md
```

**Ação:** Pode mover para `docs/examples/` ou remover se não documentam funcionalidade atual.

---

### 7. Markdown Espalhado (fora de docs/)

```bash
# Raiz
TODO.md                              # ️ AVALIAR: manter se for roadmap ativo

# Analytics
analytics/README.md                   # ✅ MANTER: documenta estrutura
analytics/evaluators/README.md        # ✅ MANTER: documenta evaluators
analytics/analysis/MANUAL_metrics_collector.md  #  REMOVER: manual interno do agent

# Cluster
cluster/README.md                     # ✅ MANTER: documenta cluster
```

**Ação:**
- `analytics/analysis/MANUAL_metrics_collector.md` → Remover (nota interna de desenvolvimento)
- Avaliar `TODO.md` (manter se for roadmap, remover se for lista de tarefas antigas)

---

## 📦 DIRETÓRIOS INTOCÁVEIS (conforme solicitado)

- ✅ `data/` - Instâncias e resultados
- ✅ `notebooks/` - Análises Jupyter
- ✅ `tests/` - Testes automatizados (engine/metaheuristics/nsga2/tests)
- ✅ `docs/` - Documentação permanente

---

## 🧹 SUGESTÕES DE ORGANIZAÇÃO

### Criar `archive/` ou `deprecated/`

Mover scripts obsoletos mas que podem ter valor histórico:

```bash
mkdir -p archive/cluster_old
mv cluster/submit_euler.sh archive/cluster_old/
mv cluster/submit_all_methods.sh archive/cluster_old/
mv cluster/batch_submit_euler.sh archive/cluster_old/
mv cluster/submit_all_windows.sh archive/cluster_old/

mkdir -p archive/scripts_temp
mv scripts/test_comparative_gantt.sh archive/scripts_temp/
mv scripts/testing/ archive/scripts_temp/
```

### Consolidar `scripts/utils/`

Manter apenas:
- `aggregate_epsilon_results.py` (se usado)
- Remover resto

---

## ✅ COMANDO DE LIMPEZA SEGURA

```bash
cd /home/remote-dev/Projetos/DISSERTACAO-Alocacao-Medicos

# 1. Criar archive
mkdir -p archive/{cluster_old,scripts_temp,pipelines_old,extra_old}

# 2. Mover scripts cluster obsoletos
mv cluster/submit_euler.sh archive/cluster_old/
mv cluster/submit_all_methods.sh archive/cluster_old/
mv cluster/batch_submit_euler.sh archive/cluster_old/
mv cluster/submit_all_windows.sh archive/cluster_old/
mv cluster/tests/ archive/cluster_old/

# 3. Mover scripts temporários
mv scripts/test_comparative_gantt.sh archive/scripts_temp/
mv scripts/compare_primary_objectives.sh archive/scripts_temp/
mv scripts/testing/ archive/scripts_temp/
mv scripts/analyze_branch_priority_batch.py archive/scripts_temp/

# 4. Mover utilitários pontuais
mkdir -p archive/scripts_temp/utils
mv scripts/utils/add_file_paths.py archive/scripts_temp/utils/
mv scripts/utils/add_i18n_support.py archive/scripts_temp/utils/
mv scripts/utils/create_yaml_model.py archive/scripts_temp/utils/
mv scripts/utils/send_email_alert.py archive/scripts_temp/utils/
mv scripts/utils/clear_pycache_dirs.sh archive/scripts_temp/utils/

# 5. Mover pipeline obsoleto
mv pipelines/run_epsilon_pipeline.py archive/pipelines_old/

# 6. Mover exemplos
mv extra/ archive/extra_old/

# 7. Remover markdown interno
rm analytics/analysis/MANUAL_metrics_collector.md

# 8. Limpar __pycache__ e .pytest_cache
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null

# 9. Limpar logs antigos (opcional - avaliar)
# find logs/ -name "*.log" -mtime +30 -delete

echo "✅ Limpeza concluída!"
echo "📦 Arquivos movidos para: archive/"
echo "🗑️  Para remover permanentemente: rm -rf archive/"
```

---

## 📊 RESUMO

| Categoria | Quantidade | Ação |
|-----------|------------|------|
| Scripts cluster obsoletos | 5 | Mover para archive/ |
| Scripts temporários | 6 | Mover para archive/ |
| Utilitários pontuais | 6 | Mover para archive/ |
| Pipeline obsoleto | 1 | Mover para archive/ |
| Exemplos | 3 | Mover para archive/ |
| Markdown interno | 1 | Remover |
| **TOTAL** | **22 arquivos** | **Cleanup** |

---

## ️ ANTES DE EXECUTAR

1. **Backup:** `git add . && git commit -m "Pre-cleanup snapshot"`
2. **Validar:** Verificar se algum script em `archive/` é referenciado
3. **Testar:** Rodar pipelines principais após limpeza
4. **Deletar:** Após 1 semana sem problemas: `rm -rf archive/`

---

## 🎯 ESTRUTURA FINAL LIMPA

```
.
├── bin/                      # Runners locais
│   ├── run-epsilon-local
│   ├── run-mip-heuristics-local
│   └── run-nsga2-local
├── cluster/                  # Cluster PBS
│   ├── submit_run_1.sh      # ✅ PRINCIPAL
│   ├── submit_run_2.sh      # ✅ PRINCIPAL
│   ├── pbs/                 # PBS scripts
│   ├── configs/             # YAML configs
│   └── batch/               # Batch processors
├── scripts/
│   ├── data/                # Scripts de dados (verificar)
│   └── utils/               # Apenas aggregate_epsilon_results.py
├── analytics/               # Análise agnóstica
├── engine/                  # Core optimization
├── data/                    # Intocável
├── docs/                    # Intocável
├── notebooks/               # Intocável
└── tests/                   # Intocável (NSGA-2)
```
