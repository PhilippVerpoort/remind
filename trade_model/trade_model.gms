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
    p24_distance(all_regi,all_regi)                                         'Distance per regions (in units of 1000km)'
;

$gdxIn './input_data/distance.gdx'
$load p24_distance=d
$gdxIn

p24_distance(regi,regi2) = p24_distance(regi,regi2)/1000;

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
  p_peprice_pegas(ttot,all_regi)                                            'Loaded peprice prices.'
;

***pm_exportPrice(ttot,regi,tradePe) = pm_pvp(ttot,tradePe);
***pm_exportPrice(ttot,regi,tradeSe) = pm_SEPrice(ttot,regi,tradeSe);

$gdxIn './input_data/pm_pvp_pegas.gdx'
$load pm_pvp_pegas=d
$gdxIn

$gdxIn './input_data/p_peprice_pegas.gdx'
$load p_peprice_pegas=d
$gdxIn

loop(regi,
  pm_exportPrice(ttot,regi,'pegas') = p_peprice_pegas(ttot,regi);
);



**********************************************************************
*** Definition of the main characteristics set 'char':
**********************************************************************
SET char          "Characteristics of transport technologies"
/  
  tech_stat       "Technology status: how close a technology is to market readiness. Scale: 0-3, with 0 'I can go out and build a GW plant today' to 3 'Still some research necessary'."
  inco0           "Initial investment costs given in $(2015)/kW(output) capacity. Independent of distance."
  inco0_d         "Initial investment costs given in $(2015)/kW(output) capacity. Per 1000km."
  constrTme       "Construction time in years, needed to calculate turn-key cost premium compared to overnight costs"
  eta             "Conversion efficieny, i.e. the amount of energy NOT lost in transportation. Independent of distance (e.g. conversion processes etc)."
  eta_d           "Conversion efficieny, i.e. the amount of energy NOT lost in transportation. Per 1000km."
  omf             "Fixed operation and maintenance costs given as a fraction of investment costs inco0. Independent of distance."
  omf_d           "Fixed operation and maintenance costs given as a fraction of investment costs inco0_d. Per 1000km."
  omv             "Variable operation and maintenance costs given in $(2015)/kWa energy production. Independent of distance."
  omv_d           "Variable operation and maintenance costs given in $(2015)/kWa energy production. Per 1000km."
  lifetime        "Given in years"
/
;



**********************************************************************
*** load technology characteristics
**********************************************************************
PARAMETERS
  p24_transpcost_perdistance(teTranspMode)                                'Transportation cost per distance (tr$2005/TWa/1000km)'
      / pipeline 0.01
        shipping 0.03 /
  p24_transpcost_disallowed(teTranspMode)                                 'Transportation cost for disallowed trade partners (tr$2005/TWa/1000km)'
      / pipeline 1
        shipping 3 /
;

TABLE p24_dataglob_transp(char,all_enty,teTranspMode)                     'Transportation technology characteristics: investment costs, O&M costs, efficiency, ...'
$include "./input_data/generisdata_transportation.prn"
;


**********************************************************************
*** variables
**********************************************************************
EQUATION  q24_objfunc_opttransp                                           'Objective function for optimisation inside trade module';
VARIABLE  v24_objvar_opttransp                                            'Objective variable for optimisation inside trade module';

POSITIVE VARIABLES
  v24_shipment_quan(ttot,all_regi,all_regi,all_enty,teTranspMode)         'Shipment quantities for different transportation modes'
  v24_shipment_cost(ttot,all_regi,all_enty)                               'Total transportation cost'
  v24_nonserve_cost(ttot,all_regi,all_enty)                               'Total cost arising from non-serviced transportation'
  v24_transpCap(ttot,all_regi,all_regi,all_enty,teTranspMode)             'Net total capacities for transportation'
  v24_transpDeltaCap(ttot,all_regi,all_regi,all_enty,teTranspMode)        'Capacity additions for transportation'
;
VARIABLES
  v24_purchase_cost(ttot,all_regi,all_enty)                               'Total income or expense generated from trade'
  vm_budget(ttot,all_regi)                                                'Budget of regions'
