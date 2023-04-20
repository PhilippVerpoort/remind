#!/usr/bin/env python3

# author: Clara Bachorz
# edited: Philipp C. Verpoort


import pandas as pd
import csv


# list of levers and switches
levers = {
    'biomass': ['cm_maxProdBiolc'],
    'ccsdepl': ['c_ccsinjecratescen'],
    'direlec': ['cm_CESMkup_build', 'cm_build_H2costAddH2Inv', 'cm_CESMkup_ind', 'cm_steel_secondary_max_share_scenario', 'cm_FEtax_trajectory_rel', 'cm_EDGEtr_scen'],
    'greenh2': ['cm_PriceDurSlope_elh2'],
}


# load H2global scen config file
fname = 'scenario_config_H2global'
scenConfig = pd.read_csv(f"./config/{fname}.csv", sep=';')


# define new scenarios
newScenarios = []
for d in range(2):
    for climScen in ['WB2C', '1p5C']:
        scen1 = scenConfig.query(f"title=='Scen_{d+1}-{climScen}'").iloc[0:1].reset_index(drop=True)
        scen2 = scenConfig.query(f"title=='Scen_{d+2}-{climScen}'").iloc[0:1].reset_index(drop=True)
        
        for leverID, leverSwitches in levers.items():
            newScen1 = scen1.copy()
            newScen2 = scen2.copy()
            
            values1 = newScen1[leverSwitches].copy()
            values2 = newScen2[leverSwitches].copy()
            
            newScen1[leverSwitches] = values2
            newScen2[leverSwitches] = values1
            
            newScen1['title'] += f"+{leverID}"
            newScen2['title'] += f"-{leverID}"
            
            newScenarios.extend([newScen1, newScen2])
newScenariosDF = pd.concat(newScenarios).sort_values(by='title')


# collect all scenarios and export to new scenario config file
delimiter = scenConfig.iloc[0:1].copy()
delimiter['title'] = '_____Sensitivity_____'

allScenariosOut = pd.concat([scenConfig, delimiter, newScenariosDF]).reset_index(drop=True)
allScenariosOut.to_csv(f"./config/{fname}_sensitivity.csv", sep=';', index=False)
