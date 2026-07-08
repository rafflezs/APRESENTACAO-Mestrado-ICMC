Há várias variantes de NSGA‑II e alguns usos de NSGA‑III em escalonamento de profissionais de saúde, mas quase sempre combinando: representação mais compacta/indireta, operadores muito mais agressivos e componentes meméticos ou matheurísticos; em geral, problemas com escala e acoplamento de restrições semelhantes ao seu acabam resolvidos com SA/LNS ou MIP/branch‑and‑price, e não com um NSGA‑II “direto” como o que você implementou. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/attachments/119698365/813c3141-c592-407e-b315-61b0b9cd29fb/limitacoes-nsga2.md)

***

## Situação geral na literatura

- Em nurse rostering “industrial” (INRC‑I/II, múltiplas unidades, horizontes de semanas) o estado da arte são MIP/branch‑and‑price, matheurísticas e LNS/SA; MOEAs são mais comuns como baseline ou para casos didáticos. [link.springer](http://link.springer.com/10.1007/s10479-020-03527-6)
- Em physician scheduling mais recente, resultados fortes vêm de modelos MIP com cortes e desigualdades válidas específicas (por exemplo, igualização de carga), e não de NSGA‑II. [sciencedirect](https://www.sciencedirect.com/science/article/abs/pii/S0305048317309726)
- Revisões de NSGA‑II em scheduling mostram muitas adaptações de codificação, operadores e híbridos, inclusive para alocação hospitalar, mas quase nenhuma em escalas com centenas de profissionais × dezenas de dias com matrizes \(i,u,d,t\) binárias “full” como a sua. [opus.lib.uts.edu](https://opus.lib.uts.edu.au/bitstream/10453/168579/2/processes-10-00098-v2.pdf)

***

## Variações de NSGA‑II em nurse/physician scheduling

- Many‑Objective Nurse Scheduling com NSGA‑II + Pareto partial dominance: Ohki et al. tratam um NRP com 12 objetivos usando NSGA‑II modificado, substituindo dominância completa por “Pareto partial dominance” e agendando linearmente o tamanho do subconjunto de objetivos usado na ordenação. [scitepress](http://www.scitepress.org/DigitalLibrary/Link.aspx?doi=10.5220/0006894501180125)
- O mesmo grupo mostra, em aplicação real em hospital japonês, que NSGA‑II com Pareto partial dominance e subset‑size scheduling consegue otimizar 12 objetivos de escala prática, apesar de limitações de diversidade, sendo competitivo em qualidade de escala, mas em horizontes de 1 mês e cerca de 30–50 enfermeiras. [ieeexplore.ieee](https://ieeexplore.ieee.org/document/9263847/)
- Trabalhos de NRP com fatores humanos usam NSGA‑II combinado com outras meta‑heurísticas (por exemplo, algoritmo Keshtel, Tabu Search), além de representações por padrões de turno, justamente para manter factibilidade e reduzir dimensionalidade. [opus.lib.uts.edu](https://opus.lib.uts.edu.au/bitstream/10453/168579/2/processes-10-00098-v2.pdf)
- Há GAs para nurse rerostering que usam codificação por padrões de turno e operadores constraint‑aware (evitando reparo pesado), mostrando que representação e operadores são o foco, não tanto a troca de NSGA‑II por outro MOEA. [sciencedirect](https://www.sciencedirect.com/science/article/abs/pii/S0305054805001140)

***

## NSGA‑II “melhorado” em scheduling de saúde (não só NRP)

- Em appointment scheduling hospitalar multiobjetivo, Ala et al. combinam NSGA‑II com Whale Optimization (WOA) e simulação, usando codificação discreta especializada e operadores projetados para o modelo de filas, o que melhora convergência e diversidade da fronteira. [pmc.ncbi.nlm.nih](https://pmc.ncbi.nlm.nih.gov/articles/PMC8494746/)
- Em home health care routing & scheduling, modelos multiobjetivo são resolvidos com NSGA‑II e NSGA‑III como baselines; estudos recentes propõem variantes como um Grey Wolf multiobjetivo discreto (DMOGWO) que superam consistentemente NSGA‑II/III em convergência e distribuição da fronteira, mantendo codificações compactas (sequências de visitas/turnos) e vizinhanças grandes. [sciencedirect](https://www.sciencedirect.com/science/article/abs/pii/S0360835222003266)
- Um trabalho recente de workforce scheduling em saúde (MOO‑GA para escalas de unidade hospitalar) usa um GA multiobjetivo no espírito de NSGA‑II, mas com: inicialização híbrida baseada em heurísticas de atendimento, operadores de cruzamento por blocos de turno e horários modulares, e forte ênfase em equilíbrio entre custo, cobertura e satisfação da equipe. [arxiv](https://arxiv.org/html/2508.20953v1)

***

## NSGA‑III e muitos objetivos em scheduling

- NSGA‑III em si quase não aparece em nurse/physician rostering, mas é usado em problemas de scheduling análogos (task scheduling em nuvem, timetabling profissional) com múltiplos objetivos conflitantes (tempo, energia, custo, balanceamento). [dl.acm](https://dl.acm.org/doi/10.1109/CEC45853.2021.9504797)
- Esses trabalhos exploram os pontos fortes do NSGA‑III: seleção baseada em pontos de referência bem distribuídos no espaço objetivo e mecanismos de normalização para manter diversidade em muitos objetivos; na prática, exigem cuidado com geração dos pontos de referência e normalização, que podem ser pesados e sensíveis. [sciencedirect](https://www.sciencedirect.com/science/article/pii/S131915782200101X)
- Em home health care, NSGA‑III aparece mais como baseline comparativo (tipicamente superado por heurísticas multiobjetivo ad hoc), sugerindo que, em problemas de scheduling altamente estruturados, o ganho de mudar NSGA‑II → NSGA‑III é pequeno se a representação e os operadores continuarem “ingênuos”. [sciencedirect](https://www.sciencedirect.com/science/article/abs/pii/S0360835222003266)

***

## Padrões que atacam fraquezas semelhantes às do seu NSGA‑II

Tomando as limitações que você listou (dimensionalidade absurda, gargalo de inicialização, quase nenhuma evolução, vizinhanças locais demais, ausência de informação dual, reparo difícil), o que a literatura efetivamente faz é: [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/attachments/119698365/813c3141-c592-407e-b315-61b0b9cd29fb/limitacoes-nsga2.md)

- Reduzir dimensionalidade / usar codificação indireta.  
  - NRP de competição e muitos trabalhos de GA codificam padrões de turno ou sequências por enfermeira/dia (ou por sequência de dias), em vez de um gene por variável \(x_{i,u,d,t}\), o que traz ordens de magnitude a menos em tamanho de cromossomo. [sciencedirect](https://www.sciencedirect.com/science/article/abs/pii/S0305054805001140)
  - Há abordagens rule‑based em que o cromossomo codifica apenas prioridades/pesos de regras, e um decodificador construtivo (muitas vezes tipo EDA + ant‑miner) gera o schedule, exatamente para evitar trabalhar diretamente em um hipercubo binário gigantesco. [arxiv](https://arxiv.org/pdf/0711.3591.pdf)

- Inicialização híbrida e barata.  
  - Em nurse rostering competitivo, a população inicial costuma vir de heurísticas bem rápidas (greedy, pattern‑based) e, às vezes, de soluções de MIP simplificados, em vez de um constructive sampling caro por indivíduo. [arxiv](https://arxiv.org/pdf/2311.05438.pdf)
  - Alguns trabalhos de workforce e home health scheduling usam LNS ou solvers exatos apenas para produzir algumas boas soluções semente, que depois alimentam a população de NSGA‑II, reduzindo o número de indivíduos que precisam ser “construídos do zero”. [sciencedirect](https://www.sciencedirect.com/science/article/abs/pii/S2210650222001420)

- Operadores com vizinhança grande + busca local memética.  
  - Memetic algorithms são muito comuns: crossover gera um filho próximo de soluções boas, e uma busca local tipo LNS/VNS (trocas múltiplas de turnos, realocação em blocos de dias/rotas) faz o “refinamento pesado”. [scitepress](https://www.scitepress.org/Papers/2024/124023/124023.pdf)
  - Em nurse scheduling many‑objective, os trabalhos com NSGA‑II que apresentam bons resultados quase sempre usam operadores que mexem em blocos de sequência de shifts ou em “padrões” reutilizáveis, não apenas reatribuições pontuais, para poder explorar extremos lexicográficos. [pdfs.semanticscholar](https://pdfs.semanticscholar.org/c059/241da48bc16a3a9f13310d2d2e3a6729e999.pdf)

- Híbridos com MIP/CP (matheurísticas).  
  - NRP com múltiplas unidades e muitas soft constraints são hoje resolvidos com branch‑and‑price, branch‑and‑cut com cortes especializados e CP, às vezes combinando meta‑heurísticas como geradores de colunas ou como heurísticas de primal improvement. [mdpi](https://www.mdpi.com/2079-8954/13/9/745)
  - Em physician scheduling, há uso de desigualdades válidas baseadas em equalização (workload balancing) para fortalecer o MIP; isso é análogo à sua observação de que o MIP explora muito melhor os extremos de trocas/exames do que o GA rodando no primal puro. [sciencedirect](https://www.sciencedirect.com/science/article/abs/pii/S0305048317309726)

- Tratamento explícito de muitos objetivos e diversidade.  
  - Trabalhos com 10–12 objetivos em NRP substituem a dominância Pareto padrão por dominância parcial, escolhendo subconjuntos de objetivos por geração (ou com agendamento linear do tamanho do subconjunto) para evitar colapso da pressão seletiva; isso é uma forma de corrigir a perda de poder discriminativo do NSGA‑II em muitos objetivos. [scitepress](https://www.scitepress.org/Papers/2018/68945/68945.pdf)
  - Revisões apontam também variantes “espaciais” de NSGA‑II e mecanismos de normalização do espaço objetivo para melhorar cobertura da fronteira; mas o ganho mais robusto vem de codificação/operadores adequados e de hibridização, não apenas de ajustes de ranking. [pmc.ncbi.nlm.nih](https://pmc.ncbi.nlm.nih.gov/articles/PMC11198908/)

***

## Relação com o seu problema específico

- O seu modelo trabalha com 500k–1,5M de genes binários, população ~100 e praticamente 1 geração útil sob orçamentos de minutos, o que te coloca fora do regime onde NSGA‑II é eficiente; a literatura evita exatamente essa combinação de alta dimensionalidade direta + inicialização construtiva pesada. [ppl-ai-file-upload.s3.amazonaws](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/attachments/119698365/813c3141-c592-407e-b315-61b0b9cd29fb/limitacoes-nsga2.md)
- Codificar decisões no nível médico–dia (ou em padrões de agendas por bloco) e usar um decodificador rápido (e.g. MIP/CP simplificado, greedy) para gerar \(x_{i,u,d,t}\) é muito mais alinhado com o que tem funcionado em NRP realista e em scheduling de saúde (home care, workforce). [arxiv](https://arxiv.org/pdf/2311.05438.pdf)
- Dado o acoplamento forte de G1–G6 e o gargalo de reparo que você observou, seguir a linha dos trabalhos que tratam factibilidade “por construção” (padrões válidos, operadores que preservam hard constraints) tende a ser mais promissor do que tentar sofisticar ainda mais o esquema de reparo em espaço binário full. [scitepress](https://www.scitepress.org/Papers/2024/124023/124023.pdf)

***

## Quando (não) vale migrar para NSGA‑III

- A literatura de nurse/physician scheduling não mostra evidência forte de que NSGA‑III, isoladamente, resolva problemas estruturais de representação, custo de inicialização ou de operadores com vizinhança pequena; quando NSGA‑III é competitivo, é em problemas com poucos milhares de variáveis, codificações compactas e muitas funções objetivo. [dl.acm](https://dl.acm.org/doi/10.1109/CEC45853.2021.9504797)
- Estudos comparando NSGA‑II e NSGA‑III em scheduling (por exemplo, timetabling profissional) sugerem ganhos em diversidade da fronteira, mas somente quando a base é uma implementação já bem afinada em termos de codificação, operadores e parametrização; o “salto” de performance vem desses elementos, não do rótulo NSGA‑III em si. [pmc.ncbi.nlm.nih](https://pmc.ncbi.nlm.nih.gov/articles/PMC11198908/)
- Para o seu caso, faz mais sentido primeiro atacar representação, inicialização e vizinhanças (possivelmente dentro de um framework memético ou matheurístico) e só depois, se ainda fizer sentido, experimentar NSGA‑III ou operadores de seleção por referencia points para melhorar a cobertura da fronteira.  

***

## Resumo em Markdown (para você salvar como .md)

```markdown
# NSGA-II e variantes na alocação de médicos/enfermeiras

## 1. Posição do NSGA-II na literatura
- Em nurse rostering realista (INRC-I/II, múltiplas unidades), predominam MIP/branch-and-price, matheurísticas e LNS/SA; NSGA-II aparece mais como baseline do que como estado da arte.[web:4][web:7][web:16]
- Em physician scheduling recente, trabalhos fortes usam MIP com cortes e igualização de carga; quase não há NSGA-II em larga escala.[web:24]
- Revisões de NSGA-II em scheduling reportam muitas adaptações de codificação e operadores, inclusive em hospitais, mas em escalas menores que o seu problema.[web:45][file:1]

## 2. Variações de NSGA-II específicas para NRP
- Many-objective nurse scheduling com NSGA-II baseado em Pareto partial dominance e agendamento linear do tamanho do subconjunto de objetivos (12 objetivos em hospital japonês).[web:6][web:8][web:37][web:40]
- GAs para NRP com fatores humanos combinam NSGA-II com outros metaheurísticos (Keshtel, Tabu), usando codificação por padrões de turno para reduzir dimensionalidade e preservar factibilidade.[web:31][web:41][web:45]

## 3. NSGA-II melhorado em scheduling de saúde
- Appointment scheduling multiobjetivo em hospitais: NSGA-II híbrido com Whale Optimization e simulação para melhorar convergência e diversidade.[web:42]
- Home health care routing & scheduling: NSGA-II/III usados como baselines, frequentemente superados por DMOGWO e matheurísticas, mas sempre com codificação compacta (sequência de visitas/turnos).[web:26][web:29][web:36]
- Workforce scheduling hospitalar com MOO-GA no espírito de NSGA-II: inicialização heurística, operadores por blocos de turno e balanceamento custo–cobertura–satisfação.[web:25]

## 4. NSGA-III e muitos objetivos
- NSGA-III é aplicado em scheduling (timetabling, cloud tasks), explorando seleção por reference points para muitos objetivos, mas raramente em nurse/physician rostering.[web:23][web:44]
- Em home health care, NSGA-III serve mais como baseline; heurísticas multiobjetivo específicas obtêm melhor fronteira de Pareto.[web:26]

## 5. Padrões de desenho que atacam fraquezas como as do seu NSGA-II
- Redução de dimensionalidade: codificação por padrões de turno ou médico–dia, ou ainda cromossomos que codificam regras/pesos, decodificados por heurísticas ou MIP/CP simplificados.[web:14][web:31][web:45]
- Inicialização híbrida: população inicial gerada por heurísticas rápidas e/ou poucas soluções MIP de boa qualidade, evitando constructive sampling caro para cada indivíduo.[web:4][web:16][web:25][web:29]
- Operadores de grande vizinhança + busca local memética: LNS/VNS sobre soluções elite, mexendo em blocos de dias/rotas em vez de reatribuições pontuais.[web:4][web:14][web:41][web:46]
- Tratamento de factibilidade por construção, usando padrões válidos e operadores constraint-preserving, minimizando o uso de reparos em hard constraints acopladas.[web:31][web:41][web:45]
- Dominância parcial e mecanismos de diversidade específicos para muitos objetivos, como Pareto partial dominance com subset-size scheduling.[web:6][web:8][web:37][web:40]

## 6. Implicações para o seu trabalho
- O gargalo de inicialização e a representação full x_{i,u,d,t} tornam o seu NSGA-II efetivamente uma heurística construtiva multi-start, sem evolução significativa sob orçamentos de minutos.[file:1]
- Antes de migrar para NSGA-III, a literatura sugere focar em: (i) representação compacta/indireta, (ii) inicialização híbrida com heurísticas/MIP, (iii) vizinhanças grandes com busca local memética e (iv) tratamento de factibilidade por construção.
- Mesmo assim, para a escala e acoplamento G1–G6 do seu problema, soluções competitivas com MIP exato tendem a exigir um framework matheurístico (combinação forte de MIP/CP com heurísticas evolutivas ou LNS).[web:4][web:7][web:16][web:24]
```