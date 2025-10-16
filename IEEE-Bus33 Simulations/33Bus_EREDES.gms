$eolcom ->
$onecho > SimData.txt
Par=NodeData Rng=Transmission!J1:R34 Cdim=1 Rdim=1
Par=LineData Rng=Transmission!A1:H38 Cdim=1 Rdim=1
Par=DGData Rng=Generation!A1:L6 Cdim=1 Rdim=1
Par=ReactivePower Rng=Reactive!A1:Y34 Cdim=1 Rdim=1
Par=ActivePower Rng=Active!A1:Y34 Cdim=1 Rdim=1
Par=Renewabels Rng=Generation!A14:E38 Cdim=1 Rdim=1
Par=DR_Priority_Factor Rng=Generation!k8:L12 Cdim=1 Rdim=1
Par=StatusScenarios Rng=Status!A1:F38 Cdim=1 Rdim=1
$offecho

Sets
l        Feeder Index /l01*l37/
g        Gen Index /g1*g5/
n        Bus Node Index /n01*n33/
t        Time Index      /t01*t24/
d        DR blocks /d1*d4/
comp     Island indices /c1*c33/
sc       Scenario Index  /sc5/;

Alias(n,n2,m);
Alias (comp,c);

Sets
visited(n),adj(n,m),queue(n),visited(n),activeIslands(comp),keepSLK(g,n),Master(g,n),activeScenarios(sc);;
Parameters
NodeData(n,*),LineData(l,*),DGData(g,*),SLK(g,n),ActivePower(n,t),ReactivePower(n,t),Renewabels(t,*),DR_Priority_Factor(d,*),StatusScenarios(l,sc);

$call gdxxrw SimData.xlsx log=gdxxrw.log trace=3 squeeze='N' @SimData.txt
$gdxin SimData.gdx
$load NodeData,LineData,DGData,ActivePower,ReactivePower,Renewabels,DR_Priority_Factor,StatusScenarios
$gdxin

*######################################################################################################################*
*                                         -Inputs Scalars,Parameters,Variables-                                        *
*######################################################################################################################*
Scalars
BigM,SBase,VBase,ZBase,DR_BlockFraction /0.25/,maxSg,countAtMax,compCounter /0/,maxENS /0/, bestScenNum /0/;
Parameters
MapNL(n,l),MapNNL(n,m,l),MapNN(n,m),MapGN(g,n),r(l),x(l),b(l),Sl_max(l),Sg_max(g),C_a(g),C_b(g),C_c(g),Bl(l)
Gl(l),Z2(l),V_Max(n),V_Min(n),y0(l),Pg_min(g),Pg_max(g),Qg_max(g),Vmin(m),Vmax(m),Imin(l),Imax(l),Priority(n),PF(n)
Lambda(n),EMG(n),Pr_L(n),Pr_DR(n,d),P_DR_step(n,d,t),componentID(n),hasSLK(comp),compSg(g,n),componentID(n),slkCount(comp)
nodesInComponent(n, comp),OFval(sc), ENSval(sc),hasSLK_byNode(n),Best_TableBus_L(n,t,sc,*),Best_TableLine_L(l,t,sc,*),Best_LossOld(sc,*)
Best_Func(sc,*),Best_TableDR_Status(n,d,t,sc,*),Best_TableDR_Used(n,d,t,sc,*),Best_TableDR_Gamma(n,d,t,sc,*),Best_TableDR_Total(n,t,sc,*)
Best_TableDR_LoadStatus(n,t,sc,*),Best_TableGen_P(g,t,sc,*);
Variables
OF,Lp(n),Lq(n),Pl(l,t),Ql(l,t),Qg(g,t),Theta(n,t),P_DR(n,t),P_Restored(n,t),Q_Restored(n,t);
Positive Variables
Pg(g,t),P_Loss(l,t),Q_Loss(l,t),V2(n,t),I2(l,t),McCormick(m,l,t),ActiveLoadShedding(n,t),ReactiveLoadShedding(n,t)
gamma_DR(n,d,t),DR_step_Used_Status(n,d,t);
Binary Variables
y(l),alpha(n,m,l,t),LoadShedding(n,t),nu(n,m,t),DR_step_Status(n,d,t),LoadStatus(n,t);
*######################################################################################################################*
*                                                 -Numbers for Variables-                                              *
*######################################################################################################################*
BigM=1e4;
SBase=10e3;
VBase=12.66;
ZBase=VBase*VBase/(SBase/1000);
Vmin(m)=0.81;
Vmax(m)=1.21;
Imin(l)=-BigM;
Imax(l)=+BigM;

