Equations
EquationObj,Equation01,Equation02,Equation03a,Equation03b,Equation04,Equation05,Equation06,Equation07
Equation08,Equation09,Equation10,Equation11,Equation12,Equation13,Equation14,Equation15,Equation16,Equation17,Equation18,Equation19
Equation20,Equation21,Equation22,Equation23,Equation24,Equation25,Equation26,Equation27,Equation28,Equation29,Equation30,Equation31
Equation32,Equation33,Equation34,Equation35,Equation36,Equation37,Equation38,Equation39,Equation40,Equation41,Equation42,Equation43
Equation44,Equation45,Equation46,Equation47,Equation48,Equation49,Equation50,Equation51,Equation52,Equation53,Equation54,Equation55,Equation56,Equation57;

EquationObj..                                              OF =e=Sum((n,t), Priority(n)*LoadStatus(n,t))
                                                           -Sum((n,d,t)$Lambda(n), Priority(n)*Pr_DR(n,d)*DR_step_Status(n,d,t))
                                                           +Sum((n,t), 1000*LoadStatus(n,t));

Equation01(n,t)..                         -Sum(l,Pl(l,t)*MapNL(n,l)+(SBase*P_Loss(l,t))$(MapNL(n,l)=1))+Sum(g$MapGN(g,n),Pg(g,t))+Sum(k$MapEES(k,n), P_Dchr(k,t) - P_Chr(k,t))=e=P_Restored(n,t);
Equation02(n,t)..                         -Sum(l,Ql(l,t)*MapNL(n,l)+(SBase*Q_Loss(l,t))$(MapNL(n,l)=1))+Sum(g$MapGN(g,n),Qg(g,t))=l=Q_Restored(n,t);

Equation56(n,t)$(not Lambda(n))..
    -Sum(l,Ql(l,t)*MapNL(n,l)+(SBase*Q_Loss(l,t))$(MapNL(n,l)=1))+Sum(g$MapGN(g,n),Qg(g,t)) =g= Q_Restored(n,t);


