# Roteiro — Cola de Apresentação (notas rápidas)

**Defesa de Mestrado — Otimização na Alocação de Médicos em Múltiplas Clínicas**
Thiago Rafael Mariotti Claudio · Orientadora: Profa. Dra. Maristela Oliveira dos Santos · USP-ICMC

> ⏱️ **~30 min · ~29 slides · ~1 min/slide.** Resultados (§5) é o coração — não corra até lá.

---

## 🆘 Se travar (leia isto antes de subir)

- **Respira. Bebe água.** Ninguém percebe 3 s de silêncio como você percebe.
- Travou? Volte à **frase-âncora** da seção (a linha em **negrito** de cada bloco abaixo).
- Não decore número a número — decore a **história**: *setor importante → faltam médicos → escala manual é cara → ninguém na literatura junta múltiplas unidades + trocas → nós modelamos e resolvemos de 3 jeitos → o que achamos → o que recomendamos.*
- Se esquecer um dado, diga o conceito ("da ordem de bilhões de exames") e siga. O número exato está no slide.

---

## §1 — Introdução  ⏱️ ~4 min
**Âncora: "Setor enorme, mas faltam médicos — e a escala é feita na mão."**

- **1.1 O setor em números** — 🎯 gancho: 2,4 bi exames/ano · R$ 24 bi (2022) · diagnóstico precoce reduz custo. ➡️ "Mas há um gargalo..."
- **1.2 Escassez de profissionais** — 🎯 vagas não preenchidas 6%→18% · 1,51 mil médicos p/ 1,99 mi hab (2017) · máquina parada = custo. ➡️ "Com equipe enxuta, a **escala** vira alavanca."
- **1.3 Delineando o problema** — 🎯 múltiplas unidades **autônomas** compartilham médicos · escala **manual**, sem otimalidade · relação vários-p/-vários = **explosão combinatória**. 🔑 duplo desafio: atender demanda **e** minimizar trocas. ➡️ "Será que a literatura resolve isso?"
- **1.4 Lacunas (imagem)** — 🎯 deixe a matriz falar. Aponte: literatura = **unidade única**; só **este estudo** marca *múltiplas unidades* + *minimização de trocas* + *exames* + *dados reais*. ➡️ "É essa lacuna que atacamos."
- **1.5 Objetivos** — 🎯 4 objetivos; o central = tratar como **bi-objetivo** (exames × trocas) via **ε-restrito**. ➡️ "Vamos formalizar o problema."

---

## §2 — Definição do Problema  ⏱️ ~7 min
**Âncora: "Alocar médico a sala/turno respeitando regras; minimizar dois custos."**

- **2.1 Contextualização** — 🎯 médico → clínica → demanda; agenda ao longo do horizonte. 🔑 exame ≈ **15 min** define capacidade. Dados **reais e estáticos**.
- **2.2 Hipóteses (H1–H7)** — 🎯 não leia todas; destaque **H1** (cobertura mínima), **H2** (1 unidade/dia), **H6–H7** (trocas). ➡️ "Viram variáveis e restrições."
- **2.3 Notação** — 🎯 rápido: `x` = alocação turno, `w` = alocação dia, `c` = exames não atendidos, `z` = troca. Não leia índice por índice.
- **2.4 Restrições R1–R6** — 🎯 use a **Chave** embaixo: R1 disponibilidade · R2–R3 uma unidade/dia · R4–R5 elegibilidade+salas · **R6 cobertura mínima** (guarde: é a que o genético viola).
- **2.5 Bi-objetivos** — 🎯 **Z1** exames não atendidos (operacional) · **Z2** trocas (ergonômico) · **conflitantes**. ➡️ "Contar trocas tem uma armadilha..."
- **2.6 Detectando trocas (γ)** — 🔑 **contribuição central.** Lacunas (dias sem trabalho) quebram a comparação ingênua. Variável de estado **γ** (do GLSP) carrega a clínica "atual" mesmo sem trabalhar → conta trocas através das lacunas. ➡️ "Agora, como resolver."

---

## §3 — Metodologia e Abordagens  ⏱️ ~6 min
**Âncora: "Três famílias para a mesma fronteira de Pareto."**

- **3.1 ε-restrito** — 🎯 objetivos conflitantes → **fronteira de Pareto**. Fixa Z1 como objetivo, Z2 ≤ ε; **7 pontos** por instância. Mesma grade p/ todos → comparável.
- **3.2 MIP-heurísticas** — 🎯 decompõe o tempo em **janelas**. **Relax-and-Fix** constrói; **Fix-and-Optimize** refina; **Híbrido** = RF→FO.
- **3.3 NSGA-II** — 🎯 evolutivo bi-objetivo: ordenação não-dominada + crowding + elitismo.
- **3.4 Operadores** — 🎯 feitos sob medida: amostragem com restrições, **cruzamento por blocos diários**, **mutação por realocação de slot** (preservam coerência da agenda).
- **3.5 Encoding Estendido vs Compacto** — 🔑 Compacto = 1 gene por médico-dia → **~70× menor** → **mais gerações** no mesmo tempo. Guardar: o Compacto ganha por isso. ➡️ "Como testamos."

