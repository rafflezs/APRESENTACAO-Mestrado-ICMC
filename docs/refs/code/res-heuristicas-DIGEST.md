# Digest: Factibilidade NSGA-II — Feedback Maristela

**Contexto:** Orientadora questiona comparações entre NSGA-II e métodos exatos/heurísticos porque NSGA-II não garante factibilidade. Gerado para investigar se o problema é erro de análise ou ausência real de soluções factíveis.

---

## Mensagens relevantes (íntegra)

| Local | Mensagem |
|-------|----------|
| 5.6.2 | "Vc nao tem nenhuma solução factível no Genético? Não pode comparar com o método exato, na fronteira pois as soluções não são comparáveis. Seriam comparáveis se fossem factíveis." |
| 5.6.2 | "'No horizonte de 60 dias, o NSGA-IIc inclusive supera a fronteira do exato (HV relativo de 1,039), em razão da não-convergência do solver neste horizonte.' Como pode dizer que fez isso se não tem garantia de factibilidade. Não pode comparar." |
| 6.2   | "não tem como dizer que nao compromete. Elas não sao factiveis. Como medir? Ou eu nao estou entendendo." |
| Geral | "o seu genético não obtem soluções factíveis, então nao tem como comparar." |
| Geral | "Tem que deixar separado. Nos trabalhos futuros, diz que vai lidar com isso, um reparador." |

---

## O que é sabido (CLAUDE.md / dissertação)

- NSGA-II viola **apenas C5** (cobertura mínima de exames), **não C1–C4**
- C1–C4: restrições estruturais (unicidade de alocação, compatibilidade médico-clínica, respeito de disponibilidade, capacidade de sala)
- C5: toda demanda de exames deve ser atendida (restrição de cobertura completa)
- Cromossomo compacto (NSGAIIc): variáveis `w` apenas (médico-dia-clínica); decodificação gera `x` implicitamente
- Cromossomo estendido (NSGAIIe): variáveis `x` e `w` binárias explícitas

---

## Distinção crítica: "infactível" em qual sentido?

Duas interpretações possíveis para "sem solução factível":

### Interpretação A — violação apenas de C5 (cobertura)
Soluções são **estruturalmente válidas** (alocação coerente médico-clínica-turno) mas **cobrem menos exames** que o mínimo exigido. Z1 > 0 não é problema — Z1 minimiza exames não atendidos, e o método ε-constraint usa Z1 como objetivo. Se Z2 está dentro do ε, a solução é factível para o subproblema ε-constraint.

**→ Neste caso:** soluções NSGA-II podem ser comparáveis se as restrições C1–C4 forem respeitadas. A questão é se Z1 e Z2 calculados correspondem a alocações válidas.

### Interpretação B — violação de C1–C4 também
Alguma restrição estrutural (ex.: médico alocado a clínica sem habilitação, ou dois médicos na mesma sala) é violada. Neste caso Z1/Z2 reportados são artefatos — a alocação é incoerente e os valores não têm significado real.

**→ Neste caso:** comparação com exato é inválida. HV relativo de 1,039 no horizonte 60 dias é espúrio.

---

## Perguntas para investigar no código/resultados

1. **Quais restrições são violadas por quê?**
   - Verificar log de pós-processamento do NSGA-II: existe checagem de factibilidade por restrição?
   - Arquivo de resultados tem flag de violação por constraint (C1, C2, C3, C4, C5)?

2. **Como Z1 e Z2 são calculados para soluções NSGA-II?**
   - São calculados diretamente da decodificação do cromossomo (podem incluir alocações inválidas)?
   - Ou passam por validação antes da avaliação?

3. **O HV é calculado com soluções brutas ou filtradas?**
   - Se HV usa Z1/Z2 de soluções que violam C1–C4, valor é inválido
   - Se HV usa apenas soluções C1–C4-factíveis (mesmo violando C5), comparação tem base

4. **Existem soluções com Z1=0 no NSGA-II?**
   - Se existem, são estruturalmente válidas (C1–C4)?
   - Se sim, são comparáveis com exato em Z2

5. **Por que NSGAIIc supera exato a 60 dias?**
   - Hipótese 1: solver não convergiu (gap alto), NSGA-II encontrou solução melhor genuína
   - Hipótese 2: NSGA-II viola restrição que solver honra, tornando Z2 artificialmente menor
   - Verificar: qual é o gap do exato a 60 dias? Quais restrições NSGA-II violou nas soluções desse horizonte?

---

## Checklist de investigação

- [ ] Rodar script de validação nas soluções NSGA-II: checar C1–C5 individualmente
- [ ] Confirmar se violação se limita a C5 ou inclui C1–C4
- [ ] Verificar gap do solver no horizonte 60 dias
- [ ] Comparar Z1/Z2 de soluções NSGA-II C1–C4-factíveis vs. fronteira exata
- [ ] Avaliar se HV calculado usa soluções válidas ou brutas
- [ ] Identificar instâncias onde NSGA-IIc tem Z1=0 com C1–C4 respeitados

---

## Consequências para o texto

| Cenário | Ação no texto |
|---------|---------------|
| Apenas C5 violada, C1–C4 ok | Notar que soluções são estruturalmente válidas mas sem garantia de cobertura completa; comparação de Z2 pode ser contextualizada separadamente |
| C1–C4 violadas | Remover toda comparação direta NSGA-II vs. exato; reescrever §5.6.2 como análise isolada; remover HV relativo no 60 dias |
| Misto por instância | Filtrar e reportar apenas soluções C1–C4-factíveis; indicar % de soluções válidas por horizonte |

---

## Tarefas derivadas (TODO)

- [ ] Verificar código de avaliação NSGA-II: onde C1–C5 são checadas
- [ ] Gerar tabela de violações por restrição e horizonte
- [ ] Decidir estratégia de texto com base nos resultados acima
