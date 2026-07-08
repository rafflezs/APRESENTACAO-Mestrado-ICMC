# Capitulo 3 - Problem Definition

The problem considered in this study consists of allocating medical professionals in the field of ultrasound and diagnostic imaging to a network of clinics based on a real problem in a large city in Brazil, with the aim of meeting the demand for exams requested for the period according to the availability of each professional. Both availability and demand are discrete values, which, when not known in advance, are estimated based on the average time of a consultation, estimated at 15 minutes for this type of exam, as pointed out by the Regional Council of Paraná.

The employment contract for professionals allows for free agreement, for all intents and purposes, with the management of the units, ensuring flexibility, as professionals can negotiate the days of the week and shifts in which they will work. The company, in turn, hires professionals based on the forecast of exams at its units and the availability of rooms.
There are no administrative restrictions on transferring a professional between units, provided that they are contractually associated with the new clinic and that this change does not occur between shifts on the same day.

With the proposal to generate allocation grids for the entire planning horizon, the company applies heuristic methods based on historical data, while employing statistical methods (such as machine learning regressions) to determine future demand values for that same horizon. The process of allocating physicians is done manually by the operations department, seeking to comply with contractual and operational standards, associating a professional with a schedule, using as the main quality metrics of the solution the total number of exams not attended and the coverage of the clinics, which allow viewing and implementing possible adjustments. However, as this task is performed manually, it demands time from the department and generates solutions without a guarantee of optimality.

The table below presents the hypotheses raised for the development of the model based on the operating rules and administrative compliance requirements used by network management. This study therefore considers a scheduling problem in which several units with different equipment demands and availabilities must be served simultaneously. 


**Table: Hypotheses raised regarding the nature of the problem.**

| Hypothesis | Description |
|---|---|
| *H1* | All clinics must be served, even if with minimal coverage |
| *H2* | A doctor must be associated with only one unit per day |
| *H3* | Each doctor must be associated with a clinic room |
| *H4* | A doctor performs a certain number of exams based on the unit's demand |
| *H5* | The difference between visits and demand is called unmet exams |
| *H6* | Given the irregular schedule of doctors, there is no limit to the total number of reassignments/exchanges between clinics |
| *H7* | Assuming an initial allocation condition prior to the current planning horizon, possible reassignments are minimized |

For this type of care, therefore, it is necessary to assign a physician to a room, without overlapping or conflicting schedules. Once assigned to a unit for the day, the professional cannot be reassigned to another clinic, even if they are available to work during the opposite shift. These schedules should be designed to minimize the number of unattended exams and avoid the transfer of professionals between units, as discussed in the following sections.

## Mathematical Modeling

The problem is modeled as an integer optimization, in which each doctor can be assigned to a maximum of one unit per shift, without the possibility of working in more than one unit in the same period, respecting their availability.  A period is defined as the day of the week, which is divided into shifts. Each day of the week has two shifts (morning and afternoon), including Sunday, even if there is no afternoon demand. In addition, the number of professionals allocated cannot exceed the capacity of the unit, defined by the number of rooms available for exams. Finally, whenever a unit has demand in a period and shift, at least one physician must be allocated to it to ensure minimum coverage of the unit.


**Indices and sets**

| Index | Description |
|---|---|
| $i ∈ I $ | Physicians |
| $u ∈ U $ | Units |
| $U_i $ | Units served by physician $i$ |
| $I_u $ | Physicians who work at unit $u$ |
| $t ∈ T $ | Shifts |
| $d ∈ D $ | Days |

| Parameter | Description |
|---|---|
| $e_{udt}$  | Demand for exams at unit $u$ on day $d$ and shift $t$ |
| $s_{ut}$  | Rooms available for exams at unit $u$ on day $d$ and shift $t$ |
| $q_{idt}$ | Number of exams that doctor $i$ can perform on day $d$ and shift $t$ |
| $a_{idt}$ |  1, if doctor $i$ is available to work on day $d$ and shift $t$; 0 otherwise. |
| $b_{udt}$ |  1, if unit $u$ has demand on day $d$ and shift $t$; 0 otherwise. |

