$eolcom ->
$onecho > SimData.txt
Par=NodeData Rng=Transmission!J1:R70 Cdim=1 Rdim=1
Par=LineData Rng=Transmission!A1:H74 Cdim=1 Rdim=1
Par=DGData Rng=Generation!A1:L7 Cdim=1 Rdim=1
Par=ReactivePower Rng=Reactive!A1:Y70 Cdim=1 Rdim=1
Par=ActivePower Rng=Active!A1:Y70 Cdim=1 Rdim=1
Par=Renewabels Rng=Generation!A15:E39 Cdim=1 Rdim=1
Par=DR_Priority_Factor Rng=Generation!k9:L13 Cdim=1 Rdim=1
Par=StorageData Rng=Generation!A9:I12 Cdim=1 Rdim=1
$offecho

Sets
l        Feeder Index /l01*l73/
g        Gen Index /g1*g6/
n        Bus Node Index /n01*n69/
t        Time Index      /t01*t24/
d        DR blocks /d1*d4/
comp     Island indices /c1*c69/
k        EES Index /k1*k3/;

Alias(n,n2,m);
Alias (comp,c);

Sets
visited(n),adj(n,m),queue(n),visited(n),activeIslands(comp),keepSLK(g,n),Master(g,n);
Parameters
NodeData(n,*),LineData(l,*),DGData(g,*),SLK(g,n),ActivePower(n,t),ReactivePower(n,t),Renewabels(t,*),DR_Priority_Factor(d,*),StorageData(k,*);

$call gdxxrw SimData.xlsx log=gdxxrw.log trace=3 squeeze='N' @SimData.txt
$gdxin SimData.gdx
$load NodeData,LineData,DGData,ActivePower,ReactivePower,Renewabels,DR_Priority_Factor,StorageData
$gdxin

*######################################################################################################################*
*                                         -Inputs Scalars,Parameters,Variables-                                        *
*######################################################################################################################*
Scalars
BigM,SBase,VBase,ZBase,DR_BlockFraction /0.25/,maxSg,countAtMax,compCounter /0/,minENS /1e10/, bestScenNum /0/;
Parameters
MapNL(n,l),MapNNL(n,m,l),MapNN(n,m),MapGN(g,n),r(l),x(l),b(l),Sl_max(l),Sg_max(g),C_a(g),C_b(g),C_c(g),Bl(l)
Gl(l),Z2(l),V_Max(n),V_Min(n),y0(l),Pg_min(g),Pg_max(g),Qg_max(g),Vmin(m),Vmax(m),Imin(l),Imax(l),Priority(n),PF(n)
Lambda(n),EMG(n),Pr_L(n),Pr_DR(n,d),P_DR_step(n,d,t),componentID(n),hasSLK(comp),compSg(g,n),componentID(n),slkCount(comp)
nodesInComponent(n, comp),hasSLK_byNode(n),Best_TableBus_L(n,t,*),Best_TableLine_L(l,t,*),Best_LossOld(*)
Best_Func(*),Best_TableDR_Status(n,d,t,*),Best_TableDR_Used(n,d,t,*),Best_TableDR_Gamma(n,d,t,*),Best_TableDR_Total(n,t,*)
Best_TableDR_LoadStatus(n,t,*);
Variables
OF,Lp(n),Lq(n),Pl(l,t),Ql(l,t),Qg(g,t),Theta(n,t),P_DR(n,t),P_Restored(n,t),Q_Restored(n,t);
Positive Variables
Pg(g,t),P_Loss(l,t),Q_Loss(l,t),V2(n,t),I2(l,t),McCormick(m,l,t),ActiveLoadShedding(n,t),ReactiveLoadShedding(n,t)
gamma_DR(n,d,t),DR_step_Used_Status(n,d,t);
Binary Variables
y(l),alpha(n,m,l,t),LoadShedding(n,t),nu(n,m,t),DR_step_Status(n,d,t),LoadStatus(n,t),EES_DischargeStopped(k,t);
Parameters
MapEES(k,n),E_Chr_max(k),E_Dechr_max(k),E_min(k),E_max(k),P_Chr_max(k),P_Dechr_max(k),E0(k);
Positive Variables
E_EES(k,t),P_Chr(k,t),P_Dchr(k,t);
Binary Variables
I_Chr(k,t),I_Dchr(k,t);


Positive Variables
    LoadInterruption(n,t);
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