Loop((n,l),
If(Ord(n)=LineData(l,'From'),MapNL(n,l)=1);
If(Ord(n)=LineData(l,'To'),MapNL(n,l)=-1);
);

Loop((n,m,l),
If((Ord(n)=LineData(l,'From'))$(Ord(m)=LineData(l,'To')),
MapNN(n,m)=1;
MapNN(m,n)=1;
));

Loop((n,m,l),
If((Ord(n)=LineData(l,'From'))$(Ord(m)=LineData(l,'To')),
MapNNL(n,m,l)=1;
r(l)=LineData(l,'R')/ZBase;
x(l)=LineData(l,'X')/ZBase;
));

*######################################################################################################################*
*                                                 -Pulling data to variables-                                          *
*######################################################################################################################*
Priority(n)=NodeData(n,'Priority');

Master(g,n)=No;
Loop((g,n),If((Ord(n)=DGData(g,'BN')and(DGData(g,'SLK')=1)),Master(g,n)=yes));

*Introducing the limits
Sl_max(l)=LineData(l,'SMax')*LineData(l,'Status');

Loop((g,n),
If(Ord(n)=DGData(g,'BN'),MapGN(g,n)=1);
);

C_b(g)=DGData(g,'b');
Pg_min(g)=DGData(g,'Pmin')*DGData(g,'Status');
Sg_max(g)=DGData(g,'Smax')*DGData(g,'Status');
Pg_max(g)=DGData(g,'Pmax')*DGData(g,'Status');
Qg_max(g)=DGData(g,'Qmax')*DGData(g,'Status');
Bl(l)=(LineData(l,'X')/ZBase)/(SQR((LineData(l,'X')/ZBase))+SQR((LineData(l,'R')/ZBase)));
Gl(l)=(LineData(l,'R')/ZBase)/(SQR((LineData(l,'X')/ZBase))+SQR((LineData(l,'R')/ZBase)));
Z2(l)=SQR((LineData(l,'X')/ZBase))+SQR((LineData(l,'R')/ZBase));
y0(l)=LineData(l,'Status');
V_Max(n)=NodeData(n,'Vmax');
V_Min(n)=NodeData(n,'Vmin');


Pg.fx('g4',t) = Renewabels(t,'pvnorm');
Pg.fx('g5',t) = Renewabels(t,'windnorm');
Pg.fx('g1',t) = 0;

Lambda(n)$(NodeData(n,'DR')=1)=1;
EMG(n)$(NodeData(n,'PrivateMG')=1)=1;
Pr_DR(n,d)$Lambda(n) = DR_Priority_Factor(d,'Value');
PF(n) = NodeData(n,'PF');
P_DR_step(n,d,t)$Lambda(n) = DR_BlockFraction * ActivePower(n,t);
Binary variables
NodeSupplied(n);

Binary Variables
LoadSupplied(n,t);

Parameter
Table_OpenedSW(l,sc,*)
Table_slkCount(comp,sc,*)
Table_Master(g, n,sc,*)
Table_hasSLK(comp,sc,*)
Export_nodesInComponent(n, comp,sc,*)
OpenedSW(l);

*######################################################################################################################*
*                                                 -Equations-                                                          *
*######################################################################################################################*
$include Equations.gms
*######################################################################################################################*
*                                           -Model Definition & Option Settings-                                       *
*######################################################################################################################*