---

## §4 — Experimentos  ⏱️ ~4 min
**Âncora: "Dados reais, 4 horizontes, protocolo de dois estágios."**

- **4.1 Ambiente** — 🎯 cluster Euler (ICMC); Gurobi 12, pymoo 0.6.1; **3.600 s por ponto ε**.
- **4.2 Base + pipeline** — 🔑 **250 médicos, 37 unidades, 28.445 registros, 576 dias**; pipeline separa base-modelo de validação (sem vazamento).
- **4.3 Instâncias/protocolo** — 🎯 4 horizontes **15/30/60/90 d**; 10 instâncias/horizonte = **2 param + 8 validação → 40 pares**. Gráfico mostra sazonalidade.
- **4.4 Métricas** — 🎯 dois eixos: **qualidade da fronteira** (HV, amplitude, gap) e **custo/factibilidade** (MIP gap, tempo, factibilidade).

---

## §5 — Resultados e Discussão  ⏱️ ~8 min  ⭐ CORAÇÃO
**Âncora: "Existe uma virada entre 15 e 30 dias — daí em diante, heurística é obrigatória."**

- **5.1 Transição de regime** ⭐ — 🔑 MIP gap: **4,1% (15d) → 42,7 → 78,1 → 96,8%**. Exato só converge no **quinzenal**. ➡️ "≥30 d exige aproximação."
- **5.1b MIP gap: exato vs MIP-heur.** — 🎯 tabela Exato/RF/Híbrido (mesmo conjunto). 🔑 gap do heurístico usa **limitante próprio (mais frouxo)** → **não é comparação de qualidade**; RF pode ter gap maior *e* solução melhor. Além de 15 d, ninguém prova ótimo.
- **5.2 Fronteiras de Pareto** — 🎯 só os **factíveis**: Exato, RF, Híbrido (NSGA **fora** — ver 5.6/5.7). ⚠️ **RF parece bater exato/Híbrido em 60–90 d**: explicar — ninguém converge, curvas = incumbentes no limite de tempo; RF **decompõe** → melhor incumbente factível no mesmo tempo (**não** otimalidade).
- **5.4 Escalabilidade/tempo** — 🔑 NSGA-II **~7× mais rápido** (≈3.600 s vs ≈25.200 s).
- **5.5 Parametrização** — 🎯 Compacto (allon) **HV 0,67–0,72** vs Estendido **0,47–0,51**; MIP-heur: RF w75/o2 e Híbrido w50/o2.
- **5.6 NSGA-II: resultados (Compacto vs Estendido)** — 🎯 mostra a **fronteira isolada** do genético (dentro da família, não vs exato). 🔑 **Compacto domina o Estendido**: mesmas trocas, bem menos exames não atendidos → efeito do cromossomo ~70× menor. Instância 30 d.
- **5.7 Factibilidade do NSGA-II** ⚠️ — 🔑 **CUIDADO (ponto da Maristela):** genético viola **só a cobertura mínima (R6)**, nunca as estruturais R1–R4 (Estendido 100%; Compacto 89,8%). **Não é diretamente comparável** ao exato → lê-se como **tendência**, não campeão. Reparo = trabalho futuro.
- **5.8 Quadro-resumo (todos os métodos)** — 🎯 tabela consolidada: HV relativo + tempo + factível, 5 métodos × 4 horizontes. Não ler célula a célula — 3 padrões: Híbrido ≈ exato (15/30d); NSGA ~ordem de grandeza mais rápido; **factível: sim (MIP) / não (NSGA, só R6)**. HV>1 = referência não convergida.
- **5.9 Sumarizando** — 🎯 as 4 observações: exato escala mal; Híbrido bom em curto; Compacto domina Estendido; factibilidade aponta o reparo.

---

## §6 — Conclusões e Perspectivas  ⏱️ ~2,5 min
**Âncora: "Contribuímos com o modelo bi-objetivo multiunidade + γ; recomendação prática por horizonte."**

- **6.1 Contribuições + recomendação** — 🎯 5 contribuições (modelo bi-obj, **γ**, acoplamento ε+heurística, variantes NSGA-II, avaliação sistemática). 🔑 **Recomendação:** quinzenal → **exato**; mensal+ → heurística (**Híbrido** se há tempo, **NSGA-IIc** se o tempo aperta).
- **6.2 Limitações + futuro** — 🎯 limitações: factibilidade NSGA, dados determinísticos, regras ergonômicas fora. Futuro: **operador de reparo**, demanda estocástica, ML/warm-start, pipeline híbrida exato⊕meta. ➡️ "Muito obrigado — à disposição para perguntas."

---

## Encerramento
- Slide de **Agradecimentos** (CNPq / CAPES) — agradeça banca e orientadora **por nome**.
- "**Obrigado. Fico à disposição para as perguntas.**"
- Perguntas: respira, repita a pergunta em voz alta (ganha tempo), responda o que sabe. Não sabe? "Ótima questão para trabalho futuro."
