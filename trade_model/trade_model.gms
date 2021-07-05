**********************************************************************
*** define sets and parameters for trade exports and imports
**********************************************************************
SETS
    ttot            'loaded times'
    all_regi        'loaded regions'
    teSETransp      'technologies for transporting SE' / shipping, pipeline /
;

alias(all_regi,regi,regi2,regi3);

PARAMETERS
    pm_Xport(ttot,all_regi)            "Export of traded commodity."
    pm_Mport(ttot,all_regi)            "Import of traded commodity."
;



**********************************************************************
*** load pooled export and import quantities from GDX files
**********************************************************************
$gdxIn "./input_data/pegas_Xports.gdx"
$load ttot = dim1
$load all_regi = dim2
$load pm_Xport=d
$gdxIn

display pm_Xport;

$gdxIn "./input_data/pegas_Mports.gdx"
$load pm_Mport=d
$gdxIn

display pm_Mport;



**********************************************************************
*** sanity check: do the global exports and imports add up?
**********************************************************************
PARAMETERS M, X;

PARAMETERS
    total_trade_quant(ttot)             "Total amount of traded commodities";

loop(ttot,
  M = sum(all_regi,pm_Mport(ttot,all_regi));
  X = sum(all_regi,pm_Xport(ttot,all_regi));
  display M, X;
  if(X < M,
    display "Less exported than imported!";
  );
  total_trade_quant(ttot) = min(M,X);
);



**********************************************************************
*** define constraints: which regions are allowed to trade with which?
**********************************************************************
PARAMETERS
    pm_constraints(all_regi,all_regi,teSETransp)    "which regions can trade with each other?"
    pm_constraints_load1(all_regi,all_regi)
    pm_constraints_load2(all_regi,all_regi)
;

$gdxIn "./input_data/constraints_pipeline.gdx"
$load pm_constraints_load1=d
$gdxIn

pm_constraints(regi,regi2,"pipeline") = pm_constraints_load1(regi,regi2);

$gdxIn "./input_data/constraints_shipping.gdx"
$load pm_constraints_load2=d
$gdxIn

pm_constraints(regi,regi2,"shipping") = pm_constraints_load2(regi,regi2);

display pm_constraints;



**********************************************************************
*** define distances: how far apart are the regions?
**********************************************************************
PARAMETERS
    pm_distance(all_regi,all_regi)    "how far apart are regions?"
;

$gdxIn "./input_data/distance.gdx"
$load pm_distance=d
$gdxIn

display pm_distance;





**********************************************************************
*** sanity check: is the distance matrix symmetric?
**********************************************************************
PARAMETERS d1, d2, diff;

loop(regi,
  loop(regi2,
    d1 = pm_distance(regi,regi2);
    d2 = pm_distance(regi2,regi);
    diff = d2-d1
    display diff;
  );
);



**********************************************************************
*** optimisation / disaggregation
**********************************************************************
PARAMETERS
  cost_perdistance(teSETransp) "Transportation cost per distance"
      / pipeline 1
        shipping 3 /
  cost_disallowed(teSETransp) "Transportation cost for disallowed trade partners"
      / pipeline 5000
        shipping 300 /
;

POSITIVE VARIABLES
  vm_shipmentquan(ttot, all_regi, all_regi, teSETransp)    'shipment quantities for different transportation modes'
;

VARIABLE  vm_shipmentcost                                   'total transportation cost' ;

EQUATIONS
  eq_cost                      "Total transportation cost"
  eq_totquan(ttot)             "Total traded quantities"
  eq_Xports(ttot, all_regi)    "Total exports"
  eq_Mports(ttot, all_regi)    "Total imports"
;

eq_cost.. vm_shipmentcost =e= sum((ttot, regi,regi2,teSETransp), vm_shipmentquan(ttot,regi,regi2,teSETransp) * ( cost_perdistance(teSETransp) * pm_distance(regi,regi2) + cost_disallowed(teSETransp) * (1-pm_constraints(regi,regi2,teSETransp)) ));

eq_totquan(ttot).. total_trade_quant(ttot) =e= sum((regi,regi2,teSETransp), vm_shipmentquan(ttot,regi,regi2,teSETransp));

eq_Xports(ttot, regi ).. sum((regi2,teSETransp), vm_shipmentquan(ttot,regi,regi2,teSETransp)) =l= pm_Xport(ttot, regi);
eq_Mports(ttot, regi2).. sum((regi,teSETransp),  vm_shipmentquan(ttot,regi,regi2,teSETransp)) =l= pm_Mport(ttot, regi2);

Model transport / all /;

solve transport using lp minimizing vm_shipmentcost;

display vm_shipmentquan.l;

execute_unload './output_data/results.gdx', vm_shipmentquan;