| Variable | Description |
|---|---|
| $x_{iudt}$ | 1 if physician $i$ is assigned to unit $u$ on day $d$ and shift $t$; 0 otherwise. |
| $w_{iud}$ | 1 if doctor $i$ is assigned to unit $u$ during day $d$; 0 otherwise. |

The parameter $q_{idt}$ is calculated based on the number of hours in the shift and the fact that each exam takes an average of 15 minutes. The constraints are presented below:

$$\begin{alignat}{2}
    \sum_{u \in U_i} x_{iudt} \leq a_{idt}  \quad & \forall i \in I, d \in D, t \in T \\
	\sum_{u \in U_i} w_{iud} \leq 1  \quad & \forall i \in I, d \in D \\
	x_{iudt} \leq w_{iud} \quad & \forall i \in I, u \in U, d \in D, t \in T_d \\
    w_{iud} = 0 \quad & \forall i \in I, u \notin U_i, d \in D \\
	\sum_{i \in I_u} x_{iudt} \leq s_{udt} \quad & \forall u \in U, d \in D, t \in T \\
	\sum_{i \in I_u}x_{iudt} \geq b_{udt} \quad & \forall u \in U, d \in D, t \in T \\
	x_{iudt}, w_{iud} \in \{0,1\} \quad & \forall i \in I, u \in U, d \in D, t \in T\\
\end{alignat}$$

The set of constraints ensures that the doctor will only be assigned to a given unit on a given day and shift if and only if he or she is available to work during that period. The restrictions ensure that the professional will only be assigned to one unit per day, regardless of how many shifts they work, and ensures that they cannot work in clinics with which they are not associated. The number of physicians allocated per shift is limited by the number of rooms available at the unit, subject to restrictions. On the other hand, restrictions indicate that, if there is demand for work at the unit, at least one professional must be allocated to ensure minimum coverage of the clinic. The restrictions define the domain of the variables.

### Objective Functions

The investigation of the hypotheses mentioned in Table \ref{tab:modeling-hypotheses} provided the study with distinct objectives to be investigated: the coverage of clinical exams and the relocation of physicians throughout the planning horizon. Both cases have direct implications for modeling and solving the problem. This section therefore proposes the study of the two objective functions and the implementation of a bi-objective function.

#### FO1 - Minimize Missed Exams

As discussed at the beginning of this section, the demand $e_{udt}$ for exams to be performed for a unit in any given period is known, even if only by estimate, just as the availability of care $a_{idt}$ and the number of possible exams $q_{idt}$ for a physician per day and per period are known. An unattended exam is therefore considered to be the surplus of exams that could not be attended by the doctors available at the time, introducing into the model the constraints that compute the differences for each clinic in all periods. To model this situation, new variables $c_{udt}$ are considered, representing the number of examinations not attended to in unit $u$, in shift $t$, on day $d$.

$$\begin{alignat}{2}
    c_{udt} \geq e_{udt} - \sum_{i \in I_u}(q_{iut} \cdot x_{iudt}) \quad & \forall u \in U, d \in D, t \in T \\
	c_{udt} \in \mathbb{Z}^{*}_{+} \quad & \forall i \in I, u \in U, d \in D, t \in T
\end{alignat}$$

Thus, the system can be modeled in this case as a minimization problem, seeking to obtain the smallest possible number of unmet exams throughout the entire planning horizon.

$$\begin{equation} 
    \min \sum_{u \in U}\sum_{d \in D}\sum_{t \in T} c_{udt}
\end{equation}$$

#### FO2 - Minimize Clinic Transfers

