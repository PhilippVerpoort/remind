*** |  (C) 2006-2020 Potsdam Institute for Climate Impact Research (PIK)
*** |  authors, and contributors see CITATION.cff file. This file is part
*** |  of REMIND and licensed under AGPL-3.0-or-later. Under Section 7 of
*** |  AGPL-3.0, you are granted additional permissions described in the
*** |  REMIND License Exception, version 1.0 (see LICENSE file).
*** |  Contact: remind@pik-potsdam.de
*** SOF ./modules/23_capitalMarket/imperfect/equations.gms

*ML 20181220* cumulated trade deficit must not be greater than some percentage of GDP and the growth rate of trade deficit must not exceed a certain percentage of GDP

q23_limit_debt(t,regi)..
  vm_cesIO(t,regi,"inco") * p23_debtCoeff
  =g=
  sum(ttot$(ttot.val le t.val),
    sum(mrktsPool, (pm_pvp(ttot,mrktsPool)/(pm_pvp("2005","good") + 0.000000001))*(vm_MportMrkt(ttot,regi,mrktsPool)- vm_XportMrkt(ttot,regi,mrktsPool)))
  )  
;

q23_limit_debt_growth(t,regi)..
  vm_cesIO(t,regi,"inco") * p23_debt_growthCoeff(regi)
  =g=
  vm_Mport(t,regi,"good") - vm_Xport(t,regi,"good") 
  + sum(mrktsPool, (pm_pvp(t,mrktsPool)/(pm_pvp(t,"good")+0.000000001))*(vm_Mport(t,regi,mrktsPool)- vm_Xport(t,regi,mrktsPool))) 
  + (pm_pvp(t,"perm")/(pm_pvp(t,"good")+0.000000001)) * (vm_Mport(t,regi,"perm") - vm_Xport(t,regi,"perm"))
;

*** EOF ./modules/23_capitalMarket/imperfect/equations.gms
