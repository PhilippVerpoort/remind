**********************************************************************
*** define sets and parameters for trade exports and imports
**********************************************************************
SETS
    ttot                                                                        'Loaded times'
    all_regi                                                                    'Loaded regions'
    teTradeTransp                                                               'Technologies for transportation in trade'          
        /
        pipeline
        shipping
        shipping_Mport
        shipping_Xport
        shipping_vessels
        /
    teTradeTranspModes(teTradeTransp)                                           'Primary transportation modes'          
        /
        pipeline
        shipping
        /
    all_enty                                                                    'Quantities traded in the network topology'  
        /
        pegas
        /
;

PARAMETERS
    pm_ttot_val
;

SCALAR cm_startyear "first optimized modelling time step [year]"
/ 2005 /;

alias(all_regi,regi,regi2,regi3);
alias(all_enty,tradeSe);



**********************************************************************
*** load pooled export and import quantities from GDX files
**********************************************************************
PARAMETERS
    pm_Xport(ttot,all_regi,all_enty)                                            'Export of traded commodity.'
    pm_Mport(ttot,all_regi,all_enty)                                            'Import of traded commodity.'
    pm_Xport_effective(ttot,all_regi,all_enty)                                  'Export of traded commodity effective (computed from imports).'
    pm_XMport_pipeline(all_regi,all_regi,all_enty)                         'Export of traded commodity via pipeline.'
    p24_Xport_loaded(ttot,all_regi)                                             'Loaded export.'
    p24_Mport_loaded(ttot,all_regi)                                             'Loaded import.'
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

pm_ttot_val(ttot) = ttot.val;

pm_Xport_effective(ttot,regi,tradeSe)
 = pm_Xport(ttot,regi,tradeSe)
 + sum(regi2,pm_Mport(ttot,regi2,tradeSe) - pm_Xport(ttot,regi2,tradeSe))
 * pm_Xport(ttot,regi,tradeSe) / sum(regi2,pm_Xport(ttot,regi2,tradeSe))
;

pm_XMport_pipeline(regi,regi2,tradeSe) = 0.0;
pm_XMport_pipeline('MEA','EUR','pegas') = 0.100;
pm_XMport_pipeline('REF','EUR','pegas') = 0.150;
***pm_XMport_pipeline('CAZ','JPN','pegas') = 0.050;



**********************************************************************
*** sanity check: do the global exports and imports add up?
**********************************************************************
PARAMETERS M, X;

PARAMETERS
    total_trade_quant(ttot,all_enty)                                            'Total amount of traded commodities';

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
    p24_constraints(all_regi,all_regi,all_enty,teTradeTranspModes)              'Which regions can trade with each other?'
    p24_disallowed(all_regi,all_regi,all_enty,teTradeTranspModes)               'Opposite of p24_constraints'
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

p24_disallowed(all_regi,all_regi,tradeSe,teTradeTranspModes) = 1 - p24_constraints(all_regi,all_regi,tradeSe,teTradeTranspModes);



**********************************************************************
*** define distances: how far apart are the regions?
**********************************************************************
PARAMETERS
    p24_distance(all_regi,all_regi)                                             'Distance per regions (in units of 1000km)'
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
  pm_exportPrice(ttot,all_regi,all_enty)                                        'Export of traded commodity.'
  pm_pvp_pegas(ttot)                                                            'Loaded pvp prices.'
  p_peprice_pegas(ttot,all_regi)                                                'Loaded peprice prices.'
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
  p24_transpcost_perdistance(teTradeTranspModes)                                'Transportation cost per distance (tr$2005/TWa/1000km)'
      / pipeline 0.001
        shipping 0.03 /
  p24_transpcost_disallowed(teTradeTranspModes)                                 'Transportation cost for disallowed trade partners (tr$2005/TWa/1000km)'
      / pipeline 1
        shipping 3 /
  p24_cap_absMaxGrowthRate(teTradeTransp)                                       'Absolute maximum yearly growth rate for trade transportation capacity (TWa)'
      / pipeline 0.0
        shipping_Mport 100.0
        shipping_Xport 0.020 /
  p24_cap_relMaxGrowthRate(teTradeTransp)                                       'Relative maximum yearly growth rate for trade transportation capacity (percent)'
      / pipeline 0.0
        shipping_Mport 0.03
        shipping_Xport 0.01 /
;

TABLE p24_dataglob_transp(char,all_enty,teTradeTransp)                          'Transportation technology characteristics: investment costs, O&M costs, efficiency, ...'
$include "./input_data/generisdata_tradeTransp.prn"
;



