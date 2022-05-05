*** |  (C) 2006-2020 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/24_trade/standard/equations.gms

***-------------------------------------------------------------------------------
***                           TOTAL TRADE FROM MARKETS
***-------------------------------------------------------------------------------

q24_totalMport(t,regi,trade)..
    vm_Mport(t,regi,trade)
  =e=
    sum(mrkts2tradedGoods(tradeMrkts,trade),
      vm_MportMrkt(t,regi,tradeMrkts)
    )
;

q24_totalXport(t,regi,trade)..
    vm_Xport(t,regi,trade)
  =e=
    sum(mrkts2tradedGoods(tradeMrkts,trade),
      vm_XportMrkt(t,regi,tradeMrkts)
    )
;

*** EOF ./modules/24_trade/standard/equations.gms
