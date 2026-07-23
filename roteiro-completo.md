# Roteiro Completo — Texto para Ensaio

**Defesa de Mestrado — Técnicas de Otimização na Alocação de Médicos em Redes de Unidades de Diagnóstico por Imagem**
Thiago Rafael Mariotti Claudio · Orientadora: Profa. Dra. Maristela Oliveira dos Santos · USP-ICMC

---

## Abertura  *(slide de título)*

Bom dia a todas e todos. [pausa, respira] Agradeço à banca pela presença e ao tempo dedicado a este trabalho. Meu nome é Thiago Mariotti, sou orientado pela Professora Maristela Oliveira dos Santos, e hoje vou apresentar minha dissertação sobre técnicas de otimização aplicadas à alocação de médicos em redes de clínicas de diagnóstico por imagem.

A ideia central é simples de enunciar e difícil de resolver: montar escalas de trabalho para médicos que atendem em várias unidades ao mesmo tempo, buscando dois objetivos que competem entre si. Vou percorrer a motivação, o modelo matemático, as abordagens de solução, os experimentos e, principalmente, os resultados. [transição]

---

## §1 — Introdução

### 1.1 — O setor de diagnóstico em números
Primeiro, por que isso importa. O diagnóstico por imagem é um setor enorme: são cerca de **2,4 bilhões de exames realizados por ano**, e só em 2022 movimentou uma receita bruta da ordem de **24 bilhões de reais**. Além do peso econômico, há o peso clínico: o diagnóstico precoce melhora o acompanhamento do paciente e, no fim, reduz custo. Ou seja, é um setor grande, relevante e em crescimento. [pausa] Mas ele tem um gargalo. [transição]

### 1.2 — Escassez de profissionais
O gargalo é gente. Faltam profissionais especializados: a estimativa é de que a fração de vagas não preenchidas suba de cerca de 6% para 18%. No Brasil, o quadro é de escassez — algo como **1,51 mil médicos para cada 1,99 milhão de habitantes**, em dado de 2017. E isso tem uma consequência operacional direta: equipamento caro parado, filas, e pressão sobre as margens das clínicas. [pausa] Quando a equipe é enxuta, a forma como você **monta a escala** deixa de ser detalhe e vira uma alavanca operacional. É aí que a otimização entra. [transição]

### 1.3 — Delineando o problema
E que problema é esse, concretamente? Temos uma rede com **múltiplas unidades autônomas** — cada uma com sua demanda, suas salas, seus equipamentos — que **compartilham** os mesmos médicos. Hoje, essa escala é montada **manualmente** pelo setor de operações: consome tempo e não tem nenhuma garantia de qualidade. E como cada médico pode atender em várias unidades, temos uma relação de vários-para-vários que gera uma **explosão combinatória** de possibilidades. [pausa] O desafio é duplo: atender o máximo de exames com a equipe que existe **e**, ao mesmo tempo, evitar ficar remanejando o médico de uma unidade para outra. [transição] Será que a literatura já resolve isso?

### 1.4 — Lacunas de literatura
[deixe a imagem aparecer, aponte para a tabela] Esta matriz resume o que encontrei na revisão. As linhas são os grandes grupos de trabalhos; as colunas, as características do nosso problema. E o padrão é claro: a literatura se concentra em **uma unidade só** — contexto hospitalar, ambulatorial, escalonamento de enfermagem. [aponte a última linha] Só o **nosso estudo** marca ao mesmo tempo *múltiplas unidades autônomas*, *minimização de trocas*, *alocação de médicos*, em contexto de *exames* e com *dados reais*. É exatamente essa combinação — múltiplas unidades mais minimização de trocas — que quase ninguém trata. [pausa] É essa lacuna que o trabalho ataca. [transição]

### 1.5 — Objetivos
Então os objetivos são: primeiro, **modelar matematicamente** esse escalonamento em múltiplas unidades; segundo, e é o ponto central, tratar o problema como **bi-objetivo** — minimizar exames não atendidos e, simultaneamente, minimizar trocas de clínica; terceiro, avaliar **três famílias** de solução; e, por fim, contribuir para a literatura de escalonamento multiunidade. A grande mudança em relação a versões anteriores do trabalho é justamente essa: os dois objetivos deixam de ser tratados isoladamente e passam a ser resolvidos **em conjunto**, pelo método ε-restrito. [transição] Vamos formalizar isso.