**********************************************************************
*** variables
**********************************************************************
EQUATION  q24_objfunc_opttransp                                                 'Objective function for optimisation inside trade module';
VARIABLE  v24_objvar_opttransp                                                  'Objective variable for optimisation inside trade module';

POSITIVE VARIABLES
  v24_shipment_quan(ttot,all_regi,all_regi,all_enty,teTradeTranspModes)         'Shipment quantities for different transportation modes'
  v24_shipment_cost(ttot,all_regi,all_enty)                                     'Total transportation cost'
  v24_nonserve_cost(ttot,all_regi,all_enty)                                     'Total cost arising from non-serviced transportation'
  v24_tradeTransp_cost(ttot,all_regi,all_enty)                                  'Cost incurring from trade transportation'
  v24_cap_tradeTransp(ttot,all_regi,all_regi,all_enty,teTradeTransp)            'Net total capacities for transportation'
  v24_deltaCap_tradeTransp(ttot,all_regi,all_regi,all_enty,teTradeTransp)       'Capacity additions for transportation'
;
VARIABLES
  v24_purchase_cost(ttot,all_regi,all_enty)                                     'Total income or expense generated from trade'
  vm_budget(ttot,all_regi)                                                      'Budget of regions'
;



**********************************************************************
*** equations
**********************************************************************
EQUATIONS
  q24_totMport_quan(ttot,all_regi,all_enty)                                     'Total imports of each region must equal the demanded imports'
  q24_shipment_cost(ttot,all_regi,all_enty)                                     'Total transportation cost'
  q24_nonserve_cost(ttot,all_regi,all_enty)                                     'Total cost arising from non-serviced transportation'
  q24_purchase_cost(ttot,all_regi,all_enty)                                     'Total income or expense generated from trade'
  q24_tradeTransp_cost(ttot,all_regi,all_enty)                                  'Cost incurring from trade transportation'
  q24_cap_tradeTransp_pipeline(ttot,all_regi,all_regi,all_enty)                 'Trade is limited by capacity for pipelines.'
  q24_cap_tradeTransp_shipping_Mport(ttot,all_regi,all_enty)                    'Trade is limited by capacity for shipping.'
  q24_cap_tradeTransp_shipping_Xport(ttot,all_regi,all_enty)                    'Trade is limited by capacity for shipping.'
  q24_deltaCap_tradeTransp(ttot,all_regi,all_regi,all_enty,teTradeTransp)       'Trade transportation capacities from deltaCap.'
  q24_deltaCap_limit(ttot,all_regi,all_regi,all_enty,teTradeTransp)             'Limit deltaCap.'
  q24_prohibit_MportXport(ttot,regi,tradeSe)                                    'Prohibit importers to be exessive exporters.'
  qm_budget(ttot,all_regi)                                                      'Budgets of regions'
;

*** shipments constrained by capacity
q24_cap_tradeTransp_pipeline(ttot,regi,regi2,tradeSe)..
    v24_shipment_quan(ttot,regi,regi2,tradeSe,'pipeline')
  =l=
    v24_cap_tradeTransp(ttot,regi,regi2,tradeSe,'pipeline')
;

q24_cap_tradeTransp_shipping_Mport(ttot,regi,tradeSe)..
    sum(regi2, v24_shipment_quan(ttot,regi2,regi,tradeSe,'shipping'))
  =l=
    v24_cap_tradeTransp(ttot,regi,regi,tradeSe,'shipping_Mport')
;

q24_cap_tradeTransp_shipping_Xport(ttot,regi,tradeSe)..
    sum(regi2, v24_shipment_quan(ttot,regi,regi2,tradeSe,'shipping'))
  =l=
    v24_cap_tradeTransp(ttot,regi,regi,tradeSe,'shipping_Xport')
;

q24_deltaCap_tradeTransp(ttot,regi,regi2,tradeSe,teTradeTransp)$(pm_ttot_val(ttot) gt cm_startyear)..
    v24_deltaCap_tradeTransp(ttot,regi,regi2,tradeSe,teTradeTransp)
  =e=
    v24_cap_tradeTransp(ttot,regi,regi2,tradeSe,teTradeTransp)
  - v24_cap_tradeTransp(ttot-1,regi,regi2,tradeSe,teTradeTransp)
;

