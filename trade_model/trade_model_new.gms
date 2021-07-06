**********************************************************************
*** define sets and parameters for trade exports and imports
**********************************************************************
SETS
  ttot                                                                      'Loaded times'
  all_regi                                                                  'Loaded regions'
  teTranspMode                                                              'Technologies for transportation mode'          
      / shipping, pipeline /
  all_enty                                                                  'Quantities traded in the network topology'  
      / pegas /
;

alias(all_regi,regi,regi2,regi3);
alias(all_enty,tradeSe);



**********************************************************************
*** load pooled export and import quantities from GDX files
**********************************************************************
PARAMETERS
    pm_Xport(ttot,all_regi,all_enty)                                        'Export of traded commodity.'
    pm_Mport(ttot,all_regi,all_enty)                                        'Import of traded commodity.'
    p24_Xport_loaded(ttot,all_regi)                                         'Loaded export.'
    p24_Mport_loaded(ttot,all_regi)                                         'Loaded import.'
;

$gdxIn './input_data/pegas_Xports.gdx'
$load ttot = dim1
$load all_regi = dim2
$load p24_Xport_loaded=d
$gdxIn

pm_Xport(ttot,all_regi,'pegas') = p24_Xport_loaded(ttot,all_regi);

display pm_Xport;

$gdxIn './input_data/pegas_Mports.gdx'
$load p24_Mport_loaded=d
$gdxIn

pm_Mport(ttot,all_regi,'pegas') = p24_Mport_loaded(ttot,all_regi);

display pm_Mport;
;



**********************************************************************
*** sanity check: do the global exports and imports add up?
**********************************************************************
PARAMETERS M, X;

PARAMETERS
    total_trade_quant(ttot,all_enty)                                        'Total amount of traded commodities';

loop(ttot,
  M = sum(all_regi,pm_Mport(ttot,all_regi,'pegas'));
  X = sum(all_regi,pm_Xport(ttot,all_regi,'pegas'));
  display M, X;
  if(X < M,
    display 'Less exported than imported!';
  );
  total_trade_quant(ttot,'pegas') = min(M,X);
);



**********************************************************************
*** define constraints: which regions are allowed to trade with which?
**********************************************************************
PARAMETERS
    p24_constraints(all_regi,all_regi,all_enty,teTranspMode)                'Which regions can trade with each other?'
    p24_disallowed(all_regi,all_regi,all_enty,teTranspMode)                 'Opposite of p24_constraints'
    p24_constraints_load1(all_regi,all_regi)
    p24_constraints_load2(all_regi,all_regi)
;

$gdxIn './input_data/constraints_pipeline.gdx'
$load p24_constraints_load1=d
$gdxIn

p24_constraints(regi,regi2,'pegas','pipeline') = p24_constraints_load1(regi,regi2);

$gdxIn './input_data/constraints_shipping.gdx'
$load p24_constraints_load2=d
$gdxIn

p24_constraints(regi,regi2,'pegas','shipping') = p24_constraints_load2(regi,regi2);

display p24_constraints;

p24_disallowed(all_regi,all_regi,tradeSe,teTranspMode) = 1 - p24_constraints(all_regi,all_regi,tradeSe,teTranspMode);



**********************************************************************
*** define distances: how far apart are the regions?
**********************************************************************
PARAMETERS
    p24_distance(all_regi,all_regi)                                         'How far apart are regions?'
;

$gdxIn './input_data/distance.gdx'
$load p24_distance=d
$gdxIn

display p24_distance;



**********************************************************************
*** sanity check: is the distance matrix symmetric?
**********************************************************************
PARAMETERS d1, d2, diff;

loop(regi,
  loop(regi2,
    d1 = p24_distance(regi,regi2);
    d2 = p24_distance(regi2,regi);
    diff = d2-d1
    display diff;
  );
);



**********************************************************************
*** load prices from GDX file
**********************************************************************
PARAMETERS
  pm_exportPrice(ttot,all_regi,all_enty)                                    'Export of traded commodity.'
  pm_pvp_pegas(ttot)                                                        'Loaded pvp prices.'
;

***pm_exportPrice(ttot,regi,tradePe) = pm_pvp(ttot,tradePe);
***pm_exportPrice(ttot,regi,tradeSe) = pm_SEPrice(ttot,regi,tradeSe);

$gdxIn './input_data/pm_pvp_pegas.gdx'
$load pm_pvp_pegas=d
$gdxIn

loop(regi,
  pm_exportPrice(ttot,regi,'pegas') = pm_pvp_pegas(ttot);
);