Parameter TableRestoredLoads(n,t,sc,*);
Parameter yBest(l);


Model Main_L/ALL/
Option MIQCP=CPLEX;
Option MINLP=SCIP;
Option resLim=216000;
*Option solveopt = clear;
Option Optcr=0.0001;
Option Optca=0;
Option limcol = 0;

Loop(sc,

    y0(l) = StatusScenarios(l,sc);
    y.lo(l) = 0; y.up(l) = 1;
    y.fx(l)$(ord(l) < 33) = y0(l);
    y.l(l)$(ord(l) >= 33 and ord(l) <= 37) = y0(l);


$include IslandSearch.gms

Solve Main_L Using MIQCP maximizing OF;

ENSval(sc) = Sum((n,t), ActivePower(n,t) - P_Restored.l(n,t));


    if (ENSval(sc) > maxENS,
        maxENS = ENSval(sc);
        bestScenNum = ord(sc);
        yBest(l) = y.l(l);
    );


Best_TableBus_L(n,t,sc,'Voltage_Mag')=round(sqrt(V2.l(n,t)),5);
Best_TableBus_L(n,t,sc,'Gen_P')=round(Sum(g$MapGN(g,n),Pg.l(g,t)),5);
Best_TableBus_L(n,t,sc,'Load_P')=round(ActivePower(n,t),5);
Best_TableLine_L(l,t,sc,'Bus_F')=LineData(l,'From');
Best_TableLine_L(l,t,sc,'Bus_T')=LineData(l,'To');
Best_TableLine_L(l,t,sc,'P_F2T')=round(Pl.l(l,t),5);
Best_TableLine_L(l,t,sc,'P_T2F')=round(-Pl.l(l,t),5);
Best_TableLine_L(l,t,sc,'P_Loss')=round(P_Loss.l(l,t),5);
Best_LossOld(sc,'Total_Loss')=Sum((l,t),P_Loss.l(l,t));
Best_Func(sc,'OF') = OF.l;
Best_TableDR_Status(n,d,t,sc,'Status')$Lambda(n) = round(DR_step_Status.l(n,d,t),5);
Best_TableDR_Used(n,d,t,sc,'Used')$Lambda(n) = round(DR_step_Used_Status.l(n,d,t),5);
Best_TableDR_Gamma(n,d,t,sc,'Gamma')$Lambda(n) = round(gamma_DR.l(n,d,t),5);
Best_TableDR_Total(n,t,sc,'P_DR')$Lambda(n) = round(P_DR.l(n,t),5);
Best_TableDR_LoadStatus(n,t,sc,'Status') = round(LoadStatus.l(n,t),5);
TableRestoredLoads(n,t,sc,'Restored') = round(P_Restored.l(n,t), 5);
TableRestoredLoads(n,t,sc,'Unrestored') = round(ActivePower(n,t)-P_Restored.l(n,t), 5);
Best_TableGen_P(g,t,sc,'Pg') = round(Pg.l(g,t), 5);
TableRestoredLoads(n,t,sc,'Priority') = Priority(n);


OFval(sc) = OF.l;

nodesInComponent(n,comp)$(componentID(n) = Ord(comp)) = 1;
Export_nodesInComponent(n, comp,sc,'Nodes in Components') = nodesInComponent(n, comp);


Table_OpenedSW(l,sc,'Opened_Switches')=y.l(l);

Display nodesInComponent, slkCount, Master, hasSLK;

);


Parameter AdjacencyMatrix(n,n);

* Initialize all to 0
AdjacencyMatrix(n,m) = 0;

* Fill the matrix based on the solution
Loop(l$ (yBest(l) = 1),
    Loop((n,m)$MapNNL(n,m,l),
        AdjacencyMatrix(n,m) = 1;
    );
);

Parameter Table_MapNN(n,m);

Table_MapNN(n,m) = AdjacencyMatrix(n,m);

Display y.l, OF.l, ENSval, bestScenNum;

$include Store.gms