For this problem, a change is defined as any action of transferring a professional from one clinic to another between days. Taking Figure \ref{fig:ex-troca-medico} as an example, the transfer check is binary (whether or not the doctor changed clinics between days), due to the restriction that prevents the clinician from working in more than one unit on the same day. The unit worked on the current day and the previous day ($d$ and $d-1$) are compared. It is evident that if the professional does not work on at least one of the days of the verification, the exchange should not be counted.

**Critical challenge:** When a physician has gaps in their schedule (non-working days), we must track which clinic they are "assigned to" even when not actively working. Simply comparing consecutive working days fails to detect swaps that occur across gaps. For example, if a physician works at clinic U01 on days 1-2, doesn't work on days 3-4, then works at clinic U02 on day 5, this represents a swap from U01 to U02 that must be detected.

**State preservation with gamma variable:** We introduce a state variable $\gamma_{iud}$ that tracks which clinic a physician is conceptually "at" on each day, regardless of whether they are actively working. This state persists through non-working days, enabling correct swap detection across schedule gaps.

We introduce the parameter $CI$, a vector of size $|I|$, representing the clinic to which the professional was assigned in a period prior to the planning horizon. It is also possible that, if there is no initial condition, all values of the vector are $0$, i.e., the physician did not work at any clinic previously. Consider the new variable to capture the exchanges, $z_{it}$, which assumes 1 if professional $i$ changed units in period $t$. 

**Parameters**

| Parameter | Description |
|---|---|
| $CI_{i}$ | Unit to which professional $i$ was assigned on the day preceding $d=1$ (on day $d=0$) |

**Additional Variables**

| Variable | Description |
|---|---|
| $\gamma_{iud}$ | 1, if physician $i$'s state is clinic $u$ on day $d$ (even if not working); 0 otherwise. |

**Gamma state variable definition constraints:**

| Constraint | Formula |
|---|---|
| Gamma definition | $\gamma_{iud} \geq w_{iud} \quad \forall i \in I,\; u \in U,\; d \in D$ |
| Gamma preservation | $\displaystyle \sum_{u \in U_i} \gamma_{iud} = 1 \quad \forall i \in I,\; d \in D$ |

The constraints def}) ensure that if a physician works at a clinic on day $d$, their state is set to that clinic. The constraints preserve}) ensure that exactly one clinic remains as the physician's "current" state on each day, preserving state through non-working days.

**Initial condition constraint:**

$$\begin{alignat}{2}
    \gamma_{i,CI_i,0} = 1 \quad & \forall i \in I
\end{alignat}$$

This sets the initial state (day $d=0$) to the physician's initial clinic assignment.

**Swap detection with gamma:**

$$\begin{alignat}{2}
    z_{i1} \geq \gamma_{iu1} + \gamma_{i,CI_i,0} - 1  \quad & \forall i \in I, u \in U_i, u \neq CI_i
\end{alignat}$$

The restrictions verify exchanges between the first day of the horizon ($d=1$) and the initial condition. Only if the physician's state on day 1 differs from their initial clinic $CI_i$ is an exchange detected.

$$\begin{alignat}{2}
	z_{id} \geq \gamma_{iud} + \sum_{u' \in U_i, u' \neq u} \gamma_{i,u',d-1} - 1 \quad & \forall i \in I, u \in U_i, d \in D \setminus \{1\}
\end{alignat}$$

The constraints compute the exchanges for days $d > 1$. A swap is detected if the physician's state on day $d$ (clinic $u$) differs from their state on day $d-1$ (any clinic $u' \neq u$). Because gamma preserves state through non-working days, this correctly detects swaps across schedule gaps.

**Objective function:**

$$\begin{equation} 
    \min \sum_{i \in I}\sum_{d \in D} z_{id}
\end{equation}$$

The ultimate goal of the function is therefore to minimize the total number of exchanges between clinics for all professionals throughout the execution period, given an initial allocation condition. The gamma state variable ensures swaps are correctly counted even when physicians have irregular schedules with gaps.