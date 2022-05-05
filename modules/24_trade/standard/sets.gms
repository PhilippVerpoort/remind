*** |  (C) 2006-2020 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/24_trade/standard/sets.gms

***-------------------------------------------------------------------------------
***                               GENERAL TRADE SETS
***-------------------------------------------------------------------------------
SETS
mrktsTrade                                  "Trade markets"
/
  good,
  perm,

  peoil,
  pecoal,
  peur,
  pebiolc,
  
  pegas_lng,
  pegas_ref_eur
/

mrktsPool                                   "Trade markets operating in pool-trade mode"
/
  good,
  perm,

  peoil,
  pecoal,
  peur,
  pebiolc,
  
  pegas_lng
/

mrktsPoolPE                                 "PE trade markets operating in pool-trade mode"
/
  peoil,
  pecoal,
  peur,
  pebiolc,
  
  pegas_lng
/

mrktsBilat                                  "Trade markets with bilateral price agreements"
/
/

mrkts2tradedGoods(mrktsTrade,all_enty)      "Mapping markets to traded goods"
/
  good.good, 
  perm.perm,
  
  peoil.peoil,
  pecoal.pecoal,
  peur.peur,
  pebiolc.pebiolc,
  
  pegas_lng.pegas,
  pegas_ref_deu.pegas
/

mrktsOpen(mrktsTrade)                       "Markets open to all regions by default"
/
  good,
  perm,

  peoil,
  pecoal,
  peur,
  pebiolc,
  
  pegas_lng
/

access2mrkts(all_regi,mrktsTrade)           "Other access to markets"
/
  EUR.pegas_ref_eur,
  REF.pegas_ref_eur
/

trade(all_enty)                             "All traded commodities (automatically calculated from mrkts2tradedGoods)"
/
/

tradePool(all_enty)                         "All commodities traded in pool-trade mode (automatically calculated from mrkts2tradedGoods)"
/
/

tradePoolPE(all_enty)                       "All PE commodities traded in pool-trade mode (automatically calculated from mrkts2tradedGoods)"
/
/

tradeBilat(all_enty)                        "All commodities traded in bilateral mode (automatically calculated from mrkts2tradedGoods)"
/
/
;

*** EOF ./modules/24_trade/standard/sets.gms