---

## §2 — Definição do Problema

### 2.1 — Contextualização
O problema é alocar médicos de ultrassonografia numa rede de clínicas, para atender a demanda de exames respeitando a disponibilidade de cada profissional. [aponte a agenda] Esta figura é uma agenda de um médico ao longo do horizonte: em cada dia e turno, ele está — ou não — alocado a uma unidade. Um detalhe que estrutura tudo: cada exame leva em média **15 minutos**, e é isso que define quantos exames cabem num turno. Os dados são reais e, para este trabalho, tratados como estáticos. [transição]

### 2.2 — Hipóteses de modelagem
A partir das regras de operação da rede, levantei sete hipóteses. Não vou ler todas [aponte]; destaco três. A **H1**: toda clínica com demanda precisa de pelo menos uma cobertura mínima. A **H2**: um médico fica em uma única unidade por dia. E as **H6 e H7**, que tratam das trocas: a agenda é irregular, não há limite de trocas, mas, partindo de uma condição inicial, a gente quer minimizá-las. Essas hipóteses viram, diretamente, as variáveis e restrições do modelo. [transição]

### 2.3 — Notação
Rapidamente, a notação. [aponte, sem ler tudo] Os índices são médico, unidade, dia e turno. As variáveis que importam: **x** diz se o médico está alocado num turno específico; **w**, se está alocado naquela unidade no dia; **c** conta os exames não atendidos; e **z** marca se houve troca de clínica. Guardem o **w** e o **z** — eles voltam. [transição]

### 2.4 — Restrições estruturais
Estas são as seis restrições estruturais. Em vez de ler equação por equação, uso a **chave** aqui embaixo: a primeira garante que só aloco quem está disponível; a segunda e a terceira garantem uma unidade por dia; a quarta e a quinta cuidam de elegibilidade e da capacidade de salas; e a **sexta** garante a **cobertura mínima** — toda unidade com demanda recebe pelo menos um médico. [pausa] Guardem essa sexta restrição, a cobertura mínima; ela vai reaparecer nos resultados. [transição]

### 2.5 — Os "bi"-objetivos
Agora os dois objetivos. O **Z1** minimiza os **exames não atendidos** — é o lado operacional, a cobertura, o caixa. O **Z2** minimiza as **trocas de clínica** — é o lado ergonômico, a estabilidade da agenda do médico. [aponte a figura] Uma troca é isso: o médico mudar de unidade de um dia para o outro. E esses dois objetivos **conflitam**: se eu empurro cobertura ao máximo, tendo a gerar mais trocas; se eu congelo o médico numa unidade, deixo demanda descoberta. [pausa] Mas contar essas trocas tem uma armadilha. [transição]

### 2.6 — Detectando trocas (γ) — *contribuição central*
[tom de "aqui está o pulo do gato"] A armadilha é a seguinte: a agenda tem **lacunas** — dias em que o médico não trabalha. Se eu simplesmente comparo dias consecutivos, eu perco trocas que acontecem **através** dessas lacunas. Exemplo: o médico trabalha na clínica A, folga dois dias, e volta na clínica B. Isso é uma troca, mas a comparação ingênua não vê. [pausa] A solução é uma **variável de estado**, o **γ**, que adaptei do problema de dimensionamento de lotes, o GLSP. O γ carrega qual é a clínica "atual" do médico **mesmo nos dias em que ele não trabalha** — o estado persiste na lacuna. Com isso, a troca passa a ser detectada corretamente. [aponte a figura] Essa é a principal contribuição de modelagem do trabalho. [transição] Com o modelo montado, vamos aos métodos.

---

## §3 — Metodologia e Abordagens