*** delta cap constrained to small increase
q24_deltaCap_limit(ttot,regi,regi2,tradeSe,teTradeTransp)$(pm_ttot_val(ttot) gt cm_startyear)..
    v24_deltaCap_tradeTransp(ttot,regi,regi2,tradeSe,teTradeTransp)
  =l=
    v24_cap_tradeTransp(ttot-1,regi,regi2,tradeSe,teTradeTransp)
  * (pm_ttot_val(ttot) - pm_ttot_val(ttot-1))
  * p24_cap_relMaxGrowthRate(teTradeTransp)
  + p24_cap_absMaxGrowthRate(teTradeTransp)
  * (pm_ttot_val(ttot) - pm_ttot_val(ttot-1))
;

*** shipments constrained: importers cant be exporters
q24_prohibit_MportXport(ttot,regi,tradeSe)$(pm_Mport(ttot,regi,tradeSe))..
    sum((regi2,teTradeTranspModes), v24_shipment_quan(ttot,regi,regi2,tradeSe,teTradeTranspModes))
  =l=
    pm_Xport_effective(ttot,regi,tradeSe)
;

*** shipment import equal to demands
q24_totMport_quan(ttot,regi,tradeSe)..
    pm_Mport(ttot,regi,tradeSe) =e= sum(  (regi2,teTradeTranspModes), v24_shipment_quan(ttot,regi2,regi,tradeSe,teTradeTranspModes)  );

*** cost from shipments
q24_shipment_cost(ttot,regi,tradeSe)..
    v24_shipment_cost(ttot,regi,tradeSe) =e= sum(  (regi2,teTradeTranspModes), v24_shipment_quan(ttot,regi2,regi,tradeSe,teTradeTranspModes) * p24_transpcost_perdistance(teTradeTranspModes) * p24_distance(regi,regi2)  );
    
q24_nonserve_cost(ttot,regi,tradeSe)..
    v24_nonserve_cost(ttot,regi,tradeSe) =e= sum(  (regi2,teTradeTranspModes), v24_shipment_quan(ttot,regi2,regi,tradeSe,teTradeTranspModes) * 10000 * p24_transpcost_disallowed(teTradeTranspModes) * p24_disallowed(regi,regi2,tradeSe,teTradeTranspModes)  );
    
q24_purchase_cost(ttot,regi,tradeSe)..
    v24_purchase_cost(ttot,regi,tradeSe) =e= sum(  (regi2,teTradeTranspModes), v24_shipment_quan(ttot,regi2,regi,tradeSe,teTradeTranspModes) * pm_exportPrice(ttot,regi2,tradeSe)  )
;

*** cost from transportation capacities
q24_tradeTransp_cost(ttot,regi,tradeSe)..
    v24_tradeTransp_cost(ttot,regi,tradeSe)
  =e=
    sum(regi2,
      v24_deltaCap_tradeTransp(ttot,regi2,regi,tradeSe,'pipeline')        * (p24_dataglob_transp('inco0',tradeSe,'pipeline')         + p24_dataglob_transp('inco0_d',tradeSe,'pipeline')         * p24_distance(regi,regi2))
    + v24_cap_tradeTransp(ttot,regi2,regi,tradeSe,'pipeline')             * (p24_dataglob_transp('omf'  ,tradeSe,'pipeline')         + p24_dataglob_transp('omf_d'  ,tradeSe,'pipeline')         * p24_distance(regi,regi2))
    + v24_shipment_quan(ttot,regi2,regi,tradeSe,'pipeline')               * (p24_dataglob_transp('omv'  ,tradeSe,'pipeline')         + p24_dataglob_transp('omv_d'  ,tradeSe,'pipeline')         * p24_distance(regi,regi2))
    + v24_deltaCap_tradeTransp(ttot,regi2,regi2,tradeSe,'shipping_Xport') * (p24_dataglob_transp('inco0',tradeSe,'shipping_Xport')   + p24_dataglob_transp('inco0_d',tradeSe,'shipping_Xport')   * p24_distance(regi,regi2))
    + v24_cap_tradeTransp(ttot,regi2,regi2,tradeSe,'shipping_Xport')      * (p24_dataglob_transp('omf'  ,tradeSe,'shipping_Xport')   + p24_dataglob_transp('omf_d'  ,tradeSe,'shipping_Xport')   * p24_distance(regi,regi2))
    + v24_deltaCap_tradeTransp(ttot,regi2,regi2,tradeSe,'shipping_Mport') * (p24_dataglob_transp('inco0',tradeSe,'shipping_Mport')   + p24_dataglob_transp('inco0_d',tradeSe,'shipping_Mport')   * p24_distance(regi,regi2))
    + v24_cap_tradeTransp(ttot,regi2,regi2,tradeSe,'shipping_Mport')      * (p24_dataglob_transp('omf'  ,tradeSe,'shipping_Mport')   + p24_dataglob_transp('omf_d'  ,tradeSe,'shipping_Mport')   * p24_distance(regi,regi2))
    + v24_shipment_quan(ttot,regi2,regi,tradeSe,'shipping')               * (p24_dataglob_transp('omv'  ,tradeSe,'shipping_vessels') + p24_dataglob_transp('omv_d'  ,tradeSe,'shipping_vessels') * p24_distance(regi,regi2))
    )