Equation03a(l,n,m,t)$MapNNL(n,m,l)..                       V2(n,t)-V2(m,t)=g=2*(Pl(l,t)*R(l)+Ql(l,t)*X(l))/SBase+Z2(l)*I2(l,t)-(1-y(l))*BigM;
Equation03b(l,n,m,t)$MapNNL(n,m,l)..                       V2(n,t)-V2(m,t)=l=2*(Pl(l,t)*R(l)+Ql(l,t)*X(l))/SBase+Z2(l)*I2(l,t)+(1-y(l))*BigM;
Equation04(l,t)..                                          P_Loss(l,t)=e=R(l)*I2(l,t);
Equation05(l,t)..                                          Q_Loss(l,t)=e=X(l)*I2(l,t);
Equation06(n,m,l,t)$MapNNL(n,m,l)..                        nu(n,m,t)+nu(m,n,t)=e=y(l);
Equation07(g,n,t)$Master(g,n)..                            Sum(m$MapNN(n,m),nu(m,n,t))=e=0;
Equation08(n,t)..                                          Sum(m$MapNN(n,m),nu(m,n,t))=l=1;
Equation09(l,t)..                                          Pl(l,t)=l=BigM*y(l);
Equation10(l,t)..                                          Pl(l,t)=g=-BigM*y(l);
Equation11(l,t)..                                          Ql(l,t)=l=BigM*y(l);
Equation12(l,t)..                                          Ql(l,t)=g=-BigM*y(l);
Equation13(l,t)..                                          I2(l,t)=g=(Pl(l,t)/SBase)*(Pl(l,t)/SBase)+(Ql(l,t)/SBase)*(Ql(l,t)/SBase);
Equation14(g,t)..                                          Pg(g,t)=l=Pg_max(g);
Equation15(g,t)..                                          Qg(g,t)=g=-Qg_max(g);
Equation16(g,t)..                                          Qg(g,t)=l=Qg_max(g);
Equation17(g,t)..                                          Pg(g,t)*Pg(g,t)+Qg(g,t)*Qg(g,t)=l=Sg_max(g)*Sg_max(g);
Equation18(g,t)..                                          Pg(g,t)=g=0;
Equation19(l,n,m,t)$MapNNL(n,m,l)..                        McCormick(m,l,t)=g=(Pl(l,t)/SBase)*(Pl(l,t)/SBase)+(Ql(l,t)/SBase)*(Ql(l,t)/SBase);
Equation20(l,n,m,t)$MapNNL(n,m,l)..                        McCormick(m,l,t)=g=Vmin(m)*I2(l,t)+V2(m,t)*Imin(l)-Vmin(m)*Imin(l);
Equation21(l,n,m,t)$MapNNL(n,m,l)..                        McCormick(m,l,t)=g=Vmax(m)*I2(l,t)+V2(m,t)*Imax(l)-Vmax(m)*Imax(l);
Equation22(l,n,m,t)$MapNNL(n,m,l)..                        McCormick(m,l,t)=l=Vmax(m)*I2(l,t)+V2(m,t)*Imin(l)-Vmax(m)*Imin(l);
Equation23(l,n,m,t)$MapNNL(n,m,l)..                        McCormick(m,l,t)=l=V2(m,t)*Imax(l)+Vmin(m)*I2(l,t)-Vmin(m)*Imax(l);
Equation24(l,n,m,t)$MapNNL(n,m,l)..                        McCormick(m,l,t)=l=I2(l,t);
Equation25(n,t)..                                          V2(n,t)=g=0.9*0.9;
Equation26(n,t)..                                          V2(n,t)=l=1.1*1.1;
Equation27(n,t)..                                          ActiveLoadShedding(n,t)=e=LoadShedding(n,t)*ActivePower(n,t);
Equation28(n,t)..                                          ReactiveLoadShedding(n,t)=e=LoadShedding(n,t)*ReactivePower(n,t);
Equation29(g,n,t)$Master(g,n)..                            V2(n,t)=e=1;
Equation30(g,n,t)$Master(g,n)..                            Theta(n,t)=e=0;
Equation31(n,t)$(not Lambda(n))..                          P_Restored(n,t)=e=LoadStatus(n,t)*ActivePower(n,t);
Equation32(n,t)$(not Lambda(n))..                          Q_Restored(n,t)=l=LoadStatus(n,t)*ReactivePower(n,t);
Equation33(n,t)$(EMG(n) and not Lambda(n))..               LoadStatus(n,t)=e=1;
Equation34(n,t)$Lambda(n)..                                P_Restored(n,t)=e=ActivePower(n,t)-P_DR(n,t);
Equation35(n,t)$Lambda(n)..                                Q_Restored(n,t)=e=ReactivePower(n,t)-P_DR(n,t)*PF(n);
Equation36(n,t)$Lambda(n)..                                sum(d, P_DR_step(n,d,t))=l=ActivePower(n,t);
Equation37(n,t)$Lambda(n)..                                P_DR(n,t)=e=sum(d,gamma_DR(n,d,t));
Equation38(n,d,t)$Lambda(n)..                              gamma_DR(n,d,t)=l=P_DR_step(n,d,t)*DR_step_Status(n,d,t);
Equation39(n,d,t)$Lambda(n)..                              gamma_DR(n,d,t)=l=DR_step_Used_Status(n,d,t);
Equation40(n,d,t)$Lambda(n)..                              gamma_DR(n,d,t)=g=DR_step_Used_Status(n,d,t)-P_DR_step(n,d,t)*(1-DR_step_Status(n,d,t));
Equation41(n,d,t)$Lambda(n)..                              gamma_DR(n,d,t)=g=0;
Equation42(n,d,t)$(Lambda(n) and (ord(d) < card(d)))..     DR_step_Used_Status(n,d,t)=g=DR_step_Status(n,d+1,t)*P_DR_step(n,d,t);
Equation43(n,d,t)$(Lambda(n))..                            LoadStatus(n,t)=l=1-DR_step_Status(n,d,t);
Equation44(n,t)$(Lambda(n))..                              LoadStatus(n,t)=g=sum(d$(Lambda(n)),(1-DR_step_Status(n,d,t)))-(card(d)-1);
Equation45(n,d,t)$(Lambda(n) and (ord(d) < card(d)))..     DR_step_Status(n,d,t)=g=DR_step_Status(n,d+1,t);
Equation46(n,t)$(not hasSLK_byNode(n))..                   LoadStatus(n,t) =e= 0;
Equation47(k,t)$(ord(t) > 1)..                             E_EES(k,t)=e=E_EES(k,t-1)+(E_Chr_max(k)*P_Chr(k,t)-(P_Dchr(k,t)/E_Dechr_max(k)));
Equation48(k,t)..                                          E_EES(k,t)=g=E_min(k);
Equation49(k,t)..                                          E_EES(k,t)=l=E_max(k);
Equation50(k)..                                            E_EES(k,'t01') =e= E0(k);
Equation51(k)..                                            E_EES(k,'t24') =l= E_max(k);
Equation52(k,t)..                                          P_Chr(k,t)=l=P_Chr_max(k)*I_Chr(k,t);
Equation53(k,t)..                                          P_Dchr(k,t)=l=P_Dechr_max(k)*I_Dchr(k,t);
Equation54(k,t)..                                          I_Dchr(k,t)+I_Chr(k,t)=l=1;
Equation55(k,t)..                                          I_Dchr(k,t)+I_Chr(k,t)=g=0;
Equation57(n,t)$(ord(t) > 1 and Priority(n) > 0.1)..       LoadStatus(n,t-1) - LoadStatus(n,t) =l= 0;