;

v24_shipment_quan.lo(ttot,all_regi,all_regi,all_enty,teTranspMode) = 0.0;
v24_shipment_cost.lo(ttot,all_regi,all_enty) = 0.0;
v24_nonserve_cost.lo(ttot,all_regi,all_enty) = 0.0;



**********************************************************************
*** equations
**********************************************************************
EQUATIONS
  q24_totMport_quan(ttot,all_regi,all_enty)                               'Total imports of each region must equal the demanded imports'
  q24_shipment_cost(ttot,all_regi,all_enty)                               'Total transportation cost'
  q24_nonserve_cost(ttot,all_regi,all_enty)                               'Total cost arising from non-serviced transportation'
  q24_purchase_cost(ttot,all_regi,all_enty)                               'Total income or expense generated from trade'
  qm_budget(ttot,all_regi)                                                'Budgets of regions'
;

v24_shipment_quan.fx(ttot,regi,regi2,tradeSe,teTranspMode)$sameAs(regi,regi2) = 0.0;
v24_shipment_quan.fx(ttot,regi,regi2,tradeSe,teTranspMode)$(p24_constraints(regi,regi2,tradeSe,teTranspMode) lt 1.0) = 0.0;

q24_totMport_quan(ttot,regi,tradeSe)..
    pm_Mport(ttot,regi,tradeSe) =e= sum(  (regi2,teTranspMode), v24_shipment_quan(ttot,regi2,regi,tradeSe,teTranspMode)  );

***q24_shipment_cost(ttot,regi,tradeSe)..
***    v24_shipment_cost(ttot,regi,tradeSe) =e= sum(  (regi2,teTranspMode), v24_shipment_quan(ttot,regi2,regi,tradeSe,teTranspMode) * p24_transpcost_perdistance(teTranspMode) * p24_distance(regi,regi2)  );

q24_shipment_cost(ttot,regi,tradeSe)..
    v24_shipment_cost(ttot,regi,tradeSe)
  =e=
    sum(  (regi2,teTranspMode), v24_shipment_quan(ttot,regi2,regi,tradeSe,teTranspMode) * p24_transpcost_perdistance(teTranspMode) * p24_distance(regi,regi2)  );
    
q24_nonserve_cost(ttot,regi,tradeSe)..
    v24_nonserve_cost(ttot,regi,tradeSe) =e= sum(  (regi2,teTranspMode), v24_shipment_quan(ttot,regi2,regi,tradeSe,teTranspMode) * 10000 * p24_transpcost_disallowed(teTranspMode) * p24_disallowed(regi,regi2,tradeSe,teTranspMode)  );
    
q24_purchase_cost(ttot,regi,tradeSe)..
    v24_purchase_cost(ttot,regi,tradeSe)
  =e=
    sum(  (regi2,teTranspMode), v24_shipment_quan(ttot,regi2,regi,tradeSe,teTranspMode) * pm_exportPrice(ttot,regi2,tradeSe)  )
***  - sum(  (regi2,teTranspMode), v24_shipment_quan(ttot,regi,regi2,tradeSe,teTranspMode) * pm_exportPrice(ttot,regi ,tradeSe)  )
;
    
qm_budget(ttot,regi)..
    vm_budget(ttot,regi)
  =e=
    sum(tradeSe, v24_shipment_cost(ttot,regi,tradeSe))
  + sum(tradeSe, v24_purchase_cost(ttot,regi,tradeSe))
***  + sum(tradeSe, v24_nonserve_cost(ttot,regi,tradeSe))
;



**********************************************************************
*** optimisation
**********************************************************************
q24_objfunc_opttransp..
    v24_objvar_opttransp
  =e= 
    sum(  (ttot,regi), vm_budget(ttot,regi)  )
;

Model transport / all /;

solve transport using lp minimizing v24_objvar_opttransp;

display v24_shipment_quan.l;

execute_unload './output_data/results.gdx', v24_shipment_quan;