### 3.1 — O método ε-restrito
Como os objetivos conflitam, não existe uma única solução ótima, e sim uma **fronteira de Pareto** — um conjunto de bons compromissos. Para gerá-la, uso o método **ε-restrito**: fixo o Z1 como objetivo e transformo o Z2 numa restrição, "no máximo ε trocas". Variando o ε, obtenho **sete pontos** da fronteira por instância. Um detalhe importante: essa mesma grade de sete pontos é usada por todos os métodos, o que torna a comparação justa, ponto a ponto. [transição]

### 3.2 — MIP-heurísticas
A primeira família aproximada são as MIP-heurísticas, que decompõem o horizonte no **tempo**. [aponte a janela] O **Relax-and-Fix** avança por janelas: resolve uma janela, fixa as decisões, e segue. O **Fix-and-Optimize** faz o oposto: parte de uma solução e reotimiza vizinhanças. E o **Híbrido** junta os dois — constrói com Relax-and-Fix e depois refina com Fix-and-Optimize. [transição]

### 3.3 — Meta-heurística: NSGA-II
A segunda família é evolutiva: o **NSGA-II**, um algoritmo genético multiobjetivo. Ele mantém uma população de escalas e evolui por três mecanismos: ordenação por não-dominância, distância de crowding para preservar diversidade, e elitismo, unindo pais e filhos. Ele já foi pensado para problemas bi-objetivo, então encaixa bem aqui. [transição]

### 3.4 — Operadores customizados
Só que o NSGA-II genérico produziria muita solução inviável. Então desenhei operadores sob medida para o problema: uma amostragem inicial **com consciência das restrições**; um **cruzamento por blocos diários**, que troca dias inteiros entre soluções em vez de genes soltos; e uma **mutação por realocação de slot**. Todos preservam a coerência temporal da agenda. [transição]

### 3.5 — Encoding: Estendido vs Compacto
E aqui está a decisão mais impactante. [aponte] Na versão **Estendida**, o cromossomo carrega todas as variáveis x e w — fica enorme. Na versão **Compacta**, cada gene representa só a associação médico-dia, algo como o w. O resultado é um cromossomo cerca de **70 vezes menor**. E menor cromossomo significa **muito mais gerações** dentro do mesmo tempo — guardem isso, porque é o que faz o Compacto vencer o Estendido nos resultados. [transição] Agora, como testamos tudo isso.

---

## §4 — Experimentos

### 4.1 — Ambiente computacional
Os experimentos rodaram no cluster Euler, do ICMC. Do lado de software, Python, **Gurobi 12** para o método exato e as MIP-heurísticas, e a biblioteca **pymoo** para o NSGA-II. Um limite importante: **3.600 segundos, uma hora, por ponto ε** — é o orçamento de tempo que torna a comparação honesta. [transição]

### 4.2 — Base de dados e pipeline
Os dados são reais, da rede de clínicas: **250 médicos, 37 unidades, cerca de 28 mil registros de exames**, cobrindo **576 dias** de 2022 e 2023. [aponte o pipeline] Criei um pipeline que processa esses dados históricos e, importante, **separa** a base usada para montar o modelo da base usada para validar — para não haver vazamento de informação. [transição]

### 4.3 — Instâncias e protocolo
[aponte o gráfico] Este gráfico mostra demanda e disponibilidade ao longo do tempo — dá para ver a sazonalidade semanal. Avaliei **quatro horizontes aninhados**: 15, 30, 60 e 90 dias, que correspondem ao ciclo real de replanejamento, do quinzenal ao trimestral. Para cada horizonte, dez instâncias, divididas em **duas para calibrar os parâmetros e oito para validar** — quarenta pares no total. Essa separação garante que o desempenho reportado não está viciado nos dados de calibração. [transição]

### 4.4 — Métricas
Por fim, as métricas, em dois eixos. Qualidade da fronteira: **hipervolume**, amplitude e gap de referência. E custo e factibilidade: **MIP gap**, tempo de execução e a **taxa de factibilidade** do genético. Como o problema é multiobjetivo, importam as duas coisas juntas — quão boa é a fronteira e quanto custa obtê-la. [transição] E é aqui que a história fica interessante.

---

## §5 — Resultados e Discussão  *(o coração — desacelere)*