Loop((k,n),
If(Ord(n)=StorageData(k,'BN'),MapEES(k,n)=1);
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


P_Chr_max(k)=StorageData(k,'P_CH');
P_Dechr_max(k)=StorageData(k,'P_DCH');
E_Chr_max(k)=StorageData(k,'Et_Ch');
E_Dechr_max(k)=StorageData(k,'Et_DCH');
E_min(k)=StorageData(k,'Emin');
E_max(k)=StorageData(k,'Emax');
E0(k)=StorageData(k,'E0');


*ActivePower('n29',t) = ActivePower('n29',t) - Renewabels(t,'pvnorm');
*ActivePower('n31',t) = ActivePower('n31',t) - Renewabels(t,'windnorm');
Pg.fx('g4',t) = Renewabels(t,'pvnorm');
Pg.fx('g3',t) = Renewabels(t,'windnorm');
Pg.up('g1',t) = 0;


y.l(l)=y0(l);

y.fx(l) = y0(l);

y.fx('l01')=0;
y.fx('l14')=0;
y.fx('l20')=0;
y.fx('l40')=0;
y.fx('l41')=0;
y.fx('l60')=0;

* Unfix only the lines l33 to l37 to allow switching
loop(l$(ord(l) >= 69 and ord(l) <= 73),
    y.up(l) = 1;
    y.lo(l)=0;
);

Binary Variables
LoadSupplied(n,t);


Lambda(n)$(NodeData(n,'DR')=1)=1;
EMG(n)$(NodeData(n,'PrivateMG')=1)=1;
Pr_DR(n,d)$Lambda(n) = DR_Priority_Factor(d,'Value');
PF(n) = NodeData(n,'PF');
P_DR_step(n,d,t)$Lambda(n) = DR_BlockFraction * ActivePower(n,t);


Parameter TableRestoredLoads(n,t,*),TableStorage(k,n,t,*);

*######################################################################################################################*
*                                                 -Equations-                                                          *
*######################################################################################################################*
$include Equations.gms
*######################################################################################################################*
*                                           -Model Definition & Option Settings-                                       *
*######################################################################################################################*

Model Main_L/ALL/
Option MIQCP=CPLEX;
Option MINLP=SCIP;
Option resLim=216000;
Option Optcr=0.0001;
Option Optca=0;


$include IslandSearch.gms

Solve Main_L Using MIQCP maximizing OF;

Best_TableBus_L(n,t,'Voltage_Mag')=round(sqrt(V2.l(n,t)),5);
Best_TableBus_L(n,t,'Gen_P')=round(Sum(g$MapGN(g,n),Pg.l(g,t)),5);
Best_TableBus_L(n,t,'Load_P')=round(ActivePower(n,t),5);
Best_TableLine_L(l,t,'Bus_F')=LineData(l,'From');
Best_TableLine_L(l,t,'Bus_T')=LineData(l,'To');
Best_TableLine_L(l,t,'P_F2T')=round(Pl.l(l,t),5);
Best_TableLine_L(l,t,'P_T2F')=round(-Pl.l(l,t),5);
Best_TableLine_L(l,t,'P_Loss')=round(P_Loss.l(l,t),5);
Best_LossOld('Total_Loss')=Sum((l,t),P_Loss.l(l,t));
Best_Func('OF') = OF.l;
Best_TableDR_Status(n,d,t,'Status')$Lambda(n) = round(DR_step_Status.l(n,d,t),5);
Best_TableDR_Used(n,d,t,'Used')$Lambda(n) = round(DR_step_Used_Status.l(n,d,t),5);
Best_TableDR_Gamma(n,d,t,'Gamma')$Lambda(n) = round(gamma_DR.l(n,d,t),5);
Best_TableDR_Total(n,t,'P_DR')$Lambda(n) = round(P_DR.l(n,t),5);
Best_TableDR_LoadStatus(n,t,'Status') = round(LoadStatus.l(n,t),5);
TableStorage('k1',n,t,'Storage')$MapEES('k1',n) = round(E_EES.l('k1',t), 5);
TableStorage('k2',n,t,'Storage')$MapEES('k2',n) = round(E_EES.l('k2',t), 5);
TableStorage('k3',n,t,'Storage')$MapEES('k3',n) = round(E_EES.l('k3',t), 5);
*TableStorage('k4',n,t,'Storage')$MapEES('k4',n) = round(E_EES.l('k4',t), 5);
TableRestoredLoads(n,t,'Restored') = round(P_Restored.l(n,t), 5);
TableRestoredLoads(n,t,'Unrestored') = round(ActivePower(n,t)-P_Restored.l(n,t), 5);
TableRestoredLoads(n,t,'Priority') = Priority(n);

Binary Variables
OpenedSW(l);

Loop(l,If(y.l(l)=0, OpenedSW.l(l) = 1););


nodesInComponent(n,comp)$(componentID(n) = Ord(comp)) = 1;


Display nodesInComponent, y.l;

$include Store.gms
