adj(n,m) = 0;
componentID(n) = 0;
visited(n) = no;
queue(n) = no;
compCounter = 0;
activeIslands(comp) = no;
hasSLK(comp) = no;
slkCount(comp) = 0;
compSg(g,n) = 0;
keepSLK(g,n) = Master(g,n);
hasSLK_byNode(n) = 0;
nodesInComponent(n,comp)=0;


adj(n,m) = 0;
Loop(l$(y.l(l) = 1),
  Loop((n,m),
    If((Ord(n)=LineData(l,'From') and Ord(m)=LineData(l,'To')),
      adj(n,m) = 1;
      adj(m,n) = 1;
    );
  );
);


componentID(n) = 0;
visited(n) = no;

Loop(n$(not visited(n)),
  compCounter = compCounter + 1;
  queue(n) = no;
  queue(n) = yes;

  Repeat
    Loop(n2$(queue(n2)),
      visited(n2) = yes;
      componentID(n2) = compCounter;
      queue(n2) = no;
      Loop(m$(adj(n2,m) and not visited(m)),
        queue(m) = yes;
      );
    );
  Until card(queue) = 0;
);

activeIslands(comp) = no;
Loop(n,
  activeIslands(comp)$(Ord(comp) = componentID(n)) = yes;
);


hasSLK(comp) = no;
Loop((g,n)$Master(g,n),
    hasSLK(comp)$(Ord(comp) = componentID(n)) = yes;
);

slkCount(comp) = 0;
Loop((g,n)$Master(g,n),
    slkCount(comp)$(Ord(comp) = componentID(n)) = slkCount(comp) + 1;
);

keepSLK(g,n) = Master(g,n);

Loop(comp$(slkCount(comp) > 1),
    compSg(g,n)$(Master(g,n) and (Ord(comp) = componentID(n))) = Sg_max(g);
    maxSg = smax((g,n)$compSg(g,n), compSg(g,n));
    Loop((g,n)$(Master(g,n) and (Ord(comp) = componentID(n)) and (Sg_max(g) < maxSg)),
        keepSLK(g,n) = no;
    );
    countAtMax = 0;
    Loop((g,n)$(Master(g,n) and (Ord(comp) = componentID(n)) and (Sg_max(g) = maxSg)),
        if(countAtMax = 0,
            countAtMax = 1;
        else
            keepSLK(g,n) = no;
        );
    );
);

Master(g,n) = keepSLK(g,n);
hasSLK(comp) = no;
Loop((g,n)$Master(g,n),
    hasSLK(comp)$(Ord(comp) = componentID(n)) = yes;
);


hasSLK_byNode(n) = 0;
loop((n,comp),
    hasSLK_byNode(n)$(componentID(n) = ord(comp)) = hasSLK(comp);
);