### 5.1 — Transição de regime *(resultado central)*
Este é o resultado central do trabalho. [pausa] Olhem o **MIP gap** do método exato conforme o horizonte cresce: no quinzenal, **4,1%** — o Gurobi praticamente resolve. Aos 30 dias, salta para **42,7%**. Aos 60, **78%**. Aos 90, **quase 97%**. [pausa] Ou seja, existe uma **transição de regime** entre 15 e 30 dias: o método exato só converge no ciclo quinzenal. A partir dos 30 dias, ele satura a hora de processamento sem fechar o problema. [pausa] E isso não é um defeito de implementação — é a natureza combinatória do problema. É exatamente o que justifica precisar de heurísticas. [transição]

### 5.1b — MIP gap: exato vs. MIP-heurísticas
[aponte a tabela] Aqui trago o MIP gap também das MIP-heurísticas, ao lado do exato, todos no **mesmo conjunto de instâncias**. O padrão acompanha o exato: baixo em 15 dias, crescendo até os noventa. [pausa] Mas há uma ressalva técnica que faço questão de registrar: o gap de um método heurístico é medido contra o **seu próprio limitante inferior**, que é mais frouxo. Então o gap do RF pode até parecer maior sem que a solução seja pior — na verdade, como vou mostrar já a seguir, o RF frequentemente tem soluções melhores. O gap, aqui, não é comparação direta de qualidade. [transição]

### 5.2 — Fronteiras de Pareto
Aqui estão as fronteiras dos métodos que **garantem factibilidade** — o exato e as duas MIP-heurísticas. [aponte] Nos 15 dias, os três ficam praticamente colados na fronteira ótima do exato. Agora, uma observação que a banca pode levantar: nos 60 e 90 dias, o **RF parece bater o exato e o Híbrido**. E parece mesmo — mas a explicação é importante: além de 15 dias, **nenhum** método converge; todas essas curvas são apenas os melhores incumbentes encontrados no limite de uma hora. O RF **decompõe** o horizonte em janelas pequenas, e por isso consegue achar incumbentes factíveis melhores no mesmo tempo. Não é otimalidade — é decomposição rendendo uma solução viável melhor num modelo grande demais para resolver inteiro. [pausa] E o **NSGA-II não aparece aqui**: viola a cobertura mínima, então plotá-lo seria comparar o incomparável — mostro os resultados dele em separado, mais adiante. [transição]

### 5.4 — Escalabilidade e tempo
E o custo? [aponte] Enquanto os métodos MIP saturam o tempo — algo como 25 mil segundos para a fronteira inteira — o NSGA-II entrega a fronteira em torno de 3.600 segundos. Na prática, é **cerca de sete vezes mais rápido**. Em ambiente operacional, isso pesa. [transição]

### 5.5 — Parametrização
Sobre a calibração: [aponte o heatmap] a variante **Compacta** entrega hipervolume relativo entre **0,67 e 0,72**, enquanto a Estendida fica em **0,47 a 0,51**. É a confirmação daquilo do encoding: cromossomo menor, mais gerações, melhor fronteira. Nas MIP-heurísticas, as melhores configurações foram janela de 75% para o Relax-and-Fix e 50% para o Híbrido. [transição] E, dentro da própria família meta-heurística, dá para ver isso na fronteira.

### 5.6 — NSGA-II: resultados isolados (Compacto vs Estendido)
[aponte o gráfico] Aqui estão as fronteiras das duas variantes do genético, **lado a lado, isoladas** — comparação dentro da família, não contra o exato. E o resultado é visual: a fronteira do **Compacto** fica deslocada para a **esquerda e para baixo** em relação à do Estendido. Ou seja, para o mesmo nível de trocas, o Compacto entrega **bem menos exames não atendidos**. [pausa] É exatamente o efeito do encoding que mencionei: o cromossomo cerca de 70 vezes menor deixa o algoritmo rodar muito mais gerações no mesmo tempo, e isso se traduz numa fronteira melhor. [transição] Mas — e aqui preciso ser cuidadoso —, há uma ressalva importante sobre essas soluções.