;

qm_budget(ttot,regi)..
    vm_budget(ttot,regi)
  =e=
***    sum(tradeSe, v24_shipment_cost(ttot,regi,tradeSe))
    sum(tradeSe, v24_tradeTransp_cost(ttot,regi,tradeSe))
  + sum(tradeSe, v24_purchase_cost(ttot,regi,tradeSe))
***  + sum(tradeSe, v24_nonserve_cost(ttot,regi,tradeSe))
;



**********************************************************************
*** bounds
**********************************************************************
*** variable constraints
v24_shipment_quan.lo(ttot,all_regi,all_regi,all_enty,teTradeTranspModes) = 0.0;
v24_shipment_cost.lo(ttot,all_regi,all_enty) = 0.0;
v24_nonserve_cost.lo(ttot,all_regi,all_enty) = 0.0;
v24_cap_tradeTransp.lo(ttot,all_regi,all_regi,all_enty,teTradeTransp) = 0.0;
v24_deltaCap_tradeTransp.lo(ttot,all_regi,all_regi,all_enty,teTradeTransp) = 0.0;

v24_cap_tradeTransp.fx(ttot,regi,regi2,tradeSe,'shipping_Mport')$(not sameAs(regi,regi2)) = 0.0;
v24_cap_tradeTransp.fx(ttot,regi,regi2,tradeSe,'shipping_Xport')$(not sameAs(regi,regi2)) = 0.0;

*** fix initial capacities
v24_cap_tradeTransp.fx(ttot,regi,regi2,tradeSe,'pipeline')$(pm_ttot_val(ttot) eq cm_startyear) = pm_XMport_pipeline(regi,regi2,tradeSe);
v24_cap_tradeTransp.fx(ttot,regi,regi,tradeSe,'shipping_Mport')$(pm_ttot_val(ttot) eq cm_startyear) = pm_Mport(ttot,regi,tradeSe)-sum(regi2,pm_XMport_pipeline(regi2,regi,tradeSe));
v24_cap_tradeTransp.fx(ttot,regi,regi,tradeSe,'shipping_Xport')$(pm_ttot_val(ttot) eq cm_startyear) = pm_Xport_effective(ttot,regi,tradeSe)-sum(regi2,pm_XMport_pipeline(regi,regi2,tradeSe));

*** shipments constrained: no self-imports or self-exports
v24_shipment_quan.fx(ttot,regi,regi2,tradeSe,teTradeTranspModes)$sameAs(regi,regi2) = 0.0;

*** shipments constrained: trade only allowed between defined regions
***v24_shipment_quan.fx(ttot,regi,regi2,tradeSe,teTradeTranspModes)$(p24_constraints(regi,regi2,tradeSe,teTradeTranspModes) lt 1.0) = 0.0;



**********************************************************************
*** optimisation
**********************************************************************
q24_objfunc_opttransp..
    v24_objvar_opttransp
  =e= 
    sum(  (ttot,regi), vm_budget(ttot,regi)  )
;

MODEL m24_tradeTransp
    /
        q24_objfunc_opttransp
        
        q24_totMport_quan
***        q24_shipment_cost
***        q24_nonserve_cost
        q24_purchase_cost
        q24_tradeTransp_cost
        q24_cap_tradeTransp_pipeline
        q24_cap_tradeTransp_shipping_Mport
        q24_cap_tradeTransp_shipping_Xport
        q24_deltaCap_tradeTransp
        q24_deltaCap_limit
        q24_prohibit_MportXport
        qm_budget
    /
;

SOLVE m24_tradeTransp USING lp MINIMIZING v24_objvar_opttransp;

execute_unload './output_data/results.gdx', v24_shipment_quan, v24_cap_tradeTransp, v24_deltaCap_tradeTransp;