**********************************************************************
*** optimisation / disaggregation
**********************************************************************
PARAMETERS
  p24_transpcost_perdistance(teTranspMode)                                'Transportation cost per distance'
      / pipeline 1
        shipping 3 /
  p24_transpcost_disallowed(teTranspMode)                                 'Transportation cost for disallowed trade partners'
      / pipeline 5000
        shipping 300 /
;

EQUATION  q24_objfunc_opttransp                                           'Objective function for optimisation inside trade module';
VARIABLE  v24_objvar_opttransp                                            'Objective variable for optimisation inside trade module';

POSITIVE VARIABLES
  v24_shipment_quan(ttot,all_regi,all_regi,all_enty,teTranspMode)         'Shipment quantities for different transportation modes'
  v24_shipment_cost(ttot,all_regi,all_enty)                               'Total transportation cost'
  v24_nonserve_cost(ttot,all_regi,all_enty)                               'Total cost arising from non-serviced transportation'
;
VARIABLES
  v24_purchase_cost(ttot,all_regi,all_enty)                               'Total income or expense generated from trade'
  vm_budget(ttot,all_regi)                                                'Budget of regions'
;

v24_shipment_quan.lo(ttot,all_regi,all_regi,all_enty,teTranspMode) = 0.0;
v24_shipment_cost.lo(ttot,all_regi,all_enty) = 0.0;
v24_nonserve_cost.lo(ttot,all_regi,all_enty) = 0.0;

EQUATIONS
  q24_totMport_quan(ttot,all_regi,all_enty)                               'Total imports of each region must equal the demanded imports'
  q24_shipment_cost(ttot,all_regi,all_enty)                               'Total transportation cost'
  q24_nonserve_cost(ttot,all_regi,all_enty)                               'Total cost arising from non-serviced transportation'
  q24_purchase_cost(ttot,all_regi,all_enty)                               'Total income or expense generated from trade'
  qm_budget(ttot,all_regi)                                                'Budgets of regions'
;

q24_totMport_quan(ttot,regi,tradeSe)..
    pm_Mport(ttot,regi,tradeSe) =e= sum(  (regi2,teTranspMode), v24_shipment_quan(ttot,regi2,regi,tradeSe,teTranspMode)  );

v24_shipment_quan.fx(ttot,regi,regi2,tradeSe,teTranspMode)$sameAs(regi,regi2) = 0.0;

v24_shipment_quan.fx(ttot,regi,regi2,tradeSe,teTranspMode)$(p24_constraints(regi,regi2,tradeSe,teTranspMode) lt 1.0) = 0.0;

q24_shipment_cost(ttot,regi,tradeSe)..
    v24_shipment_cost(ttot,regi,tradeSe) =e= sum(  (regi2,teTranspMode), v24_shipment_quan(ttot,regi2,regi,tradeSe,teTranspMode) * p24_transpcost_perdistance(teTranspMode) * p24_distance(regi,regi2)  );
    
q24_nonserve_cost(ttot,regi,tradeSe)..
    v24_nonserve_cost(ttot,regi,tradeSe) =e= sum(  (regi2,teTranspMode), v24_shipment_quan(ttot,regi2,regi,tradeSe,teTranspMode) * 10000 * p24_transpcost_disallowed(teTranspMode) * p24_disallowed(regi,regi2,tradeSe,teTranspMode)  );
    
q24_purchase_cost(ttot,regi,tradeSe)..
    v24_purchase_cost(ttot,regi,tradeSe)
  =e=
    sum(  (regi2,teTranspMode), v24_shipment_quan(ttot,regi2,regi,tradeSe,teTranspMode) * pm_exportPrice(ttot,regi2,tradeSe)  )
  - sum(  (regi2,teTranspMode), v24_shipment_quan(ttot,regi,regi2,tradeSe,teTranspMode) * pm_exportPrice(ttot,regi ,tradeSe)  )
;

    
qm_budget(ttot,regi)..
    vm_budget(ttot,regi)
  =e=
    sum(tradeSe, v24_shipment_cost(ttot,regi,tradeSe))
  + sum(tradeSe, v24_purchase_cost(ttot,regi,tradeSe))
***  + sum(tradeSe, v24_nonserve_cost(ttot,regi,tradeSe))
;


q24_objfunc_opttransp..
    v24_objvar_opttransp
  =e= 
    sum(  (ttot,regi), vm_budget(ttot,regi)  )
;

Model transport / all /;

solve transport using lp minimizing v24_objvar_opttransp;

display v24_shipment_quan.l;

execute_unload './output_data/results.gdx', v24_shipment_quan;