### 5.7 — Factibilidade do NSGA-II  *(o cuidado — seja honesto)*
[tom firme e honesto] É fundamental ler o genético **em separado**. Por quê? Porque **nenhuma** solução do NSGA-II satisfaz a **cobertura mínima**, aquela restrição R6 que pedi para guardarem. [pausa] Isso significa que ele **não é diretamente comparável** aos métodos exato e MIP, que garantem factibilidade. Agora, sendo justo com o método: as restrições **estruturais**, R1 a R4, são respeitadas — 100% na variante Estendida, 89,8% na Compacta. A violação se concentra na cobertura mínima, em torno de 4 a 6% dos períodos. [pausa] Então a mensagem correta é: os resultados do genético devem ser lidos como **tendências e trade-offs dentro da família meta-heurística**, e não como um campeão que bate o exato. E isso aponta, de forma natural, para o próximo passo do trabalho: um operador de reparo. [transição]

### 5.8 — Quadro-resumo: todos os métodos
[aponte a tabela] Para consolidar, este é o quadro com **todos os cinco métodos** lado a lado — hipervolume relativo à esquerda, tempo total à direita, e a coluna de factibilidade. Não precisam ler célula a célula; o que quero que fiquem é o padrão: o **Híbrido colado no exato** em 15 e 30 dias; o **NSGA-II uma ordem de grandeza mais rápido**; e a última coluna, **factível: sim para os três métodos MIP, não para o genético** — que viola apenas a cobertura mínima. E lembrando: onde o hipervolume passa de 1, é porque a referência exata não convergiu. [transição]

### 5.9 — Sumarizando
Resumindo os achados em quatro pontos. Um: o **exato escala mal** — ótimo no quinzenal, inviável a partir dos 30 dias. Dois: entre as MIP-heurísticas, o **Híbrido** é o melhor nos horizontes curtos, e o Relax-and-Fix puro é bem mais rápido. Três: o **NSGA-II Compacto domina o Estendido** em toda linha, graças ao encoding enxuto. E quatro: a **factibilidade parcial** do genético é justamente o que aponta para o trabalho futuro. [transição]

---

## §6 — Conclusões e Perspectivas

### 6.1 — Contribuições e recomendação
Fechando. As contribuições foram cinco: o **modelo bi-objetivo** para múltiplas clínicas autônomas; a variável de estado **γ**, que resolve a detecção de trocas em agendas com lacunas; o **acoplamento** do ε-restrito com as MIP-heurísticas; as variantes **Estendida e Compacta** do NSGA-II com operadores próprios; e a **avaliação sistemática** das três famílias sobre dados reais. [pausa] E disso sai uma recomendação **prática** para a rede: o ciclo **quinzenal** pode usar o método **exato**; do mensal em diante, é preciso heurística — o **Híbrido** quando há tempo de processamento, e o **NSGA-II Compacto** quando o tempo é apertado. [transição]

### 6.2 — Limitações e trabalhos futuros
Sobre limitações, sou transparente: o genético precisa de um mecanismo de reparo; a demanda e a disponibilidade são tratadas como determinísticas; e algumas regras ergonômicas ainda estão fora do modelo. Isso abre as frentes futuras: desenvolver o **operador de reparo** da cobertura; tratar a demanda de forma **estocástica**, com reprogramação online; usar **aprendizado de máquina** para prever demanda e gerar bons pontos de partida; e, por fim, uma **pipeline híbrida** que combine método exato e meta-heurística num só fluxo. [pausa]

Com isso eu encerro. O trabalho trata, de forma conjunta, múltiplas unidades e a minimização de trocas — uma combinação pouco explorada na literatura. [pausa] **Muito obrigado pela atenção. Fico à disposição da banca para as perguntas.**

---

## Perguntas — táticas rápidas
- Respire antes de responder. **Repita a pergunta em voz alta** — organiza a resposta e ganha tempo.
- Responda o núcleo primeiro, depois detalhe.
- Se for sobre a factibilidade do genético: reafirme que **os resultados são apresentados como tendências**, que as estruturais R1–R4 são respeitadas, e que o reparo é trabalho futuro assumido.
- Não sabe? "Não avaliei isso diretamente, mas é uma boa direção — encaixa no que apontei como trabalho futuro."
