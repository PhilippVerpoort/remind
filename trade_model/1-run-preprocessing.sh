#!/bin/bash

# dump and convert import and export quantities from SSP2
gdxdump ./input_data/input.gdx Symb=vm_Mport | grep "pegas'.L " | sed "s/'.'pegas'.L /,/g" | sed "s/'\.'/,/g" | sed "s/'//g" | sed "s/, //g" > ./input_data/pegas_Mports.dat
gdxdump ./input_data/input.gdx Symb=vm_Xport | grep "pegas'.L " | sed "s/'.'pegas'.L /,/g" | sed "s/'\.'/,/g" | sed "s/'//g" | sed "s/, //g" > ./input_data/pegas_Xports.dat

csv2gdx ./input_data/pegas_Mports.dat output=./input_data/pegas_Mports.gdx id=d fieldSep=comma index=1,2 useHeader=y value=3
csv2gdx ./input_data/pegas_Xports.dat output=./input_data/pegas_Xports.gdx id=d fieldSep=comma index=1,2 useHeader=y value=3



# dump and convert prices
gdxdump ./input_data/input.gdx Symb=pm_pvp | grep 'pegas' | sed "s/'.'pegas' /,/g" | sed "s/^'//g" | sed "s/, //g" > ./input_data/pm_pvp_pegas.dat
gdxdump ./input_data/input.gdx Symb=p_peprice | grep "pegas" | sed "s/'.'pegas' /,/g" | sed "s/'\.'/,/g" | sed "s/'//g" | sed "s/, //g" > ./input_data/p_peprice_pegas.dat
gdxdump ./input_data/input.gdx Symb=pm_seprice | grep "seh2" | sed "s/'.'seh2' /,/g" | sed "s/'\.'/,/g" | sed "s/'//g" | sed "s/, //g" > ./input_data/pm_seprice_seh2.dat

csv2gdx ./input_data/pm_pvp_pegas.dat output=./input_data/pm_pvp_pegas.gdx id=d fieldSep=comma index=1 useHeader=y value=2
csv2gdx ./input_data/p_peprice_pegas.dat output=./input_data/p_peprice_pegas.gdx id=d fieldSep=comma index=1,2 useHeader=y value=3
csv2gdx ./input_data/pm_seprice_seh2.dat output=./input_data/pm_seprice_seh2.gdx id=d fieldSep=comma index=1,2 useHeader=y value=3



# convert custom trade constraints to a GDX file
csv2gdx ./input_data/constraints_pipeline.dat id=d index=1 values=2..lastCol useHeader=y
csv2gdx ./input_data/constraints_shipping.dat id=d index=1 values=2..lastCol useHeader=y
csv2gdx ./input_data/distance.dat id=d index=1 values=2..lastCol useHeader=y

mv constraints_pipeline.gdx ./input_data/
mv constraints_shipping.gdx ./input_data/
mv distance.gdx ./input_data/
